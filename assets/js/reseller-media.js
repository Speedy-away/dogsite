(() => {
  const dialog = document.getElementById('media-dialog');
  const trigger = document.getElementById('open-media-pack');
  if (!dialog || !trigger) return;
  trigger.addEventListener('click', () => dialog.showModal());
  document.getElementById('close-media-pack').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const rect = dialog.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => trigger.focus());
})();
