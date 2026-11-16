(() => {
  'use strict';
  const key = 'scooby.platform';
  const save = value => { try { localStorage.setItem(key, value); } catch (_) {} };
  document.querySelectorAll('[data-platform-choice]').forEach(link => link.addEventListener('click', () => save(link.dataset.platformChoice)));
  const tabs = document.querySelectorAll('[data-download-platform]');
  function selectDownload(platform) {
    tabs.forEach(tab => {
      if (tab.dataset.downloadPlatform === platform) tab.setAttribute('aria-current', 'page');
      else tab.removeAttribute('aria-current');
    });
    document.querySelectorAll('.pc-download').forEach(el => { el.hidden = platform !== 'pc'; });
    document.querySelectorAll('.console-download').forEach(el => { el.hidden = platform !== 'console'; });
  }
  tabs.forEach(tab => tab.addEventListener('click', event => {
    event.preventDefault(); save(tab.dataset.downloadPlatform);
    selectDownload(tab.dataset.downloadPlatform);
    history.replaceState(null, '', '#' + tab.dataset.downloadPlatform);
  }));
  if (tabs.length) {
    const showDownloadFromLocation = () => {
      let saved = 'pc';
      try { if (localStorage.getItem(key) === 'console') saved = 'console'; } catch (_) {}
      const hash = location.hash;
      const target = document.getElementById(hash.slice(1));
      const pcTarget = target?.closest('.pc-download');
      selectDownload(hash === '#console' ? 'console' : hash === '#pc' || pcTarget ? 'pc' : saved);
    };
    showDownloadFromLocation();
    window.addEventListener('hashchange', showDownloadFromLocation);
  }
  const home = location.pathname === '/' || location.pathname === '/index.html' || /^\/lang\/[^/]+\/(?:index.html)?$/.test(location.pathname);
  if (!home) return;
  let selected; try { selected = localStorage.getItem(key); } catch (_) {}
  if (selected && location.hash !== '#platform') return;
  const dialog = document.createElement('dialog');
  dialog.className = 'platform-dialog';
  dialog.setAttribute('aria-labelledby', 'platform-heading');
  dialog.innerHTML = '<header class="platform-topbar"><img class="platform-header-logo" src="/assets/images/brand/scooby-mark.svg" alt="Scooby"><h2 id="platform-heading">Choose your platform</h2><span class="platform-step">PC / CONSOLE</span></header><div class="platform-options"><a class="platform-choice" href="/" data-choice="pc"><span class="platform-scene" aria-hidden="true"></span><img class="platform-center-logo" src="/assets/images/brand/scooby-mark.svg" alt="Scooby logo"><span class="platform-caption"><span class="platform-kicker">THE PC LIBRARY</span><strong>PC</strong><small>CLICK TO SELECT <span aria-hidden="true">↗</span></small></span></a><a class="platform-choice console" href="/console/" data-choice="console"><span class="platform-scene" aria-hidden="true"></span><img class="platform-center-logo" src="/assets/images/brand/scooby-mark.svg" alt="Scooby logo"><span class="platform-caption"><span class="platform-kicker">PLAYSTATION 4</span><strong>CONSOLE</strong><small>CLICK TO SELECT <span aria-hidden="true">↗</span></small></span></a></div>';

  document.body.append(dialog);
  let previousOverflow;
  dialog.addEventListener('close', () => { document.body.style.overflow = previousOverflow; });
  dialog.querySelectorAll('[data-choice]').forEach(link => link.addEventListener('click', event => {
    save(link.dataset.choice);
    if (link.dataset.choice === 'pc') event.preventDefault();
    dialog.close();
    if (location.hash === '#platform') history.replaceState(null, '', location.pathname + location.search);
  }));
  dialog.addEventListener('cancel', () => save('pc'));
  // Wait for any existing language dialog to finish before opening this choice.
  const open = () => {
    const activeModal = [...document.querySelectorAll('dialog[open], [aria-modal="true"]')]
      .some(element => element.getClientRects().length && getComputedStyle(element).visibility === 'visible');
    if (activeModal) { setTimeout(open, 400); return; }
    previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    dialog.showModal();
  };
  setTimeout(open, 500);
})();
