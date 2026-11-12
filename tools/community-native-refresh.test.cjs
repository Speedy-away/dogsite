'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');

const IMPORTER = path.join(__dirname, 'build-community-library.cjs');
const SITE_LIBRARY = path.join(__dirname, '../community/data/library.json');
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'scooby-native-refresh-'));
  const source = path.join(root, 'sources'), target = path.join(root, 'downloads'), output = path.join(root, 'site/library.json');
  const cs2 = path.join(source, 'Scooby-Op/CS2/simple-base-cs2');
  const gta5 = path.join(source, 'Scooby-Op/GTA5/EE/GTA - Main Src');
  const rdr2 = path.join(source, 'Scooby-Op/RDR2/Scooby-RDR2-old - before-UI-update - working');
  function put(file, data) { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, typeof data === 'object' && !Buffer.isBuffer(data) ? JSON.stringify(data) : data); }
  function file(relative, data) { const bytes = Buffer.from(data); put(path.join(target, relative), bytes); return { path: relative, name: path.basename(relative), size: bytes.length, sha256: digest(bytes) }; }
  function seed(items) { const manifest = { version: 1, fixtureMetadata: { retained: true }, items }; put(output, manifest); put(path.join(target, 'catalog/library.json'), manifest); }
  function run(games, extra = []) { return spawnSync(process.execPath, [IMPORTER, '--target', target, '--source-root', source, '--output', output, '--refresh-catalog', '--refresh-games', games, ...extra], { encoding: 'utf8', windowsHide: true }); }
  function read() { return JSON.parse(fs.readFileSync(output, 'utf8')); }
  t.after(() => {
    // Delete only this explicitly created temporary fixture directory.
    assert.equal(path.dirname(path.resolve(root)), path.resolve(os.tmpdir()));
    assert(path.basename(root).startsWith('scooby-native-refresh-'));
    fs.rmSync(root, { recursive: true, force: true });
  });
  return { root, source, target, output, cs2, gta5, rdr2, put, file, seed, run, read };
}
function item(id, game, category, files = [], extra = {}) { return { id, game, category, name: id, menu: 'Scooby', tags: ['existing-tag'], files, ...extra }; }
function cs2Sources(f, packages) {
  f.put(path.join(f.cs2, 'assets/custom_models/catalog.json'), { version: 1, packages });
  for (const directory of ['configs', 'hud-presets', 'vfx/materials/scooby_vfx/sky', 'vfx/source-images']) fs.mkdirSync(path.join(f.cs2, 'assets', directory), { recursive: true });
  f.put(path.join(f.cs2, 'assets/vfx/README.md'), 'Fixture procedural artwork attribution.');
}
function tree(root) {
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root, { withFileTypes: true }).flatMap(entry => entry.isDirectory() ? tree(path.join(root, entry.name)) : [[path.relative(root, path.join(root, entry.name)), digest(fs.readFileSync(path.join(root, entry.name)))]]);
}

test('CS2 refresh adds/updates source packages and payloads while preserving unrelated catalogs', t => {
  const f = fixture(t), realBefore = digest(fs.readFileSync(SITE_LIBRARY));
  const originalDate = '2025-11-10T09:00:00Z';
  const preserved = [
    item('gta5-paintjob-native-kept', 'gta5', 'paintjobs', [f.file('downloads/gta5/paintjobs/kept.json', '{}')], { nativePaintjob: true }),
    item('gta5-mods-author-kept', 'gta5', 'addon-vehicles'),
    item('gta5-themes-hosted-kept', 'gta5', 'themes'),
    item('rdr2-outfit-kept', 'rdr2', 'outfits', [f.file('downloads/rdr2/outfits/kept.json', '{}')]),
    item('rdr2-native-addon-kept', 'rdr2', 'addon-peds'),
    item('menu-cs2-author-config', 'cs2', 'configs'),
  ];
  f.seed([...preserved,
    item('cs2-model-alpha', 'cs2', 'weapons', [], { name: 'Old Alpha', addedAt: originalDate }),
    item('cs2-model-retired', 'cs2', 'weapons'),
    item('cs2-configs-retired', 'cs2', 'configs', [f.file('downloads/cs2/configs/retired.json', '{}')]),
    item('cs2-misc-hud-night', 'cs2', 'misc', [f.file('downloads/cs2/misc/hud-night.json', '{"old":true}')]),
    item('cs2-texture-cloud', 'cs2', 'textures', [f.file('downloads/cs2/textures/cloud.png', 'old artwork')]),
    item('cs2-skyboxes-cloud', 'cs2', 'skyboxes', [f.file('downloads/cs2/skyboxes/cloud.zip', 'old sky')]),
    item('old-native-lua', 'cs2', 'lua'),
  ]);
  const packages = [
    { id: 'alpha', name: 'Updated Alpha', category: 'weapons', group: 'knife', url: 'https://example.org/alpha.zip', images: [{ path: 'art/alpha.png' }] },
    { id: 'new-player', name: 'New Player', category: 'players', url: 'https://example.org/player.zip' },
  ];
  cs2Sources(f, packages);
  f.put(path.join(f.cs2, 'assets/custom_models/art/alpha.png'), 'new model artwork');
  f.put(path.join(f.cs2, 'assets/configs/new.json'), { aim: 'fixture' });
  f.put(path.join(f.cs2, 'assets/hud-presets/night.json'), { updated: true });
  f.put(path.join(f.cs2, 'assets/vfx/source-images/cloud.png'), 'new texture artwork');
  f.put(path.join(f.cs2, 'assets/vfx/materials/scooby_vfx/sky/cloud.vmat_c'), 'new material');
  f.put(path.join(f.cs2, 'assets/vfx/materials/scooby_vfx/sky/cloud.vtex_c'), 'new sky texture');
  f.put(path.join(f.cs2, 'assets/scripts/excluded.lua'), 'error("This fixture must never execute")');
  const result = f.run('cs2');
  assert.equal(result.status, 0, result.stderr);
  const catalog = f.read(), byId = new Map(catalog.items.map(row => [row.id, row]));
  assert.deepEqual(catalog.fixtureMetadata, { retained: true });
  for (const row of preserved) assert.deepEqual(byId.get(row.id), row);
  assert.equal(byId.get('cs2-model-alpha').name, 'Updated Alpha');
  assert.equal(byId.get('cs2-model-alpha').category, 'knives');
  assert.equal(byId.get('cs2-model-alpha').addedAt, originalDate);
  assert.equal(byId.get('cs2-model-new-player').category, 'players');
  assert(Date.parse(byId.get('cs2-model-new-player').addedAt) > Date.parse(originalDate));
  assert(!byId.has('cs2-model-retired'));
  assert(!byId.has('cs2-configs-retired'));
  assert(byId.has('cs2-configs-new'));
  assert(catalog.items.every(row => row.category !== 'lua'));
  assert(!fs.existsSync(path.join(f.target, 'downloads/cs2/lua')));
  assert.equal(fs.readFileSync(path.join(f.target, byId.get('cs2-model-alpha').preview), 'utf8'), 'new model artwork');
  assert.equal(fs.readFileSync(path.join(f.target, byId.get('cs2-texture-cloud').files[0].path), 'utf8'), 'new texture artwork');
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(f.target, 'catalog/cs2-models.json'), 'utf8')).packages, packages);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(f.target, 'catalog/library.json'), 'utf8')), catalog);
  assert.equal(digest(fs.readFileSync(SITE_LIBRARY)), realBefore, 'fixture must not touch the actual site catalog');
  const unchanged = fs.readFileSync(f.output);
  assert.equal(f.run('cs2').status, 0);
  assert(fs.readFileSync(f.output).equals(unchanged), 'unchanged source refresh is repeatable');
  assert.equal(f.run('cs2', ['--check']).status, 0, 'generated byte sizes and hashes must verify');
});

test('CS2 refresh keeps downloadable and locally generated pet packs in Pets with their source and models', t => {
  const f = fixture(t);
  const addedAt = '2025-11-10T09:00:00Z';
  f.seed([item('cs2-model-pets-pack', 'cs2', 'weapons', [], { addedAt })]);
  const fox = 'models/pets/fox.vmdl', rabbit = 'models/pets/rabbit.vmdl';
  const downloadUrl = 'https://example.org/pets.zip', sourceUrl = 'https://example.org/pets';
  const packages = [
    { id: 'pets-pack', name: 'Forest Pet Pack', category: 'pets', resourcePath: fox, resourcePaths: [fox, rabbit],
      source: 'Author site', author: 'Example Author', license: 'CC BY 4.0', page: sourceUrl, url: downloadUrl },
    { id: 'local-pet', name: 'Local Cat', category: 'weapons', group: 'pet', resourcePath: 'models/pets/cat.vmdl',
      source: 'Local CS2', license: 'Build locally from installed assets', page: 'https://example.org/local-cat',
      url: 'https://example.org/unused-local-cat.zip', localSource: { vpkPart: 'fixture' },
      images: [{ path: 'art/local-cat.jpg' }] },
  ];
  cs2Sources(f, packages);
  f.put(path.join(f.cs2, 'assets/custom_models/models/pets/cat.vmdl_c'), 'private donor asset');
  f.put(path.join(f.cs2, 'assets/custom_models/art/local-cat.jpg'), 'locally generated preview');
  const result = f.run('cs2');
  assert.equal(result.status, 0, result.stderr);
  const rows = f.read().items;
  const [download, local] = packages.map(pack => rows.find(row => row.id === `cs2-model-${pack.id}`));
  assert.equal(download.category, 'pets');
  assert.equal(download.addedAt, addedAt);
  assert.deepEqual(download.resourcePaths, [fox, rabbit]);
  assert.deepEqual(download.files, [{ url: downloadUrl, name: 'pets-pack.zip' }]);
  assert.equal(download.source, 'Author site');
  assert.equal(download.sourceUrl, sourceUrl);
  assert.equal(download.credits, 'Example Author');
  assert.equal(download.license, 'CC BY 4.0');
  assert.equal(local.category, 'pets');
  assert.equal(local.status, 'in-menu');
  assert.deepEqual(local.resourcePaths, ['models/pets/cat.vmdl']);
  assert.deepEqual(local.files, []);
  assert.equal(local.preview, undefined);
  assert.equal(local.source, 'Local CS2');
  assert.equal(local.sourceUrl, 'https://example.org/local-cat');
  assert.equal(local.license, 'Build locally from installed assets');
  assert(!fs.existsSync(path.join(f.target, 'downloads/cs2')));
  assert(!fs.existsSync(path.join(f.target, 'previews/cs2/local-pet.jpg')));
});

test('missing or malformed selected sources fail before catalog or asset mutation', t => {
  const f = fixture(t);
  f.seed([item('cs2-model-retained', 'cs2', 'players'), item('gta5-author-retained', 'gta5', 'vehicles')]);
  const before = fs.readFileSync(f.output), targetBefore = tree(f.target);
  let result = f.run('cs2');
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Required native refresh source/);
  cs2Sources(f, []);
  f.put(path.join(f.cs2, 'assets/custom_models/catalog.json'), { notPackages: [] });
  result = f.run('cs2');
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /packages array/);
  f.put(path.join(f.cs2, 'assets/custom_models/catalog.json'), { packages: [{ id: 'new', name: 'New', category: 'players' }] });
  result = f.run('cs2,gta5');
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Required native refresh source/);
  assert(fs.readFileSync(f.output).equals(before));
  assert.deepEqual(tree(f.target), targetBefore);
});

test('Rockstar refresh extracts maps without Lua examples and refreshes native data only', t => {
  const f = fixture(t);
  const preserved = [item('gta5-themes-preset-thirdparty', 'gta5', 'themes'), item('gta5-mods-original', 'gta5', 'vehicles'), item('cs2-model-untouched', 'cs2', 'players')];
  f.seed(preserved);
  for (const root of [f.gta5, f.rdr2]) {
    f.put(path.join(root, 'Translations/en_US.json'), { hello: 'Hello' });
    f.put(path.join(root, 'assets/listui-layouts/Default.json'), { reference: true });
  }
  f.put(path.join(f.gta5, 'configs/default.json'), { native: true });
  f.put(path.join(f.gta5, 'assets/maps/BiggerScriptMaps.json.zlib'), zlib.deflateSync(JSON.stringify([{ path: 'Example/Placement.xml', xml: '<SpoonerPlacements />' }])));
  f.put(path.join(f.gta5, 'assets/maps/IniMaps.json.zlib'), zlib.deflateSync('[]'));
  f.put(path.join(f.gta5, 'assets/maps/manifest.json'), { source: 'fixture maps' });
  f.put(path.join(f.rdr2, 'src/game/frontend/submenus/outfiteditor/BundledOutfits.cpp'), 'const BundledOutfit g_BundledOutfits[] = {\n{"Fixture Outfit", "Male", R"json({"1":2,"compatibility":{"gender":true}})json"}\n};');
  const result = f.run('gta5,rdr2');
  assert.equal(result.status, 0, result.stderr);
  const rows = f.read().items;
  for (const row of preserved) assert.deepEqual(rows.find(value => value.id === row.id), row);
  assert(rows.some(row => row.game === 'gta5' && row.category === 'maps'));
  assert(rows.some(row => row.id === 'rdr2-outfit-male-fixture-outfit'));
  assert.equal(rows.filter(row => row.category === 'languages').length, 2);
  assert.equal(rows.filter(row => row.id.endsWith('-listui-layout-sample')).length, 2);
  assert(rows.every(row => row.category !== 'lua'));
});
