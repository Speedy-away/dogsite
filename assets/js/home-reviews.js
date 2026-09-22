(() => {
    'use strict';
    const grid = document.getElementById('communityReviews');
    const filters = document.getElementById('reviewFilters');
    const more = document.getElementById('reviewMore');
    const count = document.getElementById('reviewCount');
    if (!grid || !filters || !more || !count) return;
    const games = {
        'GTA 5': { label:'GTA V', art:'gta5', href:'/products/gta5/' },
        'RedM': { label:'RedM', art:'redm', href:'/products/redm/' },
        'FiveM': { label:'FiveM', art:'fivem', href:'/products/fivem/' },
        'RDR2': { label:'RDR2', art:'rdr2', href:'/products/rdr2/' },
        'CS2': { label:'CS2', art:'cs2', href:'/products/cs2/' }
    };
    const arrow = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M7 17 17 7M7 7h10v10"/></svg>';
    let reviews = [];
    let selected = 'all';
    let limit = 6;

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
        const top = element('div', 'community-card-top');
        const avatar = element('span', 'community-avatar', review.n.replace(/[^a-z0-9]/gi, '').slice(0,2).toUpperCase());
        avatar.setAttribute('aria-hidden', 'true');
        const author = element('div', 'community-person');
        author.append(element('h3','community-author',review.n), element('p','community-role',review.r));
        top.append(avatar, author);
        top.insertAdjacentHTML('beforeend','<svg class="community-quote-mark" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 6h8v7H7c0 3 2 4 4 5l-2 2c-4-2-6-5-6-9zm12 0h8v7h-4c0 3 2 4 4 5l-2 2c-4-2-6-5-6-9z"/></svg>');
        const quote = element('blockquote', 'community-quote', review.t);
        const link = element('a', 'community-game');
        link.href = game.href;
        const img = new Image(44,29);
        img.alt = '';
        img.src = `/assets/images/games/${game.art}-small.webp`;
        img.loading = 'lazy';
        img.decoding = 'async';
        link.append(img, element('span','',game.label));
        link.insertAdjacentHTML('beforeend',arrow);
        card.append(top,quote,link);
        return card;
    }
    function interleave(list) {
        const queues = Object.keys(games).map(game => list.filter(review => review.g === game));
        const result = [];
        for (let row=0; queues.some(queue=>row<queue.length); row++) queues.forEach(queue=>{if(queue[row])result.push(queue[row]);});
        return result;
    }
    function render() {
        const filtered = selected === 'all' ? interleave(reviews) : reviews.filter(review => review.g === selected);
        grid.replaceChildren(...filtered.slice(0,limit).map(createCard));
        count.textContent = `Showing ${Math.min(limit,filtered.length)} of ${filtered.length} reviews`;
        more.hidden = limit >= filtered.length;
        filters.querySelectorAll('button').forEach(button => button.setAttribute('aria-pressed',String(button.dataset.game === selected)));
    }
    more.addEventListener('click', () => {
        const firstNew = limit;
        limit += 6;
        render();
        const next = grid.children[firstNew];
        if (next) { next.focus({preventScroll:true}); next.scrollIntoView({block:'nearest'}); }
    });
    async function init() {
        try {
            const response = await fetch('/assets/data/home-reviews.json');
            if (!response.ok) throw new Error('Reviews unavailable');
            const data = await response.json();
            if (!Array.isArray(data) || !data.length || data.some(review => !games[review.g] || typeof review.n !== 'string' || typeof review.r !== 'string' || typeof review.t !== 'string')) return;
            reviews = data;
            const options = [['all','All games'], ...Object.entries(games).map(([key,game])=>[key,game.label])];
            const buttons = options.map(([value,label])=>{
                const button = element('button','review-filter');
                button.type = 'button';
                button.dataset.game = value;
                button.setAttribute('aria-controls','communityReviews');
                button.setAttribute('aria-pressed',String(value === selected));
                const total = value === 'all' ? reviews.length : reviews.filter(review=>review.g === value).length;
                button.setAttribute('aria-label',`${label}, ${total} reviews`);
                button.append(element('span','',label),element('span','review-filter-count',String(total)));
                button.addEventListener('click',()=>{selected=value;limit=6;render();});
                return button;
            });
            filters.replaceChildren(...buttons);
            filters.hidden = false;
            render();
        } catch (_) {
            // The first six reviews are rendered in HTML and remain readable
            // if JavaScript or the review data request is unavailable.
        }
    }
    init();
})();
