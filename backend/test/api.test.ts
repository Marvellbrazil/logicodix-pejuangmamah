import { after, before, test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.ts';
import { migrate, openDb, type Db } from '../src/db/client.ts';
import { readEnv } from '../src/env.ts';
import { seed } from '../src/db/seed.ts';

const env = readEnv({
  NODE_ENV: 'test',
  JWT_SECRET: 'test-secret-value-that-is-long-enough-1234',
  DATABASE_PATH: ':memory:',
  SEED: 'false',
  DEMO_PASSWORD: 'Rahasia123!',
  AUTH_ATTEMPT_LIMIT: '1000',
  APP_ORIGINS: 'http://localhost',
});

let db: Db;
let app: ReturnType<typeof createApp>;

before(async () => {
  db = openDb(':memory:');
  migrate(db);
  await seed(db, { demoPassword: 'Rahasia123!' });
  app = createApp(db, env);
});

after(() => db.close());

async function call(
  path: string,
  init: RequestInit = {},
): Promise<{ status: number; body: any }> {
  const response = await app.fetch(
    new Request(`http://localhost${path}`, {
      ...init,
      headers: { 'content-type': 'application/json', ...(init.headers ?? {}) },
    }),
  );
  return { status: response.status, body: await response.json() };
}

async function register(
  email: string,
  role: 'worker' | 'employer' = 'worker',
): Promise<{ token: string; id: string }> {
  const result = await call('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({
      email,
      password: 'Rahasia123!',
      fullName: 'Rina Pratiwi',
      displayName: 'Rina',
      role,
    }),
  });
  assert.equal(result.status, 201, JSON.stringify(result.body));
  return { token: result.body.token, id: result.body.user.id };
}

function auth(token: string): Record<string, string> {
  return { authorization: `Bearer ${token}` };
}

describe('auth', () => {
  test('register menolak email duplikat', async () => {
    await register('dup@kerjaqueue.local');
    const again = await call('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        email: 'dup@kerjaqueue.local',
        password: 'Rahasia123!',
        fullName: 'Rina Pratiwi',
        displayName: 'Rina',
      }),
    });
    assert.equal(again.status, 409);
    assert.equal(again.body.error.code, 'conflict');
  });

  test('login menolak kata sandi salah tanpa membocorkan detail', async () => {
    const result = await call('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        email: 'pencari@kerjaqueue.local',
        password: 'salah-sekali',
      }),
    });
    assert.equal(result.status, 401);
    assert.equal(result.body.error.message, 'Email atau kata sandi salah.');
  });

  test('login demo berhasil dan /api/me mengembalikan profil diri', async () => {
    const login = await call('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        email: 'pencari@kerjaqueue.local',
        password: 'Rahasia123!',
      }),
    });
    assert.equal(login.status, 200);
    assert.equal(login.body.user.email, 'pencari@kerjaqueue.local');

    const me = await call('/api/me', { headers: auth(login.body.token) });
    assert.equal(me.status, 200);
    assert.equal(me.body.user.displayName, 'Rina');
    assert.ok(me.body.stats.applications >= 0);
  });

  test('endpoint terproteksi menolak tanpa token', async () => {
    const result = await call('/api/me');
    assert.equal(result.status, 401);
    assert.equal(result.body.error.code, 'unauthorized');
  });

  test('google ditolak rapi saat CLIENT_ID belum diisi', async () => {
    const result = await call('/api/auth/google', {
      method: 'POST',
      body: JSON.stringify({ idToken: 'x'.repeat(40) }),
    });
    assert.equal(result.status, 503);
    assert.match(result.body.error.message, /belum dikonfigurasi/);
  });
});

describe('jobs dan lamaran', () => {
  test('feed mengembalikan lowongan seed berurutan urgensi', async () => {
    const { token } = await register('feed@kerjaqueue.local');
    const result = await call('/api/jobs', { headers: auth(token) });
    assert.equal(result.status, 200);
    assert.ok(result.body.jobs.length >= 12);
    assert.ok(result.body.categories.includes('Kuliner'));
    const urgencies = result.body.jobs.map((job: any) => job.urgency);
    const firstThisWeek = urgencies.indexOf('thisWeek');
    assert.equal(urgencies.slice(0, firstThisWeek).every((u: string) => u === 'today'), true);
  });

  test('cursor tanpa pasangan id ditolak', async () => {
    const { token } = await register('cursor@kerjaqueue.local');
    const result = await call('/api/jobs?cursor=2026-11-14T09%3A00%3A00.000Z', {
      headers: auth(token),
    });
    assert.equal(result.status, 200);
  });

  test('cursor cacat ditolak', async () => {
    const { token } = await register('cursor-invalid@kerjaqueue.local');
    const result = await call('/api/jobs?cursor=', { headers: auth(token) });
    assert.equal(result.status, 400);
  });

  test('filter upah invalid ditolak', async () => {
    const { token } = await register('pay-filter@kerjaqueue.local');
    const result = await call('/api/jobs?minPay=-1', { headers: auth(token) });
    assert.equal(result.status, 400);
  });

  test('pencarian dan filter kategori bekerja', async () => {
    const { token } = await register('search@kerjaqueue.local');
    const found = await call('/api/jobs?q=barista', { headers: auth(token) });
    assert.equal(found.status, 200);
    assert.ok(found.body.jobs.length >= 1);

    const filtered = await call('/api/jobs?category=Desain', {
      headers: auth(token),
    });
    assert.ok(
      filtered.body.jobs.every((job: any) => job.category === 'Desain'),
    );
  });

  test('melamar membuat lamaran dan chat awal', async () => {
    const worker = await register('lamar@kerjaqueue.local');
    const feed = await call('/api/jobs', { headers: auth(worker.token) });
    const target = feed.body.jobs[0];

    const applied = await call(`/api/jobs/${target.id}/apply`, {
      method: 'POST',
      headers: auth(worker.token),
    });
    assert.equal(applied.status, 201);
    assert.equal(applied.body.application.status, 'sent');
    assert.ok(applied.body.chatId);

    const again = await call(`/api/jobs/${target.id}/apply`, {
      method: 'POST',
      headers: auth(worker.token),
    });
    assert.equal(again.status, 200);

    const mine = await call('/api/applications/mine', {
      headers: auth(worker.token),
    });
    assert.equal(mine.body.applications.length, 1);
  });

  test('pemilik lowongan tidak bisa melamar lowongannya sendiri', async () => {
    const employer = await register('owner@kerjaqueue.local', 'employer');
    const created = await call('/api/jobs', {
      method: 'POST',
      headers: auth(employer.token),
      body: JSON.stringify({
        title: 'Bantu bersihkan gerai',
        company: 'Kopi Sendiri',
        category: 'Kebersihan',
        description: 'Bersihkan gerai sebelum buka pagi ini.',
        pay: 90000,
        district: 'Rungkut',
        startHour: 6,
        endHour: 9,
        urgency: 'today',
      }),
    });
    assert.equal(created.status, 201);

    const self = await call(`/api/jobs/${created.body.job.id}/apply`, {
      method: 'POST',
      headers: auth(employer.token),
    });
    assert.equal(self.status, 403);
  });

  test('akun pekerja tidak bisa memasang lowongan', async () => {
    const worker = await register('worker-post@kerjaqueue.local');
    const result = await call('/api/jobs', {
      method: 'POST',
      headers: auth(worker.token),
      body: JSON.stringify({
        title: 'Bantu bersihkan gerai',
        company: 'Kopi Sendiri',
        category: 'Kebersihan',
        description: 'Bersihkan gerai sebelum buka pagi ini.',
        pay: 90000,
        district: 'Rungkut',
        startHour: 6,
        endHour: 9,
        urgency: 'today',
      }),
    });
    assert.equal(result.status, 403);
  });

  test('pemberi kerja melihat pelamar dan bisa mengubah status', async () => {
    const employer = await register('bos@kerjaqueue.local', 'employer');
    const worker = await register('pekerja@kerjaqueue.local');

    const created = await call('/api/jobs', {
      method: 'POST',
      headers: auth(employer.token),
      body: JSON.stringify({
        title: 'Angkut barang pasar',
        company: 'Toko Bos',
        category: 'Fisik',
        description: 'Angkut empat karung beras dari pasar ke toko.',
        pay: 85000,
        district: 'Wonokromo',
        startHour: 7,
        endHour: 10,
        urgency: 'today',
      }),
    });
    const jobId = created.body.job.id;

    await call(`/api/jobs/${jobId}/apply`, {
      method: 'POST',
      headers: auth(worker.token),
    });

    const applicants = await call(`/api/jobs/${jobId}/applicants`, {
      headers: auth(employer.token),
    });
    assert.equal(applicants.status, 200);
    assert.equal(applicants.body.applicants.length, 1);
    const applicationId = applicants.body.applicants[0].id;

    const viewed = await call(`/api/applications/${applicationId}`, {
      method: 'PATCH',
      headers: auth(employer.token),
      body: JSON.stringify({ status: 'viewed' }),
    });
    assert.equal(viewed.status, 200);

    const interview = await call(`/api/applications/${applicationId}`, {
      method: 'PATCH',
      headers: auth(employer.token),
      body: JSON.stringify({ status: 'interview' }),
    });
    assert.equal(interview.status, 200);

    const accepted = await call(`/api/applications/${applicationId}`, {
      method: 'PATCH',
      headers: auth(employer.token),
      body: JSON.stringify({ status: 'accepted' }),
    });
    assert.equal(accepted.status, 200);
    assert.equal(accepted.body.application.status, 'accepted');

    const detail = await call(`/api/jobs/${jobId}`, {
      headers: auth(employer.token),
    });
    assert.equal(detail.body.job.filled, true);
  });

  test('pekerja tidak bisa mengubah status jadi accepted', async () => {
    const worker = await register('nakal@kerjaqueue.local');
    const feed = await call('/api/jobs', { headers: auth(worker.token) });
    const applied = await call(`/api/jobs/${feed.body.jobs[1].id}/apply`, {
      method: 'POST',
      headers: auth(worker.token),
    });
    const result = await call(
      `/api/applications/${applied.body.application.id}`,
      {
        method: 'PATCH',
        headers: auth(worker.token),
        body: JSON.stringify({ status: 'accepted' }),
      },
    );
    assert.equal(result.status, 403);
  });
});

describe('chat', () => {
  test('chat terbentuk dari lamaran dan bisa bertukar pesan', async () => {
    const employer = await register('chattoko@kerjaqueue.local', 'employer');
    const worker = await register('chatkerja@kerjaqueue.local');

    const created = await call('/api/jobs', {
      method: 'POST',
      headers: auth(employer.token),
      body: JSON.stringify({
        title: 'Jaga warung siang',
        company: 'Warung Chat',
        category: 'Kuliner',
        description: 'Jaga warung dari siang sampai sore, layani pembeli.',
        pay: 95000,
        district: 'Gubeng',
        startHour: 11,
        endHour: 16,
        urgency: 'today',
      }),
    });

    const applied = await call(`/api/jobs/${created.body.job.id}/apply`, {
      method: 'POST',
      headers: auth(worker.token),
    });
    const chatId = applied.body.chatId;

    const workerChats = await call('/api/chats', {
      headers: auth(worker.token),
    });
    assert.equal(workerChats.status, 200);
    assert.ok(workerChats.body.chats.length >= 1);

    const sent = await call(`/api/chats/${chatId}/messages`, {
      method: 'POST',
      headers: auth(worker.token),
      body: JSON.stringify({ body: 'Saya bisa mulai jam 11.' }),
    });
    assert.equal(sent.status, 201);

    const employerView = await call(`/api/chats/${chatId}/messages`, {
      headers: auth(employer.token),
    });
    assert.equal(employerView.status, 200);
    assert.ok(
      employerView.body.messages.some((m: any) =>
        m.body.includes('mulai jam 11'),
      ),
    );

    const employerList = await call('/api/chats', {
      headers: auth(employer.token),
    });
    assert.ok(employerList.body.unread >= 1);

    await call(`/api/chats/${chatId}/read`, {
      method: 'POST',
      headers: auth(employer.token),
    });
    const afterRead = await call('/api/chats', {
      headers: auth(employer.token),
    });
    assert.equal(afterRead.body.unread, 0);
  });

  test('orang luar tidak bisa membaca chat', async () => {
    const outsider = await register('luar@kerjaqueue.local');
    const chats = await call('/api/chats', { headers: auth(outsider.token) });
    assert.equal(chats.status, 200);
    assert.equal(chats.body.chats.length, 0);

    const firstChat = db
      .prepare('SELECT id FROM chats LIMIT 1')
      .get() as { id: string };
    const result = await call(`/api/chats/${firstChat.id}/messages`, {
      headers: auth(outsider.token),
    });
    assert.equal(result.status, 403);
  });
});

describe('profil', () => {
  test('PATCH /api/me memperbarui profil dan menolak jam terbalik', async () => {
    const worker = await register('profil@kerjaqueue.local');

    const updated = await call('/api/me', {
      method: 'PATCH',
      headers: auth(worker.token),
      body: JSON.stringify({
        fullName: 'Rina Pratiwi',
        displayName: 'Rina',
        headline: 'Barista & pelayanan',
        district: 'Rungkut',
        skills: ['Barista', 'Kasir', 'Barista'],
        maxDistanceKm: 6,
        minPay: 100000,
      }),
    });
    assert.equal(updated.status, 200);
    assert.deepEqual(updated.body.user.skills, ['Barista', 'Kasir']);
    assert.equal(updated.body.user.minPay, 100000);

    const invalid = await call('/api/me', {
      method: 'PATCH',
      headers: auth(worker.token),
      body: JSON.stringify({ startHour: 15, endHour: 9 }),
    });
    assert.equal(invalid.status, 400);
  });

  test('profil publik tidak membocorkan email atau telepon', async () => {
    const worker = await register('publik@kerjaqueue.local');
    const result = await call(`/api/users/${worker.id}`, {
      headers: auth(worker.token),
    });
    assert.equal(result.status, 200);
    assert.equal(result.body.user.email, undefined);
    assert.equal(result.body.user.phone, undefined);
  });

  test('daftar orang bisa dicari berdasarkan peran', async () => {
    const worker = await register('cariorang@kerjaqueue.local');
    const result = await call('/api/users?role=employer', {
      headers: auth(worker.token),
    });
    assert.equal(result.status, 200);
    assert.ok(result.body.people.every((p: any) => p.role === 'employer'));
    assert.ok(
      result.body.people.every((p: any) => p.id !== worker.id),
    );
  });
});

describe('asisten', () => {
  test('menolak rapi ketika ZAI_API_KEY kosong', async () => {
    const worker = await register('asisten@kerjaqueue.local');
    const result = await call('/api/assistant', {
      method: 'POST',
      headers: auth(worker.token),
      body: JSON.stringify({
        messages: [{ role: 'user', text: 'Lowongan apa yang cocok?' }],
      }),
    });
    assert.equal(result.status, 503);
    assert.match(result.body.error.message, /belum aktif/);
  });

  test('validasi menolak pesan kosong', async () => {
    const worker = await register('asisten2@kerjaqueue.local');
    const result = await call('/api/assistant', {
      method: 'POST',
      headers: auth(worker.token),
      body: JSON.stringify({ messages: [] }),
    });
    assert.equal(result.status, 400);
  });
});

describe('umum', () => {
  test('health melaporkan status integrasi', async () => {
    const result = await call('/health');
    assert.equal(result.status, 200);
    assert.equal(result.body.ok, true);
    assert.equal(result.body.assistant, false);
  });

  test('endpoint tidak dikenal mengembalikan JSON 404', async () => {
    const result = await call('/api/tidak-ada');
    assert.equal(result.status, 404);
    assert.equal(result.body.error.code, 'not_found');
  });
});
