/* PS4 uses the same RDR2 product; modal work happens only on interaction. */
(() => {
    'use strict';
    const modal = document.getElementById('paymentModal');
    const trigger = document.querySelector('[data-payment-open]');
    if (!modal || !trigger) return;
    // Keep the dialog outside the page wrapper before making the background inert.
    document.body.appendChild(modal);
    const closeButton = modal.querySelector('[data-payment-close]');
    let previousFocus, previousOverflow, siblings = [];
    const focusable = () => [...modal.querySelectorAll('button, a[href]')].filter(el => !el.disabled && el.getClientRects().length);
    function close() {
        if (!modal.classList.contains('active')) return;
        modal.classList.remove('active');
        modal.setAttribute('aria-hidden', 'true');
        trigger.setAttribute('aria-expanded', 'false');
        document.body.style.overflow = previousOverflow;
        for (const [el, wasInert] of siblings) el.inert = wasInert;
        siblings = [];
        if (previousFocus?.isConnected) previousFocus.focus();
    }
    trigger.addEventListener('click', () => {
        if (modal.classList.contains('active')) return;
        previousFocus = document.activeElement;
        previousOverflow = document.body.style.overflow;
        siblings = [...document.body.children].filter(el => el !== modal && el.tagName !== 'SCRIPT').map(el => [el, el.inert]);
        for (const [el] of siblings) el.inert = true;
        modal.classList.add('active');
        modal.setAttribute('aria-hidden', 'false');
        trigger.setAttribute('aria-expanded', 'true');
        document.body.style.overflow = 'hidden';
        closeButton.focus();
    });
    closeButton.addEventListener('click', close);
    modal.addEventListener('click', event => { if (event.target === modal) close(); });
    document.addEventListener('keydown', event => {
        if (!modal.classList.contains('active')) return;
        if (event.key === 'Escape') { event.preventDefault(); close(); }
        else if (event.key === 'Tab') {
            const items = focusable(), first = items[0], last = items[items.length - 1];
            if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
            else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
        }
    });
})();
