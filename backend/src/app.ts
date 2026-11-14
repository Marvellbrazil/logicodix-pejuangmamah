import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { secureHeaders } from 'hono/secure-headers';
import { bodyLimit } from 'hono/body-limit';
import { logger } from 'hono/logger';
import type { AppVariables } from './lib/context.ts';
import { ApiError } from './lib/errors.ts';
import { RateLimiter } from './lib/ratelimit.ts';
import type { Db } from './db/client.ts';
import type { Env } from './env.ts';
import { corsOrigins } from './env.ts';
import { errorHandler, notFoundHandler } from './middleware/error.ts';
import { requireAuth } from './middleware/auth.ts';
import { authRoutes } from './routes/auth.ts';
import { meRoutes } from './routes/me.ts';
import { jobRoutes } from './routes/jobs.ts';
import { applicationRoutes, applyRoutes } from './routes/applications.ts';
import { chatRoutes } from './routes/chats.ts';
import { assistantRoutes } from './routes/assistant.ts';
import { healthRoutes } from './routes/health.ts';
import { userRoutes } from './routes/users.ts';

export function createApp(db: Db, env: Env): Hono<{ Variables: AppVariables }> {
  const app = new Hono<{ Variables: AppVariables }>();
  const authLimiter = new RateLimiter(env.AUTH_ATTEMPT_LIMIT, 15 * 60_000);
  const assistantLimiter = new RateLimiter(
    env.ASSISTANT_DAILY_LIMIT,
    24 * 60 * 60_000,
  );

  app.use('*', async (c, next) => {
    c.set('db', db);
    c.set('env', env);
    c.set('authLimiter', authLimiter);
    c.set('assistantLimiter', assistantLimiter);
    await next();
  });

  if (env.NODE_ENV !== 'test') {
    app.use('*', logger());
  }
  app.use('*', secureHeaders());
  app.use(
    '*',
    cors({
      origin: (origin) => {
        if (origin === undefined || origin === '') return undefined;
        const allowed = corsOrigins(env);
        return allowed.includes(origin) ? origin : undefined;
      },
      allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
      allowHeaders: ['content-type', 'authorization'],
      maxAge: 86_400,
    }),
  );
  app.use(
    '/api/*',
    bodyLimit({
      maxSize: 256 * 1024,
      onError: () => {
        throw ApiError.badRequest('Permintaan terlalu besar.', 'payload_too_large');
      },
    }),
  );

  app.onError(errorHandler);
  app.notFound(notFoundHandler);

  app.route('/health', healthRoutes);

  const api = new Hono<{ Variables: AppVariables }>();
  api.route('/auth', authRoutes);
  api.route('/me', meRoutes);
  api.route('/jobs', jobRoutes);
  api.route('/jobs', applyRoutes);
  api.route('/applications', applicationRoutes);
  api.route('/chats', chatRoutes);
  api.route('/users', userRoutes);
  api.route('/assistant', assistantRoutes);
  api.get('/session', requireAuth, (c) =>
    c.json({ userId: c.var.userId, role: c.var.session.role }),
  );

  app.route('/api', api);

  return app;
}
