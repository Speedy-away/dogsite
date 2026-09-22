(() => {
    'use strict';
    const grid = document.getElementById('communityReviews');
    const filters = document.getElementById('reviewFilters');
    const next = document.getElementById('reviewNext');
    const toggle = document.getElementById('reviewRotationToggle');
    const controls = document.getElementById('reviewRotationControls');
    const count = document.getElementById('reviewCount');
    if (!grid || !filters || !next || !toggle || !controls || !count) return;
    const games = {
        'GTA 5': { label:'GTA V', href:'/products/gta5/' },
        'CS2': { label:'CS2', href:'/products/cs2/' },
        'L4D': { label:'L4D 1 & 2', href:'/products/l4d/' },
        'GMod': { label:'GMod', href:'/products/gmod/' },
        'RDR2': { label:'RDR2', href:'/products/rdr2/' },
        'FiveM': { label:'FiveM', href:'/products/fivem/' },
        'RedM': { label:'RedM', href:'/products/redm/' }
    };
    const arrow = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M7 17 17 7M7 7h10v10"/></svg>';
    let reviews = [];
    let selected = 'all';
    const motion = matchMedia('(prefers-reduced-motion: reduce)');
    const mobile = matchMedia('(max-width:680px)');
    const tablet = matchMedia('(max-width:980px)');
    let capacity = mobile.matches ? 1 : tablet.matches ? 2 : 3;
    let pool = [];
    let deck = [];
    let showing = [];
    let visible = false;
    let paused = motion.matches;
    let preferenceOverridden = false;
    let timer;

    function element(tag, className, content) {
        const el = document.createElement(tag);
        el.className = className;
        if (content !== undefined) el.textContent = content;
        return el;
    }
    function createCard(review) {
        const game = games[review.g];
        const card = element('article', 'community-card');
        card.tabIndex = -1;
        card.dataset.review = String(reviews.indexOf(review));
        const top = element('div', 'community-card-top');
        const author = element('div', 'community-person');
        author.append(element('h3','community-author',review.displayName || review.n), element('p',review.r === 'Free User' ? 'community-role is-free' : 'community-role',review.r));
        top.append(author);
        top.insertAdjacentHTML('beforeend','<svg class="community-quote-mark" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 6h8v7H7c0 3 2 4 4 5l-2 2c-4-2-6-5-6-9zm12 0h8v7h-4c0 3 2 4 4 5l-2 2c-4-2-6-5-6-9z"/></svg>');
        const quote = element('blockquote', 'community-quote', review.t);
        const link = element('a', 'community-game');
        link.href = game.href;
        link.append(element('span','',game.label));
        link.insertAdjacentHTML('beforeend',arrow);
        card.append(top,quote,link);
        return card;
    }
    function shuffle(items) {
        for (let i = items.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [items[i], items[j]] = [items[j], items[i]];
        }
        return items;
    }
    function canRotate() {
        return visible && !paused && !document.hidden && pool.length > capacity &&
            !grid.contains(document.activeElement);
    }
    function updateControls() {
        const available = pool.length > capacity;
        next.disabled = !available;
        toggle.disabled = !available;
        toggle.setAttribute('aria-pressed', String(paused));
        const action = paused ? 'Resume automatic reviews' : 'Pause automatic reviews';
        toggle.setAttribute('aria-label', action);
        toggle.title = action;
        count.textContent = `${showing.length} of ${pool.length} reviews`;
    }
    function schedule() {
        clearTimeout(timer);
        if (canRotate()) timer = setTimeout(advance, 7000 + Math.floor(Math.random() * 3001));
    }
    function advance() {
        clearTimeout(timer);
        const batch = [];
        const size = Math.min(capacity, pool.length);
        while (batch.length < size) {
            if (!deck.length) {
                // Visit the whole shuffled deck before starting another round.
                // Keep the previous cards at the end to avoid immediate repeats.
                const candidates = pool.filter(review => !batch.includes(review));
                deck = [...shuffle(candidates.filter(review => !showing.includes(review))),
                    ...shuffle(candidates.filter(review => showing.includes(review)))];
            }
            const review = deck.shift();
            if (!batch.includes(review)) batch.push(review);
        }
        showing = batch;
        grid.replaceChildren(...showing.map(createCard));
        updateControls();
        schedule();
    }
    function selectGame(value) {
        selected = value;
        pool = selected === 'all' ? reviews : reviews.filter(review => review.g === selected);
        deck = shuffle([...pool]);
        showing = [];
        filters.querySelectorAll('button').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.game === selected)));
        advance();
    }
    next.addEventListener('click', advance);
    toggle.addEventListener('click', () => {
        paused = !paused;
        preferenceOverridden = true;
        updateControls();
        schedule();
    });
    grid.addEventListener('focusin', schedule);
    grid.addEventListener('focusout', () => setTimeout(schedule, 0));
    document.addEventListener('visibilitychange', schedule);
    motion.addEventListener('change', () => {
        if (!preferenceOverridden) paused = motion.matches;
        updateControls();
        schedule();
    });
    function resize() {
        const size = mobile.matches ? 1 : tablet.matches ? 2 : 3;
        if (size === capacity) return;
        capacity = size;
        if (reviews.length) selectGame(selected);
    }
    mobile.addEventListener('change', resize);
    tablet.addEventListener('change', resize);
    if ('IntersectionObserver' in window) {
        new IntersectionObserver(entries => {
            visible = entries[0].isIntersecting;
            schedule();
        }, { threshold:0.1 }).observe(grid);
    } else visible = true;
    async function init() {
        try {
            const response = await fetch('/assets/data/home-reviews.json?v=6');
            if (!response.ok) throw new Error('Reviews unavailable');
            const data = await response.json();
            if (!Array.isArray(data) || !data.length || data.some(review => !games[review.g] || typeof review.n !== 'string' || typeof review.r !== 'string' || typeof review.t !== 'string' || (review.displayName !== undefined && typeof review.displayName !== 'string') || (review.sample !== undefined && typeof review.sample !== 'boolean'))) return;
            reviews = data.filter(review => !review.sample);
            if (!reviews.length) return;
            const options = [['all','All games'], ...Object.entries(games).filter(([key]) => reviews.some(review => review.g === key)).map(([key,game])=>[key,game.label])];
            const buttons = options.map(([value,label])=>{
                const button = element('button','review-filter');
                button.type = 'button';
                button.dataset.game = value;
                button.setAttribute('aria-controls','communityReviews');
                button.setAttribute('aria-pressed',String(value === selected));
                const total = value === 'all' ? reviews.length : reviews.filter(review=>review.g === value).length;
                button.setAttribute('aria-label', `${label}, ${total} reviews`);
                button.append(element('span','',label),element('span','review-filter-count',String(total)));
                button.addEventListener('click', () => selectGame(value));
                return button;
            });
            filters.replaceChildren(...buttons);
            filters.hidden = false;
            controls.hidden = false;
            selectGame('all');
            grid.classList.add('is-rotating');
        } catch (_) {
            // The first three reviews are rendered in HTML and remain readable
            // if JavaScript or the review data request is unavailable.
        }
    }
    init();
})();
