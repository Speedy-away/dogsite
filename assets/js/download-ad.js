(() => {
  'use strict';

  const sponsor = 'https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd';
  const handled = new WeakSet();
  // Run after the file transfer starts: opening a window consumes the browser's
  // user activation and must never take precedence over saving the file.
  function open(event) {
    if (!event?.isTrusted || handled.has(event)) return;
    handled.add(event);
    try { window.open(sponsor, '_blank', 'noopener,noreferrer,popup'); }
    catch { /* A blocked advertisement must not interrupt the download. */ }
  }
  globalThis.ScoobyDownloadAd = { open };

  document.addEventListener('click', event => {
    if (!event.isTrusted || event.defaultPrevented || event.button !== 0 ||
        event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;

    const target = event.target.closest('a.resource-download[download]');
    if (target && !target.matches(':disabled, [aria-disabled="true"]')) {
      // Let the anchor's native download action run before opening the sponsor.
      setTimeout(() => open(event), 0);
    }
  });
})();
