(() => {
    const slot = document.querySelector('.product-banner-slot');
    const frame = slot?.querySelector('iframe');
    if (!frame) return;

    window.addEventListener('message', function showCreative(event) {
        if (event.origin !== new URL(frame.src).origin || event.source !== frame.contentWindow ||
            event.data !== 'scooby:product-banner-ready') return;
        frame.removeAttribute('inert');
        slot.classList.add('has-creative');
        window.removeEventListener('message', showCreative);
    });
})();
