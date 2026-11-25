(() => {
    'use strict';
    const button = document.getElementById('portalLoaderDownloadButton');
    const label = button.querySelector('span');
    const status = document.getElementById('portalLoaderDownloadStatus');
    const dialog = document.getElementById('dashboardDownloadDialog');
    const unavailable = 'The loader is temporarily unavailable. Please try again later.';
    let busy = false;

    function endpoint() {
        if (!window.scoobyLoaderDownloadUrl) return null;
        try {
            const url = new URL(window.scoobyLoaderDownloadUrl);
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
        dialog.close();
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
            const response = await fetch(url, {
                headers: { Authorization: `Bearer ${token}` },
                credentials: 'omit',
                cache: 'no-store',
                redirect: 'error',
                signal: AbortSignal.timeout(60000),
            });
            // A response for an account that has logged out must not start a download.
            if (!currentUser || sessionToken !== token) { await response.body?.cancel(); return; }
            if (response.status === 401 || response.status === 403) {
                await response.body?.cancel();
                expired();
                return;
            }
            const filename = response.headers.get('Content-Disposition')?.match(/^attachment;\s*filename="([a-f0-9]{32}\.exe)"$/i)?.[1];
            if (!response.ok || !filename) {
                await response.body?.cancel();
                throw new Error('Download unavailable');
            }
            const blob = await response.blob();
            if (!currentUser || sessionToken !== token) return;
            if (!blob.size) throw new Error('Empty download');
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
