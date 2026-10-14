/* Use the existing GTA checkout flow for comparison links and library referrals. */
(() => {
    const plans = ['premium', 'premium-plus', 'upgrade'];
    document.querySelectorAll('[data-gta-plan]').forEach(link => link.addEventListener('click', event => {
        if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button !== 0) return;
        if (!plans.includes(link.dataset.gtaPlan)) return;
        event.preventDefault();
        selectTier(link.dataset.gtaPlan);
    }));
    const plan = new URLSearchParams(location.search).get('plan');
    if (plans.includes(plan)) selectTier(plan);
})();
