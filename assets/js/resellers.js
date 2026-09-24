/* Region/game filtering and the reseller product/payment dialog. */
(() => {
  'use strict';
  const cards = [...document.querySelectorAll('.reseller-card')];
  const regions = [...document.querySelectorAll('[data-region]')];
  const gameFilter = document.getElementById('game-filter');
  const dialog = document.getElementById('reseller-dialog');
  const title = document.getElementById('dialog-title');
  const description = document.getElementById('dialog-description');
  const products = document.getElementById('product-options');
  const payments = document.getElementById('payment-options');
  const selected = document.getElementById('selected-product');
  const back = dialog.querySelector('.dialog-back');
  const note = document.getElementById('dialog-note');
  let region = 'international';
  let activeCard = null;
  let opener = null;
  let selectedGame = null;
  const games = {
    gta5: { name: 'Grand Theft Auto V', description: 'Scooby for GTA 5', image: '/assets/images/store/gta5-logo-transparent.png' },
    rdr2: { name: 'Red Dead Redemption 2', description: 'Scooby for RDR2', image: '/assets/images/store/rdr2-logo-transparent.png' },
    fivem: { name: 'FiveM', description: 'Scooby for FiveM', image: '/assets/images/store/fivem.webp' },
    redm: { name: 'RedM', description: 'Scooby for RedM', image: '/assets/images/store/redm.webp' }
  };
  const iconPaths = {
    arrow: 'M5 12h14M13 6l6 6-6 6',
    external: 'M7 17 17 7M7 7h10v10',
    card: 'M3 5h18v14H3zM3 10h18M6 15h4',
    crypto: 'M12 3 5 12l7 4 7-4-7-9ZM5 15l7 6 7-6',
    support: 'M4 4h16v12H9l-5 4V4Z'
  };
  function icon(name, className = '') {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    for (const [attr, value] of Object.entries({ viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '1.5', 'aria-hidden': 'true', class: className })) svg.setAttribute(attr, value);
    const path = document.createElementNS(svg.namespaceURI, 'path');
    path.setAttribute('d', iconPaths[name]); svg.append(path); return svg;
  }
  function element(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }
  function image(game) {
    const img = element('img', 'product-art'); img.src = game.image; img.alt = ''; img.width = 96; img.height = 60; return img;
  }
  function outbound(url) {
    const link = document.createElement('a'); link.href = url; link.target = '_blank'; link.rel = 'noopener';
    link.addEventListener('click', () => dialog.close()); return link;
  }
  function filterCards() {
    let count = 0;
    for (const card of cards) {
      const visible = card.dataset.regions.split(' ').includes(region) && (gameFilter.value === 'all' || Boolean(card.dataset[gameFilter.value]));
      card.hidden = !visible; if (visible) count++;
    }
    regions.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.region === region)));
    document.getElementById('directory-count').textContent = `${count} ${count === 1 ? 'store' : 'stores'} available`;
    document.getElementById('directory-empty').hidden = count !== 0;
    document.getElementById('empty-title').textContent = region === 'chinese' ? 'More stores on the way.' : 'No stores for this selection.';
    document.getElementById('empty-description').textContent = region === 'chinese' ? 'No resellers are listed for this region yet. Browse International for more options.' : 'Try another game or browse International to find more stores.';
  }
  regions.forEach(button => button.addEventListener('click', () => { region = button.dataset.region; filterCards(); }));
  gameFilter.addEventListener('change', filterCards);
  document.querySelector('.reset-filters').addEventListener('click', () => {
    region = 'international'; gameFilter.value = 'all'; filterCards(); regions[0].focus();
  });
  function renderProducts() {
    title.textContent = 'Choose your game.';
    description.textContent = 'Pick the Scooby license you want to explore.';
    document.getElementById('dialog-step').textContent = 'SELECT A PRODUCT';
    products.hidden = false; payments.hidden = true; selected.hidden = true; back.hidden = true;
    note.textContent = activeCard.dataset.checkout === 'payment' ? 'Choose a game to see the available payment options.' : "The reseller's store opens in a new tab.";
    products.replaceChildren();
    for (const [key, game] of Object.entries(games)) {
      const url = activeCard.dataset[key]; if (!url) continue;
      const option = activeCard.dataset.checkout === 'payment' ? document.createElement('button') : outbound(url);
      if (option.tagName === 'BUTTON') {
        option.type = 'button'; option.addEventListener('click', () => renderPayments(key, url));
      }
      option.className = 'product-option'; option.dataset.product = key;
      const copy = element('span', 'product-copy');
      copy.append(element('strong', '', game.name), element('small', '', game.description));
      option.append(image(game), copy, icon(activeCard.dataset.checkout === 'payment' ? 'arrow' : 'external', 'option-arrow'));
      products.append(option);
    }
  }
  function renderPayments(key, url) {
    selectedGame = key;
    title.textContent = 'How would you like to pay?';
    description.textContent = 'Choose a payment option for your Scooby license.';
    document.getElementById('dialog-step').textContent = 'PAYMENT OPTIONS';
    products.hidden = true; payments.hidden = false; selected.hidden = false; back.hidden = false;
    selected.replaceChildren(image(games[key]), element('strong', '', games[key].name));
    note.textContent = 'Checkout and support open in a new tab.';
    payments.replaceChildren();
    const methods = [
      { name: 'Card & more', detail: 'Continue to the store checkout', icon: 'card', url },
      { name: 'Cryptocurrency', detail: 'Bitcoin, Ethereum & more', icon: 'crypto', url: 'https://nenyoo.store/' },
      { name: 'Other payment options', detail: 'PayPal, Skrill, Paysafe & more · Contact support', icon: 'support', url: 'https://discord.gg/tGtvzChYQq' }
    ];
    methods.forEach(method => {
      const link = outbound(method.url); link.className = 'payment-option';
      const mark = element('span', 'payment-icon'); mark.append(icon(method.icon));
      const copy = element('span', 'payment-copy'); copy.append(element('strong', '', method.name), element('small', '', method.detail));
      link.append(mark, copy, icon('external', 'option-arrow')); payments.append(link);
    });
    dialog.scrollTop = 0; title.focus({ preventScroll: true });
  }
  for (const card of cards) {
    card.querySelector('.choose-products').addEventListener('click', event => {
      activeCard = card; opener = event.currentTarget; selectedGame = null;
      document.getElementById('dialog-seller-name').textContent = card.dataset.name;
      document.getElementById('dialog-avatar').replaceChildren(...[...card.querySelector('.seller-avatar').childNodes].map(node => node.cloneNode(true)));
      renderProducts(); dialog.showModal(); document.body.classList.add('dialog-open'); dialog.scrollTop = 0; title.focus({ preventScroll: true });
    });
  }
  back.addEventListener('click', () => {
    renderProducts(); dialog.scrollTop = 0;
    (products.querySelector(`[data-product="${selectedGame}"]`) || title).focus({ preventScroll: true });
  });
  dialog.addEventListener('keydown', event => {
    if (event.key !== 'Tab') return;
    const controls = [...dialog.querySelectorAll('button, a[href]')].filter(node => !node.disabled && node.getClientRects().length);
    const first = controls[0], last = controls[controls.length - 1];
    if (event.shiftKey && (document.activeElement === first || document.activeElement === title)) {
      event.preventDefault(); last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault(); first.focus();
    }
  });
  dialog.querySelector('.dialog-close').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const rect = dialog.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => {
    document.body.classList.remove('dialog-open');
    if (opener && !opener.closest('[hidden]')) opener.focus({ preventScroll: true });
  });
  const menuButton = document.querySelector('.menu-toggle');
  const navigation = document.getElementById('partner-nav');
  function closeMenu() { menuButton.setAttribute('aria-expanded', 'false'); navigation.classList.remove('is-open'); }
  menuButton.addEventListener('click', () => {
    const open = menuButton.getAttribute('aria-expanded') !== 'true';
    menuButton.setAttribute('aria-expanded', String(open)); navigation.classList.toggle('is-open', open);
  });
  navigation.addEventListener('click', event => { if (event.target.closest('a')) closeMenu(); });
  document.addEventListener('keydown', event => { if (event.key === 'Escape') closeMenu(); });
})();
