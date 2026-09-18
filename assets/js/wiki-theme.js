/* Apply the saved theme before first paint. Storage may be unavailable in private contexts. */
(function () {
    try {
        const theme = localStorage.getItem('scooby-wiki-theme');
        if (theme === 'light' || theme === 'dark') document.documentElement.dataset.theme = theme;
    } catch (_) {}
})();
