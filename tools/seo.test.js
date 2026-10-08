const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const { applyMetadata } = require('./seo-metadata');
const { selectUrls, submit } = require('./indexnow');
const SITE = 'https://scoobymenu.cc';
const meta = { title: 'Test guide - Scooby', description: 'A guide with real navigation.', keywords: 'Scooby guide' };

test('navigation normalization preserves fragments, queries, external URLs and scripts', () => {
  const { routeMap, normalizeLinks } = require('./seo-links');
  const routes = routeMap(['index.html', 'guides/index.html', 'products/gta5/index.html']);
  const html = `<a href="/guides?game=gta5&amp;tab=lua#start">Guide</a><a href="../gta5/index.html#features">Game</a><a href="#local">Local</a><a href="https://example.com/guides">External</a><script>const example = '<a href="/guides">';</script>`;
  const result = normalizeLinks('products/gta5/index.html', html, routes);
  assert(result.includes('href="/guides/?game=gta5&amp;tab=lua#start"'));
  assert(result.includes('href="/products/gta5/#features"'));
  assert(result.includes('href="#local"'));
  assert(result.includes('href="https://example.com/guides"'));
  assert(result.includes(`<script>const example = '<a href="/guides">';</script>`));
  assert.equal(normalizeLinks('products/gta5/index.html', result, routes), result);
});

test('public HTML navigation uses canonical routes and has no missing local targets', () => {
  const path = require('path');
  const { walk } = require('./seo-metadata');
  const { pageUrl } = require('./seo-structured');
  const { routeMap, normalizeLinks } = require('./seo-links');
  const root = path.resolve(__dirname, '..');
  const files = walk(root).map(file => path.relative(root, file).replace(/\\/g, '/'));
  const routes = routeMap(files);
  for (const file of files) {
    const html = fs.readFileSync(path.join(root, file), 'utf8');
    assert.equal(normalizeLinks(file, html, routes), html, 'Run npm run seo:links: ' + file);
    const markup = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>|<!--[^]*?-->/gi, '');
    for (const match of markup.matchAll(/<a\b[^>]*\shref=["']([^"']+)["']/gi)) {
      const url = new URL(match[1], pageUrl(file));
      if (url.origin !== SITE) continue;
      assert(fs.existsSync(path.join(root, decodeURIComponent(url.pathname))), file + ' links to missing ' + url.pathname);
    }
  }
});

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
test('structured metadata matches the current page with or without a trailing slash', () => {
  for (const suffix of ['', '/']) {
    const application = { '@type': 'SoftwareApplication', url: SITE + '/products/gmod' + suffix,
      description: 'Old description', keywords: 'Old keywords',
      isRelatedTo: { '@type': 'SoftwareApplication', url: SITE + '/products/gta5/', description: 'GTA description', keywords: 'GTA 5 mod menu' } };
    const html = '<html><head><title>Old</title><script type="application/ld+json">' + JSON.stringify(application) + '</script></head><body><h1>GMOD Cheat</h1></body></html>';
    const result = applyMetadata('products/gmod/index.html', html, meta);
    const data = JSON.parse(result.match(/type="application\/ld\+json">([\s\S]*?)<\/script>/)[1]);
    assert.equal(data.description, meta.description);
    assert.equal(data.keywords, meta.keywords);
    assert.deepEqual(data.isRelatedTo, application.isRelatedTo);
    assert.equal(applyMetadata('products/gmod/index.html', result, meta), result);
  }
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
  const expected = Object.fromEntries(homes.map(([code, locale]) => [locale.tag, SITE + (code === 'en' ? '/' : '/lang/' + code + '/')]));
  expected['x-default'] = SITE + '/';
  for (const [code, locale] of homes) {
    const file = code === 'en' ? 'index.html' : 'lang/' + code + '/index.html';
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
    assert(body.includes(locale.intro), 'Missing visible translated prose: ' + file);
    for (const marker of ['class="hero"', 'id="heroScenes"', 'id="startModal"', '/assets/js/home-features.js', '/assets/js/hero-slideshow.js']) {
      assert(html.includes(marker), 'Missing full homepage layout: ' + file + ' ' + marker);
    }
    assert(!html.includes('/assets/css/site-directory.css'), 'Simplified directory layout: ' + file);
    const data = JSON.parse(head.match(/id="seo-page-structure">\s*([\s\S]*?)<\/script>/)[1]);
    assert.equal(data['@graph'].find(item => item['@type'] === 'WebPage').inLanguage, locale.tag, file);
    assert(html.includes('/lang/i18n.js'), 'Full homepage needs the language selector: ' + file);
  }
});

test('static homepages and runtime dictionaries cover the same languages with nonempty matching keys', () => {
  const vm = require('vm');
  const locales = require('./search-locales.json');
  const engine = fs.readFileSync('lang/i18n.js', 'utf8');
  const registered = [...engine.match(/var LANGS = \[([\s\S]*?)\];/)[1].matchAll(/code:\s*'([^']+)'/g)].map(m => m[1]).filter(code => code !== 'en');
  assert.deepEqual(registered.sort(), Object.keys(locales).sort());
  let expectedKeys;
  for (const code of registered) {
    const context = { window: {} };
    vm.runInNewContext(fs.readFileSync('lang/' + code + '.js', 'utf8'), context);
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
