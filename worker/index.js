const ZAI_MODEL = 'glm-4.7-flash';
const ZAI_URL = 'https://api.z.ai/api/paas/v4/chat/completions';
const MAX_MESSAGES = 12;
const MAX_TEXT = 2000;

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

function sanitize(messages) {
  const contents = [];
  for (const message of messages.slice(-MAX_MESSAGES)) {
    if (!message || typeof message.text !== 'string') continue;
    const role = message.role === 'model' ? 'model' : 'user';
    const text = message.text.slice(0, MAX_TEXT).trim();
    if (!text) continue;
    contents.push({ role, parts: [{ text }] });
  }
  while (contents.length && contents[0].role === 'model') contents.shift();
  return contents;
}

export default {
  async fetch(request, env) {
    if (!env.ZAI_API_KEY) {
      return json({ error: 'Worker belum memiliki konfigurasi AI.' }, 503);
    }
    if (request.method !== 'POST') {
      return json({ error: 'Gunakan POST.' }, 405);
    }
    if (env.CLIENT_KEY && request.headers.get('x-client-key') !== env.CLIENT_KEY) {
      return json({ error: 'Kunci klien tidak cocok.' }, 401);
    }

    if (!request.headers.get('content-type')?.includes('application/json')) {
      return json({ error: 'Konten harus berformat JSON.' }, 415);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Body bukan JSON.' }, 400);
    }

    const contents = sanitize(Array.isArray(body.messages) ? body.messages : []);
    if (contents.length === 0) {
      return json({ error: 'Tidak ada pesan.' }, 400);
    }
    const system =
      typeof body.system === 'string' ? body.system.slice(0, 4000) : '';

    let upstream;
    try {
      upstream = await fetch(ZAI_URL, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${env.ZAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: ZAI_MODEL,
          messages: [
            ...(system ? [{ role: 'system', content: system }] : []),
            ...contents.map(({ role, parts }) => ({
              role: role === 'model' ? 'assistant' : role,
              content: parts.map((part) => part.text).join(''),
            })),
          ],
          temperature: 0.6,
          max_tokens: 400,
        }),
      });
    } catch {
      return json({ error: 'Penyedia AI tidak dapat dihubungi.' }, 502);
    }

    if (!upstream.ok) {
      await upstream.body?.cancel();
      return json(
        { error: 'Penyedia AI menolak permintaan.', status: upstream.status },
        502,
      );
    }

    let data;
    try {
      data = await upstream.json();
    } catch {
      return json({ error: 'Balasan penyedia AI tidak valid.' }, 502);
    }
    const reply = data?.choices?.[0]?.message?.content;
    if (typeof reply !== 'string' || !reply.trim()) {
      return json({ error: 'Balasan AI kosong.' }, 502);
    }
    return json({ reply: reply.trim() });
  },
};
