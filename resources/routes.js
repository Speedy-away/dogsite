(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ScoobyResourceRoutes = api;
})(globalThis, function () {
  'use strict';
  const base = '/resources/';
  const guideBase = `${base}guides/`;

  function collectionPath(game, category, menu = 'scooby', archive = '') {
    const directory = (game === 'gta5' || game === 'rdr2') && menu !== 'scooby' ? `${game}/${menu}` : game;
    const section = game === 'gta5' && menu === 'stand' && archive === 'old-shares' ? 'old-shares/' : '';
    return `${base}${directory}/${section}${category && category !== 'all' ? `${category}/` : ''}`;
  }

  function catalogURL({ game, menu = 'scooby', category, archive, page, ...filters }, published) {
    const collection = collectionPath(game, undefined, menu, archive);
    const categoryPath = collectionPath(game, category, menu, archive);
    const query = new URLSearchParams();
    const pathname = published.has(categoryPath) ? categoryPath : published.has(collection) ? collection : base;
    if (pathname === base) {
      query.set('game', game);
      if (menu !== 'scooby') query.set('menu', menu);
    }
    if (pathname !== categoryPath && category && category !== 'all') query.set('category', category);
    for (const key of ['edition', 'q', 'tag', 'model', 'ui', 'style', 'sort', 'format']) {
      if (filters[key]) query.set(key, filters[key]);
    }
    if (page > 1) query.set('page', page);
    return pathname + (query.size ? `?${query}` : '');
  }

  function guidePath(game, category, menu) {
    return guideBase + collectionPath(game, category, menu).slice(base.length);
  }

  function guideURL({ game, menu, category }, published, hash = '') {
    const path = published[guidePath(game, category, menu)] || published[guidePath(game, 'all', menu)] || guideBase;
    return path + hash;
  }

  function resourceHash(id, view = 'preview') {
    const prefix = view === 'changelog' ? 'changelog' : 'resource';
    return `#${prefix}-${String(id).replace(/[^a-z0-9_-]/gi, '-')}`;
  }

  function resourceView(hash) {
    if (hash.startsWith('#resource-')) return 'preview';
    if (hash.startsWith('#changelog-')) return 'changelog';
    return '';
  }

  return { base, collectionPath, catalogURL, guideBase, guidePath, guideURL, resourceHash, resourceView };
});
