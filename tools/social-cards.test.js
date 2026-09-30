const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { applyMetadata, pages, excluded } = require('./seo-metadata');
const ROOT = path.resolve(__dirname, '..');
const SITE = 'https://scoobymenu.cc';
const { VERSION } = require('./social-cards');
function metaTags(html) {
  const head = html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || '';
  return [...head.matchAll(/<meta\b[^>]*>/gi)].map(([tag]) => Object.fromEntries(
    [...tag.matchAll(/([\w:-]+)="([^"]*)"/g)].map(([, key, value]) => [key, value])));
}
function value(tags, key) {
  const found = tags.filter(tag => (tag.property || tag.name) === key);
  assert.equal(found.length, 1, 'Expected one ' + key);
  return found[0].content;
}

test('public HTML exposes a complete, fetchable PNG preview without JavaScript', () => {
  const images = new Set();
  for (const file of Object.keys(pages)) {
    const html = fs.readFileSync(path.join(ROOT, file), 'utf8');
    if (excluded(html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || '')) continue;
    const tags = metaTags(html), image = value(tags, 'og:image');
    assert(image.startsWith(SITE + '/assets/images/social/'), file);
    assert.equal(value(tags, 'twitter:image'), image, file);
    assert.equal(value(tags, 'og:image:secure_url'), image, file);
    assert.equal(value(tags, 'twitter:card'), 'summary_large_image', file);
    assert.equal(value(tags, 'og:image:type'), 'image/png', file);
    assert(value(tags, 'og:image:alt').length > 10, file);
    assert.equal(value(tags, 'twitter:image:alt'), value(tags, 'og:image:alt'), file);
    const png = fs.readFileSync(path.join(ROOT, new URL(image).pathname));
    assert.deepEqual(png.subarray(0, 8), Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), file);
    assert.equal(png.readUInt32BE(16), Number(value(tags, 'og:image:width')), file);
    assert.equal(png.readUInt32BE(20), Number(value(tags, 'og:image:height')), file);
    assert(png.length < 1024 * 1024, 'Oversized preview: ' + file);
    assert.equal(applyMetadata(file, html), html, 'Metadata is stale: ' + file);
    images.add(image);
  }
  assert(images.size > 10, 'Sections should not all share the homepage image');
});

test('legacy image metadata is replaced and duplicates cannot leak into a preview', () => {
  const html = `<html><head><title>Old</title>
    <meta property="og:image" content="${SITE}/background-home.jpg">
    <meta property="og:image" content="${SITE}/old.jpg">
    <meta property="og:image:secure_url" content="${SITE}/old.jpg">
    <meta property="og:image:width" content="1920"><meta property="og:image:height" content="1080">
    <meta property="og:image:type" content="image/jpeg"><meta name="twitter:image" content="${SITE}/old.jpg">
    </head><body><h1>Wiki</h1></body></html>`;
  const updated = applyMetadata('guides/index.html', html), tags = metaTags(updated);
  assert.equal(value(tags, 'og:image'), SITE + '/assets/images/social/guides-' + VERSION + '.png');
  assert.equal(value(tags, 'og:image:width'), '1200');
  assert.equal(value(tags, 'og:image:height'), '630');
  assert(!updated.includes('background-home.jpg') && !updated.includes('old.jpg'));
  assert.equal(applyMetadata('guides/index.html', updated), updated);
  assert.equal(updated.match(/<body>[\s\S]*<\/body>/)[0], '<body><h1>Wiki</h1></body>');
});

test('wiki, API, store and product links have distinct relevant preview cards', () => {
  const expected = {
    'guides/index.html': 'guides', 'guides/tf2/index.html': 'guides',
    'guides/general/connection/index.html': 'support', 'docs/index.html': 'docs',
    'api/cs2/index.html': 'docs', 'api/tf2/index.html': 'docs',
    'store/index.html': 'store', 'source-games/index.html': 'source',
    'products/tf2/index.html': 'game-tf2', 'products/gta5/index.html': 'game-gta5',
    'products/free/index.html': 'free', 'features-list/l4d-features/index.html': 'features',
  };
  for (const [file, card] of Object.entries(expected)) {
    assert.equal(value(metaTags(fs.readFileSync(path.join(ROOT, file), 'utf8')), 'og:image'),
      `${SITE}/assets/images/social/${card}-${VERSION}.png`, file);
  }
});
