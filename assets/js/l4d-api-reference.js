(() => {
  const input = document.getElementById('api-search');
  const clear = document.getElementById('clear-search');
  const status = document.getElementById('search-status');
  const entries = [...document.querySelectorAll('.reference-entry')];
  const sections = [...document.querySelectorAll('.reference-section')];
  const links = [...document.querySelectorAll('#sidebar-nav .entry')];
  const text = entries.map(entry => entry.textContent.toLowerCase());
  const filter = () => {
    const words = input.value.trim().toLowerCase().split(/\s+/).filter(Boolean);
    let visible = 0;
    entries.forEach((entry,i) => {
      const match = words.every(word => text[i].includes(word));
      entry.hidden = !match;
      links[i].hidden = !match;
      if (match) visible++;
    });
    sections.forEach(section => {
      section.hidden = ![...section.querySelectorAll('.reference-entry')].some(entry => !entry.hidden);
      document.querySelector(`[data-section="${section.id}"]`).hidden = section.hidden;
    });
    status.textContent = words.length ? `${visible} matching topic${visible === 1 ? '' : 's'}` : `${entries.length} reference topics · Press / to search`;
    document.getElementById('no-results').hidden = visible !== 0;
    clear.hidden = !input.value;
  };
  const reset = () => { input.value = ''; filter(); };
  input.addEventListener('input', filter);
  clear.addEventListener('click', () => { reset(); input.focus(); });
  const toggle = document.querySelector('.menu-toggle');
  const close = () => { document.body.classList.remove('menu-open'); toggle.setAttribute('aria-expanded','false'); };
  toggle.addEventListener('click', () => toggle.setAttribute('aria-expanded',String(document.body.classList.toggle('menu-open'))));
  document.getElementById('sidebar-nav').addEventListener('click', event => { if (event.target.closest('a')) close(); });
  document.addEventListener('keydown', event => {
    const typing = event.target.closest('input,textarea,[contenteditable="true"]');
    if (event.key === '/' && !typing && !event.ctrlKey && !event.metaKey && !event.altKey) { event.preventDefault(); input.focus(); }
    if (event.key === 'Escape') { if (document.body.classList.contains('menu-open')) { close(); toggle.focus(); } else if (event.target === input) reset(); }
  });
  const revealHash = () => {
    let id; try { id = decodeURIComponent(location.hash.slice(1)); } catch { return; }
    const target = document.getElementById(id);
    if (!target) return;
    if (target.closest('[hidden]')) reset();
    if (location.hash) requestAnimationFrame(() => target.scrollIntoView());
  };
  window.addEventListener('hashchange',revealHash);
  let scheduled = false;
  const mark = () => {
    scheduled = false;
    let active = null;
    const top = matchMedia('(max-width:800px)').matches ? 200 : 80;
    for (const link of links) {
      if (!link.hidden && document.getElementById(link.hash.slice(1)).getBoundingClientRect().top <= top) active = link;
    }
    links.forEach(link => { if (link === active) link.setAttribute('aria-current','location'); else link.removeAttribute('aria-current'); });
  };
  window.addEventListener('scroll', () => { if (!scheduled) { scheduled=true; requestAnimationFrame(mark); } }, {passive:true});
  filter(); revealHash(); mark();
})();
