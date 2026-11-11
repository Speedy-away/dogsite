'use strict';
// Static resource content and links work without JavaScript. Local previews
// reuse the allowlisted download-repository route used by the main browser.
const localPreview = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
for (const image of document.querySelectorAll('[data-resource-image], [data-resource-image-fallback], [data-resource-image-unavailable]')) {
  const path = image.dataset.resourceImage;
  const fallback = image.dataset.resourceImageFallback;
  const unavailable = image.hasAttribute('data-resource-image-unavailable');
  const showFallback = () => {
    image.closest('a')?.setAttribute('aria-label', image.alt.replace(/ preview$/, ''));
    if (unavailable) {
      const message = document.createElement('span');
      message.className = 'preview-unavailable';
      message.textContent = 'Preview unavailable';
      image.replaceWith(message);
      return;
    }
    image.classList.add('preview-placeholder');
    image.alt = '';
    image.src = fallback;
  };
  if (fallback || unavailable) image.addEventListener('error', showFallback, { once: true });
  if (localPreview && path && !path.startsWith('/') && !path.includes('\\') && !path.split('/').some(part => part === '..' || part === '.')) {
    image.src = '/community-files/' + path.split('/').map(encodeURIComponent).join('/');
  } else if ((fallback || unavailable) && image.complete && !image.naturalWidth) {
    image.removeEventListener('error', showFallback);
    showFallback();
  }
}

for (const button of document.querySelectorAll('[data-download-file]')) {
  button.addEventListener('click', async () => {
    const status = button.closest('.resource-sample').querySelector('.resource-download-status');
    button.disabled = true;
    status.textContent = 'Preparing download…';
    try {
      const file = JSON.parse(button.dataset.downloadFile);
      const url = new URL(file.url, location.origin);
      if (url.protocol !== 'https:' && url.origin !== location.origin) throw Error('Unsupported download URL');
      const local = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
      if (local && url.origin === 'https://scoobymenu.cc' && url.pathname.startsWith('/community/media/')) {
        url.protocol = location.protocol;
        url.host = location.host;
      }
      if (local && url.hostname === 'raw.githubusercontent.com' && url.pathname.startsWith('/Speedy-away/cool-repo/main/')) {
        const relative = decodeURIComponent(url.pathname.slice('/Speedy-away/cool-repo/main/'.length));
        if (relative.split('/').some(part => !part || part === '.' || part === '..')) throw Error('Unsupported download path');
        url.href = location.origin + '/community-files/' + relative.split('/').map(encodeURIComponent).join('/');
      }
      const archive = /\.(?:zip|rar|7z|gz)(?:\.\d{3})?$/i.test(file.formatPath || file.name || url.pathname);
      const stored = url.origin === location.origin || (url.hostname === 'raw.githubusercontent.com' && url.pathname.startsWith('/Speedy-away/cool-repo/main/'));
      const largeArchive = stored && Number(file.size) >= 50 * 1024 * 1024 && archive;
      // Cross-origin download attributes do not save renderable JSON/XML/text.
      // Only verified binary archives can use a native transfer.
      const native = archive && (file.downloadMethod === 'direct' || largeArchive || (url.hostname === 'github.com' && url.pathname.includes('/releases/download/')));
      const anchor = document.createElement('a');
      anchor.download = file.name || 'download';
      let object;
      if (native) anchor.href = url.href;
      else {
        const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
        if (!response.ok || /text\/html/i.test(response.headers.get('content-type') || '')) throw Error('Download unavailable');
        object = URL.createObjectURL(await response.blob());
        anchor.href = object;
      }
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      if (object) setTimeout(() => URL.revokeObjectURL(object), 10000);
      status.textContent = native ? 'Download started.' : 'Downloaded.';
    } catch { status.textContent = 'Download unavailable. Please try again.'; }
    finally { button.disabled = false; }
  });
}

const changelogDialog = document.getElementById('resource-changelog');
if (changelogDialog) {
  for (const button of document.querySelectorAll('[data-resource-changelog]')) button.addEventListener('click', () => {
    const data = JSON.parse(button.dataset.resourceChangelog);
    document.getElementById('resource-changelog-title').textContent = `${data.name} · Changelog`;
    const content = document.getElementById('resource-changelog-content');
    content.replaceChildren();
    if (data.notes?.length) {
      const list = document.createElement('ul');
      for (const note of data.notes) { const item = document.createElement('li'); item.textContent = note; list.append(item); }
      content.append(list);
    } else content.textContent = 'No changelog has been published for this resource.';
    changelogDialog.showModal();
  });
  document.getElementById('close-resource-changelog').addEventListener('click', () => changelogDialog.close());
  changelogDialog.addEventListener('click', event => {
    if (event.target !== changelogDialog) return;
    const rect = changelogDialog.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) changelogDialog.close();
  });
}

function loadCatalogScript(source) {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = source;
    script.onload = resolve;
    script.onerror = reject;
    document.head.append(script);
  });
}

async function mountCatalog() {
  const directory = document.querySelector('.resource-directory');
  const response = await fetch('/resources/', { signal: AbortSignal.timeout(10000) });
  if (!response.ok) return;
  const shell = new DOMParser().parseFromString(await response.text(), 'text/html');
  const main = shell.querySelector('main:has(#collection)');
  const dialogs = [...shell.querySelectorAll('#gta-menu-dialog, #preview, #changelog')];
  const catalogSource = shell.querySelector('head script[src^="/resources/catalog.js"]')?.getAttribute('src');
  if (!main || dialogs.length !== 3 || !catalogSource) return;
  main.id = directory.id;

  await Promise.all(['taxonomy', 'menus', 'editions', 'routes'].map(name => loadCatalogScript(`/resources/${name}.js`)));
  const ad = directory.querySelector('.ad-sidebar');
  const adPosition = document.createComment('advertisement');
  if (ad) {
    ad.before(adPosition);
    main.querySelector('.ad-sidebar').replaceWith(ad);
  }
  const skip = document.querySelector('.skip');
  directory.replaceWith(main);
  document.body.append(...dialogs);
  try {
    await loadCatalogScript(catalogSource);
    if (skip) skip.href = '#collection';
    if (location.hash === '#collection') document.getElementById('collection').scrollIntoView();
  } catch {
    if (ad) adPosition.replaceWith(ad);
    main.replaceWith(directory);
    for (const dialog of dialogs) dialog.remove();
  }
}

let catalogMount;
function openCatalog() {
  if (catalogMount || document.getElementById('collection')) return;
  catalogMount = mountCatalog().catch(() => {}).finally(() => { catalogMount = undefined; });
}

document.querySelector('.resource-browse')?.addEventListener('click', openCatalog);
window.addEventListener('hashchange', openCatalog);
openCatalog();
