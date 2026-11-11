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
    { id: 'xforce', name: 'X-Force' }, { id: 'yim', name: 'Yim', deferred: true }
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
  // A resource may be discoverable in Scooby's collection while retaining its
  // required original format or compatibility layer in the item details.
  const supports = (entry, menu) => Array.isArray(entry?.listedMenus) && !isCheraxTheme(entry)
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
  return { MENUS, canonical, menusFor, menuFor, menuName, displayName: menuName, categoryGroups, gtaCategoryGroups: categoryGroups, categoryLabel, menuIds, supports, compatibleWith, isCheraxTheme, themeInterface, legacyOverrideMap };
});
