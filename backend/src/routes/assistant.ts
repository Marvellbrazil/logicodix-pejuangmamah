import { Hono } from 'hono';
import { z } from 'zod';
import type { AppVariables } from '../lib/context.ts';
import { ApiError } from '../lib/errors.ts';
import type { UserRow } from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';
import { rateLimit } from '../middleware/ratelimit.ts';

const schema = z.object({
  system: z.string().max(4000).default(''),
  messages: z
    .array(
      z.object({
        role: z.enum(['user', 'model', 'assistant']),
        text: z.string().max(4000),
      }),
    )
    .min(1)
    .max(20),
});

const SYSTEM_PROMPT = `Kamu adalah Asisten Kerjaqueue, pendamping pencari kerja harian di Indonesia.
Jawab dengan bahasa Indonesia sederhana, maksimal 90 kata. Pakai hanya data lowongan
dan profil yang diberikan; jangan mengarang lowongan baru. Jika informasi kunci belum
ada, tanyakan satu hal saja per balasan.`;

async function consumeQuota(
  db: {
    prepare: (sql: string) => {
      get: (...a: unknown[]) => unknown;
      run: (...a: unknown[]) => unknown;
    };
  },
  userId: string,
  limit: number,
): Promise<boolean> {
  const day = new Date().toISOString().slice(0, 10);
  const row = db
    .prepare('SELECT count FROM assistant_usage WHERE user_id = ? AND day = ?')
    .get(userId, day) as { count: number } | undefined;
  if (row === undefined || Number(row.count) < limit) {
    db.prepare(
      `INSERT INTO assistant_usage (user_id, day, count) VALUES (?, ?, 1)
       ON CONFLICT (user_id, day) DO UPDATE SET count = count + 1`,
    ).run(userId, day);
    return true;
  }
  return false;
}

export const assistantRoutes = new Hono<{ Variables: AppVariables }>();

assistantRoutes.use('*', requireAuth);
assistantRoutes.use('*', rateLimit('assistant'));

assistantRoutes.post('/', async (c) => {
  const parsed = schema.safeParse(await c.req.json().catch(() => ({})));
  if (!parsed.success) {
    throw ApiError.badRequest(
      parsed.error.issues[0]?.message ?? 'Permintaan asisten tidak valid.',
    );
  }

  const env = c.var.env;
  if (env.ZAI_API_KEY === '') {
    throw ApiError.unavailable(
      'Asisten AI belum aktif di server. Pakai saran lokal dulu.',
    );
  }

  const db = c.var.db;
  if (!(await consumeQuota(db, c.var.userId, env.ASSISTANT_DAILY_LIMIT))) {
    throw ApiError.tooMany(
      'Batas harian Asisten sudah tercapai. Coba lagi besok.',
    );
  }

  const user = db
    .prepare('SELECT * FROM users WHERE id = ?')
    .get(c.var.userId) as UserRow | undefined;
  const profileLine =
    user === undefined || user.full_name === ''
      ? 'Profil pengguna belum lengkap.'
      : `Profil pengguna: ${user.full_name}, keahlian ${
          (JSON.parse(user.skills) as string[]).join(', ') || 'belum diisi'
        }, kecamatan ${user.district || 'belum diisi'}, upah minimum ${user.min_pay}.`;

  const system = [SYSTEM_PROMPT, parsed.data.system, profileLine]
    .filter((part) => part.trim() !== '')
    .join('\n\n');

  const payload = {
    model: env.ZAI_MODEL,
    messages: [
      { role: 'system', content: system },
      ...parsed.data.messages.map((message) => ({
        role: message.role === 'model' ? 'assistant' : message.role,
        content: message.text,
      })),
    ],
    temperature: 0.6,
    max_tokens: 400,
  };

  let upstream: Response;
  try {
    upstream = await fetch(env.ZAI_URL, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${env.ZAI_API_KEY}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(20_000),
    });
  } catch {
    throw ApiError.unavailable('Asisten AI tidak merespons. Coba lagi.');
  }

  if (!upstream.ok) {
    console.error('[assistant] upstream status', upstream.status);
    if (upstream.status === 429) {
      throw ApiError.tooMany('Kuota Asisten AI sedang penuh. Coba lagi nanti.');
    }
    throw ApiError.unavailable('Asisten AI sedang bermasalah. Coba lagi.');
  }

  let data: unknown;
  try {
    data = await upstream.json();
  } catch {
    throw ApiError.unavailable('Balasan Asisten AI tidak bisa dibaca.');
  }

  const reply = (
    data as { choices?: Array<{ message?: { content?: string } }> }
  )?.choices?.[0]?.message?.content?.trim();
  if (!reply) {
    throw ApiError.unavailable('Asisten AI mengirim balasan kosong.');
  }
  return c.json({ reply });
});
