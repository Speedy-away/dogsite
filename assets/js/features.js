/* Feature explorer: static content, progressively enhanced search and filters. */
(() => {
    const gameSelect = document.getElementById('game-select');
    if (gameSelect) gameSelect.addEventListener('change', () => {
        window.location.assign(gameSelect.value);
    });
    const search = document.getElementById('feature-search');
    const clear = document.getElementById('clear-search');
    const select = document.getElementById('category-select');
    const accessSelect = document.getElementById('access-select');
    let access = 'all';
    const subSelect = document.getElementById('subcategory-select');
    let subcategory = 'all';
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
    const subTabs = groups.filter(el => el.tagName === 'DETAILS');
    const expanded = new Map([...categories, ...subTabs].map(el => [el, el.open]));
    const syncSubcategories = () => {
        if (!subSelect) return;
        subSelect.replaceChildren(new Option('All categories', 'all'));
        categories.filter(el => active === 'all' || el.closest('.feature-section').dataset.section === active).forEach(el => {
            const section = el.closest('.feature-section').querySelector('h2').textContent;
            subSelect.add(new Option((active === 'all' ? section + ' / ' : '') + el.querySelector('h3').textContent, el.id));
        });
        if (![...subSelect.options].some(option => option.value === subcategory)) subcategory = 'all';
        subSelect.value = subcategory;
    };
    let active = 'all';
    let timer;
    const readUrl = () => {
        const params = new URLSearchParams(location.search);
        let requested = params.get('category') || 'all';
        if (subSelect) requested = ({vehicle:'vehicles', 'night-club':'silent-night', misc:'settings'})[requested] || requested;
        active = blocks.some(block => block.dataset.section === requested) ? requested : 'all';
        access = accessSelect && ['free', 'premium', 'plus', 'paid'].includes(params.get('plan')) ? params.get('plan') : 'all';
        if (accessSelect) accessSelect.value = access;
        search.value = (params.get('q') || '').slice(0, 200);
        subcategory = params.get('subcategory') || 'all';
        syncSubcategories();
    };
    const saveUrl = push => {
        const url = new URL(location.href);
        if (active === 'all') url.searchParams.delete('category'); else url.searchParams.set('category', active);
        if (accessSelect) { if (access === 'all') url.searchParams.delete('plan'); else url.searchParams.set('plan', access); }
        if (search.value.trim()) url.searchParams.set('q', search.value.trim()); else url.searchParams.delete('q');
        if (subSelect) { if (subcategory === 'all') url.searchParams.delete('subcategory'); else url.searchParams.set('subcategory', subcategory); }
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
            const matchesAccess = !accessSelect || access === 'all' || access === 'premium' || access === 'plus' || record.el.dataset.access === (access === 'paid' ? 'premium' : 'free');
            const visible = (!subSelect || subcategory === 'all' || record.category.id === subcategory) && matchesAccess && (active === 'all' || record.block.dataset.section === active) && words.every(word => record.text.includes(word));
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
            el.open = words.length || subcategory !== 'all' ? totals.has(el) : expanded.get(el);
        });
        subTabs.forEach(el => {
            el.querySelector('.subtab-count').textContent = String(totals.get(el) || 0);
            el.open = words.length ? totals.has(el) : expanded.get(el);
        });
        blocks.forEach(el => { el.querySelector('.section-heading > span').textContent = `${(totals.get(el) || 0).toLocaleString()} features`; });
        sectionLinks.forEach(link => { if (link.dataset.section === active) link.setAttribute('aria-current', 'true'); else link.removeAttribute('aria-current'); });
        select.value = active;
        clear.hidden = !search.value;
        document.getElementById('feature-empty').hidden = shown !== 0;
        document.getElementById('result-count').textContent = `${shown.toLocaleString()} of ${records.length.toLocaleString()} features${words.length ? ' match your search' : ''}`;
    };
    const filter = value => { clearTimeout(timer); active = value; subcategory = 'all'; syncSubcategories(); apply(); saveUrl(true); };
    sectionLinks.forEach(link => link.addEventListener('click', event => {
        if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        filter(link.dataset.section);
        if (document.getElementById('explorer').getBoundingClientRect().top < 0) document.getElementById('explorer').scrollIntoView();
    }));
    select.addEventListener('change', () => filter(select.value));
    if (subSelect) subSelect.addEventListener('change', () => { clearTimeout(timer); subcategory = subSelect.value; apply(); saveUrl(true); });
    if (accessSelect) accessSelect.addEventListener('change', () => { clearTimeout(timer); access = accessSelect.value; apply(); saveUrl(true); });
    search.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => { apply(); saveUrl(false); }, 120); });
    const reset = () => { clearTimeout(timer); search.value = ''; active = 'all'; access = 'all'; subcategory = 'all'; syncSubcategories(); if (accessSelect) accessSelect.value = access; apply(); saveUrl(false); search.focus(); };
    clear.addEventListener('click', () => { clearTimeout(timer); search.value = ''; apply(); saveUrl(false); search.focus(); });
    document.getElementById('reset-search').addEventListener('click', reset);
    document.getElementById('expand-all').addEventListener('click', () => [...categories, ...subTabs].filter(el => !el.hidden).forEach(el => { el.open = true; expanded.set(el, true); }));
    document.getElementById('collapse-all').addEventListener('click', () => [...categories, ...subTabs].filter(el => !el.hidden).forEach(el => { el.open = false; expanded.set(el, false); }));
    [...categories, ...subTabs].forEach(el => el.addEventListener('toggle', () => { if (!search.value.trim()) expanded.set(el, el.open); }));
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
        active = 'all'; access = 'all'; subcategory = 'all'; syncSubcategories(); if (accessSelect) accessSelect.value = access; search.value = ''; apply();
        const category = target.closest('.feature-category');
        if (category) { category.open = true; expanded.set(category, true); }
        const group = target.closest('.feature-subtab');
        if (group) { group.open = true; expanded.set(group, true); }
        requestAnimationFrame(() => target.scrollIntoView());
    };
    window.addEventListener('hashchange', revealHash);
    window.addEventListener('popstate', () => { clearTimeout(timer); readUrl(); apply(); revealHash(); });
    readUrl(); apply(); revealHash();
})();
