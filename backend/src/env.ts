import { z } from 'zod';

const schema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(8080),
  HOST: z.string().default('0.0.0.0'),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_PATH: z.string().default('./data/kerjaqueue.db'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET minimal 32 karakter'),
  APP_ORIGINS: z.string().default('http://localhost:3000'),
  GOOGLE_CLIENT_ID: z.string().default(''),
  ZAI_API_KEY: z.string().default(''),
  ZAI_MODEL: z.string().default('glm-4.7-flash'),
  ZAI_URL: z
    .string()
    .default('https://api.z.ai/api/paas/v4/chat/completions'),
  ASSISTANT_DAILY_LIMIT: z.coerce.number().int().min(1).default(60),
  AUTH_ATTEMPT_LIMIT: z.coerce.number().int().min(1).default(10),
  SEED: z
    .string()
    .default('true')
    .transform((value) => value !== 'false'),
  DEMO_PASSWORD: z.string().default(''),
});

export type Env = z.infer<typeof schema>;

export function readEnv(
  source: Record<string, string | undefined> = process.env,
): Env {
  const parsed = schema.safeParse(source);
  if (!parsed.success) {
    const detail = parsed.error.issues
      .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
      .join('; ');
    throw new Error(`Konfigurasi tidak valid — ${detail}`);
  }
  return parsed.data;
}

export function corsOrigins(env: Env): string[] {
  return env.APP_ORIGINS.split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}
