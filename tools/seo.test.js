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
  const guides = require('../resources/guides/routes.json');
  for (const file of files) {
    const html = fs.readFileSync(path.join(root, file), 'utf8');
    assert.equal(normalizeLinks(file, html, routes, guides), html, 'Run npm run seo:links: ' + file);
    const markup = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>|<!--[^]*?-->/gi, '');
    for (const match of markup.matchAll(/<a\b[^>]*\shref=["']([^"']+)["']/gi)) {
      const url = new URL(match[1], pageUrl(file));
      if (url.origin !== SITE) continue;
      assert(fs.existsSync(path.join(root, decodeURIComponent(url.pathname))), file + ' links to missing ' + url.pathname);
    }
  }
});

test('resource link migration keeps filters and anchors on the canonical scope', () => {
  const { routeMap, normalizeLinks } = require('./seo-links');
  const collection = '/resources/gta5/cherax/lua/';
  const guide = '/resources/guides/gta5/cherax/lua/';
  const routes = routeMap([collection.slice(1) + 'index.html', guide.slice(1) + 'index.html']);
  const html = '<a href="/resources/?game=gta5&amp;menu=Cherax&amp;category=lua&amp;q=two+words&amp;page=2#resource-one">Resource</a>' +
    '<a href="/community/guides/?game=gta5&amp;menu=cherax&amp;category=lua#cherax-lua">Guide</a>';
  assert.equal(normalizeLinks('index.html', html, routes, { [guide]: guide }),
    `<a href="${collection}?q=two+words&amp;page=2#resource-one">Resource</a><a href="${guide}#cherax-lua">Guide</a>`);
});

test('metadata preserves noindex pages and redirect stubs, regardless of attribute order', () => {
  for (const marker of ['<meta content="noindex, follow" name="ROBOTS">', '<meta content="0; url=/" http-equiv="Refresh">']) {
    const html = `<html><head><title>Private</title>${marker}</head><body>Account</body></html>`;
    assert.equal(applyMetadata('portal/index.html', html, meta), html);
  }
});

test('keyword tags are trimmed and deduplicated consistently with structured data', () => {
  const result = applyMetadata('guides/example/index.html', '<html><head><title>Old</title></head><body>Guide</body></html>',
    { ...meta, keywords: ' Scooby guide, scooby GUIDE, , Lua   scripts, Lua scripts ' });
  assert(result.includes('name="keywords" content="Scooby guide, Lua scripts"'));
  const data = JSON.parse(result.match(/id="seo-page-structure">\s*([\s\S]*?)<\/script>/)[1]);
  assert.equal(data['@graph'][0].keywords, 'Scooby guide, Lua scripts');
  assert.equal(applyMetadata('guides/example/index.html', result, { ...meta, keywords: 'Scooby guide, Lua scripts' }), result);
});

test('sitemap excludes aliases, private pages and redirects, escapes XML and omits unknown dates', t => {
  const path = require('node:path');
  const tmp = require('node:os').tmpdir();
  const { buildSitemap } = require('./seo-sitemap');
  const root = fs.mkdtempSync(path.join(tmp, 'scooby-seo-'));
  t.after(() => {
    assert.equal(path.dirname(root), tmp);
    assert(path.basename(root).startsWith('scooby-seo-'));
    fs.rmSync(root, { recursive:true, force:true });
  });
  const fixtures = {
    'index.html': '', 'lang/fr/index.html': '', 'guide&tips.html': '',
    'alias/index.html': '<link rel="canonical" href="https://scoobymenu.cc/">',
    'offsite/index.html': '<link href="https://example.com/" rel="canonical">',
    'private/index.html': '<meta content="noindex, follow" name="robots">',
    'redirect.html': '<meta content="0;url=/" http-equiv="refresh">',
    'portal/index.html': '', 'tools/preview.html': ''
  };
  for (const [file, head] of Object.entries(fixtures)) {
    fs.mkdirSync(path.dirname(path.join(root, file)), { recursive:true });
    fs.writeFileSync(path.join(root, file), `<html><head>${head}</head><body></body></html>`);
  }
  const { rows, xml } = buildSitemap({ root, dateFor: file => file === 'index.html' ? '2026-11-20' : null });
  assert.equal(rows.length, 3);
  assert(xml.includes('<loc>https://scoobymenu.cc/guide&amp;tips.html</loc>'));
  assert.equal((xml.match(/<lastmod>/g) || []).length, 1);
  assert(xml.includes('<lastmod>2026-11-20</lastmod>'));
  assert.equal((xml.match(/hreflang="fr"/g) || []).length, 2);
  assert(!xml.includes('/lang/de/'));
  assert.equal(buildSitemap({ root, dateFor: file => file === 'index.html' ? '2026-11-20' : null }).xml, xml);
});

test('sitemap language clusters match HTML alternates without labeling English products as translations', () => {
  const xml = fs.readFileSync('sitemap.xml', 'utf8');
  const locales = require('./search-locales.json');
  const expected = { en:SITE + '/', ...Object.fromEntries(Object.entries(locales).map(([code, locale]) => [locale.tag, SITE + '/lang/' + code + '/'])), 'x-default':SITE + '/' };
  assert(xml.includes('xmlns:xhtml="http://www.w3.org/1999/xhtml"'));
  for (const match of xml.matchAll(/<url>([\s\S]*?)<\/url>/g)) {
    const loc = match[1].match(/<loc>([^<]+)<\/loc>/)[1];
    const alternates = [...match[1].matchAll(/<xhtml:link rel="alternate" hreflang="([^"]+)" href="([^"]+)" \/>/g)];
    if (Object.values(expected).includes(loc)) {
      assert.equal(alternates.length, Object.keys(expected).length, loc);
      assert.deepEqual(Object.fromEntries(alternates.map(m => [m[1], m[2]])), expected, loc);
    } else assert.equal(alternates.length, 0, loc);
  }
});

test('media sitemap entries point to public screenshots and dedicated video watch pages', () => {
  const xml = fs.readFileSync('sitemap.xml', 'utf8');
  const { pageUrl } = require('./seo-structured');
  const { videos } = require('./seo-watch.cjs');
  const { isPublic } = require('./site-layout.cjs');
  const rows = new Map([...xml.matchAll(/<url>\s*<loc>([^<]+)<\/loc>([\s\S]*?)<\/url>/g)]
    .map(match => [match[1], match[2]]));
  const gta = rows.get(SITE + '/products/gta5/');
  assert(gta.includes('<image:loc>' + SITE + '/assets/images/previews/gta5/gta5-enhanced-self-menu-2026-10.jpg</image:loc>'));
  for (const [, link] of xml.matchAll(/<image:loc>([^<]+)<\/image:loc>/g)) {
    const relative = decodeURIComponent(new URL(link).pathname.slice(1));
    assert(isPublic(relative) && fs.existsSync(relative), relative);
    assert(!relative.startsWith('assets/images/resource-previews/cherax/'), relative);
  }
  assert(!rows.get(SITE + '/videos/').includes('<video:video>'));
  const library = fs.readFileSync('videos/index.html', 'utf8');
  for (const video of videos) {
    const url = pageUrl(video.file);
    const page = fs.readFileSync(video.file, 'utf8');
    const matching = rows.get(url);
    assert(library.includes('href="' + new URL(url).pathname + '"'), video.file);
    assert(page.includes('<iframe class="watch-frame" src="' + video.player + '"'), video.file);
    const metadata = JSON.parse(page.match(/<script type="application\/ld\+json">(.*?)<\/script>/s)[1]);
    assert.equal(metadata['@type'], 'VideoObject');
    assert.equal(metadata.embedUrl, video.player);
    assert.equal(metadata.thumbnailUrl, video.thumbnail);
    assert.equal(metadata.uploadDate, video.uploadDate);
    assert(matching.includes('<video:player_loc>' + video.player + '</video:player_loc>'), video.file);
    assert(matching.includes('<video:thumbnail_loc>' + video.thumbnail + '</video:thumbnail_loc>'), video.file);
  }
  assert.equal((xml.match(/<video:video>/g) || []).length, videos.length);
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
  assert.equal(data.isPartOf[0].description, 'Parent collection');
  assert.deepEqual(data.isPartOf[1], { '@id': SITE + '/#website' });
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
    for (const marker of ['class="hero"', 'id="heroScenes"', 'id="startModal"', '/assets/js/hero-slideshow.js']) {
      assert(html.includes(marker), 'Missing full homepage layout: ' + file + ' ' + marker);
    }
    assert(!html.includes('/assets/css/site-directory.css'), 'Simplified directory layout: ' + file);
    const data = JSON.parse(head.match(/id="seo-page-structure">\s*([\s\S]*?)<\/script>/)[1]);
    assert.equal(data['@graph'].find(item => item['@type'] === 'WebPage').inLanguage, locale.tag, file);
    assert(html.includes('/lang/i18n.js'), 'Full homepage needs the language selector: ' + file);
  }
});

test('static homepages and runtime dictionaries cover the same languages with nonempty translations', () => {
  const vm = require('vm');
  const locales = require('./search-locales.json');
  const engine = fs.readFileSync('lang/i18n.js', 'utf8');
  const entries = [...engine.match(/var LANGS = \[([\s\S]*?)\];/)[1].matchAll(/code:\s*'([^']+)'([^\n]*)/g)];
  for (const [, code, fields] of entries) {
    const flag = fields.match(/flag:\s*'([a-z-]+)'/)?.[1];
    assert(flag && fs.existsSync('lang/flags/' + flag + '.svg'), 'Missing language flag: ' + code);
  }
  const registered = entries.map(entry => entry[1]).filter(code => code !== 'en');
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
    if (locales[code].coverage === 'core') {
      for (const key of ['Home', 'Products', 'Store', 'Guides', 'Support', 'Login', 'Languages', 'Change language', 'Select language', 'Free Version', 'Frequently asked questions', 'Site directory', 'Become a reseller', 'Terms of Service', 'Choose a game', 'Player reviews', 'Toggle menu']) {
        assert(Object.hasOwn(dictionary, key), code + ': missing ' + key);
      }
      assert(Object.values(dictionary).includes(locales[code].intro), code + ': missing homepage introduction');
    } else {
      if (!expectedKeys) expectedKeys = keys;
      assert.deepEqual(keys, expectedKeys, 'Dictionary key mismatch: ' + code);
    }
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
  const { pages } = require('./seo-metadata');
  for (const file of files) assert(pages[file], 'Public page has no SEO catalogue entry: ' + file);
  const urls = files.map(pageUrl).sort();
  assert.deepEqual(sitemapUrls(fs.readFileSync('sitemap.xml', 'utf8')).sort(), urls);
  assert(![SITE + '/portal/', SITE + '/discord.html', SITE + '/scoobyontop.html'].some(url => urls.includes(url)));
  const directory = fs.readFileSync('sitemap/index.html', 'utf8');
  for (const file of files.filter(file => file !== 'sitemap/index.html')) {
    assert(directory.includes('href="' + pageUrl(file).slice(SITE.length) + '"'), 'Directory omits ' + file);
  }
});

test('each indexable page identifies its canonical URL, language and website in structured data', () => {
  const path = require('node:path');
  const { walk, excluded, attrs, pages } = require('./seo-metadata');
  const { pageUrl, isPageEntity } = require('./seo-structured');
  const root = path.resolve(__dirname, '..');
  for (const absolute of walk(root)) {
    const html = fs.readFileSync(absolute, 'utf8');
    const head = html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || '';
    if (excluded(head)) continue;
    const file = path.relative(root, absolute).split(path.sep).join('/');
    const url = pageUrl(file);
    const language = pages[file].language || 'en';
    const canonicals = [...head.matchAll(/<link\b[^>]*>/gi)].map(match => attrs(match[0]))
      .filter(link => link.rel === 'canonical');
    assert.deepEqual(canonicals.map(link => link.href), [url], file);
    assert.equal(attrs(html.match(/<html\b[^>]*>/i)?.[0] || '').lang, language, file);
    const entities = [...head.matchAll(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
      .flatMap(match => {
        const data = JSON.parse(match[1]);
        return Array.isArray(data) ? data : data['@graph'] || [data];
      });
    const entity = entities.find(node => isPageEntity(node, url));
    assert(entity, file);
    assert.equal(entity.url, url, file);
    assert.equal(entity.inLanguage, language, file);
    assert.equal(entity.description, pages[file].description, file);
    assert([entity.isPartOf].flat().some(parent => parent?.['@id'] === SITE + '/#website'), file);
    assert.equal(entity.publisher?.['@id'], SITE + '/#organization', file);
  }
});
