'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { setTimeout: pause } = require('node:timers/promises');
const { parseListing } = require('./community-mod-marketplace.cjs');
const { recordResourceAdditions } = require('./resource-additions.cjs');

const root = path.resolve(__dirname, '..');
const origin = 'https://www.gta5-mods.com';
const output = path.join(root, 'community/data/gta5-addons.json');
// PC Enhanced release date from Rockstar's March 4, 2025 Newswire.
const enhancedLaunch = '2025-03-04';
const feeds = [
  { route: 'vehicles/tags/add-on/most-downloaded', category: 'addon-vehicles', pages: 18 },
  { route: 'vehicles/tags/add-on%2Benhanced', category: 'addon-vehicles', pages: 5 },
  { route: 'player/tags/add-on/most-downloaded', category: 'addon-peds', pages: 8 },
  { route: 'player/tags/add-on%2Benhanced', category: 'addon-peds', pages: 1 },
  { route: 'player/tags/add-on%2Bclothing', category: 'addon-clothing', pages: 2 },
  { route: 'maps/tags/add-on/most-downloaded', category: 'addon-maps', pages: 2 },
  { route: 'misc/tags/prop/most-downloaded', category: 'addon-objects', pages: 1 },
  { route: 'misc/tags/animation/most-downloaded', category: 'addon-animations', pages: 1 }
];

function editionFor(item) {
  // An Enhanced listing tag establishes support for that edition. Explicit
  // title or version labels can identify additional supported editions.
  const titleLabels = [...item.name.matchAll(/\[([^\]]+)\]|\(([^)]+)\)/g)]
    .flatMap(([, bracket, parenthesis]) => (bracket || parenthesis).split(/[|/,&+]/));
  const label = /^(?:(?:for|gta\s*(?:v|5)|sp)\s+)*(legacy|enhanced)(?:\s+(?:only|version|edition|support))?$/i;
  const labels = [...titleLabels, (item.version || '').replace(/^v?\d[\d.]*[\s-]*/i, '')]
    .map(value => value.trim().match(label)?.[1].toLowerCase()).filter(Boolean);
  if (labels.includes('legacy') && labels.includes('enhanced')) return 'both';
  return labels[0] || (item.tags.some(tag => /^enhanced$/i.test(tag)) ? 'enhanced' : '');
}

function addon(item, category) {
  const tags = new Set(item.tags.map(tag => tag.toLowerCase()));
  if (/\b(?:deprecated|outdated|unsupported|obsolete|wip|beta test)\b/i.test(item.name) ||
      /\bfivem[ -]+only\b/i.test(item.name) || new URL(item.preview || origin).hostname !== 'img.gta5-mods.com') return null;
  const clothing = ['clothing', 'shoes', 'mask', 'helmet', 'hair', 'eyes', 'tattoo', 'watch', 'jewellery', 'wardrobe'].some(tag => tags.has(tag));
  const ped = /\badd[ -]?on\s+peds?\b/i.test(item.name);
  if (category === 'addon-clothing' && ped) category = 'addon-peds';
  if (category === 'addon-peds' && !ped && (clothing || !/\b(?:ped|peds|add[ -]?on)\b/i.test(item.name))) return null;
  if (category === 'addon-maps' && !['add-on', 'ymap', 'mlo'].some(tag => tags.has(tag))) return null;
  if (category === 'addon-maps' && /\b(?:add[ -]?on\s+props?|props?\s+add[ -]?on)\b/i.test(item.name) &&
      !['map model', 'interior', 'ymap', 'mlo'].some(tag => tags.has(tag))) category = 'addon-objects';
  if (category === 'addon-objects' && !/\b(?:props?|objects?)\b/i.test(item.name)) return null;
  const sourceUrl = item.sourceUrl;
  const editionSupport = editionFor(item);
  return {
    id: 'gta5-author-addon-' + createHash('sha256').update(sourceUrl).digest('hex').slice(0, 16),
    game: 'gta5', category, name: item.name, author: item.creator, source: 'GTA5-Mods', sourceUrl,
    status: 'author-hosted', preview: item.preview, files: [], version: item.version,
    ...(editionSupport ? { editionSupport, editionSource: sourceUrl } : {}),
    tags: item.tags
  };
}

async function readPage(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(15000), headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130.0.0.0 Safari/537.36'
  } });
  if (!response.ok) throw Object.assign(Error(`${url} returned HTTP ${response.status}`), { status: response.status });
  return response.text();
}

function writeCatalog(data) {
  const temporary = `${output}.${process.pid}.tmp`;
  fs.writeFileSync(temporary, JSON.stringify(data, null, 2) + '\n');
  fs.renameSync(temporary, output);
}

async function refresh() {
  const previous = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
  // Detail-page reviews can cover listings outside the automated feeds.
  const items = (previous.items || []).filter(item => item.reviewed === true);
  const existing = ['library.json', 'menu-resources.json', 'gta5-editions.json'].map(file =>
    JSON.parse(fs.readFileSync(path.join(root, 'community/data', file), 'utf8')));
  const seen = new Set([...items, ...existing.flatMap(data => data.items)].map(item => item.sourceUrl).filter(Boolean));
  for (const feed of feeds) {
    const start = items.length;
    for (let page = 1; page <= feed.pages; page++) {
      const url = `${origin}/${feed.route}${page === 1 ? '' : '/' + page}`;
      const parsed = parseListing(await readPage(url), { ...feed, tags: [], url });
      if (!parsed.length && page > 1) break;
      if (!parsed.length) throw Error(`No public listing cards found at ${url}`);
      for (const item of parsed) {
        if (seen.has(item.sourceUrl)) continue;
        const entry = addon(item, feed.category);
        if (entry) { items.push(entry); seen.add(item.sourceUrl); }
      }
      await pause(300);
    }
    console.log(`${feed.route}: ${items.length - start} new listings`);
  }
  if (items.filter(item => item.category === 'addon-vehicles' && !item.reviewed).length < 300) throw Error('Expected at least 300 new vehicle addons');
  const dates = new Map((previous.items || []).filter(item => item.releaseDate).map(item => [item.sourceUrl, item]));
  const galleries = new Map((previous.items || []).filter(item => item.imageUrls?.length).map(item => [item.sourceUrl, item.imageUrls]));
  for (const item of items) {
    if (galleries.has(item.sourceUrl)) item.imageUrls = galleries.get(item.sourceUrl);
    const prior = dates.get(item.sourceUrl);
    if (!item.editionSupport && prior && prior.version === item.version) {
      Object.assign(item, { editionSupport: prior.editionSupport, editionSource: prior.editionSource, releaseDate: prior.releaseDate });
    }
  }
  const catalog = { items, previews: previous.previews };
  recordResourceAdditions(catalog, previous);
  writeCatalog(catalog);
  console.log(`Wrote ${items.length} author-hosted addons.`);
}

function galleryImages(html) {
  const urls = [];
  for (const match of html.matchAll(/<a\b[^>]*\bclass=["'][^"']*\bmfp-image\b[^"']*["'][^>]*>/gi)) {
    const href = match[0].match(/\bhref=["']([^"']+)["']/i)?.[1];
    if (!href) continue;
    try {
      const url = new URL(href.replace(/&amp;/g, '&'));
      if (url.protocol === 'https:' && url.hostname === 'img.gta5-mods.com' && /\/images\/.+\.(?:jpe?g|png|webp)$/i.test(url.pathname)) urls.push(url.href);
    } catch { /* Ignore malformed media URLs. */ }
  }
  return [...new Set(urls)];
}

async function collectVehicleGalleries(limit = 40) {
  const catalog = JSON.parse(fs.readFileSync(output, 'utf8'));
  const candidates = catalog.items.filter(item => item.category === 'addon-vehicles' && item.sourceUrl?.startsWith(`${origin}/vehicles/`) && !item.imageUrls?.length);
  candidates.sort((a, b) => Number(Boolean(b.reviewed)) - Number(Boolean(a.reviewed)));
  let updated = 0;
  for (const item of candidates.slice(0, limit)) {
    try {
      const images = galleryImages(await readPage(item.sourceUrl));
      if (images.length > 1) { item.imageUrls = images; updated++; }
    } catch (error) {
      console.warn(`${item.name}: ${error.message}`);
      if ([403, 429].includes(error.status)) break;
    }
    await pause(350);
  }
  writeCatalog(catalog);
  console.log(`Added image galleries to ${updated} vehicle listings.`);
}

async function reviewEditions() {
  const catalog = JSON.parse(fs.readFileSync(output, 'utf8'));
  const pending = catalog.items.filter(item => !item.reviewed && !item.editionSupport && new URL(item.sourceUrl).origin === origin);
  // Review older releases across all addon types, including the smaller categories.
  const groups = [...new Set(pending.map(item => item.category))].map(category => pending.filter(item => item.category === category));
  const queue = [];
  for (let row = 0; groups.some(group => row < group.length) && queue.length < 180; row++) {
    queue.push(...groups.map(group => group[row]).filter(Boolean));
  }
  let added = 0;
  for (const item of queue) {
    try {
      const html = await readPage(item.sourceUrl);
      const date = html.match(/"dateModified"\s*:\s*"(\d{4}-\d{2}-\d{2})/)?.[1];
      if (date && date < enhancedLaunch) {
        Object.assign(item, { editionSupport: 'legacy', editionSource: item.sourceUrl, releaseDate: date });
        added++;
      }
    } catch (error) {
      if ([403, 429].includes(error.status)) { console.warn(error.message); break; }
    }
    await pause(350);
  }
  writeCatalog(catalog);
  console.log(`Added ${added} Legacy labels using original release dates.`);
}

if (require.main === module) {
  (process.argv.includes('--collect-galleries') ? collectVehicleGalleries() : process.argv.includes('--review-editions') ? reviewEditions() : refresh())
    .catch(error => { console.error(error.message); process.exitCode = 1; });
}

module.exports = { editionFor, galleryImages };
