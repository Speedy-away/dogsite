// Shared artwork and presentation helpers. Account data still comes from portal.js.
function portalProductLogo(...values) {
    const names = values.filter(Boolean).map(value => String(value).toLowerCase().replace(/[^a-z0-9]/g, ''));
    if (names.some(name => /fivem/.test(name))) return null;
    const logos = [
        { pattern:/redm/, id:'redm', source:'redm.webp' },
        { pattern:/grandtheft|gtalegacy|gtaenhanced|gtabe|gta5|gtav|^gta$/, id:'gta-v', source:'gta-v.jpg' },
        { pattern:/reddead|rdr/, id:'rdr2', source:'rdr2.png' }
    ];
    const logo = logos.find(item => names.some(name => item.pattern.test(name)));
    return logo ? { id:logo.id, src:`images/reference-logos/${logo.source}` } : null;
}

function portalProductArtwork(...values) {
    const name = values.filter(Boolean).join(' ').toLowerCase().replace(/[^a-z0-9]/g, '');
    const artwork = [
        [/fivem/, 'fivem'], [/redm/, 'redm'],
        [/grandtheft|gtalegacy|gtaenhanced|gtabe|gta5|gtav|^gta$/, 'gta-v'],
        [/reddead|rdr/, 'rdr2'], [/counterstrike|cs2|csgo/, 'cs2'],
        [/rainbowsix|siege|r6/, 'r6'], [/pubg|battleground/, 'pubg'],
        [/garry|gmod/, 'gmod'], [/sbox|sandbox/, 'sbox'],
        [/left4dead|leftfordead|l4d/, 'l4d'], [/lastofus|tlou/, 'tlou'],
        [/spoofer|hwid/, 'spoofer']
    ];
    const match = artwork.find(([pattern]) => pattern.test(name));
    return match ? `images/product-icons/${match[1]}.png` : '../assets/images/logo.png';
}

(() => {
    const originalCategories = loadCategories;
    loadCategories = async function(...args) {
        document.getElementById('forumSummary').textContent = 'Loading discussions...';
        document.getElementById('forumFilterEmpty').hidden = true;
        await originalCategories(...args);
        const rows = document.querySelectorAll('#categoryList .node-item');
        const summary = document.getElementById('forumSummary');
        if (rows.length) {
            const totalThreads = cachedCategories.reduce((total, category) => total + (Number(category.thread_count) || 0), 0);
            summary.textContent = `${rows.length} forums · ${totalThreads.toLocaleString()} threads`;
        } else summary.textContent = 'Choose a forum to get started.';
        rows.forEach(row => {
            const title = row.querySelector('.node-title').textContent;
            const source = portalProductArtwork(title);
            if (!source.includes('assets/images/logo')) {
                const image = document.createElement('img');
                image.src = source;
                image.alt = '';
                image.width = 56;
                image.height = 56;
                image.loading = 'lazy';
                row.querySelector('.node-icon').replaceChildren(image);
            }
            row.setAttribute('role', 'link');
            row.tabIndex = 0;
            row.setAttribute('aria-label', `Open ${title}`);
            row.addEventListener('keydown', event => {
                if (event.target === row && (event.key === 'Enter' || event.key === ' ')) {
                    event.preventDefault();
                    row.click();
                }
            });
        });
        filterForums();
    };

    function filterForums() {
        const query = document.getElementById('forumFilter').value.trim().toLowerCase();
        const rows = [...document.querySelectorAll('#categoryList .node-item')];
        let visible = 0;
        rows.forEach(row => {
            const name = row.querySelector('.node-main').textContent.toLowerCase();
            row.hidden = !name.includes(query);
            if (!row.hidden) visible++;
        });
        document.getElementById('forumFilterEmpty').hidden = !rows.length || visible > 0;
    }
    document.getElementById('forumFilter').addEventListener('input', filterForums);

    const originalSubscriptions = fetchSubscriptionsConfig;
    fetchSubscriptionsConfig = async function(...args) {
        const subscriptions = await originalSubscriptions(...args);
        return subscriptions.map(product => ({ ...product, image: portalProductArtwork(product.name, product.key) }));
    };
    // Use native form submission for keyboard access and avoid duplicate Enter requests.
    document.getElementById('loginForm').addEventListener('submit', event => { event.preventDefault(); login(); });
    document.getElementById('registerForm').addEventListener('submit', event => { event.preventDefault(); register(); });
    document.querySelectorAll('.nav-tab').forEach(tab => {
        if (tab.dataset.page) tab.setAttribute('href', '#' + tab.dataset.page);
    });
})();
(() => {
    const trigger = document.getElementById('dashboardDownloadButton');
    const dialog = document.getElementById('dashboardDownloadDialog');
    const close = document.getElementById('dashboardDownloadClose');
    let previousOverflow = '';
    trigger.addEventListener('click', () => {
        if (dialog.open) return;
        previousOverflow = document.body.style.overflow;
        dialog.showModal();
        document.body.style.overflow = 'hidden';
        dialog.querySelector('.portal-loader-link').focus();
    });
    close.addEventListener('click', () => dialog.close());
    dialog.addEventListener('keydown', event => {
        if (event.key !== 'Tab') return;
        const controls = [...dialog.querySelectorAll('button:not([disabled]), a[href]')];
        const first = controls[0];
        const last = controls[controls.length - 1];
        if (event.shiftKey && document.activeElement === first) {
            event.preventDefault();
            last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
            event.preventDefault();
            first.focus();
        }
    });
    dialog.addEventListener('click', event => {
        if (event.target !== dialog) return;
        const bounds = dialog.getBoundingClientRect();
        if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
    });
    dialog.addEventListener('close', () => {
        document.body.style.overflow = previousOverflow;
        if (trigger.getClientRects().length) trigger.focus();
    });
    window.addEventListener('hashchange', () => { if (dialog.open) dialog.close(); });
})();
