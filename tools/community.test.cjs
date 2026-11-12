'use strict';

// Run after the asset import: node --test tools/community.test.cjs
// Set COMMUNITY_DOWNLOAD_ROOT when cool-repo is not a sibling checkout.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { isDeepStrictEqual } = require('node:util');
const { readBundledOutfits } = require('./extract-community-outfits.cjs');
const { createServer } = require('./preview.cjs');

const SITE = path.resolve(__dirname, '..');
const DOWNLOADS = path.resolve(process.env.COMMUNITY_DOWNLOAD_ROOT || path.join(SITE, '..', 'cool-repo'));
const SOURCE_ROOT = path.resolve(process.env.COMMUNITY_SOURCE_ROOT || path.dirname(SITE));
const GAMES = ['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d'];
const CATEGORIES = new Set(['vehicles', 'modded', 'outfits', 'addon-vehicles', 'addon-peds', 'addon-clothing', 'addon-maps', 'addon-objects', 'addon-animations', 'maps',
  'textures', 'paintjobs', 'liveries', 'players', 'weapons', 'knives', 'throwables', 'bombs', 'pets', 'skyboxes',
  'themes', 'configs', 'languages', 'misc', 'asi-mods', 'dotnet-mods']);
const readJSON = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const digest = (file) => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
let libraryCache;
function library() {
  if (!libraryCache) libraryCache = readJSON(path.join(SITE, 'community/data/library.json'));
  return libraryCache;
}

function httpsURL(value, context) {
  assert.equal(typeof value, 'string', context);
  const url = new URL(value);
  assert.equal(url.protocol, 'https:', context);
  assert(!url.username && !url.password, `Credentials in ${context}`);
  return url;
}

function assetPath(relative) {
  assert.equal(typeof relative, 'string');
  assert(relative && !/[\\:?#\0]/.test(relative), `Invalid asset path: ${relative}`);
  const decoded = decodeURIComponent(relative);
  assert(!/[\\:?#\0]/.test(decoded), `Invalid encoded asset path: ${relative}`);
  assert(decoded.split('/').every((part) => part && part !== '.' && part !== '..'), `Asset traversal: ${relative}`);
  const resolved = path.resolve(DOWNLOADS, relative);
  const delta = path.relative(DOWNLOADS, resolved);
  assert(delta && !delta.startsWith('..') && !path.isAbsolute(delta), `Asset escapes repository: ${relative}`);
  return resolved;
}

function sample(values, limit = 8) {
  if (values.length <= limit) return values;
  return Array.from({ length: limit }, (_, index) => values[Math.floor(index * (values.length - 1) / (limit - 1))]);
}

test('community catalog has unique identities, supported games/categories and safe download references', () => {
  const data = library();
  assert.equal(data.version, 1);
  const base = httpsURL(data.downloadBaseUrl, 'download base');
  assert(base.pathname.endsWith('/'), 'Download base must preserve relative paths');
  assert(Array.isArray(data.items) && data.items.length > 545, 'Expected the populated multi-game catalog');
  assert(!data.items.some(item => item.category === 'lua'), 'Imported Lua examples must stay out of the resource catalog');
  const ids = new Set();
  for (const item of data.items) {
    assert.equal(typeof item.id, 'string');
    assert(item.id && !ids.has(item.id), `Duplicate or empty item ID: ${item.id}`);
    ids.add(item.id);
    assert(GAMES.includes(item.game), `Unsupported game: ${item.id}`);
    assert(CATEGORIES.has(item.category), `Unsupported category: ${item.id}`);
    for (const category of item.categories || []) assert(CATEGORIES.has(category), `${item.id}: ${category}`);
    assert(typeof item.name === 'string' && item.name.trim(), `Missing display name: ${item.id}`);
    assert(Array.isArray(item.files), `Missing files array: ${item.id}`);
    for (const file of item.files) {
      assert(Boolean(file.path) !== Boolean(file.url), `Download must have one path or URL: ${item.id}`);
      if (file.url) httpsURL(file.url, item.id);
      else {
        assetPath(file.path);
        assert(Number.isSafeInteger(file.size) && file.size >= 0, `Missing local size: ${file.path}`);
        assert.match(file.sha256, /^[a-f0-9]{64}$/, `Missing local checksum: ${file.path}`);
      }
      if (file.sha256 !== undefined) assert.match(file.sha256, /^[a-f0-9]{64}$/, item.id);
      if (file.size !== undefined) assert(Number.isSafeInteger(file.size) && file.size >= 0, item.id);
    }
    if (item.preview) {
      if (/^[a-z][a-z0-9+.-]*:/i.test(item.preview)) httpsURL(item.preview, `${item.id} preview`);
      else assetPath(item.preview);
    }
    if (item.sourceUrl) httpsURL(item.sourceUrl, `${item.id} source`);
  }
  // RedM has a selector and guides; no compatible distributable source assets were found.
  for (const game of ['gta5', 'rdr2', 'cs2', 'fivem', 'l4d']) {
    assert(data.items.some((item) => item.game === game), `No imported catalog content for ${game}`);
  }
});

test('download repository matches the site catalog and contains the advertised assets', () => {
  const data = library();
  assert.deepEqual(readJSON(path.join(DOWNLOADS, 'catalog/library.json')), data);
  const local = data.items.flatMap((item) => item.files).filter((file) => file.path);
  assert(local.length > 356, 'Expected outfit and other local downloads');
  for (const file of local) {
    const stat = fs.lstatSync(assetPath(file.path));
    assert(stat.isFile() && !stat.isSymbolicLink(), file.path);
    assert.equal(stat.size, file.size, file.path);
  }
  for (const item of data.items.filter((entry) => entry.preview && !/^https:\/\//.test(entry.preview))) {
    assert(fs.statSync(assetPath(item.preview)).isFile(), `Missing preview: ${item.preview}`);
  }
  // Sample content hashes across the catalog without rereading large theme/media bundles.
  const small = local.filter((file) => file.size <= 2 * 1024 * 1024).sort((a, b) => a.path.localeCompare(b.path));
  for (const file of sample(small)) assert.equal(digest(assetPath(file.path)), file.sha256, file.path);
  const redirect = fs.readFileSync(path.join(DOWNLOADS, 'index.html'), 'utf8');
  assert.match(redirect, /http-equiv=["']refresh["']/i);
  assert.match(redirect, /https:\/\/scoobymenu\.cc\/resources\//);
});

test('the complete CS2 model repository retains all source identities and categories', () => {
  const catalogPath = path.join(DOWNLOADS, 'catalog/cs2-models.json');
  const catalog = readJSON(catalogPath);
  assert(catalog.packages.length >= 545, 'Expected the existing CS2 model collection');
  const original = path.join(SOURCE_ROOT, 'Scooby-Op/CS2/simple-base-cs2/assets/custom_models/catalog.json');
  if (fs.existsSync(original)) {
    assert(isDeepStrictEqual(catalog, readJSON(original)), 'The mirrored CS2 model catalog must match the source metadata');
  }
  const entries = library().items.filter((item) => item.id.startsWith('cs2-model-'));
  assert.equal(entries.length, catalog.packages.length);
  const byID = new Map(entries.map((item) => [item.id, item]));
  for (const model of catalog.packages) {
    const item = byID.get(`cs2-model-${model.id}`);
    assert(item, `Missing CS2 model: ${model.id}`);
    const isPet = [model.category, model.group].some(value => value === 'pet' || value === 'pets');
    const category = isPet ? 'pets' : ({ knife: 'knives', throwable: 'throwables', bomb: 'bombs' })[model.group]
      || (model.category === 'players' ? 'players' : 'weapons');
    assert.equal(item.category, category, model.id);
    if (isPet && model.localSource) assert.deepEqual(item.files, [], `Local pet advertised as a download: ${model.id}`);
    else if (model.url) assert(item.files.some((file) => file.url === model.url), `Lost original download: ${model.id}`);
  }
});

test('all 356 RDR2 outfit downloads are valid clothing data with the original gender distribution', () => {
  const outfits = library().items.filter((item) => item.game === 'rdr2' && item.category === 'outfits');
  assert.equal(outfits.length, 356);
  let male = 0, female = 0;
  const hashes = [];
  for (const outfit of outfits) {
    const file = outfit.files.find((entry) => entry.path?.endsWith('.json'));
    assert(file, `Missing outfit JSON: ${outfit.id}`);
    const source = fs.readFileSync(assetPath(file.path), 'utf8');
    const data = JSON.parse(source);
    assert(data.compatibility && typeof data.compatibility.gender === 'boolean', outfit.id);
    if (data.compatibility.gender) male++; else female++;
    assert(Object.keys(data).some((key) => /^\d+$/.test(key)), `No clothing components: ${outfit.id}`);
    for (const [key, value] of Object.entries(data)) {
      if (key === 'compatibility') continue;
      assert(/^\d+$/.test(key) && Number(key) <= 0xffffffff, outfit.id);
      assert(Number.isInteger(value) && value >= 0 && value <= 0xffffffff, outfit.id);
    }
    const hash = crypto.createHash('sha256').update(source).digest('hex');
    assert.equal(hash, file.sha256, outfit.id);
    hashes.push(hash);
  }
  assert.equal(male, 173);
  assert.equal(female, 183);
  const original = path.join(SOURCE_ROOT, 'Scooby-Op/RDR2/Scooby-RDR2-old - before-UI-update - working/src/game/frontend/submenus/outfiteditor/BundledOutfits.cpp');
  if (fs.existsSync(original)) {
    assert.deepEqual(hashes.sort(), readBundledOutfits(original).map((outfit) => outfit.sha256).sort(),
      'Extracted downloads must preserve the bundled outfit data');
  }
});

test('existing GTA outfit and vehicle downloads retain their cached files and direct URL paths', () => {
  const data = library();
  const legacyBase = httpsURL(data.legacyDownloadBaseUrl, 'legacy download base');
  assert.equal(legacyBase.href, new URL('downloads/gta5/', data.downloadBaseUrl).href);
  for (const kind of ['vehicles', 'outfits']) {
    const local = readJSON(path.join(SITE, `community/data/${kind}/local-assets.json`));
    const files = [];
    for (const value of Object.values(local)) {
      if (!value.file) continue;
      assert.match(value.file, /^\.\/media\//);
      const name = path.posix.basename(value.file);
      const original = path.join(SITE, 'community/media', name);
      const destination = assetPath(`downloads/gta5/${kind}/${name}`);
      assert.equal(fs.statSync(destination).size, fs.statSync(original).size, name);
      assert.equal(new URL(`${kind}/${name}`, legacyBase).href,
        new URL(`downloads/gta5/${kind}/${name}`, data.downloadBaseUrl).href, name);
      files.push({ original, destination, name });
    }
    assert(files.length > 100, `${kind} cache is unexpectedly empty`);
    for (const file of sample(files, 3)) assert.equal(digest(file.destination), digest(file.original), file.name);
  }
});

test('local community downloads serve listed files while refusing unlisted paths and traversal', async (context) => {
  const previewDownloads = path.resolve(SITE, '..', 'cool-repo');
  if (DOWNLOADS !== previewDownloads) {
    context.skip('The local preview server uses the sibling cool-repo checkout.');
    return;
  }
  const outfit = library().items.find((item) => item.game === 'rdr2' && item.category === 'outfits');
  const file = outfit?.files.find((entry) => entry.path?.endsWith('.json'));
  assert(file, 'A new RDR2 outfit is required to exercise the download route');
  const server = createServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const route = `/community-files/${file.path.split('/').map(encodeURIComponent).join('/')}`;
  try {
    const head = await fetch(base + route, { method: 'HEAD' });
    assert.equal(head.status, 200);
    assert.equal(Number(head.headers.get('content-length')), file.size);
    assert.equal(head.headers.get('content-type'), 'application/json');
    assert.equal(await head.text(), '');
    const response = await fetch(base + route);
    assert.equal(response.status, 200);
    const body = Buffer.from(await response.arrayBuffer());
    assert.equal(crypto.createHash('sha256').update(body).digest('hex'), file.sha256);
    for (const denied of ['/community-files/.git/config', '/community-files/README.md',
      '/community-files/downloads/%2e%2e%2f%2e%2e%2f.git/config',
      '/community-files/downloads/%252e%252e/config']) {
      assert.equal((await fetch(base + denied)).status, 404, denied);
    }
    const missing = await fetch(base + '/community-files/.git/config', { method: 'HEAD' });
    assert.equal(missing.status, 404);
    assert.equal(await missing.text(), '');
    const post = await fetch(base + route, { method: 'POST' });
    assert.equal(post.status, 405);
    assert.equal(post.headers.get('allow'), 'GET, HEAD');
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test('resource pages expose six games and keep the requested ad placements', () => {
  const adURL = 'https://bellnewyork.org/21/916d4be3288f94a3bc49ab6cdaef5ba9';
  const container = 'container-916d4be3288f94a3bc49ab6cdaef5ba9';
  for (const relative of ['resources/index.html', 'resources/guides/index.html']) {
    const html = fs.readFileSync(path.join(SITE, relative), 'utf8');
    const scripts = [...html.matchAll(/<script\b[^>]*>/gi)].map((match) => match[0]);
    const ads = scripts.filter((tag) => tag.includes(adURL));
    assert.equal(ads.length, 1, `${relative}: ad loader count`);
    assert.match(ads[0], /\basync(?:\s|=|>)/i);
    assert.match(ads[0], /data-cfasync=["']false["']/i);
    assert.equal([...html.matchAll(new RegExp(`\\bid=["']${container}["']`, 'g'))].length, 1,
      `${relative}: ad container count`);
    assert.match(html, /class="ad-sidebar" aria-label="Advertisement"/);
    for (const game of GAMES) {
      assert(new RegExp(`(?:data-game|value)=["']${game}["']`).test(html), `${relative}: missing ${game} selector`);
    }
  }
  for (const relative of ['resources/index.html', 'resources/guides/index.html', 'resources/redm/ui-presets/index.html', 'products/free/index.html']) {
    const html = fs.readFileSync(path.join(SITE, relative), 'utf8');
    const headAd = 'https://accountut.com/1/21bac2cf6146c6ff2689111563b5f00a';
    const bodyAd = 'https://bellnewyork.org/14/179ef803d1a93ce7af0ad7b09a49ead9';
    for (const [url, tag] of [[headAd, '</head>'], [bodyAd, '</body>']]) {
      const snippet = `<script data-cfasync="false" src="${url}"></script>`;
      assert.equal(html.split(snippet).length, 2, `${relative}: duplicate or missing ad script`);
      assert(html.slice(html.indexOf(snippet) + snippet.length).trimStart().startsWith(tag), `${relative}: ad placement before ${tag}`);
    }
    assert(html.includes('href="https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd"'), relative);
  }
  const ui = fs.readFileSync(path.join(SITE, 'resources/index.html'), 'utf8')
    + fs.readFileSync(path.join(SITE, 'resources/catalog.js'), 'utf8');
  for (const label of ['ClickUI', 'ListUI', '2Take1', 'Stand', 'Impulse', 'Silkroad', 'Ozark', 'X-Force']) {
    assert(ui.includes(label), `Missing interface/style filter: ${label}`);
  }
});

test('theme images remain disabled while supported theme downloads stay available', () => {
  const data = library();
  assert.equal(data.themePreviewsEnabled, false);
  const themes = data.items.filter(item => item.category === 'themes');
  assert(themes.length > 500);
  for (const item of themes) {
    assert(['gta5', 'rdr2'].includes(item.game), item.id);
    assert.equal(item.menu, 'Scooby', item.id);
    assert(['ClickUI', 'ListUI'].includes(item.uiStyle), item.id);
    assert(!item.preview && !item.previewCaption && !item.previewKind, item.id);
    assert(item.files.length || item.status === 'in-menu', item.id);
  }
});

test('external GTA mod sources retain provenance, import requirements and actual download contracts', () => {
  const items = library().items;
  const marketplace = items.filter((item) => item.id.startsWith('gta5-modverse-'));
  const authorListings = items.filter((item) => item.id.startsWith('gta5-mods-'));
  assert(marketplace.length > 120, 'Expected public ModVerse outfit and vehicle source metadata');
  const downloadSource = readJSON(path.join(DOWNLOADS, 'catalog/marketplace/direct-downloads-source.json'));
  const listingSource = readJSON(path.join(DOWNLOADS, 'catalog/marketplace/gta5-mods-source.json'));
  const knownSources = new Set([...listingSource.feeds.flatMap(feed => feed.items), ...listingSource.tools].map(item => item.sourceUrl));
  const verifiedSources = new Set(Object.entries(downloadSource.entries)
    .filter(([url, entry]) => knownSources.has(url) && entry.status === 'verified').map(([url]) => url));
  assert(verifiedSources.size > 0, 'Expected at least one verified direct author download');
  assert.deepEqual(new Set(authorListings.map(item => item.sourceUrl)), verifiedSources,
    'Only verified public files belong in the active author catalog');
  const provenance = readJSON(path.join(DOWNLOADS, 'catalog/marketplace/modverse-source.json'));
  assert.equal(provenance.repository, 'xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace');
  assert.match(provenance.revision, /^[a-f0-9]{40}$/);
  for (const item of marketplace) {
    assert(item.format && item.compatibility, `Missing original format requirements: ${item.id}`);
    assert(item.credits && item.sourceUrl, `Missing source attribution: ${item.id}`);
    assert.equal(item.status, 'download', item.id);
    assert.equal(item.downloadsOnScooby, true, item.id);
    assert(item.requirements?.length, `Missing importer requirements: ${item.id}`);
    assert.notEqual(item.category, 'themes', `Cherax-only ClickGUI theme advertised as Scooby: ${item.id}`);
    assert.match(item.publisherChecksum?.sha256, /^[a-f0-9]{64}$/, item.id);
    // Public JSON line-ending normalization can invalidate publisher byte hashes.
    // Unverified publisher claims must not be presented as the served file hash.
    assert(item.publisherChecksum.verification.includes('not independently verified'), item.id);
    for (const file of item.files) {
      assert.equal(file.sha256, undefined, item.id);
      // Cross-origin JSON/raw binary navigation can replace the Scooby page.
      // These resources must use the frontend's fetch-and-blob download path.
      assert.notEqual(file.downloadMethod, 'direct', item.id);
    }
  }
  for (const item of authorListings) {
    assert.equal(item.status, 'download', item.id);
    assert.equal(item.downloadsOnScooby, true, item.id);
    assert.equal(item.files.length, 1, `A verified package is required for Download: ${item.id}`);
    assert.equal(new URL(item.sourceUrl).origin, 'https://www.gta5-mods.com', item.id);
    assert(item.credits && item.requirements?.length, item.id);
    const verified = downloadSource.entries[item.sourceUrl];
    const file = item.files[0];
    const host = httpsURL(file.url, item.id).hostname;
    assert(['files.gta5-mods.com', 'github.com'].includes(host), item.id);
    if (host === 'github.com') assert(new URL(file.url).pathname.includes('/releases/download/'), item.id);
    assert.equal(file.url, verified.url, item.id);
    assert.equal(file.name, verified.name, item.id);
    assert.equal(file.size, verified.size, item.id);
    assert.equal(file.downloadMethod, 'direct', item.id);
    assert.match(file.name, /\.(?:zip|rar|7z|oiv|asi|dll)$/i, item.id);
    assert.match(file.contentType, /^(?:application\/(?:zip|x-zip-compressed|x-rar-compressed|vnd\.rar|x-7z-compressed|octet-stream|binary)|binary\/octet-stream)(?:;|$)/i, item.id);
    assert.equal(item.downloadVerification.responseStatus, 200, item.id);
    assert([200, 206].includes(item.downloadVerification.probeStatus), item.id);
    assert(['zip', 'rar', '7z', 'native-plugin'].includes(file.packageKind), item.id);
    assert(Number.isFinite(Date.parse(item.downloadVerification.verifiedAt)), item.id);
    if (new URL(item.sourceUrl).pathname.startsWith('/paintjobs/')) {
      assert.equal(item.category, 'liveries', `External livery mixed into native LSC PaintJobs: ${item.id}`);
      assert(item.compatibility.includes('separate from Scooby LSC PaintJobs'), item.id);
    }
  }
  // Unresolvable public listings remain auditable without a broken Download card.
  for (const sourceUrl of knownSources) {
    if (!verifiedSources.has(sourceUrl)) assert(downloadSource.failures[sourceUrl]?.reason, `Missing resolution reason: ${sourceUrl}`);
  }
});
