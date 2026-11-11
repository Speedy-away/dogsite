/* Keep crawlable navigation on the same URLs as the canonical tags. */
const fs = require('node:fs');
const path = require('node:path');
const { pageUrl } = require('./seo-structured');
const resourceRoutes = require('../resources/routes.js');
const menus = require('../resources/menus.js');
const taxonomy = require('../resources/taxonomy.js');
const SITE = 'https://scoobymenu.cc';
const resourceGames = new Set(['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d']);

function routeMap(files) {
  const routes = new Map();
  for (const file of files) {
    const canonical = new URL(pageUrl(file)).pathname;
    routes.set('/' + file, canonical);
    routes.set(canonical, canonical);
    if (canonical.endsWith('/') && canonical !== '/') routes.set(canonical.slice(0, -1), canonical);
  }
  return routes;
}

function normalizeResourceLink(href, file, routes, guides) {
  if (!href.includes('?')) return '';
  let url;
  try { url = new URL(href.replace(/&amp;/gi, '&'), pageUrl(file)); } catch { return ''; }
  if (url.origin !== SITE) return '';
  const pathname = url.pathname.replace(/^\/community(?=\/|$)/, '/resources').replace(/\/index\.html$/, '/').replace(/\/?$/, '/');
  const guide = pathname === resourceRoutes.guideBase;
  if (!guide && pathname !== resourceRoutes.base) return '';
  const game = url.searchParams.get('game');
  if (!resourceGames.has(game)) return '';
  const menu = menus.menuFor(game, url.searchParams.get('menu'));
  const category = taxonomy.categoryId(game, url.searchParams.get('category'), menu);
  const target = guide ? guides[resourceRoutes.guidePath(game, category, menu)] : resourceRoutes.collectionPath(game, category, menu);
  if (!target || !routes.has(target)) return '';
  for (const key of ['game', 'menu', 'category']) url.searchParams.delete(key);
  return target + url.search.replace(/&/g, '&amp;') + url.hash.replace(/&/g, '&amp;');
}

function normalizeLinks(file, html, routes, guides = {}) {
  // Skip script/code content; only rewrite actual anchor tags, retaining bookmarks and queries.
  return html.replace(/<script\b[^>]*>[\s\S]*?<\/script>|<!--[^]*?-->|<a\b[^>]*>/gi, tag => {
    if (!/^<a\b/i.test(tag)) return tag;
    return tag.replace(/(\s+href\s*=\s*)(["'])(.*?)\2/i, (attribute, prefix, quote, href) => {
      if (!href || href.startsWith('#')) return attribute;
      const resource = normalizeResourceLink(href, file, routes, guides);
      if (resource) return prefix + quote + resource.replaceAll(quote, quote === '"' ? '&quot;' : '&#39;') + quote;
      let url;
      try { url = new URL(href, pageUrl(file)); } catch { return attribute; }
      if (url.origin !== SITE || !routes.has(url.pathname)) return attribute;
      const target = routes.get(url.pathname);
      if (url.pathname === target) return attribute;
      return prefix + quote + target + url.search + url.hash + quote;
    });
  });
}

if (require.main === module) {
  const { walk } = require('./seo-metadata');
  const root = path.resolve(__dirname, '..');
  const files = walk(root).map(file => path.relative(root, file).replace(/\\/g, '/'));
  const routes = routeMap(files);
  const guideManifest = path.join(root, 'resources/guides/routes.json');
  const guides = fs.existsSync(guideManifest) ? JSON.parse(fs.readFileSync(guideManifest, 'utf8')) : {};
  let changed = 0;
  for (const file of files) {
    const target = path.join(root, file), html = fs.readFileSync(target, 'utf8');
    const updated = normalizeLinks(file, html, routes, guides);
    if (updated === html) continue;
    changed++;
    if (process.argv.includes('--apply')) fs.writeFileSync(target, updated);
  }
  console.log(`${changed} pages ${process.argv.includes('--apply') ? 'updated' : 'need canonical link normalization'}.`);
  if (changed && !process.argv.includes('--apply')) process.exitCode = 1;
}
module.exports = { routeMap, normalizeLinks };
