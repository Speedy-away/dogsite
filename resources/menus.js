(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ScoobyMenus = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const MENUS = [
    { id: 'scooby', name: 'Scooby' }, { id: 'nenyoo', name: 'Nenyoo' },
    { id: 'cherax', name: 'Cherax' }, { id: 'stand', name: 'Stand', source: { url: 'https://github.com/calamity-inc/Stand-OSS', label: 'Stand source on GitHub ↗' } },
    { id: 'xforce', name: 'X-Force' }, { id: 'yim', name: 'Yim', deferred: true }
  ];
  const key = value => String(value || '').toLowerCase().replace(/[^a-z0-9]/g, '');
  const canonical = value => MENUS.find(menu => menu.id === key(value))?.id || '';
  const menuFor = (game, value) => game === 'gta5' ? canonical(value) || 'scooby' : 'scooby';
  const menuName = value => MENUS.find(menu => menu.id === canonical(value))?.name || 'Scooby';
  const gtaFiles = ['themes', 'configs', 'lua', 'languages', 'wallpapers', 'misc'];
  const gtaResourceOrder = ['vehicles', 'modded', 'outfits', 'maps', 'textures', 'graphics-packs', 'paintjobs', 'liveries', 'asi-mods', 'dotnet-mods'];
  const gtaAddonOrder = ['addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing', 'addon-packs'];
  function gtaCategoryGroups(menu, ids) {
    if (MENUS.find(item => item.id === canonical(menu))?.deferred) return [];
    const available = new Set(ids);
    const ordered = [...new Set([...gtaResourceOrder, ...gtaAddonOrder, ...available])].filter(id => available.has(id));
    const name = menuName(menu);
    return [
      [`${name} Files`, gtaFiles.filter(id => available.has(id))],
      [`${name} Resources`, ordered.filter(id => !gtaFiles.includes(id) && !id.startsWith('addon-'))],
      ['Addons', ordered.filter(id => id.startsWith('addon-'))]
    ].filter(([, group]) => group.length);
  }
  const assetCategories = new Set(['vehicles', 'modded', 'outfits', 'maps', 'dlc', 'textures', 'paintjobs', 'liveries', ...gtaAddonOrder]);
  const isCheraxTheme = entry => entry?.game === 'gta5' && entry.category === 'themes' && (
    canonical(entry.sourceMenu) === 'cherax' || entry.source === 'ModVerse public catalog' ||
    /^(?:menu-cherax-theme-|gta5-modverse-themes-)/.test(entry.id || '')
  );
  const themeInterface = entry => entry?.uiStyle || (isCheraxTheme(entry) ? 'ClickGUI' : undefined);
  function menuIds(entry) {
    if (!entry || entry.game !== 'gta5') return ['scooby'];
    if (isCheraxTheme(entry)) return ['cherax'];
    if (Array.isArray(entry.supportedMenus)) return [...new Set(entry.supportedMenus.map(canonical).filter(Boolean))];
    const origin = canonical(entry.sourceMenu);
    if (origin) {
      const compatibleData = assetCategories.has(entry.category);
      return [...new Set([origin, ...(compatibleData && ['scooby', 'nenyoo', 'cherax', 'stand'].includes(origin) ? ['scooby', 'nenyoo'] : [])])];
    }
    if (entry.source === 'ModVerse public catalog') return ['scooby', 'nenyoo', 'cherax'];
    // Existing native Scooby exports remain in their original collection.
    // Resource styles named after another menu do not imply that menu's format.
    return assetCategories.has(entry.category) ? ['scooby', 'nenyoo'] : ['scooby'];
  }
  const compatibleWith = (entry, menu) => menuIds(entry).includes(canonical(typeof menu === 'object' ? menu.id : menu) || 'scooby');
  // A resource may be discoverable in Scooby's collection while retaining its
  // required original format or compatibility layer in the item details.
  const supports = (entry, menu) => Array.isArray(entry?.listedMenus) && !isCheraxTheme(entry)
    ? entry.listedMenus.map(canonical).includes(canonical(typeof menu === 'object' ? menu.id : menu) || 'scooby')
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
  return { MENUS, canonical, menuFor, menuName, displayName: menuName, gtaCategoryGroups, menuIds, supports, compatibleWith, isCheraxTheme, themeInterface, legacyOverrideMap };
});
