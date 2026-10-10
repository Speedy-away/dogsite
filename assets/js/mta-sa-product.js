(function () {
  const trigger = document.getElementById('mtaPurchase');
  const dialog = document.getElementById('mtaPurchaseModal');
  let previousOverflow;
  trigger.addEventListener('click', function () {
    previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    dialog.showModal();
  });
  dialog.querySelectorAll('[data-close-purchase]').forEach(button => {
    button.addEventListener('click', () => dialog.close());
  });
  dialog.addEventListener('click', event => {
    if (event.target === dialog) {
      const rect = dialog.getBoundingClientRect();
      if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
    }
  });
  dialog.addEventListener('close', function () {
    document.body.style.overflow = previousOverflow;
    trigger.focus();
  });
})();
