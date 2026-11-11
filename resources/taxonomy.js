(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ScoobyTaxonomy = api;
})(typeof globalThis === 'object' ? globalThis : this, function () {
  'use strict';

  const GAME_ALIASES = {
    gta5: ['gta5', 'gta 5', 'gta v', 'grand theft auto 5', 'grand theft auto v'],
    rdr2: ['rdr2', 'rdr 2', 'red dead redemption 2', 'red dead redemption ii'],
    cs2: ['cs2', 'counter strike 2', 'counterstrike 2', 'counterstrike2'],
    fivem: ['fivem', 'five m', 'gta roleplay'],
    redm: ['redm', 'red m', 'red dead roleplay'],
    l4d: ['l4d', 'left 4 dead', 'left four dead']
  };
  const CATEGORY_ALIASES = {
    vehicles: ['vehicles', 'vehicle', 'cars', 'car'],
    modded: ['modded vehicles', 'modded builds', 'custom vehicles', 'modded'],
    outfits: ['outfits', 'outfit', 'clothing', 'wardrobe'],
    'mod-menus': ['mod menus', 'mod menu'],
    'addon-vehicles': ['addon vehicles', 'vehicle addons', 'add on vehicles', 'vehicles', 'vehicle', 'cars'],
    'addon-peds': ['addon peds', 'ped addons', 'ped', 'peds', 'pedestrian', 'pedestrians', 'character models'],
    'addon-objects': ['object addons', 'objects', 'object models', 'props', 'prop models'],
    'addon-animations': ['animation addons', 'animations', 'animation packs', 'animation clips'],
    'addon-maps': ['map addons', 'streamed maps', 'ymap', 'mlo', 'map assets'],
    'addon-clothing': ['clothing addons', 'clothing models', 'clothing textures', 'wardrobe assets'],
    dlc: ['dlc', 'dlc packs', 'addon packs', 'downloadable content'],
    wallpapers: ['wallpapers', 'wallpaper', 'menu backgrounds', 'background images'],
    maps: ['maps', 'map', 'menyoo maps', 'placement maps', 'xml maps', 'ini maps', 'simple trainer maps'],
    textures: ['textures', 'texture', 'materials', 'material'],
    paintjobs: ['paintjobs', 'paintjob', 'paint jobs', 'paint job', 'lsc paintjobs', 'lsc paint jobs', 'paint presets', 'colour presets', 'color presets'],
    liveries: ['liveries', 'livery', 'vehicle liveries', 'vehicle textures', 'livery textures'],
    'asi-mods': ['asi mods', 'asi mod', 'asi plugins', 'asi plugin', 'script hook v', 'scripthookv', 'native mods'],
    'dotnet-mods': ['dotnet mods', 'dotnet mod', 'dot net mods', 'net mods', 'net scripts', 'c sharp', 'csharp', 'script hook v dot net', 'scripthookvdotnet'],
    players: ['players', 'player models', 'player model', 'characters', 'character models', 'peds'],
    weapons: ['weapons', 'weapon models', 'weapon model', 'guns', 'gun'],
    'weapon-models': ['weapons', 'weapon models', 'weapon skins', 'gun skins', 'models', 'skins'],
    'sound-packs': ['sound packs', 'sounds', 'audio', 'weapon sounds', 'gun sounds'],
    'graphics-packs': ['graphics packs', 'graphics', 'pvp graphics', 'rp graphics', 'cinematic'],
    'ui-presets': ['ui presets', 'ui boost', 'colors xml', 'colors.xml', 'color presets', 'weapon wheel', 'hud'],
    'visual-effects': ['visual effects', 'effects', 'tracers', 'tracer presets', 'bloodfx', 'blood effects'],
    scopes: ['scopes', 'scope', 'clean scope', 'scope textures'],
    settings: ['client settings', 'settings', 'low settings', 'weapon binds', 'graphics settings'],
    knives: ['knives', 'knife', 'knifes', 'knife models', 'knife model', 'melee'],
    throwables: ['throwables', 'throwable', 'grenades', 'grenade'],
    bombs: ['bombs', 'bomb', 'c4', 'explosives'],
    skyboxes: ['skyboxes', 'skybox', 'sky boxes', 'sky box', 'sky'],
    themes: ['themes', 'theme', 'appearance', 'menu themes', 'ui themes', 'ui styles', 'ui style'],
    configs: ['configs', 'config', 'configuration', 'configurations', 'settings', 'presets'],
    lua: ['lua', 'lua scripts', 'scripts', 'script'],
    languages: ['languages', 'language', 'translations', 'translation', 'localization', 'localisation'],
    misc: ['misc', 'miscellaneous', 'resources']
  };
  const UI_ALIASES = {
    clickui: ['clickui', 'click ui', 'click interface'],
    listui: ['listui', 'list ui', 'list interface']
  };
  const STYLE_ALIASES = {
    '2take1': ['2take1', '2 take 1', '2take1 style'],
    stand: ['stand', 'stand style'], impulse: ['impulse', 'impulse style'],
    silkroad: ['silkroad', 'silk road', 'silkroad style'],
    ozark: ['ozark', 'ozark style'], xforce: ['x force', 'xforce', 'x force style'],
    scooby: ['scooby', 'scooby style']
  };
  const MENU_NAMES = {
    scooby: 'Scooby', nenyoo: 'Nenyoo', cherax: 'Cherax', stand: 'Stand', xforce: 'X-Force'
  };
  const MENU_TOPICS = {
    lua: 'Lua scripts', outfits: 'outfits', vehicles: 'vehicles', modded: 'modded vehicles',
    maps: 'maps', themes: 'themes', configs: 'configs', languages: 'translations',
    dlc: 'DLC packs', 'addon-vehicles': 'addon vehicles', 'addon-peds': 'addon peds',
    'addon-objects': 'object addons', 'addon-maps': 'map addons',
    'addon-animations': 'animation addons', 'addon-clothing': 'clothing addons',
    textures: 'textures', paintjobs: 'paintjobs', liveries: 'liveries',
    wallpapers: 'wallpapers', 'asi-mods': 'ASI mods', 'dotnet-mods': '.NET mods'
  };

  function menuTopic(menu, category) {
    const name = MENU_NAMES[normalizeTag(menu).replace(/\s/g, '')];
    return name && MENU_TOPICS[category] ? `${name} ${MENU_TOPICS[category]}` : '';
  }

  function normalizeTag(value) {
    if (typeof value !== 'string' && typeof value !== 'number') return '';
    return String(value).normalize('NFKD').replace(/\p{M}/gu, '').toLowerCase()
      .replace(/&/g, ' and ').replace(/[’']/g, '').replace(/[^\p{L}\p{N}]+/gu, ' ').trim().replace(/\s+/g, ' ');
  }

  function values(value) {
    if (Array.isArray(value)) return value.flatMap(values);
    if (typeof value === 'string') return value.split(/[,;|\n]+/).map(part => part.trim()).filter(Boolean);
    return typeof value === 'number' ? [String(value)] : [];
  }

  function tagsFor(item, options = {}) {
    if (!item || typeof item !== 'object') return [];
    const result = new Set();
    const add = value => {
      const tag = normalizeTag(value);
      if (tag && tag.length <= 80 && result.size < 128) result.add(tag);
    };
    const game = normalizeTag(item.game).replace(/\s/g, '');
    const categories = [...new Set(values([item.category, item.categories]))];
    const themes = categories.includes('themes') && ['gta5', 'rdr2'].includes(game);
    const ui = themes ? values(item.uiStyle) : [];
    const styles = themes ? values(item.style) : [];
    const supplied = values([item.tags, item.keywords]);
    const knownUI = new Set(['listui', 'list ui', 'list interface', 'clickui', 'click ui', 'click interface']);

    // Primary labels precede aliases so a short visible tag list stays useful.
    add(game);
    if (game === 'gta5') {
      const origin = MENU_NAMES[normalizeTag(item.sourceMenu || item.menu).replace(/\s/g, '')];
      if (origin) {
        add(origin);
        categories.forEach(category => add(menuTopic(origin, category)));
      }
    }
    if (options.menu) add(options.menu);
    categories.forEach(add);
    if (game === 'l4d') {
      if (item.edition === 'l4d1' || item.edition === 'both') ['l4d1', 'left 4 dead 1'].forEach(add);
      if (item.edition === 'l4d2' || item.edition === 'both') ['l4d2', 'left 4 dead 2'].forEach(add);
    }
    ui.forEach(add);
    styles.forEach(add);
    values([item.modelLabel, item.model]).forEach(add);
    if (item.attachments > 0 && categories.includes('vehicles')) add('modded vehicles');
    for (const tag of supplied) if (themes || !knownUI.has(normalizeTag(tag))) add(tag);
    values(options.menu || [item.menu, item.supportedMenus]).forEach(add);
    if (item.downloadStatus === 'pending') add('coming soon');
    for (const file of Array.isArray(item.files) ? item.files : []) {
      const extension = String(file.name || file.path || '').split('.').pop();
      if (/^[a-z0-9]{1,8}$/i.test(extension)) add(extension);
    }
    if (themes && item.status === 'in-menu' && /\bdefault\b/i.test(String(item.name || ''))) {
      add('default');
      for (const value of ui) { add(`default ${value}`); add(`default${normalizeTag(value).replace(/\s/g, '')}`); }
    }

    (GAME_ALIASES[game] || []).forEach(add);
    for (const category of categories) (CATEGORY_ALIASES[category] || []).forEach(add);
    if (item.attachments > 0 && categories.includes('vehicles')) CATEGORY_ALIASES.modded.forEach(add);
    for (const value of ui) (UI_ALIASES[normalizeTag(value).replace(/\s/g, '')] || []).forEach(add);
    for (const value of styles) (STYLE_ALIASES[normalizeTag(value).replace(/\s/g, '')] || []).forEach(add);
    if (!options.compact) return [...result];
    const primary = new Set([game, ...categories, ...ui, ...styles, ...values([item.modelLabel, item.model])].map(normalizeTag));
    const aliases = new Set([
      ...(GAME_ALIASES[game] || []),
      ...categories.flatMap(category => CATEGORY_ALIASES[category] || []),
      ...ui.flatMap(value => UI_ALIASES[normalizeTag(value).replace(/\s/g, '')] || []),
      ...styles.flatMap(value => STYLE_ALIASES[normalizeTag(value).replace(/\s/g, '')] || [])
    ].map(normalizeTag).filter(tag => !primary.has(tag)));
    return [...result].filter(tag => !aliases.has(tag) && tag.length <= 42 && !/^\d+$/.test(tag));
  }

  function searchText(item) {
    if (!item || typeof item !== 'object') return '';
    const files = Array.isArray(item.files) ? item.files.flatMap(file => [file.name, file.path, file.url]) : [];
    return normalizeTag([
      item.name, item.description, item.model, item.modelLabel, item.author, item.sourceUrl,
      item.format, item.source, item.sourceMenu, item.sourceFilename, item.compatibility, item.downloadStatus,
      ...files, ...tagsFor(item)
    ].filter(value => typeof value === 'string' || typeof value === 'number').join(' '));
  }

  const ROLEPLAY_LABELS = Object.freeze({ lua: 'Lua scripts', themes: 'Themes', misc: 'Misc', 'graphics-packs': 'Graphics packs & textures' });
  const roleplayResources = ['outfits', 'mod-menus', 'lua', 'triggers', 'server-dumps', 'misc'];
  const roleplayVisions = ['weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings'];

  function roleplayCategoryId(game, id) {
    return (game === 'redm' || game === 'fivem') && id === 'textures' ? 'graphics-packs' : id;
  }

  function roleplayCategoryGroups(game, categories) {
    if (game !== 'redm' && game !== 'fivem') return null;
    const files = ['configs', 'themes', ...categories.filter(id => id === 'languages' || id === 'wallpapers')];
    const visions = roleplayVisions.filter(id => id === 'graphics-packs' || categories.includes(id));
    const addons = categories.filter(id => id.startsWith('addon-'));
    const grouped = new Set([...roleplayResources, ...files, ...visions, ...addons, 'textures', 'paintjobs']);
    const otherResources = categories.filter(id => !grouped.has(id));
    return [
      ['Scooby resources', [...roleplayResources, ...otherResources]],
      ['Scooby files', files],
      ['Textures/Visions', visions],
      ['Addons', addons]
    ];
  }

  return Object.freeze({ normalizeTag, tagsFor, searchText, menuTopic, roleplayCategoryGroups, roleplayCategoryId, ROLEPLAY_LABELS });
});
