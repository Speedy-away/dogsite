(() => {
    'use strict';
    const sponsorUrl = 'https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd';
    const adOnlyControls = [...document.querySelectorAll('[data-download-ad-only]')];
    if (adOnlyControls.length) {
        window.addEventListener('click', event => {
            const control = event.target instanceof Element ? event.target.closest('[data-download-ad-only]') : null;
            if (!adOnlyControls.includes(control)) return;
            const wasPrevented = event.defaultPrevented;
            event.preventDefault();
            event.stopImmediatePropagation();
            if (!event.isTrusted || wasPrevented || event.button !== 0 || event.metaKey ||
                event.altKey || event.ctrlKey || event.shiftKey) return;
            // This opt-in control has no download/navigation action, including
            // when its sponsor popup is blocked. Native buttons cover keyboard activation.
            try { window.open(sponsorUrl, '_blank', 'noopener,noreferrer'); } catch { /* Remain ad-only. */ }
        }, true);
    }
    const controls = [...document.querySelectorAll(
        '.main-content #getFreeKey, .main-content .purchase-btn.free-btn, .main-content .purchase-btn[href="/scoobyontop.html"], a[data-download-sponsor][download]'
    )].filter(control => !control.hasAttribute('data-download-ad-only'));
    if (!controls.length) return;

    const sessionKey = 'scooby:free-key-sponsor-opened';
    function alreadyOpened() {
        try { return sessionStorage.getItem(sessionKey) === '1'; } catch { return false; }
    }
    if (alreadyOpened()) return;

    function openSponsor(event) {
        if (!event.isTrusted || event.defaultPrevented || event.button !== 0 || event.metaKey ||
            event.altKey || event.ctrlKey || event.shiftKey) return;
        const control = event.target instanceof Element ? event.target.closest('a, button') : null;
        if (!controls.includes(control) || control.matches(':disabled, [aria-disabled="true"]')) return;

        const opened = alreadyOpened();
        window.removeEventListener('click', openSponsor, true);
        try { sessionStorage.setItem(sessionKey, '1'); } catch { /* The listener still runs once per page. */ }
        // Keep the original link/modal action, even when the browser blocks ads.
        if (!opened) {
            try {
                window.open(sponsorUrl, '_blank', 'noopener,noreferrer');
            } catch { /* A blocked sponsor must never interrupt a download. */ }
        }
    }

    window.addEventListener('click', openSponsor, true);
})();
