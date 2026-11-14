import { Hono } from 'hono';
import type { AppVariables } from '../lib/context.ts';
import { ApiError } from '../lib/errors.ts';
import {
  toPublicUser,
  type JobRow,
  type UserRow,
} from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';

export const userRoutes = new Hono<{ Variables: AppVariables }>();

userRoutes.use('*', requireAuth);

userRoutes.get('/', (c) => {
  const q = (c.req.query('q') ?? '').trim();
  const role = (c.req.query('role') ?? '').trim();
  const clauses: string[] = ["id <> ?"];
  const params: unknown[] = [c.var.userId];

  if (q !== '') {
    clauses.push('(full_name LIKE ? OR display_name LIKE ? OR headline LIKE ? OR district LIKE ?)');
    const like = `%${q}%`;
    params.push(like, like, like, like);
  }
  if (role === 'worker' || role === 'employer') {
    clauses.push('role = ?');
    params.push(role);
  }

  const rows = c.var.db
    .prepare(
      `SELECT * FROM users WHERE ${clauses.join(' AND ')} ORDER BY full_name LIMIT 30`,
    )
    .all(...params) as UserRow[];

  return c.json({
    people: rows.map((row) => ({
      ...toPublicUser(row),
      openJobs: Number(
        (
          c.var.db
            .prepare('SELECT COUNT(*) AS total FROM jobs WHERE employer_id = ? AND filled = 0')
            .get(row.id) as { total: number }
        ).total,
      ),
    })),
  });
});

userRoutes.get('/:id', (c) => {
  const db = c.var.db;
  const row = db
    .prepare('SELECT * FROM users WHERE id = ?')
    .get(c.req.param('id')) as UserRow | undefined;
  if (row === undefined) throw ApiError.notFound('Pengguna tidak ditemukan.');

  const jobs = db
    .prepare(
      'SELECT * FROM jobs WHERE employer_id = ? AND filled = 0 ORDER BY created_at DESC LIMIT 10',
    )
    .all(row.id) as JobRow[];

  return c.json({
    user: toPublicUser(row),
    openJobs: jobs.map((job) => ({
      id: job.id,
      title: job.title,
      company: job.company,
      category: job.category,
      pay: job.pay,
      payPeriod: job.pay_period,
      district: job.district,
      urgency: job.urgency,
      createdAt: job.created_at,
    })),
  });
});
