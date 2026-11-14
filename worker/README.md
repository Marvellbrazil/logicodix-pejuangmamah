# Worker Asisten Kerjaqueue

Proxy tipis ke Z.ai supaya API key tidak ikut ke dalam APK.

## Cara pasang

1. Revoke any Z.ai API key that was pasted into chat; generate a replacement.
2. Deploy Worker:

```bash
npm install -g wrangler
wrangler login
cd worker
wrangler secret put ZAI_API_KEY
wrangler secret put CLIENT_KEY
wrangler deploy
```

Set `ZAI_API_KEY` to the newly generated key directly in Wrangler's prompt. Do not put it in `.env`, Dart defines, build args, or source files. `CLIENT_KEY` is a separate random gate value; set the same value at build with `--dart-define=ASSISTANT_CLIENT_KEY=...`.

After deploy, use the printed Worker URL for `--dart-define=ASSISTANT_ENDPOINT=https://...`.

The Worker calls the standard Z.ai chat completions endpoint:
`https://api.z.ai/api/paas/v4/chat/completions`. The configured model is `glm-4.7-flash`, which the Z.ai pricing page lists as free. Confirm the model ID is enabled for your API account; pricing documentation does not guarantee endpoint availability.

## Flutter build

```bash
flutter run --dart-define=ASSISTANT_ENDPOINT=https://<worker>.workers.dev --dart-define=ASSISTANT_CLIENT_KEY=<client-gate>
```

## Contract

Request:

```json
{
  "system": "instructions for model",
  "messages": [{ "role": "user", "text": "hello" }]
}
```

Success response: `{ "reply": "..." }`. Errors return 4xx/5xx with `{ "error": "..." }`.

## Limits and security

`CLIENT_KEY` is compiled into the app, so it can be extracted and is not a security boundary. Apply Cloudflare rate limits and budget alerts. The provider key must only exist in Worker secret storage. Without an endpoint, the app uses local assistant answers.
