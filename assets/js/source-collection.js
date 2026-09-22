/* All cards and links remain usable without JavaScript. */
(() => {
  'use strict';
  const tools = document.querySelector('.collection-tools');
  if (!tools) return;
  const input = document.getElementById('source-game-search');
  const cards = Array.from(document.querySelectorAll('[data-game]'));
  const sections = Array.from(document.querySelectorAll('[data-catalog-section]'));
  const filters = Array.from(document.querySelectorAll('[data-engine-filter]'));
  const status = document.getElementById('collection-results');
  const empty = document.getElementById('collection-empty');
  const normalize = value => value.toLowerCase().replace(/[^a-z0-9]+/g, '');
  let engine = 'all';
  function update() {
    const query = normalize(input.value);
    let count = 0;
    cards.forEach(card => {
      const match = (engine === 'all' || card.dataset.engine === engine) && normalize(card.dataset.search).includes(query);
      card.hidden = !match;
      if (match) count++;
    });
    sections.forEach(section => {
      const visible = section.querySelectorAll('[data-game]:not([hidden])').length;
      section.hidden = visible === 0;
      section.querySelector('.source-section-count').textContent = String(visible).padStart(2, '0');
    });
    filters.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.engineFilter === engine)));
    status.textContent = `${count} of ${cards.length} games & collections`;
    empty.hidden = count > 0;
  }
  function reset() { engine = 'all'; input.value = ''; update(); }
  filters.forEach(button => button.addEventListener('click', () => { engine = button.dataset.engineFilter; update(); }));
  input.addEventListener('input', update);
  document.getElementById('collection-reset').addEventListener('click', () => { reset(); input.focus(); });
  document.querySelectorAll('.collection-hero-actions a').forEach(link => link.addEventListener('click', reset));
  tools.hidden = false;
  status.hidden = false;
  update();
})();
