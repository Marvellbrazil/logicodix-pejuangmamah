import { Hono } from 'hono';
import { z } from 'zod';
import type { AppVariables } from '../lib/context.ts';
import { ApiError } from '../lib/errors.ts';
import { newId, nowIso } from '../lib/ids.ts';
import type {
  ChatRow,
  MessageRow,
} from '../db/types.ts';
import { requireAuth } from '../middleware/auth.ts';

const sendSchema = z.object({
  body: z.string().trim().min(1, 'Pesan tidak boleh kosong.').max(2000),
});

type ChatSummaryRow = ChatRow & {
  title: string;
  company: string;
  worker_name: string;
  worker_display: string;
  worker_photo: string | null;
  employer_name: string;
  employer_display: string;
  employer_photo: string | null;
  last_body: string | null;
  last_at: string | null;
  last_sender: string | null;
  unread: number;
};

function summary(
  db: {
    prepare: (sql: string) => { all: (...a: unknown[]) => unknown[] };
  },
  viewerId: string,
  chatId?: string,
): ChatSummaryRow[] {
  const filter = chatId === undefined ? '' : 'AND c.id = ?';
  const params: unknown[] = [viewerId, viewerId, viewerId, viewerId];
  if (chatId !== undefined) params.push(chatId);
  return db
    .prepare(
      `SELECT c.*, j.title, j.company,
              w.full_name AS worker_name, w.display_name AS worker_display,
              w.photo_url AS worker_photo,
              e.full_name AS employer_name, e.display_name AS employer_display,
              e.photo_url AS employer_photo,
              (SELECT body FROM messages WHERE chat_id = c.id
                ORDER BY created_at DESC LIMIT 1) AS last_body,
              (SELECT created_at FROM messages WHERE chat_id = c.id
                ORDER BY created_at DESC LIMIT 1) AS last_at,
              (SELECT sender_id FROM messages WHERE chat_id = c.id
                ORDER BY created_at DESC LIMIT 1) AS last_sender,
              (SELECT COUNT(*) FROM messages m
                WHERE m.chat_id = c.id
                  AND m.sender_id <> ?
                  AND m.created_at > COALESCE(
                    (SELECT last_read_at FROM chat_reads
                      WHERE chat_id = c.id AND user_id = ?), '')) AS unread
         FROM chats c
         JOIN jobs j ON j.id = c.job_id
         JOIN users w ON w.id = c.worker_id
         JOIN users e ON e.id = c.employer_id
        WHERE (c.worker_id = ? OR c.employer_id = ?) ${filter}
        ORDER BY COALESCE(last_at, c.created_at) DESC, c.id DESC`,
    )
    .all(...params) as ChatSummaryRow[];
}

function party(
  row: ChatSummaryRow,
  viewerId: string,
):
  | { id: string; fullName: string; displayName: string; photoUrl: string | null }
  | null {
  const otherIsWorker = row.employer_id === viewerId;
  const id = otherIsWorker ? row.worker_id : row.employer_id;
  if (otherIsWorker) {
    return {
      id,
      fullName: row.worker_name,
      displayName: row.worker_display,
      photoUrl: row.worker_photo,
    };
  }
  return {
    id,
    fullName: row.employer_name,
    displayName: row.employer_display,
    photoUrl: row.employer_photo,
  };
}

function shapeSummary(row: ChatSummaryRow, viewerId: string) {
  return {
    id: row.id,
    jobId: row.job_id,
    applicationId: row.application_id,
    jobTitle: row.title,
    company: row.company,
    counterpart: party(row, viewerId),
    lastMessage: row.last_body,
    lastMessageAt: row.last_at ?? row.created_at,
    lastSenderId: row.last_sender,
    unread: Number(row.unread),
  };
}

function assertMember(db: {
  prepare: (sql: string) => { get: (...a: unknown[]) => unknown };
}, chatId: string, viewerId: string): ChatRow {
  const chat = db.prepare('SELECT * FROM chats WHERE id = ?').get(chatId) as
    | ChatRow
    | undefined;
  if (chat === undefined) throw ApiError.notFound('Percakapan tidak ditemukan.');
  if (chat.worker_id !== viewerId && chat.employer_id !== viewerId) {
    throw ApiError.forbidden('Kamu bukan bagian dari percakapan ini.');
  }
  return chat;
}

export const chatRoutes = new Hono<{ Variables: AppVariables }>();

chatRoutes.use('*', requireAuth);

chatRoutes.get('/', (c) => {
  const rows = summary(c.var.db, c.var.userId);
  return c.json({
    chats: rows.map((row) => shapeSummary(row, c.var.userId)),
    unread: rows.reduce((total, row) => total + Number(row.unread), 0),
  });
});

chatRoutes.get('/:id/messages', (c) => {
  const db = c.var.db;
  const chat = assertMember(db, c.req.param('id'), c.var.userId);
  const messages = db
    .prepare(
      `SELECT * FROM messages WHERE chat_id = ? ORDER BY created_at ASC LIMIT 200`,
    )
    .all(chat.id) as MessageRow[];
  const [chatSummary] = summary(db, c.var.userId, chat.id);
  return c.json({
    chat: chatSummary === undefined ? null : shapeSummary(chatSummary, c.var.userId),
    messages: messages.map((row) => ({
      id: row.id,
      chatId: row.chat_id,
      senderId: row.sender_id,
      body: row.body,
      createdAt: row.created_at,
      mine: row.sender_id === c.var.userId,
    })),
  });
});

chatRoutes.post('/:id/messages', async (c) => {
  const parsed = sendSchema.safeParse(await c.req.json().catch(() => ({})));
  if (!parsed.success) {
    throw ApiError.badRequest(parsed.error.issues[0]?.message ?? 'Pesan tidak valid.');
  }
  const db = c.var.db;
  const chat = assertMember(db, c.req.param('id'), c.var.userId);
  const id = newId();
  const timestamp = nowIso();
  db.prepare(
    'INSERT INTO messages (id, chat_id, sender_id, body, created_at) VALUES (?, ?, ?, ?, ?)',
  ).run(id, chat.id, c.var.userId, parsed.data.body, timestamp);
  db.prepare('UPDATE chats SET updated_at = ? WHERE id = ?').run(timestamp, chat.id);
  return c.json(
    {
      message: {
        id,
        chatId: chat.id,
        senderId: c.var.userId,
        body: parsed.data.body,
        createdAt: timestamp,
        mine: true,
      },
    },
    201,
  );
});

chatRoutes.post('/:id/read', (c) => {
  const db = c.var.db;
  const chat = assertMember(db, c.req.param('id'), c.var.userId);
  const timestamp = nowIso();
  db.prepare(
    `INSERT INTO chat_reads (chat_id, user_id, last_read_at) VALUES (?, ?, ?)
     ON CONFLICT (chat_id, user_id) DO UPDATE SET last_read_at = excluded.last_read_at`,
  ).run(chat.id, c.var.userId, timestamp);
  return c.json({ ok: true, readAt: timestamp });
});
