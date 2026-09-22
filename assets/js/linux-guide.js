/* Progressive enhancements; setup steps also work without JavaScript. */
(function () {
    const guide = document.getElementById('linux-mac');
    if (!guide) return;
    const status = document.createElement('p');
    status.className = 'sr-only';
    status.setAttribute('role', 'status');
    guide.append(status);
    const copyButtons = new Map();
    guide.querySelectorAll('pre > code').forEach(code => {
        const bar = document.createElement('div');
        bar.className = 'command-bar';
        const label = document.createElement('span');
        label.className = 'command-label';
        label.textContent = code.dataset.commandLabel || 'Terminal command';
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'copy-command';
        button.textContent = 'Copy';
        button.setAttribute('aria-label', 'Copy: ' + label.textContent);
        button.addEventListener('click', async () => {
            try {
                await navigator.clipboard.writeText(code.textContent.trim());
                button.textContent = 'Copied';
                status.textContent = label.textContent + ' copied. Paste it in your terminal.';
            } catch (_) {
                const range = document.createRange();
                range.selectNodeContents(code);
                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
                button.textContent = 'Select & copy';
                status.textContent = 'Clipboard access is unavailable. The command is selected; copy it manually.';
            }
        });
        bar.append(label, button);
        code.parentElement.before(bar);
        copyButtons.set(code, button);
    });
    guide.querySelectorAll('[data-steam-setup]').forEach(section => {
        const field = section.querySelector('[data-appid-field]');
        const input = field.querySelector('input');
        const help = field.querySelector('[data-appid-help]');
        const commands = [...section.querySelectorAll('[data-appid-command]')].map(code => ({code, template: code.textContent}));
        field.hidden = false;
        section.querySelector('[data-appid-fallback]').hidden = true;
        const update = () => {
            const value = input.value.trim();
            const valid = /^[1-9][0-9]{0,9}$/.test(value) && Number(value) <= 4294967295;
            input.setAttribute('aria-invalid', String(Boolean(value) && !valid));
            help.textContent = valid ? 'Your command is ready. Copy it below, then paste it in your terminal.' : value ? 'Enter only the positive game number from the list above (up to 4294967295).' : 'Paste the number next to your game. Your launch command will update below.';
            commands.forEach(({code, template}) => {
                code.textContent = template.replace(/APPID/g, valid ? value : 'APPID');
                const button = copyButtons.get(code);
                button.disabled = !valid;
                button.textContent = 'Copy';
                button.title = valid ? '' : 'Enter your game App ID above first';
            });
        };
        input.addEventListener('input', update);
        update();
    });
    const revealHash = () => {
        let id;
        try { id = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
        const target = document.getElementById(id);
        if (!target || !guide.contains(target)) return;
        let parent = target;
        while (parent && parent !== guide) {
            if (parent.tagName === 'DETAILS') parent.open = true;
            parent = parent.parentElement;
        }
        requestAnimationFrame(() => target.scrollIntoView({block: 'start'}));
    };
    window.addEventListener('hashchange', revealHash);
    guide.addEventListener('click', event => {
        const link = event.target.closest('a[href^="#"]');
        if (link && link.hash === location.hash) revealHash();
    });
    revealHash();
})();
