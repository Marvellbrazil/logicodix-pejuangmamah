import { Hono } from 'hono';
import { z } from 'zod';
import type { AppVariables } from '../lib/context.ts';
import { ApiError } from '../lib/errors.ts';
import { nowIso } from '../lib/ids.ts';
import {
  serializeExperience,
  serializeSkills,
  toSelfUser,
  type UserRow,
} from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';

const experienceSchema = z.object({
  title: z.string().trim().max(80).default(''),
  company: z.string().trim().max(80).default(''),
  period: z.string().trim().max(40).default(''),
  detail: z.string().trim().max(400).default(''),
});

const patchSchema = z
  .object({
    fullName: z.string().trim().min(2, 'Nama lengkap wajib diisi.').max(80),
    displayName: z
      .string()
      .trim()
      .min(1, 'Nama panggilan wajib diisi.')
      .max(40),
    headline: z.string().trim().max(120),
    district: z.string().trim().max(60),
    bio: z.string().trim().max(800),
    skills: z.array(z.string().trim().min(1).max(40)).max(20),
    experience: z.array(experienceSchema).max(10),
    role: z.enum(['worker', 'employer']),
    maxDistanceKm: z.number().min(0).max(100),
    minPay: z.number().int().min(0).max(10_000_000),
    startHour: z.number().int().min(0).max(23),
    endHour: z.number().int().min(1).max(24),
    phone: z.string().trim().max(30),
    photoUrl: z.string().trim().url().max(500).nullable(),
  })
  .partial();

function loadUser(db: { prepare: (sql: string) => { get: (...a: unknown[]) => unknown } }, id: string): UserRow {
  const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as
    | UserRow
    | undefined;
  if (row === undefined) throw ApiError.notFound('Pengguna tidak ditemukan.');
  return row;
}

export const meRoutes = new Hono<{ Variables: AppVariables }>();

meRoutes.use('*', requireAuth);

meRoutes.get('/', (c) => {
  const db = c.var.db;
  const row = loadUser(db, c.var.userId);
  const counts = db
    .prepare(
      `SELECT
         (SELECT COUNT(*) FROM applications WHERE worker_id = ?) AS applications,
         (SELECT COUNT(*) FROM jobs WHERE employer_id = ?) AS jobs,
         (SELECT COUNT(*) FROM chats WHERE worker_id = ? OR employer_id = ?) AS chats`,
    )
    .get(row.id, row.id, row.id, row.id) as {
    applications: number;
    jobs: number;
    chats: number;
  };
  return c.json({
    user: toSelfUser(row),
    stats: {
      applications: Number(counts.applications),
      jobs: Number(counts.jobs),
      chats: Number(counts.chats),
    },
  });
});

meRoutes.patch('/', async (c) => {
  const parsed = patchSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!parsed.success) {
    throw ApiError.badRequest(parsed.error.issues[0]?.message ?? 'Data tidak valid.');
  }
  const db = c.var.db;
  const row = loadUser(db, c.var.userId);
  const input = parsed.data;

  if (input.startHour !== undefined && input.endHour !== undefined) {
    if (input.endHour <= input.startHour) {
      throw ApiError.badRequest('Jam selesai harus setelah jam mulai.');
    }
  }

  const next = {
    full_name: input.fullName ?? row.full_name,
    display_name: input.displayName ?? row.display_name,
    headline: input.headline ?? row.headline,
    district: input.district ?? row.district,
    bio: input.bio ?? row.bio,
    skills:
      input.skills === undefined
        ? row.skills
        : serializeSkills([...new Set(input.skills)]),
    experience:
      input.experience === undefined
        ? row.experience
        : serializeExperience(input.experience),
    role: input.role ?? row.role,
    max_distance_km: input.maxDistanceKm ?? row.max_distance_km,
    min_pay: input.minPay ?? row.min_pay,
    start_hour: input.startHour ?? row.start_hour,
    end_hour: input.endHour ?? row.end_hour,
    phone: input.phone ?? row.phone,
    photo_url: input.photoUrl === undefined ? row.photo_url : input.photoUrl,
  };

  db.prepare(
    `UPDATE users SET
       full_name = ?, display_name = ?, headline = ?, district = ?, bio = ?,
       skills = ?, experience = ?, role = ?, max_distance_km = ?, min_pay = ?,
       start_hour = ?, end_hour = ?, phone = ?, photo_url = ?, updated_at = ?
     WHERE id = ?`,
  ).run(
    next.full_name,
    next.display_name,
    next.headline,
    next.district,
    next.bio,
    next.skills,
    next.experience,
    next.role,
    next.max_distance_km,
    next.min_pay,
    next.start_hour,
    next.end_hour,
    next.phone,
    next.photo_url,
    nowIso(),
    row.id,
  );

  return c.json({ user: toSelfUser(loadUser(db, row.id)) });
});
