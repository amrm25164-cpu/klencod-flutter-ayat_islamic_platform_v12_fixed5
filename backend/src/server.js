import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import OpenAI from 'openai';

const app = express();
app.disable('x-powered-by');
app.use(helmet());
const origins = (process.env.CORS_ORIGINS || '*').split(',').map(x => x.trim());
app.use(cors({ origin: origins.includes('*') ? true : origins }));
app.use(express.json({ limit: '32kb' }));
app.use('/api', rateLimit({ windowMs: 60_000, limit: 40, standardHeaders: 'draft-7', legacyHeaders: false }));

const token = process.env.AYAT_APP_TOKEN || '';
function auth(req, res, next) {
  if (!token) return res.status(503).json({ error: 'server_not_configured', message: 'AYAT_APP_TOKEN is not configured.' });
  if (req.get('X-AYAT-APP-TOKEN') !== token) return res.status(401).json({ error: 'unauthorized' });
  next();
}
const clean = value => typeof value === 'string' ? value.trim().slice(0, 1200) : '';
app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'ayat-gateway', version: '1.0.0' }));
app.get('/api/status', auth, (_req, res) => res.json({ assistant: Boolean(process.env.OPENAI_API_KEY), hadith: Boolean(process.env.HADITH_PROVIDER_URL), prayer: 'client_aladhan_api', quran: 'client_alquran_cloud_api' }));

app.post('/api/assistant/ask', auth, async (req, res) => {
  const question = clean(req.body?.question);
  const context = clean(req.body?.context);
  if (question.length < 3) return res.status(400).json({ error: 'invalid_question', message: 'اكتب سؤالاً واضحاً.' });
  if (!process.env.OPENAI_API_KEY) return res.status(503).json({ error: 'assistant_not_configured', message: 'لم يتم إعداد مفتاح النموذج على الخادم.' });
  try {
    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const response = await client.responses.create({
      model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
      instructions: `أنت مساعد داخل تطبيق آيات. أجب بالعربية الواضحة وبأدب. لا تختلق آيات أو أحاديث أو أرقام تخريج أو درجات. إذا كان السؤال يتطلب فتوى أو حكماً شرعياً محدداً فوضح أن الجواب معلوماتي وليس فتوى، واطلب الرجوع لعالم مؤهل. ميّز بين النص المنقول والشرح. لا تدّعِ أنك تحققت من مصدر لم يتم تزويدك به. إذا لم تكن متأكداً فقل ذلك صراحة. لا تنشئ مراجع وهمية.`,
      input: `سياق اختياري من التطبيق: ${context || 'لا يوجد'}\n\nسؤال المستخدم: ${question}`,
      max_output_tokens: 900,
    });
    res.json({ answer: response.output_text || 'لم أتمكن من صياغة إجابة.', label: 'إجابة مولّدة بالذكاء الاصطناعي وليست نقلاً موثقاً', sources: [], requires_verification: true });
  } catch (error) {
    console.error('assistant_request_failed', error?.status || error?.name || 'unknown');
    res.status(502).json({ error: 'assistant_provider_error', message: 'تعذر الحصول على إجابة من مزود الذكاء الاصطناعي.' });
  }
});

app.get('/api/hadith/search', auth, async (req, res) => {
  const q = clean(req.query.q);
  if (q.length < 2) return res.status(400).json({ error: 'invalid_query' });
  const endpoint = process.env.HADITH_PROVIDER_URL;
  if (!endpoint) return res.status(503).json({ error: 'hadith_provider_not_configured', message: 'لم يتم توصيل مزود حديث مرخّص على الخادم بعد.' });
  try {
    const url = new URL(endpoint);
    url.searchParams.set('q', q);
    const upstream = await fetch(url, { headers: process.env.HADITH_PROVIDER_TOKEN ? { Authorization: `Bearer ${process.env.HADITH_PROVIDER_TOKEN}` } : {}, signal: AbortSignal.timeout(12000) });
    if (!upstream.ok) return res.status(502).json({ error: 'hadith_provider_error' });
    const data = await upstream.json();
    const results = Array.isArray(data) ? data : (data.results || data.data || []);
    // Preserve provider metadata; never manufacture grading or references.
    res.json({ results: results.slice(0, 20).map(x => ({ text: x.text || x.arabic || x.body || '', source: x.source || x.book || 'المصدر غير محدد', reference: x.reference || x.number || '', grade: x.grade || x.grading || 'لم تُذكر الدرجة', narrator: x.narrator || null, url: x.url || null })).filter(x => x.text) });
  } catch {
    res.status(502).json({ error: 'hadith_provider_unreachable' });
  }
});

app.use((err, _req, res, _next) => { console.error('request_error', err?.name || 'unknown'); res.status(400).json({ error: 'bad_request' }); });
const port = Number(process.env.PORT || 8080);
if (process.env.NODE_ENV !== 'test') app.listen(port, '0.0.0.0', () => console.log(`AYAT gateway listening on ${port}`));
export { app };
