/* Feature explorer: static content, progressively enhanced search and filters. */
(() => {
    const search = document.getElementById('feature-search');
    const clear = document.getElementById('clear-search');
    const select = document.getElementById('category-select');
    const sectionLinks = [...document.querySelectorAll('.category-nav a')];
    const blocks = [...document.querySelectorAll('.feature-section')];
    const categories = [...document.querySelectorAll('.feature-category')];
    const groups = [...document.querySelectorAll('.feature-group')];
    const records = [...document.querySelectorAll('.feature-item')].map(el => {
        const block = el.closest('.feature-section');
        const category = el.closest('.feature-category');
        const group = el.closest('.feature-group');
        const heading = el.querySelector('h5');
        return {el, block, category, group, heading, label: heading.textContent,
            text: [el.textContent, block.querySelector('h2').textContent, category.querySelector('h3').textContent, group.dataset.group].join(' ').toLowerCase()};
    });
    const expanded = new Map(categories.map(el => [el, el.open]));
    let active = 'all';
    let timer;
    const readUrl = () => {
        const params = new URLSearchParams(location.search);
        const requested = params.get('category') || 'all';
        active = blocks.some(block => block.dataset.section === requested) ? requested : 'all';
        search.value = (params.get('q') || '').slice(0, 200);
    };
    const saveUrl = push => {
        const url = new URL(location.href);
        if (active === 'all') url.searchParams.delete('category'); else url.searchParams.set('category', active);
        if (search.value.trim()) url.searchParams.set('q', search.value.trim()); else url.searchParams.delete('q');
        url.hash = '';
        if (url.href !== location.href) history[push ? 'pushState' : 'replaceState'](null, '', url);
    };
    const highlight = (record, words) => {
        record.heading.replaceChildren();
        if (!words.length) { record.heading.textContent = record.label; return; }
        const expression = new RegExp('(' + words.map(word => word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|') + ')', 'gi');
        record.label.split(expression).forEach((part, index) => {
            if (index % 2) { const mark = document.createElement('mark'); mark.textContent = part; record.heading.append(mark); }
            else record.heading.append(document.createTextNode(part));
        });
    };
    const apply = () => {
        const words = search.value.trim().toLowerCase().split(/\s+/).filter(Boolean);
        const totals = new Map();
        let shown = 0;
        records.forEach(record => {
            const visible = (active === 'all' || record.block.dataset.section === active) && words.every(word => record.text.includes(word));
            record.el.hidden = !visible;
            if (visible) {
                shown++;
                [record.block, record.category, record.group].forEach(el => totals.set(el, (totals.get(el) || 0) + 1));
                highlight(record, words);
            }
        });
        [...blocks, ...groups].forEach(el => { el.hidden = !totals.has(el); });
        categories.forEach(el => {
            el.hidden = !totals.has(el);
            el.querySelector('.category-count').textContent = String(totals.get(el) || 0);
            el.open = words.length ? totals.has(el) : expanded.get(el);
        });
        blocks.forEach(el => { el.querySelector('.section-heading > span').textContent = `${(totals.get(el) || 0).toLocaleString()} features`; });
        sectionLinks.forEach(link => { if (link.dataset.section === active) link.setAttribute('aria-current', 'true'); else link.removeAttribute('aria-current'); });
        select.value = active;
        clear.hidden = !search.value;
        document.getElementById('feature-empty').hidden = shown !== 0;
        document.getElementById('result-count').textContent = `${shown.toLocaleString()} of ${records.length.toLocaleString()} features${words.length ? ' match your search' : ''}`;
    };
    const filter = value => { clearTimeout(timer); active = value; apply(); saveUrl(true); };
    sectionLinks.forEach(link => link.addEventListener('click', event => {
        if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        filter(link.dataset.section);
        if (document.getElementById('explorer').getBoundingClientRect().top < 0) document.getElementById('explorer').scrollIntoView();
    }));
    select.addEventListener('change', () => filter(select.value));
    search.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => { apply(); saveUrl(false); }, 120); });
    const reset = () => { clearTimeout(timer); search.value = ''; active = 'all'; apply(); saveUrl(false); search.focus(); };
    clear.addEventListener('click', () => { clearTimeout(timer); search.value = ''; apply(); saveUrl(false); search.focus(); });
    document.getElementById('reset-search').addEventListener('click', reset);
    document.getElementById('expand-all').addEventListener('click', () => categories.filter(el => !el.hidden).forEach(el => { el.open = true; expanded.set(el, true); }));
    document.getElementById('collapse-all').addEventListener('click', () => categories.filter(el => !el.hidden).forEach(el => { el.open = false; expanded.set(el, false); }));
    categories.forEach(el => el.addEventListener('toggle', () => { if (!search.value.trim()) expanded.set(el, el.open); }));
    document.addEventListener('keydown', event => {
        if (event.key === '/' && !event.ctrlKey && !event.metaKey && !event.altKey && !event.target.closest('input,textarea,select,[contenteditable=true]')) { event.preventDefault(); search.focus(); }
        if (event.key === 'Escape' && event.target === search) { search.value = ''; clear.click(); }
    });
    const revealHash = () => {
        clearTimeout(timer);
        let id; try { id = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
        if (!id) return;
        const target = document.getElementById(id);
        if (!target || !target.closest('#feature-results')) return;
        active = 'all'; search.value = ''; apply();
        const category = target.closest('.feature-category');
        if (category) { category.open = true; expanded.set(category, true); }
        requestAnimationFrame(() => target.scrollIntoView());
    };
    window.addEventListener('hashchange', revealHash);
    window.addEventListener('popstate', () => { clearTimeout(timer); readUrl(); apply(); revealHash(); });
    readUrl(); apply(); revealHash();
})();
