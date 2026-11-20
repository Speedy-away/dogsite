(() => {
  'use strict';

  const sponsor = 'https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd';
  document.addEventListener('click', event => {
    if (!event.isTrusted || event.defaultPrevented || event.button !== 0 ||
        event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;

    const target = event.target.closest('[data-download-ad], button[data-download-file], a.resource-download[download]');
    if (target && !target.matches(':disabled, [aria-disabled="true"]')) {
      window.open(sponsor, '_blank', 'noopener,noreferrer,popup');
    }
  }, true);
})();
