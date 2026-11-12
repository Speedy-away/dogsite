'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { plain, pageUrl } = require('./seo-structured');
const menus = require('../resources/menus.js');
const { gtaAddonCategory } = require('../resources/taxonomy.js');

const ROOT = path.resolve(__dirname, '..');
const ORIGIN = 'https://scoobymenu.cc';
const GAMES = ['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d'];
const read = (file) => fs.readFileSync(path.join(ROOT, file), 'utf8');
const json = (file) => JSON.parse(read(file));
let snapshot;
function inventory() {
  if (!snapshot) snapshot = require('./resource-pages.cjs').buildData();
  assert(Array.isArray(snapshot.pages), 'The resource directory must expose its generated page inventory');
  return snapshot.pages;
}
function markup(file) {
  return read(file).replace(/<script\b[^>]*>[\s\S]*?<\/script>|<!--[^]*?-->/gi, '');
}
function attributes(tag) {
  return Object.fromEntries([...tag.matchAll(/([\w:-]+)\s*=\s*(["'])(.*?)\2/g)]
    .map((match) => [match[1].toLowerCase(), match[3]]));
}
function metadata(html, name) {
  const tags = [...html.matchAll(/<meta\b[^>]*>/gi)].map((match) => attributes(match[0]));
  return tags.filter((tag) => (tag.name || tag.property || '').toLowerCase() === name.toLowerCase())
    .map((tag) => plain(tag.content || ''));
}
function links(file) {
  return [...markup(file).matchAll(/<a\b[^>]*\shref=(["'])(.*?)\1/gi)]
    .map((match) => new URL(match[2].replace(/&amp;/g, '&'), pageUrl(file)));
}
function schemaNodes(value) {
  if (!value || typeof value !== 'object') return [];
  return [value, ...Object.values(value).flatMap(schemaNodes)];
}
function schemas(file) {
  return [...read(file).matchAll(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
    .flatMap((match) => schemaNodes(JSON.parse(match[1])));
}
function hasType(node, type) {
  return Array.isArray(node['@type']) ? node['@type'].includes(type) : node['@type'] === type;
}

test('Resources shares game-specific previews and exposes RedM graphics search topics', () => {
  const { cardFor } = require('./social-cards');
  const taxonomy = require('../resources/taxonomy.js');
  const files = ['resources/index.html', 'resources/guides/index.html',
    ...GAMES.map(game => `resources/${game}/index.html`), 'resources/redm/graphics-packs/index.html'];
  const images = files.map(file => {
    const html = read(file), card = cardFor(file);
    const [image] = metadata(html, 'og:image');
    assert.equal(image, ORIGIN + card.path, file);
    assert.equal(metadata(html, 'twitter:image')[0], image, file);
    assert.equal(metadata(html, 'og:description')[0], metadata(html, 'description')[0], file);
    const png = fs.readFileSync(path.join(ROOT, card.path));
    assert.equal(png.readUInt32BE(16), 1200, file);
    assert.equal(png.readUInt32BE(20), 630, file);
    return image;
  });
  assert.equal(new Set(images).size, files.length);

  const redm = files.at(-1);
  const keywords = metadata(read(redm), 'keywords')[0];
  assert.match(keywords, /RedM PvP packs/);
  assert.match(keywords, /RedM RP packs/);
  assert.match(keywords, /RedM cinematic packs/);
  const queries = links(redm).filter(url => url.pathname === '/resources/redm/graphics-packs/').map(url => url.searchParams.get('q'));
  const { items } = require('./resource-pages.cjs').buildData();
  const packs = items.filter(item => item.game === 'redm' && item.category === 'graphics-packs');
  for (const topic of taxonomy.REDM_GRAPHICS_TOPICS) {
    assert(queries.includes(topic.query), topic.name);
    const matches = packs.filter(item => taxonomy.redmGraphicsTopics(item).includes(topic));
    assert(matches.length > 0 && matches.length < packs.length, topic.name);
    assert(matches.every(item => taxonomy.tagsFor(item).includes(topic.query)), topic.name);
    assert.equal(taxonomy.redmGraphicsTopicForQuery(topic.query), topic);
  }
  assert.deepEqual(taxonomy.redmGraphicsTopics({ game: 'fivem', category: 'graphics-packs', tags: ['pvp packs'] }), []);
});

function expectedInventory() {
  const prepared = fs.existsSync(path.join(ROOT, 'community/data/menu-resources.json')) ? json('community/data/menu-resources.json') : {};
  const supplement = menus.mergeCheraxResources(prepared, json('community/data/cherax-resources.json'));
  const overrides = new Map((supplement.libraryOverrides || []).map(item => [item.id, item]));
  const legacy = menus.legacyOverrideMap(supplement);
  const items = new Map();
  for (const item of json('community/data/library.json').items) {
    assert.notEqual(item.category, 'lua', 'Removed imported Lua must not return to the base library');
    items.set(item.id, { ...item, ...overrides.get(item.id), id: item.id });
  }
  for (const item of supplement.items || []) {
    if (item.category === 'lua') {
      assert.equal(item.menuResource, true, item.id);
      assert.equal(item.sourceCatalog, 'menu-resources', item.id);
      assert(item.files?.length || (item.downloadStatus === 'pending' && Array.isArray(item.files) && !item.files.length) ||
        (menus.isStandLua(item) && item.status === 'author-hosted' && /^https:\/\/github\.com\//.test(item.sourceUrl)), item.id);
      assert(Array.isArray(item.supportedMenus) && item.supportedMenus.length, `Lua needs explicit menu API compatibility: ${item.id}`);
    }
    items.set(item.id, item);
  }
  for (const item of json('community/data/gta5-editions.json').items) {
    assert(!items.has(item.id), `Reviewed listing duplicates ${item.id}`);
    items.set(item.id, item);
  }
  for (const catalog of ['nenyoo', 'scooby-lua']) {
    for (const item of json(`community/data/${catalog}.json`).items) {
      assert(!items.has(item.id), `${catalog} listing duplicates ${item.id}`);
      items.set(item.id, item);
    }
  }
  const downloadSources = new Set([...items.values()].filter(item => item.game === 'gta5' && item.status !== 'author-hosted').map(item => item.sourceUrl));
  for (const item of json('community/data/gta5-addons.json').items) {
    if (downloadSources.has(item.sourceUrl)) continue;
    assert(!items.has(item.id), `Addon listing duplicates ${item.id}`);
    items.set(item.id, item);
  }
  for (const kind of ['vehicles', 'outfits']) {
    const index = json(`community/data/${kind}/index.json`);
    const assets = json(`community/data/${kind}/local-assets.json`);
    assert.equal(index.items.length, index.totalItems);
    index.items.forEach((entry, position) => {
      const id = `${kind}-${position}`;
      const formatExtension = menus.fileExtension({ formatPath: assets[position]?.file || entry[1] });
      items.set(id, { id, game: 'gta5', category: kind, format: index.formats?.[entry[5]], attachments: index.attachments?.[position] || 0, ...legacy.get(`${kind}:${position}`), formatExtension, id });
    });
  }
  const scopes = new Map(GAMES.map(game => [`${game}:scooby`, { game, menu: 'scooby', categories: new Set(), items: [] }]));
  for (const original of items.values()) {
    assert(GAMES.includes(original.game), `Unsupported resource game: ${original.game}`);
    for (const menu of menus.menusFor(original.game).filter(menu => !menu.deferred)) {
      if (!menus.supports(original, menu.id)) continue;
      const item = gtaAddonCategory(original, menu.id);
      const key = `${item.game}:${menu.id}`;
      if (!scopes.has(key)) scopes.set(key, { game: item.game, menu: menu.id, categories: new Set(), items: [] });
      const bucket = scopes.get(key);
      bucket.items.push(item);
      const categories = [item.category, ...(item.categories || [])];
      if (item.category === 'vehicles' && item.attachments > 0) categories.push('modded');
      for (const category of categories) bucket.categories.add(category);
    }
  }
  const stand = scopes.get('gta5:stand');
  const archive = stand.items.filter(item => item.oldShares);
  const archiveCategories = new Set(archive.flatMap(item => [item.category, ...(item.categories || []),
    ...(item.category === 'vehicles' && item.attachments > 0 ? ['modded'] : [])]));
  scopes.set('gta5:stand:old-shares', { game: 'gta5', menu: 'stand', archive: 'old-shares', items: archive, categories: archiveCategories });
  return scopes;
}

test('resource routes cover menu-compatible collections and the CS2 Pets submission directory', () => {
  const expected = expectedInventory();
  const pages = inventory();
  const files = new Set(pages.map((page) => page.file));
  assert.equal(files.size, pages.length, 'Duplicate resource landing route');
  const required = new Set();
  for (const bucket of expected.values()) {
    const prefix = `resources/${bucket.game}/${bucket.menu === 'scooby' ? '' : bucket.menu + '/'}${bucket.archive ? bucket.archive + '/' : ''}`;
    required.add(`${prefix}index.html`);
    for (const category of bucket.categories.keys()) required.add(`${prefix}${category}/index.html`);
  }
  required.add('resources/cs2/pets/index.html');
  assert.deepEqual([...files].sort(), [...required].sort());
  for (const page of pages) {
    assert(GAMES.includes(page.game), page.file);
    const category = page.category && page.category !== 'all' ? page.category : null;
    const bucket = expected.get(`${page.game}:${page.menu}${page.archive ? ':' + page.archive : ''}`);
    assert(bucket, `Unexpected menu route: ${page.file}`);
    const listed = category ? bucket.items.filter(item => item.category === category || item.categories?.includes(category) || (category === 'modded' && item.category === 'vehicles' && item.attachments > 0)) : bucket.items;
    const { nativeDefault } = menus.presetFormatScope(listed, page.menu, category || 'all');
    const subset = nativeDefault ? listed.filter(item => !menus.alternatePreset(item, page.menu)) : listed;
    const count = subset.length;
    assert.equal(page.itemCount, count, `Stale or invented resource count: ${page.file}`);
    if (category && page.file !== 'resources/cs2/pets/index.html') assert(count > 0, `Unexpected empty category: ${page.file}`);
    for (const item of page.samples) assert(subset.some(expected => expected.id === item.id), `Incompatible sample on ${page.file}: ${item.id}`);
    if (!subset.some(item => item.category === 'lua' || item.category === 'mod-menus')) assert(!/\blua\b/i.test([page.title, page.description, page.keywords].join(' ')), page.file);
    if (subset.length && subset.every(item => item.downloadStatus === 'pending' && !item.files?.length)) {
      assert((page.menu === 'stand' ? /unavailable/i : /coming soon/i).test(page.title + ' ' + page.description), page.file);
    }
  }
});

test('resource pages have unique self-canonical metadata and explicit indexing directives', () => {
  const { pages: registered } = require('./seo-metadata');
  const titles = new Set(), descriptions = new Set();
  for (const page of inventory()) {
    const html = read(page.file);
    const head = html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0];
    assert(head, page.file);
    assert(registered[page.file], `Resource page is missing from the central SEO catalog: ${page.file}`);
    const title = plain(head.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i)?.[1] || '');
    const description = metadata(head, 'description');
    const keywords = metadata(head, 'keywords');
    assert.equal(title, page.title, page.file);
    assert.equal(description.length, 1, page.file);
    assert.equal(description[0], page.description, page.file);
    assert.equal(keywords.length, 1, page.file);
    assert(keywords[0].trim(), page.file);
    assert(!titles.has(title), `Duplicate resource title: ${title}`);
    assert(!descriptions.has(description[0]), `Duplicate resource description: ${page.file}`);
    titles.add(title); descriptions.add(description[0]);
    if (page.game === 'gta5') {
      assert(title.includes(menus.menuName(page.menu)), `Missing menu-specific title: ${page.file}`);
      assert(keywords[0].includes(menus.menuName(page.menu)), `Missing menu-specific keywords: ${page.file}`);
    }
    if (!['gta5', 'rdr2'].includes(page.game)) {
      assert(!/\bListUI\b/i.test(`${title} ${description[0]} ${keywords[0]}`),
        `A game without ListUI is promoted as supporting it: ${page.file}`);
    }
    const canonical = [...head.matchAll(/<link\b[^>]*>/gi)].map((match) => attributes(match[0]))
      .filter((tag) => tag.rel === 'canonical');
    assert.deepEqual(canonical.map((tag) => tag.href), [pageUrl(page.file)], page.file);
    const robots = metadata(head, 'robots').join(',');
    if (page.category === 'pets' && !page.itemCount) assert.equal(robots, 'noindex, follow', page.file);
    else assert(/\bindex\b/.test(robots) && !/\bnoindex\b/.test(robots), page.file);
    assert(!/<meta\b[^>]*http-equiv=["']refresh["']/i.test(head), page.file);
    assert.equal(metadata(head, 'og:url')[0], pageUrl(page.file), page.file);
    assert.equal(metadata(head, 'og:title')[0], title, page.file);
    assert.equal(metadata(head, 'og:description')[0], description[0], page.file);
    assert.equal((markup(page.file).match(/<h1\b/gi) || []).length, 1, page.file);
  }
});

test('game and category links are crawlable and indexable resource pages appear in both sitemaps', () => {
  const pages = inventory();
  assert.doesNotMatch(markup('resources/index.html'), /Browse GTA 5 menu collections|class="menu-directory"/i);
  const rootLinks = links('resources/index.html').filter((url) => url.origin === ORIGIN).map((url) => url.pathname);
  const sitemap = read('sitemap.xml');
  const locations = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
  const directory = links('sitemap/index.html').map((url) => url.href);
  const rootKeywords = metadata(read('resources/index.html'), 'keywords')[0];
  for (const menu of ['cherax', 'stand']) {
    const menuLinks = links(`resources/gta5/${menu}/index.html`);
    for (const [category, label] of [['lua', 'Lua scripts'], ['outfits', 'outfits'], ['vehicles', 'vehicles']]) {
      const phrase = `${menus.menuName(menu)} ${label}`;
      const route = `/resources/gta5/${menu}/${category}/`;
      assert(menuLinks.some((url) => url.href === ORIGIN + route), `Menu collection omits ${phrase}`);
      assert(rootKeywords.includes(phrase), `Missing root keyword for ${phrase}`);
      assert(metadata(read(route.slice(1) + 'index.html'), 'keywords')[0].includes(phrase), route);
    }
  }
  for (const url of [...locations, ...directory]) assert(!new URL(url).pathname.startsWith('/community/'), url);
  for (const route of ['/resources/', '/resources/guides/']) {
    assert(locations.includes(ORIGIN + route), route);
    assert(directory.includes(ORIGIN + route), route);
  }
  for (const game of GAMES) assert(rootLinks.includes(`/resources/${game}/`), `No crawlable ${game} resource link`);
  for (const page of pages) {
    const url = pageUrl(page.file);
    const indexable = page.category !== 'pets' || page.itemCount > 0;
    assert.equal(locations.filter((location) => location === url).length, Number(indexable), `XML sitemap indexing mismatch for ${url}`);
    assert.equal(directory.includes(url), indexable, `HTML sitemap indexing mismatch for ${url}`);
    assert(!url.includes('?') && !url.includes('#'), url);
    const hrefs = links(page.file);
    assert(hrefs.some((href) => href.origin === ORIGIN && href.pathname === '/resources/'), page.file);
    for (const href of hrefs.filter((link) => link.origin === ORIGIN)) {
      const target = path.join(ROOT, decodeURIComponent(href.pathname));
      assert(fs.existsSync(target), `${page.file} links to a missing target: ${href.pathname}`);
    }
    if (page.category && page.category !== 'all') {
      const parent = `resources/${page.game}/${page.menu === 'scooby' ? '' : page.menu + '/'}${page.archive ? page.archive + '/' : ''}index.html`;
      assert(links(parent).some((href) => href.href === url), `Game directory omits ${url}`);
    } else if (page.archive) {
      assert(links(`resources/${page.game}/${page.menu}/index.html`).some(href => href.href === url), `Menu omits its archive ${url}`);
    } else if (page.menu !== 'scooby') {
      assert(links(`resources/${page.game}/index.html`).some(href => href.href === url), `Default collection omits menu directory ${url}`);
    }
    assert(hrefs.some(href => href.href === `${url}#collection`), `Missing interactive browse link: ${page.file}`);
    assert(!hrefs.some(href => href.pathname === '/resources/' && href.searchParams.has('game')), page.file);
  }
  const expectedURLs = new Set(pages.map(page => pageUrl(page.file)));
  assert.deepEqual(json('resources/routes.json').map(route => ORIGIN + route).sort(), [...expectedURLs].sort());
  for (const url of locations.filter(url => /^https:\/\/scoobymenu\.cc\/resources\/(?:gta5|rdr2|cs2|fivem|redm|l4d)\//.test(url))) assert(expectedURLs.has(url), `Stale resource route in sitemap: ${url}`);
});

test('old resource bookmarks redirect to the matching page with filters and anchors intact', () => {
  for (const old of ['community/index.html', 'community/guides/index.html', 'community/gta5/cherax/vehicles/index.html']) {
    const html = read(old);
    const route = '/' + old.replace(/^community\//, 'resources/').replace(/index\.html$/, '');
    const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
    assert(script, old);
    assert(metadata(html, 'robots').includes('noindex'), old);
    assert(links(old).some(link => link.pathname === route), old);
    assert(fs.existsSync(path.join(ROOT, route, 'index.html')), route);
    const search = '?game=gta5&menu=cherax&category=vehicles&edition=legacy';
    const hash = '#collection';
    let redirected;
    vm.runInNewContext(script, { location: { search, hash, replace: url => { redirected = url; } } });
    assert.equal(redirected, route + search + hash);
  }
});

test('installation guides have clean scoped links, unique SEO pages and canonical aliases', () => {
  const { buildGuideData } = require('./resource-guides.cjs');
  const guides = buildGuideData(require('./resource-pages.cjs').buildData());
  const manifest = json('resources/guides/routes.json');
  assert.deepEqual(manifest, guides.routes);
  const sitemap = read('sitemap.xml');
  const directory = read('sitemap/index.html');
  const titles = new Set();
  for (const guide of guides.pages) {
    const html = read(guide.file);
    const url = ORIGIN + guide.href;
    assert(!titles.has(guide.title), guide.file);
    titles.add(guide.title);
    assert.equal(metadata(html, 'og:url')[0], url);
    assert(html.includes(`<link rel="canonical" href="${url}">`), guide.file);
    assert(html.includes(`<section id="${guide.topics[0].id}"`), guide.file);
    assert(sitemap.includes(`<loc>${url}</loc>`), guide.file);
    assert(directory.includes(`href="${guide.href}"`), guide.file);
  }
  for (const [alias, canonical] of Object.entries(manifest)) {
    if (alias === canonical) continue;
    const redirect = read(`${alias.slice(1)}index.html`);
    assert.match(redirect, /content="noindex, follow"/);
    assert(redirect.includes(`location.replace(${JSON.stringify(canonical)} + location.search + location.hash)`));
    assert(!sitemap.includes(`<loc>${ORIGIN + alias}</loc>`), alias);
    assert(!directory.includes(`href="${alias}"`), alias);
  }
  assert(links('resources/gta5/cherax/lua/index.html').some(url => url.pathname === '/resources/guides/gta5/cherax/lua/' && !url.search));
});

test('GTA edition filters use verified packages and author-hosted cards retain their own actions', () => {
  const editions = require('../resources/editions.js');
  const reviewed = json('community/data/gta5-editions.json');
  const { items } = require('./resource-pages.cjs').buildData();
  const published = new Map(items.map(item => [item.id, item]));
  for (const [id, record] of Object.entries(reviewed.verified)) {
    const item = published.get(id);
    assert.equal(editions.support(item), record.editionSupport, `Verification no longer matches the published package for ${id}`);
    assert.equal(editions.support(editions.withVerification({ id, game: 'gta5', files: [{ path: 'changed.zip' }] }, reviewed)), '');
    for (const filter of ['enhanced', 'legacy', 'both']) {
      assert.equal(editions.matches(item, filter), record.editionSupport === filter || record.editionSupport === 'both', `${id}, ${filter}`);
    }
  }
  const unknown = { game: 'gta5', edition: 'Legacy and Enhanced may work' };
  assert(editions.matches(unknown, ''));
  assert(!editions.matches(unknown, 'enhanced'));
  assert(!editions.matches(unknown, 'legacy'));
  assert(!editions.matches(unknown, 'both'));
  assert.equal(editions.choice('rdr2', 'legacy'), '');

  const graphics = read('resources/gta5/graphics-packs/index.html');
  for (const [variant, label, url] of [
    ['evolved', 'Legacy', 'https://razedmods.com/gtavlegacy'],
    ['enhanced', 'Enhanced', 'https://razedmods.com/gtavenhanced']
  ]) {
    const card = graphics.match(new RegExp(`<article[^>]+id="resource-gta5-razed-naturalvision-${variant}"[^>]*>[\\s\\S]*?</article>`))?.[0];
    assert(card?.includes(`>${label}</span>`), variant);
    assert(card.includes('By Razed Mods') && card.includes(`href="${url}"`), variant);
    assert(!card.includes('data-download-file='), 'Author pages are links, not downloadable files');
  }
});

test('Left 4 Dead filters keep game-specific add-ons and shared files in the right collections', () => {
  const editions = require('../resources/editions.js');
  const resources = inventory().find(page => page.game === 'l4d' && !page.category);
  const { items } = require('./resource-pages.cjs').buildData();
  const listing = items.filter(item => item.game === 'l4d');
  assert.equal(editions.choice('gta5', 'l4d1'), '');
  for (const game of ['l4d1', 'l4d2']) {
    assert.equal(editions.choice('l4d', game), game);
    assert(links(resources.file).some(url => url.searchParams.get('edition') === game));
    const visible = listing.filter(item => editions.matches(item, game));
    assert(visible.some(item => item.category === 'maps' && item.edition === game && item.status === 'author-hosted'));
    assert(visible.some(item => item.category === 'languages' && editions.support(item) === 'both'));
    assert(!visible.some(item => item.edition === (game === 'l4d1' ? 'l4d2' : 'l4d1')));
  }
  const sky = listing.find(item => item.id === 'l4d-galaxy-skybox');
  assert.equal(editions.support(sky), 'both');
  assert.equal(fs.statSync(path.join(ROOT, sky.files[0].url)).size, sky.files[0].size);
  assert(read('resources/l4d/skyboxes/index.html').includes(sky.files[0].url));
});

test('CS2 lists GameBanana skybox sources with conversion requirements and author links', () => {
  const source = json('project/community-menu-sources/cs2-gamebanana-skyboxes.json');
  const page = inventory().find(page => page.game === 'cs2' && page.category === 'skyboxes');
  const html = read(page.file);
  assert(source.items.length > 1);
  assert(page.samples.some(item => item.files?.length), 'Native downloads remain available');
  for (const entry of source.items) {
    assert.match(entry.sourceUrl, /^https:\/\/gamebanana\.com\/mods\/\d+$/);
    const sample = page.samples.find(item => item.id === entry.id);
    assert.equal(sample?.status, 'author-hosted', entry.id);
    assert.deepEqual(sample.files, [], entry.id);
    const card = html.match(new RegExp(`<article[^>]+id="resource-${entry.id}"[^>]*>[\\s\\S]*?</article>`))?.[0];
    assert(card?.includes('CS2 conversion required'), entry.id);
    assert(card.includes(`href="${entry.sourceUrl}"`), entry.id);
    assert(!card.includes('data-download-file='), entry.id);
  }
});

test('CS2 visual resources list source requirements and preserve the downloadable PNG panoramas', () => {
  const cs2 = inventory().filter(page => page.game === 'cs2');
  const skyboxes = cs2.find(page => page.category === 'skyboxes');
  const textures = cs2.find(page => page.category === 'textures');
  for (const [page, manifest, label] of [
    [skyboxes, 'cs2-hdri-skies', 'Compile in CS2 Workshop Tools'],
    [textures, 'cs2-hammer-materials', 'Build a Source 2 material']
  ]) {
    const sources = json(`project/community-menu-sources/${manifest}.json`).items;
    const html = read(page.file);
    assert(sources.length > 1);
    for (const entry of sources) {
      const listing = page.samples.find(item => item.id === entry.id);
      assert.equal(listing?.status, 'author-hosted', entry.id);
      assert.equal(listing.license, 'CC0', entry.id);
      assert.deepEqual(listing.files, [], entry.id);
      assert(listing.requirementLabel.includes(label), entry.id);
      assert(html.includes(`href="${entry.sourceUrl}"`), entry.id);
    }
  }
  const originals = new Map(json('community/data/library.json').items.map(item => [item.id, item]));
  for (const { id } of json('project/community-menu-sources/cs2-panorama-imports.json').libraryOverrides) {
    const item = skyboxes.samples.find(entry => entry.id === id);
    assert.deepEqual(item?.files, originals.get(id).files, id);
    assert(textures.samples.some(entry => entry.id === id), id);
  }
});

test('resource structured data describes visible collections and real sample entries', () => {
  for (const page of inventory()) {
    const nodes = schemas(page.file);
    const collection = nodes.find((node) => hasType(node, 'CollectionPage') && node.url === pageUrl(page.file));
    assert(collection, `Missing CollectionPage data: ${page.file}`);
    const body = plain(markup(page.file));
    const hrefs = new Set(links(page.file).map((url) => url.href));
    const lists = nodes.filter((node) => hasType(node, 'ItemList'));
    if (page.itemCount > 0) assert(lists.some((list) => list.itemListElement?.length), `No static resource samples: ${page.file}`);
    for (const list of lists) {
      const entries = list.itemListElement || [];
      if (list.numberOfItems !== undefined) {
        assert(Number.isSafeInteger(list.numberOfItems) && list.numberOfItems >= entries.length, page.file);
        assert(list.numberOfItems <= page.itemCount, `Invented structured resource count: ${page.file}`);
      }
      for (const [index, entry] of entries.entries()) {
        const item = entry.item || entry;
        const name = item.name || entry.name;
        const url = typeof item === 'string' ? item : item.url || entry.url;
        assert(typeof name === 'string' && name.trim(), `Unnamed resource sample: ${page.file}`);
        assert(body.includes(name), `Structured sample is absent from visible HTML: ${page.file}: ${name}`);
        assert(typeof url === 'string' && hrefs.has(new URL(url, pageUrl(page.file)).href),
          `Structured sample has no crawlable visible link: ${page.file}: ${name}`);
        if (entry.position !== undefined) assert.equal(entry.position, index + 1, page.file);
      }
    }
    for (const node of nodes.filter((node) => hasType(node, 'BreadcrumbList'))) {
      const trail = node.itemListElement || [];
      assert(trail.some((entry) => entry.item === pageUrl(page.file)), page.file);
      for (const [index, entry] of trail.entries()) assert.equal(entry.position, index + 1, page.file);
    }
    if (!page.itemCount) {
      assert(/no .{0,35}(?:downloads|files|resources|packs)|(?:downloads|files|resources).{0,35}(?:yet|available|added)|coming soon/i.test(body),
        `${page.file} must state that its downloadable catalog is empty`);
    }
  }
});

test('pending downloads and verified theme captures render honest static actions', () => {
  const { renderPage } = require('./resource-pages.cjs');
  const base = inventory().find(page => page.game === 'gta5' && page.menu === 'scooby');
  const cherax = inventory().find(page => page.game === 'gta5' && page.menu === 'cherax' && page.category === 'lua');
  const entry = {
    id: 'availability-regression', game: 'gta5', category: 'lua', name: 'API-specific script listing',
    menuResource: true, sourceCatalog: 'menu-resources', sourceMenu: 'cherax', supportedMenus: ['cherax'],
    downloadStatus: 'pending', files: [], changelog: [{ version: '1.0', changes: ['Published source description'] }]
  };
  const pending = renderPage({ ...cherax, samples: [entry], itemCount: 1, pendingCount: 1 });
  const article = pending.match(/<article\b[^>]*>[\s\S]*?<\/article>/)?.[0];
  assert(article, 'Missing pending source listing');
  assert(!article.includes('Download — Coming soon'), 'Cherax source-only cards omit the disabled download action');
  const standArchive = inventory().find(page => page.archive && page.category === 'lua');
  const unavailable = renderPage({ ...standArchive, samples: [{ ...entry, sourceMenu: 'stand', supportedMenus: ['stand'], downloadLabel: 'Download unavailable' }] });
  assert.match(unavailable, /<button\b[^>]*\bdisabled\b[^>]*>Download unavailable<\/button>/);
  assert(!article.includes('data-download-file='), 'Pending metadata must not expose a pretend download');
  assert(article.includes('Published source description') && article.includes('Changelog'));
  assert(!article.includes('class="resource-tags"'), 'Search tags should stay out of the listing');
  assert(article.includes('In Scooby, use the Cherax Lua compatibility layer to load this script.'));
  const withoutNotes = renderPage({ ...base, samples: [{ ...entry, changelog: undefined }] });
  assert(withoutNotes.includes('data-resource-changelog=') && withoutNotes.includes('&quot;notes&quot;:[]'), 'Missing changelogs need an honest empty popup');
  assert(withoutNotes.includes('&quot;hash&quot;:&quot;#changelog-'));
  assert(withoutNotes.includes('id="resource-changelog" aria-labelledby="resource-changelog-title"'), 'The changelog dialog needs an accessible title');

  const crosslisted = renderPage({ ...base, samples: [{ ...entry, listedMenus: ['scooby', 'cherax'], requirementLabel: 'Requires the Cherax Lua API or its supported compatibility layer' }] });
  assert(crosslisted.includes('Requires the Cherax Lua API or its supported compatibility layer'));
  const unspecified = renderPage({ ...base, samples: [{ ...entry, listedMenus: ['scooby', 'cherax'] }] });
  assert(unspecified.includes('Requires the original menu format and a compatible loader or importer.'));

  const theme = { ...entry, category: 'themes', preview: 'https://example.invalid/captured-menu.png', changelog: undefined };
  const unverified = renderPage({ ...base, samples: [theme] });
  assert(!unverified.includes('captured-menu.png'), 'Unverified theme imagery must stay hidden');
  const verified = renderPage({ ...base, samples: [{ ...theme, previewVerified: true }] });
  assert(verified.includes('src="https://example.invalid/captured-menu.png"'), 'A verified source capture may be displayed');
  assert(!verified.includes('In Scooby, use the Cherax Lua compatibility layer'));
});

test('CS2 Pets exposes submissions and shows pack contents and provenance in static listings', () => {
  const { renderPage } = require('./resource-pages.cjs');
  const page = inventory().find(page => page.game === 'cs2' && page.category === 'pets');
  const guide = '/resources/guides/cs2/pets/';
  const guideRoutes = { [guide]: guide };
  const empty = renderPage({ ...page, samples: [], itemCount: 0 }, guideRoutes);
  assert.deepEqual(metadata(empty, 'robots'), ['noindex, follow']);
  assert.match(empty, /No CS2 pet packs are listed yet/);
  assert(empty.includes(`href="${guide}#cs2-pet-submissions">Add a pet pack`));
  assert.match(empty, /href="\/resources\/cs2\/pets\/#collection"/);

  const pack = {
    id: 'pet-pack-fixture', game: 'cs2', category: 'pets', name: 'Pet pack fixture',
    resourcePaths: ['models/pets/fox.vmdl', 'models/pets/rabbit.vmdl'],
    credits: 'Example & Co', license: 'CC BY 4.0', sourceUrl: 'https://example.invalid/pet-pack',
    files: [{ url: 'https://example.invalid/pet-pack.zip', name: 'Pet pack.zip' }]
  };
  const local = {
    ...pack, id: 'pet-reference-fixture', name: 'Local pet pack fixture', status: 'in-menu', files: [],
    compatibility: 'Build locally with the required donor files.', sourceUrl: undefined, source: 'Local donor models'
  };
  const populated = renderPage({ ...page, samples: [pack, local], itemCount: 2 }, guideRoutes);
  assert.match(metadata(populated, 'robots')[0], /^index, follow\b/);
  const [download, reference] = populated.match(/<article\b[^>]*>[\s\S]*?<\/article>/g);
  assert.match(download, /data-download-file=/);
  assert.match(download, /<summary>Details<\/summary>/);
  assert.match(download, /<li>models\/pets\/fox\.vmdl<\/li><li>models\/pets\/rabbit\.vmdl<\/li>/);
  assert.match(download, /Credits: Example &amp; Co/);
  assert.match(download, /License: CC BY 4\.0/);
  assert.match(download, /href="https:\/\/example\.invalid\/pet-pack"[^>]*>Source ↗/);
  assert.doesNotMatch(reference, /data-download-file=/);
  assert.match(reference, /Locally generated pet pack/);
  assert.match(reference, /Source: Local donor models/);
  assert.match(reference, /Build locally with the required donor files/);
});

test('Lua search tags keep script-specific names, source filenames and topics', () => {
  const { tagsFor, searchText } = require('../resources/taxonomy.js');
  const entry = {
    game: 'gta5', category: 'lua', sourceMenu: 'stand', name: 'Chat Translator',
    sourceFilename: 'translator_v2.pluto', tags: ['Translation', 'Chat']
  };
  const tags = tagsFor(entry);
  for (const tag of ['chat translator', 'translator v2', 'pluto', 'translation']) {
    assert(tags.includes(tag), tag);
    assert(searchText(entry).includes(tag), tag);
  }
});
