'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { plain, pageUrl } = require('./seo-structured');
const menus = require('../resources/menus.js');

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

function expectedInventory() {
  const supplement = fs.existsSync(path.join(ROOT, 'community/data/menu-resources.json')) ? json('community/data/menu-resources.json') : {};
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
      assert(item.files?.length || (item.downloadStatus === 'pending' && Array.isArray(item.files) && !item.files.length), item.id);
      assert(Array.isArray(item.supportedMenus) && item.supportedMenus.length, `Lua needs explicit menu API compatibility: ${item.id}`);
    }
    items.set(item.id, item);
  }
  for (const kind of ['vehicles', 'outfits']) {
    const index = json(`community/data/${kind}/index.json`);
    assert.equal(index.items.length, index.totalItems);
    index.items.forEach((entry, position) => {
      const id = `${kind}-${position}`;
      items.set(id, { id, game: 'gta5', category: kind, format: index.formats?.[entry[5]], attachments: index.attachments?.[position] || 0, ...legacy.get(`${kind}:${position}`), id });
    });
  }
  const scopes = new Map(GAMES.map(game => [`${game}:scooby`, { game, menu: 'scooby', total: 0, categories: new Map(), items: [] }]));
  for (const item of items.values()) {
    assert(GAMES.includes(item.game), `Unsupported resource game: ${item.game}`);
    for (const menu of menus.MENUS.filter(menu => !menu.deferred && (menu.id === 'scooby' || item.game === 'gta5'))) {
      if (!menus.supports(item, menu.id)) continue;
      const key = `${item.game}:${menu.id}`;
      if (!scopes.has(key)) scopes.set(key, { game: item.game, menu: menu.id, total: 0, categories: new Map(), items: [] });
      const bucket = scopes.get(key);
      bucket.total++; bucket.items.push(item);
      const categories = [item.category, ...(item.categories || [])];
      if (item.category === 'vehicles' && item.attachments > 0) categories.push('modded');
      for (const category of new Set(categories)) bucket.categories.set(category, (bucket.categories.get(category) || 0) + 1);
    }
  }
  return scopes;
}

test('resource routes cover actual menu-compatible collections without empty category promises', () => {
  const expected = expectedInventory();
  const pages = inventory();
  const files = new Set(pages.map((page) => page.file));
  assert.equal(files.size, pages.length, 'Duplicate resource landing route');
  const required = new Set();
  for (const bucket of expected.values()) {
    const prefix = `resources/${bucket.game}/${bucket.menu === 'scooby' ? '' : bucket.menu + '/'}`;
    required.add(`${prefix}index.html`);
    for (const category of bucket.categories.keys()) required.add(`${prefix}${category}/index.html`);
  }
  assert.deepEqual([...files].sort(), [...required].sort());
  for (const page of pages) {
    assert(GAMES.includes(page.game), page.file);
    const category = page.category && page.category !== 'all' ? page.category : null;
    const bucket = expected.get(`${page.game}:${page.menu}`);
    assert(bucket, `Unexpected menu route: ${page.file}`);
    const count = category ? bucket.categories.get(category) : bucket.total;
    assert.equal(page.itemCount, count, `Stale or invented resource count: ${page.file}`);
    if (category) assert(count > 0, `Empty category should not have an indexable page: ${page.file}`);
    const subset = category ? bucket.items.filter(item => item.category === category || item.categories?.includes(category) || (category === 'modded' && item.category === 'vehicles' && item.attachments > 0)) : bucket.items;
    for (const item of page.samples) assert(subset.some(expected => expected.id === item.id), `Incompatible sample on ${page.file}: ${item.id}`);
    if (!subset.some(item => item.category === 'lua')) assert(!/\blua\b/i.test([page.title, page.description, page.keywords].join(' ')), page.file);
    if (subset.length && subset.every(item => item.downloadStatus === 'pending' && !item.files?.length)) {
      assert(/coming soon/i.test(page.title + ' ' + page.description), page.file);
    }
  }
});

test('resource pages have unique self-canonical metadata and explicit indexing without JavaScript', () => {
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
    assert(/\bindex\b/.test(robots) && !/\bnoindex\b/.test(robots), page.file);
    assert(!/<meta\b[^>]*http-equiv=["']refresh["']/i.test(head), page.file);
    assert.equal(metadata(head, 'og:url')[0], pageUrl(page.file), page.file);
    assert.equal(metadata(head, 'og:title')[0], title, page.file);
    assert.equal(metadata(head, 'og:description')[0], description[0], page.file);
    assert.equal((markup(page.file).match(/<h1\b/gi) || []).length, 1, page.file);
  }
});

test('game and category links are crawlable and every resource page appears in both sitemaps', () => {
  const pages = inventory();
  const rootLinks = links('resources/index.html').filter((url) => url.origin === ORIGIN).map((url) => url.pathname);
  const sitemap = read('sitemap.xml');
  const locations = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
  const directory = links('sitemap/index.html').map((url) => url.href);
  for (const url of [...locations, ...directory]) assert(!new URL(url).pathname.startsWith('/community/'), url);
  for (const route of ['/resources/', '/resources/guides/']) {
    assert(locations.includes(ORIGIN + route), route);
    assert(directory.includes(ORIGIN + route), route);
  }
  for (const game of GAMES) assert(rootLinks.includes(`/resources/${game}/`), `No crawlable ${game} resource link`);
  for (const page of pages) {
    const url = pageUrl(page.file);
    assert.equal(locations.filter((location) => location === url).length, 1, `XML sitemap omits/duplicates ${url}`);
    assert(directory.includes(url), `HTML sitemap omits ${url}`);
    assert(!url.includes('?') && !url.includes('#'), url);
    const hrefs = links(page.file);
    assert(hrefs.some((href) => href.origin === ORIGIN && href.pathname === '/resources/'), page.file);
    for (const href of hrefs.filter((link) => link.origin === ORIGIN)) {
      const target = path.join(ROOT, decodeURIComponent(href.pathname));
      assert(fs.existsSync(target), `${page.file} links to a missing target: ${href.pathname}`);
    }
    if (page.category && page.category !== 'all') {
      const parent = `resources/${page.game}/${page.menu === 'scooby' ? '' : page.menu + '/'}index.html`;
      assert(links(parent).some((href) => href.href === url), `Game directory omits ${url}`);
    } else if (page.menu !== 'scooby') {
      assert(links(`resources/${page.game}/index.html`).some(href => href.href === url), `Default collection omits menu directory ${url}`);
    }
    const browseLinks = hrefs.filter(href => href.pathname === '/resources/' && href.searchParams.get('game') === page.game);
    assert(browseLinks.length, `Missing interactive browse link: ${page.file}`);
    if (page.game === 'gta5') for (const href of browseLinks) assert.equal(href.searchParams.get('menu'), page.menu, page.file);
  }
  const expectedURLs = new Set(pages.map(page => pageUrl(page.file)));
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
    const search = '?game=gta5&menu=cherax&category=vehicles';
    const hash = '#collection';
    let redirected;
    vm.runInNewContext(script, { location: { search, hash, replace: url => { redirected = url; } } });
    assert.equal(redirected, route + search + hash);
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
      assert(/no .{0,35}(?:downloads|files|resources)|(?:downloads|files|resources).{0,35}(?:yet|available|added)|coming soon/i.test(body),
        `${page.file} must state that its downloadable catalog is empty`);
    }
  }
});

test('pending downloads and verified theme captures render honest static actions', () => {
  const { renderPage } = require('./resource-pages.cjs');
  const base = inventory().find(page => page.game === 'gta5' && page.menu === 'scooby');
  const entry = {
    id: 'availability-regression', game: 'gta5', category: 'lua', name: 'API-specific script listing',
    menuResource: true, sourceCatalog: 'menu-resources', supportedMenus: ['cherax'],
    downloadStatus: 'pending', files: [], changelog: [{ version: '1.0', changes: ['Published source description'] }]
  };
  const pending = renderPage({ ...base, menu: 'cherax', menuName: 'Cherax', samples: [entry], itemCount: 1, pendingCount: 1 });
  const article = pending.match(/<article\b[^>]*>[\s\S]*?<\/article>/)?.[0];
  assert(article, 'Missing pending source listing');
  assert(/<button\b[^>]*\bdisabled\b[^>]*>Download — Coming soon<\/button>/.test(article));
  assert(!article.includes('data-download-file='), 'Pending metadata must not expose a pretend download');
  assert(article.includes('Published source description') && article.includes('Changelog'));
  assert(article.includes('menu=cherax'), 'Pending listing tags must preserve their menu context');
  const withoutNotes = renderPage({ ...base, samples: [{ ...entry, changelog: undefined }] });
  assert(withoutNotes.includes('data-resource-changelog=') && withoutNotes.includes('&quot;notes&quot;:[]'), 'Missing changelogs need an honest empty popup');
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
});
