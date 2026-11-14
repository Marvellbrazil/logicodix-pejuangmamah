import { createMiddleware } from 'hono/factory';
import { ApiError } from '../lib/errors.ts';
import type { AppVariables } from '../lib/context.ts';

export function requireRole(role: 'worker' | 'employer') {
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const user = c.var.db
      .prepare('SELECT role FROM users WHERE id = ?')
      .get(c.var.userId) as { role: string } | undefined;
    if (user?.role !== role) {
      throw ApiError.forbidden(
        role === 'employer'
          ? 'Fitur ini hanya untuk pemberi kerja.'
          : 'Fitur ini hanya untuk pencari kerja.',
      );
    }
    await next();
  });
}
