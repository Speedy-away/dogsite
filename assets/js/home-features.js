(() => {
    'use strict';
    const section = document.getElementById('features');
    const grid = document.getElementById('whyCards');
    const picker = document.getElementById('whyProductPicker');
    if (!section || !grid || !picker) return;

    const products = [
        { id:'gta5', name:'GTA V', href:'/features-list/gta-features/', cards:[
            { art:'gta-casino', kicker:'Plan your next big score', title:'Heist Editor', description:'Set your cuts and take control of Cayo Perico, Casino, Doomsday, and apartment heists.', href:'/guides/gta5/money/#topic-11', action:'Explore heist tools' },
            { art:'gta-hills', kicker:'Change the way you play', title:'Fun & Chaos', description:'Vehicle spawns, world effects, player options, and unexpected ways to make every session your own.', href:'/features-list/gta-features/#section-world', action:'Explore fun features' },
            { art:'gta-desert', kicker:'Build your progression', title:'Money Recovery', description:'Business Manager, money tools, RP, rank, stats, and unlocks. Manage your progression in one place.', href:'/features-list/gta-features/#section-recovery', action:'See recovery features' }
        ] },
        { id:'rdr2', name:'RDR2', href:'/features-list/rdr2-features/', cards:[
            { art:'rdr-heartlands', kicker:'Make the frontier yours', title:'Horses & Spawners', description:'Explore horse, animal, wagon, and object spawners, with customization for your next frontier adventure.', href:'/products/rdr2/#product-details', action:'Explore RDR2 tools' },
            { art:'rdr-forest', kicker:'Turn the world upside down', title:'Fun & Chaos', description:'Stampedes, tornadoes, meteor showers, gravity effects, and more ways to change the world around you.', href:'/features-list/rdr2-features/#section-world', action:'Explore fun features' },
            { art:'rdr-drifter', kicker:'Your next frontier', title:'Money & XP', description:'Money recovery, role XP, collectible loops, and unlock tools for your Red Dead Online progression.', href:'/products/rdr2/#product-details', action:'See recovery tools' }
        ] },
        { id:'fivem', name:'FiveM', href:'/products/fivem/', cards:[
            { art:'gta-night', kicker:'Build your next session', title:'Vehicle Spawner', description:'Bring vehicle and player tools together for your FiveM setup, with options for custom servers.', href:'/products/fivem/#product-details', action:'Explore FiveM tools' },
            { art:'gta-coast', kicker:'Make room for the unexpected', title:'Fun & Chaos', description:'Vehicle spawns, ped tools, and player effects. Bring a different kind of energy to your next session.', href:'/products/fivem/#product-details', action:'Explore fun features' },
            { art:'gta-casino', kicker:'Know your server', title:'Money & Items', description:'Explore money, item, and weapon options, with availability depending on the server you play on.', href:'/guides/fivem/money-items-weapons/', action:'Explore the options' }
        ] },
        { id:'redm', name:'RedM', href:'/products/redm/', cards:[
            { art:'rdr-overlook', kicker:'Head out into the frontier', title:'Horses & Wagons', description:'Find your next ride with horse breeds, custom stats, bonding options, wagons, and carriages.', href:'/products/redm/#product-details', action:'Explore RedM tools' },
            { art:'rdr-drifter', kicker:'A different kind of wild west', title:'Fun & Chaos', description:'Spawn NPCs and change the time and weather to set the scene for your next frontier adventure.', href:'/products/redm/#product-details', action:'Explore fun features' },
            { art:'rdr-heartlands', kicker:'Know your server', title:'Money & Items', description:'Money, item, and weapon options for RedM, with availability shaped by each server and its requirements.', href:'/guides/redm/money-items-weapons/', action:'Explore the options' }
        ] }
    ];
    const cards = [...grid.querySelectorAll('.why-card')];
    const buttons = [...picker.querySelectorAll('button')];
    const label = document.getElementById('whyProductLabel');
    const allLink = document.getElementById('whyAllFeatures');
    const status = document.getElementById('whyProductStatus');
    const motion = matchMedia('(prefers-reduced-motion: reduce)');
    const cache = new Map();
    let current = 0;
    let visible = false;
    let held = false;
    let busy = false;
    let request = 0;
    let timer;

    function canRun() {
        return visible && !held && !motion.matches && !document.hidden && !section.matches(':hover') && !section.contains(document.activeElement);
    }
    function schedule() {
        clearTimeout(timer);
        if (canRun() && !busy) timer = setTimeout(() => changeProduct((current + 1) % products.length, false), 12000);
    }
    function loadArtwork(art) {
        if (cache.has(art)) return cache.get(art);
        const promise = new Promise((resolve, reject) => {
            const image = new Image();
            const timeout = setTimeout(() => reject(new Error('Artwork timed out')), 15000);
            image.alt = '';
            image.width = 960;
            image.height = 540;
            image.decoding = 'async';
            image.fetchPriority = 'low';
            image.className = 'why-art-image';
            image.onload = async () => {
                clearTimeout(timeout);
                try { await image.decode(); } catch (_) { /* Loaded images can still render. */ }
                resolve(image);
            };
            image.onerror = () => { clearTimeout(timeout); reject(new Error('Artwork unavailable')); };
            image.src = `/assets/images/hero/${art}-v2-960.webp`;
        });
        cache.set(art, promise);
        promise.catch(() => cache.delete(art));
        return promise;
    }
    function preloadNext() {
        if (canRun()) products[(current + 1) % products.length].cards.forEach(card => loadArtwork(card.art).catch(() => {}));
    }
    async function changeProduct(index, manual) {
        if (manual) held = true;
        clearTimeout(timer);
        const token = ++request;
        if (index === current) {
            busy = false;
            grid.removeAttribute('aria-busy');
            return;
        }
        busy = true;
        status.textContent = '';
        grid.setAttribute('aria-busy', 'true');
        try {
            const product = products[index];
            const artwork = await Promise.all(product.cards.map(card => loadArtwork(card.art)));
            if (token !== request || (!manual && !canRun())) return;
            product.cards.forEach((feature, i) => {
                const card = cards[i];
                const stage = card.querySelector('.why-card-art');
                const previous = stage.querySelector('.is-active');
                // An artwork image can appear in more than one product. Clone it
                // so switching products never moves a visible image between cards.
                const image = artwork[i].cloneNode();
                stage.appendChild(image);
                void image.offsetWidth;
                image.classList.add('is-active');
                if (previous) {
                    previous.classList.remove('is-active');
                    setTimeout(() => previous.remove(), motion.matches ? 0 : 1250);
                }
                card.querySelector('.why-card-kicker').textContent = feature.kicker;
                card.querySelector('h3').textContent = feature.title;
                card.querySelector('p').textContent = feature.description;
                const link = card.querySelector('.why-link');
                link.href = feature.href;
                link.querySelector('span').textContent = feature.action;
            });
            current = index;
            grid.dataset.product = product.id;
            label.textContent = `Inside the ${product.name} menu`;
            allLink.href = product.href;
            allLink.querySelector('span').textContent = `Explore ${product.name} features`;
            buttons.forEach((button, i) => button.setAttribute('aria-pressed', String(i === index)));
            preloadNext();
        } catch (_) {
            if (manual && token === request) status.textContent = 'That scene could not load. Select the product to try again.';
            // Keep the previous product's images, copy, and links together if a
            // scene cannot load. Automatic playback retries on its next interval.
        } finally {
            if (token === request) {
                busy = false;
                grid.removeAttribute('aria-busy');
                schedule();
            }
        }
    }
    buttons.forEach((button, index) => button.addEventListener('click', () => changeProduct(index, true)));
    picker.hidden = false;
    section.addEventListener('mouseenter', schedule);
    section.addEventListener('mouseleave', () => { schedule(); preloadNext(); });
    section.addEventListener('focusin', schedule);
    section.addEventListener('focusout', () => setTimeout(() => { schedule(); preloadNext(); }, 0));
    document.addEventListener('visibilitychange', () => { schedule(); preloadNext(); });
    motion.addEventListener('change', () => { schedule(); preloadNext(); });
    if ('IntersectionObserver' in window) {
        new IntersectionObserver(entries => {
            visible = entries[0].isIntersecting;
            schedule();
            preloadNext();
        }, { threshold:0.1 }).observe(grid);
    } else {
        visible = true;
        schedule();
        preloadNext();
    }
})();
