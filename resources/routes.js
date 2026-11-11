(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ScoobyResourceRoutes = api;
})(globalThis, function () {
  'use strict';
  const base = '/resources/';
  const guideBase = `${base}guides/`;

  function collectionPath(game, category, menu = 'scooby') {
    const directory = (game === 'gta5' || game === 'rdr2') && menu !== 'scooby' ? `${game}/${menu}` : game;
    return `${base}${directory}/${category && category !== 'all' ? `${category}/` : ''}`;
  }

  function catalogURL({ game, menu = 'scooby', category, page, ...filters }, published) {
    const collection = collectionPath(game, undefined, menu);
    const categoryPath = collectionPath(game, category, menu);
    const query = new URLSearchParams();
    const pathname = published.has(categoryPath) ? categoryPath : published.has(collection) ? collection : base;
    if (pathname === base) {
      query.set('game', game);
      if (menu !== 'scooby') query.set('menu', menu);
    }
    if (pathname !== categoryPath && category && category !== 'all') query.set('category', category);
    for (const key of ['edition', 'q', 'model', 'ui', 'style', 'sort']) {
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

  function resourceHash(id) {
    return `#resource-${String(id).replace(/[^a-z0-9_-]/gi, '-')}`;
  }

  return { base, collectionPath, catalogURL, guideBase, guidePath, guideURL, resourceHash };
});
