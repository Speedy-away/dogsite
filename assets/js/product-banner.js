(() => {
    const slot = document.querySelector('.product-banner-slot');
    const frame = slot?.querySelector('iframe');
    if (!frame) return;

    const bannerOrigin = new URL(frame.src).origin;
    window.addEventListener('message', (event) => {
        if (event.origin !== bannerOrigin || event.source !== frame.contentWindow) return;
        if (event.data === 'scooby:product-banner-ready') {
            frame.removeAttribute('inert');
            slot.classList.add('has-creative');
            return;
        }
        if (event.data?.type !== 'scooby:product-banner-click' ||
            !slot.classList.contains('has-creative') || document.activeElement !== frame ||
            !navigator.userActivation?.isActive || typeof event.data.href !== 'string') return;
        let destination;
        try { destination = new URL(event.data.href); } catch { return; }
        if (/^https?:$/.test(destination.protocol)) location.assign(destination.href);
    });
})();
