import test from 'node:test';
import assert from 'node:assert/strict';
import worker from './index.js';

const env = { ZAI_API_KEY: 'test-secret', CLIENT_KEY: 'client-secret' };

function request(body, headers = {}) {
  return new Request('https://worker.example/chat', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-client-key': 'client-secret', ...headers },
    body: JSON.stringify(body),
  });
}

test('proxies messages to Z.ai and returns assistant text', async (t) => {
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  let sent;
  globalThis.fetch = async (url, options) => {
    sent = { url: String(url), options, body: JSON.parse(options.body) };
    return Response.json({ choices: [{ message: { content: 'Ada lowongan cocok.' } }] });
  };

  const response = await worker.fetch(request({
    system: 'jawab singkat',
    messages: [
      { role: 'user', text: 'halo' },
      { role: 'model', text: 'hai' },
      { role: 'user', text: 'cari kerja' },
    ],
  }), env);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { reply: 'Ada lowongan cocok.' });
  assert.equal(sent.url, 'https://api.z.ai/api/paas/v4/chat/completions');
  assert.equal(sent.options.headers.authorization, 'Bearer test-secret');
  assert.equal(sent.body.model, 'glm-4.7-flash');
  assert.equal(sent.body.messages[0].role, 'system');
  assert.deepEqual(sent.body.messages.slice(1), [
    { role: 'user', content: 'halo' },
    { role: 'assistant', content: 'hai' },
    { role: 'user', content: 'cari kerja' },
  ]);
});

test('rejects requests without client gate key', async () => {
  const response = await worker.fetch(
    request({ messages: [{ role: 'user', text: 'hai' }] }, { 'x-client-key': 'wrong' }),
    env,
  );
  assert.equal(response.status, 401);
});

test('rejects empty message payload without upstream call', async () => {
  const response = await worker.fetch(request({ messages: [] }), env);
  assert.equal(response.status, 400);
});

test('does not expose upstream error body or provider key', async (t) => {
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  globalThis.fetch = async () => new Response('secret provider details', { status: 429 });

  const response = await worker.fetch(
    request({ messages: [{ role: 'user', text: 'hai' }] }),
    env,
  );
  const body = await response.text();
  assert.equal(response.status, 502);
  assert.equal(body.includes('secret provider details'), false);
  assert.equal(body.includes('test-secret'), false);
});
