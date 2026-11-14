import { randomBytes, randomUUID } from 'node:crypto';

export function newId(): string {
  return randomUUID();
}

export function newToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

export function nowIso(): string {
  return new Date().toISOString();
}
