const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const vm = require('node:vm');
const crypto = require('node:crypto');
const menus = require('../resources/menus.js');
const taxonomy = require('../resources/taxonomy.js');
const root = path.resolve(__dirname, '../community/data');

test('game bundles preserve catalog entries and metadata with lossless compressed fallbacks', () => {
  for (const game of ['gta5', 'rdr2', 'cs2', 'fivem', 'redm', 'l4d']) {
    const raw = fs.readFileSync(path.join(root, 'games', game + '.json'));
    const packed = fs.readFileSync(path.join(root, 'games', game + '.json.gz'));
    assert.deepEqual(zlib.gunzipSync(packed), raw);
    assert(packed.length < raw.length / 2);
    const bundle = JSON.parse(raw);
    for (const [name, catalog] of Object.entries(bundle)) {
      const source = JSON.parse(fs.readFileSync(path.join(root, name + '.json'), 'utf8'));
      if (!source.items) continue;
      // Published Cherax assets use the external host, matching the site packager.
      const expected = JSON.parse(JSON.stringify(source.items.filter(item => item.game === game))
        .replace(/\/assets\/(?:downloads|images\/resource-previews)\/cherax\/[a-f0-9]{20}\.(?:lua|json|zip|rar|7z|webp)\b/g,
          url => 'https://raw.githubusercontent.com/Speedy-away/dogsite/main' + url));
      assert.deepEqual(catalog.items, expected, game + ': ' + name);
      if (source.downloadBaseUrl) assert.equal(catalog.downloadBaseUrl, source.downloadBaseUrl);
    }
  }
});

test('menu bundles preserve every browser listing, version and detail while reducing transfer size', () => {
  const browser = fs.readFileSync(path.join(__dirname, '../resources/catalog.js'), 'utf8');
  const implementation = browser.match(/function libraryEntries\(supplement\) \{[\s\S]*?(?=\nfunction excludedRedMResource)/)?.[0];
  assert(implementation);
  const catalogs = ['library', 'menu-resources', 'gta5-editions', 'gta5-addons', 'nenyoo', 'scooby-lua'];
  function entries(bundle, menu, game, allCategories) {
    const context = {
      library: bundle.library, gtaEditionCatalog: bundle['gta5-editions'], gtaAddonCatalog: bundle['gta5-addons'],
      nenyooCatalog: bundle.nenyoo, scoobyLuaCatalog: bundle['scooby-lua'], menuSystem: menus, taxonomy,
      defaultAdditionDates: bundle['resource-additions'].defaults,
      historicalAdditionDates: new Map(Object.entries(bundle['resource-additions'].batches).flatMap(([date, ids]) => ids.map(id => [id, date]))),
      state: { game, menu }, categories: () => allCategories,
      supportsMenu: item => menus.supports(item, menu), categoryId: (game, id) => taxonomy.categoryId(game, id, menu),
      pendingDownload: item => item.category === 'lua' && item.downloadStatus === 'pending',
      authorPage: item => item.status === 'author-hosted' ? item.sourceUrl : '',
      excludedRedMResource: () => false, downloadURL: file => file.url || file.path || ''
    };
    vm.runInNewContext(implementation + '\nthis.getEntries = libraryEntries;', context);
    return context.getEntries(menus.mergeCheraxResources(bundle['menu-resources'], bundle['cherax-resources']))
      .sort((a, b) => a.id.localeCompare(b.id));
  }
  const digest = item => crypto.createHash('sha256').update(JSON.stringify(item, (_key, value) =>
    value && typeof value === 'object' && !Array.isArray(value) ? Object.fromEntries(Object.entries(value).sort(([a], [b]) => a.localeCompare(b))) : value)).digest('hex');
  for (const game of ['gta5', 'rdr2']) {
   const full = JSON.parse(fs.readFileSync(path.join(root, `games/${game}.json`), 'utf8'));
   const originalBytes = fs.statSync(path.join(root, `games/${game}.json.gz`)).size;
   const allCategories = [...new Set(catalogs.flatMap(name => full[name].items.flatMap(item => [item.category, ...(item.categories || [])])))];
   for (const { id } of menus.menusFor(game)) {
    const packed = fs.readFileSync(path.join(root, `games/${game}-${id}.json.gz`));
    assert(packed.length < originalBytes, id + ': scoped download must be smaller');
    const scope = JSON.parse(zlib.gunzipSync(packed));
    const expected = entries(full, id, game, allCategories), actual = entries(scope, id, game, allCategories);
    assert.equal(actual.length, expected.length, id + ': resource count');
    for (let index = 0; index < expected.length; index++) {
      assert.equal(actual[index].id, expected[index].id, id + ': resource identity');
      if (digest(actual[index]) !== digest(expected[index])) {
        const fields = [...new Set([...Object.keys(actual[index]), ...Object.keys(expected[index])])]
          .filter(key => JSON.stringify(actual[index][key]) !== JSON.stringify(expected[index][key]));
        for (const field of fields) console.log({ field, actual: JSON.stringify(actual[index][field])?.slice(0, 240), expected: JSON.stringify(expected[index][field])?.slice(0, 240) });
      }
      assert.equal(digest(actual[index]), digest(expected[index]), `${id}: changed browser metadata for ${expected[index].id}`);
    }
    assert.deepEqual(scope['menu-resources'].legacyGroups, full['menu-resources'].legacyGroups, id + ': preserve legacy assignments');
    assert.deepEqual(scope['resource-additions'], full['resource-additions'], id + ': preserve addition dates');
   }
  }
});
