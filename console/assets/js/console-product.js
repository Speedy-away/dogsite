(() => {
  'use strict';
  const dialog = document.getElementById('consoleAccessDialog');
  document.querySelectorAll('[data-console-access]').forEach(button => {
    button.addEventListener('click', () => {
      document.getElementById('consoleAccessTitle').textContent = button.dataset.consoleAccess + ' access · Coming soon';
      document.getElementById('consoleAccessMessage').textContent = 'This PlayStation 4 product has not been released yet. ' + (button.dataset.consoleAccess === 'Free' ? 'Free keys' : 'Purchases') + ' are not available yet.';
      dialog.showModal();
    });
  });
  dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
})();
