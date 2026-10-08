/* Keep crawlable navigation on the same URLs as the canonical tags. */
const fs = require('node:fs');
const path = require('node:path');
const { pageUrl } = require('./seo-structured');
const SITE = 'https://scoobymenu.cc';

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

function normalizeLinks(file, html, routes) {
  // Skip script/code content; only rewrite actual anchor tags, retaining bookmarks and queries.
  return html.replace(/<script\b[^>]*>[\s\S]*?<\/script>|<!--[^]*?-->|<a\b[^>]*>/gi, tag => {
    if (!/^<a\b/i.test(tag)) return tag;
    return tag.replace(/(\s+href\s*=\s*)(["'])(.*?)\2/i, (attribute, prefix, quote, href) => {
      if (!href || href.startsWith('#')) return attribute;
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
  let changed = 0;
  for (const file of files) {
    const target = path.join(root, file), html = fs.readFileSync(target, 'utf8');
    const updated = normalizeLinks(file, html, routes);
    if (updated === html) continue;
    changed++;
    if (process.argv.includes('--apply')) fs.writeFileSync(target, updated);
  }
  console.log(`${changed} pages ${process.argv.includes('--apply') ? 'updated' : 'need canonical link normalization'}.`);
  if (changed && !process.argv.includes('--apply')) process.exitCode = 1;
}
module.exports = { routeMap, normalizeLinks };
