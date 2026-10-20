/* Optional conveniences; setup instructions remain usable without JavaScript. */
(function () {
    const guide = document.getElementById('plus-setup');
    if (!guide) return;
    const feedback = guide.querySelector('[data-plus-feedback]');
    const timers = new WeakMap();

    const imageLinks = [...guide.querySelectorAll('.plus-bios-enlarge')];
    if (imageLinks.length) {
        const viewer = document.createElement('dialog');
        viewer.className = 'plus-bios-dialog';
        viewer.setAttribute('aria-labelledby', 'plus-bios-viewer-title');
        const heading = document.createElement('h2');
        heading.id = 'plus-bios-viewer-title';
        const close = document.createElement('button');
        close.type = 'button';
        close.textContent = 'Close';
        close.setAttribute('aria-label', 'Close BIOS picture');
        const zoom = document.createElement('button');
        zoom.type = 'button';
        zoom.textContent = 'Zoom in';
        zoom.setAttribute('aria-pressed', 'false');
        const header = document.createElement('div');
        header.className = 'plus-bios-viewer-header';
        header.append(heading, zoom, close);
        const hint = document.createElement('p');
        hint.textContent = 'Use Zoom in for small labels, then scroll to move around the picture. Press Esc to close.';
        const viewport = document.createElement('div');
        viewport.className = 'plus-bios-zoom-area';
        viewport.tabIndex = 0;
        viewport.setAttribute('role', 'region');
        viewport.setAttribute('aria-label', 'Enlarged BIOS picture');
        const caption = document.createElement('p');
        caption.className = 'plus-bios-viewer-caption';
        viewer.append(header, hint, viewport, caption);
        document.body.append(viewer);
        let opener = null;
        let enlarged = false;
        imageLinks.forEach(link => link.addEventListener('click', event => {
            // Preserve the normal full-size image link for modified clicks.
            if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
            event.preventDefault();
            opener = link;
            const shot = link.querySelector('.plus-bios-shot').cloneNode(true);
            shot.querySelector('img').loading = 'eager';
            viewport.replaceChildren(shot);
            heading.textContent = link.dataset.biosTitle;
            const figure = link.closest('figure');
            caption.textContent = figure.querySelector('.plus-bios-target').textContent + '. ' + figure.querySelector('figcaption').textContent;
            enlarged = false;
            zoom.textContent = 'Zoom in';
            zoom.setAttribute('aria-pressed', 'false');
            viewer.showModal();
            viewport.scrollTo(0, 0);
        }));
        zoom.addEventListener('click', () => {
            enlarged = !enlarged;
            const shot = viewport.querySelector('.plus-bios-shot');
            const img = shot.querySelector('img');
            shot.style.width = enlarged ? Math.max(img.naturalWidth || img.width, 1200) + 'px' : '';
            zoom.textContent = enlarged ? 'Fit image' : 'Zoom in';
            zoom.setAttribute('aria-pressed', String(enlarged));
        });
        close.addEventListener('click', () => viewer.close());
        viewer.addEventListener('close', () => { opener?.focus(); });
        viewer.addEventListener('click', event => {
            if (event.target !== viewer) return;
            const bounds = viewer.getBoundingClientRect();
            if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) viewer.close();
        });
    }

    // Deep links also reveal sections inside the optional reference panels.
    const revealHash = () => {
        let id;
        try { id = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
        const target = document.getElementById(id);
        if (!target || !guide.contains(target)) return;
        let detail = target.closest('details');
        while (detail) {
            detail.open = true;
            detail = detail.parentElement.closest('details');
        }
        requestAnimationFrame(() => target.scrollIntoView({ block: 'start' }));
    };
    window.addEventListener('hashchange', revealHash);
    revealHash();

    guide.querySelectorAll('pre > code').forEach(code => {
        const pre = code.parentElement;
        const wrapper = document.createElement('div');
        wrapper.className = 'plus-code-block';
        pre.before(wrapper);
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'plus-copy-button';
        const label = pre.dataset.copyLabel || 'Copy text';
        button.textContent = label;
        wrapper.append(button, pre);
        button.addEventListener('click', async () => {
            clearTimeout(timers.get(button));
            try {
                await navigator.clipboard.writeText(code.textContent);
                button.textContent = 'Copied';
                feedback.textContent = label === 'Copy template' ? 'Support template copied.' : 'Text copied. Copying does not run the command.';
            } catch (_) {
                const selection = window.getSelection();
                const range = document.createRange();
                range.selectNodeContents(code);
                selection.removeAllRanges();
                selection.addRange(range);
                button.textContent = 'Text selected';
                feedback.textContent = 'Clipboard access is unavailable. The text is selected; use your device’s Copy command.';
            }
            timers.set(button, setTimeout(() => { button.textContent = label; }, 2500));
        });
    });

    // Expand the help sections for printing, then restore the reader's view.
    let printState = null;
    window.addEventListener('beforeprint', () => {
        if (printState) return;
        printState = [...guide.querySelectorAll('details')].map(detail => [detail, detail.open]);
        printState.forEach(([detail]) => { detail.open = true; });
    });
    window.addEventListener('afterprint', () => {
        if (!printState) return;
        printState.forEach(([detail, open]) => { detail.open = open; });
        printState = null;
    });
    const printButton = guide.querySelector('[data-plus-print]');
    if (typeof window.print === 'function') {
        printButton.hidden = false;
        printButton.addEventListener('click', async () => {
            // Load the reference image before asking the browser to print it.
            await Promise.all([...guide.querySelectorAll('img')].map(async img => {
                img.loading = 'eager';
                try { await img.decode(); } catch (_) { /* Print text even if an image is unavailable. */ }
            }));
            window.print();
        });
    }
})();
