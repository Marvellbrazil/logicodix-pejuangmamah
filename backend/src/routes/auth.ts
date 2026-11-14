import { Hono } from 'hono';
import { z } from 'zod';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { AppVariables } from '../lib/context.ts';
import type { Db } from '../db/client.ts';
import { ApiError } from '../lib/errors.ts';
import { newId, nowIso } from '../lib/ids.ts';
import { hashPassword, verifyPassword } from '../lib/password.ts';
import { signSession } from '../lib/jwt.ts';
import { toSelfUser, type UserRow } from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';
import { rateLimit } from '../middleware/ratelimit.ts';
import { withTransaction } from '../db/transaction.ts';

const registerSchema = z.object({
  email: z.string().trim().toLowerCase().email('Format email tidak valid.'),
  password: z.string().min(8, 'Kata sandi minimal 8 karakter.').max(200),
  fullName: z.string().trim().min(2, 'Nama lengkap wajib diisi.').max(80),
  displayName: z.string().trim().min(1, 'Nama panggilan wajib diisi.').max(40),
  role: z.enum(['worker', 'employer']).default('worker'),
});

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Format email tidak valid.'),
  password: z.string().min(1, 'Kata sandi wajib diisi.').max(200),
});

const googleSchema = z.object({
  idToken: z.string().min(20, 'Token Google tidak valid.'),
  role: z.enum(['worker', 'employer']).default('worker'),
});

const googleJwks = createRemoteJWKSet(
  new URL('https://www.googleapis.com/oauth2/v3/certs'),
);

function findByEmail(db: Db, email: string): UserRow | undefined {
  return db.prepare('SELECT * FROM users WHERE email = ?').get(email) as
    | UserRow
    | undefined;
}

function findById(db: Db, id: string): UserRow | undefined {
  return db.prepare('SELECT * FROM users WHERE id = ?').get(id) as
    | UserRow
    | undefined;
}

function insertUser(
  db: Db,
  values: {
    email: string;
    passwordHash: string | null;
    googleSub: string | null;
    fullName: string;
    displayName: string;
    photoUrl: string | null;
    role: 'worker' | 'employer';
  },
): UserRow {
  const id = newId();
  const timestamp = nowIso();
  db.prepare(
    `INSERT INTO users
      (id, email, password_hash, google_sub, full_name, display_name,
       headline, district, bio, skills, experience, role,
       max_distance_km, min_pay, start_hour, end_hour, photo_url, phone,
       created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, '', '', '', '[]', '[]', ?, 5, 50000, 8, 17, ?, '', ?, ?)`,
  ).run(
    id,
    values.email,
    values.passwordHash,
    values.googleSub,
    values.fullName,
    values.displayName,
    values.role,
    values.photoUrl,
    timestamp,
    timestamp,
  );
  const row = findById(db, id);
  if (row === undefined) throw ApiError.unavailable('Gagal membuat akun.');
  return row;
}

async function issueToken(row: UserRow, secret: string): Promise<string> {
  return signSession({ sub: row.id, role: row.role }, secret);
}

export const authRoutes = new Hono<{ Variables: AppVariables }>();

authRoutes.post('/register', rateLimit('auth'), async (c) => {
  const body = registerSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!body.success) {
    throw ApiError.badRequest(body.error.issues[0]?.message ?? 'Data tidak valid.');
  }
  const db = c.var.db;
  if (findByEmail(db, body.data.email) !== undefined) {
    throw ApiError.conflict('Email sudah terdaftar. Coba masuk saja.');
  }
  const passwordHash = await hashPassword(body.data.password);
  let row: UserRow;
  try {
    row = withTransaction(db, () =>
      insertUser(db, {
        email: body.data.email,
        passwordHash,
        googleSub: null,
        fullName: body.data.fullName,
        displayName: body.data.displayName,
        photoUrl: null,
        role: body.data.role,
      }),
    );
  } catch (error) {
    if (
      error instanceof Error &&
      /UNIQUE constraint failed: users\.email/.test(error.message)
    ) {
      throw ApiError.conflict('Email sudah terdaftar. Coba masuk saja.');
    }
    throw error;
  }
  return c.json(
    { token: await issueToken(row, c.var.env.JWT_SECRET), user: toSelfUser(row) },
    201,
  );
});

authRoutes.post('/login', rateLimit('auth'), async (c) => {
  const body = loginSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!body.success) {
    throw ApiError.badRequest(body.error.issues[0]?.message ?? 'Data tidak valid.');
  }
  const row = findByEmail(c.var.db, body.data.email);
  if (row === undefined || row.password_hash === null) {
    throw ApiError.unauthorized('Email atau kata sandi salah.');
  }
  if (!(await verifyPassword(body.data.password, row.password_hash))) {
    throw ApiError.unauthorized('Email atau kata sandi salah.');
  }
  return c.json({
    token: await issueToken(row, c.var.env.JWT_SECRET),
    user: toSelfUser(row),
  });
});

authRoutes.post('/google', rateLimit('auth'), async (c) => {
  const body = googleSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!body.success) {
    throw ApiError.badRequest(body.error.issues[0]?.message ?? 'Data tidak valid.');
  }
  const clientId = c.var.env.GOOGLE_CLIENT_ID;
  if (clientId === '') {
    throw ApiError.unavailable(
      'Login Google belum dikonfigurasi di server. Pakai email dan kata sandi dulu.',
    );
  }

  let email: string;
  let name: string;
  let picture: string | null;
  let subject: string;
  try {
    const { payload } = await jwtVerify(body.data.idToken, googleJwks, {
      issuer: ['https://accounts.google.com', 'accounts.google.com'],
      audience: clientId,
    });
    if (typeof payload.email !== 'string' || typeof payload.sub !== 'string') {
      throw new Error('klaim tidak lengkap');
    }
    if (payload.email_verified === false) {
      throw new Error('email belum diverifikasi');
    }
    email = payload.email.toLowerCase();
    name = typeof payload.name === 'string' ? payload.name : email;
    picture = typeof payload.picture === 'string' ? payload.picture : null;
    subject = payload.sub;
  } catch {
    throw ApiError.unauthorized('Token Google tidak valid atau kedaluwarsa.');
  }

  const db = c.var.db;
  const existing = db
    .prepare('SELECT * FROM users WHERE google_sub = ? OR email = ?')
    .get(subject, email) as UserRow | undefined;
  if (existing !== undefined) {
    if (existing.email !== email && existing.google_sub !== subject) {
      throw ApiError.conflict('Akun Google tidak cocok dengan email akun ini.');
    }
    const refreshed = withTransaction(db, () => {
      if (existing.google_sub === null) {
        db.prepare(
          'UPDATE users SET google_sub = ?, photo_url = COALESCE(photo_url, ?), updated_at = ? WHERE id = ?',
        ).run(subject, picture, nowIso(), existing.id);
      }
      return findById(db, existing.id)!;
    });
    return c.json({
      token: await issueToken(refreshed, c.var.env.JWT_SECRET),
      user: toSelfUser(refreshed),
    });
  }

  let row: UserRow;
  try {
    row = withTransaction(db, () =>
      insertUser(db, {
        email,
        passwordHash: null,
        googleSub: subject,
        fullName: name,
        displayName: name.split(' ')[0] ?? name,
        photoUrl: picture,
        role: body.data.role,
      }),
    );
  } catch (error) {
    if (
      error instanceof Error &&
      /UNIQUE constraint failed: users\.(email|google_sub)/.test(error.message)
    ) {
      throw ApiError.conflict('Akun Google sudah terhubung ke akun lain.');
    }
    throw error;
  }
  return c.json(
    { token: await issueToken(row, c.var.env.JWT_SECRET), user: toSelfUser(row) },
    201,
  );
});

authRoutes.get('/me', requireAuth, (c) => {
  const row = findById(c.var.db, c.var.userId);
  if (row === undefined) throw ApiError.unauthorized();
  return c.json({ user: toSelfUser(row) });
});
