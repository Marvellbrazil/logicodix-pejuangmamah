import { createMiddleware } from 'hono/factory';
import { ApiError } from '../lib/errors.ts';
import { verifySession } from '../lib/jwt.ts';
import type { AppVariables } from '../lib/context.ts';

export const requireAuth = createMiddleware<{ Variables: AppVariables }>(
  async (c, next) => {
    const header = c.req.header('authorization') ?? '';
    const [scheme, token] = header.split(' ');
    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      throw ApiError.unauthorized('Header Authorization Bearer wajib diisi.');
    }
    const claims = await verifySession(token, c.var.env.JWT_SECRET);
    if (claims === null) {
      throw ApiError.unauthorized();
    }
    c.set('session', claims);
    c.set('userId', claims.sub);
    await next();
  },
);
