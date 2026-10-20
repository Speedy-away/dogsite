/* Optional reading tools. Instructions and original image links work without JS. */
(function () {
    const main = document.getElementById('main-content');
    if (!main) return;
    const revealHash = () => {
        let id;
        try { id = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
        const target = document.getElementById(id);
        if (!target || !main.contains(target)) return;
        let detail = target.closest('details');
        while (detail) {
            detail.open = true;
            detail = detail.parentElement.closest('details');
        }
        requestAnimationFrame(() => target.scrollIntoView({block: 'start'}));
    };
    window.addEventListener('hashchange', revealHash);
    main.addEventListener('click', event => {
        const anchor = event.target.closest('a[href^="#"]');
        if (anchor && anchor.hash === location.hash) revealHash();
    });
    revealHash();

    const article = main.querySelector('.general-guide');
    if (article && typeof window.print === 'function') {
        const toolbar = document.createElement('div');
        toolbar.className = 'help-print';
        const print = document.createElement('button');
        print.type = 'button';
        print.textContent = 'Print guide';
        toolbar.append(print);
        const quickLinks = article.querySelector('.help-quick-links');
        if (quickLinks) quickLinks.append(toolbar);
        else article.before(toolbar);
        let state;
        const expand = () => {
            if (state) return;
            state = [...article.querySelectorAll('details')].map(detail => [detail, detail.open]);
            state.forEach(([detail]) => { detail.open = true; });
        };
        window.addEventListener('beforeprint', expand);
        window.addEventListener('afterprint', () => {
            state?.forEach(([detail, open]) => { detail.open = open; });
            state = undefined;
        });
        print.addEventListener('click', async () => {
            expand();
            await Promise.all([...article.querySelectorAll('img')].map(async img => {
                img.loading = 'eager';
                try { await img.decode(); } catch (_) { /* Text can still be printed. */ }
            }));
            window.print();
        });
    }

    if (typeof HTMLDialogElement === 'undefined') return;
    const links = main.querySelectorAll('[data-help-image]');
    if (!links.length) return;
    const dialog = document.createElement('dialog');
    dialog.className = 'help-image-dialog';
    dialog.setAttribute('aria-labelledby', 'help-image-title');
    dialog.innerHTML = '<header><p id="help-image-title"></p><button type="button" autofocus>Close</button></header><div class="help-image-dialog-content"></div><footer><a target="_blank" rel="noopener">Open original image ↗</a></footer>';
    document.body.append(dialog);
    let trigger;
    dialog.querySelector('button').addEventListener('click', () => dialog.close());
    dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
    dialog.addEventListener('close', () => trigger?.focus());
    links.forEach(link => link.addEventListener('click', event => {
        if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        const img = link.querySelector('img');
        if (!img) return;
        event.preventDefault();
        trigger = link;
        dialog.querySelector('#help-image-title').textContent = img.alt;
        const content = (link.querySelector('.help-image-frame') || img).cloneNode(true);
        const picture = content.tagName === 'IMG' ? content : content.querySelector('img');
        picture.loading = 'eager';
        dialog.querySelector('.help-image-dialog-content').replaceChildren(content);
        dialog.querySelector('footer a').href = link.href;
        dialog.showModal();
    }));
})();
