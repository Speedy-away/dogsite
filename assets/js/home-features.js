(() => {
    'use strict';
    const section = document.getElementById('features');
    const grid = document.getElementById('whyCards');
    const picker = document.getElementById('whyProductPicker');
    if (!section || !grid || !picker) return;

    const products = [
        { id:'gta5', name:'GTA V', href:'/features-list/gta-features/', cards:[
            { art:'gta-heist', kicker:'Plan your next big score', title:'Heist Editor', description:'Set your cuts and take control of Cayo Perico, Casino, Doomsday, and apartment heists.', href:'/guides/gta5/money/#topic-11', action:'Explore heist tools' },
            { art:'gta-chaos', kicker:'Change the way you play', title:'Fun & Chaos', description:'Player trolling, weapon mods, modded outfits and vehicles, vehicle spawns, and world effects. Make every session your own.', href:'/features-list/gta-features/#section-world', action:'Explore fun features' },
            { art:'gta-business', kicker:'Build your progression', title:'Money Recovery', description:'Business Manager, money tools, RP, rank, stats, and unlocks. Manage your progression in one place.', href:'/features-list/gta-features/#section-recovery', action:'See recovery features' }
        ] },
        { id:'rdr2', name:'RDR2', href:'/features-list/rdr2-features/', cards:[
            { art:'rdr-horses', kicker:'Make the frontier yours', title:'Horses & Spawners', description:'Explore horse, animal, wagon, and object spawners, with customization for your next frontier adventure.', href:'/products/rdr2/#product-details', action:'Explore RDR2 tools' },
            { art:'rdr-chaos', kicker:'Turn the world upside down', title:'Fun & Chaos', description:'Stampedes, tornadoes, meteor showers, gravity effects, and more ways to change the world around you.', href:'/features-list/rdr2-features/#section-world', action:'Explore fun features' },
            { art:'rdr-progression', kicker:'Your next frontier', title:'Money & XP', description:'Money recovery, role XP, collectible loops, and unlock tools for your Red Dead Online progression.', href:'/products/rdr2/#product-details', action:'See recovery tools' }
        ] },
        { id:'fivem', name:'FiveM', href:'/products/fivem/', cards:[
            { art:'fivem-vehicles', kicker:'Dial in your combat setup', title:'Aimbot & ESP', description:'Aimbot, silent aim, triggerbot, and ESP for players, vehicles, and items. Fine-tune your aim and visual settings.', href:'/products/fivem/#product-details', action:'Explore combat & visuals' },
            { art:'fivem-chaos', kicker:'Make it your own', title:'Lua Executor & Triggers', description:'Lua execution, triggers, event and resource managers, plus Server Dumper to dump all resources and Stream Dumper for streamed assets.', href:'/docs/fivem/', action:'Explore Lua & server tools' },
            { art:'fivem-items', kicker:'Take control of the scene', title:'Freecam & World', description:'Freecam, noclip, teleportation, vehicle spawns, and player tools. Explore the map and change the way you play.', href:'/products/fivem/#product-details', action:'Explore world tools' }
        ] },
        { id:'redm', name:'RedM', href:'/products/redm/', cards:[
            { art:'redm-rides', kicker:'Dial in your frontier setup', title:'Aimbot & ESP', description:'Aimbot, triggerbot, and ESP for players, NPCs, horses, and objects, with customizable aim and visual settings.', href:'/products/redm/#product-details', action:'Explore combat & visuals' },
            { art:'redm-chaos', kicker:'Make it your own', title:'Lua Executor & Triggers', description:'Lua execution, triggers, event and resource managers, plus Server Dumper to dump all resources and Stream Dumper for streamed assets.', href:'/docs/redm/', action:'Explore Lua & server tools' },
            { art:'redm-trading', kicker:'Explore the frontier', title:'Freecam & World', description:'Freecam, noclip, teleportation, and horse, wagon, and NPC spawners. Set the scene with time and weather controls.', href:'/products/redm/#product-details', action:'Explore world tools' }
        ] },
        { id:'cs2', name:'CS2', href:'/features-list/cs2-features/', cards:[
            { art:'cs2-aim', kicker:'Dial in your setup', title:'Aim & Recoil', description:'Aim assistance, recoil controls, and triggerbot settings with options to fine-tune your setup.', href:'/features-list/cs2-features/#section-combat', action:'Explore combat tools' },
            { art:'cs2-visuals', kicker:'See the full picture', title:'ESP & Chams', description:'Player visuals, customizable chams, and overlays. Choose the information you want to see.', href:'/features-list/cs2-features/#section-player-visuals', action:'Explore visual tools' },
            { art:'cs2-loadout', kicker:'Your loadout, your style', title:'Skins & Loadouts', description:'Weapon skins, gloves, agents, and local inventory options to build your own look.', href:'/features-list/cs2-features/#section-skins-inventory', action:'Explore loadout tools' }
        ] },
        { id:'l4d', name:'Left 4 Dead', href:'/features-list/l4d-features/', cards:[
            { art:'l4d-awareness', kicker:'Keep your bearings', title:'Infected & Item ESP', description:'Infected, weapons, and pickup visuals, with radar and chams for Left 4 Dead 1 and 2.', href:'/features-list/l4d-features/#section-visuals', action:'Explore survival visuals' },
            { art:'l4d-movement', kicker:'Keep moving', title:'Movement Tools', description:'Bunnyhop, auto-strafe, and movement assistance. Customize your controls and keep moving through every campaign.', href:'/features-list/l4d-features/#section-movement', action:'Explore movement tools' },
            { art:'l4d-world', kicker:'Set the atmosphere', title:'World & View', description:'Adjust world visuals and view settings, then bring your setup together with hotkeys and profiles.', href:'/features-list/l4d-features/#section-world', action:'Explore world settings' }
        ] },
        { id:'gmod', name:'GMod', href:'/features-list/gmod-features/', cards:[
            { art:'gmod-visuals', kicker:'Choose your playstyle', title:'Rage & Legit Aimbot', description:'Rage and Legit aimbot, triggerbot, player and entity ESP, chams, and radar with customizable settings.', href:'/features-list/gmod-features/#section-combat', action:'Explore combat & visuals' },
            { art:'gmod-sandbox', kicker:'Keep moving', title:'Bunnyhop & Movement', description:'Bunnyhop, air strafe, edge jump, crouch jump, and long jump, with movement settings for your playstyle.', href:'/features-list/gmod-features/#section-movement', action:'Explore movement tools' },
            { art:'gmod-profiles', kicker:'Make it your own', title:'Lua Executor', description:'Run custom Lua scripts and manage your setup with saved profiles, hotkeys, and favorite features.', href:'/features-list/gmod-features/#section-lua', action:'Explore Lua tools' }
        ] }
    ];
    const cards = [...grid.querySelectorAll('.why-card')];
    const buttons = [...picker.querySelectorAll('[data-product]')];
    const controls = document.getElementById('whyProductControls');
    const toggle = document.getElementById('whyRotationToggle');
    const label = document.getElementById('whyProductLabel');
    const allLink = document.getElementById('whyAllFeatures');
    const status = document.getElementById('whyProductStatus');
    const motion = matchMedia('(prefers-reduced-motion: reduce)');
    const cache = new Map();
    let current = 0;
    let visible = false;
    let paused = motion.matches;
    let preferenceOverridden = false;
    let busy = false;
    let request = 0;
    let timer;
    let queue = [];

    function shuffle(items) {
        for (let i = items.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [items[i], items[j]] = [items[j], items[i]];
        }
        return items;
    }
    function nextProduct() {
        if (!queue.length) {
            queue = shuffle(products.map((_, index) => index));
            // Keep the end and start of consecutive shuffled rounds different.
            if (queue[0] === current) {
                const swap = 1 + Math.floor(Math.random() * (queue.length - 1));
                [queue[0], queue[swap]] = [queue[swap], queue[0]];
            }
        }
        return queue[0];
    }
    function canRun() {
        // Ordinary hovering or selecting a tab must not stop automatic rotation.
        // Hold a focused/hovered card link steady while someone is using it.
        return visible && !paused && !document.hidden &&
            !grid.querySelector('a:hover') && !grid.contains(document.activeElement);
    }
    function updateToggle() {
        const action = paused ? 'Resume automatic rotation' : 'Pause automatic rotation';
        toggle.setAttribute('aria-pressed', String(paused));
        toggle.setAttribute('aria-label', action);
        toggle.title = action;
    }
    function schedule() {
        clearTimeout(timer);
        if (canRun() && !busy) {
            const delay = 7000 + Math.floor(Math.random() * 3001);
            timer = setTimeout(() => changeProduct(nextProduct(), false), delay);
            preloadNext();
        }
    }
    function loadArtwork(art) {
        if (cache.has(art)) return cache.get(art);
        const promise = new Promise((resolve, reject) => {
            const image = new Image();
            const timeout = setTimeout(() => reject(new Error('Artwork timed out')), 15000);
            image.alt = '';
            image.width = 800;
            image.height = 1200;
            image.decoding = 'async';
            image.fetchPriority = 'low';
            image.className = 'why-art-image';
            image.onload = async () => {
                clearTimeout(timeout);
                try { await image.decode(); } catch (_) { /* A loaded image can still render. */ }
                resolve(image);
            };
            image.onerror = () => { clearTimeout(timeout); reject(new Error('Artwork unavailable')); };
            image.src = `/assets/images/features/${art}-v1.webp`;
        });
        cache.set(art, promise);
        promise.catch(() => cache.delete(art));
        return promise;
    }
    function preloadNext() {
        if (canRun()) products[nextProduct()].cards.forEach(card => loadArtwork(card.art).catch(() => {}));
    }
    async function changeProduct(index, manual) {
        clearTimeout(timer);
        const token = ++request;
        status.textContent = '';
        if (index === current) {
            busy = false;
            grid.removeAttribute('aria-busy');
            schedule();
            return;
        }
        busy = true;
        grid.setAttribute('aria-busy', 'true');
        try {
            const product = products[index];
            const artwork = await Promise.all(product.cards.map(card => loadArtwork(card.art)));
            if (token !== request || (!manual && !canRun())) return;
            product.cards.forEach((feature, i) => {
                const card = cards[i];
                const stage = card.querySelector('.why-card-art');
                const previous = stage.querySelector('.is-active');
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
            queue = queue.filter(item => item !== index);
            grid.dataset.product = product.id;
            label.textContent = `Inside the ${product.name} menu`;
            allLink.href = product.href;
            allLink.querySelector('span').textContent = `Explore ${product.name} features`;
            buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.product === product.id)));
        } catch (_) {
            if (token === request) {
                if (manual) status.textContent = 'That scene could not load. Select the product to try again.';
                else if (queue[0] === index) queue.push(queue.shift());
            }
        } finally {
            if (token === request) {
                busy = false;
                grid.removeAttribute('aria-busy');
                schedule();
            }
        }
    }
    queue = shuffle(products.map((_, index) => index).filter(index => index !== current));
    buttons.forEach(button => button.addEventListener('click', () => {
        const index = products.findIndex(product => product.id === button.dataset.product);
        if (index >= 0) changeProduct(index, true);
    }));
    toggle.addEventListener('click', () => {
        paused = !paused;
        preferenceOverridden = true;
        updateToggle();
        schedule();
    });
    updateToggle();
    controls.hidden = false;
    grid.querySelectorAll('a').forEach(link => {
        link.addEventListener('mouseenter', schedule);
        link.addEventListener('mouseleave', schedule);
    });
    grid.addEventListener('focusin', schedule);
    grid.addEventListener('focusout', () => setTimeout(schedule, 0));
    document.addEventListener('visibilitychange', schedule);
    motion.addEventListener('change', () => {
        if (!preferenceOverridden) paused = motion.matches;
        updateToggle();
        schedule();
    });
    if ('IntersectionObserver' in window) {
        new IntersectionObserver(entries => {
            visible = entries[0].isIntersecting;
            schedule();
        }, { threshold:0.1 }).observe(grid);
    } else {
        visible = true;
        schedule();
    }
})();
