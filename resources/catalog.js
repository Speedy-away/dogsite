'use strict';

const $ = id => document.getElementById(id);
const GAMES = {
  gta5: { name: 'GTA 5', assets: ['vehicles', 'modded', 'outfits', 'maps', 'textures', 'paintjobs', 'liveries', 'dlc', 'wallpapers', 'asi-mods', 'dotnet-mods', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing'] },
  rdr2: { name: 'RDR2', assets: ['outfits', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps'] },
  cs2: { name: 'CS2', assets: ['players', 'weapons', 'knives', 'throwables', 'bombs', 'skyboxes', 'textures'] },
  fivem: { name: 'FiveM', assets: ['vehicles', 'outfits', 'maps', 'textures', 'paintjobs', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing'] },
  redm: { name: 'RedM', assets: ['outfits', 'weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings', 'maps', 'textures', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps'] },
  l4d: { name: 'L4D', assets: ['players', 'weapons', 'maps', 'textures'] }
};
const LABELS = {
  all: 'All resources', vehicles: 'Vehicles', modded: 'Modded vehicles', outfits: 'Outfits',
  'addon-vehicles': 'Vehicles', 'addon-peds': 'Peds', 'addon-objects': 'Objects', 'addon-animations': 'Animations', 'addon-maps': 'Maps', 'addon-clothing': 'Clothing', maps: 'Maps', textures: 'Textures',
  paintjobs: 'LSC paintjobs', liveries: 'Liveries', players: 'Player models', weapons: 'Weapon models', knives: 'Knife models',
  throwables: 'Throwables', bombs: 'Bombs', skyboxes: 'Skyboxes', themes: 'Themes', configs: 'Configs',
  lua: 'Lua scripts', languages: 'Translations / Languages', misc: 'Miscellaneous',
  'asi-mods': 'ASI mods', 'dotnet-mods': '.NET mods', dlc: 'DLC packs', wallpapers: 'Wallpapers',
  'weapon-models': 'Weapon models/skins', 'sound-packs': 'Sound packs', 'graphics-packs': 'Graphics packs',
  'ui-presets': 'UI presets', 'visual-effects': 'Visual effects', scopes: 'Scopes', settings: 'Settings'
};
const MENU_CATEGORIES = ['themes', 'configs', 'lua', 'languages', 'misc'];
const PAGE_SIZE = 24;
const taxonomy = globalThis.ScoobyTaxonomy;
const menuSystem = globalThis.ScoobyMenus;
const tagCache = new WeakMap();
const searchCache = new WeakMap();
const cache = new Map();
const legacy = new Map();
const LOCAL_PREVIEW = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
let library = { items: [], downloadBaseUrl: 'https://raw.githubusercontent.com/Speedy-away/cool-repo/main/' };
let menuResources = { items: [] };
let libraryError = false;
let entries = [];
let revision = 0;
let loadRevision = 0;
let gameLoading = false;
let state = readState();
let inputTimer;

function node(tag, text, className) {
  const result = document.createElement(tag);
  if (text !== undefined && text !== null) result.textContent = String(text);
  if (className) result.className = className;
  return result;
}

function normalize(value) { return String(value || '').toLowerCase().replace(/[^a-z0-9]/g, ''); }
function menuFor(game, id) { return menuSystem ? menuSystem.menuFor(game, id) : 'scooby'; }
function menuName(id = state.menu) { return menuSystem ? menuSystem.displayName(id) : 'Scooby'; }
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
function categories(game = state.game) { return [...GAMES[game].assets, ...MENU_CATEGORIES]; }
function readState() {
  const query = new URLSearchParams(location.search);
  const game = Object.hasOwn(GAMES, query.get('game')) ? query.get('game') : 'gta5';
  const category = [...GAMES[game].assets, ...MENU_CATEGORIES].includes(query.get('category')) ? query.get('category') : 'all';
  const themeFilters = ['gta5', 'rdr2'].includes(game) && ['all', 'themes'].includes(category);
  return {
    game, category, menu: menuFor(game, query.get('menu')), q: query.get('q') || '', model: query.get('model') || '',
    ui: themeFilters ? query.get('ui') || '' : '', style: themeFilters ? query.get('style') || '' : '',
    sort: ['name', 'attachments'].includes(query.get('sort')) ? query.get('sort') : '',
    page: Math.max(1, Number.parseInt(query.get('page'), 10) || 1)
  };
}

function saveState(replace = false) {
  const url = new URL(location.href);
  url.search = '';
  url.searchParams.set('game', state.game);
  if (state.game === 'gta5' && state.menu !== 'scooby') url.searchParams.set('menu', state.menu);
  if (state.category !== 'all') url.searchParams.set('category', state.category);
  for (const key of ['q', 'model', 'ui', 'style', 'sort']) if (state[key]) url.searchParams.set(key, state[key]);
  if (state.page > 1) url.searchParams.set('page', state.page);
  if (url.href !== location.href) history[replace ? 'replaceState' : 'pushState'](null, '', url);
}

async function json(url) {
  if (!cache.has(url)) cache.set(url, fetch(url, { signal: AbortSignal.timeout(20000) }).then(response => {
    if (!response.ok) throw new Error('Collection unavailable');
    return response.json();
  }).catch(error => { cache.delete(url); throw error; }));
  return cache.get(url);
}

function safeURL(value, base = location.href) {
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

function previewAllowed(entry) {
  return entry.previewVerified !== false && (entry.category !== 'themes' || entry.previewVerified === true);
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
  const value = entry?.guide;
  if (/^\/(?:community|resources)\/guides\//.test(value || '')) {
    const url = new URL(value.replace(/^\/community\//, '/resources/'), location.href);
    if (state.game === 'gta5') url.searchParams.set('menu', state.menu);
    return url.pathname + url.search + url.hash;
  }
  const query = new URLSearchParams({ game: entry?.game || state.game, category: entry?.category || state.category });
  if (state.game === 'gta5') query.set('menu', state.menu);
  return `/resources/guides/?${query}`;
}

function link(text, href, external = false) {
  const result = node('a', text);
  result.href = href;
  if (external) { result.target = '_blank'; result.rel = 'noopener noreferrer'; }
  return result;
}

function image(src, name) {
  const result = node('img');
  result.src = src;
  result.alt = name;
  result.loading = 'lazy';
  result.decoding = 'async';
  result.onerror = () => result.replaceWith(node('span', 'Preview unavailable'));
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
  const [base, supplemental] = await Promise.allSettled([json('/community/data/library.json'), json('/community/data/menu-resources.json')]);
  libraryError = false;
  if (base.status === 'fulfilled' && Array.isArray(base.value.items)) library = base.value;
  else libraryError = true;
  if (supplemental.status === 'fulfilled' && Array.isArray(supplemental.value.items)) menuResources = supplemental.value;
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
  for (const item of menuResources.items) {
    const id = item.id || `${item.game}:${item.category}:${item.name}:${item.sourceMenu || item.menu || ''}`;
    merged.set(id, { ...merged.get(id), ...item });
  }
  return [...merged.values()].filter(item => item.game === state.game && categories().includes(item.category) && !excludedRedMResource(item) &&
    (pendingDownload(item) || item.status === 'in-menu' || (item.game === 'cs2' && item.status === 'workshop') ||
      (Array.isArray(item.files) && item.files.some(file => downloadURL(file)))))
    .map(item => ({ ...item, tags: Array.isArray(item.tags) ? item.tags : [] }));
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
  return category === 'all' || entry.category === category || entry.categories?.includes(category) || (category === 'modded' && entry.category === 'vehicles' && entry.attachments > 0);
}

function categoryButton(category) {
  const button = node('a', null, 'category-choice');
  button.setAttribute('role', 'button');
  button.dataset.category = category;
  button.setAttribute('aria-pressed', String(state.category === category));
  const count = entries.filter(entry => inCategory(entry, category)).length;
  button.href = state.menu !== 'scooby' ? `/resources/?${new URLSearchParams({ game: state.game, menu: state.menu, ...(category !== 'all' ? { category } : {}) })}` : category === 'all' ? `/resources/${state.game}/` : count > 0 ? `/resources/${state.game}/${category}/` : `/resources/?${new URLSearchParams({ game: state.game, category })}`;
  button.append(node('span', LABELS[category]), node('small', count.toLocaleString()));
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

function addMetadataOptions() {
  for (const id of ['style']) {
    for (const entry of entries) for (const value of [].concat(entry[id] || [])) {
      const normalized = normalize(value);
      if (normalized && ![...$(id).options].some(option => option.value === normalized)) $(id).add(new Option(String(value), normalized));
    }
  }
}

function updateControls() {
  document.querySelectorAll('[data-game]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.game === state.game)));
  $('collection-title').textContent = state.game === 'gta5' ? `${menuName()}'s GTA 5 resources` : `${GAMES[state.game].name} resources`;
  $('menu-field').hidden = state.game !== 'gta5';
  $('menu').replaceChildren();
  for (const menu of menuSystem?.MENUS || [{ id: 'scooby', name: 'Scooby' }]) $('menu').add(new Option(menu.name + (menu.deferred ? ' · Coming soon' : ''), menu.id));
  $('menu').value = state.menu;
  const source = state.game === 'gta5' ? menuSystem?.MENUS.find(menu => menu.id === state.menu)?.source : undefined;
  const sourceLink = $('menu-source');
  sourceLink.hidden = !source;
  sourceLink.textContent = source?.label || '';
  if (source) sourceLink.href = source.url;
  else sourceLink.removeAttribute('href');
  $('context-guide').href = guideURL();
  $('search').value = state.q;
  $('search').placeholder = {
    gta5: 'Search outfits, vehicles or files…', rdr2: 'Search outfits or files…',
    cs2: 'Search models, skyboxes or files…', fivem: 'Search vehicles, maps or files…',
    redm: 'Search outfits, peds or files…', l4d: 'Search models, maps or files…'
  }[state.game];
  $('categories').replaceChildren(categoryButton('all'));
  const assets = GAMES[state.game].assets;
  for (const [label, list] of [[`${menuName()}’s resources`, assets.filter(category => !category.startsWith('addon-'))], ['Addons', assets.filter(category => category.startsWith('addon-'))], [`${menuName()} files`, MENU_CATEGORIES]]) {
    if (!list.length) continue;
    const group = node('div', null, 'category-group');
    group.append(node('p', label, 'category-group-label'));
    for (const category of list) group.append(categoryButton(category));
    $('categories').append(group);
  }
  const models = new Map();
  for (const entry of selectedEntries()) {
    if (entry.model) models.set(String(entry.model), String(entry.modelLabel || entry.model));
  }
  $('model').replaceChildren(new Option('All models', ''));
  [...models].sort((a, b) => a[1].localeCompare(b[1])).forEach(([value, label]) => $('model').add(new Option(label, value)));
  $('model-field').hidden = !models.size;
  addMetadataOptions();
  for (const id of ['model', 'ui', 'style', 'sort']) setSelect(id, state[id]);
  const themeFilters = ['gta5', 'rdr2'].includes(state.game) && ['all', 'themes'].includes(state.category);
  $('ui-field').hidden = !themeFilters;
  $('style-field').hidden = !themeFilters;
  if (!themeFilters) { state.ui = ''; state.style = ''; $('ui').value = ''; $('style').value = ''; }
  $('filters').hidden = !models.size && !themeFilters;
  const attachments = state.game === 'gta5' && ['all', 'vehicles', 'modded'].includes(state.category);
  $('sort').querySelector('[value=attachments]').disabled = !attachments;
  if (!attachments && state.sort === 'attachments') { state.sort = ''; $('sort').value = ''; }
  $('install-note').textContent = state.game === 'gta5' && state.menu !== 'scooby'
    ? `Keep the complete download together and follow its installation guide. Choose files made for ${menuName()} and your game version.`
    : ['gta5', 'rdr2'].includes(state.game)
    ? 'Keep the complete download together and follow its installation guide. A theme’s appearance can resemble another menu while using Scooby’s own format. Choose a theme that supports your ClickUI or ListUI interface.'
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
    entries = [...original, ...libraryEntries()].filter(supportsMenu);
    setLoading(false);
    updateControls();
    await render();
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

function comingSoonButton() {
  const button = node('button', 'Download — Coming soon', 'download-pending');
  button.type = 'button';
  button.disabled = true;
  button.setAttribute('aria-label', 'Download — Coming soon');
  return button;
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
    const url = `/resources/?${new URLSearchParams({ game: state.game, ...(state.menu !== 'scooby' ? { menu: state.menu } : {}), ...(state.category !== 'all' ? { category: state.category } : {}), q: tag })}`;
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

function showDetails(entry, files) {
  $('preview-title').textContent = visibleText(entry, entry.name);
  const preview = previewURL(entry);
  $('pictures').replaceChildren();
  if (preview) {
    const figure = node('figure', null, 'preview-figure');
    figure.append(image(preview, entry.name));
    if (entry.previewCaption) figure.append(node('figcaption', entry.previewCaption, 'preview-caption'));
    $('pictures').append(figure);
  }
  const details = $('preview-details');
  details.replaceChildren();
  if (entry.description) details.append(node('p', visibleText(entry, entry.description)));
  if (entry.compatibility) details.append(node('p', visibleText(entry, entry.compatibility)));
  if (entry.edition) details.append(node('p', `Edition: ${visibleText(entry, entry.edition)}`));
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
  if (entry.uiStyle || entry.style) details.append(node('p', [entry.uiStyle, entry.style && `Appearance: ${entry.style}`].filter(Boolean).join(' · ')));
  if (entry.author || entry.credits) details.append(node('p', `Credits: ${visibleText(entry, entry.credits || entry.author)}`));
  if (entry.license) details.append(node('p', `License: ${visibleText(entry, entry.license)}`));
  if (pendingDownload(entry)) {
    details.append(comingSoonButton());
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
  if (entry.category === 'lua') details.append(changelogButton(entry));
  details.append(link('Installation guide ↗', guideURL(entry)));
  if (!$('preview').open) $('preview').showModal();
}

async function card(entry) {
  const files = pendingDownload(entry) ? [] : await resolveFiles(entry);
  const article = node('article', null, 'card');
  article.dataset.category = entry.category;
  const shot = node('button', null, 'shot');
  shot.type = 'button';
  shot.setAttribute('aria-label', `View ${entry.name}`);
  const preview = previewURL(entry);
  if (entry.category === 'themes' && preview) article.className += ' has-verified-preview';
  if (preview) shot.append(image(preview, entry.name));
  else {
    const art = node('div', null, 'file-art');
    const extension = files[0]?.name?.split('.').pop();
    art.append(node('strong', extension && extension.length < 8 ? extension.toUpperCase() : GAMES[entry.game].name), node('span', LABELS[entry.category] || 'Community file'));
    shot.append(art);
  }
  shot.onclick = () => showDetails(entry, files);
  const info = node('div', null, 'info');
  const pendingExtension = String(entry.sourceFilename || '').match(/\.(lua|pluto)$/i)?.[1]?.toLowerCase();
  const knownExtension = pendingDownload(entry) && pendingExtension === normalize(entry.formatExtension) ? pendingExtension : '';
  const title = resourceTitle(visibleText(entry, entry.name), files, knownExtension);
  title.title = title.textContent;
  info.append(title);
  info.append(node('p', [entry.modelLabel || LABELS[entry.category], entry.attachments > 0 && `${entry.attachments} attachments`, files.length === 1 && prettySize(files[0].size), entry.status === 'in-menu' && 'In-menu', entry.status === 'workshop' && 'Workshop'].filter(Boolean).join(' · ')));
  const sourceMenu = menuSystem?.canonical(entry.sourceMenu);
  if (['cherax', 'stand', 'xforce'].includes(sourceMenu) && typeof menuSystem?.compatibleWith === 'function' && !menuSystem.compatibleWith(entry, state.menu)) {
    info.append(node('p', visibleText(entry, entry.requirementLabel || `Requires ${menuName(sourceMenu)} format`), 'compatibility-note'));
  }
  if (entry.description) info.append(node('p', visibleText(entry, entry.description), 'description'));
  if (entry.uiStyle || entry.style) info.append(node('p', [entry.uiStyle, entry.style && `${entry.style} style`].filter(Boolean).join(' · '), 'meta'));
  const actions = node('div', null, 'card-actions');
  if (pendingDownload(entry)) actions.append(comingSoonButton());
  else if (!files.length) {
    const details = node('button', 'Details');
    details.type = 'button';
    details.className = 'theme-details';
    details.onclick = () => showDetails(entry, files);
    actions.append(details);
  }
  if (files.length === 1) {
    actions.append(downloadButton(files[0], info));
  } else if (files.length > 1) {
    const details = node('button', 'Download ↓');
    details.type = 'button';
    details.onclick = () => showDetails(entry, files);
    actions.append(details);
  }
  if (entry.category === 'lua') actions.append(changelogButton(entry));
  info.append(actions);
  if (files.length || entry.status === 'in-menu' || pendingDownload(entry)) {
    const guide = link('Install guide ↗', guideURL(entry));
    guide.className = 'guide-link';
    info.append(guide);
  }
  if (entry.category !== 'themes' || preview) article.append(shot);
  article.append(info);
  return article;
}

function matchesFilters(entry) {
  const query = normalizeSearch(state.q);
  if (state.model && String(entry.model) !== state.model) return false;
  if (state.ui && ![].concat(entry.uiStyle || []).some(ui => normalize(ui) === normalize(state.ui))) return false;
  if (state.style && ![].concat(entry.style || []).some(style => normalize(style) === normalize(state.style))) return false;
  if (!query) return true;
  const text = resourceSearchText(entry);
  return query.split(/\s+/).every(word => text.includes(word));
}

function emptyState() {
  const empty = node('div', null, 'empty');
  const activeFilters = state.q || state.model || state.ui || state.style;
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
  matches.sort(state.sort === 'name'
    ? (a, b) => a.name.localeCompare(b.name)
    : state.sort === 'attachments'
      ? (a, b) => (b.attachments || 0) - (a.attachments || 0)
      : (a, b) => Number(Boolean(b.preview) && previewAllowed(b)) - Number(Boolean(a.preview) && previewAllowed(a)));
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
  state = { ...state, q: '', model: '', ui: '', style: '', sort: '', page: 1 };
  updateControls();
  saveState();
  render();
}

document.querySelectorAll('[data-game]').forEach(button => {
  button.onclick = event => {
    if (button.tagName === 'A' && (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0)) return;
    event.preventDefault();
    if (button.dataset.game === state.game) return;
    clearTimeout(inputTimer);
    state = { game: button.dataset.game, category: 'all', menu: menuFor(button.dataset.game, 'scooby'), q: '', model: '', ui: '', style: '', sort: '', page: 1 };
    saveState();
    loadGame();
  };
  if (button.tagName === 'A') button.onkeydown = event => { if (event.key === ' ') { event.preventDefault(); button.click(); } };
});
$('menu').onchange = () => {
  clearTimeout(inputTimer);
  state = { ...state, menu: menuFor(state.game, $('menu').value), q: '', model: '', ui: '', style: '', page: 1 };
  saveState();
  loadGame();
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
window.addEventListener('popstate', () => { clearTimeout(inputTimer); state = readState(); loadGame(); });
const mobileFilters = matchMedia('(max-width: 760px)');
$('filter-panel').open = !mobileFilters.matches;
mobileFilters.addEventListener('change', event => { $('filter-panel').open = !event.matches; });

(async () => { setLoading(true); await loadLibrary(); await loadGame(); })();
