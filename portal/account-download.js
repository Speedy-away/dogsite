/* Console credentials are exported locally; this module performs no account API calls. */
(() => {
    'use strict';
    const form = document.getElementById('consoleAccountForm');
    if (!form) return;
    const username = document.getElementById('consoleAccountUsername');
    const password = document.getElementById('consoleAccountPassword');
    const button = document.getElementById('consoleAccountDownload');
    const status = document.getElementById('consoleAccountStatus');
    const urls = new Set();
    const text = (message, tone) => {
        status.dataset.tone = tone;
        if (typeof window.portalText === 'function') window.portalText(status, message);
        else status.textContent = message;
    };
    const release = url => {
        URL.revokeObjectURL(url);
        urls.delete(url);
    };
    const clear = () => {
        form.reset();
        username.value = '';
        password.value = '';
        username.setCustomValidity('');
        password.setCustomValidity('');
        text('', '');
        urls.forEach(release);
    };
    form.addEventListener('input', () => {
        username.setCustomValidity('');
        password.setCustomValidity('');
        text('', '');
    });
    form.addEventListener('submit', event => {
        event.preventDefault();
        const name = username.value.trim();
        const secret = password.value;
        const bytes = new TextEncoder();
        if (!name || /[\x00-\x1f\x7f]/.test(name) || bytes.encode(name).length > 128) {
            username.setCustomValidity('Enter a username of up to 128 UTF-8 bytes, without control characters.');
        }
        if (!secret.trim() || /[\x00-\x1f\x7f]/.test(secret) || bytes.encode(secret).length > 256) {
            password.setCustomValidity('Enter a password of up to 256 UTF-8 bytes, without control characters.');
        }
        if (!form.reportValidity()) return;
        let url;
        let link;
        try {
            const file = new Blob([JSON.stringify({ username: name, password: secret }, null, 2) + '\n'], {
                type: 'application/json;charset=utf-8'
            });
            url = URL.createObjectURL(file);
            urls.add(url);
            link = document.createElement('a');
            link.href = url;
            link.download = 'account.json';
            link.hidden = true;
            document.body.appendChild(link);
            link.click();
            text('Download started. Copy account.json to the Scooby folder on your PS4. Keep this file private.', 'success');
            // Give the browser time to accept the download before releasing the Blob.
            setTimeout(() => { if (urls.has(url)) release(url); }, 1000);
        } catch (_) {
            if (url && urls.has(url)) release(url);
            text('Could not start the download. Please enter your password and try again.', 'error');
        } finally {
            link?.remove();
            password.value = '';
        }
    });
    window.addEventListener('pagehide', clear);
    window.addEventListener('pageshow', event => { if (event.persisted) clear(); });
    window.addEventListener('hashchange', clear);
    // Clear credentials when the portal leaves Dashboard, including sign-out without a hash change.
    const dashboard = document.getElementById('page-dashboard');
    if (dashboard) new MutationObserver(() => {
        if (!dashboard.classList.contains('active')) clear();
    }).observe(dashboard, { attributes: true, attributeFilter: ['class'] });
    button.disabled = false;
})();
