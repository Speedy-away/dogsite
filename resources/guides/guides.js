(() => {
  'use strict';

  const $ = id => document.getElementById(id);
  const menus = window.ScoobyMenus;
  const taxonomy = window.ScoobyTaxonomy;
  const routes = window.ScoobyResourceRoutes;
  const GAMES = {
    gta5: { name: 'GTA 5' },
    rdr2: { name: 'RDR2', assets: ['outfits', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps'] },
    cs2: { name: 'CS2', assets: ['players', 'weapons', 'knives', 'throwables', 'bombs', 'skyboxes', 'textures'] },
    fivem: { name: 'FiveM', assets: ['vehicles', 'outfits', 'maps', 'textures', 'sound-packs', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing'] },
    redm: { name: 'RedM', assets: ['outfits', 'weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings', 'maps', 'textures', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps'] },
    l4d: { name: 'L4D', assets: ['players', 'weapons', 'maps', 'textures', 'skyboxes', 'sound-packs'] }
  };
  const LABELS = {
    all: 'All guides', vehicles: 'Vehicles', modded: 'Modded vehicles', outfits: 'Outfits',
    'addon-vehicles': 'Vehicles', 'addon-peds': 'Peds', 'addon-objects': 'Objects', 'addon-animations': 'Animations', 'addon-maps': 'Maps', 'addon-clothing': 'Clothing', maps: 'Maps', textures: 'Textures',
    paintjobs: 'Paintjobs', liveries: 'Liveries', 'asi-mods': 'ASI mods', 'dotnet-mods': '.NET mods',
    players: 'Player models', weapons: 'Weapon models', knives: 'Knife models', throwables: 'Throwables',
    bombs: 'Bombs', skyboxes: 'Skyboxes', themes: 'Themes', configs: 'Configs', lua: 'Lua scripts',
    languages: 'Translations / Languages', wallpapers: 'Wallpapers', 'addon-packs': 'Packs', misc: 'Miscellaneous',
    'loader-translations': 'Loader translations', fonts: 'Fonts', emotes: 'Emote audio',
    'weapon-models': 'Weapon models/skins', 'sound-packs': 'Sound packs', 'graphics-packs': 'Graphics packs',
    'ui-presets': 'UI presets', 'visual-effects': 'Visual effects', scopes: 'Scopes', settings: 'Settings',
    'mod-menus': 'Lua Menus', triggers: 'Triggers', 'server-dumps': 'Server dumps'
  };
  const FILES = ['themes', 'configs', 'lua', 'languages', 'wallpapers', 'misc'];
  const sections = [...document.querySelectorAll('.guide-topics > section')];
  const collectionLinks = document.querySelectorAll('a[href="/resources/"]');
  const pluginLinks = document.querySelectorAll('[data-resource-category]');
  const mobile = matchMedia('(max-width: 760px)');
  let publishedRoutes = new Set(Object.keys(GAMES).map(game => routes.collectionPath(game)));
  let publishedGuides = Object.fromEntries(Object.keys(GAMES).map(game => [routes.guidePath(game), routes.guidePath(game)]));
  const menuCategories = {};
  let state = readState();

  function hasMenuChoice(game) { return menus.menusFor(game).length > 1; }
  function roleplayGroups(game) { return taxonomy?.roleplayCategoryGroups?.(game, [...GAMES[game].assets, ...FILES]); }
  function categories(game, menu) {
    if (game === 'rdr2' && menu === 'scooby') return [...GAMES[game].assets, ...FILES];
    if (hasMenuChoice(game)) return menuCategories[game]?.[menu] || [];
    const groups = roleplayGroups(game);
    return groups ? groups.flatMap(([, ids]) => ids) : [...GAMES[game].assets, ...FILES];
  }
  function categoryFor(game, menu, requested) {
    if (requested === 'all' || categories(game, menu).includes(requested)) return requested;
    return hasMenuChoice(game) ? 'all' : GAMES[game].assets[0];
  }
  function contains(value, candidate) { return String(value || '').split(/\s+/).some(part => part === 'all' || part === candidate); }
  function relevant(section, game, category, menu) {
    return contains(section.dataset.games, game) && contains(section.dataset.menus || 'scooby', menu) &&
      (category === 'all' || contains(section.dataset.categories, category));
  }
  function targetSection() {
    try { const target = $(decodeURIComponent(location.hash.slice(1))); return sections.includes(target) ? target : null; }
    catch { return null; }
  }
  function readState() {
    const params = new URLSearchParams(location.search);
    const target = targetSection();
    const targetGame = String(target?.dataset.games || '').split(/\s+/).find(game => Object.hasOwn(GAMES, game));
    const game = Object.hasOwn(GAMES, params.get('game')) ? params.get('game') : targetGame || 'gta5';
    const targetMenu = String(target?.dataset.menus || '').split(/\s+/).find(id => menus.MENUS.some(menu => menu.id === id));
    const menu = menus.menuFor(game, params.get('menu') || targetMenu);
    const choices = categories(game, menu);
    const requested = taxonomy?.categoryId(game, params.get('category'), menu) ?? params.get('category');
    if (hasMenuChoice(game)) {
      const linkedSection = target && relevant(target, game, 'all', menu);
      const targetCategory = linkedSection && target.dataset.categories.split(/\s+/).find(category => choices.includes(category));
      const defaultCategory = game === 'gta5' ? 'vehicles' : menu === 'scooby' ? 'outfits' : 'all';
      const category = categoryFor(game, menu, requested || (linkedSection ? targetCategory || 'all' : defaultCategory));
      return { game, category, menu };
    }
    const targetCategory = contains(target?.dataset.games, game) ? String(target?.dataset.categories || '').split(/\s+/).find(category => choices.includes(category)) : '';
    const category = requested === 'all' || choices.includes(requested) ? requested : targetCategory || GAMES[game].assets[0];
    return { game, category, menu };
  }
  function address(game, category, menu = state.menu) {
    return routes.guideURL({ game, category, menu: menus.menuFor(game, menu) }, publishedGuides);
  }
  function saveState() {
    const published = address(state.game, state.category);
    if (published !== routes.guideBase) { location.assign(published); return; }
    const url = `${routes.guideBase}?${new URLSearchParams(state)}`;
    if (location.pathname + location.search !== url) history.pushState({}, '', url);
  }
  function restoreState() {
    state = readState();
    if (menuCategories[state.game]) {
      const url = new URL(location.href);
      if (url.searchParams.has('category') && url.searchParams.get('category') !== state.category) {
        url.searchParams.set('category', state.category);
        history.replaceState(history.state, '', url);
      }
    }
    update();
  }
  function node(tag, text, className) {
    const element = document.createElement(tag);
    if (text) element.textContent = text;
    if (className) element.className = className;
    return element;
  }
  function categoryLink(category, label = LABELS[category]) {
    const choice = node('a', label, 'category-choice');
    choice.href = address(state.game, category);
    choice.dataset.category = category;
    choice.setAttribute('aria-current', state.category === category ? 'page' : 'false');
    choice.onclick = event => {
      if (event.button > 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      if (choice.pathname !== routes.guideBase) return;
      event.preventDefault();
      if (state.category === category) return;
      state.category = category;
      saveState();
      update();
      if (mobile.matches) { $('guide-category-panel').open = false; $('guide-status').scrollIntoView({ block: 'start' }); }
      else $('guide-categories').querySelector('[aria-current="page"]').focus({ preventScroll: true });
    };
    return choice;
  }
  function update() {
    const menuName = menus.menuName(state.menu);
    const menuChoice = hasMenuChoice(state.game);
    $('guide-menu-control').hidden = !menuChoice;
    $('guide-menu').replaceChildren(...menus.menusFor(state.game).map(menu => new Option(menu.name + (menu.deferred ? ' — later' : ''), menu.id)));
    $('guide-menu').value = state.menu;
    document.querySelectorAll('[data-game]').forEach(choice => {
      choice.setAttribute('aria-pressed', String(choice.dataset.game === state.game));
      const game = choice.dataset.game;
      choice.href = address(game, categoryFor(game, menus.menuFor(game, state.menu), state.category));
    });
    $('guide-categories').replaceChildren(categoryLink('all'));
    const assets = GAMES[state.game].assets;
    const roleplay = menuChoice ? null : roleplayGroups(state.game);
    const groups = menuChoice ? menus.categoryGroups(state.menu, categories(state.game, state.menu)) : roleplay || [
      [`${menuName} resources`, assets.filter(category => !category.startsWith('addon-'))],
      ['Addons', assets.filter(category => category.startsWith('addon-'))],
      [`${menuName} files`, FILES]
    ];
    for (const [label, list] of groups) {
      if (!list.length) continue;
      const group = node('div', '', 'category-group');
      group.append(node('p', label, 'category-group-label'));
      for (const category of list) group.append(categoryLink(category, menus.categoryLabel(state.menu, category) || (roleplay ? taxonomy.roleplayCategoryLabel(state.game, category) : undefined)));
      $('guide-categories').append(group);
    }
    let count = 0;
    for (const section of sections) {
      section.hidden = !relevant(section, state.game, state.category, state.menu);
      section.classList.remove('is-relevant');
      if (!section.hidden) count++;
      for (const child of section.querySelectorAll('[data-guide-games], [data-guide-menus]')) {
        child.hidden = (child.dataset.guideGames && !contains(child.dataset.guideGames, state.game)) ||
          (child.dataset.guideMenus && !contains(child.dataset.guideMenus, state.menu));
      }
    }
    document.querySelectorAll('[data-menu-name]').forEach(element => { element.textContent = menuName; });
    const currentLabel = menus.categoryLabel(state.menu, state.category) || (state.category === 'mod-menus' ? taxonomy?.roleplayCategoryLabel(state.game, state.category) : undefined) || LABELS[state.category];
    $('guide-status').textContent = `${GAMES[state.game].name} · ${menuName} · ${currentLabel}${count ? '' : ' · Guide not available yet'}`;
    $('guide-empty').hidden = count > 0;
    const collection = routes.catalogURL(state, publishedRoutes);
    for (const link of collectionLinks) link.href = collection;
    for (const link of pluginLinks) {
      link.href = routes.catalogURL({ game: 'gta5', menu: state.menu, category: link.dataset.resourceCategory }, publishedRoutes);
    }
  }

  $('guide-menu').onchange = () => {
    state.menu = menus.menuFor(state.game, $('guide-menu').value);
    state.category = categoryFor(state.game, state.menu, state.category);
    saveState();
    update();
  };
  for (const choice of document.querySelectorAll('[data-game]')) {
    choice.onclick = event => {
      if (event.button > 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      if (choice.pathname !== routes.guideBase) return;
      event.preventDefault();
      if (choice.dataset.game === state.game) return;
      const game = choice.dataset.game;
      const menu = menus.menuFor(game, state.menu);
      state = { game, category: categoryFor(game, menu, state.category), menu };
      saveState();
      update();
    };
    choice.onkeydown = event => { if (event.key === ' ') { event.preventDefault(); choice.click(); } };
  }
  $('guide-category-panel').open = !mobile.matches;
  mobile.addEventListener('change', event => { $('guide-category-panel').open = !event.matches; });
  window.addEventListener('popstate', restoreState);
  window.addEventListener('hashchange', restoreState);
  update();

  async function loadMenuCategories(game) {
    try {
      const response = await fetch(`/resources/${game}/categories.json`);
      if (!response.ok) return;
      menuCategories[game] = await response.json();
    } catch { return; }
    if (state.game !== game) return;
    restoreState();
    const target = targetSection();
    if (target && !target.hidden) target.scrollIntoView();
  }
  for (const game of ['gta5', 'rdr2']) loadMenuCategories(game);

  async function loadResourceRoutes() {
    try {
      const response = await fetch('/resources/routes.json');
      if (!response.ok) return;
      publishedRoutes = new Set(await response.json());
    } catch { return; }
    update();
  }
  loadResourceRoutes();

  async function loadGuideRoutes() {
    try {
      const response = await fetch('/resources/guides/routes.json');
      if (!response.ok) return;
      publishedGuides = await response.json();
    } catch { return; }
    const query = new URLSearchParams(location.search);
    const game = query.get('game');
    if (Object.hasOwn(GAMES, game)) {
      const menu = menus.menuFor(game, query.get('menu'));
      const category = taxonomy.categoryId(game, query.get('category'), menu);
      const target = publishedGuides[routes.guidePath(game, category, menu)];
      if (target) { location.replace(target + location.hash); return; }
    }
    update();
  }
  loadGuideRoutes();
})();
