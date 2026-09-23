const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const { applyMetadata } = require('./seo-metadata');
const { selectUrls, submit } = require('./indexnow');
const SITE = 'https://scoobymenu.cc';
const meta = { title: 'Test guide - Scooby', description: 'A guide with real navigation.', keywords: 'Scooby guide' };

test('metadata preserves noindex pages and redirect stubs, regardless of attribute order', () => {
  for (const marker of ['<meta content="noindex, follow" name="ROBOTS">', '<meta content="0; url=/" http-equiv="Refresh">']) {
    const html = `<html><head><title>Private</title>${marker}</head><body>Account</body></html>`;
    assert.equal(applyMetadata('portal/index.html', html, meta), html);
  }
});
test('breadcrumb data follows visible navigation, escapes script content and is stable on reruns', () => {
  const html = '<html><head><title>Old</title></head><body><div class="breadcrumbs"><a href="/guides/">Guides</a> / <a href="/guides/source-games/">Source &amp; GoldSrc</a></div><h1>Half-Life setup</h1></body></html>';
  const result = applyMetadata('guides/half-life-1/getting-started/index.html', html, meta);
  assert.equal(applyMetadata('guides/half-life-1/getting-started/index.html', result, meta), result);
  const data = JSON.parse(result.match(/id="seo-page-structure">\s*([\s\S]*?)<\/script>/)[1]);
  const trail = data['@graph'].find(item => item['@type'] === 'BreadcrumbList').itemListElement;
  assert.deepEqual(trail.map(item => item.name), ['Guides', 'Source & GoldSrc', 'Half-Life setup']);
  assert.deepEqual(trail.map(item => item.position), [1, 2, 3]);
  assert.equal(trail[2].item, SITE + '/guides/half-life-1/getting-started/');
});
test('updating a page does not overwrite the description of its parent collection', () => {
  const html = '<html><head><title>Old</title><script type="application/ld+json">{"@type":"WebPage","url":"https://scoobymenu.cc/products/css/","description":"old","isPartOf":{"@type":"CollectionPage","url":"https://scoobymenu.cc/source-games/","description":"Parent collection"}}</script></head><body><h1>CSS</h1></body></html>';
  const result = applyMetadata('products/css/index.html', html, meta);
  const data = JSON.parse(result.match(/type="application\/ld\+json">([\s\S]*?)<\/script>/)[1]);
  assert.equal(data.description, meta.description);
  assert.equal(data.isPartOf.description, 'Parent collection');
});
test('IndexNow selects changed public pages and removals, excluding dashboard, redirects and unrelated files', () => {
  const files = [{ file: 'index.html', html: '' }, { file: 'guides/index.html', html: '' }];
  assert.deepEqual(selectUrls(files, ['index.html', 'portal/index.html', 'discord.html', 'tools/private.html', 'SEO.md', 'old/index.html'], [SITE + '/old/', SITE + '/portal/', 'https://example.com/']), [SITE + '/', SITE + '/old/']);
  assert.deepEqual(selectUrls(files, ['assets/css/guides.css']), [SITE + '/', SITE + '/guides/']);
});
test('IndexNow refuses to submit before a matching key is deployed', async () => {
  const calls = [];
  await assert.rejects(submit([SITE + '/'], 'a'.repeat(32), async url => { calls.push(url); return new Response('old key'); }), /not live yet/);
  assert.deepEqual(calls, [SITE + '/indexnow-key.txt']);
});
test('IndexNow checks the deployed sitemap and sends one canonical batch', async () => {
  const calls = [];
  const key = 'a'.repeat(32);
  await submit([SITE + '/'], key, async (url, options) => {
    calls.push({ url, options });
    if (url.endsWith('indexnow-key.txt')) return new Response(key);
    if (url.endsWith('sitemap.xml')) return new Response(fs.readFileSync('sitemap.xml', 'utf8'));
    return new Response('', { status: 202 });
  });
  assert.equal(calls.length, 3);
  assert.equal(calls[2].url, 'https://api.indexnow.org/indexnow');
  assert.deepEqual(JSON.parse(calls[2].options.body).urlList, [SITE + '/']);
});

test('all language homepages contain translated HTML with reciprocal, self-canonical alternates', () => {
  const locales = require('./search-locales.json');
  const { plain } = require('./seo-structured');
  const homes = [['en', { tag:'en' }], ...Object.entries(locales)];
  const expected = Object.fromEntries(homes.map(([code, locale]) => [locale.tag, SITE + (code === 'en' ? '/' : '/' + code + '/')]));
  expected['x-default'] = SITE + '/';
  for (const [code, locale] of homes) {
    const file = code === 'en' ? 'index.html' : code + '/index.html';
    const html = fs.readFileSync(file, 'utf8');
    const head = html.match(/<head\b[^>]*>([\s\S]*?)<\/head>/i)[1];
    const alternates = [...head.matchAll(/<link rel="alternate" hreflang="([^"]+)" href="([^"]+)">/g)];
    assert.equal(alternates.length, homes.length + 1, file);
    assert.deepEqual(Object.fromEntries(alternates.map(m => [m[1], m[2]])), expected, file);
    assert.equal((head.match(/rel="canonical"/g) || []).length, 1, file);
    assert(head.includes('rel="canonical" href="' + expected[locale.tag] + '"'), file);
    assert.equal(applyMetadata(file, html), html, 'Metadata rerun changed ' + file);
    if (code === 'en') continue;
    assert(html.includes('lang="' + locale.tag + '" dir="' + (locale.rtl ? 'rtl' : 'ltr') + '"'), file);
    const body = plain(html.match(/<body\b[^>]*>([\s\S]*?)<\/body>/i)[1]);
    assert(body.includes(locale.intro) && body.includes(locale.about) && body.includes(locale.notice), 'Missing visible translated prose: ' + file);
    const data = JSON.parse(head.match(/id="seo-page-structure">\s*([\s\S]*?)<\/script>/)[1]);
    assert.equal(data['@graph'].find(item => item['@type'] === 'WebPage').inLanguage, locale.tag, file);
    assert(!html.includes('/languages/i18n.js'), 'A saved preference must not rewrite a translated URL');
  }
});

test('static homepages and runtime dictionaries cover the same languages with nonempty matching keys', () => {
  const vm = require('vm');
  const locales = require('./search-locales.json');
  const engine = fs.readFileSync('languages/i18n.js', 'utf8');
  const registered = [...engine.match(/var LANGS = \[([\s\S]*?)\];/)[1].matchAll(/code:\s*'([^']+)'/g)].map(m => m[1]).filter(code => code !== 'en');
  assert.deepEqual(registered.sort(), Object.keys(locales).sort());
  let expectedKeys;
  for (const code of registered) {
    const context = { window: {} };
    vm.runInNewContext(fs.readFileSync('languages/' + code + '.js', 'utf8'), context);
    const entry = context.window.__scoobyI18nQueue;
    assert.equal(entry.length, 1, code);
    assert.equal(entry[0][0], code);
    const dictionary = entry[0][1];
    const keys = Object.keys(dictionary).sort();
    if (!expectedKeys) expectedKeys = keys;
    assert.deepEqual(keys, expectedKeys, 'Dictionary key mismatch: ' + code);
    assert(Object.values(dictionary).every(value => typeof value === 'string' && value.trim()), code);
  }
});

test('sitemap and JavaScript-free directory cover public pages while excluding account and redirect pages', () => {
  const path = require('path');
  const { walk, excluded } = require('./seo-metadata');
  const { pageUrl } = require('./seo-structured');
  const { sitemapUrls } = require('./indexnow');
  const root = path.resolve(__dirname, '..');
  const files = walk(root).filter(file => !excluded(fs.readFileSync(file, 'utf8').match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || ''))
    .map(file => path.relative(root, file).replace(/\\/g, '/'));
  const urls = files.map(pageUrl).sort();
  assert.deepEqual(sitemapUrls(fs.readFileSync('sitemap.xml', 'utf8')).sort(), urls);
  assert(![SITE + '/portal/', SITE + '/discord.html', SITE + '/scoobyontop.html'].some(url => urls.includes(url)));
  const directory = fs.readFileSync('sitemap/index.html', 'utf8');
  for (const file of files.filter(file => file !== 'sitemap/index.html')) {
    assert(directory.includes('href="' + pageUrl(file).slice(SITE.length) + '"'), 'Directory omits ' + file);
  }
});
