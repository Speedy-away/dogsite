'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { createPublicationPlan, publish, parseArgs } = require('./publish-cherax-assets.cjs');
const ROOT = path.resolve(__dirname, '../..');
const SOURCES = 'project/community-menu-sources';
const FIXTURES = path.join(ROOT, SOURCES, 'cherax-publication-test');
const sha = body => crypto.createHash('sha256').update(body).digest('hex');
function setup() {
  fs.mkdirSync(FIXTURES, { recursive: true }); fs.writeFileSync(path.join(FIXTURES, '.gitignore'), '*\n');
  const fixture = fs.mkdtempSync(path.join(FIXTURES, 'run-'));
  const workspace = path.join(fixture, 'source'), target = path.join(fixture, 'target');
  fs.mkdirSync(target); fs.mkdirSync(path.join(target, 'catalog'));
  fs.writeFileSync(path.join(target, 'catalog/menu-resources.json'), '{"untouched":true}\n');
  fs.mkdirSync(path.join(workspace, SOURCES), { recursive: true });
  return { fixture, workspace, target, expectedTarget: target };
}
function index(f, stageName, assets) {
  const relative = `${SOURCES}/${stageName}/asset-index.json`, stageDirectory = `${SOURCES}/${stageName}`;
  fs.mkdirSync(path.dirname(path.join(f.workspace, relative)), { recursive: true });
  fs.writeFileSync(path.join(f.workspace, relative), JSON.stringify({ schemaVersion: 1, sourceMenu: 'Cherax', stageDirectory, assets }));
  return relative;
}
function asset(f, stageName, key, body, extension = '.json', magic = 'JSON', extras = {}) {
  const actual = { sha256: sha(body), size: body.length, extension, magic };
  const relative = `${extras.role === 'thumbnail' ? 'previews' : 'downloads'}/gta5/menus/cherax/${actual.sha256.slice(0, 20)}${extension}`;
  const localPath = `${SOURCES}/${stageName}/assets/${relative}`;
  fs.mkdirSync(path.dirname(path.join(f.workspace, localPath)), { recursive: true });
  fs.writeFileSync(path.join(f.workspace, localPath), body);
  return { assetKey: key, resourceId: 'fixture-resource', sourceId: 'fixture-source', sourceURL: 'https://example.com/resource', originalName: `fixture${extension}`, category: 'configs', role: 'payload', status: 'downloaded', targetRelativePath: relative, localPath, actual, ...extras };
}
function tree(dir) {
  const result = {};
  function visit(current) { for (const name of fs.readdirSync(current)) { const file = path.join(current, name), stat = fs.lstatSync(file); if (stat.isDirectory()) visit(file); else result[path.relative(dir, file)] = stat.isSymbolicLink() ? '[link]' : sha(fs.readFileSync(file)); } }
  visit(dir); return result;
}
test('read-only default and exact-target publication require explicit mode', () => {
  assert.equal(parseArgs([]).publish, false);
  assert.throws(() => parseArgs(['--publish']), /explicit --target/);
  assert.deepEqual(parseArgs(['--check', '--index', 'one', '--index', 'two']).indexes, ['one', 'two']);
  assert.throws(() => createPublicationPlan({ target: path.join(FIXTURES, 'wrong') }), /exact authorized/);
});
test('checks are read-only; publication deduplicates exact bytes and subsequent index additions preserve prior provenance', () => {
  const f = setup(), body = Buffer.from('{\r\n  "colour": "red"\r\n}\r\n');
  const a = asset(f, 'cherax-downloads', 'public:first', body);
  const duplicate = { ...a, assetKey: 'public:duplicate', sourceURL: 'https://example.com/other-source' };
  const image = asset(f, 'cherax-downloads', 'public:cover', Buffer.from([255, 216, 255, 224, 1, 2, 3]), '.jpg', 'JPEG', { role: 'thumbnail', previewEligible: false, publisherThumbnailKind: 'catalog_cover' });
  const firstIndex = index(f, 'cherax-downloads', [a, duplicate, image]);
  const before = tree(f.target), plan = createPublicationPlan({ ...f, indexes: [firstIndex] });
  assert.deepEqual(tree(f.target), before); assert.equal(plan.summary.uniqueFiles, 2); assert.equal(plan.summary.duplicateReferences, 1);
  const result = publish(plan); assert.equal(result.copied, 2);
  assert.deepEqual(fs.readFileSync(path.join(f.target, a.targetRelativePath)), body);
  assert.equal(fs.readFileSync(path.join(f.target, 'downloads/gta5/menus/cherax/.gitattributes'), 'utf8'), '* -text\n');
  assert.equal(fs.readFileSync(path.join(f.target, 'previews/gta5/menus/cherax/.gitattributes'), 'utf8'), '* -text\n');
  const lua = asset(f, 'cherax-export-downloads', 'discord:lua', Buffer.from('-- Source resource only\nreturn 1\n'), '.lua', 'UTF8-source-only', { category: 'lua' });
  const forbidden = asset(f, 'cherax-export-downloads', 'discord:blocked', Buffer.from('do not publish this\n'), '.txt', 'UTF8-text', { originalName: 'unsafe.ps1' });
  const secondIndex = index(f, 'cherax-export-downloads', [lua, forbidden]);
  const next = createPublicationPlan({ ...f, indexes: [secondIndex] });
  assert.equal(next.summary.retainedPriorRecords, 3); assert.equal(next.summary.downloadedRecords, 4); assert.equal(next.summary.pendingOrFailedRecords, 1);
  publish(next);
  const catalog = JSON.parse(fs.readFileSync(path.join(f.target, 'catalog/cherax-acquired-assets.json')));
  assert.equal(catalog.assets.length, 4); assert.equal(catalog.sourceIndexes.length, 2);
  assert.equal(catalog.assets.find(x => x.assetKey === 'public:duplicate').sourceURL, duplicate.sourceURL);
  assert.equal(catalog.assets.find(x => x.assetKey === 'public:cover').previewEligible, false);
  assert.equal(fs.readFileSync(path.join(f.target, 'catalog/menu-resources.json'), 'utf8'), '{"untouched":true}\n');
  assert(!fs.existsSync(path.join(f.target, forbidden.targetRelativePath)));
  assert.equal(createPublicationPlan({ ...f, indexes: [firstIndex, secondIndex] }).summary.filesToCopy, 0);
});
test('hash mismatch, destination collision, traversal and linked staging are rejected', () => {
  const f = setup(), a = asset(f, 'cherax-downloads', 'one', Buffer.from('{"ok":true}\n'));
  const idx = index(f, 'cherax-downloads', [a]);
  fs.writeFileSync(path.join(f.workspace, a.localPath), '{"ok":false}');
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /size mismatch|SHA-256 mismatch/);
  fs.writeFileSync(path.join(f.workspace, a.localPath), '{"ok":true}\n');
  fs.mkdirSync(path.dirname(path.join(f.target, a.targetRelativePath)), { recursive: true }); fs.writeFileSync(path.join(f.target, a.targetRelativePath), 'different');
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /size mismatch|SHA-256 mismatch/);
  fs.unlinkSync(path.join(f.target, a.targetRelativePath));
  index(f, 'cherax-downloads', [{ ...a, localPath: '../escape' }]);
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /not canonical/);
  index(f, 'cherax-downloads', [a]);
  const real = path.join(f.workspace, SOURCES, 'cherax-downloads/assets');
  const moved = path.join(f.workspace, SOURCES, 'kept-assets'); fs.renameSync(real, moved); fs.symlinkSync(moved, real, process.platform === 'win32' ? 'junction' : 'dir');
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /Linked path/);
});
test('split publication is bound to verified reconstruction bytes; orphan parts fail', () => {
  const f = setup(), original = Buffer.from('complete resource body split in two ordered parts');
  const reconstructionOf = { sha256: sha(original), size: original.length, name: 'large-resource.zip' };
  const parts = [original.subarray(0, 24), original.subarray(24)].map((body, i) => asset(f, 'cherax-export-downloads', `part:${i}`, body, '.part', 'split-part', { expectedKind: 'split-part', reconstructionOf }));
  const document = { schemaVersion: 1, type: 'binary-concatenation', original: reconstructionOf, partBytes: 95000000, parts: parts.map((p, i) => ({ partNumber: i + 1, targetRelativePath: p.targetRelativePath, size: p.actual.size, sha256: p.actual.sha256 })) };
  const manifest = asset(f, 'cherax-export-downloads', 'reconstruction', Buffer.from(JSON.stringify(document)), '.json', 'JSON', { expectedKind: 'reconstruction-manifest', reconstructionOf });
  const idx = index(f, 'cherax-export-downloads', parts);
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /no verified reconstruction/);
  index(f, 'cherax-export-downloads', [...parts, manifest]);
  const plan = createPublicationPlan({ ...f, indexes: [idx] }); assert.equal(plan.summary.uniqueFiles, 3); publish(plan);
  assert.equal(createPublicationPlan({ ...f, indexes: [idx] }).summary.filesToCopy, 0);
  const bad = { ...manifest, reconstructionOf: { ...reconstructionOf, sha256: 'f'.repeat(64) } };
  index(f, 'cherax-export-downloads', [...parts, bad]);
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /differs from index|different original/);
});
test('export provenance permits absent URLs, videos stay downloads, and known rejected Lua hashes become gaps', () => {
  const f = setup();
  const bytes = Buffer.concat([Buffer.from([0, 0, 0, 24]), Buffer.from('ftypisom'), Buffer.alloc(12)]);
  const ids = { sourceGuildId: '100000000000000001', sourceChannelId: '100000000000000002', sourceMessageId: '100000000000000003', sourceAttachmentId: '100000000000000004' };
  const video = asset(f, 'cherax-export-downloads', 'export:video', bytes, '.mp4', 'MP4', { ...ids, role: 'media', sourceURL: null, provenance: { guildId: ids.sourceGuildId, sourceKind: 'attachment' } });
  const badLua = asset(f, 'cherax-export-downloads', 'export:excluded-lua', Buffer.from('known excluded Lua source\n'), '.lua', 'UTF8-source-only', { category: 'lua' });
  fs.writeFileSync(path.join(f.workspace, SOURCES, 'cherax-lua-audit.json'), JSON.stringify({ exclusions: [{ sha256: badLua.actual.sha256, reason: 'Known rejected fixture source' }] }));
  const idx = index(f, 'cherax-export-downloads', [video, badLua]);
  const plan = createPublicationPlan({ ...f, indexes: [idx] });
  assert.equal(plan.summary.downloadedRecords, 1); assert.equal(plan.gaps.length, 1); assert.equal(plan.records[0].previewEligible, false);
  assert(video.targetRelativePath.startsWith('downloads/')); publish(plan);
  const again = createPublicationPlan({ ...f, indexes: [idx] });
  assert.equal(again.summary.filesToCopy, 0); assert.equal(again.records[0].sourceURL, null);
  assert(again.records[0].provenance.some(row => row.sourceAttachmentId === ids.sourceAttachmentId));
  assert(!fs.existsSync(path.join(f.target, badLua.targetRelativePath)));
});
test('art project sources are payloads and cannot be promoted to image previews', () => {
  const f = setup(), body = Buffer.from('gimp xcf v001\0source layers');
  const xcf = asset(f, 'cherax-export-downloads', 'art:xcf', body, '.xcf', 'XCF', { category: 'wallpapers' });
  const idx = index(f, 'cherax-export-downloads', [xcf]);
  assert.equal(createPublicationPlan({ ...f, indexes: [idx] }).summary.uniqueFiles, 1);
  const bad = asset(f, 'cherax-export-downloads', 'art:bad-preview', body, '.xcf', 'XCF', { category: 'wallpapers', role: 'thumbnail' });
  index(f, 'cherax-export-downloads', [bad]);
  assert.throws(() => createPublicationPlan({ ...f, indexes: [idx] }), /Non-image thumbnail/);
});
