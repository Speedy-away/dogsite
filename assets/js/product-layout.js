/* Shared navigation for product pages. Purchase and gallery controls stay local. */
(function () {
    'use strict';
    const nav = document.getElementById('product-nav');
    const button = document.getElementById('hamburgerBtn');
    const links = document.getElementById('navLinks');
    if (!nav || !button || !links) return;
    const mobile = window.matchMedia('(max-width: 980px)');
    function setOpen(open) {
        links.classList.toggle('mobile-open', open);
        button.setAttribute('aria-expanded', String(open));
        button.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
    }
    button.addEventListener('click', function () { setOpen(button.getAttribute('aria-expanded') !== 'true'); });
    links.querySelectorAll('a').forEach(function (link) { link.addEventListener('click', function () { setOpen(false); }); });
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape' && button.getAttribute('aria-expanded') === 'true') {
            setOpen(false);
            button.focus();
        }
    });
    document.addEventListener('click', function (event) { if (!nav.contains(event.target)) setOpen(false); });
    mobile.addEventListener('change', function () { setOpen(false); });
    function updateScroll() { nav.classList.toggle('scrolled', window.scrollY > 60); }
    window.addEventListener('scroll', updateScroll, { passive: true });
    updateScroll();
})();
