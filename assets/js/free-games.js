(() => {
    const track = document.getElementById('included-products');
    const controls = document.querySelector('.free-game-controls');
    if (!track || !controls) return;
    const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
    const toggle = controls.querySelector('[data-game-toggle]');
    let playing = !reducedMotion.matches;
    let hovered = false;
    let visible = false;
    let timer;

    function schedule() {
        clearTimeout(timer);
        if (playing && visible && !hovered && !document.hidden && !track.contains(document.activeElement)) {
            timer = setTimeout(() => { advance(1); schedule(); }, 4500);
        }
    }
    function advance(direction) {
        const max = track.scrollWidth - track.clientWidth;
        const step = track.firstElementChild.getBoundingClientRect().width + parseFloat(getComputedStyle(track).gap);
        const edge = direction > 0 ? track.scrollLeft >= max - 2 : track.scrollLeft <= 2;
        track.scrollTo({ left:edge ? (direction > 0 ? 0 : max) : track.scrollLeft + step * direction, behavior:reducedMotion.matches ? 'instant' : 'smooth' });
    }
    function updateToggle() {
        toggle.textContent = playing ? 'Pause' : 'Play';
        toggle.setAttribute('aria-label', `${playing ? 'Pause' : 'Start'} automatic scrolling`);
        toggle.setAttribute('aria-pressed', String(!playing));
        schedule();
    }
    controls.hidden = false;
    controls.querySelector('[data-game-previous]').addEventListener('click', () => { advance(-1); schedule(); });
    controls.querySelector('[data-game-next]').addEventListener('click', () => { advance(1); schedule(); });
    toggle.addEventListener('click', () => { playing = !playing; updateToggle(); });
    track.addEventListener('pointerenter', () => { hovered = true; schedule(); });
    track.addEventListener('pointerleave', () => { hovered = false; schedule(); });
    track.addEventListener('pointerdown', () => { playing = false; updateToggle(); });
    track.addEventListener('focusin', schedule);
    track.addEventListener('focusout', () => setTimeout(schedule, 0));
    track.addEventListener('keydown', event => {
        if (event.target !== track || !['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
        event.preventDefault();
        advance(event.key === 'ArrowRight' ? 1 : -1);
        schedule();
    });
    document.addEventListener('visibilitychange', schedule);
    reducedMotion.addEventListener('change', () => { playing = !reducedMotion.matches; updateToggle(); });
    new IntersectionObserver(entries => { visible = entries[0].isIntersecting; schedule(); }, { threshold:.25 }).observe(track);
    updateToggle();
})();
