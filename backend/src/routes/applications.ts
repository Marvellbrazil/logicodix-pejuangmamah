import { Hono } from 'hono';
import { z } from 'zod';
import type { AppVariables } from '../lib/context.ts';
import { ApiError } from '../lib/errors.ts';
import { newId, nowIso } from '../lib/ids.ts';
import {
  toJobDto,
  type ApplicationRow,
  type ChatRow,
  type JobRow,
  type UserRow,
} from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';
import { requireRole } from '../middleware/role.ts';
import { withTransaction } from '../db/transaction.ts';

const statusSchema = z.object({
  status: z.enum(['sent', 'viewed', 'interview', 'accepted', 'rejected', 'withdrawn']),
});

const EMPLOYER_STATUSES = new Set(['viewed', 'interview', 'accepted', 'rejected']);

type ApplicationWithJob = ApplicationRow & {
  title: string;
  company: string;
  category: string;
  pay: number;
  pay_period: string;
  district: string;
  urgency: JobRow['urgency'];
  filled: number;
  employer_id: string;
  employer_name: string;
  employer_display: string;
  employer_photo: string | null;
  chat_id: string | null;
};

function applicationRows(
  db: {
    prepare: (sql: string) => { all: (...a: unknown[]) => unknown[] };
  },
  sql: string,
  ...params: unknown[]
): ApplicationWithJob[] {
  return db.prepare(sql).all(...params) as ApplicationWithJob[];
}

function shapeApplication(row: ApplicationWithJob) {
  return {
    id: row.id,
    status: row.status,
    note: row.note,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    chatId: row.chat_id,
    job: {
      id: row.job_id,
      title: row.title,
      company: row.company,
      category: row.category,
      pay: row.pay,
      payPeriod: row.pay_period,
      district: row.district,
      urgency: row.urgency,
      filled: row.filled === 1,
      employerId: row.employer_id,
      employerName: row.employer_name,
      employerDisplayName: row.employer_display,
      employerPhotoUrl: row.employer_photo,
    },
  };
}

const APPLICATION_SELECT = `
  SELECT a.*, j.title, j.company, j.category, j.pay, j.pay_period, j.district,
         j.urgency, j.filled, j.employer_id,
         u.full_name AS employer_name, u.display_name AS employer_display,
         u.photo_url AS employer_photo, c.id AS chat_id
    FROM applications a
    JOIN jobs j ON j.id = a.job_id
    JOIN users u ON u.id = j.employer_id
    LEFT JOIN chats c ON c.application_id = a.id
`;

export const applicationRoutes = new Hono<{ Variables: AppVariables }>();

applicationRoutes.use('*', requireAuth);

applicationRoutes.get('/mine', requireRole('worker'), (c) => {
  const rows = applicationRows(
    c.var.db,
    `${APPLICATION_SELECT} WHERE a.worker_id = ? ORDER BY a.created_at DESC`,
    c.var.userId,
  );
  return c.json({ applications: rows.map(shapeApplication) });
});

applicationRoutes.get('/inbox', requireRole('employer'), (c) => {
  const rows = applicationRows(
    c.var.db,
    `${APPLICATION_SELECT} WHERE j.employer_id = ? ORDER BY a.created_at DESC`,
    c.var.userId,
  );
  return c.json({ applications: rows.map(shapeApplication) });
});

applicationRoutes.patch('/:id', async (c) => {
  const parsed = statusSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!parsed.success) throw ApiError.badRequest('Status tidak valid.');

  const db = c.var.db;
  const row = db
    .prepare('SELECT * FROM applications WHERE id = ?')
    .get(c.req.param('id')) as ApplicationRow | undefined;
  if (row === undefined) throw ApiError.notFound('Lamaran tidak ditemukan.');

  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(row.job_id) as JobRow;
  const isWorker = row.worker_id === c.var.userId;
  const isEmployer = job.employer_id === c.var.userId;

  if (!isWorker && !isEmployer) {
    throw ApiError.forbidden('Kamu tidak terlibat di lamaran ini.');
  }
  if (isWorker && parsed.data.status !== 'withdrawn') {
    throw ApiError.forbidden('Pencari kerja hanya bisa menarik lamaran.');
  }
  if (isEmployer && !EMPLOYER_STATUSES.has(parsed.data.status)) {
    throw ApiError.forbidden('Status itu bukan wewenang pemberi kerja.');
  }
  if (isWorker && row.status !== 'sent') {
    throw ApiError.conflict('Lamaran yang sudah diproses tidak bisa ditarik.');
  }
  if (isEmployer) {
    const allowedNext: Record<ApplicationRow['status'], ApplicationRow['status'][]> = {
      sent: ['viewed', 'rejected'],
      viewed: ['interview', 'accepted', 'rejected'],
      interview: ['accepted', 'rejected'],
      accepted: [],
      rejected: [],
      withdrawn: [],
    };
    if (!allowedNext[row.status].includes(parsed.data.status)) {
      throw ApiError.conflict('Transisi status lamaran tidak valid.');
    }
  }

  db.prepare('UPDATE applications SET status = ?, updated_at = ? WHERE id = ?').run(
    parsed.data.status,
    nowIso(),
    row.id,
  );
  if (parsed.data.status === 'accepted') {
    db.prepare('UPDATE jobs SET filled = 1, updated_at = ? WHERE id = ?').run(
      nowIso(),
      job.id,
    );
  }

  const refreshed = applicationRows(
    db,
    `${APPLICATION_SELECT} WHERE a.id = ?`,
    row.id,
  )[0];
  return c.json({ application: shapeApplication(refreshed) });
});

export const applyRoutes = new Hono<{ Variables: AppVariables }>();

applyRoutes.use('*', requireAuth);
applyRoutes.use('*', requireRole('worker'));

applyRoutes.post('/:id/apply', (c) => {
  const db = c.var.db;
  const job = db
    .prepare('SELECT * FROM jobs WHERE id = ?')
    .get(c.req.param('id')) as JobRow | undefined;
  if (job === undefined) throw ApiError.notFound('Lowongan tidak ditemukan.');
  if (job.filled === 1) {
    throw ApiError.conflict('Lowongan ini sudah terisi.');
  }
  if (job.employer_id === c.var.userId) {
    throw ApiError.badRequest('Kamu tidak bisa melamar lowongan milikmu sendiri.');
  }
  const account = db
    .prepare('SELECT role FROM users WHERE id = ?')
    .get(c.var.userId) as { role: string } | undefined;
  if (account?.role !== 'worker') {
    throw ApiError.forbidden('Hanya pencari kerja yang bisa melamar lowongan.');
  }

  const existing = db
    .prepare('SELECT * FROM applications WHERE job_id = ? AND worker_id = ?')
    .get(job.id, c.var.userId) as ApplicationRow | undefined;
  if (existing !== undefined) {
    const chat = db
      .prepare('SELECT * FROM chats WHERE application_id = ?')
      .get(existing.id) as ChatRow | undefined;
    const refreshed = applicationRows(
      db,
      `${APPLICATION_SELECT} WHERE a.id = ?`,
      existing.id,
    )[0];
    return c.json(
      { application: shapeApplication(refreshed), chatId: chat?.id ?? null },
      200,
    );
  }

  const { applicationId, chatId } = withTransaction(db, () => {
    const timestamp = nowIso();
    const applicationId = newId();
    const chatId = newId();
    db.prepare(
      `INSERT INTO applications (id, job_id, worker_id, status, note, created_at, updated_at)
       VALUES (?, ?, ?, 'sent', '', ?, ?)`,
    ).run(applicationId, job.id, c.var.userId, timestamp, timestamp);
    db.prepare(
      `INSERT INTO chats (id, job_id, application_id, worker_id, employer_id, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    ).run(
      chatId,
      job.id,
      applicationId,
      c.var.userId,
      job.employer_id,
      timestamp,
      timestamp,
    );
    db.prepare(
      `INSERT INTO messages (id, chat_id, sender_id, body, created_at)
       VALUES (?, ?, ?, ?, ?)`,
    ).run(
      newId(),
      chatId,
      c.var.userId,
      `Halo, saya berminat untuk "${job.title}". Apakah masih tersedia?`,
      timestamp,
    );
    return { applicationId, chatId };
  });

  const refreshed = applicationRows(
    db,
    `${APPLICATION_SELECT} WHERE a.id = ?`,
    applicationId,
  )[0];
  const employer = db
    .prepare('SELECT * FROM users WHERE id = ?')
    .get(job.employer_id) as UserRow | undefined;
  return c.json(
    {
      application: shapeApplication(refreshed),
      chatId,
      job: toJobDto(job, employer, { id: applicationId, status: 'sent' }, 1),
    },
    201,
  );
});
