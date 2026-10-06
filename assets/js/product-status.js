/* Availability is advisory on the site; the loader enforces the same feed. */
(() => {
  'use strict';
  const feedURL = 'https://raw.githubusercontent.com/Rendererrr/Rendererrr.github.io/main/scooby/product-status.json';
  const labels = { online: 'Online', updating: 'Updating', offline: 'Offline', disabled: 'Disabled' };
  const aliases = { 'half-life-1': 'halflife', 'half-life-2': 'hl2', 'last-of-us': 'tlou', 'lastofuspart1': 'tlou', 's-and-box': 'sbox' };
  const key = id => aliases[id] || id;
  const routeId = path => key((path.match(/\/products\/([^/]+)/) || [])[1]);
  const pageId = location.pathname.startsWith('/download') ? 'loader' : routeId(location.pathname);
  const actionSelector = '[data-buy], [data-free], .purchase-btn:not([href^="/guides/"]):not([href^="/features-list/"]):not([href^="/api/"]), #loader-download, [data-product-access]';
  let current = null, pending = false;
  const previous = new WeakMap();
  function validate(data) {
    if (!data || data.schema !== 1 || !data.products || Array.isArray(data.products) || typeof data.products !== 'object' || !Object.keys(data.products).length) throw new Error('Invalid status feed');
    for (const [id, entry] of Object.entries(data.products)) {
      if (!/^[a-z][a-z0-9-]{0,63}$/.test(id) || !entry || !Object.hasOwn(labels, entry.state) || (entry.message !== undefined && (typeof entry.message !== 'string' || entry.message.length > 960))) throw new Error('Invalid status entry');
    }
    return data;
  }
  function entry(id) {
    if (!current || !id) return null;
    const global = current.products.loader;
    return global && global.state !== 'online' ? global : current.products[key(id)] || null;
  }
  function productOf(el) {
    const container = el.closest('[data-product], [data-status-product]');
    return key(el.getAttribute('data-buy') || container?.dataset.statusProduct || container?.dataset.product || pageId);
  }
  function actionBlocked(el) {
    const id = productOf(el), status = entry(id);
    if (!status || status.state === 'online') return false;
    // FiveM licenses remain purchasable during its update; loading/free access
    // and loader-wide outages still follow the availability feed.
    const updatingPurchase = id === 'fivem' && status === current.products.fivem &&
      status.state === 'updating' && el.matches('[data-buy="fivem"]');
    return !updatingPurchase;
  }
  function badge(el, status) {
    if (el.hasAttribute('data-static-status')) return;
    const text = labels[status.state];
    if (el.textContent !== text) el.textContent = text;
    if (el.dataset.availability !== status.state) el.dataset.availability = status.state;
    if (el.title !== (status.message || text)) el.title = status.message || text;
  }
  function render() {
    if (!current) return;
    for (const card of document.querySelectorAll('[data-product], .catalog-card, .source-card, .game-card, .more-game-card')) {
      const id = key(card.dataset.product || routeId(card.getAttribute('href') || card.querySelector('a[href*="/products/"]')?.getAttribute('href') || ''));
      const status = entry(id); if (!status) continue;
      card.dataset.statusProduct = id;
      const badges = card.querySelectorAll('.catalog-status, .product-badge, .status-badge, .game-status, .source-availability, [data-status-badge]');
      for (const el of badges) if (/^(online|updating|offline|disabled|coming soon|released)$/i.test(el.textContent.trim()) || el.hasAttribute('data-availability')) badge(el, status);
    }
    const status = entry(pageId);
    if (status && !document.querySelector('.product-heading [data-static-status]')) {
      const heading = document.querySelector('.product-heading-badges, .product-heading, .download-card, main h1');
      if (heading) {
        let el = heading.querySelector('[data-live-status]');
        if (!el) {
          el = [...heading.querySelectorAll('.product-status')].find(node => /^(online|updating|offline|disabled)$/i.test(node.textContent.trim()));
          if (!el) { el = document.createElement('span'); el.className = 'product-status'; heading.append(el); }
          el.dataset.liveStatus = ''; el.setAttribute('role', 'status');
        }
        badge(el, status);
        let note = document.querySelector('[data-status-message]');
        if (!note) { note = document.createElement('p'); note.dataset.statusMessage = ''; note.className = 'availability-message'; (heading.closest('.product-heading') || heading).insertAdjacentElement('afterend', note); }
        let message = status.state === 'online' ? '' : status.message || `${labels[status.state]}: access is temporarily unavailable. Please check back later.`;
        if (pageId === 'tf2' && current.products['tf2-classified']) {
          const classified = entry('tf2-classified');
          if (classified.state !== status.state) message += `${message ? ' ' : ''}TF2 Classified: ${labels[classified.state]}. ${classified.message || ''}`;
        }
        if (note.textContent !== message) note.textContent = message;
        note.hidden = !message;
      }
    }
    for (const el of document.querySelectorAll(actionSelector)) {
      const status = entry(productOf(el)); const blocked = actionBlocked(el);
      if (blocked) {
        if (!previous.has(el)) previous.set(el, { aria: el.getAttribute('aria-disabled'), title: el.getAttribute('title') });
        el.dataset.statusBlocked = 'true'; el.setAttribute('aria-disabled', 'true');
        el.title = status.message || `${labels[status.state]}: access is currently unavailable.`;
      } else if (previous.has(el)) {
        const old = previous.get(el); previous.delete(el); delete el.dataset.statusBlocked;
        if (old.aria === null) el.removeAttribute('aria-disabled'); else el.setAttribute('aria-disabled', old.aria);
        if (old.title === null) el.removeAttribute('title'); else el.setAttribute('title', old.title);
      }
    }
  }
  document.addEventListener('click', event => {
    const action = event.target.closest?.(actionSelector); if (!action) return;
    if (actionBlocked(action)) { event.preventDefault(); event.stopImmediatePropagation(); }
  }, true);
  async function fetchStatus(url) {
    const controller = new AbortController(); const timeout = setTimeout(() => controller.abort(), 6000);
    try {
      const response = await fetch(url, { cache: 'no-store', credentials: 'omit', signal: controller.signal });
      if (!response.ok) throw new Error('Unavailable status feed');
      const text = await response.text(); if (text.length > 65536) throw new Error('Status feed too large');
      return validate(JSON.parse(text));
    } finally { clearTimeout(timeout); }
  }
  async function refresh() {
    if (pending) return; pending = true;
    try {
      current = await fetchStatus(location.hostname === '127.0.0.1' || location.hostname === 'localhost' ? '/assets/data/product-status.json' : feedURL + '?minute=' + Math.floor(Date.now() / 60000)); render();
      try { localStorage.setItem('scooby.product-status.v1', JSON.stringify(current)); } catch (_) {}
    } catch (_) {
      // Retain the last valid feed through transport errors and malformed updates.
      if (!current) try { current = await fetchStatus('/assets/data/product-status.json'); render(); } catch (_) {}
    } finally { pending = false; }
  }
  function start() {
    try { current = validate(JSON.parse(localStorage.getItem('scooby.product-status.v1'))); render(); } catch (_) {}
    refresh(); setInterval(refresh, 60000);
    // Catalogs may render dynamically; watch inserted nodes, never our own attributes/text.
    new MutationObserver(records => { if (records.some(r => [...r.addedNodes].some(n => n.nodeType === 1))) render(); }).observe(document.body, { childList: true, subtree: true });
    document.addEventListener('visibilitychange', () => { if (!document.hidden) refresh(); });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start, { once: true }); else start();
})();
