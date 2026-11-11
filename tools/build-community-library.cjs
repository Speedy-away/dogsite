#!/usr/bin/env node
'use strict';

// Asset-only, repeatable importer. Never traverses an entire source repository.
// Usage: node tools/build-community-library.cjs --target C:\path\to\cool-repo
// Add --dry-run for an inventory without writes, or --check to verify an import.
// --refresh-catalog updates only palette/Stand additions and source-only metadata.
// --refresh-catalog --refresh-games cs2,gta5,rdr2 updates selected native assets.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const { renderClickUiPreview } = require('./render-community-theme-preview.cjs');
const { importNativeThemeCatalog } = require('./community-native-themes.cjs');
const { tagsFor } = require('../resources/taxonomy.js');
const { buildMarketplaceItems } = require('./community-mod-marketplace.cjs');
const { recordResourceAdditions } = require('./resource-additions.cjs');
const { DEFAULT_ROOT: DEFAULT_PAINTJOBS_ROOT, readNativePaintjobs } = require('./community-native-paintjobs.cjs');
const { DEFAULT_ROOT: DEFAULT_RDR2_ADDONS_ROOT, collectRdrAddonPacks, collectPublicRedmObjects } = require('./community-rdr2-addons.cjs');

const SITE = path.resolve(__dirname, '..');
const BASE_URL = 'https://raw.githubusercontent.com/Speedy-away/cool-repo/main/';
const DESTINATION = 'https://scoobymenu.cc/resources/';
// Theme imagery is disabled at the user's request. Keep the actual theme files.
const THEME_PREVIEWS = false;
const GAMES = new Set(['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d']);
const ALLOWED = new Set(['.json', '.lua', '.xml', '.ini', '.ui', '.xf_cnfg', '.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.ytd', '.wav', '.ttf', '.otf', '.txt', '.md', '.vmat_c', '.vtex_c']);
const args = process.argv.slice(2);
function argument(name, fallback) {
  const i = args.indexOf(name);
  if (i === -1) return fallback;
  if (!args[i + 1] || args[i + 1].startsWith('--')) throw Error(`Missing value for ${name}`);
  return args[i + 1];
}
const target = argument('--target');
const dryRun = args.includes('--dry-run');
const checking = args.includes('--check');
const refreshCatalog = args.includes('--refresh-catalog');
const refreshGames = new Set(String(argument('--refresh-games', '')).split(',').filter(Boolean));
const partialRefresh = refreshGames.size > 0;
if (partialRefresh && !refreshCatalog) throw Error('--refresh-games requires --refresh-catalog');
for (const game of refreshGames) if (!['cs2', 'gta5', 'rdr2'].includes(game)) throw Error(`Unsupported refresh game: ${game}`);
const sourceRoot = path.resolve(argument('--source-root', path.dirname(SITE)));
const paintjobsRoot = path.resolve(argument('--paintjobs-root', DEFAULT_PAINTJOBS_ROOT));
const rdr2AddonsRoot = path.resolve(argument('--rdr2-addons-root', DEFAULT_RDR2_ADDONS_ROOT));
const targetRoot = target && path.resolve(target);
const output = path.resolve(argument('--output', path.join(SITE, 'community', 'data', 'library.json')));
const roots = {
  gta5: path.join(sourceRoot, 'Scooby-Op', 'GTA5', 'EE', 'GTA - Main Src'),
  rdr2: path.join(sourceRoot, 'Scooby-Op', 'RDR2', 'Scooby-RDR2-old - before-UI-update - working'),
  cs2: path.join(sourceRoot, 'Scooby-Op', 'CS2', 'simple-base-cs2'),
  nenyoo: path.join(sourceRoot, 'project-native-gui', 'GTAV'),
};
function posix(value) { return value.split(path.sep).join('/'); }
function slug(value) {
  return String(value).normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'file';
}
function title(value) { return String(value).replace(/[_-]+/g, ' ').replace(/\b\w/g, c => c.toUpperCase()); }
function sha(data) { return crypto.createHash('sha256').update(data).digest('hex'); }
function within(root, relative) {
  if (typeof relative !== 'string' || !relative || relative.includes('\\') || relative.startsWith('/') || relative.split('/').some(p => !p || p === '.' || p === '..')) throw Error(`Unsafe asset path: ${relative}`);
  const resolved = path.resolve(root, ...relative.split('/'));
  const delta = path.relative(root, resolved);
  if (!delta || delta.startsWith('..') || path.isAbsolute(delta)) throw Error(`Asset escapes destination: ${relative}`);
  return resolved;
}
function walk(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => {
    if (entry.isSymbolicLink() || entry.name.startsWith('.')) return [];
    const full = path.join(directory, entry.name);
    return entry.isDirectory() ? walk(full) : entry.isFile() ? [full] : [];
  });
}
function assetEntries(directory, prefix = '') {
  return walk(directory).filter(f => ALLOWED.has(path.extname(f).toLowerCase())).map(f => ({
    name: `${prefix}${posix(path.relative(directory, f))}`, data: fs.readFileSync(f),
  }));
}

// Small standard ZIP writer: UTF-8 names, CRC32, deflate, no dependencies or shell.
const crcTable = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = (c & 1) ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(data) {
  let c = 0xffffffff;
  for (const byte of data) c = crcTable[(c ^ byte) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function zip(entries) {
  const local = [], central = [];
  let offset = 0;
  for (const entry of entries) {
    within(SITE, entry.name);
    const name = Buffer.from(entry.name, 'utf8');
    const data = Buffer.isBuffer(entry.data) ? entry.data : Buffer.from(entry.data);
    const compressed = zlib.deflateRawSync(data, { level: 6 });
    const crc = crc32(data);
    const header = Buffer.alloc(30);
    header.writeUInt32LE(0x04034b50); header.writeUInt16LE(20, 4); header.writeUInt16LE(0x0800, 6);
    header.writeUInt16LE(8, 8); header.writeUInt16LE(33, 12); header.writeUInt32LE(crc, 14);
    header.writeUInt32LE(compressed.length, 18); header.writeUInt32LE(data.length, 22); header.writeUInt16LE(name.length, 26);
    local.push(header, name, compressed);
    const directory = Buffer.alloc(46);
    directory.writeUInt32LE(0x02014b50); directory.writeUInt16LE(20, 4); directory.writeUInt16LE(20, 6);
    directory.writeUInt16LE(0x0800, 8); directory.writeUInt16LE(8, 10); directory.writeUInt16LE(33, 14);
    directory.writeUInt32LE(crc, 16); directory.writeUInt32LE(compressed.length, 20); directory.writeUInt32LE(data.length, 24);
    directory.writeUInt16LE(name.length, 28); directory.writeUInt32LE(offset, 42);
    central.push(directory, name); offset += header.length + name.length + compressed.length;
  }
  const directory = Buffer.concat(central), end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50); end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(directory.length, 12); end.writeUInt32LE(offset, 16);
  return Buffer.concat([...local, directory, end]);
}

const items = [], planned = new Map(), addedIds = new Set(), stats = { files: 0, bytes: 0, copied: 0, unchanged: 0 };
let sourceThemeItems = [];
function plan(relative, data) {
  within(SITE, relative);
  const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data);
  if (bytes.length >= 100 * 1024 * 1024) throw Error(`Asset exceeds GitHub's 100 MiB file limit: ${relative}`);
  if (planned.has(relative) && !planned.get(relative).equals(bytes)) throw Error(`Conflicting asset: ${relative}`);
  planned.set(relative, bytes);
  return { path: relative, name: path.posix.basename(relative), size: bytes.length, sha256: sha(bytes) };
}
function planSource(relative, source) {
  within(SITE, relative);
  const size = fs.statSync(source).size;
  if (size >= 100 * 1024 * 1024) throw Error(`Asset exceeds GitHub's 100 MiB file limit: ${relative}`);
  const digest = sha(fs.readFileSync(source));
  if (planned.has(relative)) throw Error(`Conflicting asset: ${relative}`);
  planned.set(relative, { source, size, sha256: digest });
  return { path: relative, name: path.posix.basename(relative), size, sha256: digest };
}
function add(item) {
  // Imported game scripts are intentionally excluded until individually validated.
  if (item.category === 'lua') return;
  if (!GAMES.has(item.game)) throw Error(`Unknown game ${item.game}`);
  if (items.some(v => v.id === item.id)) throw Error(`Duplicate item ID ${item.id}`);
  const guide = item.guide?.startsWith('/resources/guides/#')
    ? `/resources/guides/?game=${item.game}&category=${item.category}${item.menu === 'Nenyoo' ? '&menu=Nenyoo' : ''}`
    : item.guide;
  const family = nativeAssetFamily(item);
  items.push({ menu: 'Scooby', tags: [], files: [], ...item, ...(family ? { nativeImportFamily: family } : {}), ...(guide ? { guide } : {}) });
  addedIds.add(item.id);
}
function localFile(game, category, file, options = {}) {
  if (category === 'lua') return;
  if (!fs.existsSync(file)) return;
  if (!ALLOWED.has(path.extname(file).toLowerCase())) throw Error(`Unexpected asset type: ${file}`);
  const name = options.name || path.basename(file, path.extname(file));
  const relative = `downloads/${game}/${category}/${slug(options.id || name)}${path.extname(file).toLowerCase()}`;
  add({ game, category, name, files: [plan(relative, fs.readFileSync(file))],
    guide: `/resources/guides/?game=${game}&category=${category}`, credits: 'Scooby',
    ...options, id: `${game}-${category}-${slug(options.id || name)}` });
}
function packageFiles(game, category, id, name, entries, options = {}) {
  if (category === 'lua') return;
  if (!entries.length) return;
  const filename = `downloads/${game}/${category}/${slug(id)}.zip`;
  add({ id: `${game}-${category}-${slug(id)}`, game, category, name,
    files: [plan(filename, zip(entries))], guide: `/resources/guides/?game=${game}&category=${category}`,
    credits: 'Scooby', ...options });
}

function importCs2() {
  const root = roots.cs2;
  const catalogFile = path.join(root, 'assets/custom_models/catalog.json');
  if (!fs.existsSync(catalogFile)) return;
  const original = fs.readFileSync(catalogFile);
  const catalog = JSON.parse(original);
  if (!Array.isArray(catalog.packages)) throw Error(`CS2 catalog has no packages array: ${catalogFile}`);
  plan('catalog/cs2-models.json', original);
  for (const model of catalog.packages) {
    let category = model.category === 'players' ? 'players' : 'weapons';
    if (model.group === 'knife') category = 'knives';
    if (model.group === 'throwable') category = 'throwables';
    if (model.group === 'bomb') category = 'bombs';
    const files = model.url ? [{ url: model.url, name: model.archive || `${model.id}.zip`, size: model.downloadBytes, sha256: model.sha256 }] : [];
    let preview;
    const artwork = model.images?.find(image => image.path && fs.existsSync(path.join(root, 'assets/custom_models', image.path)));
    if (artwork) {
      const source = within(path.join(root, 'assets/custom_models'), artwork.path);
      preview = plan(`previews/cs2/${slug(model.id)}${path.extname(source)}`, fs.readFileSync(source)).path;
    } else if (model.images?.[0]?.url) preview = model.images[0].url;
    add({ id: `cs2-model-${model.id}`, game: 'cs2', category, name: model.name,
      description: model.localSource ? 'Build this variant in Scooby Custom > Repo using your installed CS2 files.' : model.workshopId ? 'Install this collection through Scooby Custom > Repo with Steam running.' : `Compiled ${{ players: 'player', weapons: 'weapon', knives: 'knife', throwables: 'throwable', bombs: 'bomb' }[category]} model package. Keep its materials and textures together.`,
      files, preview, guide: '/guides/cs2/custom-models/', sourceUrl: model.page || model.url,
      status: model.localSource ? 'in-menu' : model.workshopId ? 'workshop' : 'download',
      credits: model.author || model.source || 'See original source', license: model.license,
      tags: [model.category, model.group, model.source, model.author, model.resourcePath, ...(model.resourcePaths || [])].filter(Boolean),
      compatibility: model.localSource ? 'Requires the matching installed CS2 donor build. Install from the in-game Repo.' : 'Scooby CS2 Custom > Library; source author terms apply.',
    });
  }
  for (const file of walk(path.join(root, 'assets/configs')).filter(f => path.extname(f) === '.json')) {
    localFile('cs2', 'configs', file, { description: 'Scooby CS2 configuration preset. Back up your current profile before loading.', guide: '/resources/guides/#configs' });
  }
  for (const file of walk(path.join(root, 'assets/scripts')).filter(f => path.extname(f) === '.lua')) {
    localFile('cs2', 'lua', file, { description: 'Scooby CS2 Lua example. Load it from the CS2 script library.', guide: '/resources/guides/#lua', compatibility: 'Scooby CS2 Lua API; use a matching current host build.' });
  }
  for (const file of walk(path.join(root, 'assets/hud-presets')).filter(f => path.extname(f) === '.json')) {
    localFile('cs2', 'misc', file, { id: `hud-${path.basename(file, '.json')}`, name: `${title(path.basename(file, '.json'))} HUD preset`, description: 'Scooby CS2 HUD layout preset.', tags: ['HUD', 'layout'] });
  }
  const vfx = path.join(root, 'assets/vfx');
  const skies = path.join(vfx, 'materials/scooby_vfx/sky');
  for (const file of walk(skies).filter(f => path.extname(f) === '.vmat_c')) {
    const name = path.basename(file, '.vmat_c'), texture = path.join(skies, `${name}.vtex_c`);
    if (!fs.existsSync(texture)) continue;
    const entries = [file, texture].map(f => ({ name: posix(path.relative(vfx, f)), data: fs.readFileSync(f) }));
    entries.push({ name: 'INSTALL.txt', data: 'Close CS2. Extract materials into the detected CS2 game/csgo folder, retaining all relative paths. These are original Scooby procedural assets. Select the matching sky material in Scooby World/VFX. Back up files before replacement.\n' });
    entries.push({ name: 'README.md', data: fs.readFileSync(path.join(vfx, 'README.md')) });
    packageFiles('cs2', 'skyboxes', name, `Scooby ${title(name)}`, entries, { description: 'Original procedural sky material and texture. Includes installation instructions.', license: 'Original Scooby procedural assets; see included README.', tags: ['sky', 'VFX', name], guide: '/resources/guides/#skyboxes' });
  }
  const images = path.join(vfx, 'source-images');
  for (const file of walk(images).filter(f => (path.dirname(f) === images && path.extname(f) === '.png') || (path.dirname(f) === path.join(images, 'animated') && path.extname(f) === '.gif'))) {
    const name = path.basename(file, path.extname(file)), animated = path.extname(file) === '.gif';
    const relative = `downloads/cs2/textures/${slug(name)}${path.extname(file)}`;
    const resource = plan(relative, fs.readFileSync(file));
    add({ id: `cs2-texture-${slug(name)}`, game: 'cs2', category: 'textures', name: `${title(name)}${animated ? ' Animated' : ''}`, description: 'Original Scooby texture artwork. Copy to C:\\scooby\\CS2\\textures and import through Custom > Textures.', files: [resource], preview: relative, guide: '/guides/cs2/textures-and-sounds/', credits: 'Scooby', license: 'Original Scooby procedural artwork.', tags: ['VFX', animated ? 'animated' : 'PNG'] });
  }
}

function importRockstar(game) {
  const root = roots[game];
  if (!fs.existsSync(root)) return;
  const folder = game === 'gta5' ? 'GTA5' : 'RDR2';
  if (game === 'rdr2') {
    const outfitFile = path.join(root, 'src/game/frontend/submenus/outfiteditor/BundledOutfits.cpp');
    if (fs.existsSync(outfitFile)) {
      const { readBundledOutfits } = require('./extract-community-outfits.cjs');
      for (const outfit of readBundledOutfits(outfitFile)) {
        const resource = plan(`downloads/rdr2/outfits/${outfit.filename}`, outfit.json);
        add({ id: `rdr2-outfit-${outfit.filename.slice(0, -5)}`, game, category: 'outfits', name: outfit.name,
          description: `${outfit.gender} RDR2 outfit preset from the bundled Scooby collection.`,
          files: [resource], tags: [outfit.gender.toLowerCase(), 'preset'], credits: 'Scooby bundled outfit collection',
          guide: '/guides/rdr2/outfits/', compatibility: `Scooby RDR2 outfit JSON; ${outfit.gender} multiplayer model.` });
      }
    }
  }
  const languages = { ar: 'Arabic', de: 'German', en: 'English', es: 'Spanish', fr: 'French', he: 'Hebrew', hi: 'Hindi', id: 'Indonesian', it: 'Italian', ja: 'Japanese', ka: 'Georgian', ko: 'Korean', nl: 'Dutch', pl: 'Polish', pt: 'Portuguese', ru: 'Russian', sr: 'Serbian', th: 'Thai', tr: 'Turkish', vi: 'Vietnamese', zh: 'Chinese' };
  for (const file of walk(path.join(root, 'Translations')).filter(f => /^[a-z]{2}_[A-Z]{2}\.json$/.test(path.basename(f)))) {
    const locale = path.basename(file, '.json');
    localFile(game, 'languages', file, { name: `${languages[locale.slice(0, 2)] || locale} (${locale})`, id: locale,
      description: `Scooby ${folder} language file. Install it into C:\\scooby\\${folder}\\Languages.`, tags: [locale], compatibility: `Scooby ${folder} translation catalog.`, guide: `/resources/guides/?game=${game}&category=languages` });
  }
  for (const file of walk(path.join(root, 'assets/listui-layouts')).filter(f => path.extname(f) === '.json')) {
    const name = path.basename(file, '.json');
    localFile(game, 'themes', file, { name: `${name} ListUI layout sample`, uiStyle: 'ListUI', style: name === '2Take1' ? '2Take1' : 'Scooby',
      description: 'Reference navigation layout JSON from the Scooby source assets.', tags: ['layout', 'navigation', 'sample'], compatibility: 'Layout reference sample; use the matching style controls and current guide. An automatic import path is not assumed.', guide: `/resources/guides/?game=${game}&category=themes` });
  }
  for (const file of walk(path.join(root, 'configs')).filter(f => path.basename(f) === 'default.json')) {
    localFile(game, 'configs', file, { name: `Scooby ${folder} default config`, description: 'Original default configuration. Save a backup of your current configuration first.' });
  }
  // Lua is excluded. Maps must still refresh when no examples/lua folder exists.
  if (game !== 'gta5') return;
  for (const filename of ['BiggerScriptMaps.json.zlib', 'IniMaps.json.zlib']) {
    const packed = path.join(root, 'assets/maps', filename);
    if (!fs.existsSync(packed)) continue;
    const maps = JSON.parse(zlib.inflateSync(fs.readFileSync(packed)).toString('utf8'));
    for (const map of maps) {
      const original = String(map.path).replace(/\\/g, '/');
      within(SITE, original);
      const extension = path.posix.extname(original).toLowerCase();
      if (!['.xml', '.ini'].includes(extension)) throw Error(`Unexpected map asset ${original}`);
      const name = path.posix.basename(original, extension), id = `${slug(name)}-${sha(original).slice(0, 8)}`;
      const resource = plan(`downloads/gta5/maps/${id}${extension}`, map.xml);
      add({ id: `gta5-map-${id}`, game: 'gta5', category: 'maps', name: name.replace(/_/g, ' '), description: 'Map placement preset from the bundled GTA 5 map collection.', files: [resource], tags: original.split('/').slice(0, -1), credits: 'Original map authors; bundled collection', guide: '/resources/guides/#maps', compatibility: `Scooby GTA5 map loader; ${extension.slice(1).toUpperCase()} placement format.` });
    }
  }
  const manifest = path.join(root, 'assets/maps/manifest.json');
  if (fs.existsSync(manifest)) plan('catalog/gta5-maps-source.json', fs.readFileSync(manifest));
}

function importLegacyPresets() {
  for (const kind of ['vehicles', 'outfits']) {
    const file = path.join(SITE, 'resources/data', kind, 'local-assets.json');
    if (!fs.existsSync(file)) continue;
    const assets = JSON.parse(fs.readFileSync(file, 'utf8'));
    for (const asset of Object.values(assets)) {
      if (!asset.file) continue;
      const relative = asset.file.replace(/^\.\//, '');
      if (!relative.startsWith('media/')) throw Error(`Unexpected legacy asset ${asset.file}`);
      const source = within(path.join(SITE, 'community'), relative);
      if (!fs.existsSync(source)) throw Error(`Missing legacy payload ${source}`);
      const name = path.basename(source);
      planSource(`downloads/gta5/${kind}/${name}`, source);
    }
  }
  const summary = path.join(SITE, 'community/data/summary.json');
  if (fs.existsSync(summary)) plan('catalog/gta5-presets-source.json', fs.readFileSync(summary));
}

function importAddonCollection() {
  const root = path.join(sourceRoot, 'Rendererrr.github.io/scooby/GTA5/addons');
  const manifestFile = path.join(root, 'download-manifest.json');
  if (!fs.existsSync(manifestFile)) return;
  const original = fs.readFileSync(manifestFile), manifest = JSON.parse(original);
  const parts = fs.readdirSync(root).filter(name => /^Scooby-GTA-V-Addons-[0-9]+\.zip\.00[1-7]$/.test(name)).sort();
  if (parts.length !== 7) throw Error('GTA addon collection requires all seven archive parts');
  const files = parts.map(name => planSource(`downloads/gta5/addons/${name}`, path.join(root, name)));
  files.push(plan('downloads/gta5/addons/download-manifest.json', original));
  const readme = path.join(root, 'README.md');
  if (fs.existsSync(readme)) files.push(plan('downloads/gta5/addons/README.md', fs.readFileSync(readme)));
  add({ id: 'gta5-addon-collection', game: 'gta5', category: 'addon-vehicles', categories: ['addon-vehicles', 'addon-peds'],
    name: 'GTA 5 addon collection', description: 'Vehicles, peds, animations, sounds and replacement resources. Download all seven parts together and extract from .zip.001.',
    files, tags: ['addons', 'vehicles', 'peds', 'animations', 'sounds', 'Legacy', 'Enhanced', '7 parts'],
    sourceUrl: 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/addons',
    credits: 'Original pack authors; instructions and credits retained inside the archive.', guide: '/resources/guides/#addons',
    compatibility: 'Scooby GTA5 Addons/Replacements. Use the edition-specific content and converter where required.' });
  // Preserve the publisher checksum manifest verbatim; the archive payloads retain exact hashes.
  for (const part of manifest.parts || []) {
    const name = typeof part === 'string' ? part : part.name || part.file;
    if (!name || !parts.includes(name)) continue;
    const actual = files.find(file => file.name === name);
    if (part.sha256 && part.sha256 !== actual.sha256) throw Error(`Addon checksum mismatch: ${name}`);
  }
}

function importOtherGames() {
  for (const [game, root] of [
    ['fivem', path.join(sourceRoot, 'Scooby-Op/FiveM/new')],
    ['l4d', path.join(sourceRoot, 'Scooby-Op/source/L4D-Debug')],
  ]) {
    for (const file of walk(path.join(root, 'assets/languages')).filter(f => path.extname(f) === '.json')) {
      localFile(game, 'languages', file, { name: `${title(path.basename(file, '.json'))} language`, description: `Scooby ${game === 'l4d' ? 'L4D' : 'FiveM'} language catalog.`, guide: '/resources/guides/#languages' });
    }
    for (const file of walk(path.join(root, 'assets/scripts')).filter(f => path.extname(f) === '.lua')) {
      localFile(game, 'lua', file, { description: `Bundled Scooby ${game === 'l4d' ? 'L4D' : 'FiveM'} Lua example. Use the matching game's script library.`, guide: '/resources/guides/#lua' });
    }
  }
}

function importNenyooThemes() {
  const root = path.join(roots.nenyoo, 'theme_packages');
  for (const file of walk(root).filter(f => path.basename(f) === 'theme.lua')) {
    const directory = path.dirname(file), relative = posix(path.relative(root, directory));
    const id = slug(relative), name = path.basename(directory), stand = relative.startsWith('Stand Imports/');
    const entries = assetEntries(directory, `${name}/`);
    if (!entries.length) continue;
    packageFiles('gta5', 'themes', `nenyoo-${id}`, name, entries, { menu: 'Nenyoo', uiStyle: 'ListUI', style: stand ? 'Stand' : 'Nenyoo',
      description: 'Nenyoo ListUI theme bundle with its supporting textures. Extract the theme folder into %LOCALAPPDATA%\\Nenyoo\\Plus\\Themes.',
      compatibility: 'Nenyoo Lua theme format. Requires Nenyoo; Scooby JSON theme compatibility is not implied.',
      tags: [stand ? 'Stand Imports' : 'Nenyoo', 'theme.lua'], credits: stand ? 'Original Stand theme authors; Nenyoo import collection' : 'Nenyoo theme package authors', guide: '/resources/guides/#nenyoo-themes' });
  }
}

function importNativeThemes() {
  const mappings = [
    ['2Take1', '2Take1', '2TAKE1/Default', 'Themes/ListUI'],
    ['impulse theme', 'Impulse', 'IMPULSE/Default', 'Themes/ListUI'],
    ['Infamous-Full', 'Infamous', 'Infamous-Full', 'images/ListUI'],
    ['Paragon', 'Paragon', 'Paragon', 'Themes/ListUI'],
    ['Sx', 'Sx', 'Sx', 'images/ListUI'],
    ['xforce-v6', 'X-Force', 'X-Force v6', 'Themes/ListUI'],
  ];
  for (const game of ['gta5', 'rdr2']) {
    const root = roots[game], folder = game === 'gta5' ? 'GTA5' : 'RDR2';
    for (const [directory, style, destination, workspace] of mappings) {
      const source = path.join(root, 'assets/listui', directory);
      const entries = assetEntries(source, `${destination}/`);
      if (!entries.length) continue;
      entries.push({ name: 'INSTALL.txt', data: `Scooby ${folder} ${style} ListUI resource pack\n\nExtract the ${destination.split('/')[0]} folder into C:/scooby/${folder}/${workspace}. Preserve all subfolders. Select the matching built-in ListUI style in Scooby Settings, then use that style's Appearance controls. Keep a backup of custom assets before replacing them.\n\nThis archive contains the source-bundled UI data and artwork only. Credits and original preset filenames are preserved. It is a Scooby style resource pack; format compatibility with the original third-party menu is not implied.\n` });
      packageFiles(game, 'themes', `scooby-${slug(style)}-resources`, `${style} ListUI resource pack`, entries, {
        uiStyle: 'ListUI', style, description: `Bundled ${style} artwork, presets and layout resources for Scooby ${folder}. Includes installation instructions.`,
        compatibility: `Requires a compatible Scooby ${folder} build with the ${style} ListUI style. Extract into C:\\scooby\\${folder}\\${workspace.replaceAll('/', '\\')}.`,
        credits: 'Source-bundled style resources; original artwork and preset authors.', tags: ['ListUI', style, 'resources'],
      });
    }
  }
  const root = roots.gta5;
  const silkroad = path.join(root, 'src/core/frontend/ListUI/Styles/Silkroad/Assets/Embedded');
  const silkroadEntries = assetEntries(silkroad, 'Silkroad/Assets/');
  if (silkroadEntries.length) {
    silkroadEntries.push({ name: 'Silkroad/INSTALL.txt', data: 'Extract the Silkroad folder into C:/scooby/GTA5/Themes/ListUI or C:/scooby/RDR2/Themes/ListUI. Both Silkroad v3/v4 and Silkroad Simple share these assets. Select the theme from Silkroad Appearance > Themes.\n' });
    for (const game of ['gta5', 'rdr2']) packageFiles(game, 'themes', 'silkroad-resources', 'Silkroad ListUI theme pack', silkroadEntries, { uiStyle: 'ListUI', style: 'Silkroad', description: 'Shared artwork for Silkroad v3/v4 and Silkroad Simple styles. Includes installation instructions.', compatibility: 'Scooby Silkroad ListUI styles.', tags: ['Silkroad', 'ListUI', 'artwork'] });
  }
  const ozark = path.join(root, 'src/core/frontend/ListUI/Styles/Ozark/Assets/Embedded/themes');
  const indexFile = path.join(ozark, 'themes-index.json');
  if (fs.existsSync(indexFile)) {
    const index = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
    const entries = [];
    for (const theme of index) {
      const document = fs.readFileSync(path.join(ozark, `${theme.slug}.json`));
      const parsed = JSON.parse(document);
      entries.push({ name: `Ozark v34/Presets/${theme.name}.json`, data: document });
      for (const role of ['header', 'background', 'footer']) {
        const relative = parsed.values?.[`Ozark.Image.${role}`];
        if (!relative) continue;
        within(SITE, relative);
        const name = `Ozark v34/${relative}`;
        if (!entries.some(e => e.name === name)) entries.push({ name, data: fs.readFileSync(path.join(ozark, path.posix.basename(relative))) });
      }
    }
    entries.push({ name: 'Ozark v34/INSTALL.txt', data: 'Extract Ozark v34 into C:/scooby/GTA5/Themes/ListUI or C:/scooby/RDR2/Themes/ListUI. Select Ozark v34 in Scooby Settings, then load the included presets using its Appearance controls. Preserve Presets and referenced artwork folders together.\n' });
    for (const game of ['gta5', 'rdr2']) packageFiles(game, 'themes', 'ozark-presets', 'Ozark v34 ListUI themes', entries, { uiStyle: 'ListUI', style: 'Ozark', description: 'Bundled Ozark v34 JSON presets with their original artwork and installation instructions.', compatibility: 'Scooby Ozark v34 ListUI style.', tags: ['Ozark', 'ListUI', 'presets'] });
  }
}

function importGtaTextures() {
  const root = path.join(roots.gta5, 'assets/CustomTextures/Original');
  for (const file of walk(root).filter(f => ['.png', '.jpg', '.gif'].includes(path.extname(f).toLowerCase()))) {
    const extension = path.extname(file).toLowerCase(), basename = path.basename(file, extension);
    const name = basename.replaceAll('-', ' '), id = `${slug(basename)}-${extension.slice(1)}`;
    const relative = `downloads/gta5/textures/${id}${extension}`;
    add({ id: `gta5-texture-${id}`, game: 'gta5', category: 'textures', name: `${name} (${extension.slice(1).toUpperCase()})`,
      description: 'Original Scooby image texture. Import with the GTA 5 Custom Textures browser for a supported target.',
      files: [planSource(relative, file)], preview: relative, guide: '/resources/guides/?game=gta5&category=textures', credits: 'Scooby original texture collection', tags: ['original', extension.slice(1), extension === '.gif' ? 'animated' : 'image'] });
  }
}

function importLiveryConcept() {
  const template = path.join(roots.gta5, 'assets/CustomTextures/Concepts/Scooby-Livery-Concept.png');
  if (fs.existsSync(template)) {
    const resource = planSource('downloads/gta5/liveries/scooby-livery-concept.png', template);
    add({ id: 'gta5-paintjob-scooby-livery-concept', game: 'gta5', category: 'liveries', name: 'Scooby livery concept artwork',
      description: 'Image artwork for designing a vehicle livery. Adapt it to the target vehicle texture layout before installation.',
      files: [resource], preview: resource.path, guide: '/resources/guides/?game=gta5&category=liveries', credits: 'Scooby', tags: ['livery', 'concept', 'PNG'], compatibility: 'Editable image artwork; vehicle-specific texture preparation is required.' });
  }
}

function importNativePaintjobs() {
  const presets = readNativePaintjobs(paintjobsRoot), inventory = [];
  for (const preset of presets) {
    const document = preset.document, name = document.name || path.posix.basename(preset.filename, '.json');
    const folder = preset.folder === '.' ? '' : preset.folder;
    const filename = `${slug(path.posix.basename(preset.filename, '.json'))}-${sha(preset.relative).slice(0, 8)}.json`;
    const relative = `downloads/gta5/paintjobs/${folder ? `${slug(folder)}/` : ''}${filename}`;
    const resource = { ...plan(relative, preset.data), name: preset.filename };
    if (resource.sha256 !== preset.sha256) throw Error(`Native paintjob copy mismatch: ${preset.relative}`);
    const id = `gta5-paintjob-native-${sha(preset.relative).slice(0, 16)}`;
    const installFolder = `C:\\scooby\\GTA5\\LSC\\PaintJobs${folder ? `\\${folder.replaceAll('/', '\\')}` : ''}`;
    add({ id, game: 'gta5', category: 'paintjobs', name,
      description: `Native LSC paint preset${folder ? ` from ${folder}` : ''}. Copy the JSON into ${installFolder}, then select it in LSC’s Save/Load Paint Jobs controls while inside a vehicle.`,
      files: [resource], sourceFormat: 'Scooby LSC PaintJob JSON', nativePaintjob: true, paintjobFormat: document.format,
      paintCategory: document.category || folder || 'Root', installFolder,
      paintColours: ['primary', 'secondary'].filter(key => document.colours[key]?.rgb).map(key => ({ label: key, rgb: document.colours[key].rgb })),
      credits: document.creator ? String(document.creator) : 'Scooby native paint library', source: document.source || 'Requested local LSC PaintJobs library',
      tags: ['LSC', 'paintjob', 'native', 'color', 'colour', folder, document.hex, document.secondary_hex, document.pearl_hex, document.creator].filter(Boolean),
      compatibility: 'Scooby GTA5 native saved-paintjob JSON. Enter a vehicle, choose the preset’s folder and file, then select Load Paint Job.',
      guide: '/resources/guides/?game=gta5&category=paintjobs' });
    inventory.push({ id, file: resource.path, originalFile: preset.relative, size: resource.size, sha256: resource.sha256, format: document.format, version: document.version, source: document.source, creator: document.creator });
  }
  plan('catalog/native-paintjobs-source.json', JSON.stringify({ version: 1, format: 'scooby.paintjob', installRoot: 'C:\\scooby\\GTA5\\LSC\\PaintJobs', files: inventory }));
  return presets.length;
}

function importRdr2Addons() {
  const packs = collectRdrAddonPacks(rdr2AddonsRoot), inventory = [];
  for (const pack of packs) {
    const instructions = Buffer.from(`Scooby RDR2 addon export: ${pack.name}\n\nThe original runtime pack and credits are retained. Editing projects, disabled replacements and backup files were omitted.\n\nCopy this ZIP into C:/scooby/RDR2/Addon Archives. Open Addons/Replacements > Archives, choose Refresh Archives, select the pack root and use Import to Library. Then Refresh Library and use Validate Direct Pack before a compatible load/staging action. Direct Pack loading is marked experimental by the native menu. LML staging requires Lenny's Mod Loader and applies on the next game launch. The menu's registration checks and spawn controls are separate from archive validation.\n\nDo not combine files from different exports. Keep the install.xml, ped metadata and all Streamer files together. Original package instructions and author terms remain applicable.\n`);
    const entries = pack.files.map(file => ({ name: file.name, data: file.data }));
    entries.push({ name: 'COMMUNITY-INSTALL.txt', data: instructions });
    const resource = plan(`downloads/rdr2/${pack.categories[0]}/${pack.id}.zip`, zip(entries));
    const id = `rdr2-native-addon-${pack.id}`;
    add({ id, game: 'rdr2', category: pack.categories[0], categories: pack.categories, name: pack.name,
      description: 'Complete native RDR2 addon ped resources with install.xml, ped metadata and supporting streaming files. Download the ZIP and import it through Addons/Replacements.',
      files: [resource], sourceFormat: 'RDR2 EasyInstall/LML addon resource ZIP', version: pack.version,
      credits: `${pack.author}; original package instructions retained`, source: 'Requested local RDR2 Addons library',
      tags: ['RDR2', 'addon', 'ped', pack.id, 'YDD', 'YTD', 'YMT', 'LML'],
      requirements: ['A compatible Scooby RDR2 build with Addons/Replacements', 'Keep the full resource set together', 'Lenny’s Mod Loader when using next-launch LML staging'],
      compatibility: 'Native RDR2 resource format and declared file dependencies checked. Live game loading and registration remain unverified; use the menu’s validation and registration controls.',
      guide: `/resources/guides/?game=rdr2&category=${pack.categories[0]}` });
    inventory.push({ id, name: pack.name, author: pack.author, version: pack.version, categories: pack.categories,
      download: resource, originalFolder: pack.folder, files: pack.files.map(file => ({ path: file.relative, size: file.size, sha256: file.sha256 })), excluded: pack.excluded });
  }
  plan('catalog/rdr2-addons-source.json', JSON.stringify({ version: 1, source: 'Explicit local RDR2 Addons asset directory', archiveInstallFolder: 'C:\\scooby\\RDR2\\Addon Archives', packs: inventory }));
  return packs.length;
}

function packColor(vector, round = false, alpha) {
  const channels = vector.map(value => {
    const scaled = Math.fround(Math.fround(value) * 255);
    return Math.max(0, Math.min(255, round ? Math.floor(scaled + 0.5) : Math.trunc(scaled)));
  });
  if (alpha !== undefined) channels[3] = alpha;
  return (channels[0] | (channels[1] << 8) | (channels[2] << 16) | (channels[3] << 24)) >>> 0;
}

function importClickUiPalettes() {
  // Export data values from the shipped native palettes into the actual saved-theme
  // color keys. This emits no source code and makes no game-runtime validation claim.
  if (packColor([1, 0, 0, 1], true) !== 0xff0000ff || packColor([0.035, 0.050, 0.070, 0.98]) !== 0xf9110c08) throw Error('ClickUI color packing sanity check failed');
  for (const game of ['gta5', 'rdr2']) {
    const root = roots[game];
    const paletteFile = path.join(root, 'src/core/frontend/manager/styles/ColorThemes.hpp');
    const loaderFile = path.join(root, 'src/core/frontend/manager/styles/UIThemeSettings.cpp');
    if (!fs.existsSync(paletteFile) || !fs.existsSync(loaderFile)) continue;
    const source = fs.readFileSync(paletteFile, 'utf8'), loader = fs.readFileSync(loaderFile, 'utf8');
    const paletteAssignments = ['ApplyAccentColor', 'ApplyFullTheme'].map(name => {
      const start = loader.indexOf(`void UIThemeSettings::${name}(`);
      if (start < 0) throw Error(`Missing native ${name} mapping for ${game}`);
      const next = loader.indexOf('\n\tvoid UIThemeSettings::', start + 20);
      return loader.slice(start, next < 0 ? loader.length : next);
    }).join('\n');
    const expression = /inline\s+ThemeColors\s+(\w+)\s*=\s*\{\s*"([^"]+)"\s*,([\s\S]*?)\n\s*\};/g;
    let count = 0;
    for (const match of source.matchAll(expression)) {
      const vectors = [...match[3].matchAll(/ImVec4\(([^)]+)\)/g)].map(entry => entry[1].split(',').map(number => Number(number.trim().replace(/f$/, ''))));
      if (vectors.length !== 9 || vectors.some(vector => vector.length !== 4 || vector.some(number => !Number.isFinite(number) || number < 0 || number > 1))) throw Error(`Invalid source palette ${match[1]}`);
      const [primary, secondary, deep, panel, accent, , , gradientStart, gradientEnd] = vectors;
      const color = packColor(primary, true);
      const document = {
        windowBackground: packColor(deep), windowBorder: packColor(primary, false, 80),
        windowScrollbar: color, windowCursor: color, tabSelectedIcon: color, tabIndicator: color,
        categoryIndicator: color, toggleOn: color, sliderFilled: color, childTitle: color,
        childAccentLeft: color, contentSectionText: color, textAccent: color, notificationAccent: color,
        childBackground: game === 'gta5' ? packColor(panel, false, 0) : packColor(panel), groupBackground: packColor(panel, false, 0),
        groupBorder: packColor(accent, false, 70), contentPanelBackground: packColor(panel, false, 235),
        contentListBackground: packColor(panel, false, 220),
        tabUnselectedBg: packColor(panel, false, 100), categoryUnselectedBg: packColor(panel, false, 80),
        gradientStart: packColor(gradientStart, true), gradientEnd: packColor(gradientEnd, true),
        useGradients: !/\bfalse\b/.test(match[3].slice(match[3].lastIndexOf('ImVec4'))),
      };
      // Palette layouts differ by host revision. Emit only keys explicitly read by
      // that host's saved-theme loader; shared source names alone are insufficient.
      for (const key of Object.keys(document)) {
        if (!loader.includes(`state.contains("${key}")`) || !new RegExp(`\\b${key}\\s*=`).test(paletteAssignments)) delete document[key];
      }
      for (const key of ['windowBackground', 'windowBorder', 'tabIndicator', 'toggleOn', 'sliderFilled']) if (!(key in document)) throw Error(`ClickUI loader is missing ${key} for ${game}`);
      const name = `${match[2]} ClickUI colors`, id = `clickui-${slug(match[1])}`;
      if (game === 'gta5') document._bundle = { format: 'ScoobyTheme', version: 3, name, scope: 'ClickUI' };
      const data = JSON.stringify(document, null, 2) + '\n';
      if (JSON.parse(data).windowBackground !== document.windowBackground) throw Error(`Invalid exported palette ${id}`);
      const resource = plan(`downloads/${game}/themes/${id}.json`, data);
      const preview = THEME_PREVIEWS ? plan(`previews/themes/clickui/${game}-themes-${id}.svg`, renderClickUiPreview({ name, game, document })).path : undefined;
      add({ id: `${game}-themes-${id}`, game, category: 'themes', uiStyle: 'ClickUI', style: 'Scooby', name,
        description: 'Applies source-derived Scooby ClickUI palette colors. Back up your current theme before loading.',
        preview, previewKind: 'palette', previewCaption: 'ClickUI color palette illustration',
        files: [resource], credits: 'Scooby built-in palette data', tags: ['ClickUI', 'colors', 'palette', match[2]],
        compatibility: game === 'gta5' ? 'Scooby GTA5 saved-theme JSON. Copy to C:\\scooby\\GTA5\\themes, refresh the library and load with ClickUI scope.' : 'Scooby RDR2 saved-theme JSON. Copy to C:\\scooby\\RDR2\\theme, refresh Saved Themes and load.',
        guide: `/resources/guides/?game=${game}&category=themes` });
      count++;
    }
    const expectedCount = game === 'gta5' ? 19 : 8;
    if (count !== expectedCount) throw Error(`Expected ${expectedCount} built-in ClickUI palette data entries for ${game}; found ${count}`);
  }
}

function importStandCollections() {
  const root = path.join(sourceRoot, 'Rendererrr.github.io/scooby/GTA5/ListUI/Themes/Stand');
  const indexFile = path.join(root, 'stand-packs.json');
  if (!fs.existsSync(indexFile)) return;
  const index = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
  plan('catalog/stand-theme-packs-source.json', fs.readFileSync(indexFile));
  for (const pack of index.packs) {
    if (!/^ListUI-Stand-\d{2}\.zip$/.test(pack.file)) throw Error(`Unexpected Stand pack ${pack.file}`);
    const resource = planSource(`downloads/shared/themes/stand/${pack.file}`, path.join(root, pack.file));
    if (resource.sha256 !== pack.sha256 || resource.size !== pack.bytes) throw Error(`Published Stand collection checksum mismatch: ${pack.file}`);
    for (const game of ['gta5', 'rdr2']) {
      const folder = game === 'gta5' ? 'GTA5' : 'RDR2', number = pack.file.match(/(\d{2})\.zip$/)[1];
      add({ id: `${game}-themes-stand-collection-${number}`, game, category: 'themes', uiStyle: 'ListUI', style: 'Stand',
        name: `Stand ListUI collection ${number}`, description: 'Original published collection supported by Scooby’s Stand style. Includes theme profiles, scripts and their supporting artwork.',
        files: [resource], credits: 'Original Stand collection authors; publisher archive and credits retained.',
        tags: ['Stand', 'ListUI', 'collection', 'themes', 'profiles'],
        compatibility: `Requires a compatible Scooby ${folder} build with the native Stand style. Extract Stand into C:\\scooby\\${folder}\\Themes\\ListUI and refresh Stand Themes.`,
        sourceUrl: 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/ListUI/Themes/Stand',
        guide: `/resources/guides/?game=${game}&category=themes` });
    }
  }
}

function archiveSourceThemes() {
  const archived = items.filter(item => item.menu === 'Nenyoo');
  sourceThemeItems = [...new Map([...sourceThemeItems, ...archived].map(item => [item.id, item])).values()];
  for (let i = items.length - 1; i >= 0; i--) if (items[i].menu === 'Nenyoo') items.splice(i, 1);
  plan('catalog/source-theme-packs.json', JSON.stringify({ version: 1, purpose: 'Source bundles retained for reference; excluded from the active Scooby catalog because they require Nenyoo.', downloadBaseUrl: BASE_URL, items: sourceThemeItems }));
}

// Reserved ID namespaces plus their asset paths identify older importer rows.
// Category alone is deliberately insufficient: author listings and menu-source
// resources can share a game/category without belonging to this importer.
function nativeAssetFamily(item) {
  const { id = '', game } = item;
  const local = prefix => (item.files || []).some(file => file.path?.startsWith(prefix));
  if (game === 'cs2') {
    if (id.startsWith('cs2-model-')) return 'cs2:models';
    if (id.startsWith('cs2-configs-') && local('downloads/cs2/configs/')) return 'cs2:configs';
    if (id.startsWith('cs2-misc-hud-') && local('downloads/cs2/misc/')) return 'cs2:hud';
    if (id.startsWith('cs2-skyboxes-') && local('downloads/cs2/skyboxes/')) return 'cs2:skyboxes';
    if (id.startsWith('cs2-texture-') && local('downloads/cs2/textures/')) return 'cs2:textures';
  }
  if (game === 'gta5' || game === 'rdr2') {
    if (id.startsWith(`${game}-languages-`) && local(`downloads/${game}/languages/`)) return `${game}:languages`;
    if (id.startsWith(`${game}-configs-`) && local(`downloads/${game}/configs/`)) return `${game}:configs`;
    if (id.startsWith(`${game}-themes-`) && id.endsWith('-listui-layout-sample') && local(`downloads/${game}/themes/`)) return `${game}:layouts`;
    if (game === 'gta5' && id.startsWith('gta5-map-') && local('downloads/gta5/maps/')) return 'gta5:maps';
    if (game === 'gta5' && id.startsWith('gta5-texture-') && local('downloads/gta5/textures/')) return 'gta5:textures';
    if (game === 'rdr2' && id.startsWith('rdr2-outfit-') && local('downloads/rdr2/outfits/')) return 'rdr2:outfits';
  }
  return '';
}

function refreshNativeAssets(existing) {
  const familyInputs = {
    'cs2:models': ['assets/custom_models/catalog.json'], 'cs2:configs': ['assets/configs'],
    'cs2:hud': ['assets/hud-presets'], 'cs2:skyboxes': ['assets/vfx/materials/scooby_vfx/sky', 'assets/vfx/README.md'],
    'cs2:textures': ['assets/vfx/source-images'],
    'gta5:languages': ['Translations'], 'gta5:configs': ['configs'], 'gta5:layouts': ['assets/listui-layouts'],
    'gta5:maps': ['assets/maps/BiggerScriptMaps.json.zlib', 'assets/maps/IniMaps.json.zlib', 'assets/maps/manifest.json'],
    'gta5:textures': ['assets/CustomTextures/Original'],
    'rdr2:languages': ['Translations'], 'rdr2:configs': ['configs'], 'rdr2:layouts': ['assets/listui-layouts'],
    'rdr2:outfits': ['src/game/frontend/submenus/outfiteditor/BundledOutfits.cpp'],
  };
  const priorFamilies = new Set(existing.items.map(nativeAssetFamily).filter(Boolean));
  const requireSource = source => {
    if (!fs.existsSync(source) || fs.lstatSync(source).isSymbolicLink()) throw Error(`Required native refresh source is unavailable: ${source}`);
  };
  // Check every selected source before replacing any row or writing an asset.
  for (const game of refreshGames) {
    requireSource(roots[game]);
    if (game === 'cs2') {
      const source = path.join(roots.cs2, 'assets/custom_models/catalog.json');
      requireSource(source);
      if (!Array.isArray(JSON.parse(fs.readFileSync(source, 'utf8')).packages)) throw Error(`CS2 catalog has no packages array: ${source}`);
    }
    if (game === 'rdr2') requireSource(path.join(roots.rdr2, 'src/game/frontend/submenus/outfiteditor/BundledOutfits.cpp'));
    for (const [family, inputs] of Object.entries(familyInputs)) {
      if (family.startsWith(`${game}:`) && priorFamilies.has(family)) for (const relative of inputs) requireSource(path.join(roots[game], relative));
    }
  }
  items.push(...existing.items.filter(item => item.category !== 'lua' && !refreshGames.has(nativeAssetFamily(item).split(':')[0])));
  for (const game of refreshGames) {
    if (game === 'cs2') importCs2();
    else {
      importRockstar(game);
      if (game === 'gta5') importGtaTextures();
    }
  }
}

function atomicWrite(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.tmp-${process.pid}-${crypto.randomBytes(6).toString('hex')}`;
  try { fs.writeFileSync(temporary, data); fs.renameSync(temporary, file); }
  finally { if (fs.existsSync(temporary)) fs.unlinkSync(temporary); }
}

function write(relative, data) {
  const destination = within(targetRoot, relative);
  const sourceFile = !Buffer.isBuffer(data) && data.source;
  stats.files++; stats.bytes += sourceFile ? data.size : data.length;
  if (fs.existsSync(destination)) {
    const existing = fs.readFileSync(destination);
    if (sourceFile ? (existing.length === data.size && sha(existing) === data.sha256) : existing.equals(data)) { stats.unchanged++; return; }
  }
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  if (sourceFile) fs.copyFileSync(data.source, destination);
  else if (relative.startsWith('catalog/')) atomicWrite(destination, data);
  else fs.writeFileSync(destination, data);
  stats.copied++;
}
function verify() {
  const manifest = JSON.parse(fs.readFileSync(output, 'utf8'));
  const targetManifest = JSON.parse(fs.readFileSync(within(targetRoot, 'catalog/library.json'), 'utf8'));
  if (JSON.stringify(manifest) !== JSON.stringify(targetManifest)) throw Error('Site and download repository catalogs differ');
  const ids = new Set(), verified = new Map(); let local = 0, external = 0;
  for (const item of manifest.items) {
    if (!GAMES.has(item.game) || !item.category || !item.name || ids.has(item.id)) throw Error(`Invalid catalog item: ${item.id}`);
    ids.add(item.id);
    for (const file of item.files) {
      if (file.url) { if (!/^https:\/\//.test(file.url)) throw Error(`Non-HTTPS download ${item.id}`); external++; continue; }
      local++;
      if (verified.has(file.path)) {
        const prior = verified.get(file.path);
        if (prior.size !== file.size || prior.sha256 !== file.sha256) throw Error(`Conflicting shared asset metadata: ${file.path}`);
        continue;
      }
      const actual = fs.readFileSync(within(targetRoot, file.path));
      if (actual.length !== file.size || sha(actual) !== file.sha256) throw Error(`Asset mismatch: ${file.path}`);
      verified.set(file.path, file);
    }
    if (item.preview && !/^https:\/\//.test(item.preview) && !fs.existsSync(within(targetRoot, item.preview))) throw Error(`Missing preview ${item.preview}`);
  }
  if (!fs.readFileSync(within(targetRoot, 'index.html'), 'utf8').includes(DESTINATION)) throw Error('Download repository redirect is missing');
  console.log(JSON.stringify({ ok: true, items: ids.size, localDownloads: local, uniqueLocalFiles: verified.size, externalDownloads: external }));
}

function main() {
  if (!targetRoot && !dryRun) throw Error('Pass --target with the download repository absolute path');
  if (checking) { verify(); return; }
  let existing;
  if (refreshCatalog) {
    existing = JSON.parse(fs.readFileSync(output, 'utf8'));
    if (existing.version !== 1 || !Array.isArray(existing.items)) throw Error(`Invalid existing library: ${output}`);
    const archive = targetRoot && within(targetRoot, 'catalog/source-theme-packs.json');
    if (archive && fs.existsSync(archive)) sourceThemeItems = JSON.parse(fs.readFileSync(archive, 'utf8')).items || [];
    if (partialRefresh) refreshNativeAssets(existing);
    else items.push(...existing.items.filter(item => item.category !== 'lua'
      && !/^(gta5|rdr2)-themes-(clickui-|stand-collection-|hosted-|preset-|builtin-|shared-)/.test(item.id)
      && !/^gta5-paintjob-native-/.test(item.id)
      && !/^rdr2-native-addon-/.test(item.id)
      && !/^redm-public-object-rsg-/.test(item.id)
      && item.id !== 'gta5-paintjob-scooby-livery-concept'
      && !/^gta5-(?:modverse-|mods-)/.test(item.id)));
    if (!partialRefresh) for (const item of items) if (item.game === 'cs2' && item.description) item.description = item.description.replace('Compiled knive model', 'Compiled knife model');
  } else {
    importCs2(); importRockstar('gta5'); importRockstar('rdr2'); importNenyooThemes(); importNativeThemes(); importGtaTextures(); importLegacyPresets(); importAddonCollection(); importOtherGames();
  }
  let marketplace = { summary: { preserved: true } };
  let nativePaintjobs = items.filter(item => item.nativePaintjob || item.id.startsWith('gta5-paintjob-native-')).length;
  let rdr2Addons = items.filter(item => item.id.startsWith('rdr2-native-addon-')).length;
  let publicRedm = { items: items.filter(item => item.id.startsWith('redm-public-object-rsg-')) };
  if (!partialRefresh) {
    importClickUiPalettes(); importStandCollections(); archiveSourceThemes();
    importNativeThemeCatalog({ sourceRoot, roots, items, add, plan, planSource, zip, themePreviews: THEME_PREVIEWS });
    marketplace = buildMarketplaceItems();
    for (const item of marketplace.items) add(item);
    for (const source of marketplace.sources) plan(source.path, source.data);
    nativePaintjobs = importNativePaintjobs();
    rdr2Addons = importRdr2Addons();
    publicRedm = collectPublicRedmObjects();
    for (const item of publicRedm.items) add(item);
    if (publicRedm.source) plan('catalog/redm-public-objects-source.json', JSON.stringify(publicRedm.source));
    importLiveryConcept();
  }
  for (const item of items) if (!partialRefresh || addedIds.has(item.id)) item.tags = tagsFor(item);
  if (!THEME_PREVIEWS) {
    for (const item of items.filter(item => item.category === 'themes')) {
      delete item.preview;
      delete item.previewCaption;
      delete item.previewKind;
    }
    for (const key of planned.keys()) if (key.startsWith('previews/themes/')) planned.delete(key);
  }
  for (const [game, root] of Object.entries(roots)) {
    if (game === 'nenyoo') continue;
    if (partialRefresh && !refreshGames.has(game)) continue;
    for (const name of ['LICENSE', 'LICENSE.md', 'LICENSE.txt']) {
      const file = path.join(root, name);
      if (fs.existsSync(file)) { plan(`catalog/licenses/${game}-source-license.txt`, fs.readFileSync(file)); break; }
    }
  }
  const manifest = { ...(partialRefresh ? existing : {}), version: 1, themePreviewsEnabled: THEME_PREVIEWS, downloadBaseUrl: BASE_URL, legacyDownloadBaseUrl: `${BASE_URL}downloads/gta5/`, items };
  const summary = { items: items.length, archivedSourceThemes: sourceThemeItems.length, refreshCatalog, refreshGames: [...refreshGames], byGame: {}, byCategory: {}, assetFiles: planned.size, assetBytes: [...planned.values()].reduce((s, b) => s + (Buffer.isBuffer(b) ? b.length : b.size), 0) };
  summary.marketplace = marketplace.summary;
  summary.nativePaintjobs = nativePaintjobs;
  summary.rdr2Addons = rdr2Addons;
  summary.publicRedmObjects = publicRedm.items.length;
  for (const item of items) { summary.byGame[item.game] = (summary.byGame[item.game] || 0) + 1; summary.byCategory[item.category] = (summary.byCategory[item.category] || 0) + 1; }
  summary.themesByStyle = {};
  summary.themePreviewKinds = {};
  for (const item of items.filter(item => item.category === 'themes')) {
    if (THEME_PREVIEWS && !item.preview) throw Error(`Theme has no preview: ${item.id}`);
    summary.themesByStyle[item.style] = (summary.themesByStyle[item.style] || 0) + 1;
    if (item.preview) summary.themePreviewKinds[item.previewKind || 'source'] = (summary.themePreviewKinds[item.previewKind || 'source'] || 0) + 1;
  }
  if (dryRun) { console.log(JSON.stringify({ dryRun: true, ...summary }, null, 2)); return; }
  recordResourceAdditions(manifest, existing ?? (fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : undefined));
  const json = Buffer.from(JSON.stringify(manifest));
  plan('catalog/library.json', json);
  plan('index.html', `<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=${DESTINATION}"><link rel="canonical" href="${DESTINATION}"><meta name="robots" content="noindex"><title>Scooby Resource Downloads</title></head><body><p>Opening <a href="${DESTINATION}">Scooby Resources</a>…</p></body></html>\n`);
  plan('README.md', `# Scooby Resource Downloads\n\nBrowse and search the collection at ${DESTINATION}\n\nThis repository stores asset downloads and catalog metadata. Its index.html redirects visitors to Scooby Resources. Direct raw file URLs remain usable.\n\n## Organization\n\n- downloads/<game>/<category>/ — installable configs, Lua packages, languages, themes, maps, textures and skies\n- previews/cs2/ — model artwork\n- catalog/library.json — website download catalog\n- catalog/cs2-models.json — complete original CS2 model metadata, hashes, credits and source terms\n- catalog/gta5-maps-source.json — bundled map collection source manifest\n\nGames use gta5, rdr2, cs2, fivem, redm and l4d identifiers. Categories without imported files remain available on the website. No game-project source code, DLLs, executables, build outputs or credentials are included.\n\nThird-party CS2 model payloads retain their publisher's download URLs and terms. Donor-generated variants are installed through Scooby's in-game Repo, using the matching local CS2 installation. Nenyoo theme bundles use their original Lua format and are labeled separately from Scooby themes.\n\n## Rebuilding\n\nFrom the dogsite checkout, run:\n\n    node tools/build-community-library.cjs --target <absolute-path-to-cool-repo> --dry-run\n    node tools/build-community-library.cjs --target <absolute-path-to-cool-repo>\n    node tools/build-community-library.cjs --target <absolute-path-to-cool-repo> --check\n\nUse --source-root <GitHub-directory> when the game projects are not sibling checkouts. The importer only reads explicit asset folders, preserves package paths and author metadata, rejects path traversal and symbolic links, and never deletes existing repository files.\n`);
  const readme = planned.get('README.md').toString('utf8')
    .replace('installable configs, Lua packages, languages', 'installable configs, languages')
    .replace('Nenyoo theme bundles use their original Lua format and are labeled separately from Scooby themes.', 'The active website catalog contains native Scooby resources and attributed third-party GTA mod listings. Nenyoo-only theme bundles remain stored for source reference in catalog/source-theme-packs.json and are excluded from catalog/library.json. Native Stand collections supported by Scooby are separate from those archived Nenyoo imports. Theme images are currently disabled in the site catalog.')
    + '\nImported Lua downloads are excluded from the active catalog and are not regenerated by this importer.\n'
    + '\nNative GTA 5 paintjobs are saved colour JSON presets from C:/scooby/GTA5/LSC/PaintJobs. Downloads preserve their original bytes and filenames. Install them into that folder or its matching colour subfolder, enter a vehicle, then use LSC Save/Load Paint Jobs. Livery images and GTA5-Mods paintjob listings use the separate liveries category. Use --paintjobs-root <folder> to rebuild from a different explicit native preset library.\n'
    + '\nNative RDR2 addon ZIPs retain install.xml, declared ped metadata, all streaming dependencies and original credits. Import through C:/scooby/RDR2/Addon Archives and the Addons/Replacements page. Editing projects, disabled replacements and backups are excluded. Use --rdr2-addons-root <folder> to select another explicit native asset library. Public RedM object resources remain original commit-pinned author downloads with verified byte hashes; their server/archetype requirements are recorded separately from native RDR2 compatibility.\n'
    + '\n## Bounded catalog refresh\n\nAfter a full import, update source-only theme metadata and native ClickUI color/Stand additions without rebuilding the existing library:\n\n    node tools/build-community-library.cjs --target <absolute-path-to-cool-repo> --refresh-catalog\n\nClickUI color presets export the host’s built-in palette data into color fields explicitly accepted by that host’s saved-theme loader. Back up the current theme before loading: native loader defaults and migrations may also apply. These are color presets rather than full copies of every native preset effect. Stand ZIP files retain their original profiles, scripts, supporting artwork and checksums. Shared Stand payloads are stored once under downloads/shared/themes/stand.\n';
  planned.set('README.md', Buffer.from(readme + '\nFor selected native game assets, add --refresh-games cs2,gta5,rdr2 to --refresh-catalog. This replaces only importer-owned model, config, language, map, layout-sample, texture and bundled-outfit rows from those projects. Marketplace entries, native PaintJobs, addon packs and other theme collections are preserved; their ordinary --refresh-catalog refresh remains available. Missing required sources abort before any writes. Use --output <library.json> for an isolated catalog destination.\n'));
  // Publish payloads and supporting catalogs before either final library index.
  for (const [relative, data] of planned) if (relative !== 'catalog/library.json') write(relative, data);
  write('catalog/library.json', json);
  atomicWrite(output, json);
  console.log(JSON.stringify({ ...summary, ...stats, manifest: output }, null, 2));
}
try { main(); } catch (error) { console.error(error.stack || error.message); process.exitCode = 1; }
