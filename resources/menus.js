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
    { id: 'xforce', name: 'X-Force' }, { id: 'yim', name: 'Yim' }
  ];
  const key = value => String(value || '').toLowerCase().replace(/[^a-z0-9]/g, '');
  const canonical = value => MENUS.find(menu => menu.id === key(value))?.id || '';
  const menusFor = game => game === 'gta5' ? MENUS : MENUS.slice(0, game === 'rdr2' ? 2 : 1);
  const menuFor = (game, value) => menusFor(game).find(menu => menu.id === canonical(value))?.id || 'scooby';
  const menuName = value => MENUS.find(menu => menu.id === canonical(value))?.name || 'Scooby';
  const menuFiles = ['themes', 'configs', 'lua', 'languages', 'loader-translations', 'fonts', 'emotes', 'wallpapers', 'misc'];
  const gtaResourceOrder = ['vehicles', 'modded', 'outfits', 'maps', 'textures', 'graphics-packs', 'paintjobs', 'liveries', 'asi-mods', 'dotnet-mods'];
  const gtaAddonOrder = ['addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing', 'addon-packs'];
  function categoryGroups(menu, ids) {
    if (MENUS.find(item => item.id === canonical(menu))?.deferred) return [];
    const available = new Set(ids);
    const resources = menu === 'nenyoo' ? [...gtaResourceOrder.slice(0, -2), 'addon-packs', ...gtaResourceOrder.slice(-2)] : gtaResourceOrder;
    const ordered = [...new Set([...resources, ...gtaAddonOrder, ...available])].filter(id => available.has(id));
    const isAddon = id => id.startsWith('addon-') && !(menu === 'nenyoo' && id === 'addon-packs');
    const name = menuName(menu);
    return [
      [`${name} Files`, menuFiles.filter(id => available.has(id))],
      [`${name} Resources`, ordered.filter(id => !menuFiles.includes(id) && !isAddon(id))],
      ['Addons', ordered.filter(isAddon)]
    ].filter(([, group]) => group.length);
  }
  const categoryLabel = (menu, id) => menu === 'nenyoo' ? { 'addon-packs': 'DLC packs', languages: 'Translations / Languages', themes: 'Themes', maps: 'Maps' }[id] : undefined;
  const assetCategories = new Set(['vehicles', 'modded', 'outfits', 'maps', 'dlc', 'textures', 'paintjobs', 'liveries', ...gtaAddonOrder]);
  const isCheraxTheme = entry => entry?.game === 'gta5' && entry.category === 'themes' && (
    canonical(entry.sourceMenu) === 'cherax' || entry.source === 'ModVerse public catalog' ||
    /^(?:menu-cherax-theme-|gta5-modverse-themes-)/.test(entry.id || '')
  );
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
  function presetFormatScope(entries, menu) {
    let hasLua = false, hasNative = false, hasAlternate = false;
    if (presetLoaderMenus.has(menu)) for (const entry of entries) {
      const loader = presetLoader(entry, menu);
      hasLua ||= loader === 'lua';
      hasNative ||= loader === 'native';
      hasAlternate ||= loader === 'lua' || loader === 'importer';
      if (hasAlternate && hasNative) break;
    }
    return { hasLua, hasAlternate, nativeDefault: hasAlternate && hasNative };
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
      return [...new Set([origin, ...(compatibleData && ['scooby', 'nenyoo', 'cherax', 'stand'].includes(origin) ? ['scooby', 'nenyoo'] : [])])];
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
  // Themes and scripts follow their supported runtimes. Shared assets can have broader discovery listings.
  const supports = (entry, menu) => Array.isArray(entry?.listedMenus) &&
    !(['gta5', 'rdr2'].includes(entry.game) && ['themes', 'lua'].includes(entry.category))
    ? validMenus(entry.game, entry.listedMenus).includes(canonical(typeof menu === 'object' ? menu.id : menu) || 'scooby')
    : compatibleWith(entry, menu);
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
  return { MENUS, canonical, menusFor, menuFor, menuName, displayName: menuName, categoryGroups, gtaCategoryGroups: categoryGroups, categoryLabel, menuIds, supports, compatibleWith, isCheraxTheme, themeInterface, legacyOverrideMap, fileFormat, fileExtension, formatExtensions, presetLoader, alternatePreset, presetLoaderNote, presetFormatScope, presetFormatHint };
});
