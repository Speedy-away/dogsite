'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { guideBase, guidePath, collectionPath, catalogURL } = require('../resources/routes.js');
const menus = require('../resources/menus.js');
const { roleplayCategoryLabel } = require('../resources/taxonomy.js');
const { plain } = require('./seo-structured');

const root = path.resolve(__dirname, '..');
const guideIndex = 'resources/guides/index.html';
const site = 'https://scoobymenu.cc';
const escape = value => String(value).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
const attribute = (tag, name) => tag.match(new RegExp(`\\b${name}="([^"]*)"`))?.[1];
const words = value => (value || '').trim().split(/\s+/).filter(Boolean);
const matches = (values, id) => words(values).some(value => value === 'all' || value === id);
const marker = '<!-- Generated resource guide -->';

function buildGuideData(inventory) {
  const source = fs.readFileSync(path.join(root, guideIndex), 'utf8');
  const body = source.match(/<div class="guide-topics">([\s\S]*?)<\/div>\s*<aside class="ad-sidebar"/)?.[1];
  if (!body) throw Error('Resource guide topics are missing');
  const topics = [...body.matchAll(/(<section\b[^>]*>)[\s\S]*?<\/section>/g)].map(([html, opening]) => ({
    id: attribute(opening, 'id'), games: attribute(opening, 'data-games'), menus: attribute(opening, 'data-menus') || 'scooby',
    categories: words(attribute(opening, 'data-categories')), heading: plain(html.match(/<h2>([\s\S]*?)<\/h2>/)?.[1] || ''), html
  }));
  const pages = [];
  const routes = {};
  for (const collection of inventory.pages.filter(page => !page.category)) {
    const { game, menu, menuName, availableMenus } = collection;
    const gameName = inventory.games[game].name;
    const scope = availableMenus.length > 1 ? `${gameName} ${menuName}` : gameName;
    const available = topics.filter(topic => matches(topic.games, game) && matches(topic.menus, menu));
    if (!available.length) continue;
    const categoryIds = new Set(available.flatMap(topic => topic.categories));
    const groups = new Map();
    const destinations = new Map();
    for (const category of ['all', ...categoryIds]) {
      const selected = category === 'all' ? available : available.filter(topic => topic.categories.includes(category));
      const key = selected.map(topic => topic.id).join(' ');
      const href = guidePath(game, category, menu);
      const existing = destinations.get(key);
      routes[href] = existing || href;
      if (existing) continue;
      destinations.set(key, href);
      const label = category === 'all' ? 'All installation guides' :
        menus.categoryLabel(menu, category) || roleplayCategoryLabel(game, category) || inventory.categories[category]?.name || selected[0].heading;
      if (category !== 'all') groups.set(href, label);
      const title = category === 'all' ? `${scope} Resource Installation Guides` : `${scope} ${label} Installation Guide`;
      const detail = selected.slice(0, 3).map(topic => topic.heading).join(', ');
      const intro = category === 'all' ? `Find installation instructions for ${scope} resources.` : `Find ${scope} installation instructions for ${label.toLowerCase()}.`;
      const description = `${intro} ${detail}.`;
      pages.push({ file: `${href.slice(1)}index.html`, href, title, description, keywords: `${scope} resources, ${scope} installation, ${detail}`,
        game, menu, availableMenus, category, label, scope, groups, topics: selected });
    }
  }
  return { pages, routes, ad: source.match(/<aside class="ad-sidebar"[\s\S]*?<\/aside>/)?.[0] || '' };
}

function renderGuide(page, guides, inventory, collectionRoutes) {
  const home = guidePath(page.game, 'all', page.menu);
  const gameLinks = Object.entries(inventory.games).map(([game, config]) =>
    `<a href="${guidePath(game)}"${game === page.game ? ' aria-current="page"' : ''}><img src="${config.logo}" width="44" height="32" alt=""><span>${config.name}</span></a>`).join('');
  const navLink = ([href, label]) => `<a class="category-choice" href="${href}"${href === page.href ? ' aria-current="page"' : ''}>${escape(label)}</a>`;
  const menuLinks = page.availableMenus.filter(menu => guides.routes[guidePath(page.game, 'all', menu.id)]);
  const menuNav = menuLinks.length > 1 ? `<nav class="category-nav" aria-label="Menu guides">${menuLinks.map(menu => navLink([guidePath(page.game, 'all', menu.id), menu.name])).join('')}</nav>` : '';
  const categoryNav = [[home, 'All installation guides'], ...page.groups].map(navLink).join('');
  const topics = page.topics.map(topic => topic.html.replace(/<(p|a)\b([^>]*\bdata-guide-(?:games|menus)="[^"]*"[^>]*)>[\s\S]*?<\/\1>/gi, (html, _tag, attributes) => {
    const games = attribute(attributes, 'data-guide-games'), menus = attribute(attributes, 'data-guide-menus');
    return (!games || matches(games, page.game)) && (!menus || matches(menus, page.menu)) ? html : '';
  })).join('\n');
  const category = collectionRoutes.has(collectionPath(page.game, page.category, page.menu)) ? page.category : 'all';
  const collection = catalogURL({ game: page.game, menu: page.menu, category }, collectionRoutes);
  const trail = `<a href="/">Home</a><span>/</span><a href="${guideBase}">Resource installation guides</a><span>/</span>${page.category === 'all' ? `<span>${escape(page.scope)}</span>` : `<a href="${home}">${escape(page.scope)}</a><span>/</span><span>${escape(page.label)}</span>`}`;
  return `${marker}
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escape(page.title)}</title>
<link rel="icon" href="/assets/images/brand/scooby-logo.png"><link rel="stylesheet" href="/assets/css/site-brand.css"><link rel="stylesheet" href="/resources/catalog.css"><link rel="stylesheet" href="/resources/discover.css"><link rel="stylesheet" href="/resources/guides/guides.css"><link rel="stylesheet" href="/assets/css/ad-sidebar.css">
</head><body><a class="skip" href="#install">Skip to installation guides</a>
<header><a class="scooby-brand" href="/"><span class="scooby-emblem" aria-hidden="true"></span><strong>SCOOBY</strong></a><nav aria-label="Main"><a href="/resources/">Resources</a><a href="${guideBase}">Install guides</a><a href="/store/">Store ↗</a></nav></header>
<main id="install"><div class="page-heading"><h1>${escape(page.title)}</h1><a href="${escape(collection)}">Browse resources ↗</a></div>
<div class="guide-browser"><nav class="breadcrumbs" aria-label="Breadcrumb">${trail}</nav><nav class="games" aria-label="Choose a game">${gameLinks}</nav><div class="guide-layout ad-layout">
<aside class="guide-categories" aria-label="Installation categories"><details open><summary>Categories <span aria-hidden="true">+</span></summary><div class="filter-content"><h2>Categories</h2>${menuNav}<nav class="category-nav" aria-label="Guide categories">${categoryNav}</nav></div></details></aside>
<div class="guide-content"><div class="guide-topics">${topics}</div></div>${guides.ad}</div></div></main>
<footer><a href="${escape(collection)}">Browse resources</a><a href="${guideBase}">All resource guides</a></footer></body></html>\n`;
}

function writeGuides(guides, inventory) {
  const { applyMetadata } = require('./seo-metadata');
  const collectionRoutes = new Set(inventory.pages.map(page => collectionPath(page.game, page.category, page.menu)));
  const manifest = path.join(root, 'resources/guides/routes.json');
  const previous = fs.existsSync(manifest) ? JSON.parse(fs.readFileSync(manifest, 'utf8')) : {};
  const write = (href, html) => {
    if (!/^\/resources\/guides\/(?:[a-z0-9-]+\/){1,3}$/.test(href)) throw Error(`Invalid generated guide route ${href}`);
    const file = path.join(root, href.slice(1), 'index.html');
    fs.mkdirSync(path.dirname(file), { recursive: true });
    if (!fs.existsSync(file) || fs.readFileSync(file, 'utf8') !== html) fs.writeFileSync(file, html);
  };
  for (const page of guides.pages) write(page.href, applyMetadata(page.file, renderGuide(page, guides, inventory, collectionRoutes)));
  for (const href of new Set([...Object.keys(guides.routes), ...Object.keys(previous)])) {
    const target = guides.routes[href] || guides.routes[href.replace(/[^/]+\/$/, '')] || guideBase;
    if (href === target) continue;
    write(href, `${marker}
<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Resource installation guide</title><meta name="robots" content="noindex, follow"><link rel="canonical" href="${site + target}">
<script>location.replace(${JSON.stringify(target)} + location.search + location.hash);</script><noscript><meta http-equiv="refresh" content="0;url=${target}"></noscript>
</head><body><p>Continue to the <a href="${target}">resource installation guide</a>.</p></body></html>\n`);
  }
  fs.writeFileSync(manifest, JSON.stringify(guides.routes, null, 2) + '\n');
}

module.exports = { buildGuideData, writeGuides };
