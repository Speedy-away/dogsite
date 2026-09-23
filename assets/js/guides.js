/* Shared wiki controls. All articles and navigation work without JavaScript. */
(function () {
    const theme = document.getElementById('theme-select');
    theme.value = document.documentElement.dataset.theme || 'auto';
    theme.addEventListener('change', () => {
        if (theme.value === 'auto') delete document.documentElement.dataset.theme;
        else document.documentElement.dataset.theme = theme.value;
        try { localStorage.setItem('scooby-wiki-theme', theme.value); } catch (_) {}
    });
    const menu = document.querySelector('.menu-toggle');
    const sidebar = document.getElementById('wiki-sidebar');
    const closeMenu = () => { document.body.classList.remove('menu-open'); menu.setAttribute('aria-expanded', 'false'); };
    menu.addEventListener('click', () => {
        const open = document.body.classList.toggle('menu-open');
        menu.setAttribute('aria-expanded', String(open));
    });
    sidebar.addEventListener('click', event => { if (event.target.closest('a')) closeMenu(); });
    document.addEventListener('click', event => { if (!sidebar.contains(event.target) && !menu.contains(event.target)) closeMenu(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape' && document.body.classList.contains('menu-open')) { closeMenu(); menu.focus(); } });

    const sections = [...document.querySelectorAll('.guide-card[id]')];
    const sectionLinks = [...document.querySelectorAll('.wiki-toc a, .wiki-sidebar a')];
    sections.forEach(section => {
        const heading = section.querySelector('h2');
        const link = document.createElement('a');
        link.className = 'heading-link';
        link.href = '#' + section.id;
        link.textContent = '#';
        link.setAttribute('aria-label', 'Link to ' + heading.textContent);
        heading.append(link);
    });
    let scheduled = false;
    const markSection = () => {
        scheduled = false;
        let current = '';
        sections.forEach(section => { if (section.getBoundingClientRect().top <= 155) current = section.id; });
        sectionLinks.forEach(link => {
            const url = new URL(link.href);
            if (!url.hash || url.pathname.replace(/\/$/, '') !== location.pathname.replace(/\/$/, '')) return;
            if (url.hash === '#' + current) link.setAttribute('aria-current', 'location');
            else link.removeAttribute('aria-current');
        });
    };
    window.addEventListener('scroll', () => { if (!scheduled) { scheduled = true; requestAnimationFrame(markSection); } }, { passive: true });
    markSection();

    const dialog = document.getElementById('search-dialog');
    const input = document.getElementById('guide-search');
    const results = document.getElementById('guide-results');
    const status = document.getElementById('search-status');
    const searchPrompt = dialog.dataset.searchPrompt || 'Search setup instructions, troubleshooting, and account help.';
    let topics = null;
    let pending = null;
    let failed = false;
    const render = () => {
        const query = input.value.trim().toLowerCase();
        results.replaceChildren();
        if (!query) { status.textContent = searchPrompt; return; }
        if (!topics) { status.textContent = failed ? 'Search could not load. Close this window to browse the pages, or reopen it to retry.' : 'Loading topics…'; return; }
        const words = query.split(/\s+/);
        const matches = topics.filter(topic => words.every(word => (topic.game + ' ' + topic.title + ' ' + topic.text + ' ' + (topic.tags || []).join(' ')).toLowerCase().includes(word)));
        matches.sort((a,b) => Number(b.title.toLowerCase().includes(query)) - Number(a.title.toLowerCase().includes(query)));
        status.textContent = matches.length ? `${matches.length} matching topic${matches.length === 1 ? '' : 's'}` : 'No topics found. Try a game name or a different keyword.';
        matches.forEach(topic => {
            const a = document.createElement('a'); a.href = topic.href;
            if (topic.newTab) { a.target = "_blank"; a.rel = "noopener noreferrer"; }
            const context = document.createElement('span'); context.textContent = topic.game;
            const title = document.createElement('strong'); title.textContent = topic.title;
            a.append(context, title); results.append(a);
        });
    };
    const load = () => {
        if (topics || pending) return;
        failed = false;
        pending = fetch(dialog.dataset.searchIndex || '/assets/data/guide-search.json').then(response => {
            if (!response.ok) throw new Error('Search unavailable');
            return response.json();
        }).then(data => { topics = data; }).catch(() => { failed = true; }).finally(() => { pending = null; render(); });
    };
    const openSearch = () => { closeMenu(); if (!dialog.open) dialog.showModal(); input.focus(); load(); render(); };
    document.querySelector('[data-search-open]').addEventListener('click', openSearch);
    document.querySelector('[data-search-close]').addEventListener('click', () => dialog.close());
    dialog.addEventListener('click', event => { if (event.target === dialog) { const r = dialog.getBoundingClientRect(); if (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom) dialog.close(); } });
    results.addEventListener('click', event => { if (event.target.closest('a')) dialog.close(); });
    document.addEventListener('keydown', event => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); openSearch(); } });
    input.addEventListener('input', render);
    input.addEventListener('keydown', event => {
        if (event.key === 'ArrowDown' && results.firstElementChild) { event.preventDefault(); results.firstElementChild.focus(); }
        if (event.key === 'Enter' && results.firstElementChild) { event.preventDefault(); results.firstElementChild.click(); }
    });
    results.addEventListener('keydown', event => {
        const link = event.target.closest('a'); if (!link) return;
        if (event.key === 'ArrowDown') { event.preventDefault(); (link.nextElementSibling || link).focus(); }
        if (event.key === 'ArrowUp') { event.preventDefault(); (link.previousElementSibling || input).focus(); }
    });
})();
