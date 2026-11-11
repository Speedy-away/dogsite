(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ScoobyMenus = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const MENUS = [
    { id: 'scooby', name: 'Scooby' }, { id: 'nenyoo', name: 'Nenyoo', source: { url: 'https://github.com/walteryo1337/Nenyoo-Resources', label: 'Nenyoo resources on GitHub ↗' } },
    { id: 'cherax', name: 'Cherax' }, { id: 'stand', name: 'Stand', source: { url: 'https://github.com/calamity-inc/Stand-OSS', label: 'Stand source on GitHub ↗' } },
    { id: 'xforce', name: 'X-Force' },
    { id: 'yim', name: 'Yim v1 (Legacy)', yim: {
      brand: 'YimMenu v1', edition: 'Legacy',
      presetTitles: { vehicles: 'JSON & XML Vehicle Packs', maps: 'XML Map Packs', outfits: 'JSON Outfit Packs' }
    } },
    { id: 'yimv2', name: 'Yim v2 (Enhanced)', yim: { brand: 'YimMenu v2', edition: 'Enhanced' } }
  ];
  const key = value => String(value || '').toLowerCase().replace(/[^a-z0-9]/g, '');
  const canonical = value => MENUS.find(menu => menu.id === key(value))?.id || '';
  const menusFor = game => game === 'gta5' ? MENUS : MENUS.slice(0, game === 'rdr2' ? 2 : 1);
  const menuFor = (game, value) => menusFor(game).find(menu => menu.id === canonical(value))?.id || 'scooby';
  const menuName = value => MENUS.find(menu => menu.id === canonical(value))?.name || 'Scooby';
  function defaultResourceSort({ game, menu, category }) {
    const yimLua = game === 'gta5' && ['yim', 'yimv2'].includes(menu) && (!category || ['all', 'lua'].includes(category));
    return yimLua ? 'updated' : 'added';
  }
  const dateFormat = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' });
  function resourceUpdateDate(entry) {
    const timestamp = Date.parse(entry.updatedAt);
    return Number.isFinite(timestamp) ? dateFormat.format(timestamp) : '';
  }
  const compareResourceUpdates = (a, b) => (Date.parse(b.updatedAt) || 0) - (Date.parse(a.updatedAt) || 0) || a.name.localeCompare(b.name, 'en');
  const menuFiles = ['themes', 'configs', 'lua', 'languages', 'loader-translations', 'fonts', 'emotes', 'wallpapers', 'misc'];
  const gtaResourceOrder = ['vehicles', 'modded', 'outfits', 'maps', 'textures', 'graphics-packs', 'paintjobs', 'liveries', 'asi-mods', 'dotnet-mods'];
  const gtaAddonOrder = ['addon-vehicles', 'addon-peds', 'addon-weapons', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing'];
  const packLabels = { 'pack-vehicles': 'Vehicles', 'pack-outfits': 'Outfits', 'pack-all-in-one': 'All in one', 'pack-maps': 'Maps', 'addon-packs': 'DLC packs' };
  function categoryGroups(menu, ids) {
    if (MENUS.find(item => item.id === canonical(menu))?.deferred) return [];
    const available = new Set(ids);
    const ordered = [...new Set([...gtaResourceOrder, ...gtaAddonOrder, ...available])].filter(id => available.has(id));
    const isPack = id => Object.hasOwn(packLabels, id);
    const isAddon = id => id.startsWith('addon-') && !isPack(id);
    const name = menuName(menu);
    return [
      [`${name} Files`, menuFiles.filter(id => available.has(id))],
      [`${name} Resources`, ordered.filter(id => !menuFiles.includes(id) && !isAddon(id) && !isPack(id))],
      ['Addons', ordered.filter(isAddon)],
      ['Packs', Object.keys(packLabels).filter(id => available.has(id))]
    ].filter(([, group]) => group.length);
  }
  const categoryLabel = (menu, id) => packLabels[id] || (menu === 'nenyoo' ? { languages: 'Translations / Languages', themes: 'Themes', maps: 'Maps' }[id] : undefined);
  const assetCategories = new Set(['vehicles', 'modded', 'outfits', 'maps', 'dlc', 'textures', 'paintjobs', 'liveries', ...gtaAddonOrder, ...Object.keys(packLabels)]);
  const isStandLua = entry => entry?.game === 'gta5' && entry.category === 'lua' && canonical(entry.sourceMenu) === 'stand';
  const isCheraxTheme = entry => entry?.game === 'gta5' && entry.category === 'themes' && (
    canonical(entry.sourceMenu) === 'cherax' || entry.source === 'ModVerse public catalog' ||
    /^(?:menu-cherax-theme-|gta5-modverse-themes-)/.test(entry.id || '')
  );
  const nativeFileCategories = new Set(['configs', 'lua', 'languages', 'loader-translations']);
  const presetCategories = new Set(['vehicles', 'modded', 'outfits', 'maps']);
  const presetLoaderMenus = new Set(['cherax', 'stand', 'xforce']);
  const archives = new Set(['zip', 'rar', '7z', 'gz']);
  const fileFormat = value => String(value || '').toLowerCase().match(/^\.?([a-z0-9_]{1,10})$/)?.[1] || '';
  const pathFormat = value => String(value || '').split(/[?#]/)[0].toLowerCase()
    .match(/\.(?:(zip|7z|rar)\.\d{3}|([a-z0-9_]{1,10}))$/)?.slice(1).find(Boolean) || '';
  function fileExtension(file) {
    const filenameFormat = pathFormat(file?.formatPath) || pathFormat(file?.name) || pathFormat(file?.path);
    if (filenameFormat) return filenameFormat;
    let url = file?.url;
    try { url = decodeURIComponent(url); } catch { /* Keep the original path. */ }
    return pathFormat(url);
  }
  function formatExtensions(entry) {
    const formats = (entry.files || []).map(fileExtension).filter(Boolean);
    if (entry.sourceMenu === 'yim' && ['json', 'xml'].includes(entry.formatExtension) && formats.every(ext => archives.has(ext))) {
      return [entry.formatExtension];
    }
    const fallback = fileFormat(entry.formatExtension) || pathFormat(entry.sourceFilename) || (entry.builtInLua ? 'lua' : '');
    return [...new Set(formats.length ? formats : fallback ? [fallback] : [])];
  }
  function presetLoader(entry, menu) {
    if (entry.game !== 'gta5' || !presetCategories.has(entry.category) || !presetLoaderMenus.has(menu)) return '';
    const formats = formatExtensions(entry);
    const schema = entry.sourceFormat || entry.format || '';
    const origin = canonical(entry.sourceMenu);
    if (menu === 'xforce') {
      const native = origin === 'xforce' && (
        (/^X-Force vehicle INI\b/i.test(schema) && formats.includes('ini')) ||
        (/^X-Force outfit JSON\b/i.test(schema) && formats.includes('json')) ||
        (/^X-Force archive with .* (?:JSON|XFO) outfit preset/i.test(schema) && formats.some(ext => archives.has(ext)))
      );
      return native ? 'native' : 'importer';
    }
    if (menu === 'cherax') {
      return origin === 'cherax' && formats.includes('json') && /^Cherax (?:vehicle|outfit) JSON\b/i.test(schema) ? 'native' : 'lua';
    }
    // Some archives are known to contain Stand TXT files. A TXT suffix alone
    // can also hide INI data, so honor the inspected schema when available.
    const standTxt = /^Stand (?:vehicle|outfit) TXT\b/i.test(schema);
    const nativeTxt = formats.includes('txt') && (!entry.sourceFormat || standTxt);
    return origin === 'stand' && entry.category !== 'maps' && (nativeTxt || (standTxt && formats.some(ext => archives.has(ext))))
      ? 'native' : 'lua';
  }
  function alternatePreset(entry, menu) {
    const loader = presetLoader(entry, menu);
    return loader === 'lua' || loader === 'importer';
  }
  function presetLoaderNote(entry, menu) {
    const loader = presetLoader(entry, menu);
    if (loader === 'importer') return 'Check the importer for this format in your X-Force version.';
    if (loader !== 'lua') return '';
    const label = entry.requirementLabel || '';
    if (menu === 'cherax' && /BiggerScript/i.test(label)) return 'Requires BiggerScript for Cherax (Lua)';
    if (menu === 'stand' && /Constructor/i.test(label)) return 'Requires Constructor for Stand (Lua)';
    if (menu === 'stand' && /Jackz|JSTAND/i.test(entry.sourceFormat || entry.format || '')) return 'Requires a compatible Jackz Builder / JSTAND Lua loader';
    return `Requires a compatible ${menuName(menu)} Lua loader`;
  }
  function presetFormatScope(entries, menu, category) {
    let hasLua = false, hasNative = false, hasAlternate = false;
    if (presetLoaderMenus.has(menu)) for (const entry of entries) {
      const loader = presetLoader(entry, menu);
      hasLua ||= loader === 'lua';
      hasNative ||= loader === 'native';
      hasAlternate ||= loader === 'lua' || loader === 'importer';
      if (hasAlternate && hasNative) break;
    }
    return { hasLua, hasAlternate, nativeDefault: hasAlternate && (hasNative || (hasLua && category === 'all')) };
  }
  function presetFormatHint(menu, nativeDefault, category) {
    if (menu === 'xforce') {
      if (!nativeDefault) return 'Check the importer for these presets in your X-Force version.';
      return 'X-Force presets are shown by default. Choose “All formats” to see the other presets.';
    }
    if (!nativeDefault) return `These presets require a compatible Lua loader for ${menuName(menu)}.`;
    if (category === 'all') return 'Presets that need a Lua loader are hidden by default. Choose “Lua loader required” to see them.';
    const native = menu === 'cherax' ? 'Cherax .json' : 'Stand .txt';
    return `${native} presets are shown by default. Choose “Lua loader required” for other presets.`;
  }
  const themeInterface = entry => entry?.uiStyle || (isCheraxTheme(entry) ? 'ClickGUI' : undefined);
  function menuIds(entry) {
    if (!entry || menusFor(entry.game).length === 1) return ['scooby'];
    if (isCheraxTheme(entry)) return ['cherax'];
    if (Array.isArray(entry.supportedMenus)) return validMenus(entry.game, entry.supportedMenus);
    const origin = canonical(entry.sourceMenu);
    if (entry.game === 'rdr2') return [menuFor(entry.game, origin)];
    if (origin) {
      const compatibleData = assetCategories.has(entry.category);
      return compatibleData && ['scooby', 'nenyoo'].includes(origin) ? ['scooby', 'nenyoo'] : [origin];
    }
    if (entry.source === 'ModVerse public catalog') return ['scooby', 'nenyoo', 'cherax'];
    // Existing native Scooby exports remain in their original collection.
    // Resource styles named after another menu do not imply that menu's format.
    return assetCategories.has(entry.category) ? ['scooby', 'nenyoo'] : ['scooby'];
  }
  function validMenus(game, values) {
    const allowed = menusFor(game).map(menu => menu.id);
    return [...new Set(values.map(canonical).filter(id => allowed.includes(id)))];
  }
  const compatibleWith = (entry, menu) => menuIds(entry).includes(canonical(typeof menu === 'object' ? menu.id : menu) || 'scooby');
  function listingMenuIds(entry) {
    if (entry?.game === 'gta5') {
      const compatible = menuIds(entry);
      const origin = canonical(entry.sourceMenu);
      // A UI preset can also be filed under Themes, but belongs to the same menu in both views.
      const nativeFile = nativeFileCategories.has(entry.category) || entry.categories?.some(id => nativeFileCategories.has(id));
      if (nativeFile && compatible.includes(origin)) return [origin];
      if (entry.category === 'addon-vehicles' && entry.status === 'author-hosted' && Array.isArray(entry.listedMenus)) {
        return validMenus(entry.game, entry.listedMenus);
      }
      if (entry.category?.startsWith('addon-') && !['addon-vehicles', 'addon-packs'].includes(entry.category)) {
        return compatible.filter(menu => menu !== 'cherax' && menu !== 'stand');
      }
      return compatible;
    }
    if (Array.isArray(entry?.listedMenus) && !(entry.game === 'rdr2' && ['themes', 'lua'].includes(entry.category))) {
      return validMenus(entry.game, entry.listedMenus);
    }
    return menuIds(entry);
  }
  const supports = (entry, menu) => listingMenuIds(entry).includes(canonical(typeof menu === 'object' ? menu.id : menu) || 'scooby');
  function cheraxLuaLayerNote(entry) {
    return entry?.game === 'gta5' && entry.category === 'lua' && canonical(entry.sourceMenu) === 'cherax'
      ? 'In Scooby, use the Cherax Lua compatibility layer to load this script.' : '';
  }
  function legacyOverrideMap(supplement) {
    const result = new Map();
    for (const group of supplement?.legacyGroups || []) {
      if (!['vehicles', 'outfits'].includes(group.family) || !Array.isArray(group.indices)) continue;
      for (const index of group.indices) if (Number.isSafeInteger(index) && index >= 0) result.set(`${group.family}:${index}`, { ...group.metadata, family: group.family, index });
    }
    for (const entry of supplement?.legacyOverrides || []) if (['vehicles', 'outfits'].includes(entry.family) && Number.isSafeInteger(entry.index) && entry.index >= 0) {
      const key = `${entry.family}:${entry.index}`;
      result.set(key, { ...result.get(key), ...entry });
    }
    return result;
  }
  return { MENUS, canonical, menusFor, menuFor, menuName, displayName: menuName, defaultResourceSort, resourceUpdateDate, compareResourceUpdates, categoryGroups, gtaCategoryGroups: categoryGroups, categoryLabel, menuIds, listingMenuIds, supports, compatibleWith, cheraxLuaLayerNote, isCheraxTheme, isStandLua, themeInterface, legacyOverrideMap, fileFormat, fileExtension, formatExtensions, presetLoader, alternatePreset, presetLoaderNote, presetFormatScope, presetFormatHint };
});
