(() => {
    'use strict';
    const controls = [...document.querySelectorAll(
        '.main-content #getFreeKey, .main-content .purchase-btn.free-btn, .main-content .purchase-btn[href="/scoobyontop.html"], a[data-download-sponsor][download]'
    )];
    if (!controls.length) return;

    const sessionKey = 'scooby:free-key-sponsor-opened';
    function alreadyOpened() {
        try { return sessionStorage.getItem(sessionKey) === '1'; } catch { return false; }
    }
    if (alreadyOpened()) return;

    const notices = controls.map((control, index) => {
        const notice = document.createElement('p');
        notice.className = 'free-key-sponsor-note';
        notice.id = `free-key-sponsor-note-${index}`;
        notice.textContent = control.hasAttribute('data-download-sponsor')
            ? 'Download may open one sponsored tab.'
            : 'Get a Free Key may open one sponsored tab.';
        const description = control.getAttribute('aria-describedby');
        control.setAttribute('aria-describedby', [description, notice.id].filter(Boolean).join(' '));
        control.after(notice);
        return { control, notice, description };
    });

    function openSponsor(event) {
        if (!event.isTrusted || event.defaultPrevented || event.button !== 0 || event.metaKey ||
            event.altKey || event.ctrlKey || event.shiftKey) return;
        const control = event.target instanceof Element ? event.target.closest('a, button') : null;
        if (!controls.includes(control) || control.matches(':disabled, [aria-disabled="true"]')) return;

        const opened = alreadyOpened();
        window.removeEventListener('click', openSponsor, true);
        try { sessionStorage.setItem(sessionKey, '1'); } catch { /* The listener still runs once per page. */ }
        for (const entry of notices) {
            if (entry.description) entry.control.setAttribute('aria-describedby', entry.description);
            else entry.control.removeAttribute('aria-describedby');
            entry.notice.remove();
        }
        // Keep the original link/modal action, even when the browser blocks ads.
        if (!opened) {
            try {
                window.open('https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd', '_blank', 'noopener,noreferrer');
            } catch { /* A blocked sponsor must never interrupt a download. */ }
        }
    }

    window.addEventListener('click', openSponsor, true);
})();
