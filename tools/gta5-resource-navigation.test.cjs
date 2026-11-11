'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const menus = require('../resources/menus.js');
const editions = require('../resources/editions.js');
const { tagsFor } = require('../resources/taxonomy.js');
const { buildData, renderPage, route } = require('./resource-pages.cjs');

const root = path.resolve(__dirname, '..');
const origin = 'https://scoobymenu.cc';
const activeMenus = menus.MENUS.filter(menu => !menu.deferred);
const { pages, items } = buildData();
const gtaPages = pages.filter(page => page.game === 'gta5');

function categorySidebar(html) {
  const sidebar = html.match(/<nav class="resource-category-links"[^>]*>([\s\S]*?)<\/nav>/)?.[1];
  assert(sidebar, 'Resource page is missing its category sidebar');
  return [...sidebar.matchAll(/<p class="category-group-label">([^<]+)<\/p>([\s\S]*?)<\/div>/g)]
    .map(([, label, links]) => [label, [...links.matchAll(/<a href="([^"]+)"/g)].map(([, href]) => href)]);
}

test('GTA 5 category manifest and static sidebars follow the published menu routes', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'resources/gta5/categories.json'), 'utf8'));
  assert.deepEqual(Object.keys(manifest).sort(), activeMenus.map(menu => menu.id).sort());
  assert.deepEqual(manifest.yim, ['lua', 'vehicles', 'outfits', 'maps', 'pack-vehicles', 'pack-outfits', 'pack-maps']);
  assert.deepEqual(manifest.yimv2, ['lua']);

  for (const menu of activeMenus) {
    const menuPages = gtaPages.filter(page => page.menu === menu.id && !page.archive);
    const home = menuPages.find(page => !page.category);
    assert(home, `${menu.name} collection page is missing`);
    const categoryPages = menuPages.filter(page => page.category);
    assert.deepEqual([...manifest[menu.id]].sort(), categoryPages.map(page => page.category).sort(), menu.name);

    const groups = menus.gtaCategoryGroups(menu.id, manifest[menu.id]);
    assert.equal(groups[0]?.[0], `${menu.name} Files`);
    assert.deepEqual(groups.flatMap(([, ids]) => ids).sort(), [...manifest[menu.id]].sort(), menu.name);

    const sidebar = groups.map(([label, ids]) => [label, ids.map(id => route('gta5', id, menu.id))]);
    assert.deepEqual(categorySidebar(renderPage(home)), sidebar, menu.name);
    for (const page of menuPages) {
      assert.deepEqual(categorySidebar(fs.readFileSync(path.join(root, page.file), 'utf8')), sidebar, page.file);
    }
  }

  const archive = gtaPages.find(page => page.menu === 'stand' && page.archive && !page.category);
  assert(archive, 'Stand Old Shares is missing');
  const archivePaths = categorySidebar(renderPage(archive)).flatMap(([, hrefs]) => hrefs);
  for (const category of ['outfits', 'vehicles', 'lua', 'themes']) {
    assert(archivePaths.includes(route('gta5', category, 'stand', 'old-shares')), category);
  }
  assert(archive.samples.every(item => item.oldShares));
  assert.match(renderPage(gtaPages.find(page => page.menu === 'stand' && !page.category && !page.archive)), /href="\/resources\/gta5\/stand\/old-shares\/">Old Shares/);

  const xforceGroups = menus.gtaCategoryGroups('xforce', manifest.xforce);
  assert(xforceGroups[0][1].includes('themes'));
  assert(xforceGroups[1][1].includes('vehicles'));
  assert(!manifest.xforce.includes('paintjobs') && !manifest.xforce.includes('liveries'));
  assert(manifest.scooby.includes('paintjobs') && manifest.scooby.includes('liveries'));
  assert(new Map(menus.gtaCategoryGroups('scooby', manifest.scooby)).get('Addons').includes('addon-vehicles'));
});

test('Yim v1 and v2 have separate script listings and site-hosted downloads', () => {
  const manifest = require('../project/community-menu-sources/yim.json');
  for (const [menu, version, edition] of [['yim', 'v1', 'legacy'], ['yimv2', 'v2', 'enhanced']]) {
    const page = gtaPages.find(page => page.menu === menu && page.category === 'lua');
    assert(page, menu);
    const html = fs.readFileSync(path.join(root, page.file), 'utf8');
    const scripts = items.filter(item => item.sourceMenu === menu && item.category === 'lua');
    assert(scripts.length > 0, menu);
    assert.equal(scripts.length, manifest.items.filter(item => item.sourceMenu === menu && item.category === 'lua').length);
    assert.equal(page.samples.length, scripts.length);
    assert.doesNotMatch(html, /https?:\/\/[^"\s]*github/i);
    const dates = [...html.matchAll(/Last updated <time datetime="([^"]+)">/g)].map(([, date]) => Date.parse(date));
    assert.equal(dates.length, scripts.length);
    assert(dates.every((date, index) => Number.isFinite(date) && (index === 0 || dates[index - 1] >= date)), menu);
    const keywords = new Set(page.keywords.split(', '));
    for (const item of scripts) {
      assert.equal(item.category, 'lua', item.id);
      assert.equal(item.downloadStatus, 'available', item.id);
      assert.deepEqual(activeMenus.filter(option => menus.supports(item, option.id)).map(option => option.id), [menu], item.id);
      assert(keywords.has(item.name), item.id);
      assert(tagsFor(item).includes(`yimmenu ${version} lua scripts`), item.id);
      assert(item.files.every(file => html.includes(file.url) && fs.existsSync(path.join(root, file.url))), item.id);
      if (menu === 'yimv2') {
        assert.equal(item.editionSupport, edition, item.id);
        assert(item.files.every(file => file.url.endsWith('-enhanced.zip')), item.id);
      }
      if (item.preview) assert(fs.existsSync(path.join(root, item.preview)), item.id);
      for (const file of item.imagePaths || []) {
        const url = item.imageBaseUrl + file;
        assert(html.includes(url) && fs.existsSync(path.join(root, url)), item.id);
      }
    }
  }
  assert(tagsFor(items.find(item => item.id === 'menu-yim-lua-yimlls')).includes('lua language server'));
  assert(tagsFor(items.find(item => item.id === 'menu-yim-lua-solomissions')).includes('solo heists'));
});

test('YimMenu resources and installation guide have canonical search metadata and sitemap links', () => {
  const sitemap = fs.readFileSync(path.join(root, 'sitemap.xml'), 'utf8');
  const directory = fs.readFileSync(path.join(root, 'sitemap/index.html'), 'utf8');
  const hub = fs.readFileSync(path.join(root, 'resources/index.html'), 'utf8');
  for (const [menu, version, folder] of [['yim', 'v1', 'YimMenu'], ['yimv2', 'v2', 'YimMenuV2']]) {
    assert(hub.includes(`YimMenu ${version} Lua scripts`));
    const guide = `/resources/guides/gta5/${menu}/${menu === 'yim' ? 'lua/' : ''}`;
    for (const href of [`/resources/gta5/${menu}/`, `/resources/gta5/${menu}/lua/`, guide]) {
      const html = fs.readFileSync(path.join(root, href.slice(1), 'index.html'), 'utf8');
      assert(html.match(/<title>([^<]*)<\/title>/)?.[1].includes(href === guide ? `YimMenu ${version}` : menus.menuName(menu)), href);
      assert.match(html, new RegExp(`name="keywords" content="[^"]*YimMenu ${version} Lua`));
      assert.match(html, new RegExp(`property="og:description" content="[^"]*YimMenu ${version}`));
      assert(html.includes(`<link rel="canonical" href="${origin + href}">`), href);
      assert(sitemap.includes(`<loc>${origin + href}</loc>`), href);
      assert(directory.includes(`href="${href}"`), href);
      if (href === guide) assert(html.includes(`%AppData%\\${folder}\\scripts`), href);
      else if (href.endsWith('/lua/')) assert(html.includes(`href="${guide}"`), href);
    }
    if (menu === 'yimv2') assert(!sitemap.includes(`<loc>${origin}${guide}lua/</loc>`));
  }
});

test('Yim v1 preset packs use the payload format and a local archive', () => {
  const packs = items.filter(item => item.id.startsWith('menu-yim-preset-'));
  assert.equal(packs.length, 7);
  for (const [category, formats] of [['vehicles', ['json', 'json', 'json', 'json', 'xml']], ['maps', ['xml']], ['outfits', ['json']]]) {
    const page = gtaPages.find(page => page.menu === 'yim' && page.category === category);
    const html = fs.readFileSync(path.join(root, page.file), 'utf8');
    const listed = packs.filter(item => item.category === category);
    assert.deepEqual(listed.flatMap(menus.formatExtensions).sort(), formats);
    assert(html.includes(`href="/resources/guides/gta5/yim/${category}/"`), category);
    for (const item of listed) {
      assert.deepEqual(menus.listingMenuIds(item), ['yim']);
      assert.equal(item.files.length, 1, item.id);
      const file = item.files[0];
      assert.match(file.url, /^\/assets\/downloads\/yim\/[^/]+\.(?:zip|rar)$/i);
      assert.equal(fs.statSync(path.join(root, file.url)).size, file.size, item.id);
      assert(html.includes(file.url), item.id);
    }
  }
});

test('Original Cherax ClickGUI packages appear only in the Cherax collection', () => {
  const clickGuiPackages = items.filter(item => item.game === 'gta5' && item.category === 'themes' &&
    item.sourceMenu === 'cherax' && /clickgui/i.test(item.format || ''));
  assert(clickGuiPackages.length, 'The catalog must retain its original Cherax ClickGUI packages');
  for (const theme of clickGuiPackages) {
    const visibleMenus = activeMenus.filter(menu => menus.supports(theme, menu.id)).map(menu => menu.id);
    assert.deepEqual(visibleMenus, ['cherax'], theme.id);
    assert.equal(menus.compatibleWith(theme, 'scooby'), false, theme.id);
    assert.match(theme.requirementLabel || theme.compatibility, /Cherax ClickGUI/i, theme.id);
  }
  const cheraxPage = gtaPages.find(page => page.menu === 'cherax' && page.category === 'themes');
  assert(cheraxPage?.samples.some(theme => clickGuiPackages.includes(theme)));
});

test('GTA 5 menu-specific files stay in the correct collections, including presets filed as themes', () => {
  const examples = [
    ['gta5-themes-preset-x-force-c83fe600c57be6', 'xforce', 'configs'],
    ['gta5-themes-preset-x-force-916c2877143fa1', 'xforce', 'configs'],
    ['gta5-themes-preset-x-force-0b0c53c775d593', 'xforce', 'configs'],
    ['gta5-xforce-discord-70b867c8612eae15fafa', 'xforce', 'languages'],
    ['gta5-configs-scooby-gta5-default-config', 'scooby', 'configs'],
    ['gta5-languages-ar-sa', 'scooby', 'languages'],
    ['gta5-nenyoo-languages-lang-cn-json', 'nenyoo', 'languages'],
    ['gta5-lua-stand-legacy-collection-manager', 'stand', 'lua'],
    ['gta5-lua-stand-legacy-chat-translator', 'stand', 'lua'],
    ['cherax-lua-body-accessories', 'cherax', 'lua']
  ];
  for (const [id, origin, category] of examples) {
    const entry = items.find(item => item.id === id);
    assert(entry, id);
    const legacyListing = { ...entry, listedMenus: activeMenus.map(menu => menu.id) };
    assert.deepEqual(activeMenus.filter(menu => menus.supports(legacyListing, menu)).map(menu => menu.id), [origin], id);
    const sourcePage = gtaPages.find(page => page.menu === origin && page.category === category);
    assert(sourcePage, `${origin}/${category}`);
    assert(!gtaPages.some(page => page.menu !== origin && page.samples.includes(entry)), id);
  }

  const sharedMap = items.find(item => item.id === 'gta5-map-silkworld-0e1ef783');
  assert(sharedMap);
  assert.deepEqual(activeMenus.filter(menu => menus.supports(sharedMap, menu)).map(menu => menu.id), ['scooby', 'nenyoo', 'cherax', 'stand']);
  assert.match(menus.presetLoaderNote(sharedMap, 'cherax'), /BiggerScript.*Lua/);
  assert.match(menus.presetLoaderNote(sharedMap, 'stand'), /Constructor.*Lua/);
  assert.equal(menus.presetLoaderNote(sharedMap, 'scooby'), '');
  assert.equal(menus.presetLoaderNote(sharedMap, 'nenyoo'), '');
});

test('GTA 5 menu pages separate native presets from files that require Lua', () => {
  for (const [menu, nativeExtension] of [['cherax', 'json'], ['stand', 'txt']]) {
    for (const category of ['vehicles', 'outfits']) {
      const page = gtaPages.find(page => page.menu === menu && page.category === category);
      assert(page.samples.length);
      assert(page.samples.every(item => menus.presetLoader(item, menu) === 'native'));
      assert(page.samples.some(item => menus.formatExtensions(item).includes(nativeExtension)));
    }
    const maps = gtaPages.find(page => page.menu === menu && page.category === 'maps');
    assert(maps.samples.length && maps.samples.every(item => menus.presetLoader(item, menu) === 'lua'));
    assert.match(renderPage(maps), /These presets require a compatible Lua loader/);
    const vehicles = gtaPages.find(page => page.menu === menu && page.category === 'vehicles');
    assert.match(renderPage(vehicles), /\?format=lua-loader#collection/);
  }
  const construct = items.find(item => item.game === 'gta5' && item.category === 'vehicles' && (item.sourceFormat || item.format) === 'Constructor / entity-children JSON');
  assert(construct, 'The catalog has a Constructor JSON example');
  assert(menus.formatExtensions(construct).includes('json'));
  assert.equal(menus.presetLoader(construct, 'cherax'), 'lua', 'Constructor JSON is not a native Cherax export');
});

test('native GTA 5 preset views keep other formats available through the filter', () => {
  for (const [menu, ext, otherFilter] of [['cherax', 'json', 'lua-loader'], ['stand', 'txt', 'lua-loader'], ['xforce', 'ini', 'all-formats']]) {
    const vehicles = gtaPages.find(page => page.menu === menu && page.category === 'vehicles');
    assert(vehicles.samples.length && vehicles.samples.every(item => menus.presetLoader(item, menu) === 'native'), menu);
    assert(vehicles.samples.some(item => menus.formatExtensions(item).includes(ext)), menu);
    assert(renderPage(vehicles).includes(`?format=${otherFilter}#collection`), menu);
    const maps = gtaPages.find(page => page.menu === menu && page.category === 'maps');
    assert(maps.samples.length && maps.samples.every(item => menus.alternatePreset(item, menu)), menu);
  }
  const construct = items.find(item => item.id === 'gta5-biggerscript-vehicles-203edf293b8b02cd');
  assert(menus.formatExtensions(construct).includes('json'));
  assert.equal(menus.presetLoader(construct, 'cherax'), 'lua');
  assert.equal(menus.presetLoader(construct, 'nenyoo'), '');
  const menyoo = items.find(item => item.id === 'gta5-xforce-discord-e0aef81c32fbc91549c6');
  assert.equal(menus.presetLoader(menyoo, 'xforce'), 'importer');
});

test('Nenyoo source assets stay with their game and menu, and RDR2 links both collections', () => {
  const snapshot = require('../community/data/nenyoo.json');
  const imported = items.filter(item => item.source === 'Nenyoo Resources');
  assert.equal(imported.length, snapshot.items.length);
  assert(imported.some(item => item.game === 'gta5' && item.category === 'themes' && item.previewVerified && item.status === 'author-hosted'));
  for (const item of imported) {
    assert(menus.supports(item, 'nenyoo') && !menus.supports(item, 'scooby'), item.id);
    const source = new URL(item.sourceUrl);
    const folder = item.category === 'loader-translations' ? 'Loader' : item.game === 'rdr2' ? 'RDR2' : 'GTAV';
    assert(source.pathname.includes(`/${snapshot.commit}/${folder}/`), item.id);
  }
  assert.deepEqual(menus.menusFor('rdr2').map(menu => menu.id), ['scooby', 'nenyoo']);
  const rdr2 = pages.filter(page => page.game === 'rdr2');
  for (const menu of ['scooby', 'nenyoo']) {
    const home = rdr2.find(page => page.menu === menu && !page.category);
    const html = fs.readFileSync(path.join(root, home.file), 'utf8');
    assert(html.includes('href="/resources/rdr2/"') && html.includes('href="/resources/rdr2/nenyoo/"'));
    assert.deepEqual(categorySidebar(html), menus.categoryGroups(menu, home.categories.map(category => category.id))
      .map(([label, ids]) => [label, ids.map(id => route('rdr2', id, menu))]));
    const sourceCategory = menu === 'nenyoo' ? 'loader-translations' : 'outfits';
    assert(rdr2.some(page => page.menu === menu && page.category === sourceCategory && page.samples.some(item => item.files.length)));
  }
  const nenyoo = gtaPages.find(page => page.menu === 'nenyoo' && !page.category);
  const groups = menus.categoryGroups('nenyoo', nenyoo.categories.map(category => category.id));
  assert.deepEqual(groups.map(([label]) => label), ['Nenyoo Files', 'Nenyoo Resources', 'Addons', 'Packs']);
  assert.deepEqual(menus.categoryGroups('nenyoo', ['asi-mods', 'addon-packs']), [['Nenyoo Resources', ['asi-mods']], ['Packs', ['addon-packs']]]);
});

test('Nenyoo theme galleries use the original artwork and retain their catalog previews', () => {
  const snapshot = require('../community/data/nenyoo.json');
  const themes = snapshot.items.filter(item => item.category === 'themes');
  for (const theme of themes) {
    const folder = new URL(theme.imageBaseUrl);
    assert.equal(folder.hostname, 'raw.githubusercontent.com');
    assert(folder.pathname.includes(`/${snapshot.commit}/GTAV/Themes/`));
    assert(theme.imagePaths.length, theme.name);
    assert.equal(new Set(theme.imagePaths).size, theme.imagePaths.length, theme.name);
    assert.equal(theme.preview, theme.imageBaseUrl + theme.imagePaths[0].split('/').map(encodeURIComponent).join('/'));
  }
  const theme = themes.find(item => item.name === '2Take1');
  assert(theme.imagePaths.includes('textures/header.bmp'));
  const page = gtaPages.find(page => page.menu === 'nenyoo' && page.category === 'themes');
  const html = fs.readFileSync(path.join(root, page.file), 'utf8');
  assert(html.includes(`Images (${theme.imagePaths.length})`));
  assert(html.includes(`${theme.imageBaseUrl}textures/header.bmp`));
});

test('Nenyoo Lua is split by game and Stand-style Nenyoo themes retain their galleries', () => {
  const nenyooLua = items.filter(item => item.source === 'Nenyoo Resources' && item.category === 'lua');
  const gta = nenyooLua.filter(item => item.game === 'gta5');
  const rdr = nenyooLua.filter(item => item.game === 'rdr2');
  assert(gta.some(item => item.files.some(file => /\/GTAV\/Scripts\//.test(file.url))));
  assert(rdr.length && rdr.every(item => item.builtInLua && !item.files.length && /\/RDR2\/Lua\//.test(item.sourceUrl)));
  for (const [game, entries] of [['gta5', gta], ['rdr2', rdr]]) {
    const page = pages.find(entry => entry.game === game && entry.menu === 'nenyoo' && entry.category === 'lua');
    assert.equal(page.itemCount, entries.length);
    assert(page.samples.every(item => entries.includes(item)));
    const html = fs.readFileSync(path.join(root, page.file), 'utf8');
    assert(html.includes(`href="${route(game === 'gta5' ? 'rdr2' : 'gta5', 'lua', 'nenyoo')}"`));
    assert(html.includes('View module source'));
  }
  const themes = items.filter(item => item.game === 'gta5' && item.category === 'themes' && menus.supports(item, 'nenyoo'));
  assert(themes.every(item => menus.compatibleWith(item, 'nenyoo')));
  assert(themes.some(item => item.style === 'Stand' && item.sourceMenu === 'nenyoo' && item.imagePaths?.length));
});

test('Old DLC paths stay in the selected menu and prefer its package collection', () => {
  assert(!gtaPages.some(page => page.category === 'dlc'));
  for (const [menu, category] of [['scooby', 'addon-packs'], ['nenyoo', 'addon-packs'], ['cherax', 'addon-vehicles'], ['stand', 'addon-vehicles'], ['xforce', 'addon-vehicles']]) {
    const page = gtaPages.find(page => page.menu === menu && page.category === category);
    if (page) assert(page.samples.some(item => item.category === category && (item.files.length || item.status === 'author-hosted')), menu);
    if (['cherax', 'stand', 'xforce'].includes(menu)) assert(page, menu);
    const old = fs.readFileSync(path.join(root, route('gta5', 'dlc', menu), 'index.html'), 'utf8');
    assert(old.includes(`location.replace(${JSON.stringify(route('gta5', page?.category, menu))} + location.search + location.hash)`), menu);
  }
  assert(items.some(item => item.name === '875993 stew car' && item.category === 'addon-vehicles' && item.files.length));
});

test('GTA 5 addon expansion preserves source downloads, previews and edition evidence', () => {
  const additions = items.filter(item => item.id.startsWith('gta5-author-addon-'));
  assert(additions.filter(item => item.category === 'addon-vehicles').length >= 300);
  assert(additions.some(item => item.category === 'addon-peds'));
  assert.equal(new Set(additions.map(item => item.sourceUrl)).size, additions.length);
  for (const item of additions) {
    assert.equal(item.status, 'author-hosted');
    assert.equal(new URL(item.sourceUrl).hostname, 'www.gta5-mods.com');
    assert.equal(new URL(item.preview).hostname, 'img.gta5-mods.com');
    assert.equal(item.files.length, 0);
    if (editions.support(item)) {
      assert.equal(item.editionSource, item.sourceUrl);
      assert(tagsFor(item).includes(item.editionSupport));
    }
  }
  for (const edition of ['legacy', 'enhanced', 'both']) assert(additions.some(item => editions.support(item) === edition));
});

test('GTA 5 addon navigation lists vehicle packs for Cherax and Stand and broader assets for Scooby and Nenyoo', () => {
  const addonPages = menu => gtaPages.filter(page => page.menu === menu && page.category?.startsWith('addon-'));
  const [cherax] = addonPages('cherax');
  const [stand] = addonPages('stand');
  assert.deepEqual(addonPages('cherax').map(page => page.category), ['addon-vehicles']);
  assert.deepEqual(addonPages('stand').map(page => page.category), ['addon-vehicles']);
  assert(cherax.samples.some(item => item.sourceFormat === 'Vehicle DLC archive (RPF7)' && item.files.length));
  assert(cherax.samples.some(item => item.status === 'author-hosted'));
  assert(stand.samples.every(item => item.category === 'addon-vehicles'));
  assert(!menus.compatibleWith(stand.samples.find(item => item.status === 'author-hosted'), 'stand'));

  for (const menu of ['scooby', 'nenyoo']) {
    const pages = addonPages(menu);
    for (const category of ['addon-vehicles', 'addon-peds', 'addon-weapons', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing']) {
      assert(pages.some(page => page.category === category), `${menu} ${category}`);
    }
  }
});

test('Stand keeps packs in their own group and CoaLwiX starts the release ZIP download', () => {
  const home = gtaPages.find(page => page.menu === 'stand' && !page.category);
  const groups = new Map(menus.categoryGroups('stand', home.categories.map(category => category.id)));
  assert.deepEqual(groups.get('Addons'), ['addon-vehicles']);
  assert.deepEqual(groups.get('Packs'), ['pack-vehicles', 'pack-outfits', 'pack-all-in-one', 'pack-maps']);
  const pack = gtaPages.find(page => page.menu === 'stand' && page.category === 'pack-all-in-one');
  const [coalwix] = pack.samples;
  assert.equal(coalwix.name, 'CoaLwiX Pack');
  assert.equal(coalwix.status, 'download');
  assert.equal(coalwix.files.length, 1);
  assert.match(coalwix.files[0].url, /^https:\/\/github\.com\/landnthrn\/CoaLwiX\/releases\/download\/[^/]+\/CoaLwiX\.THE\.ULTIMATE\.SUPREME\.PACKAGE\.zip$/);
  const html = fs.readFileSync(path.join(root, pack.file), 'utf8');
  const card = html.match(/<article[^>]+id="resource-gta5-stand-addon-packs-coalwix"[\s\S]*?<\/article>/)[0];
  assert(card.includes('href="' + coalwix.files[0].url + '" download='));
  assert.doesNotMatch(card, /By landnthrn|Edition unlisted|<p>Packs<\/p>|Get from the author/);
  const old = fs.readFileSync(path.join(root, 'resources/gta5/stand/addon-packs/index.html'), 'utf8');
  assert(old.includes('location.replace("/resources/gta5/stand/pack-all-in-one/" + location.search + location.hash)'));
});

test('Cherax ListUI themes preserve the verified interfaces and the collection filter', () => {
  const page = gtaPages.find(page => page.menu === 'cherax' && page.category === 'themes');
  const themes = items.filter(item => menus.isCheraxTheme(item) && [].concat(menus.themeInterface(item)).includes('ListUI'));
  assert(themes.some(item => item.name === 'Impulse ListUI' && menus.themeInterface(item) === 'ListUI'));
  const red = themes.find(item => item.name === 'Transparent Red');
  assert.deepEqual(menus.themeInterface(red), ['ClickGUI', 'ListUI']);
  assert(themes.every(item => menus.compatibleWith(item, 'cherax') && !menus.supports(item, 'scooby')));
  assert.match(renderPage(page), /ui=listui[^"]*">Browse Cherax ListUI themes/);
});

test('Scooby Themes keeps native ClickUI colors and compatible ListUI styles', () => {
  const scoobyPage = gtaPages.find(page => page.menu === 'scooby' && page.category === 'themes');
  assert(scoobyPage, 'Scooby Themes route is missing');
  const native = items.find(item => item.id === 'gta5-themes-clickui-scoobycyan');
  assert(native, 'Scooby Cyan ClickUI colors are missing from the catalog');
  assert.equal(native.uiStyle, 'ClickUI');
  assert(menus.supports(native, 'scooby') && menus.compatibleWith(native, 'scooby'));

  const style = items.find(item => item.game === 'gta5' && item.category === 'themes' && item.name === 'Cherax · Stand');
  assert(style, 'Cherax · Stand ListUI style is missing from the catalog');
  assert.equal(style.uiStyle, 'ListUI');
  assert(menus.supports(style, 'scooby') && menus.compatibleWith(style, 'scooby'));

  assert(scoobyPage.samples.some(theme => theme.uiStyle === 'ClickUI' && menus.compatibleWith(theme, 'scooby')));
  const html = fs.readFileSync(path.join(root, scoobyPage.file), 'utf8');
  const links = [...html.matchAll(/<a\b[^>]*\bhref="([^"]+)"/g)]
    .map(([, href]) => new URL(href.replace(/&amp;/g, '&'), origin));
  assert(links.some(url => url.origin === origin && url.pathname === '/resources/gta5/themes/' &&
    url.search === '?ui=clickui'));
});
