import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
test('gateway package exposes health and protected routes', async () => {
  const source = await readFile(new URL('../src/server.js', import.meta.url), 'utf8');
  assert.match(source, /app\.get\('\/health'/);
  assert.match(source, /app\.post\('\/api\/assistant\/ask'/);
  assert.match(source, /app\.get\('\/api\/hadith\/search'/);
  assert.match(source, /X-AYAT-APP-TOKEN/);
});
