import { createMiddleware } from 'hono/factory';
import { ApiError } from '../lib/errors.ts';
import type { AppVariables } from '../lib/context.ts';

export function rateLimit(name: 'auth' | 'assistant') {
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const limiter =
      name === 'auth' ? c.var.authLimiter : c.var.assistantLimiter;
    const key = `${name}:${clientKey(c)}`;
    const result = limiter.hit(key);
    if (!result.allowed) {
      c.header('retry-after', String(result.retryAfterSeconds));
      throw ApiError.tooMany();
    }
    await next();
  });
}

function clientKey(c: { req: { header: (name: string) => string | undefined } }) {
  const forwarded = c.req.header('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0]!.trim();
  return c.req.header('cf-connecting-ip') ?? 'local';
}
