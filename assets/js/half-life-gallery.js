(() => {
    'use strict';
    const links = Array.from(document.querySelectorAll('[data-hl-preview]'));
    const dialog = document.getElementById('hl-lightbox');
    if (!dialog || !links.length || typeof dialog.showModal !== 'function') return;
    const image = dialog.querySelector('#hl-lightbox-image');
    const caption = dialog.querySelector('#hl-lightbox-caption');
    const count = dialog.querySelector('#hl-lightbox-count');
    let selected = 0, opener = null;
    function show(index) {
        selected = (index + links.length) % links.length;
        const link = links[selected];
        image.src = link.href;
        image.alt = link.querySelector('img').alt;
        caption.textContent = link.dataset.caption;
        count.textContent = `${selected + 1} / ${links.length}`;
    }
    links.forEach((link, index) => link.addEventListener('click', event => {
        if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        opener = link;
        show(index);
        dialog.showModal();
    }));
    dialog.querySelector('[data-hl-close]').addEventListener('click', () => dialog.close());
    dialog.querySelector('[data-hl-previous]').addEventListener('click', () => show(selected - 1));
    dialog.querySelector('[data-hl-next]').addEventListener('click', () => show(selected + 1));
    dialog.addEventListener('keydown', event => {
        if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
            event.preventDefault();
            show(selected + (event.key === 'ArrowRight' ? 1 : -1));
        }
    });
    dialog.addEventListener('click', event => {
        const rect = dialog.getBoundingClientRect();
        if (event.target === dialog && (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom)) dialog.close();
    });
    dialog.addEventListener('close', () => { if (opener) opener.focus({preventScroll: true}); });
})();
