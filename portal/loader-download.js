(() => {
    'use strict';
    const button = document.getElementById('dashboardDownloadButton');
    const label = button.querySelector('span');
    const status = document.getElementById('portalLoaderDownloadStatus');
    const unavailable = 'The loader is temporarily unavailable. Please try again later.';
    let busy = false;

    function endpoint() {
        if (!window.scoobyLoaderDownloadUrl) return null;
        try {
            const url = new URL(window.scoobyLoaderDownloadUrl, location.origin);
            const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
            if ((url.protocol !== 'https:' && !(local && url.protocol === 'http:')) || url.username || url.password) return null;
            return url.href;
        } catch (_) { return null; }
    }

    button.disabled = !endpoint();
    if (button.disabled) portalText(status, unavailable);

    function expired() {
        currentUser = null;
        sessionToken = '';
        localStorage.removeItem('portalSessionToken');
        updateUIForGuest();
        document.getElementById('dashboardDownloadButton').disabled = true;
        showPage('login');
        showToast('Your session has expired. Please sign in again.', 'error');
    }

    button.addEventListener('click', async () => {
        if (busy) return;
        if (!currentUser || !sessionToken) { expired(); return; }
        const url = endpoint();
        if (!url) { portalText(status, unavailable); return; }
        busy = true;
        button.disabled = true;
        button.setAttribute('aria-busy', 'true');
        portalText(label, 'Downloading...');
        portalText(status, '');
        const token = sessionToken;
        try {
            const session = await fetch(getApiUrl('/auth/session'), {
                headers: { Authorization: `Bearer ${token}` },
                credentials: 'omit',
                cache: 'no-store',
                redirect: 'error',
                signal: AbortSignal.timeout(10000),
            });
            if (!currentUser || sessionToken !== token) { await session.body?.cancel(); return; }
            if (session.status === 401 || session.status === 403) {
                await session.body?.cancel();
                expired();
                return;
            }
            if (!session.ok) { await session.body?.cancel(); throw new Error('Session unavailable'); }
            const account = await session.json();
            if (!currentUser || sessionToken !== token) return;
            if (account.valid !== true || !account.customer) { expired(); return; }
            // The static file is public. Never send the portal token to its host.
            const response = await fetch(url, {
                credentials: 'omit',
                cache: 'no-store',
                redirect: 'error',
                signal: AbortSignal.timeout(60000),
            });
            if (!response.ok) {
                await response.body?.cancel();
                throw new Error('Download unavailable');
            }
            const blob = await response.blob();
            if (!currentUser || sessionToken !== token) return;
            if (!blob.size) throw new Error('Empty download');
            const filename = Array.from(crypto.getRandomValues(new Uint8Array(16)), value => value.toString(16).padStart(2, '0')).join('') + '.exe';
            const objectUrl = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = objectUrl;
            link.download = filename;
            document.body.append(link);
            link.click();
            link.remove();
            setTimeout(() => URL.revokeObjectURL(objectUrl), 60000);
        } catch (_) {
            if (currentUser && sessionToken === token) portalText(status, unavailable);
        } finally {
            busy = false;
            button.disabled = !endpoint() || !currentUser;
            button.removeAttribute('aria-busy');
            portalText(label, 'Download loader');
        }
    });
})();
