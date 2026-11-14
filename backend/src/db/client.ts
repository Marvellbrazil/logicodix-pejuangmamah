import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

export type Db = DatabaseSync;

export function openDb(path: string): Db {
  if (path !== ':memory:') {
    mkdirSync(dirname(path), { recursive: true });
  }
  const db = new DatabaseSync(path);
  db.exec('PRAGMA journal_mode = WAL;');
  db.exec('PRAGMA foreign_keys = ON;');
  db.exec('PRAGMA busy_timeout = 5000;');
  return db;
}

export function migrate(db: Db): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT,
      google_sub TEXT UNIQUE,
      full_name TEXT NOT NULL DEFAULT '',
      display_name TEXT NOT NULL DEFAULT '',
      headline TEXT NOT NULL DEFAULT '',
      district TEXT NOT NULL DEFAULT '',
      bio TEXT NOT NULL DEFAULT '',
      skills TEXT NOT NULL DEFAULT '[]',
      experience TEXT NOT NULL DEFAULT '[]',
      role TEXT NOT NULL DEFAULT 'worker'
        CHECK (role IN ('worker', 'employer')),
      max_distance_km REAL NOT NULL DEFAULT 5,
      min_pay INTEGER NOT NULL DEFAULT 50000,
      start_hour INTEGER NOT NULL DEFAULT 8,
      end_hour INTEGER NOT NULL DEFAULT 17,
      photo_url TEXT,
      phone TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      employer_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      company TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      pay INTEGER NOT NULL,
      pay_period TEXT NOT NULL,
      district TEXT NOT NULL,
      distance_km REAL NOT NULL,
      start_hour INTEGER NOT NULL,
      end_hour INTEGER NOT NULL,
      urgency TEXT NOT NULL
        CHECK (urgency IN ('today', 'thisWeek', 'flexible')),
      skills TEXT NOT NULL DEFAULT '[]',
      contact TEXT NOT NULL DEFAULT '',
      filled INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS jobs_created ON jobs (created_at DESC);
    CREATE INDEX IF NOT EXISTS jobs_employer ON jobs (employer_id);

    CREATE TABLE IF NOT EXISTS applications (
      id TEXT PRIMARY KEY,
      job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
      worker_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      status TEXT NOT NULL DEFAULT 'sent'
        CHECK (status IN ('sent', 'viewed', 'interview', 'accepted', 'rejected', 'withdrawn')),
      note TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE (job_id, worker_id)
    );
    CREATE INDEX IF NOT EXISTS applications_worker ON applications (worker_id);
    CREATE INDEX IF NOT EXISTS applications_job ON applications (job_id);

    CREATE TABLE IF NOT EXISTS chats (
      id TEXT PRIMARY KEY,
      job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
      application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
      worker_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      employer_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE (application_id)
    );
    CREATE INDEX IF NOT EXISTS chats_worker ON chats (worker_id);
    CREATE INDEX IF NOT EXISTS chats_employer ON chats (employer_id);

    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      chat_id TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
      sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      body TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS messages_chat ON messages (chat_id, created_at, id);

    CREATE TABLE IF NOT EXISTS chat_reads (
      chat_id TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      last_read_at TEXT NOT NULL,
      PRIMARY KEY (chat_id, user_id)
    );

    CREATE TABLE IF NOT EXISTS assistant_usage (
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      day TEXT NOT NULL,
      count INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, day)
    );
  `);
}
