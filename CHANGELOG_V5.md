# AYAT V5

- Added a daily Quran reading goal with selectable page targets and locally persisted daily progress.
- Added a Hadith search screen and typed result model.
- Added a secure configurable backend URL using `AYAT_API_BASE_URL`; provider credentials are intentionally not stored in the app.
- Documented the normalized Hadith gateway contract and secure AI integration boundary in `backend/README.md`.
- Connected the new screens from the Islamic hub and home dashboard.

## Honest integration status

The reading goal works locally. The Hadith client requires a deployed backend implementing the documented contract. No HadithDB/OpenAI credentials, external provider access, APK build, or device test are included in this source archive.
