'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const vm = require('node:vm');
const menus = require('../resources/menus.js');
const supplement = require('../community/data/menu-resources.json');
const base = require('../community/data/library.json');
const ROOT = path.resolve(__dirname, '..');
test('resource guides retain the selected menu even when a shared item came from another menu', () => {
  const script = fs.readFileSync(path.join(ROOT, 'resources/catalog.js'), 'utf8');
  const implementation = script.match(/function guideURL\(entry\) \{[\s\S]+?(?=\nfunction link\()/)?.[0];
  assert(implementation);
  for (const selected of ['scooby', 'nenyoo', 'stand']) {
    const context = { URL, URLSearchParams, state: { game: 'gta5', category: 'themes', menu: selected }, location: { href: 'https://scoobymenu.cc/resources/' } };
    const guide = vm.runInNewContext(`(${implementation})`, context);
    for (const prefix of ['community', 'resources']) {
      const address = new URL(guide({ guide: `/${prefix}/guides/?game=gta5&menu=cherax&category=themes` }), context.location.href);
      assert.equal(address.pathname, '/resources/guides/');
      assert.equal(address.searchParams.get('menu'), selected);
      assert.equal(address.searchParams.get('category'), 'themes');
    }
  }
});
test('menu selection has a Scooby default and separates discovery from runtime requirements', () => {
  assert.equal(menus.menuFor('gta5', ''), 'scooby');
  assert.equal(menus.menuFor('gta5', 'X-Force'), 'xforce');
  assert.equal(menus.menuFor('cs2', 'stand'), 'scooby');
  assert(menus.MENUS.find(menu => menu.id === 'yim').deferred);
  const source = { game: 'gta5', category: 'lua', sourceMenu: 'cherax', supportedMenus: ['cherax'], listedMenus: ['cherax', 'scooby', 'nenyoo'] };
  assert(menus.supports(source, 'scooby'));
  assert(!menus.compatibleWith(source, 'scooby'));
  assert(!menus.supports(source, 'stand'));
  assert.deepEqual(menus.menuIds({ game: 'gta5', category: 'themes', menu: 'Scooby' }), ['scooby']);
});
test('new Lua listings have honest pending downloads, explicit source APIs and no Discord links', () => {
  const scripts = supplement.items.filter(item => item.category === 'lua' && item.game !== 'redm');
  assert(scripts.length >= 59);
  const ids = new Set();
  for (const item of scripts) {
    assert(!ids.has(item.id), item.id); ids.add(item.id);
    assert.equal(item.downloadStatus, 'pending', item.id);
    assert.deepEqual(item.files, [], item.id);
    assert.equal(item.sourceCatalog, 'menu-resources', item.id);
    assert(item.supportedMenus.length && item.sourceMenu, item.id);
    assert(menus.supports(item, 'scooby') && menus.supports(item, 'nenyoo'), item.id);
    assert(!/https?:\/\/(?:\w+\.)?discord(?:app)?\.(?:com|gg)/i.test(JSON.stringify(item)), item.id);
  }
  const notes = scripts.find(item => item.id === 'menu-cherax-lua-host-tools-1-9-0');
  assert.equal(notes.changelog[0].version, '1.9.0');
  assert.equal(notes.changelog[0].date, '2026-11-08');
  assert(notes.changelog[0].changes.length);
  assert(!base.items.some(item => item.category === 'lua'), 'Removed broken examples remain outside the base catalog');
});
test('reviewed RedM scripts download and preview-only menus have no payloads', () => {
  const redm = supplement.items.filter(item => item.game === 'redm');
  const catalog = require('../project/community-menu-sources/redm-submitted.json');
  for (const source of catalog.items) {
    const item = redm.find(entry => entry.id === source.id);
    assert(item, source.id);
    assert.equal(item.downloadStatus, source.downloadStatus);
    assert.deepEqual(item.files, source.files);
    assert.equal(item.preview, source.preview);
    assert(!item.sourceUrl, item.id);
  }
});
test('compatibility overrides reuse original resources and compact legacy groups preserve identities', () => {
  const originals = new Map(base.items.map(item => [item.id, item]));
  for (const override of supplement.libraryOverrides) assert(originals.has(override.id), override.id);
  const legacy = menus.legacyOverrideMap(supplement);
  assert(legacy.size >= 21021);
  assert(supplement.legacyGroups.length < legacy.size / 10, 'Repeated legacy metadata should be shared');
  const standKeys = new Set(require('../project/community-menu-sources/stand.json').legacyOverrides.map(item => `${item.family}:${item.index}`));
  for (const [key, value] of legacy) {
    assert.equal(key, `${value.family}:${value.index}`);
    if (standKeys.has(key)) assert(menus.supports({ ...value, game: 'gta5' }, 'stand'));
    assert(menus.supports({ ...value, game: 'gta5' }, 'scooby'));
  }
  assert(fs.statSync(path.join(ROOT, 'community/data/menu-resources.json')).size < 12 * 1024 * 1024);
});
test('BiggerScript collections augment existing downloads and preserve Stand origins', () => {
  const source = require('../project/community-menu-sources/biggerscript-public.json');
  const legacy = menus.legacyOverrideMap(supplement);
  const stand = new Map(require('../project/community-menu-sources/stand.json').legacyOverrides.map(item => [`${item.family}:${item.index}`, item]));
  assert.equal(supplement.items.filter(item => item.id.startsWith('gta5-biggerscript-')).length, source.items.length);
  for (const item of source.libraryOverrides) {
    const override = supplement.libraryOverrides.find(entry => entry.id === item.id);
    assert(override?.tags.includes('BiggerScript'), item.id);
    assert(!override.files, 'Existing map download identities remain unchanged');
  }
  for (const item of source.legacyOverrides) {
    const key = `${item.family}:${item.index}`, merged = legacy.get(key);
    assert(merged.tags.includes('BiggerScript'), key);
    assert.equal(merged.sourceUrl, item.sourceUrl);
    if (stand.has(key)) assert.equal(merged.sourceMenu, 'stand', key);
  }
});
test('verified source preview bytes are published to the allowlisted download repository', () => {
  const target = path.resolve(ROOT, '../cool-repo');
  assert.equal(fs.readFileSync(path.join(target, 'catalog/menu-resources.json'), 'utf8'), fs.readFileSync(path.join(ROOT, 'community/data/menu-resources.json'), 'utf8'));
  const checks = require('../project/community-menu-sources/cherax-network-checks.json');
  assert.equal(checks.entries.filter(entry => entry.files.some(file => file.verified)).length, 196);
  assert.equal(checks.entries.filter(entry => entry.preview).length, 160);
  const previews = new Set([...supplement.items, ...supplement.libraryOverrides].filter(item => item.previewVerified).map(item => item.preview));
  assert(previews.size > 150);
  for (const preview of previews) {
    assert(!preview.startsWith('project/'), 'Private source paths must not become public preview URLs');
    if (/^https:/.test(preview)) continue;
    const bytes = fs.readFileSync(path.join(preview.startsWith('/') ? ROOT : target, preview));
    assert(bytes.length > 0, preview);
  }
  for (const entry of checks.entries.filter(entry => entry.preview)) {
    const bytes = fs.readFileSync(path.join(ROOT, entry.preview.localPath));
    assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'), entry.preview.sha256);
  }
});
