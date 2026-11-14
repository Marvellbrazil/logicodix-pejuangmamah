import { Hono } from 'hono';
import type { AppVariables } from '../lib/context.ts';

export const healthRoutes = new Hono<{ Variables: AppVariables }>();

healthRoutes.get('/', (c) => {
  const env = c.var.env;
  return c.json({
    ok: true,
    name: 'kerjaqueue-api',
    assistant: env.ZAI_API_KEY !== '',
    google: env.GOOGLE_CLIENT_ID !== '',
    time: new Date().toISOString(),
  });
});
