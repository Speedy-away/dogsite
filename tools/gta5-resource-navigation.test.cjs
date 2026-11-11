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
  assert(!gtaPages.some(page => page.menu === 'yim'), 'Yim is deferred');
  assert.deepEqual(menus.gtaCategoryGroups('yim', []), []);

  for (const menu of activeMenus) {
    const menuPages = gtaPages.filter(page => page.menu === menu.id);
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

  const xforceGroups = menus.gtaCategoryGroups('xforce', manifest.xforce);
  assert(xforceGroups[0][1].includes('themes'));
  assert(xforceGroups[1][1].includes('vehicles'));
  assert(!manifest.xforce.includes('paintjobs') && !manifest.xforce.includes('liveries'));
  assert(manifest.scooby.includes('paintjobs') && manifest.scooby.includes('liveries'));
  assert(menus.gtaCategoryGroups('scooby', manifest.scooby).at(-1)[1].includes('addon-vehicles'));
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

test('Old DLC paths redirect to the matching package collection', () => {
  assert(!gtaPages.some(page => page.category === 'dlc'));
  for (const [menu, category] of [['scooby', 'addon-packs'], ['nenyoo', 'addon-packs'], ['cherax', 'addon-packs'], ['xforce', 'addon-vehicles']]) {
    const page = gtaPages.find(page => page.menu === menu && page.category === category);
    assert(page?.samples.some(item => item.files.length && item.category === category), menu);
    const old = fs.readFileSync(path.join(root, route('gta5', 'dlc', menu), 'index.html'), 'utf8');
    assert(old.includes(`location.replace(${JSON.stringify(route('gta5', category, menu))} + location.search + location.hash)`), menu);
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
  assert(links.some(url => url.origin === origin && url.pathname === '/resources/' &&
    url.searchParams.get('game') === 'gta5' && (url.searchParams.get('menu') || 'scooby') === 'scooby' &&
    url.searchParams.get('category') === 'themes' && url.searchParams.get('ui') === 'clickui'));
});
