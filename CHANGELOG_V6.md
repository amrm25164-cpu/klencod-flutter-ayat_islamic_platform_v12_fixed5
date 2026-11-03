# AYAT V6

- Added an Arabic AI assistant screen and connected it to a configurable secure gateway.
- Added Node.js gateway with Helmet, CORS configuration, rate limiting, input validation, protected routes, health/status endpoints and OpenAI Responses API support.
- Added a configurable hadith provider adapter that fails explicitly when no authorized provider is configured; it preserves supplied grades/references and does not invent metadata.
- Added app-token header support to the Flutter assistant and hadith clients.
- Persisted adhkar/tesbih counter and current dhikr locally across app restarts.
- Connected the assistant screen from the Islamic hub and home screen.
- Added backend deployment, security, provider and Flutter configuration documentation.

## Not represented as complete

- No provider credentials or hosted backend were supplied/deployed.
- Hadith search remains disabled until a licensed upstream provider is configured.
- AI assistant requires a server-side OpenAI API key and may incur usage charges.
- Dalail, Tarteel, Muslim Expert, Vaktim and quran.ai ChatGPT connectors are not automatically callable from a standalone Flutter APK; each needs a supported public API/SDK or an authorized server integration.
- Flutter/Dart SDK was not available in the build environment, so no `flutter analyze`, Android build or on-device test is claimed.
