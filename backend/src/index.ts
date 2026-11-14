import { serve } from '@hono/node-server';
import { createApp } from './app.ts';
import { migrate, openDb } from './db/client.ts';
import { readEnv } from './env.ts';
import { seed } from './db/seed.ts';

const env = readEnv();
const db = openDb(env.DATABASE_PATH);
migrate(db);
if (env.SEED) {
  await seed(db, { demoPassword: env.DEMO_PASSWORD });
}

const app = createApp(db, env);

serve({ fetch: app.fetch, port: env.PORT, hostname: env.HOST }, (info) => {
  console.log(
    `kerjaqueue-api listening on http://${info.address}:${info.port} (${env.NODE_ENV})`,
  );
});

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    db.close();
    process.exit(0);
  });
}
