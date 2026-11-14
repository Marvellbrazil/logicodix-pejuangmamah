import type { ErrorHandler, NotFoundHandler } from 'hono';
import { ApiError } from '../lib/errors.ts';

export const errorHandler: ErrorHandler = (error, c) => {
  if (error instanceof ApiError) {
    return c.json(
      { error: { code: error.code, message: error.message } },
      error.status as 400,
    );
  }
  const isProduction = process.env.NODE_ENV === 'production';
  console.error('[api] unhandled', error);
  return c.json(
    {
      error: {
        code: 'internal_error',
        message: isProduction
          ? 'Terjadi kesalahan pada server.'
          : String(error instanceof Error ? error.message : error),
      },
    },
    500,
  );
};

export const notFoundHandler: NotFoundHandler = (c) =>
  c.json(
    { error: { code: 'not_found', message: 'Endpoint tidak ditemukan.' } },
    404,
  );
