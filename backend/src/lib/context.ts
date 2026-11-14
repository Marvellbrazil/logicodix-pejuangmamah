import type { Context } from 'hono';
import type { Db } from '../db/client.ts';
import type { Env } from '../env.ts';
import type { RateLimiter } from '../lib/ratelimit.ts';
import type { SessionClaims } from '../lib/jwt.ts';

export type AppVariables = {
  db: Db;
  env: Env;
  session: SessionClaims;
  userId: string;
  authLimiter: RateLimiter;
  assistantLimiter: RateLimiter;
};

export type AppContext = Context<{ Variables: AppVariables }>;
