'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { loadConfig, inventory, syncOnce } = require('./resource-sync.cjs');
const { importInbox } = require('./import-resource-inbox.cjs');
function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'scooby-resource-sync-'));
  const source = path.join(root, 'cs2/catalog.json');
  fs.mkdirSync(path.dirname(source), { recursive: true });
  fs.writeFileSync(source, '{"packages":[]}');
  const target = path.join(root, 'downloads'); fs.mkdirSync(target);
  const configFile = path.join(root, 'sources.json');
  fs.writeFileSync(configFile, JSON.stringify({ version: 1, sourceRoot: '.', downloadRepository: 'downloads', inbox: 'inbox', sources: [
    { id: 'cs2', kind: 'native', games: ['cs2'], required: 'cs2/catalog.json', paths: ['cs2/catalog.json'] },
    { id: 'unavailable', kind: 'native', games: ['gta5'], required: 'missing-project', paths: ['missing-project'] }
  ] }));
  return { root, source, target, config: loadConfig(configFile, root) };
}
test('source updates are incremental, read-only checks do not checkpoint, and changed CS2 selects its importer', () => {
  const { config, source } = fixture(), calls = [];
  assert.deepEqual(syncOnce({ config, check: true }).changedSources, ['cs2']);
  assert(!fs.existsSync(config.stateFile));
  const first = syncOnce({ config, run: (script, args) => calls.push({ script, args }) });
  assert(first.updated);
  assert(calls[0].args.includes('--refresh-games'));
  assert.equal(calls[0].args.at(-1), 'cs2');
  assert(first.unavailable.includes('unavailable'));
  assert.deepEqual(inventory(config).changed, []);
  calls.length = 0;
  assert(!syncOnce({ config, run: () => assert.fail('Unchanged sources must not rebuild') }).updated);
  fs.writeFileSync(source, '{"packages":[{"id":"new-model"}]}');
  assert.deepEqual(inventory(config).changed.map(source => source.id), ['cs2']);
  syncOnce({ config, run: (script, args) => calls.push({ script, args }) });
  assert.equal(calls.filter(call => call.script.endsWith('build-community-library.cjs')).length, 1);
});
test('failed imports restore published catalogs and keep the source pending for retry', () => {
  const { root, target, config } = fixture();
  const site = path.join(root, 'community/data/library.json'), mirrored = path.join(target, 'catalog/library.json');
  for (const file of [site, mirrored]) { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, '{"items":[{"id":"previous"}]}'); }
  assert.throws(() => syncOnce({ config, run: () => { fs.writeFileSync(site, '{"items":[]}'); fs.writeFileSync(mirrored, '{"items":[]}'); throw Error('Invalid input'); } }), /Invalid input/);
  assert.equal(fs.readFileSync(site, 'utf8'), '{"items":[{"id":"previous"}]}');
  assert.equal(fs.readFileSync(mirrored, 'utf8'), fs.readFileSync(site, 'utf8'));
  assert(!fs.existsSync(config.stateFile));
  assert.equal(inventory(config).changed.length, 1);
  assert(!fs.existsSync(path.join(path.dirname(config.stateFile), 'sync.lock')));
});
test('simultaneous game and shared-resource changes run both refresh scopes', () => {
  const { config, root } = fixture(), shared = path.join(root, 'paintjob.json');
  fs.writeFileSync(shared, '{}');
  config.sources.push({ id: 'paintjobs', kind: 'native', games: [], paths: ['paintjob.json'] });
  const calls = [];
  syncOnce({ config, run: (script, args) => calls.push({ script, args }) });
  const refreshes = calls.filter(call => call.script.endsWith('build-community-library.cjs'));
  assert.equal(refreshes.length, 2);
  assert(refreshes.some(call => call.args.includes('--refresh-games')));
  assert(refreshes.some(call => !call.args.includes('--refresh-games')));
});

test('an edit arriving during an import remains pending for the next update', () => {
  const { config, source } = fixture();
  let changed = false;
  syncOnce({ config, run: () => {
    if (!changed) { fs.writeFileSync(source, '{"packages":[{"id":"arrived-during-build"}]}'); changed = true; }
  } });
  assert.deepEqual(inventory(config).changed.map(source => source.id), ['cs2']);
  syncOnce({ config, run: () => {} });
  assert.deepEqual(inventory(config).changed, []);
});

test('removing the last inbox file still refreshes the existing empty inbox', () => {
  const { config, root } = fixture(), folder = path.join(root, 'inbox'), item = path.join(folder, 'last.txt');
  fs.mkdirSync(folder); fs.writeFileSync(item, 'last resource');
  config.sources.push({ id: 'inbox', kind: 'inbox', paths: ['inbox'] });
  syncOnce({ config, run: () => {} });
  fs.unlinkSync(item);
  assert.deepEqual(inventory(config).changed.map(source => source.id), ['inbox']);
  const calls = [];
  syncOnce({ config, run: script => calls.push(script) });
  assert(calls.includes('tools/import-resource-inbox.cjs'));
});

test('a failed first run restores absence of newly created catalogs', () => {
  const { config, root } = fixture(), file = path.join(root, 'community/data/library.json');
  assert.throws(() => syncOnce({ config, run: () => {
    fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, '{"items":[]}'); throw Error('Failed first import');
  } }), /Failed first import/);
  assert(!fs.existsSync(file));
});

test('changes to referenced source images are detected without a manifest edit', () => {
  const { config, root } = fixture();
  const relative = 'project/community-menu-sources/redm/previews/original.png';
  const image = path.join(root, relative), manifest = path.join(root, 'project/community-menu-sources/redm.json');
  fs.mkdirSync(path.dirname(image), { recursive: true }); fs.writeFileSync(image, 'original image');
  fs.writeFileSync(manifest, JSON.stringify({ items: [{ preview: relative, previewVerified: true }] }));
  config.sources.push({ id: 'menu-media', kind: 'menus', paths: ['project/community-menu-sources/redm.json'] });
  syncOnce({ config, run: () => {} });
  assert.deepEqual(inventory(config).changed, []);
  fs.writeFileSync(image, 'replacement original image');
  assert.deepEqual(inventory(config).changed.map(source => source.id), ['menu-media']);
});
test('inbox adds real files/bundles, preserves companion paths and keeps Lua pending', () => {
  const { root } = fixture(), inbox = path.join(root, 'inbox'), stage = path.join(root, 'staged');
  const write = (relative, bytes) => { const file = path.join(inbox, relative); fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, bytes); };
  write('gta5/cherax/vehicles/Car.json', '{"format":"Cherax Entity","model":123}');
  write('gta5/cherax/lua/Example.lua', 'error("not executed")');
  write('redm/scooby/sound-packs/Example pack/resource.json', '{"name":"Example pack","credits":"Original author"}');
  write('redm/scooby/sound-packs/Example pack/files/audio/sound.awc', Buffer.from([1, 2, 3]));
  write('redm/scooby/scopes/faster-scope.xml', '<scope/>');
  const result = importInbox(inbox, { stageRoot: stage, output: path.join(root, 'inbox-output.json') });
  assert.equal(result.items.length, 3);
  const script = result.items.find(item => item.category === 'lua');
  assert.equal(script.downloadStatus, 'pending'); assert.deepEqual(script.files, []);
  const sound = result.items.find(item => item.category === 'sound-packs');
  assert.equal(sound.game, 'redm'); assert.equal(sound.credits, 'Original author');
  const local = path.resolve(__dirname, '..', sound.files[0].localPath);
  const bytes = fs.readFileSync(local);
  assert(bytes.includes(Buffer.from('audio/sound.awc')), 'ZIP paths must keep the resource tree');
  assert(result.coverage[0].excluded.some(file => file.includes('faster-scope')));
  const firstId = result.items.find(item => item.category === 'vehicles').id;
  write('gta5/cherax/vehicles/Car.json', '{"format":"Cherax Entity","model":456}');
  const updated = importInbox(inbox, { stageRoot: stage, output: path.join(root, 'inbox-output.json') });
  assert.equal(updated.items.find(item => item.category === 'vehicles').id, firstId);
});
test('CS2 Pets inbox adds and edits multi-model packs and locally generated references', () => {
  const { root } = fixture(), inbox = path.join(root, 'inbox');
  const options = { stageRoot: path.join(root, 'staged'), output: path.join(root, 'inbox-output.json') };
  const write = (relative, bytes) => {
    const file = path.join(inbox, relative);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, bytes);
  };
  const pack = 'cs2/scooby/pets/Companion pack';
  const reference = 'cs2/scooby/pets/Local companions';
  const modelPaths = ['models/pets/owl.vmdl_c', 'models/pets/rabbit.vmdl_c'];
  const metadata = {
    name: 'Companion pack', credits: 'Pack creator', license: 'CC BY 4.0',
    sourceUrl: 'https://example.test/companions', resourcePaths: modelPaths
  };
  const localMetadata = {
    name: 'Local companions', status: 'in-menu', author: 'Recipe creator', license: 'See the local asset terms',
    source: 'Installed CS2', requirements: ['Matching installed CS2 assets'],
    resourcePaths: ['models/pets/companion.vmdl']
  };
  write(`${pack}/resource.json`, JSON.stringify(metadata));
  for (const model of modelPaths) write(`${pack}/files/${model}`, `Test bytes for ${model}`);
  const material = 'materials/pets/shared.vmat_c';
  write(`${pack}/files/${material}`, 'Test material bytes');
  write(`${reference}/resource.json`, JSON.stringify(localMetadata));
  write('cs2/scooby/players/Agent.vmdl_c', 'Test player model bytes');
  write('cs2/stand/pets/Other.vmdl_c', 'Test model bytes');
  write('gta5/scooby/pets/Other.vmdl_c', 'Test model bytes');

  const first = importInbox(inbox, options).items;
  assert.equal(first.length, 3);
  assert(first.some(item => item.category === 'players'));
  const download = first.find(item => item.name === metadata.name);
  assert.equal(download.game, 'cs2');
  assert.equal(download.category, 'pets');
  assert.equal(download.credits, metadata.credits);
  assert.equal(download.license, metadata.license);
  assert.equal(download.sourceUrl, metadata.sourceUrl);
  assert.deepEqual(download.resourcePaths, modelPaths);
  assert.equal(download.files.length, 1);
  assert.equal(download.files[0].name, 'Companion pack.zip');
  const archive = fs.readFileSync(path.resolve(__dirname, '..', download.files[0].localPath));
  for (const file of [...modelPaths, material]) assert(archive.includes(Buffer.from(file)), file);
  const local = first.find(item => item.name === localMetadata.name);
  assert.equal(local.status, 'in-menu');
  assert.equal(local.author, localMetadata.author);
  assert.equal(local.credits, localMetadata.author);
  assert.equal(local.license, localMetadata.license);
  assert.equal(local.source, localMetadata.source);
  assert.deepEqual(local.requirements, localMetadata.requirements);
  assert.deepEqual(local.resourcePaths, localMetadata.resourcePaths);
  assert.deepEqual(local.files, []);

  write(`${pack}/resource.json`, JSON.stringify({ ...metadata, name: 'Companion pack revised' }));
  write(`${pack}/files/${modelPaths[0]}`, 'Updated test model bytes');
  write(`${reference}/resource.json`, JSON.stringify({ ...localMetadata, requirements: ['Updated local asset requirement'] }));
  const edited = importInbox(inbox, options).items;
  const revisedDownload = edited.find(item => item.id === download.id);
  assert.equal(revisedDownload.name, 'Companion pack revised');
  assert.notEqual(revisedDownload.files[0].localPath, download.files[0].localPath);
  const revisedReference = edited.find(item => item.id === local.id);
  assert.deepEqual(revisedReference.requirements, ['Updated local asset requirement']);
  assert.deepEqual(revisedReference.files, []);
});
test('invalid new JSON does not replace the last prepared inbox manifest', () => {
  const { root } = fixture(), inbox = path.join(root, 'inbox'), file = path.join(inbox, 'gta5/scooby/outfits/Broken.json'), output = path.join(root, 'prepared.json');
  fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, '{'); fs.writeFileSync(output, '{"items":[{"id":"keep"}]}');
  assert.throws(() => importInbox(inbox, { stageRoot: path.join(root, 'stage'), output }));
  assert.equal(fs.readFileSync(output, 'utf8'), '{"items":[{"id":"keep"}]}');
});
