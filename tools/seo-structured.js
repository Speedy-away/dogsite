/* Structured data derived from each page's visible navigation. */
const SITE = 'https://scoobymenu.cc';
const ID = 'seo-page-structure';
const WEBSITE_ID = SITE + '/#website';
const PUBLISHER_ID = SITE + '/#organization';
const PAGE_TYPES = ['WebPage', 'CollectionPage', 'FAQPage', 'ItemPage'];
const decode = value => value.replace(/&#(x[\da-f]+|\d+);/gi, (_, n) => String.fromCodePoint(n[0].toLowerCase() === 'x' ? parseInt(n.slice(1), 16) : Number(n)))
  .replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&apos;|&#39;/g, "'").replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
const plain = value => decode(value.replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim();

function pageUrl(file) {
  return SITE + '/' + file.replace(/\\/g, '/').replace(/(^|\/)index\.html$/, '$1');
}

function isPageEntity(node, url) {
  if (!node || ![node['@type']].flat().some(type => PAGE_TYPES.includes(type))) return false;
  if (node.url) return typeof node.url === 'string' && node.url.replace(/\/$/, '') === url.replace(/\/$/, '');
  const id = node['@id'];
  return !id || typeof id === 'string' && (id.startsWith('#') || id.split('#')[0].replace(/\/$/, '') === url.replace(/\/$/, ''));
}

function pageFields(node, url, meta) {
  const parents = [node.isPartOf].flat().filter(Boolean);
  if (!parents.some(parent => parent === WEBSITE_ID || parent['@id'] === WEBSITE_ID)) {
    parents.push({ '@id': WEBSITE_ID });
  }
  return {
    '@id': node['@id'] || url + '#webpage',
    url,
    name: node.name || meta.title,
    description: meta.description,
    keywords: meta.keywords,
    inLanguage: meta.language || 'en',
    isPartOf: parents.length === 1 ? parents[0] : parents,
    publisher: node.publisher || { '@id': PUBLISHER_ID },
  };
}

function structure(file, html, meta) {
  const url = pageUrl(file);
  const clean = html.replace(new RegExp(`<script\\b[^>]*id=["']${ID}["'][^>]*>[\\s\\S]*?<\\/script>\\s*`, 'i'), '');
  const existing = [...clean.matchAll(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
    .flatMap(match => { const data = JSON.parse(match[1]); return Array.isArray(data) ? data : data['@graph'] || [data]; });
  const graph = [];
  if (!existing.some(item => isPageEntity(item, url))) {
    graph.push({ '@type': 'WebPage', ...pageFields({}, url, meta) });
  }
  // Only describe breadcrumb paths actually present in the rendered HTML.
  const trail = clean.match(/<(?:div|nav)\b[^>]*class=["'][^"']*\b(?:breadcrumbs?|source-breadcrumb)\b[^"']*["'][^>]*>([\s\S]*?)<\/(?:div|nav)>/i)?.[1];
  if (trail && !existing.some(item => item['@type'] === 'BreadcrumbList')) {
    const items = [];
    for (const match of trail.matchAll(/<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi)) {
      const target = new URL(decode(match[1]), url);
      if (target.origin !== SITE || target.search || target.hash) continue;
      if (!items.some(item => item.item === target.href)) items.push({ name: plain(match[2]), item: target.href });
    }
    if (!items.some(item => item.item === url)) items.push({ name: plain(clean.match(/<h1\b[^>]*>([\s\S]*?)<\/h1>/i)?.[1] || meta.title), item: url });
    if (items.length > 1) graph.push({ '@type': 'BreadcrumbList', '@id': url + '#breadcrumb',
      itemListElement: items.map((item, index) => ({ '@type': 'ListItem', position: index + 1, ...item })) });
  }
  const nl = html.includes('\r\n') ? '\r\n' : '\n';
  if (!graph.length) return clean;
  const json = JSON.stringify({ '@context': 'https://schema.org', '@graph': graph }, null, 2).replace(/</g, '\\u003c').replace(/\n/g, nl);
  return clean.replace(/<\/head>/i, `<script type="application/ld+json" id="${ID}">${nl}${json}${nl}</script>${nl}</head>`);
}

module.exports = { structure, pageFields, isPageEntity, pageUrl, plain };
