'use strict';

globalThis.ScoobyResourceDialogs = {
  create(dialogs) {
    let active;

    function dismiss() {
      const dialog = active?.dialog;
      active = undefined;
      if (dialog?.open) dialog.close();
    }

    for (const dialog of dialogs) {
      dialog.querySelector('.resource-dialog-close').onclick = () => dialog.close();
      dialog.addEventListener('click', event => {
        if (event.target !== dialog) return;
        const rect = dialog.getBoundingClientRect();
        if (event.clientX < rect.left || event.clientX > rect.right ||
            event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
      });
      dialog.addEventListener('close', () => {
        if (dialog.open || active?.dialog !== dialog) return;
        const { hash } = active;
        active = undefined;
        if (hash !== location.hash) return;
        if (history.state?.resourceDialog === hash) history.back();
        else history.replaceState(history.state, '', location.pathname + location.search);
      });
    }

    return {
      present(dialog, address) {
        const url = new URL(address, location.origin);
        const { hash } = url;
        if (location.hash !== hash) history.pushState({ resourceDialog: hash }, '', location.pathname + location.search + hash);
        if (active?.dialog !== dialog) dismiss();
        active = { dialog, hash };
        dialog.querySelector('.resource-dialog-share').replaceChildren(copyResourceAddress(url.href));
        if (!dialog.open) dialog.showModal();
      },
      matches(hash) {
        return active?.hash === hash && active.dialog.open;
      },
      syncLocation() {
        if (active && active.hash !== location.hash) dismiss();
      },
      dismiss
    };
  }
};

function copyResourceAddress(url) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'resource-copy-link';
  button.textContent = 'Copy link';
  button.setAttribute('aria-live', 'polite');
  button.onclick = async () => {
    try {
      await navigator.clipboard.writeText(url);
      button.textContent = 'Link copied';
    } catch {
      const field = document.createElement('input');
      field.type = 'url';
      field.readOnly = true;
      field.value = url;
      field.setAttribute('aria-label', 'Resource link');
      button.replaceWith(field);
      field.focus();
      field.select();
    }
  };
  return button;
}
