'use strict';
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const menus = require('../resources/menus.js');
const ROOT = path.resolve(__dirname, '..');
const games = ['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d'];
const names = ['library', 'menu-resources', 'gta5-editions', 'gta5-addons', 'resource-additions', 'nenyoo', 'scooby-lua', 'cherax-resources'];
const itemCatalogs = ['library', 'menu-resources', 'gta5-editions', 'gta5-addons', 'nenyoo', 'scooby-lua'];
const rewriteAssets = content => content.replace(/\/assets\/(?:downloads|images\/resource-previews)\/cherax\/[a-f0-9]{20}\.(?:lua|json|zip|rar|7z|webp)\b/g, url => 'https://raw.githubusercontent.com/Speedy-away/dogsite/main' + url);

function menuBundle(bundle, menu, game = 'gta5') {
  if (!games.includes(game) || !menus.menusFor(game).some(option => option.id === menu)) throw Error('Unknown resource menu');
  const supplement = game === 'gta5' ? menus.mergeCheraxResources(bundle['menu-resources'], bundle['cherax-resources']) : bundle['menu-resources'];
  const resolved = { ...bundle, 'menu-resources': supplement };
  const overrides = new Map((supplement.libraryOverrides || []).map(item => [item.id, item]));
  const entries = new Map();
  for (const name of itemCatalogs) {
    for (const item of resolved[name].items) {
      entries.set(item.id, { ...entries.get(item.id), ...item, ...(name === 'library' ? overrides.get(item.id) : {}) });
    }
  }
  const sources = new Set([...entries.values()].filter(item => item.game === 'gta5' && item.status !== 'author-hosted' && item.sourceUrl).map(item => item.sourceUrl));
  const selected = new Set([...entries.values()].filter(item => menus.supports(item, menu) &&
    !(item.id?.startsWith('gta5-author-addon-') && sources.has(item.sourceUrl))).map(item => item.id));
  const result = { ...resolved };
  for (const name of itemCatalogs) {
    const catalog = resolved[name];
    result[name] = { ...catalog, items: catalog.items.filter(item => selected.has(item.id)) };
    if (catalog.libraryOverrides) result[name].libraryOverrides = catalog.libraryOverrides.filter(item => selected.has(item.id));
    for (const field of ['verified', 'previews']) {
      if (catalog[field]) result[name][field] = Object.fromEntries(Object.entries(catalog[field]).filter(([id]) => selected.has(id)));
    }
  }
  // Imported assets are already resolved into the supplement. Keep the archive
  // marker for availability checks without sending a second copy of its data.
  result['cherax-resources'] = { version: 1, assetRevision: bundle['cherax-resources'].assetRevision, items: [], libraryOverrides: [] };
  // All legacy assignments remain: excluded menu records must not fall back to
  // their original default collection when legacy indexes are loaded.
  return result;
}

function build(root = ROOT) {
  const catalogs = Object.fromEntries(names.map(name => [name, JSON.parse(fs.readFileSync(path.join(root, 'community/data', name + '.json'), 'utf8'))]));
  const identities = new Map(Object.values(catalogs).flatMap(data => (data.items || []).map(item => [item.id, item.game])));
  const directory = path.join(root, 'community/data/games');
  fs.mkdirSync(directory, { recursive: true });
  return games.map(game => {
    const bundle = Object.fromEntries(names.map(name => {
      const source = catalogs[name];
      const data = { ...source };
      if (source.items) data.items = source.items.filter(item => item.game === game);
      if (source.libraryOverrides) data.libraryOverrides = source.libraryOverrides.filter(item => (item.game || identities.get(item.id)) === game);
      if (game !== 'gta5') {
        for (const key of ['legacyOverrides', 'legacyGroups', 'coverage']) if (source[key]) data[key] = [];
        for (const key of ['verified', 'previews']) if (source[key]) data[key] = {};
      }
      return [name, data];
    }));
    const output = rewriteAssets(JSON.stringify(bundle));
    const file = path.join(directory, game + '.json');
    if (!fs.existsSync(file) || fs.readFileSync(file, 'utf8') !== output) fs.writeFileSync(file, output);
    const compressed = zlib.gzipSync(output, { level: 9 });
    if (!fs.existsSync(file + '.gz') || !fs.readFileSync(file + '.gz').equals(compressed)) fs.writeFileSync(file + '.gz', compressed);
    const scoped = [];
    const menuChoices = menus.menusFor(game);
    const runtimeBundle = menuChoices.length > 1 ? JSON.parse(output) : null;
    if (runtimeBundle) for (const { id } of menuChoices) {
      const content = JSON.stringify(menuBundle(runtimeBundle, id, game));
      const packed = zlib.gzipSync(content, { level: 9 });
      const target = path.join(directory, `${game}-${id}.json.gz`);
      if (!fs.existsSync(target) || !fs.readFileSync(target).equals(packed)) fs.writeFileSync(target, packed);
      scoped.push({ menu: id, bytes: Buffer.byteLength(content), transferBytes: packed.length });
    }
    return { game, bytes: Buffer.byteLength(output), transferBytes: compressed.length, ...(scoped.length ? { menus: scoped } : {}) };
  });
}
module.exports = { build, menuBundle };
if (require.main === module) console.log(build());
