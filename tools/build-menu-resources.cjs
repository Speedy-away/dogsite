'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const menus = require('../resources/menus.js');
const { buildMarketplaceItems } = require('./community-mod-marketplace.cjs');
const { applyCheraxCatalog } = require('./cherax-catalog.cjs');
const { recordResourceAdditions } = require('./resource-additions.cjs');
const ROOT = path.resolve(__dirname, '..');
const SOURCES = path.join(ROOT, 'project/community-menu-sources');
const targetIndex = process.argv.indexOf('--target');
const target = path.resolve(targetIndex >= 0 ? process.argv[targetIndex + 1] : path.join(ROOT, '../cool-repo'));
const publish = process.argv.includes('--publish-assets');
const l4dDownload = /^\/assets\/downloads\/l4d\/[\w.-]+\.(?:cfg|zip)$/i;
const l4dPreview = /^\/assets\/images\/resource-previews\/l4d\/[\w.-]+\.(?:jpe?g|png|webp)$/i;
const standPreview = /^\/assets\/images\/resource-previews\/stand\/[\w.-]+\.(?:jpe?g|png|webp)$/i;
const standDownload = /^\/assets\/downloads\/stand\/[\w.-]+\.zip$/i;
const yimDownload = /^\/assets\/downloads\/yim\/[\w.-]+\.(?:zip|rar)$/i;
const yimPreview = /^\/assets\/images\/resource-previews\/yim\/[\w.-]+\.(?:png|gif)$/i;
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const base = read(path.join(ROOT, 'community/data/library.json'));
const baseItems = new Map(base.items.map(item => [item.id, item]));
const GAMES = new Set(['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d']);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const planned = new Map();
const standReview = path.join(SOURCES, 'stand-discord-reviewed.json');
const oldSharesMatches = new Set((fs.existsSync(standReview) ? read(standReview).supplementMatches || [] : []).map(match => match.sha256));
const imageChecksFile = path.join(SOURCES, 'menu-image-checks.json');
const imageChecks = fs.existsSync(imageChecksFile) ? read(imageChecksFile) : {};
const output = { version: 1, items: [], libraryOverrides: [], legacyOverrides: [], legacyGroups: [], coverage: [],
  downloadBaseUrl: base.downloadBaseUrl, sourceCatalog: 'menu-resources' };
const overrides = new Map(), additions = new Map(), legacy = new Map();
const localLuaHashes = new Map();
const fields = ['name', 'category', 'categories', 'description', 'sourceMenu', 'supportedMenus', 'listedMenus', 'sourceFilename', 'formatExtension', 'sourceFormat', 'format', 'keywords',
  'author', 'credits', 'license', 'sourceUrl', 'installUrl', 'sourceChannel', 'collection', 'collectionStatus', 'archival', 'version', 'versionBasis', 'sourceVersion', 'versionStatus', 'updatedAt',
  'compatibility', 'requirementLabel', 'requirements', 'edition', 'editionSupport', 'editionSource', 'tags', 'changelog', 'changelogStatus', 'previewKind', 'previewCaption', 'uiStyle', 'style', 'resourceType', 'themePath', 'model', 'modelLabel'];
const canonicalList = values => [...new Set((values || []).map(menus.canonical).filter(Boolean))];
const aliases = { dlcs: 'dlc', translations: 'languages', wallpaper: 'wallpapers', 'custom-header': 'wallpapers', 'lua-scripts': 'lua' };
const slug = value => String(value).toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-|-$/g, '');
function asset(local, menu, family, game = 'gta5') {
  const file = path.resolve(ROOT, local);
  if (!file.startsWith(SOURCES + path.sep) || !fs.statSync(file).isFile()) throw Error('Invalid staged menu asset');
  if (!fs.realpathSync(file).startsWith(fs.realpathSync(SOURCES) + path.sep)) throw Error('Staged resource asset escaped its source directory');
  const data = fs.readFileSync(file), digest = hash(data);
  const relative = `${family}/${game}/menus/${menu}/${digest.slice(0, 20)}${path.extname(file).toLowerCase()}`;
  planned.set(relative, data);
  return relative;
}
function clean(entry, origin) {
  const result = Object.fromEntries(fields.filter(key => entry[key] !== undefined && entry[key] !== null).map(key => [key, entry[key]]));
  result.sourceMenu = menus.canonical(entry.sourceMenu || origin) || 'scooby';
  result.game = GAMES.has(entry.game) ? entry.game : 'gta5';
  if (typeof result.name === 'string') result.name = result.name.trim();
  result.category = aliases[entry.category] || entry.category;
  if (result.category === 'mod-menus' && ['free', 'paid'].includes(entry.access)) result.access = entry.access;
  if (!result.credits && (entry.creator || entry.author)) result.credits = entry.creator || entry.author;
  result.supportedMenus = canonicalList(entry.supportedMenus?.length ? entry.supportedMenus : [result.sourceMenu]);
  if (menus.isCheraxTheme(result)) {
    result.supportedMenus = menus.menuIds(result);
    result.uiStyle = menus.themeInterface(result);
  }
  if (result.game !== 'gta5') result.supportedMenus = ['scooby'];
  result.listedMenus = menus.listingMenuIds(result);
  result.tags = [...new Set([...(entry.tags || []), menus.menuName(result.sourceMenu), ...(entry.archival || entry.collectionStatus === 'archival' || entry.collection === 'old' ? ['old shares', 'archival'] : [])])];
  if (entry.oldShares === true || origin === 'stand-discord-reviewed' &&
      (entry.archival || ['old', 'archival'].includes(entry.collection) || entry.collectionStatus === 'archival' ||
       /^(?:Old Shares\b|legacy-lua-scripts$)/i.test(entry.sourceChannel || ''))) result.oldShares = true;
  result.menuResource = true;
  result.sourceCatalog = 'menu-resources';
  if (entry.previewVerified === false) result.previewVerified = false;
  result.changelog = (Array.isArray(entry.changelog) ? entry.changelog : []).map(release => ({
    ...(release.version ? { version: release.version } : {}), ...(release.date ? { date: release.date } : {}),
    ...(release.dateBasis ? { dateBasis: release.dateBasis } : {}),
    changes: (release.changes || []).filter(value => typeof value === 'string').map(value => value.replace(/https?:\/\/(?:\w+\.)?discord(?:app)?\.(?:com|gg)\S*/gi, '').trim()).filter(Boolean)
  })).filter(release => release.changes.length);
  if (entry.previewVerified === true && typeof entry.preview === 'string') {
    const checked = imageChecks[entry.preview];
    if (checked?.verified && checked.localPath) result.preview = asset(checked.localPath, result.sourceMenu, 'previews', result.game);
    else if (checked && !checked.verified) result.previewVerified = false;
    else if (entry.preview.startsWith('project/community-menu-sources/')) result.preview = asset(entry.preview, result.sourceMenu, 'previews', result.game);
    else if (result.game === 'l4d' && l4dPreview.test(entry.preview) && fs.existsSync(path.join(ROOT, entry.preview))) result.preview = entry.preview;
    else if (result.game === 'gta5' && result.sourceMenu === 'stand' && standPreview.test(entry.preview) &&
      fs.existsSync(path.join(ROOT, entry.preview.slice(1)))) result.preview = entry.preview;
    else if (origin === 'yim' && yimPreview.test(entry.preview) && fs.existsSync(path.join(ROOT, entry.preview))) {
      result.preview = entry.preview;
      const images = (entry.images || []).filter(url => yimPreview.test(url) && fs.existsSync(path.join(ROOT, url)));
      if (images.length > 1) {
        result.imageBaseUrl = '/assets/images/resource-previews/yim/';
        result.imagePaths = images.map(url => path.posix.basename(url));
      }
    }
    else if (/^https:\/\//.test(entry.preview) || entry.preview.startsWith('previews/') || entry.preview.startsWith('/community/media/')) result.preview = entry.preview;
    if (result.preview) {
      const thumbnail = result.preview.match(/^previews\/gta5\/menus\/xforce\/([a-f0-9]{20})\.(?:png|jpe?g|gif|webp)$/i);
      if (thumbnail) {
        for (const extension of ['jpg', 'webp']) {
          const local = '/assets/images/resource-previews/xforce/' + thumbnail[1] + '.' + extension;
          if (!fs.existsSync(path.join(ROOT, local.slice(1)))) continue;
          result.preview = local;
          break;
        }
      }
      result.previewVerified = true;
    }
  } else if (entry.previewVerified !== false && entry.source === 'GTA5-Mods' &&
    ['addon-peds', 'addon-vehicles'].includes(entry.category) && /^https:\/\/img\.gta5-mods\.com\//i.test(entry.preview || '')) {
    result.preview = entry.preview;
  }
  const reviewedRedmLua = result.game === 'redm' && origin === 'redm-submitted' && entry.reviewedLua === true;
  const standLua = menus.isStandLua(result);
  const reviewedStandLua = standLua && origin === 'stand-discord-reviewed' && entry.reviewedLua === true;
  const standAuthorSource = standLua && ['stand', 'stand-discord-reviewed'].includes(origin) &&
    entry.verifiedAuthorSource === true && /^https:\/\/github\.com\/[^/]+\/[^/]+/i.test(result.sourceUrl || '');
  if (standAuthorSource && !reviewedStandLua) {
    result.status = 'author-hosted';
    result.downloadStatus = 'author-hosted';
    result.files = [];
  } else if (origin === 'yim' && result.game === 'gta5') {
    result.files = (entry.files || []).filter(file => yimDownload.test(file.url) && fs.existsSync(path.join(ROOT, file.url))).map(file => {
      const bytes = fs.readFileSync(path.join(ROOT, file.url));
      return { ...file, size: bytes.length, sha256: hash(bytes) };
    });
    result.downloadStatus = result.files.length ? 'available' : 'pending';
    result.status = result.files.length ? 'download' : 'pending';
  } else if (result.category === 'lua' && !reviewedRedmLua && !reviewedStandLua) {
    result.downloadStatus = 'pending'; result.status = 'pending'; result.files = [];
    if (standLua) result.downloadLabel = 'Download unavailable';
    result.sourceFilename = result.sourceFilename || (typeof entry.source?.path === 'string' ? path.posix.basename(entry.source.path) : typeof entry.member === 'string' ? path.posix.basename(entry.member) : undefined);
    const extension = result.sourceFilename?.match(/\.(lua|pluto)$/i)?.[1]?.toLowerCase();
    if (extension) result.formatExtension = extension;
    if (/discord(?:app)?\.(?:gg|com)/i.test(result.sourceUrl || '')) delete result.sourceUrl;
  } else if (Array.isArray(entry.files)) {
    result.files = entry.files.map(file => {
      if (reviewedStandLua) {
        if (!/^downloads\/gta5\/menus\/stand\/[a-f0-9]{20}\.(?:lua|pluto|zip)$/i.test(file.path || '') ||
            !fs.existsSync(path.join(target, file.path))) return null;
        const bytes = fs.readFileSync(path.join(target, file.path));
        if (bytes.length !== file.size || hash(bytes) !== file.sha256) throw Error('Stand Lua archive checksum mismatch: ' + file.path);
        return { ...file };
      }
      if (file.url && /^https:\/\//.test(file.url)) return { ...file };
      if (result.game === 'gta5' && result.sourceMenu === 'stand' && standDownload.test(file.url || '')) {
        const bytes = fs.readFileSync(path.join(ROOT, file.url.slice(1)));
        return { ...file, size: bytes.length, sha256: hash(bytes) };
      }
      if (result.game === 'l4d' && l4dDownload.test(file.url || '')) {
        const bytes = fs.readFileSync(path.join(ROOT, file.url));
        return { url: file.url, name: path.posix.basename(file.url), size: bytes.length, sha256: hash(bytes) };
      }
      if (file.path && !path.isAbsolute(file.path) && !file.path.includes('\\') && !file.path.split('/').includes('..') && fs.existsSync(path.join(target, file.path))) return { ...file };
      if (file.localPath?.startsWith('project/community-menu-sources/')) {
        const relative = asset(file.localPath, result.sourceMenu, 'downloads', result.game);
        const data = planned.get(relative);
        return { path: relative, name: file.name || path.basename(file.localPath), size: data.length, sha256: hash(data) };
      }
      return null;
    }).filter(Boolean);
    result.status = result.files.length ? 'download' : entry.status;
    result.downloadStatus = result.files.length ? 'available' : entry.downloadStatus;
    if (reviewedStandLua && !result.files.length) {
      result.status = 'pending';
      result.downloadStatus = 'pending';
      result.downloadLabel = 'Download unavailable';
    }
  }
  if (result.game === 'gta5' && result.files?.some(file => oldSharesMatches.has(file.sha256)) && menus.supports(result, 'stand')) result.oldShares = true;
  if (result.game === 'redm') {
    const cleanLabel = value => String(value || '').replace(/\s*\(RedM\s*Hub\)\s*by\s+Dadash/ig, '').trim();
    const videoURL = /https?:\/\/(?:www\.)?(?:youtu\.be|youtube\.com|vimeo\.com)\S*/gi;
    result.name = cleanLabel(result.name);
    result.files = (result.files || []).filter(file => !/\.(?:mp4|webm|mkv|mov)(?:[?#]|$)/i.test(file.name || file.url || '')).map(file => ({ ...file, name: cleanLabel(file.name) }));
    if (result.sourceUrl && videoURL.test(result.sourceUrl)) delete result.sourceUrl;
    result.description = String(result.description || '').replace(videoURL, '').trim();
    result.requirements = (result.requirements || []).map(value => String(value).replace(videoURL, '').trim()).filter(Boolean);
  }
  result.guide = `/resources/guides/?${new URLSearchParams({ game: result.game, ...(result.game === 'gta5' ? { menu: result.sourceMenu } : {}), category: result.category })}`;
  if (origin === 'cs2-hammer-materials') result.guide += '#cs2-hammer-textures';
  return result;
}
function add(entry, origin) {
  if (!entry?.id || !entry.category) return;
  if (entry.game === 'redm' && /(?:pm[ _-]*bypass|fast(?:er)?[ _-]*scope)/i.test([entry.id, entry.name, entry.sourceChannel].join(' '))) return;
  const normalized = clean(entry, origin);
  if (baseItems.has(entry.id)) overrides.set(entry.id, { ...overrides.get(entry.id), ...normalized, id: entry.id });
  else if ((normalized.category === 'lua' && (normalized.downloadStatus === 'pending' ||
    menus.isStandLua(normalized) && normalized.status === 'author-hosted')) || normalized.files?.length ||
    entry.status === 'in-menu' || (normalized.category === 'mod-menus' && normalized.status === 'preview-only') ||
    ((['fivem-graphics', 'l4d', 'cs2-gamebanana-skyboxes', 'cs2-hdri-skies', 'cs2-hammer-materials'].includes(origin) ||
      (origin === 'fivem-server-recipes' && normalized.game === 'fivem' && normalized.category === 'server-dumps') ||
      (origin === 'fivem-lua-menus' && normalized.game === 'fivem' && normalized.category === 'mod-menus') ||
      (origin === 'fivem-sound-packs' && normalized.game === 'fivem' && normalized.category === 'sound-packs') ||
      (origin === 'fivem-addon-maps' && normalized.game === 'fivem' && normalized.category === 'addon-maps') ||
      (origin === 'fivem-addon-vehicles' && normalized.game === 'fivem' && normalized.category === 'addon-vehicles') ||
      (origin === 'fivem-addon-clothing' && normalized.game === 'fivem' && normalized.category === 'addon-clothing') ||
      (origin === 'fivem-addon-objects' && normalized.game === 'fivem' && normalized.category === 'addon-objects') ||
      (origin === 'fivem-addon-animations' && normalized.game === 'fivem' && normalized.category === 'addon-animations') ||
      (origin === 'fivem-addon-peds' && normalized.game === 'fivem' && normalized.category === 'addon-peds') ||
      (origin === 'redm-public-releases' && normalized.game === 'redm' && normalized.category === 'graphics-packs') ||
      (origin === 'gta5-addon-packs' && normalized.game === 'gta5' &&
        (normalized.category === 'addon-packs' || (normalized.sourceMenu === 'stand' && normalized.category === 'misc'))) ||
      (origin === 'stand-discord-reviewed' && normalized.category === 'asi-mods'))
      && normalized.status === 'author-hosted' && /^https:\/\//.test(normalized.sourceUrl || ''))) {
    additions.set(entry.id, { ...additions.get(entry.id), ...normalized, id: entry.id });
  }
}
function luaIdentity(entry) {
  if (additions.has(entry.id)) return entry.id;
  if (entry.sourceFilename) {
    const filename = entry.sourceFilename.toLowerCase();
    const prior = [...additions.values()].find(item => item.category === 'lua' && item.sourceMenu === 'cherax' && item.sourceFilename?.toLowerCase() === filename);
    if (prior) return prior.id;
  }
  const evidence = [...(entry.provenance?.localPaths || []), ...(entry.sourceEvidence || [])].filter(item => item.sha256);
  const preferred = evidence.find(item => path.posix.basename(String(item.path || item.sourcePath || '').replace(/\\/g, '/')).toLowerCase() === String(entry.sourceFilename || '').toLowerCase());
  return preferred && localLuaHashes.get(preferred.sha256) || entry.id;
}
function collectionOverride(prior, entry) {
  const original = prior || {};
  const originalMenus = prior && Object.keys(prior).length ? menus.menuIds({ game: 'gta5', ...original }) : [];
  return { ...original, ...entry,
    sourceMenu: entry.sourceMenu || original.sourceMenu || menus.canonical(original.menu) || 'scooby',
    collection: original.collection || entry.collection,
    tags: [...new Set([...(original.tags || []), ...(entry.tags || [])])],
    supportedMenus: canonicalList([...originalMenus, ...(entry.supportedMenus || [])]),
    credits: [...new Set([original.credits, entry.credits].filter(Boolean))].join(' · '),
    changelog: entry.changelog?.length ? entry.changelog : original.changelog || []
  };
}
function importManifest(menu, defaultGame = 'gta5') {
  const file = path.join(SOURCES, `${menu}.json`);
  if (!fs.existsSync(file)) return;
  const source = read(file);
  for (const entry of source.libraryOverrides || []) {
    const prior = { ...baseItems.get(entry.id), ...overrides.get(entry.id) };
    if (menu === 'cs2-panorama-imports') {
      if (prior.game !== 'cs2' || prior.category !== 'textures') continue;
      // Keep the original download identity when changing its catalog placement.
      delete prior.files;
    }
    add(menu === 'biggerscript-public' ? collectionOverride(prior, entry) : { ...prior, ...entry }, menu);
  }
  for (const original of source.items || []) {
    let entry = { game: defaultGame, ...original };
    if (menu === 'cherax') {
      if (entry.category === 'themes' && entry.id.startsWith('gta5-modverse-themes-')) entry.id = entry.id.replace('gta5-modverse-themes-', 'menu-cherax-theme-');
      if (entry.category === 'lua' && entry.sourceFilename) {
        entry.id = luaIdentity(entry);
      }
    }
    add(entry, menu);
  }
  for (const entry of source.legacyOverrides || []) {
    if (!['vehicles', 'outfits'].includes(entry.family) || !Number.isSafeInteger(entry.index) || entry.index < 0) continue;
    const prior = legacy.get(`${entry.family}:${entry.index}`);
    const combined = menu === 'biggerscript-public' ? collectionOverride(prior, entry) : entry;
    const normalized = clean({ category: entry.family, ...combined }, menu);
    delete normalized.files; delete normalized.status; delete normalized.downloadStatus;
    legacy.set(`${entry.family}:${entry.index}`, { ...normalized, family: entry.family, index: entry.index });
  }
  output.coverage.push({ menu, source: `project/community-menu-sources/${menu}.json`, summary: source.summary || {}, coverage: source.coverage || [], completeness: source.completeness || 'Source snapshot only' });
}
for (const menu of ['stand-submitted', 'stand', 'stand-discord-reviewed', 'xforce', 'yim', 'inbox', 'biggerscript-public', 'gta5-addon-packs']) importManifest(menu);
importManifest('redm', 'redm');
importManifest('redm-submitted', 'redm');
importManifest('redm-public-releases', 'redm');
importManifest('fivem-graphics', 'fivem');
importManifest('fivem-server-recipes', 'fivem');
importManifest('fivem-lua-menus', 'fivem');
importManifest('fivem-sound-packs', 'fivem');
importManifest('fivem-addon-maps', 'fivem');
importManifest('fivem-addon-vehicles', 'fivem');
importManifest('fivem-addon-clothing', 'fivem');
importManifest('fivem-addon-objects', 'fivem');
importManifest('fivem-addon-animations', 'fivem');
importManifest('fivem-addon-peds', 'fivem');
for (const manifest of ['cs2-gamebanana-skyboxes', 'cs2-hdri-skies', 'cs2-hammer-materials', 'cs2-panorama-imports']) importManifest(manifest, 'cs2');
for (const manifest of ['l4d', 'l4d-originals', 'l4d-configs']) importManifest(manifest, 'l4d');
// Relabel existing Cherax marketplace data in place, preserving file identities.
for (const item of base.items.filter(item => item.source === 'ModVerse public catalog')) {
  const category = item.category === 'misc' ? 'dlc' : item.category;
  add({ ...item, category, sourceMenu: 'cherax', supportedMenus: ['scooby', 'nenyoo', 'cherax'] }, 'cherax');
}
// Fresh public source snapshots can add/update resources without rebuilding
// unrelated native game assets. Existing IDs remain stable.
for (const item of buildMarketplaceItems().items) {
  const cherax = item.source === 'ModVerse public catalog';
  add({ ...item, ...(cherax ? { category: item.category === 'misc' ? 'dlc' : item.category, sourceMenu: 'cherax', supportedMenus: ['scooby', 'nenyoo', 'cherax'] } : { supportedMenus: menus.menuIds(item) }) }, cherax ? 'cherax' : 'scooby');
}
const auditFile = path.join(SOURCES, 'cherax-public-audit.json');
const checksFile = path.join(SOURCES, 'cherax-network-checks.json');
if (fs.existsSync(auditFile) && fs.existsSync(checksFile)) {
  const audit = read(auditFile), checks = new Map(read(checksFile).entries.map(entry => [entry.id, entry]));
  for (const item of audit.items.filter(item => item.category === 'themes')) {
    const verified = checks.get(item.id), files = verified?.files.filter(file => file.verified).map(file => ({ url: file.url, name: file.name, size: file.size, downloadMethod: 'direct' }));
    if (!files?.length) continue;
    const preview = verified.preview;
    add({ ...item, id: `menu-cherax-theme-${item.id}`, files, description: 'Cherax ClickGUI theme package. Keep its settings and supplied artwork together.',
      requirementLabel: 'Cherax ClickGUI format', compatibility: 'Requires a loader for the original Cherax ClickGUI package. Compatibility depends on the installed menu build.',
      requirements: ['Cherax ClickGUI theme loader or a compatible importer in the installed menu build', 'Preserve the complete package and supplied artwork'],
      credits: item.creator === 'Original developer unverified' ? item.sharedBy : item.creator,
      sourceUrl: item.sourceCatalogUrl, preview: preview?.localPath, previewVerified: Boolean(preview),
      previewCaption: preview?.kind === 'source_theme_artwork' ? 'Original theme artwork' : 'Original Cherax screenshot'
    }, 'cherax');
  }
  output.coverage.push({ menu: 'cherax', source: 'Pinned ModVerse public catalog', themesVerified: [...checks.values()].filter(entry => entry.files.some(file => file.verified)).length,
    previewsVerified: [...checks.values()].filter(entry => entry.preview).length, discordHistoryComplete: false, gaps: audit.gaps });
}
const luaRoot = 'C:/Users/whatw/Documents/GitHub/cherax-luas/luas';
if (fs.existsSync(luaRoot)) {
  for (const entry of fs.readdirSync(luaRoot, { withFileTypes: true }).filter(entry => entry.isFile() && entry.name.endsWith('.lua'))) {
    const version = entry.name.match(/(?:[- .]v?|^v)(\d+\.\d+(?:\.\d+)?)/i)?.[1];
    localLuaHashes.set(hash(fs.readFileSync(path.join(luaRoot, entry.name))), `menu-cherax-lua-${slug(entry.name)}`);
    add({ id: `menu-cherax-lua-${slug(entry.name)}`, category: 'lua', name: entry.name.replace(/\.lua$/i, '').replace(/_/g, ' '),
      sourceFilename: entry.name, sourceMenu: 'cherax', supportedMenus: ['cherax', 'scooby'], version,
      description: 'Cherax Lua script from the local collection. Download pending.', requirementLabel: 'Cherax Lua API compatibility layer',
      requirements: ['Cherax Lua API or the matching compatibility layer in the installed Scooby/Nenyoo build', 'Install required script libraries and use the game edition specified by the author'],
      compatibility: 'Original Cherax Lua script; the host compatibility layer and script dependencies must match. Individual runtime behavior has not been tested.',
      collection: 'local', tags: ['Lua', 'Cherax', entry.name], changelog: []
    }, 'cherax');
  }
}
add({ id: 'menu-cherax-lua-host-tools-1-9-0', category: 'lua', name: 'Host Tools', sourceFilename: 'Host-Tools-v1.9.0.lua', version: '1.9.0',
  sourceMenu: 'cherax', supportedMenus: ['cherax', 'scooby'], author: 'Plynko', description: 'Player and session management script. Download pending.',
  requirementLabel: 'Cherax Lua API compatibility layer', requirements: ['Cherax Lua API or matching host compatibility layer'],
  changelog: [{ version: '1.9.0', date: '2026-11-08', changes: ['Added player notes and crew-based blocking.', 'Expanded flag matching and recent-player information.', 'Updated HUD grouping and corrected player-tab flag refresh.'] }],
  tags: ['Host Tools', 'Lua', 'Cherax', 'player management'], sourceChannel: 'Host Tools changelog',
  compatibility: 'Release information read in the Discord Canary client. Script runtime behavior has not been tested.'
}, 'cherax');
importManifest('cherax');
const enrichmentFile = path.join(SOURCES, 'cherax-lua-enrichment.json');
if (fs.existsSync(enrichmentFile)) for (const entry of read(enrichmentFile).items || []) {
  const id = luaIdentity(entry), original = additions.get(id);
  if (original?.category === 'lua') add({ ...original, ...entry, id, category: 'lua' }, 'cherax');
}
output.items = [...additions.values()];
output.libraryOverrides = [...overrides.values()].map(entry => {
  const original = baseItems.get(entry.id);
  return Object.fromEntries(Object.entries(entry).filter(([key, value]) => key === 'id' || JSON.stringify(value) !== JSON.stringify(original?.[key])));
});
const groups = new Map();
for (const entry of legacy.values()) {
  const shared = ['sourceMenu', 'supportedMenus', 'listedMenus', 'collection', 'collectionStatus', 'oldShares', 'format', 'compatibility', 'requirementLabel', 'requirements', 'credits', 'author', 'version', 'versionBasis', 'tags', 'guide'];
  const metadata = Object.fromEntries(shared.filter(key => entry[key] !== undefined).map(key => [key, entry[key]]));
  metadata.archival = Boolean(entry.archival || entry.collection === 'archival' || entry.collectionStatus === 'archival');
  const key = entry.family + JSON.stringify(metadata);
  if (!groups.has(key)) groups.set(key, { family: entry.family, indices: [], metadata });
  groups.get(key).indices.push(entry.index);
  if (entry.sourceUrl || entry.previewVerified === false) output.legacyOverrides.push({ family: entry.family, index: entry.index,
    ...(entry.sourceUrl ? { sourceUrl: entry.sourceUrl } : {}), ...(entry.previewVerified === false ? { previewVerified: false } : {}) });
}
output.legacyGroups = [...groups.values()];
applyCheraxCatalog(output);
const outputFile = path.join(ROOT, 'community/data/menu-resources.json'), temporary = `${outputFile}.tmp-${process.pid}`;
recordResourceAdditions(output, fs.existsSync(outputFile) ? read(outputFile) : undefined);
const body = JSON.stringify(output, null, 2) + '\n';
fs.writeFileSync(temporary, body); fs.renameSync(temporary, outputFile);
if (publish) {
  if (!fs.existsSync(target) || fs.lstatSync(target).isSymbolicLink()) throw Error('Invalid download repository target');
  planned.set('catalog/menu-resources.json', Buffer.from(body));
  for (const [relative, data] of planned) {
    const file = path.resolve(target, relative);
    if (!file.startsWith(target + path.sep)) throw Error('Asset path escaped download repository');
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, data);
  }
}
console.log(JSON.stringify({ items: output.items.length, libraryOverrides: output.libraryOverrides.length, legacyOverrides: legacy.size, legacyGroups: output.legacyGroups.length,
  lua: output.items.filter(item => item.category === 'lua').length, images: [...output.items, ...output.libraryOverrides].filter(item => item.previewVerified).length,
  stagedAssets: planned.size, publishedAssets: publish }, null, 2));
