import { randomUUID } from 'node:crypto';
import type { Db } from './client.ts';

export function withTransaction<T>(db: Db, action: () => T): T {
  const name = `sp_${randomUUID().replaceAll('-', '')}`;
  const nested = db.isTransaction;
  if (nested) {
    db.exec(`SAVEPOINT ${name}`);
  } else {
    db.exec('BEGIN IMMEDIATE');
  }
  try {
    const result = action();
    if (nested) {
      db.exec(`RELEASE SAVEPOINT ${name}`);
    } else {
      db.exec('COMMIT');
    }
    return result;
  } catch (error) {
    if (nested) {
      db.exec(`ROLLBACK TO SAVEPOINT ${name}`);
      db.exec(`RELEASE SAVEPOINT ${name}`);
    } else {
      db.exec('ROLLBACK');
    }
    throw error;
  }
}
