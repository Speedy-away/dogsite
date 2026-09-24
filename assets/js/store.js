/* Store controls preserve the existing checkout routes; no checkout runs here. */
(() => {
    const data = JSON.parse(document.getElementById('store-data').textContent);
    const menu = document.querySelector('.menu-button');
    const nav = document.getElementById('store-nav');
    const closeMenu = () => { nav.classList.remove('is-open'); menu.setAttribute('aria-expanded', 'false'); };
    menu.addEventListener('click', () => { const open = nav.classList.toggle('is-open'); menu.setAttribute('aria-expanded', String(open)); });
    nav.addEventListener('click', event => { if (event.target.closest('a')) closeMenu(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape' && nav.classList.contains('is-open')) { closeMenu(); menu.focus(); } });
    document.addEventListener('click', event => { if (!nav.contains(event.target) && !menu.contains(event.target)) closeMenu(); });

    const cards = [...document.querySelectorAll('[data-product]')];
    const search = document.getElementById('product-search');
    const filters = [...document.querySelectorAll('[data-filter]')];
    let category = 'all';
    const updateCatalogue = () => {
        const words = search.value.toLowerCase().trim().split(/\s+/).filter(Boolean);
        cards.forEach(card => {
            const text = (card.dataset.search + ' ' + card.textContent).toLowerCase();
            card.hidden = !(category === 'all' || card.dataset.category.split(' ').includes(category)) || !words.every(word => text.includes(word));
        });
        const count = cards.filter(card => !card.hidden).length;
        document.getElementById('catalog-count').textContent = `${count} option${count === 1 ? '' : 's'}${category === 'all' && !search.value ? ' · Free and premium' : ' found'}`;
        document.getElementById('empty-state').hidden = count !== 0;
        document.querySelectorAll('[data-catalog-section]').forEach(section => {
            section.hidden = ![...section.querySelectorAll('[data-product]')].some(card => !card.hidden);
        });
        document.querySelectorAll('.product-grid').forEach(grid => { grid.hidden = ![...grid.children].some(card => !card.hidden); });
    };
    filters.forEach(button => button.addEventListener('click', () => {
        category = button.dataset.filter;
        filters.forEach(item => item.setAttribute('aria-pressed', String(item === button)));
        updateCatalogue();
    }));
    search.addEventListener('input', updateCatalogue);
    updateCatalogue();
    document.getElementById('reset-filters').addEventListener('click', () => { search.value = ''; filters[0].click(); search.focus(); });

    // Reveal catalogue sections before the browser follows an in-page link.
    document.querySelectorAll('a[href^="#"]').forEach(link => link.addEventListener('click', () => {
        const section = document.getElementById(link.hash.slice(1));
        if (!section?.matches('[data-catalog-section]')) return;
        search.value = '';
        filters[0].click();
    }));

    const gtaCheckout = document.getElementById('gta-checkout');
    document.querySelectorAll('input[name="gta-plan"]').forEach(input => input.addEventListener('change', () => {
        const plan = data.plans.find(plan => plan.id === input.value);
        gtaCheckout.dataset.tier = plan.id;
        gtaCheckout.textContent = `Get ${plan.name} — $${plan.price} →`;
    }));
    const payment = document.getElementById('payment-dialog');
    document.querySelectorAll('[data-buy]').forEach(button => button.addEventListener('click', () => {
        const product = button.dataset.buy;
        const tier = button.dataset.tier;
        const href = data.links[product]?.[tier];
        if (!href) return;
        const item = product === 'gta5' ? data.plans.find(plan => plan.id === tier) : data.products.find(item => item.slug === product);
        document.getElementById('payment-title').textContent = product === 'gta5' ? 'GTA 5' : item.name;
        document.getElementById('payment-edition').textContent = product === 'gta5' ? item.name : 'Premium · Lifetime';
        document.getElementById('payment-price').textContent = product === 'gta5' ? '$' + item.price : item.price;
        document.getElementById('payment-note').textContent = tier === 'upgrade' ? 'Requires an existing GTA 5 Premium license.' : 'Lifetime license · One-time payment';
        document.getElementById('card-payment-link').href = href;
        payment.showModal();
    }));

    const freeDialog = document.getElementById('free-dialog');
    const freeLink = document.getElementById('free-key-link');
    const freeStatus = document.getElementById('free-key-status');
    let freeTimer;
    document.querySelectorAll('[data-free]').forEach(button => button.addEventListener('click', () => {
        clearInterval(freeTimer);
        let seconds = 3;
        freeLink.removeAttribute('href');
        freeLink.setAttribute('aria-disabled', 'true');
        freeLink.setAttribute('tabindex', '-1');
        freeLink.textContent = 'Please wait…';
        freeStatus.textContent = 'Ready in 3 seconds';
        freeDialog.showModal();
        freeTimer = setInterval(() => {
            seconds--;
            freeStatus.textContent = `Ready in ${seconds} second${seconds === 1 ? '' : 's'}`;
            if (seconds <= 0) {
                clearInterval(freeTimer);
                freeLink.href = 'https://scoobymenu.cc/scoobyontop.html';
                freeLink.setAttribute('aria-disabled', 'false');
                freeLink.removeAttribute('tabindex');
                freeLink.textContent = 'Continue to get key ↗';
                freeStatus.textContent = 'Ready. The key page opens in a new tab.';
            }
        }, 1000);
    }));
    freeDialog.addEventListener('close', () => clearInterval(freeTimer));
    freeLink.addEventListener('click', event => { if (freeLink.getAttribute('aria-disabled') === 'true') event.preventDefault(); });
    document.querySelectorAll('[data-dialog]').forEach(button => button.addEventListener('click', () => document.getElementById(button.dataset.dialog).showModal()));
    document.querySelectorAll('dialog').forEach(dialog => {
        dialog.querySelector('[data-close]').addEventListener('click', () => dialog.close());
        dialog.addEventListener('click', event => {
            if (event.target !== dialog) return;
            const rect = dialog.getBoundingClientRect();
            if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
        });
    });
})();
