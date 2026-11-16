(() => {
  'use strict';
  const tabs = [...document.querySelectorAll('[data-catalog-platform]')];
  const views = [...document.querySelectorAll('[data-platform-view]')];
  const select = platform => {
    tabs.forEach(tab => tab.setAttribute('aria-pressed', String(tab.dataset.catalogPlatform === platform)));
    views.forEach(view => { view.hidden = view.dataset.platformView !== platform; });
    document.querySelectorAll('[data-console-system]').forEach(selector => { selector.hidden = platform !== 'console'; });
  };
  const fromHash = () => {
    let saved = 'pc';
    try { if (localStorage.getItem('scooby.platform') === 'console') saved = 'console'; } catch (_) {}
    const hash = location.hash;
    const target = document.getElementById(hash.slice(1));
    const targetPlatform = target?.closest('[data-platform-view]')?.dataset.platformView;
    select(hash === '#console' ? 'console' : hash === '#pc' ? 'pc' : targetPlatform || saved);
  };
  tabs.forEach(tab => tab.addEventListener('click', () => {
    const platform = tab.dataset.catalogPlatform;
    try { localStorage.setItem('scooby.platform', platform); } catch (_) {}
    history.replaceState(null, '', '#' + platform);
    select(platform);
  }));
  window.addEventListener('hashchange', fromHash);
  fromHash();
  const search = document.getElementById('console-game-filter');
  if (search) {
    const entries = [...document.querySelectorAll('[data-console-guide]')];
    const filters = [...document.querySelectorAll('[data-console-category-filter]')];
    let category = 'all';
    const update = () => {
      const words = search.value.toLowerCase().trim().split(/\s+/).filter(Boolean);
      entries.forEach(entry => { entry.hidden = !((category === 'all' || entry.dataset.consoleCategory === category) && words.every(word => entry.dataset.consoleGuide.toLowerCase().includes(word))); });
      const count = entries.filter(entry => !entry.hidden).length;
      document.getElementById('console-guide-count').textContent = count + (count === 1 ? ' guide' : ' guides');
      document.getElementById('console-guide-empty').hidden = count !== 0;
      const apps = document.getElementById('console-wiki-apps');
      if (apps) apps.hidden = !entries.some(entry => entry.dataset.consoleCategory === 'apps' && !entry.hidden);
      filters.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.consoleCategoryFilter === category)));
    };
    filters.forEach(button => button.addEventListener('click', () => { category = button.dataset.consoleCategoryFilter; update(); }));
    search.addEventListener('input', update);
    document.getElementById('console-guide-search').addEventListener('submit', event => event.preventDefault());
  }
})();
