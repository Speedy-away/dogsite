'use strict';

const fs = require('node:fs');
const path = require('node:path');
const ROOT = path.resolve(__dirname, '..');
const SITE = 'https://scoobymenu.cc';
const SCOOBY_PREVIEW_LOGO = '/assets/images/brand/scooby-mark.svg';
const menus = require('../resources/menus.js');
const editions = require('../resources/editions.js');
const { menuTopic, redmGraphicsTopics, REDM_GRAPHICS_TOPICS, roleplayCategoryGroups, roleplayCategoryId, ROLEPLAY_LABELS } = require('../resources/taxonomy.js');
const featuredTopics = ['lua', 'outfits', 'vehicles', 'maps', 'themes', 'configs', 'languages', 'dlc'];
const headAd = '<script data-cfasync="false" src="https://accountut.com/1/21bac2cf6146c6ff2689111563b5f00a"></script>';

function placeHeadAd(html) {
  if (!html.includes(headAd)) return html;
  return html.replace(headAd + '\n', '').replace('</head>', headAd + '\n</head>');
}
const GAMES = {
  gta5: { name: 'GTA 5', full: 'Grand Theft Auto V', aliases: ['GTA V', 'GTA5', 'GTA 5 Enhanced mods', 'GTA 5 Legacy mods'], logo: '/assets/images/store/gta5-logo-transparent-card.webp', intro: 'Find saved vehicles, Menyoo maps, outfits, addon cars and peds, LSC PaintJobs and Scooby themes for GTA 5 Legacy and Enhanced.' },
  rdr2: { name: 'RDR2', full: 'Red Dead Redemption 2', aliases: ['Red Dead 2'], logo: '/assets/images/store/rdr2-logo-transparent-card.webp', intro: 'Browse Red Dead Redemption 2 outfit presets, addon peds, ClickUI color presets, ListUI styles and Scooby translations.' },
  cs2: { name: 'CS2', full: 'Counter-Strike 2', aliases: ['Counter Strike 2', 'CS2 custom model repo', 'Source 2 skyboxes'], logo: '/portal/images/product-logos/cs2.png', intro: 'Browse Counter-Strike 2 custom player, weapon, knife, grenade and C4 models, plus skyboxes, textures and Scooby configs.' },
  fivem: { name: 'FiveM', full: 'FiveM', aliases: ['GTA roleplay', 'FiveM texture packs'], logo: '/assets/images/store/fivem-emblem.png', intro: 'Find FiveM graphics packs, ReShade presets, road and minimap textures, and Scooby language files for GTA roleplay.' },
  redm: { name: 'RedM', full: 'RedM', aliases: ['Red Dead roleplay'], logo: '/assets/images/store/redm-logo.png', intro: 'Browse RedM PvP and RP graphics packs, cinematic sky packs, weapon skins, sound packs, Colors.xml presets, tracers and client settings.' },
  l4d: { name: 'L4D', full: 'Left 4 Dead', aliases: ['Left 4 Dead 2', 'L4D1', 'L4D2', 'Left 4 Dead addons', 'L4D2 mods'], logo: '/assets/images/source-games/l4d-logo.png', intro: 'Find custom campaigns, survivor and infected models, weapon skins, sound packs, skyboxes and configs for Left 4 Dead 1 and 2.' }
};
const CATEGORIES = {
  vehicles: { name: 'Vehicles', words: ['saved vehicles', 'vehicle presets', 'Menyoo vehicles', 'XML vehicles'], description: 'Saved vehicle presets describe a vehicle, its customization and any attachments. Use a supported importer and install required model assets separately.' },
  modded: { name: 'Modded vehicles', words: ['modded builds', 'vehicle attachments', 'Menyoo builds'], description: 'Browse saved vehicle builds with attachments. Check the preset format and the models referenced by the build before importing it.' },
  outfits: { name: 'Outfits', words: ['outfit presets', 'saved outfits', 'clothing presets'], description: 'Choose an outfit for the intended character or ped model. Preserve its original export format and use the matching outfit library.' },
  'addon-vehicles': { name: 'Addon vehicles', words: ['vehicle mods', 'addon cars', 'custom vehicles'], description: 'Addon vehicle packages install model and texture assets. Check the game edition, dependencies and author’s installation instructions.' },
  'addon-peds': { name: 'Addon peds', words: ['ped mods', 'character models', 'pedestrians'], description: 'Browse addon character and ped resources. Keep each model, its textures and its metadata together when importing a pack.' },
  'addon-objects': { name: 'Object addons', words: ['object mods', 'custom props', 'prop models'], description: 'Browse downloadable object and prop addons. Keep the model, textures and package metadata together and use the required game-specific loader.' },
  'addon-animations': { name: 'Animation addons', words: ['animation packs', 'custom animations', 'animation clips'], description: 'Browse downloadable animation packages. Keep animation dictionaries and supporting metadata together and use the loader specified by the package.' },
  'addon-maps': { name: 'Map addons', words: ['streamed maps', 'YMAP addons', 'map assets', 'MLO'], description: 'Browse streamed map asset packages and their dependencies. These addon assets are separate from the Menyoo/XML and Simple Trainer placement presets in Maps.' },
  'addon-clothing': { name: 'Clothing addons', words: ['clothing mods', 'wardrobe assets', 'ped clothing'], description: 'Browse clothing model and texture packages. Match the intended character model and follow the package’s installation requirements.' },
  dlc: { name: 'DLC packs', words: ['DLC packs', 'addon packs', 'downloadable content'], description: 'Browse DLC and addon content packages. Keep the original package structure, match the game edition and install the required loader and dependencies.' },
  wallpapers: { name: 'Wallpapers', words: ['wallpapers', 'menu backgrounds', 'background images'], description: 'Browse wallpaper and menu background images. Use the image format and dimensions supported by the selected menu.' },
  maps: { name: 'Menyoo & placement maps', words: ['Menyoo maps', 'XML maps', 'INI maps', 'Simple Trainer maps'], description: 'Browse Menyoo/XML and Simple Trainer/INI object-placement presets, including ramps and custom scenes. Use a compatible placement loader and install any referenced model dependencies.' },
  textures: { name: 'Textures', words: ['custom textures', 'texture images', 'materials'], description: 'Find texture artwork and material resources. Choose a supported target and keep the original image or material structure when importing.' },
  paintjobs: { name: 'LSC PaintJobs', words: ['LSC paintjobs', 'saved paint jobs', 'vehicle color presets', 'Scooby PaintJobs'], description: 'Browse native Scooby LSC PaintJobs presets. Copy the original JSON files into C:\\scooby\\GTA5\\LSC\\PaintJobs and use the in-menu Paintjobs library.' },
  liveries: { name: 'Liveries', words: ['vehicle liveries', 'livery textures', 'custom vehicle textures'], description: 'Browse vehicle livery and texture packages from their original authors. Match the target vehicle model and follow the package installation instructions; these are separate from native LSC PaintJobs presets.' },
  players: { name: 'Player models', words: ['custom players', 'agent models', 'character models'], description: 'Browse custom player and agent model packages. Keep compiled models, materials and textures together, then choose the intended team and model scope.' },
  weapons: { name: 'Weapon models', words: ['custom weapons', 'gun models', 'weapon skins'], description: 'Find custom firearm and equipment models. Keep first-person, world, animation and material resources together and use a compatible target.' },
  'weapon-models': { name: 'Weapon models / skins', words: ['weapon skins', 'weapon models', 'RedM weapons', 'custom guns'], description: 'Browse RedM weapon model and skin packages. Keep model and texture files together and use the package’s stated game build and installation destination.' },
  'sound-packs': { name: 'Sound packs', words: ['weapon sounds', 'sound packs', 'audio replacements', 'RedM audio'], description: 'Browse weapon audio and sound packs. Preserve archive paths and match each pack to its intended RedM installation.' },
  'graphics-packs': { name: 'Graphics packs', words: ['graphics packs', 'texture packs', 'visual presets'], description: 'Browse graphics packs and visual presets. Use the included requirements and preserve the pack’s complete supporting files.' },
  'ui-presets': { name: 'UI presets', words: ['colors.xml', 'color presets', 'weapon wheel', 'HUD presets', 'UI boost'], description: 'Browse RedM interface and color presets. Back up the current settings and install the complete XML or UI package using its supplied instructions.' },
  'visual-effects': { name: 'Visual effects', words: ['blood effects', 'tracer presets', 'bloodfx', 'RedM effects'], description: 'Browse tracer and blood-effect resources. Keep the supplied metadata and effect assets together and follow their stated installation paths.' },
  scopes: { name: 'Scopes', words: ['clean scope', 'scope textures', 'scope presets'], description: 'Browse scope appearance resources and their installation instructions. Check the supported weapon, game build and asset format.' },
  settings: { name: 'Client settings', words: ['RedM settings', 'low settings', 'weapon binds', 'graphics settings'], description: 'Browse client setting profiles and individual visual settings. Back up existing values and follow the included instructions for the exact settings file.' },
  knives: { name: 'Knife models', words: ['custom knives', 'knife models', 'melee weapons'], description: 'Browse custom knife and melee model packages. Check the intended base knife and retain the package’s supporting materials and animations.' },
  throwables: { name: 'Throwables', words: ['grenade models', 'flashbang models', 'custom throwables'], description: 'Browse custom grenade and throwable models. Check the intended equipment type and install the complete package before assigning a model.' },
  bombs: { name: 'Bomb models', words: ['C4 models', 'custom bombs'], description: 'Browse custom bomb and C4 model packages. Retain their original compiled resource paths and supporting materials.' },
  skyboxes: { name: 'Skyboxes', words: ['custom skies', 'sky materials', 'sky textures'], description: 'Browse sky material and texture packages. Keep material and texture paths together and select a sky supported by your Scooby build.' },
  themes: { name: 'Themes & UI styles', words: ['menu themes', 'appearance themes', 'UI styles'], description: 'Browse appearance themes and UI styles. Check the original menu, interface, file format and any required compatibility layer before loading a theme.' },
  configs: { name: 'Configs', words: ['configuration profiles', 'saved settings', 'config presets'], description: 'Browse settings profiles and their original menu requirements. Back up your current configuration and use a profile made for the same game and supported build.' },
  lua: { name: 'Lua scripts', words: ['Lua scripts', 'menu Lua', 'scripting'], description: 'Browse Lua script listings for the selected menu. Check the required menu API and download availability; scripts are not interchangeable between menu runtimes.' },
  languages: { name: 'Languages', words: ['translations', 'language files', 'localization'], description: 'Browse translation and language catalogs. Match the original menu, game and host build, and preserve existing custom language overrides.' },
  misc: { name: 'Miscellaneous', words: ['HUD presets', 'resource files'], description: 'Browse additional resource files for the selected menu. Read the item details for its format, required version and installation steps.' },
  'mod-menus': { name: 'Mod Menus', words: ['mod menus', 'menu screenshots'], description: 'Browse menu listings and screenshots. Each listing shows whether a download is available.' },
  triggers: { name: 'Triggers', words: ['triggers'], description: 'Browse trigger resources and their stated requirements.' },
  'server-dumps': { name: 'Server dumps', words: ['server dumps', 'server snapshots'], description: 'Browse server snapshots shared by their owners.' },
  'asi-mods': { name: 'ASI mods', words: ['ASI plugins', 'Menyoo', 'Simple Trainer', 'Rampage trainer'], description: 'Browse ASI plugins and trainers from their original authors. Match the game edition and install the ASI loader and dependencies specified by each mod.' },
  'dotnet-mods': { name: '.NET mods', words: ['dotnet mods', 'ScriptHookVDotNet', 'C# scripts'], description: 'Browse .NET game mods and their original requirements. Use the matching script runtime and follow the author’s installation instructions.' }
};
const escape = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
const queryURL = (game, category, q, menu = 'scooby', edition) => '/resources/?' + new URLSearchParams({ game, ...(game === 'gta5' ? { menu: menus.menuFor(game, menu) } : {}), ...(category ? { category } : {}), ...(q ? { q } : {}), ...(edition ? { edition } : {}) });
const route = (game, category, menu = 'scooby') => `/resources/${game}/${game === 'gta5' && menus.menuFor(game, menu) !== 'scooby' ? menus.menuFor(game, menu) + '/' : ''}${category ? category + '/' : ''}`;
function read(relative) { return JSON.parse(fs.readFileSync(path.join(ROOT, relative), 'utf8')); }
function tagsFor(item, menu) {
  const taxonomy = path.join(ROOT, 'resources/taxonomy.js');
  return fs.existsSync(taxonomy) ? require(taxonomy).tagsFor(item, { menu: menus.menuName(menu) }) : [...new Set([GAMES[item.game]?.name, CATEGORIES[item.category]?.name, menus.menuName(menu), ...(item.tags || [])].filter(Boolean))];
}
function hasCategory(item, category) {
  return roleplayCategoryId(item.game, item.category) === category ||
    item.categories?.some(id => roleplayCategoryId(item.game, id) === category) ||
    (category === 'modded' && item.category === 'vehicles' && item.attachments > 0);
}
function fileURL(file, base) {
  if (file?.url && /^https:\/\//.test(file.url)) return file.url;
  if (/^\/assets\/downloads\/l4d\/[\w.-]+\.(?:cfg|zip)$/i.test(file?.url || '')) return file.url;
  if (!file?.path || file.path.startsWith('/') || file.path.includes('\\') || file.path.split('/').some(part => part === '..' || part === '.')) return '';
  return new URL(file.path.split('/').map(encodeURIComponent).join('/'), base).href;
}
function fileExtension(file) {
  const name = String(file?.formatPath || file?.name || file?.path || file?.url || '').split(/[?#]/)[0];
  if (/\.(zip|7z|rar)\.\d{3}$/i.test(name)) return '.' + name.match(/\.(zip|7z|rar)\.\d{3}$/i)[1].toLowerCase();
  return name.match(/\.([a-z0-9]{1,8})$/i)?.[0]?.toLowerCase() || '';
}
function resourceName(item) {
  const files = item.files || [];
  const primary = files.find(file => ['.zip', '.rar', '.7z', '.gz'].includes(fileExtension(file))) || files[0];
  const extension = fileExtension(primary) || (item.category === 'lua' && item.downloadStatus === 'pending' ? String(item.sourceFilename || '').match(/\.(lua|pluto)$/i)?.[0]?.toLowerCase() || '' : '');
  const label = String(extension && String(item.name).toLowerCase().endsWith(extension) ? String(item.name).slice(0, -extension.length) : item.name).trim();
  return { label, extension, visible: [label, extension].filter(Boolean).join(' ') };
}
const l4dCategories = {
  maps: { name: 'Maps & campaigns', words: ['custom campaigns', 'co-op maps', 'VPK addons'], description: 'Find custom campaigns and maps for Left 4 Dead or Left 4 Dead 2. Check the author’s instructions for required parts and compatible game modes.' },
  players: { name: 'Survivor & infected models', words: ['survivor models', 'infected models', 'character skins'], description: 'Browse survivor and infected replacements. Check the game and character listed on the add-on page before installing.' },
  weapons: { name: 'Weapon models & skins', words: ['weapon skins', 'weapon models', 'reskins'], description: 'Browse cosmetic weapon replacements and reskins. Each add-on targets a specific game and in-game item.' },
  'sound-packs': { ...CATEGORIES['sound-packs'], words: ['sound packs', 'audio replacements', 'sound mods'], description: 'Browse sound and music replacements. Use the author’s installation instructions for the listed game.' },
  skyboxes: { ...CATEGORIES.skyboxes, description: 'Download six-face Source skyboxes for custom maps in Left 4 Dead and Left 4 Dead 2. Keep the included VMT and VTF files together.' },
  textures: { ...CATEGORIES.textures, description: 'Find Source materials for custom maps and texture replacements for existing game assets. Each listing includes its supported game and install method.' },
  configs: { ...CATEGORIES.configs, description: 'Browse game settings presets. Follow the instructions for the file format and game listed on each preset.' }
};
const graphicsCategories = {
  gta5: { ...CATEGORIES['graphics-packs'], words: ['graphics mods', 'NaturalVision', 'visual overhauls'], description: 'Browse NaturalVision graphics mods and visual overhauls for GTA 5 Legacy and Enhanced. Check the author’s installation requirements for your edition.' },
  fivem: { ...CATEGORIES['graphics-packs'], words: ['graphics packs', 'ReShade presets', 'road textures', 'minimap textures'], description: 'Browse FiveM ReShade presets, graphics packs, road textures and minimap replacements. Check whether each pack installs on the client or server.' },
  redm: { ...CATEGORIES['graphics-packs'], words: ['PvP packs', 'PvP graphics packs', 'RP packs', 'roleplay graphics packs', 'cinematic packs', 'sky packs', 'custom sky textures'], description: 'Browse RedM PvP sky packs, RP graphics presets and cinematic packs. Compare skies, weather and lighting previews before installing.' }
};
const categoryInfo = (game, category) => (category === 'graphics-packs' ? graphicsCategories[game] : undefined) ||
  (game === 'l4d' ? l4dCategories[category] : undefined) || CATEGORIES[category];
function buildData() {
  const library = read('community/data/library.json');
  const gtaEditionCatalog = read('community/data/gta5-editions.json');
  const menuFile = path.join(ROOT, 'community/data/menu-resources.json');
  const supplement = fs.existsSync(menuFile) ? read('community/data/menu-resources.json') : {};
  const extra = supplement.items || [];
  const libraryOverrides = new Map((supplement.libraryOverrides || []).filter(item => typeof item.id === 'string').map(item => [item.id, item]));
  const legacyOverrides = menus.legacyOverrideMap(supplement);
  const approvedLua = item => item.menuResource === true && item.sourceCatalog === 'menu-resources' &&
    Array.isArray(item.supportedMenus) && item.supportedMenus.some(menu => menus.canonical(menu)) &&
    (item.files?.length || (item.downloadStatus === 'pending' && Array.isArray(item.files) && !item.files.length));
  const items = [...new Map([
    ...library.items.filter(item => item.category !== 'lua').map(item => ({ ...item, ...libraryOverrides.get(item.id), id: item.id })),
    ...extra.filter(item => item.category !== 'lua' || approvedLua(item)),
    ...gtaEditionCatalog.items
  ].filter(item => GAMES[item.game] && CATEGORIES[item.category]).map(item => [item.id, item])).values()]
    .map(item => {
      const entry = editions.withVerification(item, gtaEditionCatalog);
      return menus.isCheraxTheme(entry) ? { ...entry, uiStyle: menus.themeInterface(entry) } : entry;
    });
  for (const family of ['vehicles', 'outfits']) {
    const data = read(`community/data/${family}/index.json`), assets = read(`community/data/${family}/local-assets.json`);
    data.items.forEach((row, index) => items.push({
      id: `${family}-${index}`, game: 'gta5', category: family, name: row[0],
      format: data.formats?.[row[5]],
      model: data.models[row[3]], modelLabel: data.modelLabels?.[row[3]] || data.models[row[3]],
      attachments: data.attachments?.[index] || 0, tags: [data.modelLabels?.[row[3]] || data.models[row[3]], row[1]],
      preview: assets[index]?.preview ? '/community/' + assets[index].preview.replace(/^\.\//, '') : '',
      files: assets[index]?.file ? [{ url: SITE + '/community/' + assets[index].file.replace(/^\.\//, ''), name: row[1], formatPath: assets[index].file }] : [],
      ...legacyOverrides.get(`${family}:${index}`), id: `${family}-${index}`
    }));
  }
  const pages = [];
  for (const [game, config] of Object.entries(GAMES)) {
    const allGameItems = items.filter(item => item.game === game);
    const availableMenus = menus.MENUS.filter(menu => !menu.deferred && (menu.id === 'scooby' || (game === 'gta5' && allGameItems.some(item => menus.supports(item, menu.id)))));
    for (const selectedMenu of availableMenus) {
      const menu = selectedMenu.id, menuName = selectedMenu.name;
      const gameItems = allGameItems.filter(item => menus.supports(item, menu));
      const categories = Object.keys(CATEGORIES).map(id => ({ id, ...categoryInfo(game, id), count: gameItems.filter(item => hasCategory(item, id)).length })).filter(category => category.count);
      const makePage = category => {
      const subset = category ? gameItems.filter(item => hasCategory(item, category)) : gameItems;
      let candidates = subset.slice().sort((a, b) => Number(Boolean(b.preview)) - Number(Boolean(a.preview)));
      const scoobyThemes = game === 'gta5' && menu === 'scooby' && category === 'themes';
      if (scoobyThemes) {
        const clickUI = candidates.filter(item => item.uiStyle === 'ClickUI' && menus.compatibleWith(item, 'scooby')).slice(0, 2);
        candidates = [...new Set([...clickUI, ...candidates])];
      }
      if (!category) {
        const first = categories.map(group => candidates.find(item => hasCategory(item, group.id))).filter(Boolean);
        candidates = [...new Map([...first, ...candidates].map(item => [item.id, item])).values()];
      }
      const samples = candidates.slice(0, 12);
      const label = category === 'graphics-packs' && (game === 'fivem' || game === 'redm') ? ROLEPLAY_LABELS[category] : category ? categoryInfo(game, category).name : 'Resources';
      const pendingCount = subset.filter(item => item.downloadStatus === 'pending' && !item.files?.length).length;
      const pendingOnly = subset.length > 0 && pendingCount === subset.length;
      const scopeName = `${config.name}${game === 'gta5' ? ' ' + menuName : ''}`;
      const redmGraphics = game === 'redm' && category === 'graphics-packs';
      const title = redmGraphics ? 'RedM Graphics Packs for PvP, RP & Cinematic Play | Scooby' :
        category ? `${scopeName} ${label}${pendingOnly ? ' — Coming Soon' : ''} — Scooby Resources` : `${scopeName} Resources${pendingOnly ? ' — Coming Soon' : ' & Downloads'} — Scooby`;
      const wordsFor = id => categoryInfo(game, id).words;
      const categoryWords = category ? wordsFor(category) : categories.flatMap(group =>
        group.id === 'graphics-packs' && game === 'redm' ? group.words : group.words.slice(0, 2));
      const interfaces = [...new Set(subset.filter(item => item.category === 'themes').flatMap(item => [item.uiStyle, item.style]).filter(Boolean))];
      const topics = game === 'gta5'
        ? (category ? [category] : categories.map(group => group.id)).map(id => menuTopic(menu, id)).filter(Boolean)
        : [];
      const searches = categoryWords.filter(word => !word.toLowerCase().startsWith(config.name.toLowerCase() + ' ')).map(word => `${config.name} ${word}`);
      const keywords = [...new Set(['Scooby resources', `${config.name} resources`, menuName, `${menuName} resources`, config.name, config.full, ...topics, ...config.aliases, ...searches, ...categoryWords, ...interfaces])].join(', ');
      const intro = scoobyThemes
        ? 'Browse native Scooby ClickUI colors and ListUI styles. Some Scooby-compatible presets look like other menus. Check the file requirements before installing.'
        : game === 'gta5' && menu === 'cherax' && category === 'themes'
          ? 'Browse original Cherax ClickGUI packages. Use the Cherax theme loader and keep the settings and artwork together.'
          : category ? categoryInfo(game, category).description.replace(/the selected menu/g, menuName).replace(/selected menu/g, menuName) : menu === 'scooby' ? config.intro : `Browse ${config.name} resources listed for ${menuName}. Check each resource’s original menu format, download availability and any required compatibility layer before installing.`;
      const firstSentence = intro.split(/(?<=[.!?])\s/)[0];
      const description = pendingOnly
        ? `Browse ${subset.length.toLocaleString('en-GB')} ${scopeName} ${label.toLowerCase()} listings. Downloads are coming soon. Check requirements and changelogs.`
        : redmGraphics ? intro
        : category ? `${scopeName} resources. ${firstSentence}`
        : !gameItems.length ? `${config.name} resource installation and setup guides from Scooby. No downloads are published in this collection yet.`
        : menu === 'scooby' ? config.intro
        : `Browse ${menuName} resources for GTA 5, including ${categories.slice(0, 4).map(group => group.name.toLowerCase()).join(', ')}. Check formats and install guides.`;
      const graphicsTopics = game === 'redm' && (!category || redmGraphics)
        ? REDM_GRAPHICS_TOPICS.filter(topic => subset.some(item => redmGraphicsTopics(item).includes(topic))) : [];
      pages.push({ file: route(game, category, menu).slice(1) + 'index.html', url: SITE + route(game, category, menu), game, menu, menuName, category, name: label, title, description, keywords,
        itemCount: subset.length, pendingCount, gameItemCount: gameItems.length, categories, availableMenus, samples, intro, graphicsTopics, downloadBaseUrl: library.downloadBaseUrl });
      };
      makePage();
      for (const category of categories) makePage(category.id);
    }
  }
  return { pages, items, games: GAMES, categories: CATEGORIES, menus: menus.MENUS };
}
function renderPage(page) {
  const game = GAMES[page.game];
  const gameLinks = Object.entries(GAMES).map(([id, config]) => `<a href="${route(id, undefined, id === page.game ? page.menu : 'scooby')}"${id === page.game ? ' aria-current="page"' : ''}><img src="${config.logo}" alt="" width="38" height="28"><span>${config.name}</span></a>`).join('');
  const menuLinks = page.game === 'gta5' ? `<nav class="resource-menus" aria-label="GTA 5 menu resources">${page.availableMenus.map(menu => `<a href="${route(page.game, undefined, menu.id)}"${menu.id === page.menu ? ' aria-current="page"' : ''}>${escape(menu.name)}</a>`).join('')}</nav>` : '';
  const gameFilters = page.game === 'l4d' ? `<nav class="resource-menus" aria-label="Filter by Left 4 Dead game">${Object.entries(editions.group('l4d').options).map(([edition, label]) =>
    `<a href="${escape(queryURL(page.game, page.category, undefined, page.menu, edition))}">${escape(label)} resources</a>`).join('')}</nav>` : '';
  const byId = new Map(page.categories.map(category => [category.id, category]));
  const roleplayGroups = roleplayCategoryGroups(page.game, [...byId.keys()]);
  const categoryChoice = category => {
    const href = category.count ? route(page.game, category.id, page.menu) : queryURL(page.game, category.id, undefined, page.menu);
    const label = (roleplayGroups && ROLEPLAY_LABELS[category.id]) || category.name.replace(/^Addon /, '');
    const current = category.id === page.category ? ' aria-current="page"' : '';
    const count = category.count ? ` <span>${category.count.toLocaleString('en-GB')}</span>` : '';
    return `<a href="${escape(href)}"${current}>${escape(label)}${count}</a>`;
  };
  const fileCategories = new Set(['themes', 'configs', 'lua', 'languages', 'wallpapers', 'misc']);
  const gtaGroups = page.game === 'gta5' ? menus.gtaCategoryGroups(page.menu, byId.keys()) : null;
  const groups = gtaGroups ? gtaGroups.map(([label, ids]) => [label, ids.map(id => byId.get(id))])
    : roleplayGroups ? roleplayGroups.map(([label, ids]) => [
    label, ids.map(id => byId.get(id) || { id, ...CATEGORIES[id], count: 0 })
  ]) : [
    [page.game === 'l4d' ? 'Custom content' : `${page.menuName} resources`, page.categories.filter(category => !category.id.startsWith('addon-') && !fileCategories.has(category.id))],
    ['Addons', page.categories.filter(category => category.id.startsWith('addon-'))],
    [page.game === 'l4d' ? 'Settings and translations' : `${page.menuName} files`, page.categories.filter(category => fileCategories.has(category.id))]
  ];
  const categoryLinks = `<a href="${route(page.game, undefined, page.menu)}"${!page.category ? ' aria-current="page"' : ''}>All resources <span>${page.gameItemCount.toLocaleString('en-GB')}</span></a>` + groups.filter(([, categories]) => categories.length).map(([label, categories]) => `<div class="category-group"><p class="category-group-label">${escape(label)}</p>${categories.map(categoryChoice).join('')}</div>`).join('');
  const samples = page.samples.map(item => {
    const href = '#resource-' + item.id.replace(/[^a-z0-9_-]/gi, '-');
    const preview = item.previewVerified === false || (item.category === 'themes' && item.previewVerified !== true) ? '' : typeof item.preview === 'string' ? item.preview : item.preview?.path || item.preview?.url;
    const remotePreview = preview && !preview.startsWith('/') && !/^https:\/\//.test(preview) ? fileURL({ path: preview }, page.downloadBaseUrl) : preview;
    const local = preview && !preview.startsWith('/') && !/^https:\/\//.test(preview) ? ` data-resource-image="${escape(preview)}"` : '';
    const fallback = ` data-resource-image-fallback="${SCOOBY_PREVIEW_LOGO}"`;
    const image = remotePreview
      ? `<a class="resource-preview" href="${escape(href)}"><img src="${escape(remotePreview)}"${local}${fallback} alt="${escape(item.name)} preview" loading="lazy" decoding="async"></a>`
      : `<div class="resource-preview"><img class="preview-placeholder" src="${SCOOBY_PREVIEW_LOGO}" alt="" loading="lazy" decoding="async"></div>`;
    const tags = tagsFor(item, page.menu).filter(tag => tag.length <= 30 && !/[\\/]/.test(tag)).slice(0, 4);
    const files = (item.files || []).map(file => ({ url: fileURL(file, page.downloadBaseUrl), name: file.name || path.posix.basename(file.path || ''), formatPath: file.formatPath || file.path, size: file.size, downloadMethod: file.downloadMethod })).filter(file => file.url);
    const { extension, label: name } = resourceName(item);
    const suffix = extension ? ` <span class="resource-extension ext-${extension.slice(1)}">${escape(extension)}</span>` : '';
    const download = file => `<button type="button" class="resource-download" data-download-file="${escape(JSON.stringify(file))}">Download${files.length > 1 ? ' ' + escape(file.name) : ' ↓'}</button>`;
    const authorHosted = item.status === 'author-hosted' && /^https:\/\//.test(item.sourceUrl || '');
    const authorLink = authorHosted ? `<a class="resource-download" href="${escape(item.sourceUrl)}" target="_blank" rel="noopener noreferrer">Get from the author ↗</a>` : '';
    const install = authorHosted && /^https:\/\//.test(item.installUrl || '') ? `<p><a href="${escape(item.installUrl)}" target="_blank" rel="noopener noreferrer">Author’s install guide ↗</a></p>` : '';
    const author = item.author || (item.game === 'l4d' ? item.credits : '');
    const credit = authorHosted && author ? `<p>By ${escape(author)}</p>` : '';
    const edition = editions.support(item);
    const badge = edition ? `<span class="edition-badge edition-${edition}" title="${escape(editions.title(item.game, edition))}">${escape(editions.badge(item.game, edition))}</span>` : '';
    const actions = item.status === 'preview-only' ? '<p>Download unavailable</p>' : authorLink || (item.downloadStatus === 'pending' && !files.length ? '<button type="button" class="resource-download" disabled>Download — Coming soon</button>' : files.length === 1 ? download(files[0]) : files.length > 1 ? `<details class="resource-download-menu"><summary>Download ↓</summary>${files.map(download).join('')}</details>` : `<details class="resource-inline-details"><summary>Details</summary><p>${escape(item.compatibility || item.description || 'Included in the game menu. Use its appearance or library controls.')}</p></details>`);
    const notes = (Array.isArray(item.changelog) ? item.changelog : typeof item.changelog === 'string' ? [item.changelog] : []).flatMap(note => {
      if (typeof note === 'string') return [note];
      if (!note || typeof note !== 'object') return [];
      const heading = [/commit/i.test(note.dateBasis || '') ? 'Source update' : '', note.version, note.date].filter(Boolean).join(' · ');
      const changes = [note.changes, note.notes, note.description].flat().filter(value => typeof value === 'string');
      return changes.map(change => heading ? `${heading}: ${change}` : change);
    }).filter(Boolean);
    const changelog = item.category === 'lua' || notes.length ? `<button type="button" class="resource-changelog" data-resource-changelog="${escape(JSON.stringify({ name: item.name, notes }))}">Changelog</button>` : '';
    const requirementText = item.requirementLabel || (item.game === 'l4d' ? item.compatibility : '') || (!menus.compatibleWith(item, page.menu) ? 'Requires the original menu format and a compatible loader or importer.' : '');
    const requirement = requirementText ? `<p class="resource-requirement">${escape(requirementText)}</p>` : '';
    return `<article class="resource-sample" id="${href.slice(1)}">${image}<h3><a href="${escape(href)}">${escape(name)}</a>${suffix}</h3><p>${escape(item.modelLabel || categoryInfo(item.game, item.category)?.name || 'Menu resource')}</p>${badge}${item.description ? `<p>${escape(item.description)}</p>` : ''}${credit}${requirement}<p class="resource-tags">${tags.map(tag => `<a href="${escape(queryURL(page.game, item.category, tag, page.menu))}">${escape(tag)}</a>`).join(' ')}</p>${actions}${install}${changelog}<p class="resource-download-status" role="status"></p></article>`;
  }).join('\n');
  const collection = { '@context': 'https://schema.org', '@graph': [
    { '@type': 'CollectionPage', '@id': page.url + '#collection', url: page.url, name: page.title, description: page.description, keywords: page.keywords, inLanguage: 'en', about: { '@type': 'VideoGame', name: game.full }, isPartOf: { '@id': SITE + '/resources/#collection' }, mainEntity: { '@id': page.url + '#resources' } },
    { '@type': 'ItemList', '@id': page.url + '#resources', name: `${game.name} ${page.game === 'gta5' ? page.menuName + ' ' : ''}${page.name}`, numberOfItems: page.samples.length, itemListElement: page.samples.map((item, index) => ({ '@type': 'ListItem', position: index + 1, name: resourceName(item).visible, url: page.url + '#resource-' + item.id.replace(/[^a-z0-9_-]/gi, '-') })) }
  ] };
  const scopeName = game.name + (page.game === 'gta5' ? ' ' + page.menuName : '');
  const breadcrumb = page.menu !== 'scooby' ? `<a href="${route(page.game)}">${game.name}</a><span>/</span>${page.category ? `<a href="${route(page.game, undefined, page.menu)}">${escape(page.menuName)}</a><span>/</span><span>${escape(page.name)}</span>` : `<span>${escape(page.menuName)}</span>`}` : page.category ? `<a href="${route(page.game)}">${escape(scopeName)}</a><span>/</span><span>${escape(page.name)}</span>` : `<span>${escape(scopeName)}</span>`;
  const heading = scopeName + ' ' + (page.category ? page.name : 'resources');
  const guideURL = `/resources/guides/?game=${page.game}${page.game === 'gta5' ? '&menu=' + page.menu : ''}${page.category ? '&category=' + page.category : ''}`;
  const source = page.game === 'gta5' ? page.availableMenus.find(menu => menu.id === page.menu)?.source : undefined;
  const sourceLink = source ? `<a class="menu-source-link" href="${escape(source.url)}">${escape(source.label)}</a>` : '';
  const clickUILink = page.game === 'gta5' && page.menu === 'scooby' && page.category === 'themes'
    ? ` <a class="resource-open" href="${escape(queryURL('gta5', 'themes') + '&ui=clickui')}">Browse Scooby ClickUI themes →</a>` : '';
  const graphicsLinks = page.graphicsTopics?.length
    ? `<nav class="resource-menus" aria-label="RedM graphics pack types">${page.graphicsTopics.map(topic =>
      `<a href="${escape(queryURL('redm', 'graphics-packs', topic.query))}">${escape(topic.name)}</a>`).join('')}</nav>` : '';
  const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escape(page.title)}</title><link rel="icon" type="image/png" href="/assets/images/brand/scooby-logo.png"><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&amp;display=swap" rel="stylesheet"><link rel="stylesheet" href="/assets/css/site-brand.css"><link rel="stylesheet" href="/resources/catalog.css"><link rel="stylesheet" href="/resources/discover.css"><script src="/resources/discover.js" defer></script><script type="application/ld+json" id="resource-collection-data">${JSON.stringify(collection).replace(/</g, '\\u003c')}</script>
<link rel="stylesheet" href="/assets/css/ad-sidebar.css">
<script data-cfasync="false" src="https://accountut.com/1/21bac2cf6146c6ff2689111563b5f00a"></script>
</head>
<body><a class="skip" href="#resources">Skip to resources</a><header><a class="scooby-brand" href="/"><span class="scooby-emblem" aria-hidden="true"></span><strong>SCOOBY</strong></a><nav aria-label="Main"><a href="/resources/">Resources</a><a href="/resources/guides/">Install guides</a><a href="/store/">Store ↗</a></nav></header>
<main class="resource-directory" id="resources"><nav class="breadcrumbs" aria-label="Breadcrumb"><a href="/">Home</a><span>/</span><a href="/resources/">Resources</a><span>/</span>${breadcrumb}</nav><nav class="resource-games" aria-label="Game resources">${gameLinks}</nav>${menuLinks}${gameFilters}<div class="resource-layout ad-layout"><aside>${sourceLink}<h2>Categories</h2><nav class="resource-category-links" aria-label="Resource categories">${categoryLinks}</nav><a class="resource-guide" href="${escape(guideURL)}">Installation guide ↗</a></aside><section class="resource-content"><h1>${escape(heading)}</h1><p class="resource-intro">${escape(page.intro)}</p><p class="resource-total">${page.itemCount.toLocaleString("en-GB")} resources${page.pendingCount ? " · " + page.pendingCount.toLocaleString("en-GB") + " coming soon" : ""}${page.samples.length ? " · Showing " + page.samples.length + " from the collection" : ""}</p><a class="resource-browse" href="${escape(queryURL(page.game, page.category, undefined, page.menu))}">Browse and search ${page.category ? escape(page.name.toLowerCase()) : 'all ' + game.name + ' resources'} →</a>${clickUILink}${page.itemCount ? `<div class="resource-samples">${samples}</div>` : `<p class="resource-empty">No ${escape(scopeName)} downloads are published yet. Read the <a href="${escape(guideURL)}">resource installation guide</a>.</p>`}</section>
<aside class="ad-sidebar" aria-label="Advertisement" data-i18n-skip>
  <p class="ad-label">Advertisement</p>
  <div class="ad-content" id="container-916d4be3288f94a3bc49ab6cdaef5ba9"></div>
  <script async="async" data-cfasync="false" src="https://bellnewyork.org/21/916d4be3288f94a3bc49ab6cdaef5ba9"></script>
  <a class="ad-sponsor" href="https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd" target="_blank" rel="sponsored nofollow noopener noreferrer">Sponsored offer ↗</a>
</aside></div></main><footer><a href="/resources/">All resources</a><a href="/sitemap/">Site directory</a></footer></body></html>`;
  const dialog = '<dialog id="resource-changelog" aria-labelledby="resource-changelog-title"><button type="button" class="dialog-close" id="close-resource-changelog">Close ✕</button><h2 id="resource-changelog-title">Changelog</h2><div id="resource-changelog-content"></div></dialog>';
  return placeHeadAd(require('./seo-metadata').applyMetadata(page.file, html.replace('<div class="resource-layout ad-layout">', graphicsLinks + '<div class="resource-layout ad-layout">').replace('</body>', dialog + '\n<script data-cfasync="false" src="https://bellnewyork.org/14/179ef803d1a93ce7af0ad7b09a49ead9"></script>\n</body>')));
}
function build({ gta5Only = false } = {}) {
  const data = buildData();
  const pages = gta5Only ? data.pages.filter(page => page.game === 'gta5') : data.pages;
  const expected = new Set(pages.map(page => path.resolve(ROOT, page.file)));
  // Remove only obsolete generated category documents, never source assets.
  for (const game of gta5Only ? ['gta5'] : Object.keys(GAMES)) {
    const directory = path.join(ROOT, 'resources', game);
    if (!fs.existsSync(directory)) continue;
    const rootDelta = path.relative(ROOT, fs.realpathSync(directory));
    if (rootDelta.startsWith('..') || path.isAbsolute(rootDelta)) throw Error('Generated resource directory is outside the site workspace');
    const visit = current => {
      const relative = path.relative(directory, current);
      if (relative.startsWith('..') || path.isAbsolute(relative)) throw Error('Generated resource cleanup escaped its game directory');
      for (const child of fs.readdirSync(current, { withFileTypes: true })) {
        if (child.isDirectory() && !child.isSymbolicLink()) visit(path.join(current, child.name));
      }
      const file = path.join(current, 'index.html');
      if (!expected.has(file) && fs.existsSync(file)) {
        const html = fs.readFileSync(file, 'utf8');
        if (html.includes('id="resource-collection-data"') && html.includes('class="resource-directory"')) fs.unlinkSync(file);
      }
      if (current !== directory && !fs.readdirSync(current).length) fs.rmdirSync(current);
    };
    visit(directory);
  }
  for (const page of pages) {
    const output = path.join(ROOT, page.file);
    fs.mkdirSync(path.dirname(output), { recursive: true });
    fs.writeFileSync(output, renderPage(page));
  }
  const gtaMenus = data.pages.filter(page => page.game === 'gta5' && !page.category);
  const guideCategories = Object.fromEntries(gtaMenus.map(page => [
    page.menu, menus.gtaCategoryGroups(page.menu, page.categories.map(category => category.id)).flatMap(([, ids]) => ids)
  ]));
  fs.writeFileSync(path.join(ROOT, 'resources/gta5/categories.json'), JSON.stringify(guideCategories, null, 2) + '\n');
  if (gta5Only) {
    console.log(`Built ${pages.length} crawlable GTA 5 resource pages.`);
    return data;
  }
  const rootFile = path.join(ROOT, 'resources/index.html');
  let rootHtml = fs.readFileSync(rootFile, 'utf8').replace(/<script\b[^>]*id="resource-collection-data"[^>]*>[\s\S]*?<\/script>\s*/i, '');
  const rootUrl = SITE + '/resources/';
  const rootMeta = require('./seo-metadata').pages['resources/index.html'];
  const rootSchema = { '@context': 'https://schema.org', '@graph': [
    { '@type': 'CollectionPage', '@id': rootUrl + '#collection', url: rootUrl, name: 'Scooby Resources', description: rootMeta.description, keywords: rootMeta.keywords, inLanguage: 'en', isPartOf: { '@id': SITE + '/#website' }, mainEntity: { '@id': rootUrl + '#games' } },
    { '@type': 'ItemList', '@id': rootUrl + '#games', name: 'Game resource collections', numberOfItems: Object.keys(GAMES).length, itemListElement: Object.entries(GAMES).map(([game, config], index) => ({ '@type': 'ListItem', position: index + 1, name: config.name, url: SITE + route(game) })) }
  ] };
  rootHtml = rootHtml.replace('</head>', `<script type="application/ld+json" id="resource-collection-data">${JSON.stringify(rootSchema).replace(/</g, '\\u003c')}</script>\n</head>`);
  fs.writeFileSync(rootFile, placeHeadAd(require('./seo-metadata').applyMetadata('resources/index.html', rootHtml)));
  console.log(`Built ${data.pages.length} crawlable resource pages.`);
  return data;
}
module.exports = { GAMES, CATEGORIES, buildData, build, renderPage, route, queryURL, placeHeadAd, featuredTopics };
if (require.main === module) build({ gta5Only: process.argv.includes('--gta5-only') });
