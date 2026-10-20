/* Local game filtering. Every game link remains available without JavaScript. */
(function () {
    const list = document.getElementById('game-directory-list');
    if (!list) return;
    const cards = [...list.querySelectorAll('.guide-game-link')];
    const form = document.querySelector('[data-game-search-form]');
    const input = document.getElementById('game-filter');
    const clear = document.querySelector('[data-game-clear]');
    const categories = document.querySelector('[data-game-categories]');
    const buttons = [...categories.querySelectorAll('[data-game-category]')];
    const status = document.getElementById('game-filter-status');
    const empty = document.querySelector('[data-game-empty]');
    const normalize = value => value.toLowerCase().normalize('NFKD').replace(/[’']/g, '').replace(/[^a-z0-9]+/g, ' ').trim();
    const text = new Map(cards.map(card => [card, normalize(card.dataset.gameName + ' ' + card.dataset.gameAliases + ' ' + card.textContent)]));
    let category = 'all';
    const render = () => {
        const query = normalize(input.value);
        const words = query ? query.split(/\s+/) : [];
        let count = 0;
        cards.forEach(card => {
            const visible = (category === 'all' || card.dataset.gameCategory === category) && words.every(word => text.get(card).includes(word));
            card.hidden = !visible;
            if (visible) count += 1;
        });
        clear.hidden = input.value.length === 0;
        empty.hidden = count !== 0;
        // Avoid leaving a stray grid border around an empty result.
        list.hidden = count === 0;
        status.textContent = count + (count === 1 ? ' game' : ' games');
        buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.gameCategory === category)));
    };
    form.hidden = false;
    categories.hidden = false;
    input.addEventListener('input', render);
    clear.addEventListener('click', () => { input.value = ''; render(); input.focus(); });
    input.addEventListener('keydown', event => {
        if (event.key === 'Escape') { input.value = ''; render(); }
    });
    form.addEventListener('submit', event => {
        event.preventDefault();
        cards.find(card => !card.hidden)?.focus();
    });
    buttons.forEach(button => button.addEventListener('click', () => { category = button.dataset.gameCategory; render(); }));
    document.querySelector('[data-game-reset]').addEventListener('click', () => { category = 'all'; input.value = ''; render(); input.focus(); });
    const articleSearch = document.querySelector('[data-directory-search]');
    articleSearch.hidden = false;
    articleSearch.addEventListener('click', () => document.querySelector('[data-search-open]').click());
    render();
})();
