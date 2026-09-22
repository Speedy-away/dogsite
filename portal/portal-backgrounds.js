(() => {
    'use strict';
    const stage = document.getElementById('portalBackgrounds');
    if (!stage) return;

    const scenes = ['gta-boulevard', 'cs2-ancient-v2', 'l4d2-parish', 'gmod-construct', 'rdr-overlook'];
    const motion = matchMedia('(prefers-reduced-motion: reduce)');
    const cache = new Map();
    let current = 0;
    let activeLayer = stage.querySelector('.is-active');
    let busy = false;
    let timer;

    function editing() {
        return document.activeElement?.matches('input:not([type=hidden]),textarea,select,[contenteditable="true"]');
    }
    function canRun() { return !motion.matches && !document.hidden && !editing(); }
    function schedule() {
        clearTimeout(timer);
        stage.classList.toggle('is-paused', !canRun());
        if (canRun() && !busy) timer = setTimeout(advance, 12000);
    }
    function loadImage(index) {
        if (cache.has(index)) return cache.get(index);
        const promise = new Promise((resolve, reject) => {
            const img = new Image();
            const timeout = setTimeout(() => reject(new Error('Background timed out')), 15000);
            img.alt = '';
            img.width = 1672;
            img.height = 941;
            img.decoding = 'async';
            img.fetchPriority = 'low';
            img.onload = async () => {
                clearTimeout(timeout);
                try { await img.decode(); } catch (_) { /* A loaded image is still usable. */ }
                resolve(img);
            };
            img.onerror = () => { clearTimeout(timeout); reject(new Error('Background unavailable')); };
            img.src = `images/backgrounds/${scenes[index]}.png`;
        });
        cache.set(index, promise);
        promise.catch(() => cache.delete(index));
        return promise;
    }
    function preloadNext() {
        if (canRun()) loadImage((current + 1) % scenes.length).catch(() => {});
    }
    async function advance() {
        if (busy || !canRun()) return;
        busy = true;
        clearTimeout(timer);
        try {
            let img;
            let next;
            for (let offset = 1; offset < scenes.length; offset++) {
                next = (current + offset) % scenes.length;
                try { img = await loadImage(next); break; } catch (_) { /* Keep the current artwork if loading fails. */ }
            }
            if (!img || !canRun()) return;
            const layer = document.createElement('div');
            layer.className = 'portal-background-scene';
            layer.dataset.scene = scenes[next];
            layer.appendChild(img);
            stage.appendChild(layer);
            void layer.offsetWidth;
            layer.classList.add('is-active');
            const previous = activeLayer;
            previous.classList.add('is-leaving');
            previous.classList.remove('is-active');
            activeLayer = layer;
            current = next;
            // Keep both layers until the crossfade finishes.
            await new Promise(resolve => setTimeout(resolve, motion.matches ? 0 : 1650));
            previous.remove();
            preloadNext();
        } finally {
            busy = false;
            schedule();
        }
    }
    document.addEventListener('visibilitychange', () => { schedule(); preloadNext(); });
    document.addEventListener('focusin', schedule);
    document.addEventListener('focusout', () => setTimeout(schedule, 0));
    motion.addEventListener('change', () => { schedule(); preloadNext(); });
    schedule();
    // Fetch a single upcoming scene after the page has finished its initial load.
    if (document.readyState === 'complete') preloadNext();
    else window.addEventListener('load', preloadNext, { once:true });
})();
