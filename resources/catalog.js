'use strict';

const $ = id => document.getElementById(id);
const gameTabs = document.querySelectorAll('#collection .games [data-game]');
const GAMES = {
  gta5: { name: 'GTA 5', assets: ['vehicles', 'modded', 'outfits', 'maps', 'textures', 'graphics-packs', 'paintjobs', 'liveries', 'wallpapers', 'asi-mods', 'dotnet-mods', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing', 'addon-packs'] },
  rdr2: { name: 'RDR2', assets: ['outfits', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps'] },
  cs2: { name: 'CS2', assets: ['players', 'weapons', 'knives', 'throwables', 'bombs', 'skyboxes', 'textures'] },
  fivem: { name: 'FiveM', assets: ['vehicles', 'outfits', 'maps', 'textures', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing'] },
  redm: { name: 'RedM', assets: ['outfits', 'weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings', 'maps', 'textures', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps'] },
  l4d: { name: 'L4D', assets: ['players', 'weapons', 'maps', 'textures', 'skyboxes', 'sound-packs'] }
};
const LABELS = {
  all: 'All resources', vehicles: 'Vehicles', modded: 'Modded vehicles', outfits: 'Outfits',
  'addon-vehicles': 'Vehicles', 'addon-peds': 'Peds', 'addon-objects': 'Objects', 'addon-animations': 'Animations', 'addon-maps': 'Maps', 'addon-clothing': 'Clothing', maps: 'Maps', textures: 'Textures',
  paintjobs: 'LSC paintjobs', liveries: 'Liveries', players: 'Player models', weapons: 'Weapon models', knives: 'Knife models',
  throwables: 'Throwables', bombs: 'Bombs', skyboxes: 'Skyboxes', themes: 'Themes', configs: 'Configs',
  lua: 'Lua scripts', languages: 'Translations / Languages', misc: 'Miscellaneous',
  'loader-translations': 'Loader translations', fonts: 'Fonts', emotes: 'Emote audio',
  'asi-mods': 'ASI mods', 'dotnet-mods': '.NET mods', 'addon-packs': 'Packs', wallpapers: 'Wallpapers',
  'weapon-models': 'Weapon models/skins', 'sound-packs': 'Sound packs', 'graphics-packs': 'Graphics packs',
  'ui-presets': 'UI presets', 'visual-effects': 'Visual effects', scopes: 'Scopes', settings: 'Settings',
  'mod-menus': 'Lua Menus', triggers: 'Triggers', 'server-dumps': 'Server dumps'
};
const MENU_CATEGORIES = ['themes', 'configs', 'lua', 'languages', 'misc'];
const NENYOO_CATEGORIES = ['loader-translations', 'fonts', 'emotes', 'textures'];
const L4D_LABELS = { maps: 'Maps & campaigns', players: 'Survivor & infected models', weapons: 'Weapon models & skins' };
const PAGE_SIZE = 24;
const ACCESS_LABELS = { free: 'Free', paid: 'Paid' };
const SCOOBY_PREVIEW_LOGO = '/assets/images/brand/scooby-mark.svg';
const taxonomy = globalThis.ScoobyTaxonomy;
const menuSystem = globalThis.ScoobyMenus;
const editions = globalThis.ScoobyEditions;
const routes = globalThis.ScoobyResourceRoutes;
const initialPath = location.pathname.replace(/\/index\.html$/, '/');
const publishedRoutes = new Set([...document.querySelectorAll('#collection .games a[data-game]')].map(link => link.pathname));
if (initialPath !== routes.base) publishedRoutes.add(initialPath);
let publishedGuides = {};
const tagCache = new WeakMap();
const searchCache = new WeakMap();
const cache = new Map();
const legacy = new Map();
const LOCAL_PREVIEW = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
let library = { items: [], downloadBaseUrl: 'https://raw.githubusercontent.com/Speedy-away/cool-repo/main/' };
let menuResources = { items: [] };
let gtaEditionCatalog = { items: [], verified: {} };
let gtaAddonCatalog = { items: [] };
let nenyooCatalog = { items: [] };
let libraryError = false;
let entries = [];
let menuCategoryCounts = new Map();
let revision = 0;
let loadRevision = 0;
let catalogReady = false;
let gameLoading = false;
let state = readState();
let inputTimer;
let linkedPreviewHash = '';

function node(tag, text, className) {
  const result = document.createElement(tag);
  if (text !== undefined && text !== null) result.textContent = String(text);
  if (className) result.className = className;
  return result;
}

function normalize(value) { return String(value || '').toLowerCase().replace(/[^a-z0-9]/g, ''); }
function menuFor(game, id) { return menuSystem ? menuSystem.menuFor(game, id) : 'scooby'; }
function hasMenuChoice(game) { return menuSystem?.menusFor(game).length > 1; }
function menuName(id = state.menu) { return menuSystem ? menuSystem.displayName(id) : 'Scooby'; }
function collectionTitle() { return `${hasMenuChoice(state.game) ? `${menuName()}'s ` : ''}${GAMES[state.game].name} resources`; }
function supportsMenu(entry) { return menuSystem ? menuSystem.supports(entry, state.menu) : state.menu === 'scooby'; }
function pendingDownload(entry) { return entry.category === 'lua' && entry.downloadStatus === 'pending'; }
function normalizeSearch(value) { return taxonomy ? taxonomy.normalizeTag(value) : String(value || '').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim(); }
function resourceTags(entry) {
  if (!tagCache.has(entry)) tagCache.set(entry, taxonomy ? taxonomy.tagsFor(entry) : [...new Set([entry.game, entry.category, ...[].concat(entry.tags || [])].map(normalizeSearch).filter(Boolean))]);
  return tagCache.get(entry);
}
function resourceSearchText(entry) {
  if (!searchCache.has(entry)) searchCache.set(entry, taxonomy ? taxonomy.searchText(entry) : normalizeSearch([entry.name, entry.description, entry.model, entry.modelLabel, entry.uiStyle, entry.style, ...resourceTags(entry)].join(' ')));
  return searchCache.get(entry);
}
function roleplayGroups(game) {
  return taxonomy?.roleplayCategoryGroups?.(game, [...GAMES[game].assets, ...MENU_CATEGORIES]);
}

function categoryId(game, id, menu) { return taxonomy?.categoryId(game, id, menu) ?? id; }

function categories(game = state.game, menu = state.menu) {
  const groups = roleplayGroups(game);
  return groups ? groups.flatMap(([, ids]) => ids) : [...new Set([...GAMES[game].assets, ...MENU_CATEGORIES, ...(menu === 'nenyoo' ? NENYOO_CATEGORIES : [])])];
}
function readState() {
  const query = new URLSearchParams(location.search);
  const [, gameSlug, scope, nestedCategory] = location.pathname.replace(/\/index\.html$/, '/').split('/').filter(Boolean);
  const scopedGame = Object.hasOwn(GAMES, gameSlug) ? gameSlug : '';
  const game = scopedGame || (Object.hasOwn(GAMES, query.get('game')) ? query.get('game') : 'gta5');
  const scopedMenu = menuSystem?.menusFor(scopedGame).find(menu => menu.id === menuSystem.canonical(scope))?.id;
  const scopedCategory = scopedMenu ? nestedCategory : scope;
  const menu = menuFor(game, scopedMenu || (scopedCategory ? 'scooby' : query.get('menu')));
  const requested = categoryId(game, scopedCategory || query.get('category'), menu);
  const category = categories(game, menu).includes(requested) ? requested : 'all';
  const themeFilters = category === 'themes' && ['gta5', 'rdr2'].includes(game);
  return {
    game, category, menu, edition: editions.choice(game, query.get('edition')), q: query.get('q') || '',
    model: category === 'all' ? '' : query.get('model') || '',
    ui: themeFilters ? query.get('ui') || '' : '', style: themeFilters ? query.get('style') || '' : '',
    sort: ['name', 'attachments'].includes(query.get('sort')) ? query.get('sort') : '',
    page: Math.max(1, Number.parseInt(query.get('page'), 10) || 1)
  };
}

function updatePageTitle(url = new URL(location.href)) {
  const hub = url.pathname.replace(/\/index\.html$/, '/') === routes.base && !url.search;
  const category = state.category === 'all' ? 'Resources' : categoryLabel(state.game, state.category);
  const title = [GAMES[state.game].name, state.menu === 'scooby' ? '' : menuName(), category].filter(Boolean).join(' ');
  document.title = `${hub ? 'Resources' : title} — Scooby`;
}

function saveState(replace = false) {
  let href = routes.catalogURL(state, publishedRoutes);
  if (replace && initialPath === routes.base && location.pathname === routes.base && !location.search && href === '/resources/gta5/') href = routes.base;
  const url = new URL(href + location.hash, location.origin);
  if (url.href !== location.href) history[replace ? 'replaceState' : 'pushState'](null, '', url);
  const canonical = document.querySelector('link[rel="canonical"]');
  if (canonical) canonical.href = new URL(url.pathname, canonical.href).href;
  updatePageTitle(url);
}

async function json(url) {
  if (!cache.has(url)) cache.set(url, fetch(url, { signal: AbortSignal.timeout(20000) }).then(response => {
    if (!response.ok) throw new Error('Collection unavailable');
    return response.json();
  }).catch(error => { cache.delete(url); throw error; }));
  return cache.get(url);
}

function safeURL(value, base = new URL(routes.base, location.origin)) {
  if (!value) return '';
  try {
    const url = new URL(value, base);
    return url.protocol === 'https:' || (url.protocol === 'http:' && url.origin === location.origin) ? url.href : '';
  } catch { return ''; }
}

function downloadURL(file) {
  if (file.url) return safeURL(file.url);
  if (typeof file.path !== 'string' || !file.path || file.path.startsWith('/') || file.path.includes('\\') || file.path.split('/').some(part => part === '..' || part === '.')) return '';
  const base = LOCAL_PREVIEW ? safeURL('/community-files/') : safeURL(library.downloadBaseUrl);
  return base ? safeURL(file.path.split('/').map(encodeURIComponent).join('/'), base.endsWith('/') ? base : `${base}/`) : '';
}

function authorPage(entry) {
  return entry.status === 'author-hosted' ? safeURL(entry.sourceUrl) : '';
}

const isFiveMRecipe = entry => entry.game === 'fivem' && entry.category === 'server-dumps';

function authorAction(entry) {
  if (entry.builtInLua) return 'View module source ↗';
  if (entry.source === 'Nenyoo Resources' && entry.category === 'themes') return 'Open theme folder ↗';
  return isFiveMRecipe(entry) ? 'Download from source ↗' : 'Get from the author ↗';
}

function previewAllowed(entry) {
  return entry.previewVerified !== false && (entry.category !== 'themes' || entry.previewVerified === true);
}

function cheraxPreview(entry) {
  return entry.game === 'gta5' && (state.menu === 'cherax' || menuSystem?.canonical(entry.sourceMenu) === 'cherax');
}

function previewURL(entry) {
  if (!previewAllowed(entry)) return '';
  if (!entry.preview) return '';
  if (typeof entry.preview === 'object') return downloadURL(entry.preview);
  if (entry._legacy) return safeURL(entry.preview, new URL('/community/', location.href));
  if (/^https?:|^\/|^\.\//.test(entry.preview)) return safeURL(entry.preview);
  return downloadURL({ path: entry.preview });
}

function guideURL(entry) {
  const value = typeof entry?.guide === 'string' ? entry.guide : '';
  const game = entry?.game || state.game;
  const menu = menuFor(game, state.menu);
  const category = categoryId(game, entry?.category || state.category, menu);
  if (value.startsWith('/guides/') && menu === 'scooby') return value;
  if (/^\/(?:community|resources)\/guides\//.test(value || '')) {
    const url = new URL(value.replace(/^\/community\//, '/resources/'), location.href);
    const requested = categoryId(game, url.searchParams.get('category') || category, menu);
    return routes.guideURL({ game, menu, category: requested }, publishedGuides, url.hash);
  }
  return routes.guideURL({ game, menu, category }, publishedGuides);
}

function link(text, href, external = false) {
  const result = node('a', text);
  result.href = href;
  if (external) { result.target = '_blank'; result.rel = 'noopener noreferrer'; }
  return result;
}

function resourceURL(entry) {
  return routes.catalogURL({ game: entry.game, menu: state.menu, category: entry.category }, publishedRoutes) + routes.resourceHash(entry.id);
}

function image(src, name, showUnavailable = false) {
  const unavailable = () => node('span', 'Preview unavailable', 'preview-unavailable');
  if (!src && showUnavailable) return unavailable();
  const result = node('img');
  result.alt = name;
  result.loading = 'lazy';
  result.decoding = 'async';
  const showLogo = () => {
    if (showUnavailable) {
      result.replaceWith(unavailable());
      return;
    }
    result.classList.add('preview-placeholder');
    result.alt = '';
    result.src = SCOOBY_PREVIEW_LOGO;
  };
  if (src) result.addEventListener('error', showLogo, { once: true });
  if (src) result.src = src;
  else showLogo();
  return result;
}

function prettySize(size) {
  const bytes = Number(size);
  if (!Number.isFinite(bytes) || bytes <= 0) return '';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1073741824) return `${(bytes / 1048576).toFixed(1)} MB`;
  return `${(bytes / 1073741824).toFixed(2)} GB`;
}

async function loadLibrary() {
  const [base, supplemental, reviewed, addons, nenyoo] = await Promise.allSettled([
    json('/community/data/library.json'), json('/community/data/menu-resources.json'), json('/community/data/gta5-editions.json'), json('/community/data/gta5-addons.json'), json('/community/data/nenyoo.json')
  ]);
  libraryError = false;
  if (base.status === 'fulfilled' && Array.isArray(base.value.items)) library = base.value;
  else libraryError = true;
  if (supplemental.status === 'fulfilled' && Array.isArray(supplemental.value.items)) menuResources = supplemental.value;
  else libraryError = true;
  if (reviewed.status === 'fulfilled' && Array.isArray(reviewed.value.items)) gtaEditionCatalog = reviewed.value;
  else libraryError = true;
  if (addons.status === 'fulfilled' && Array.isArray(addons.value.items)) gtaAddonCatalog = addons.value;
  else libraryError = true;
  if (nenyoo.status === 'fulfilled' && Array.isArray(nenyoo.value.items)) nenyooCatalog = nenyoo.value;
  else libraryError = true;
}

async function loadLegacy(family) {
  if (legacy.has(family)) return applyLegacyOverrides(family, legacy.get(family));
  const [data, assets] = await Promise.all([json(`/community/data/${family}/index.json`), json(`/community/data/${family}/local-assets.json`)]);
  const result = data.items.map((row, index) => ({
    id: `${family}-${index}`, game: 'gta5', category: family, name: row[0],
    model: data.models[row[3]], modelLabel: data.modelLabels?.[row[3]] || data.models[row[3]],
    attachments: data.attachments?.[index] || 0, preview: assets[index]?.preview,
    formatExtension: fileExtension({ formatPath: assets[index]?.file || row[1] }),
    tags: [row[1], row[2], data.formats?.[row[5]] || ''],
    _legacy: { family, index, data, assets: assets[index], row }
  }));
  legacy.set(family, result);
  return applyLegacyOverrides(family, result);
}

function applyLegacyOverrides(family, original) {
  const overrides = typeof menuSystem?.legacyOverrideMap === 'function'
    ? menuSystem.legacyOverrideMap(menuResources)
    : new Map((Array.isArray(menuResources.legacyOverrides) ? menuResources.legacyOverrides : [])
      .map(override => [`${override.family}:${Number(override.index)}`, override]));
  if (!overrides.size) return original;
  return original.map(entry => {
    const override = overrides.get(`${family}:${entry._legacy.index}`);
    if (!override) return entry;
    const { family: ignoredFamily, index: ignoredIndex, ...metadata } = override;
    return { ...entry, ...metadata, id: entry.id, game: entry.game, formatExtension: entry.formatExtension, _legacy: entry._legacy };
  });
}

function libraryEntries() {
  const merged = new Map();
  const overrides = new Map((Array.isArray(menuResources.libraryOverrides) ? menuResources.libraryOverrides : []).filter(override => override.id).map(override => [override.id, override]));
  for (const item of library.items) merged.set(item.id || `${item.game}:${item.category}:${item.name}:${item.sourceMenu || item.menu || ''}`, { ...item, ...overrides.get(item.id), id: item.id });
  for (const item of [...menuResources.items, ...gtaEditionCatalog.items, ...gtaAddonCatalog.items, ...nenyooCatalog.items]) {
    const id = item.id || `${item.game}:${item.category}:${item.name}:${item.sourceMenu || item.menu || ''}`;
    merged.set(id, { ...merged.get(id), ...item });
  }
  const allowedCategories = new Set(categories());
  const sourceUrls = new Set([...merged.values()].filter(item => item.game === 'gta5' && item.status !== 'author-hosted' && item.sourceUrl).map(item => item.sourceUrl));
  return [...merged.values()].map(item => taxonomy.gtaAddonCategory(item)).filter(item => item.game === state.game &&
    !(item.id?.startsWith('gta5-author-addon-') && sourceUrls.has(item.sourceUrl)) && allowedCategories.has(categoryId(item.game, item.category)) && !excludedRedMResource(item) &&
    (pendingDownload(item) || item.status === 'in-menu' || (item.category === 'mod-menus' && item.status === 'preview-only') || authorPage(item) || (item.game === 'cs2' && item.status === 'workshop') ||
      (Array.isArray(item.files) && item.files.some(file => downloadURL(file)))))
    .map(item => ({ ...item, ...(!item.preview ? gtaAddonCatalog.previews?.[item.id] : undefined), tags: Array.isArray(item.tags) ? item.tags : [] }));
}

function excludedRedMResource(entry) {
  if (entry.game !== 'redm') return false;
  const names = [entry.name, entry.category, entry.sourceFilename, ...(Array.isArray(entry.tags) ? entry.tags : [])];
  return names.some(value => /pmbypass|fasterscope|fastscope/.test(normalize(value)));
}

function selectedEntries() {
  return entries.filter(entry => inCategory(entry, state.category));
}

function inCategory(entry, category) {
  return category === 'all' || categoryId(entry.game, entry.category) === category ||
    entry.categories?.some(id => categoryId(entry.game, id) === category) ||
    (category === 'modded' && entry.category === 'vehicles' && entry.attachments > 0);
}

function categoryLabel(game, category) {
  return menuSystem?.categoryLabel(state.menu, category) || (category === 'mod-menus' ? taxonomy?.roleplayCategoryLabel(game, category) : undefined) ||
    (game === 'l4d' ? L4D_LABELS[category] : undefined) || LABELS[category];
}

function categoryButton(category, label = categoryLabel(state.game, category)) {
  const button = node('a', null, 'category-choice');
  button.setAttribute('role', 'button');
  button.dataset.category = category;
  button.setAttribute('aria-pressed', String(state.category === category));
  const menuChoice = hasMenuChoice(state.game);
  const count = menuChoice && category !== 'all' ? menuCategoryCounts.get(category) || 0 : entries.filter(entry =>
    inCategory(entry, category) && (state.game !== 'l4d' || editions.matches(entry, state.edition))).length;
  button.href = routes.catalogURL({ game: state.game, menu: state.menu, category, edition: state.edition }, publishedRoutes);
  button.append(node('span', label), node('small', count.toLocaleString()));
  button.onclick = event => {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0) return;
    event.preventDefault();
    if (gameLoading || state.category === category) return;
    clearTimeout(inputTimer);
    state.category = category;
    state.model = '';
    state.page = 1;
    updateControls();
    saveState();
    render();
    if (mobileFilters.matches) $('filter-panel').open = false;
    else $('categories').querySelector('[aria-pressed="true"]').focus({ preventScroll: true });
  };
  button.onkeydown = event => { if (event.key === ' ') { event.preventDefault(); button.click(); } };
  return button;
}

function setSelect(id, value) {
  $(id).value = value;
  if ($(id).value !== value) { $(id).value = ''; state[id] = ''; }
}

function updateThemeFilters() {
  const themes = state.category === 'themes' ? selectedEntries() : [];
  const interfaces = new Set(themes.flatMap(entry => [].concat(entry.uiStyle || [])));
  const labels = ['ClickUI', 'ClickGUI', 'ListUI'].filter(label => interfaces.has(label));
  $('ui').replaceChildren(new Option('All interfaces', ''), ...labels.map(label => new Option(label, normalize(label))));
  if (state.game === 'gta5' && state.menu === 'cherax' && normalize(state.ui) === 'clickui') state.ui = 'clickgui';
  setSelect('ui', state.ui);
  const styles = new Map();
  for (const theme of themes) {
    if (state.ui && ![].concat(theme.uiStyle || []).some(label => normalize(label) === state.ui)) continue;
    for (const style of [].concat(theme.style || [])) if (normalize(style)) styles.set(normalize(style), style);
  }
  const options = [...styles].sort((a, b) => a[1].localeCompare(b[1]));
  $('style').replaceChildren(new Option('All styles', ''), ...options.map(([value, label]) => new Option(label, value)));
  setSelect('style', state.style);
  $('ui-field').hidden = !labels.length;
  $('style-field').hidden = !styles.size;
  return Boolean(labels.length || styles.size);
}

function updateControls() {
  gameTabs.forEach(button => {
    const game = button.dataset.game;
    button.setAttribute('aria-pressed', String(game === state.game));
    if (button.tagName === 'A') button.href = nenyooLuaGame(game)
      ? routes.catalogURL({ game, menu: 'nenyoo', category: 'lua' }, publishedRoutes) : routes.collectionPath(game);
  });
  const menuChoice = hasMenuChoice(state.game);
  $('collection-title').textContent = collectionTitle();
  const editionGroup = editions.group(state.game);
  $('collection-selectors').hidden = !editionGroup && !menuChoice;
  $('menu-field').hidden = !menuChoice;
  $('edition').parentElement.hidden = !editionGroup;
  if (editionGroup && $('edition').dataset.game !== state.game) {
    $('edition-label').textContent = editionGroup.label;
    $('edition').replaceChildren(new Option(editionGroup.all, ''), ...Object.entries(editionGroup.options).map(([value, label]) => new Option(label, value)));
    $('edition').dataset.game = state.game;
  }
  $('edition').value = state.edition;
  $('menu').replaceChildren();
  for (const menu of menuSystem?.menusFor(state.game) || [{ id: 'scooby', name: 'Scooby' }]) $('menu').add(new Option(menu.name + (menu.deferred ? ' · Coming soon' : ''), menu.id));
  $('menu').value = state.menu;
  const source = menuSystem?.menusFor(state.game).find(menu => menu.id === state.menu)?.source;
  const sourceLink = $('menu-source');
  sourceLink.hidden = !source;
  sourceLink.textContent = source?.label || '';
  if (source) sourceLink.href = source.url;
  else sourceLink.removeAttribute('href');
  $('context-guide').href = guideURL();
  const graphicsTopics = $('graphics-topics');
  const topics = state.game === 'redm' && ['all', 'graphics-packs'].includes(state.category)
    ? new Set(entries.flatMap(taxonomy.redmGraphicsTopics)) : new Set();
  graphicsTopics.hidden = !topics.size;
  graphicsTopics.firstElementChild.replaceChildren(...taxonomy.REDM_GRAPHICS_TOPICS.filter(topic => topics.has(topic)).map(topic =>
    link(topic.name, routes.catalogURL({ game: state.game, category: 'graphics-packs', q: topic.query }, publishedRoutes))));
  $('search').value = state.q;
  $('search').placeholder = {
    gta5: 'Search outfits, vehicles or files…', rdr2: 'Search outfits or files…',
    cs2: 'Search models, skyboxes or files…', fivem: 'Search packs, recipes or files…',
    redm: 'Search outfits, peds or files…', l4d: 'Search campaigns, models or files…'
  }[state.game];
  $('categories').replaceChildren(categoryButton('all'));
  const assets = GAMES[state.game].assets;
  const roleplay = roleplayGroups(state.game);
  const groups = menuChoice
    ? menuSystem.categoryGroups(state.menu, menuCategoryCounts.keys())
    : state.game === 'l4d' ? [
      ['Custom content', assets.filter(category => entries.some(entry => inCategory(entry, category)))],
      ['Settings and translations', MENU_CATEGORIES.filter(category => entries.some(entry => inCategory(entry, category)))]
    ]
    : roleplay || [
    [`${menuName()}’s resources`, assets.filter(category => !category.startsWith('addon-'))],
    ['Addons', assets.filter(category => category.startsWith('addon-'))],
    [`${menuName()} files`, MENU_CATEGORIES]
  ];
  for (const [label, list] of groups) {
    if (!list.length) continue;
    const group = node('div', null, 'category-group');
    group.append(node('p', label, 'category-group-label'));
    for (const category of list) group.append(categoryButton(category, roleplay ? taxonomy.roleplayCategoryLabel(state.game, category) : undefined));
    $('categories').append(group);
  }
  const models = new Map();
  if (state.category !== 'all') {
    for (const entry of selectedEntries()) {
      const label = String(entry.modelLabel || entry.model || '').trim();
      if (entry.model && label && !/^(?:[+-]?\d+|0x[\da-f]+)$/i.test(label)) models.set(String(entry.model), label);
    }
  }
  $('model').replaceChildren(new Option('All models', ''));
  [...models].sort((a, b) => a[1].localeCompare(b[1])).forEach(([value, label]) => $('model').add(new Option(label, value)));
  $('model-field').hidden = !models.size;
  for (const id of ['model', 'sort']) setSelect(id, state[id]);
  const themeFilters = updateThemeFilters();
  $('filters').hidden = !models.size && !themeFilters;
  const attachments = state.game === 'gta5' && ['all', 'vehicles', 'modded'].includes(state.category);
  $('sort').querySelector('[value=attachments]').disabled = !attachments;
  if (!attachments && state.sort === 'attachments') { state.sort = ''; $('sort').value = ''; }
  $('install-note').textContent = hasMenuChoice(state.game) && state.menu !== 'scooby'
    ? `Keep the complete download together and follow its installation guide. Choose files made for ${menuName()} and your game version.`
    : ['gta5', 'rdr2'].includes(state.game)
    ? 'Keep the complete download together and follow its installation guide. A theme’s appearance can resemble another menu while using Scooby’s own format. Choose a theme that supports your ClickUI or ListUI interface.'
    : state.game === 'l4d'
    ? 'Check the game badge and follow the resource’s install guide. Workshop subscriptions, manual add-ons and Scooby files use different install methods.'
    : 'Keep the complete download together and follow its installation guide. Check that the resource supports your game and Scooby version.';
  $('catalog-warning').replaceChildren();
  $('catalog-warning').hidden = !libraryError;
  if (libraryError) {
    $('catalog-warning').append(node('span', 'Some resources could not be loaded. Existing GTA 5 presets are still available. '));
    const retry = node('button', 'Retry catalog');
    retry.type = 'button';
    retry.onclick = async () => { retry.disabled = true; await loadLibrary(); await loadGame(); };
    $('catalog-warning').append(retry);
  }
}

function setLoading(loading) {
  gameLoading = loading;
  $('menu').disabled = loading;
  $('edition').disabled = loading;
  for (const form of ['filters', 'search-controls']) for (const control of $(form).elements) control.disabled = loading;
  $('categories').querySelectorAll('.category-choice').forEach(button => { button.setAttribute('aria-disabled', String(loading)); button.tabIndex = loading ? -1 : 0; });
}

async function loadGame() {
  const token = ++loadRevision;
  ++revision;
  setLoading(true);
  $('status').textContent = 'Loading collection…';
  $('grid').setAttribute('aria-busy', 'true');
  $('grid').replaceChildren();
  $('prev').disabled = true;
  $('next').disabled = true;
  try {
    const game = state.game;
    const original = game === 'gta5' ? (await Promise.all([loadLegacy('vehicles'), loadLegacy('outfits')])).flat() : [];
    if (token !== loadRevision) return;
    entries = [...original, ...libraryEntries()].filter(supportsMenu).map(item => {
      const entry = editions.withVerification(item, gtaEditionCatalog);
      return menuSystem?.isCheraxTheme(entry) ? { ...entry, uiStyle: menuSystem.themeInterface(entry) } : entry;
    });
    if (hasMenuChoice(game)) {
      menuCategoryCounts = new Map(categories(game).map(id => [id, entries.filter(entry => inCategory(entry, id)).length]).filter(([, count]) => count));
      if (state.category !== 'all' && !menuCategoryCounts.has(state.category)) {
        state.category = 'all';
        state.page = 1;
        saveState(true);
      }
    }
    setLoading(false);
    updateControls();
    await render();
    if (token === loadRevision) await openLinkedResource(token);
  } catch {
    if (token === loadRevision) { setLoading(false); failure(loadGame); }
  }
}

function failure(retry) {
  $('grid').replaceChildren();
  $('status').replaceChildren(node('span', 'Unable to load this collection. '));
  const button = node('button', 'Try again');
  button.type = 'button';
  button.onclick = retry;
  $('status').append(button);
  $('grid').setAttribute('aria-busy', 'false');
  $('page').textContent = '';
  $('prev').disabled = true;
  $('next').disabled = true;
}

async function resolveFiles(entry) {
  if (!entry._legacy) return (Array.isArray(entry.files) ? entry.files : []).map(file => ({ ...file, url: downloadURL(file) })).filter(file => file.url);
  const { family, index, data, assets, row } = entry._legacy;
  if (assets?.file) {
    const localURL = safeURL(assets.file, new URL('/community/', location.href));
    const base = safeURL(library.legacyDownloadBaseUrl);
    const filename = assets.file.split('/').pop();
    const remoteURL = base ? safeURL(`${family}/${encodeURIComponent(filename)}`, base.endsWith('/') ? base : `${base}/`) : '';
    return [{ name: matchingFilename(row[1], assets.file), formatPath: assets.file, url: LOCAL_PREVIEW ? localURL : (remoteURL || localURL), fallbackUrl: localURL }].filter(file => file.url);
  }
  const chunk = await json(`/community/data/${family}/chunks/${String(Math.floor(index / data.chunkSize)).padStart(3, '0')}.json`);
  const path = chunk[index % data.chunkSize]?.[0];
  if (typeof path !== 'string' || path.split('/').includes('..')) return [];
  const base = safeURL(data.sourceBaseUrl);
  if (!base || new URL(base).hostname !== 'raw.githubusercontent.com') return [];
  return [{ name: matchingFilename(row[1], path), formatPath: path, url: safeURL(path.split('/').map(encodeURIComponent).join('/'), base) }];
}

function matchingFilename(name, actualPath) {
  const actualSuffix = String(actualPath || '').match(/(\.(?:zip|7z|rar)\.\d{3}|\.[a-z0-9_]{1,10})$/i)?.[1];
  let filename = String(name || String(actualPath || '').split('/').pop() || 'download');
  if (!actualSuffix || filename.toLowerCase().endsWith(actualSuffix.toLowerCase())) return filename;
  filename = filename.replace(/(\.(?:zip|7z|rar)\.\d{3}|\.[a-z0-9_]{1,10})$/i, '');
  return filename + actualSuffix;
}

function fileExtension(file) {
  if (!file) return '';
  let urlPath = '';
  try { urlPath = decodeURIComponent(new URL(file.url).pathname); } catch { /* Use the supplied file name or path. */ }
  for (const value of [file.formatPath, file.name, file.path, urlPath]) {
    if (typeof value !== 'string') continue;
    const split = value.match(/\.(zip|7z|rar)\.\d{3}$/i);
    if (split) return split[1].toLowerCase();
    const extension = value.match(/\.([a-z0-9_]{1,10})$/i);
    if (extension) return extension[1].toLowerCase();
  }
  return '';
}

function resourceTitle(name, files, knownExtension = '') {
  const archives = new Set(['zip', '7z', 'rar', 'gz']);
  const primary = files.find(file => archives.has(fileExtension(file))) || files[0];
  const extension = fileExtension(primary) || knownExtension;
  let label = String(name);
  if (extension) {
    const suffix = label.match(/\.([a-z0-9_]{1,10})(?:\.\d{3})?$/i);
    const known = new Set(['json', 'xml', 'txt', 'ini', 'zip', '7z', 'rar', 'gz', 'asi', 'dll', 'cs', 'cfg', 'config', 'lua', 'png', 'jpg', 'jpeg', 'webp', 'gif', 'dds', 'ytd', 'ydr', 'yft', 'ydd', 'ybn', 'ymap', 'ytyp', 'vmdl_c', 'vmat_c', 'vtex_c', 'fbx', 'obj', 'md', 'pdf']);
    if (suffix && (suffix[1].toLowerCase() === extension || known.has(suffix[1].toLowerCase()))) label = label.slice(0, -suffix[0].length);
  }
  label = label.replace(/_/g, ' ');
  const title = node('h3', null, 'resource-title');
  title.append(node('span', label, 'resource-name'));
  if (extension) title.append(node('span', `.${extension}`, `file-extension ext-${extension}`));
  return title;
}

function downloadButton(file, container) {
  const button = node('button', 'Download ↓');
  button.type = 'button';
  let error;
  button.onclick = async () => {
    const directURL = new URL(file.url);
    const archive = ['zip', 'rar', '7z', 'gz'].includes(fileExtension(file));
    const storedFile = directURL.origin === location.origin || directURL.hostname === 'raw.githubusercontent.com';
    const largeArchive = archive && storedFile && Number(file.size) >= 50 * 1024 * 1024;
    const directArchive = archive && file.downloadMethod === 'direct';
    const releaseArchive = archive && directURL.hostname === 'github.com' && directURL.pathname.includes('/releases/download/');
    if (directArchive || largeArchive || releaseArchive) {
      const anchor = link('', file.url);
      if (file.name) anchor.download = file.name;
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      button.textContent = 'Download started';
      return;
    }
    button.disabled = true;
    button.textContent = 'Downloading…';
    if (error) { error.remove(); error = undefined; }
    try {
      let response;
      const urls = [...new Set([file.url, file.fallbackUrl].filter(Boolean))];
      for (const url of urls) {
        try {
          const attempt = await fetch(url, { signal: AbortSignal.timeout(30000) });
          const mime = attempt.headers.get('content-type') || '';
          if (attempt.ok && !/text\/html|application\/xhtml\+xml/i.test(mime)) { response = attempt; break; }
        } catch { /* Try the preserved local preset when a remote download is unavailable. */ }
      }
      if (!response) throw new Error('Download unavailable');
      const objectURL = URL.createObjectURL(await response.blob());
      const anchor = node('a');
      anchor.href = objectURL;
      anchor.download = file.name || new URL(file.url).pathname.split('/').pop() || 'download';
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      setTimeout(() => URL.revokeObjectURL(objectURL), 10000);
      button.textContent = 'Downloaded ✓';
    } catch {
      button.textContent = 'Retry download';
      error = node('p', 'Download unavailable. Please retry.', 'download-error');
      container.append(error);
    } finally { button.disabled = false; }
  };
  return button;
}

function textMetadata(value) {
  if (Array.isArray(value)) return value.map(textMetadata).filter(Boolean).join(', ');
  if (value && typeof value === 'object') return Object.entries(value).map(([key, item]) => `${key}: ${textMetadata(item)}`).join(' · ');
  return String(value || '');
}

function visibleText(entry, value) {
  const text = textMetadata(value);
  return entry.category === 'lua' ? text.replace(/(?:https?:\/\/)?(?:www\.)?(?:discord\.gg\/|discord(?:app)?\.com\/(?:invite|channels)\/)\S+/gi, '').trim() : text;
}

function changelogButton(entry) {
  const button = node('button', 'Changelog', 'changelog-button');
  button.type = 'button';
  button.onclick = () => showChangelog(entry);
  return button;
}

function pendingDownloadButton(entry) {
  const button = node('button', entry.downloadLabel || 'Download — Coming soon', 'download-pending');
  button.type = 'button';
  button.disabled = true;
  return button;
}

function versionDownload(entry, files) {
  const control = node('div', null, 'version-download');
  const label = node('label', 'Version');
  const select = node('select');
  const action = node('div');
  for (const version of entry.unavailableVersions || []) {
    const option = new Option(version + ' — unavailable', '');
    option.disabled = true;
    select.add(option);
  }
  files.forEach((file, index) => select.add(new Option(file.versionLabel || file.name, String(index))));
  select.value = '0';
  const update = () => action.replaceChildren(downloadButton(files[Number(select.value)], action));
  select.onchange = update;
  label.append(select);
  control.append(label, action);
  update();
  return control;
}

function showChangelog(entry) {
  $('changelog-title').textContent = `${visibleText(entry, entry.name)} · Changelog`;
  const content = $('changelog-content');
  content.replaceChildren();
  const releases = Array.isArray(entry.changelog) ? entry.changelog.filter(release => release && typeof release === 'object') : [];
  if (!releases.length) content.append(node('p', 'No changelog has been published for this resource.'));
  for (const release of releases) {
    const section = node('section', null, 'changelog-entry');
    const sourceUpdate = /commit/i.test(release.dateBasis || '');
    section.append(node('h3', sourceUpdate ? `Source update${release.version ? ' · ' + visibleText(entry, release.version) : ''}` : release.version ? visibleText(entry, release.version) : 'Release notes'));
    if (release.date) {
      const time = node('time', visibleText(entry, release.date));
      if (/^\d{4}-\d{2}-\d{2}/.test(String(release.date))) time.dateTime = String(release.date);
      section.append(time);
    }
    const changes = Array.isArray(release.changes) ? release.changes.map(change => visibleText(entry, change)).filter(Boolean) : [];
    if (changes.length) {
      const list = node('ul');
      changes.forEach(change => list.append(node('li', change)));
      section.append(list);
    } else section.append(node('p', 'No release notes were provided for this version.'));
    content.append(section);
  }
  if ($('preview').open) $('preview').close();
  if (!$('changelog').open) $('changelog').showModal();
}

function tagLinks(entry) {
  const explicit = new Set([
    entry.game, entry.category, entry.uiStyle, entry.style, entry.modelLabel, entry.model,
    entry.game === 'gta5' ? entry.editionSupport : '',
    entry.tags, entry.keywords
  ].flat(Infinity).filter(value => typeof value === 'string' && !/[\\/]|https?:/i.test(value))
    .flatMap(value => value.split(/[,;|\n]+/)).map(normalizeSearch));
  const allTags = taxonomy ? taxonomy.tagsFor(entry, { compact: true }) : resourceTags(entry);
  const tags = allTags.filter(tag => explicit.has(tag) && tag.length <= 42 && !/^\d+$/.test(tag) && !/gta\s*5\s*mods/.test(tag) && !(entry.category === 'lua' && /discord/.test(tag))).slice(0, 12);
  if (!tags.length) return null;
  const section = node('section', null, 'resource-tags');
  section.setAttribute('aria-label', 'Resource tags');
  section.append(node('h3', 'Tags'));
  const links = node('div');
  for (const tag of tags) {
    const url = routes.catalogURL({ game: state.game, menu: state.menu, category: state.category, edition: state.edition, q: tag, sort: state.sort }, publishedRoutes);
    const choice = link(tag, url);
    choice.title = `Search for ${tag}`;
    choice.onclick = event => {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0) return;
      event.preventDefault();
      clearTimeout(inputTimer);
      state = { ...state, q: tag, model: '', ui: '', style: '', page: 1 };
      updateControls();
      saveState();
      $('preview').close();
      render();
      $('search').focus({ preventScroll: true });
    };
    links.append(choice);
  }
  section.append(links);
  return section;
}

function themeImageGallery(entry) {
  const base = safeURL(entry.imageBaseUrl);
  if (!base || !entry.imagePaths?.length) return null;

  const gallery = node('section', null, 'theme-gallery');
  gallery.setAttribute('aria-label', 'Theme images');
  const controls = node('div', null, 'theme-gallery-controls');
  const label = node('label', `Theme images (${entry.imagePaths.length})`);
  const picker = node('select');
  entry.imagePaths.forEach((file, index) => picker.add(new Option(file, String(index))));
  label.append(picker);
  const navigation = node('div', null, 'theme-gallery-navigation');
  const previous = node('button', 'Previous');
  const next = node('button', 'Next');
  previous.type = next.type = 'button';
  previous.setAttribute('aria-label', 'Previous theme image');
  next.setAttribute('aria-label', 'Next theme image');
  const original = link('Open original ↗', base, true);
  navigation.append(previous, next, original);
  controls.append(label, navigation);
  const figure = node('figure', null, 'theme-gallery-image');
  gallery.append(controls, figure);

  function selectImage(index) {
    const file = entry.imagePaths[index];
    const url = safeURL(file.split('/').map(encodeURIComponent).join('/'), base);
    picker.value = String(index);
    previous.disabled = index === 0;
    next.disabled = index === entry.imagePaths.length - 1;
    original.href = url;
    figure.replaceChildren(image(url, `${entry.name} — ${file}`, true));
  }

  picker.onchange = () => selectImage(Number(picker.value));
  previous.onclick = () => selectImage(Number(picker.value) - 1);
  next.onclick = () => selectImage(Number(picker.value) + 1);
  selectImage(0);
  return gallery;
}

function showDetails(entry, files) {
  const hash = routes.resourceHash(entry.id);
  linkedPreviewHash = location.hash === hash ? hash : '';
  $('preview-title').textContent = visibleText(entry, entry.name);
  const preview = previewURL(entry);
  const gallery = themeImageGallery(entry);
  $('pictures').replaceChildren();
  if (gallery) $('pictures').append(gallery);
  else if (preview) {
    const figure = node('figure', null, 'preview-figure');
    figure.append(image(preview, entry.name, cheraxPreview(entry)));
    if (entry.previewCaption) {
      const caption = node('figcaption', null, 'preview-caption');
      const source = safeURL(entry.previewSource);
      caption.append(source ? link(entry.previewCaption, source, true) : entry.previewCaption);
      figure.append(caption);
    }
    $('pictures').append(figure);
  }
  const details = $('preview-details');
  details.replaceChildren();
  if (ACCESS_LABELS[entry.access]) details.append(node('span', ACCESS_LABELS[entry.access], 'resource-access'));
  if (entry.description) details.append(node('p', visibleText(entry, entry.description)));
  if (entry.compatibility) details.append(node('p', visibleText(entry, entry.compatibility)));
  const edition = editions.support(entry);
  const install = safeURL(entry.installUrl);
  if (edition) {
    const compatibility = node('p', `${entry.game === 'l4d' ? 'Game' : 'GTA 5 edition'}: ${editions.gameLabel(entry.game, edition)}`);
    const evidence = safeURL(entry.editionSource);
    if (evidence && evidence !== install) compatibility.append(' · ', link('Compatibility source ↗', evidence, true));
    details.append(compatibility);
  } else if (entry.edition) details.append(node('p', `Edition: ${visibleText(entry, entry.edition)}`));
  const requirements = Array.isArray(entry.requirements) ? entry.requirements.map(value => visibleText(entry, value)).filter(Boolean) : [];
  if (requirements.length) {
    const section = node('section', null, 'resource-requirements');
    section.append(node('h3', 'Requirements'));
    const list = node('ul');
    requirements.forEach(requirement => list.append(node('li', requirement)));
    section.append(list);
    details.append(section);
  }
  if (entry.format) details.append(node('p', `Format: ${visibleText(entry, entry.format)}`));
  if (entry.uiStyle || entry.style) details.append(node('p', [textMetadata(entry.uiStyle), entry.style && `Appearance: ${entry.style}`].filter(Boolean).join(' · ')));
  if (entry.author || entry.credits) details.append(node('p', `Credits: ${visibleText(entry, entry.credits || entry.author)}`));
  if (entry.license) details.append(node('p', `License: ${visibleText(entry, entry.license)}`));
  if (authorPage(entry)) {
    const source = link(authorAction(entry), authorPage(entry), true);
    source.className = 'external-primary';
    details.append(source);
  } else if (pendingDownload(entry)) {
    details.append(pendingDownloadButton(entry));
  } else if (entry.category === 'lua' && files.length > 1 && files.every(file => file.versionLabel)) {
    details.append(versionDownload(entry, files));
  } else if (files.length) {
    const list = node('div', null, 'file-list');
    for (const file of files) {
      const row = node('div', null, 'file-row');
      row.append(node('strong', file.name || 'Download file'));
      if (prettySize(file.size)) row.append(node('span', prettySize(file.size)));
      const actions = node('div');
      actions.append(downloadButton(file, row));
      row.append(actions);
      list.append(row);
    }
    details.append(list);
  } else details.append(node('p', entry.status === 'in-menu' ? entry.category === 'themes' ? 'This style is included with Scooby. Follow the guide to select the interface and its built-in appearance.' : entry.game === 'cs2' ? 'This item is included in Scooby’s model selector. Follow the guide to select it in the menu.' : 'This item is included with Scooby. Follow the guide to find it in the menu.' : entry.status === 'workshop' ? 'This repository entry is documented in the installation guide. A downloadable package is not available here.' : 'A download is not available for this item.'));
  const tags = tagLinks(entry);
  if (tags) details.append(tags);
  if (entry.category === 'lua' && !entry.builtInLua) details.append(changelogButton(entry));
  details.append(install ? link('Author’s install guide ↗', install, true) : link('Installation guide ↗', guideURL(entry)));
  const permalink = node('p');
  permalink.append(link('Resource permalink', resourceURL(entry)));
  details.append(permalink);
  if (!$('preview').open) $('preview').showModal();
}

async function openLinkedResource(token) {
  const hash = location.hash;
  if (!hash.startsWith('#resource-')) return;
  const entry = entries.find(entry => routes.resourceHash(entry.id) === hash);
  if (!entry) return;
  const files = pendingDownload(entry) ? [] : await resolveFiles(entry).catch(() => []);
  if (token === loadRevision && hash === location.hash) showDetails(entry, files);
}

async function card(entry) {
  const files = pendingDownload(entry) ? [] : await resolveFiles(entry);
  const article = node('article', null, 'card');
  article.dataset.category = entry.category;
  const shot = node('button', null, 'shot');
  shot.type = 'button';
  shot.setAttribute('aria-label', `View ${entry.name}`);
  const preview = previewURL(entry);
  const gtaAddon = entry.game === 'gta5' && entry.category.startsWith('addon-');
  if (entry.category === 'themes' && preview) article.className += ' has-verified-preview';
  const compactLua = entry.category === 'lua' && !preview && (cheraxPreview(entry) || entry.builtInLua);
  if (!compactLua) shot.append(image(preview, entry.name, cheraxPreview(entry) || (!preview && gtaAddon)));
  shot.onclick = () => showDetails(entry, files);
  const info = node('div', null, 'info');
  const pendingExtension = String(entry.sourceFilename || '').match(/\.(lua|pluto)$/i)?.[1]?.toLowerCase();
  const knownExtension = entry.builtInLua ? '.lua' : pendingDownload(entry) && pendingExtension === normalize(entry.formatExtension) ? pendingExtension : '';
  const title = resourceTitle(visibleText(entry, entry.name), files, knownExtension);
  title.title = title.textContent;
  const name = title.firstElementChild;
  const permalink = link(name.textContent, resourceURL(entry));
  permalink.className = name.className;
  name.replaceWith(permalink);
  info.append(title);
  info.append(node('p', [entry.modelLabel || (entry.builtInLua ? 'Built-in Lua module' : categoryLabel(entry.game, entry.category)), entry.attachments > 0 && `${entry.attachments} attachments`, files.length === 1 && prettySize(files[0].size), entry.status === 'in-menu' && 'In-menu', entry.status === 'workshop' && 'Workshop'].filter(Boolean).join(' · ')));
  const edition = editions.support(entry);
  if (edition) {
    const badge = node('span', editions.badge(entry.game, edition), `edition-badge edition-${edition}`);
    badge.title = editions.title(entry.game, edition);
    info.append(badge);
  } else if (gtaAddon) {
    info.append(node('span', 'Edition unlisted', 'edition-badge edition-unlisted'));
  }
  const sourceMenu = menuSystem?.canonical(entry.sourceMenu);
  if (['cherax', 'stand', 'xforce'].includes(sourceMenu) && typeof menuSystem?.compatibleWith === 'function' && !menuSystem.compatibleWith(entry, state.menu)) {
    info.append(node('p', visibleText(entry, entry.requirementLabel || `Requires ${menuName(sourceMenu)} format`), 'compatibility-note'));
  }
  if (entry.description) info.append(node('p', visibleText(entry, entry.description), 'description'));
  if (entry.requirementLabel && (sourceMenu === 'nenyoo' && entry.category === 'lua' || isFiveMRecipe(entry) || entry.game === 'l4d' || (entry.game === 'cs2' && ['skyboxes', 'textures'].includes(entry.category)))) {
    info.append(node('p', entry.requirementLabel, 'compatibility-note'));
  }
  if (ACCESS_LABELS[entry.access]) info.append(node('span', ACCESS_LABELS[entry.access], 'resource-access'));
  if (entry.status === 'preview-only') info.append(node('p', 'Download unavailable', 'meta'));
  if (entry.uiStyle || entry.style) info.append(node('p', [textMetadata(entry.uiStyle), entry.style && `${entry.style} style`].filter(Boolean).join(' · '), 'meta'));
  const actions = node('div', null, 'card-actions');
  const source = authorPage(entry);
  if (source) {
    const credit = entry.author || (entry.game === 'l4d' ? entry.credits : '');
    if (credit) info.append(node('p', `By ${visibleText(entry, credit)}`));
    const external = link(authorAction(entry), source, true);
    external.className = 'external-primary';
    actions.append(external);
    if (isFiveMRecipe(entry)) {
      const requirements = node('button', 'Requirements');
      requirements.type = 'button';
      requirements.onclick = () => showDetails(entry, files);
      actions.append(requirements);
    }
  } else if (pendingDownload(entry)) actions.append(pendingDownloadButton(entry));
  else if (!files.length) {
    const details = node('button', 'Details');
    details.type = 'button';
    details.className = 'theme-details';
    details.onclick = () => showDetails(entry, files);
    actions.append(details);
  }
  if (files.length === 1) {
    actions.append(downloadButton(files[0], info));
  } else if (entry.category === 'lua' && files.length > 1 && files.every(file => file.versionLabel)) {
    actions.append(versionDownload(entry, files));
  } else if (files.length > 1) {
    const details = node('button', 'Download ↓');
    details.type = 'button';
    details.onclick = () => showDetails(entry, files);
    actions.append(details);
  }
  if (entry.imagePaths?.length) {
    const images = node('button', `Images (${entry.imagePaths.length})`);
    images.type = 'button';
    images.onclick = () => showDetails(entry, files);
    actions.append(images);
  }
  if (entry.category === 'lua' && !entry.builtInLua) actions.append(changelogButton(entry));
  if (compactLua && (files.length || pendingDownload(entry))) {
    const details = node('button', 'Details', 'theme-details');
    details.type = 'button';
    details.onclick = () => showDetails(entry, files);
    actions.append(details);
  }
  info.append(actions);
  if (source || files.length || entry.status === 'in-menu' || pendingDownload(entry)) {
    const install = safeURL(entry.installUrl);
    const guide = install ? link('Author’s install guide ↗', install, true) : link('Install guide ↗', guideURL(entry));
    guide.className = 'guide-link';
    info.append(guide);
  }
  if (!compactLua && (preview || (entry.category !== 'themes' && !isFiveMRecipe(entry)))) article.append(shot);
  article.append(info);
  return article;
}

function matchesFilters(entry) {
  if (!editions.matches(entry, state.edition)) return false;
  const query = normalizeSearch(state.q);
  if (state.model && String(entry.model) !== state.model) return false;
  if (state.ui && ![].concat(entry.uiStyle || []).some(ui => normalize(ui) === normalize(state.ui))) return false;
  if (state.style && ![].concat(entry.style || []).some(style => normalize(style) === normalize(state.style))) return false;
  if (!query) return true;
  const graphicsTopic = state.game === 'redm' && taxonomy?.redmGraphicsTopicForQuery(query);
  if (graphicsTopic) return taxonomy.redmGraphicsTopics(entry).includes(graphicsTopic);
  const text = resourceSearchText(entry);
  return query.split(/\s+/).every(word => text.includes(word));
}

function emptyState() {
  const empty = node('div', null, 'empty');
  const activeFilters = state.edition || state.q || state.model || state.ui || state.style;
  const category = LABELS[state.category] || 'Files';
  if (menuSystem?.MENUS.find(menu => menu.id === state.menu)?.deferred) {
    empty.append(node('h3', `${menuName()} resources are coming soon.`), node('p', 'This menu’s collection is not available yet. Choose another menu to browse resources.'));
    return empty;
  }
  empty.append(node('h3', activeFilters ? 'No matching downloads.' : `${state.category === 'all' ? 'Downloads' : category} are being collected.`));
  empty.append(node('p', activeFilters
    ? 'Try a shorter search, another category or fewer filters.'
    : `There are no published ${state.category === 'all' ? 'files' : category.toLowerCase()} for ${menuName()} ${GAMES[state.game].name} in this collection yet. You can still read the installation guide and browse other categories.`));
  if (activeFilters) {
    const reset = node('button', 'Clear filters');
    reset.type = 'button';
    reset.onclick = resetFilters;
    empty.append(reset);
  }
  empty.append(link('Installation guide ↗', guideURL()));
  return empty;
}

async function render() {
  if (gameLoading) return;
  const token = ++revision;
  const matches = selectedEntries().filter(matchesFilters);
  const nenyooThemes = state.menu === 'nenyoo' && state.category === 'themes';
  const importedTheme = entry => nenyooThemes && entry.source === 'Nenyoo Resources' && previewAllowed(entry);
  matches.sort(state.sort === 'name'
    ? (a, b) => a.name.localeCompare(b.name)
    : state.sort === 'attachments'
      ? (a, b) => (b.attachments || 0) - (a.attachments || 0)
      : (a, b) => Number(importedTheme(b)) - Number(importedTheme(a)) || Number(Boolean(b.preview) && previewAllowed(b)) - Number(Boolean(a.preview) && previewAllowed(a)));
  const pages = Math.max(1, Math.ceil(matches.length / PAGE_SIZE));
  state.page = Math.min(state.page, pages);
  saveState(true);
  $('prev').disabled = state.page === 1;
  $('next').disabled = state.page === pages;
  $('page').textContent = `${state.page} / ${pages}`;
  $('status').textContent = `${matches.length.toLocaleString()} items${matches.length ? ' · Loading files…' : ''}`;
  $('grid').setAttribute('aria-busy', 'true');
  $('grid').replaceChildren();
  try {
    const cards = await Promise.all(matches.slice((state.page - 1) * PAGE_SIZE, state.page * PAGE_SIZE).map(card));
    if (token !== revision) return;
    $('grid').replaceChildren(...(cards.length ? cards : [emptyState()]));
    $('status').textContent = `${matches.length.toLocaleString()} items${matches.length ? ` · Page ${state.page} of ${pages}` : ''}`;
    $('grid').setAttribute('aria-busy', 'false');
  } catch { if (token === revision) failure(render); }
}

function resetFilters() {
  clearTimeout(inputTimer);
  state = { ...state, edition: '', q: '', model: '', ui: '', style: '', sort: '', page: 1 };
  updateControls();
  saveState();
  render();
}

const gtaMenuDialog = $('gta-menu-dialog');
const gtaMenuPreference = 'scooby.resources.gta5-menu';

function rememberedGtaMenu() {
  try {
    const id = localStorage.getItem(gtaMenuPreference);
    return menuSystem?.MENUS.find(menu => menu.id === id && !menu.deferred)?.id || '';
  } catch { return ''; }
}

function rememberGtaMenu(id) {
  try { localStorage.setItem(gtaMenuPreference, id); }
  catch { /* Storage may be blocked in this browser. */ }
}

function openGtaMenuDialog() {
  if (gtaMenuDialog.open) return;
  gtaMenuDialog.returnValue = '';
  $('gta-menu-remember').checked = false;
  gtaMenuDialog.showModal();
}

function nenyooLuaGame(game) {
  return state.menu === 'nenyoo' && state.category === 'lua' && menuFor(game, 'nenyoo') === 'nenyoo';
}

function selectResourceGame(game, menu = 'scooby') {
  const selectedMenu = menuFor(game, menu);
  if (game === state.game && selectedMenu === state.menu) { saveState(); return; }
  clearTimeout(inputTimer);
  const sameGame = game === state.game;
  state = {
    game, menu: selectedMenu, category: sameGame || (selectedMenu === 'nenyoo' && nenyooLuaGame(game)) ? state.category : 'all',
    edition: sameGame ? state.edition : '', q: '', model: '', ui: '', style: '',
    sort: sameGame ? state.sort : '', page: 1
  };
  saveState();
  if (catalogReady) loadGame();
}

function chooseResourceGame(game, currentMenu) {
  if (nenyooLuaGame(game)) { selectResourceGame(game, 'nenyoo'); return; }
  if (game === 'gta5') {
    const remembered = rememberedGtaMenu();
    if (!remembered) { openGtaMenuDialog(); return; }
    selectResourceGame(game, currentMenu || remembered);
  } else selectResourceGame(game);
}

for (const menu of menuSystem?.MENUS || [{ id: 'scooby', name: 'Scooby' }]) {
  const choice = node('button', menu.name + (menu.deferred ? ' · Coming soon' : ''), 'gta-menu-choice');
  choice.type = 'submit';
  choice.value = menu.id;
  choice.disabled = Boolean(menu.deferred);
  if (menu.id === 'scooby') {
    choice.classList.add('gta-menu-primary');
    choice.autofocus = true;
  }
  $('gta-menu-options').append(choice);
}
gtaMenuDialog.addEventListener('close', () => {
  const menu = menuSystem?.MENUS.find(option => option.id === gtaMenuDialog.returnValue && !option.deferred);
  if (!menu) return;
  if ($('gta-menu-remember').checked) rememberGtaMenu(menu.id);
  selectResourceGame('gta5', menu.id);
});

gameTabs.forEach(button => {
  button.onclick = event => {
    if (button.tagName === 'A' && (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0)) return;
    event.preventDefault();
    const game = button.dataset.game;
    chooseResourceGame(game, state.game === game ? state.menu : '');
  };
  if (button.tagName === 'A') button.onkeydown = event => { if (event.key === ' ') { event.preventDefault(); button.click(); } };
});
$('menu').onchange = () => {
  const selected = $('menu').value;
  if (state.game === 'gta5' && rememberedGtaMenu() && menuSystem?.MENUS.some(menu => menu.id === selected && !menu.deferred)) rememberGtaMenu(selected);
  selectResourceGame(state.game, selected);
};
$('edition').onchange = () => {
  clearTimeout(inputTimer);
  state.edition = editions.choice(state.game, $('edition').value);
  state.page = 1;
  updateControls();
  saveState();
  render();
};
for (const id of ['filters', 'search-controls']) {
  $(id).onsubmit = event => event.preventDefault();
  $(id).onreset = event => { event.preventDefault(); resetFilters(); };
}
$('search').oninput = () => {
  state.q = $('search').value;
  state.page = 1;
  clearTimeout(inputTimer);
  inputTimer = setTimeout(() => { saveState(true); render(); }, 150);
};
for (const id of ['model', 'ui', 'style', 'sort']) $(id).onchange = () => {
  state[id] = $(id).value;
  state.page = 1;
  if (id === 'ui') updateThemeFilters();
  saveState();
  render();
};
for (const [id, step] of [['prev', -1], ['next', 1]]) $(id).onclick = () => {
  state.page += step;
  saveState();
  render();
  $('collection-title').scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'start' });
};
$('close').onclick = () => $('preview').close();
$('close-changelog').onclick = () => $('changelog').close();
$('changelog').addEventListener('click', event => {
  if (event.target !== $('changelog')) return;
  const rect = $('changelog').getBoundingClientRect();
  if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) $('changelog').close();
});
$('preview').addEventListener('click', event => {
  if (event.target !== $('preview')) return;
  const rect = $('preview').getBoundingClientRect();
  if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) $('preview').close();
});
window.addEventListener('popstate', () => {
  clearTimeout(inputTimer);
  if (linkedPreviewHash && linkedPreviewHash !== location.hash) {
    $('preview').close();
    linkedPreviewHash = '';
  }
  state = readState();
  updatePageTitle();
  if (catalogReady) loadGame();
});
window.addEventListener('hashchange', () => {
  if (location.hash.startsWith('#resource-') && publishedRoutes.has(location.pathname)) location.reload();
});
const mobileFilters = matchMedia('(max-width: 760px)');
$('filter-panel').open = !mobileFilters.matches;
mobileFilters.addEventListener('change', event => { $('filter-panel').open = !event.matches; });

const gameDialog = $('resource-game-dialog');
if (initialPath === routes.base && !location.search && !location.hash && typeof gameDialog?.showModal === 'function') {
  for (const tab of gameTabs) {
    const choice = node('button');
    choice.type = 'button';
    choice.dataset.game = tab.dataset.game;
    choice.autofocus = tab === gameTabs[0];
    const icon = node('img');
    icon.src = `/assets/images/resource-game-icons/${tab.dataset.game}.webp`;
    icon.alt = '';
    icon.width = icon.height = 48;
    choice.append(icon, node('span', tab.textContent.trim()));
    choice.onclick = () => {
      gameDialog.close();
      tab.focus({ preventScroll: true });
      chooseResourceGame(tab.dataset.game);
    };
    $('resource-game-options').append(choice);
  }
  gameDialog.showModal();
}

(async () => {
  updatePageTitle();
  setLoading(true);
  const libraryReady = loadLibrary();
  const [collections, guides] = await Promise.allSettled([json('/resources/routes.json'), json('/resources/guides/routes.json')]);
  if (collections.status === 'fulfilled') for (const pathname of collections.value) publishedRoutes.add(pathname);
  if (guides.status === 'fulfilled') publishedGuides = guides.value;
  const resourceAnchor = location.hash.startsWith('#resource-');
  const target = routes.catalogURL(state, publishedRoutes);
  if (resourceAnchor && location.pathname === routes.base && !target.startsWith(`${routes.base}?`)) {
    location.replace(target + location.hash);
    return;
  }
  saveState(true);
  await libraryReady;
  catalogReady = true;
  await loadGame();
})();
