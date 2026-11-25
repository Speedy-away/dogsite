(() => {
    'use strict';
    const account = document.getElementById('userDropdown');
    const toggle = document.getElementById('accountMenuToggle');
    const menu = document.getElementById('accountMenu');
    const menuItems = () => [...menu.querySelectorAll('button')].filter(button => !button.disabled && button.getClientRects().length);

    function closeAccount(restoreFocus = false) {
        menu.hidden = true;
        toggle.setAttribute('aria-expanded', 'false');
        if (restoreFocus) toggle.focus();
    }
    function openAccount() {
        menu.hidden = false;
        toggle.setAttribute('aria-expanded', 'true');
    }
    toggle.addEventListener('click', () => menu.hidden ? openAccount() : closeAccount());
    toggle.addEventListener('keydown', event => {
        if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
            event.preventDefault();
            openAccount();
            const items = menuItems();
            items[event.key === 'ArrowDown' ? 0 : items.length - 1]?.focus();
        }
    });
    menu.addEventListener('click', event => {
        if (event.target.closest('.dropdown-item')) closeAccount(menu.contains(document.activeElement));
    });
    menu.addEventListener('keydown', event => {
        const items = menuItems();
        const index = items.indexOf(document.activeElement);
        if (index < 0) return;
        let next;
        if (event.key === 'ArrowDown') next = (index + 1) % items.length;
        if (event.key === 'ArrowUp') next = (index + items.length - 1) % items.length;
        if (event.key === 'Home') next = 0;
        if (event.key === 'End') next = items.length - 1;
        if (next !== undefined) { event.preventDefault(); items[next].focus(); }
    });
    document.addEventListener('click', event => {
        if (!account.contains(event.target)) closeAccount();
    });
    document.addEventListener('focusin', event => {
        if (!account.contains(event.target)) closeAccount();
    });
    document.addEventListener('keydown', event => {
        if (event.key !== 'Escape') return;
        if (!menu.hidden) { event.preventDefault(); closeAccount(true); }
    });
    window.addEventListener('hashchange', () => closeAccount());
})();
