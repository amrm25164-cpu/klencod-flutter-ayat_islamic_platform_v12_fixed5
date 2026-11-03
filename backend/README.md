# AYAT Secure Gateway (V6)

Node.js 20+ gateway for private integrations. It keeps provider credentials on the server, not in the Flutter APK.

## Included routes

- `GET /health` — liveness check.
- `GET /api/status` — protected capability status (does not expose secrets).
- `POST /api/assistant/ask` — protected OpenAI Responses API integration. Returns generated text clearly labelled as AI output; `sources` is empty until a real retrieval provider is wired in. It does not pretend that generation is sourced research.
- `GET /api/hadith/search?q=...` — protected adapter for a separately licensed/authorized hadith provider. It returns 503 until `HADITH_PROVIDER_URL` is configured; it never fabricates a hadith or grading.

## Local run

```bash
cp .env.example .env
# Edit .env; create a long random AYAT_APP_TOKEN and optionally set OPENAI_API_KEY.
npm install
npm start
```

Flutter run example:

```bash
flutter run \
  --dart-define=AYAT_API_BASE_URL=https://your-host.example/api \
  --dart-define=AYAT_APP_TOKEN=your-app-token
```

The app token shipped in a mobile binary can be extracted. It is a basic integration gate, **not strong user authentication**. A public production deployment should add user accounts, short-lived signed tokens, abuse controls, per-user quotas, monitoring, TLS, and preferably platform attestation. Never treat a shared embedded token as secret.

## Provider setup

`OPENAI_API_KEY` and `HADITH_PROVIDER_TOKEN` belong only in server environment secrets. Never commit `.env`. The hadith adapter expects the configured upstream to accept `?q=` and return either an array or `{ "results": [...] }` with source-provided text, reference, grade, narrator and URL fields. Verify the provider's licence, terms, completeness and grading provenance before enabling it. The ChatGPT HadithDB connector is not itself a public REST endpoint for this app.

The AI assistant is not a mufti. Do not use generated output as a religious ruling. For source-grounded answers, add a retrieval layer that fetches and verifies original Quran/hadith/book passages, then pass those passages to the model and return their actual citations. Do not populate `sources` with invented references.

## Deployment

Use a managed Node host or Docker. Set `NODE_ENV=production`, a strict `CORS_ORIGINS` list, TLS, a strong random token, and provider secrets in the host's secret manager. Add persistent user authentication before public release. `Dockerfile` is included.
