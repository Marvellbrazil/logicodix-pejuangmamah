import { Hono } from 'hono';
import { z } from 'zod';
import type { AppVariables } from '../lib/context.ts';
import { ApiError } from '../lib/errors.ts';
import { newId, nowIso } from '../lib/ids.ts';
import {
  serializeSkills,
  toJobDto,
  type ApplicationRow,
  type JobRow,
  type UserRow,
} from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';
import { requireRole } from '../middleware/role.ts';

const urgency = z.enum(['today', 'thisWeek', 'flexible']);

const createSchema = z.object({
  title: z.string().trim().min(3, 'Judul lowongan wajib diisi.').max(90),
  company: z.string().trim().min(2, 'Nama usaha wajib diisi.').max(80),
  category: z.string().trim().min(2, 'Kategori wajib diisi.').max(40),
  description: z.string().trim().min(10, 'Deskripsi minimal 10 karakter.').max(1200),
  pay: z.number().int().min(0).max(10_000_000),
  payPeriod: z.string().trim().min(2).max(20).default('per hari'),
  district: z.string().trim().min(2, 'Kecamatan wajib diisi.').max(60),
  distanceKm: z.number().min(0).max(100).default(1),
  startHour: z.number().int().min(0).max(23),
  endHour: z.number().int().min(1).max(24),
  urgency,
  skills: z.array(z.string().trim().min(1).max(40)).max(12).default([]),
  contact: z.string().trim().max(30).default(''),
});

const patchSchema = z
  .object({ filled: z.boolean() })
  .partial();

function jobRows(
  db: { prepare: (sql: string) => { all: (...a: unknown[]) => unknown[] } },
  sql: string,
  ...params: unknown[]
): JobRow[] {
  return db.prepare(sql).all(...params) as JobRow[];
}

function decorate(
  db: {
    prepare: (sql: string) => {
      get: (...a: unknown[]) => unknown;
    };
  },
  rows: JobRow[],
  viewerId: string,
): ReturnType<typeof toJobDto>[] {
  return rows.map((row) => {
    const employer = db
      .prepare('SELECT * FROM users WHERE id = ?')
      .get(row.employer_id) as UserRow | undefined;
    const application = db
      .prepare(
        'SELECT id, status FROM applications WHERE job_id = ? AND worker_id = ?',
      )
      .get(row.id, viewerId) as { id: string; status: ApplicationRow['status'] } | undefined;
    const counts = db
      .prepare('SELECT COUNT(*) AS total FROM applications WHERE job_id = ?')
      .get(row.id) as { total: number };
    return toJobDto(
      row,
      employer,
      application ?? null,
      Number(counts.total),
    );
  });
}

export const jobRoutes = new Hono<{ Variables: AppVariables }>();

jobRoutes.use('*', requireAuth);

jobRoutes.get('/', (c) => {
  const db = c.var.db;
  const q = (c.req.query('q') ?? '').trim();
  const category = (c.req.query('category') ?? '').trim();
  const urgencyFilter = (c.req.query('urgency') ?? '').trim();
  const employerOnly = c.req.query('mine') === 'true';

  const clauses: string[] = [];
  const params: unknown[] = [];

  if (employerOnly) {
    clauses.push('employer_id = ?');
    params.push(c.var.userId);
  }
  if (q !== '') {
    clauses.push('(title LIKE ? OR company LIKE ? OR district LIKE ? OR description LIKE ?)');
    const like = `%${q}%`;
    params.push(like, like, like, like);
  }
  if (category !== '') {
    clauses.push('category = ?');
    params.push(category);
  }
  if (urgencyFilter !== '') {
    if (!['today', 'thisWeek', 'flexible'].includes(urgencyFilter)) {
      throw ApiError.badRequest('Filter urgensi tidak valid.');
    }
    clauses.push('urgency = ?');
    params.push(urgencyFilter);
  }
  if (c.req.query('minPay') !== undefined) {
    const minPay = Number(c.req.query('minPay'));
    if (!Number.isSafeInteger(minPay) || minPay < 0 || minPay > 10_000_000) {
      throw ApiError.badRequest('Filter upah minimum tidak valid.');
    }
    clauses.push('pay >= ?');
    params.push(minPay);
  }
  if (c.req.query('cursor') !== undefined) {
    const cursor = c.req.query('cursor')!.trim();
    if (cursor.length === 0 || cursor.length > 100) {
      throw ApiError.badRequest('Cursor halaman tidak valid.');
    }
    clauses.push('(created_at < ? OR (created_at = ? AND id < ?))');
    params.push(cursor, cursor.split('|')[0], cursor.split('|')[1] ?? '');
  }

  const where = clauses.length === 0 ? '' : `WHERE ${clauses.join(' AND ')}`;
  const rows = jobRows(
    db,
    `SELECT * FROM jobs ${where} ORDER BY
       CASE urgency WHEN 'today' THEN 0 WHEN 'thisWeek' THEN 1 ELSE 2 END,
       created_at DESC, id DESC
     LIMIT 100`,
    ...params,
  );

  const categories = jobRows(
    db,
    'SELECT DISTINCT category FROM jobs ORDER BY category',
  ).map((row) => (row as unknown as { category: string }).category);

  return c.json({ jobs: decorate(db, rows, c.var.userId), categories });
});

jobRoutes.get('/:id', (c) => {
  const db = c.var.db;
  const row = db
    .prepare('SELECT * FROM jobs WHERE id = ?')
    .get(c.req.param('id')) as JobRow | undefined;
  if (row === undefined) throw ApiError.notFound('Lowongan tidak ditemukan.');
  const [job] = decorate(db, [row], c.var.userId);
  return c.json({ job });
});

jobRoutes.post('/', requireRole('employer'), async (c) => {
  const parsed = createSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!parsed.success) {
    throw ApiError.badRequest(parsed.error.issues[0]?.message ?? 'Data tidak valid.');
  }
  const input = parsed.data;
  if (input.endHour <= input.startHour) {
    throw ApiError.badRequest('Jam selesai harus setelah jam mulai.');
  }
  const db = c.var.db;
  const timestamp = nowIso();
  const id = newId();
  db.prepare(
    `INSERT INTO jobs
      (id, employer_id, title, company, category, description, pay, pay_period,
       district, distance_km, start_hour, end_hour, urgency, skills, contact,
       filled, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)`,
  ).run(
    id,
    c.var.userId,
    input.title,
    input.company,
    input.category,
    input.description,
    input.pay,
    input.payPeriod,
    input.district,
    input.distanceKm,
    input.startHour,
    input.endHour,
    input.urgency,
    serializeSkills(input.skills),
    input.contact,
    timestamp,
    timestamp,
  );
  const row = db.prepare('SELECT * FROM jobs WHERE id = ?').get(id) as JobRow;
  const [job] = decorate(db, [row], c.var.userId);
  return c.json({ job }, 201);
});

jobRoutes.patch('/:id', requireRole('employer'), async (c) => {
  const parsed = patchSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!parsed.success) {
    throw ApiError.badRequest('Data tidak valid.');
  }
  const db = c.var.db;
  const row = db
    .prepare('SELECT * FROM jobs WHERE id = ?')
    .get(c.req.param('id')) as JobRow | undefined;
  if (row === undefined) throw ApiError.notFound('Lowongan tidak ditemukan.');
  if (row.employer_id !== c.var.userId) {
    throw ApiError.forbidden('Hanya pemilik lowongan yang bisa mengubahnya.');
  }
  if (parsed.data.filled !== undefined) {
    db.prepare('UPDATE jobs SET filled = ?, updated_at = ? WHERE id = ?').run(
      parsed.data.filled ? 1 : 0,
      nowIso(),
      row.id,
    );
  }
  const updated = db.prepare('SELECT * FROM jobs WHERE id = ?').get(row.id) as JobRow;
  const [job] = decorate(db, [updated], c.var.userId);
  return c.json({ job });
});

jobRoutes.delete('/:id', requireRole('employer'), (c) => {
  const db = c.var.db;
  const row = db
    .prepare('SELECT * FROM jobs WHERE id = ?')
    .get(c.req.param('id')) as JobRow | undefined;
  if (row === undefined) throw ApiError.notFound('Lowongan tidak ditemukan.');
  if (row.employer_id !== c.var.userId) {
    throw ApiError.forbidden('Hanya pemilik lowongan yang bisa menghapusnya.');
  }
  db.prepare('DELETE FROM jobs WHERE id = ?').run(row.id);
  return c.json({ ok: true });
});

jobRoutes.get('/:id/applicants', requireRole('employer'), (c) => {
  const db = c.var.db;
  const row = db
    .prepare('SELECT * FROM jobs WHERE id = ?')
    .get(c.req.param('id')) as JobRow | undefined;
  if (row === undefined) throw ApiError.notFound('Lowongan tidak ditemukan.');
  if (row.employer_id !== c.var.userId) {
    throw ApiError.forbidden('Hanya pemilik lowongan yang bisa melihat pelamar.');
  }
  const applicants = db
    .prepare(
      `SELECT a.*, u.full_name, u.display_name, u.headline, u.district,
              u.skills, u.photo_url, u.email, u.phone
         FROM applications a JOIN users u ON u.id = a.worker_id
        WHERE a.job_id = ? ORDER BY a.created_at DESC`,
    )
    .all(row.id) as Array<
    ApplicationRow & {
      full_name: string;
      display_name: string;
      headline: string;
      district: string;
      skills: string;
      photo_url: string | null;
      email: string;
      phone: string;
    }
  >;
  return c.json({
    job: decorate(db, [row], c.var.userId)[0],
    applicants: applicants.map((item) => ({
      id: item.id,
      status: item.status,
      note: item.note,
      createdAt: item.created_at,
      worker: {
        id: item.worker_id,
        fullName: item.full_name,
        displayName: item.display_name,
        headline: item.headline,
        district: item.district,
        email: item.email,
        phone: item.phone,
        photoUrl: item.photo_url,
        skills: JSON.parse(item.skills) as string[],
      },
    })),
  });
});
