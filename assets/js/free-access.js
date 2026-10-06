(function () {
    'use strict';
    let pending;
    let resume;
    const dialog = document.createElement('dialog');
    dialog.className = 'free-access-dialog';
    dialog.setAttribute('aria-labelledby', 'free-access-title');
    dialog.setAttribute('aria-describedby', 'free-access-message');
    dialog.setAttribute('data-i18n-skip', '');
    dialog.innerHTML = '<h2 id="free-access-title">Turn off your ad blocker</h2>' +
        '<p id="free-access-message">Ads help support free keys. Please allow ads on this site to continue.</p>' +
        '<p>Brave: open the lion icon and turn Shields off for this site.<br>uBlock Origin / AdBlock: open the extension and disable blocking for this site.</p>' +
        '<p>Then retry below. If needed, reload this page after changing your settings.</p>' +
        '<p class="free-access-status" role="status" aria-live="polite"></p>' +
        '<button type="button">I turned it off — retry</button><a href="/">Back to home</a>';
    document.body.appendChild(dialog);
    const retry = dialog.querySelector('button');
    const status = dialog.querySelector('[role="status"]');
    dialog.addEventListener('cancel', event => event.preventDefault());

    async function request(url) {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 5000);
        try {
            const response = await fetch(url, { mode: 'no-cors', cache: 'no-store', credentials: 'omit', signal: controller.signal });
            return response.type === 'opaque' || response.ok;
        } catch (_) { return false; }
        finally { clearTimeout(timer); }
    }

    async function detect() {
        const bait = document.createElement('div');
        bait.className = 'adsbox ad-banner ad-placement pub_300x250';
        bait.setAttribute('aria-hidden', 'true');
        bait.style.cssText = 'position:absolute;left:-10000px;top:-10000px;width:10px;height:10px;pointer-events:none;';
        document.body.appendChild(bait);
        await new Promise(resolve => setTimeout(resolve, 150));
        const style = getComputedStyle(bait);
        const hidden = !bait.offsetHeight || style.display === 'none' || style.visibility === 'hidden';
        bait.remove();
        if (hidden) return 'blocked';
        // Fetch only: never execute third-party advertising code as a probe.
        const [local, advertising] = await Promise.all([
            request('/assets/js/ads/ads.js'),
            request('https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js')
        ]);
        if (local && advertising) return 'clear';
        // A failed request alone cannot distinguish filtering from an outage.
        return 'unavailable';
    }

    function check() {
        if (pending) return pending;
        pending = detect().then(result => {
            if (result === 'clear') {
                if (dialog.open) dialog.close();
                return true;
            }
            status.textContent = result === 'blocked'
                ? 'Ad blocking is still active. Allow ads on this site, then try again.'
                : 'Advertising could not be reached. Check your blocker settings and connection, then retry.';
            if (!dialog.open) dialog.showModal();
            return false;
        }).finally(() => { pending = null; });
        return pending;
    }
    retry.addEventListener('click', async () => {
        retry.disabled = true;
        status.textContent = 'Checking…';
        try { if (await check()) resume?.(); }
        finally { retry.disabled = false; }
    });
    window.scoobyFreeAccess = { check, onReady(callback) { resume = callback; } };
    // Capture navigation before inline click handlers, including keyboard clicks.
    let approvedTarget = null;
    document.addEventListener('click', async event => {
        const target = event.target.closest('a, button');
        if (!target || dialog.contains(target)) return;
        if (target.id === 'freeKeyBtn' && target.hasAttribute('disabled')) {
            event.preventDefault();
            event.stopImmediatePropagation();
            return;
        }
        if (target === approvedTarget) return;
        if (!target.matches('#freeKeyBtn, #continueBtn, .purchase-btn.free-btn')) return;
        event.preventDefault();
        event.stopImmediatePropagation();
        if (await check()) {
            approvedTarget = target;
            try { target.click(); } finally { approvedTarget = null; }
        }
    }, true);
    check();
})();
