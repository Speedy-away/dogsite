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
  const assetCategories = new Set(['vehicles', 'modded', 'outfits', 'maps', 'dlc', 'textures', 'paintjobs', 'liveries', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-maps', 'addon-clothing', 'addon-animations']);
  function menuIds(entry) {
    if (!entry || entry.game !== 'gta5') return ['scooby'];
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
  const supports = (entry, menu) => Array.isArray(entry?.listedMenus)
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
  return { MENUS, canonical, menuFor, menuName, displayName: menuName, menuIds, supports, compatibleWith, legacyOverrideMap };
});
