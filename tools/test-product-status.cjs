const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 1365, height: 900 } });
  await page.addInitScript(() => localStorage.setItem('scooby.lang', 'en'));
  let feed = JSON.parse(fs.readFileSync(path.join(root, 'assets/data/product-status.json'), 'utf8'));
  feed.products.l4d = { state: 'disabled', message: 'L4D is being updated. Please check back later.' };
  let checks = 0;
  await page.route('**/*', async route => {
    const url = new URL(route.request().url());
    if (url.hostname === 'raw.githubusercontent.com' && url.pathname.endsWith('/product-status.json')) return route.fulfill({ json: feed });
    if (url.hostname !== 'scooby.test') return route.abort();
    let file = path.resolve(root, '.' + decodeURIComponent(url.pathname));
    if (file !== root && !file.startsWith(root + path.sep)) return route.abort();
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    if (!fs.existsSync(file)) return route.fulfill({ status: 404, body: '' });
    const types = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css', '.json': 'application/json', '.webp': 'image/webp', '.png': 'image/png', '.svg': 'image/svg+xml' };
    return route.fulfill({ body: fs.readFileSync(file), contentType: types[path.extname(file)] || 'application/octet-stream' });
  });
  async function refresh(state) {
    if (state) feed.products.l4d.state = state;
    await page.evaluate(() => document.dispatchEvent(new Event('visibilitychange')));
  }
  try {
    await page.goto('https://scooby.test/products/l4d/');
    await page.waitForFunction(() => document.querySelector('[data-live-status]')?.textContent === 'Disabled'); checks++;
    assert.match(await page.locator('.product-heading-badges').innerText(), /Free Product/); checks++;
    assert.equal(await page.locator('.purchase-btn[href^="/guides/"]').getAttribute('data-status-blocked'), null); checks++;
    assert.equal(await page.locator('.purchase-btn[href^="/features-list/"]').getAttribute('data-status-blocked'), null); checks++;
    const action = page.locator('.purchase-btn').first();
    assert.equal(await action.getAttribute('aria-disabled'), 'true'); checks++;
    await page.evaluate(() => { window.statusClickCount = 0; document.querySelector('.purchase-btn').addEventListener('click', () => window.statusClickCount++); document.querySelector('.purchase-btn').click(); });
    assert.equal(await page.evaluate(() => window.statusClickCount), 0); checks++;
    fs.mkdirSync(path.join(root, 'project/build/product-status'), { recursive: true });
    await page.waitForTimeout(400);
    assert.equal(await page.locator('[data-status-message]').isVisible(), true); checks++;
    await page.screenshot({ path: path.join(root, 'project/build/product-status/l4d-disabled.png') });
    for (const state of ['offline', 'updating', 'online']) {
      await refresh(state);
      await page.waitForFunction(state => document.querySelector('[data-live-status]')?.dataset.availability === state, state);
      assert.equal(await action.getAttribute('data-status-blocked'), state === 'online' ? null : 'true'); checks++;
    }
    // Preserve account-owned disabled state when availability recovers.
    await action.evaluate(el => el.setAttribute('aria-disabled', 'true'));
    await refresh('disabled'); await page.waitForFunction(() => document.querySelector('.purchase-btn').dataset.statusBlocked === 'true');
    const good = feed; feed = { schema: 1, products: { l4d: { state: 'invalid' } } };
    await refresh(); await page.waitForTimeout(150);
    assert.equal(await action.getAttribute('data-status-blocked'), 'true'); checks++;
    feed = good; await refresh('online'); await page.waitForFunction(() => !document.querySelector('.purchase-btn').dataset.statusBlocked);
    assert.equal(await action.getAttribute('aria-disabled'), 'true'); checks++;
    feed.products.l4d.state = 'disabled';
    await page.goto('https://scooby.test/store/');
    await page.waitForFunction(() => document.querySelector('[data-product="l4d"] [data-availability]')?.textContent === 'Disabled'); checks++;
    assert.equal(await page.locator('[data-product="l4d"] [data-free]').getAttribute('data-status-blocked'), 'true'); checks++;
    // Updating FiveM still sells licenses on both purchase surfaces.
    feed.products.fivem.state = 'updating';
    for (const surface of [
      { url: '/store/', badge: '[data-product="fivem"] [data-availability]', free: '[data-product="fivem"] [data-free]', modal: '#payment-dialog', link: '#card-payment-link' },
      { url: '/products/fivem/', badge: '[data-live-status]', free: '.free-btn', modal: '#paymentModal', link: '#cardPaymentLink' }
    ]) {
      await page.goto('https://scooby.test' + surface.url);
      await page.waitForFunction(selector => document.querySelector(selector)?.textContent === 'Updating', surface.badge);
      const buy = page.locator('[data-buy="fivem"]');
      assert.equal(await buy.getAttribute('data-status-blocked'), null); checks++;
      assert.equal(await page.locator(surface.free).getAttribute('data-status-blocked'), 'true'); checks++;
      await buy.click();
      assert.equal(await page.locator(surface.modal).isVisible(), true); checks++;
      assert.match(await page.locator(surface.link).getAttribute('href'), /\/products\/scooby-fivem$/); checks++;
      if (surface.url === '/store/') await page.locator(surface.modal).evaluate(el => el.close());
      else await page.evaluate(() => closePaymentModal());
      for (const state of ['offline', 'disabled', 'updating']) {
        feed.products.fivem.state = state;
        await refresh();
        await page.waitForFunction(({ selector, state }) => document.querySelector(selector)?.dataset.availability === state, { selector: surface.badge, state });
        assert.equal(await buy.getAttribute('data-status-blocked'), state === 'updating' ? null : 'true'); checks++;
      }
      feed.products.loader.state = 'updating';
      await refresh();
      await page.waitForFunction(() => document.querySelector('[data-buy="fivem"]').dataset.statusBlocked === 'true'); checks++;
      feed.products.loader.state = 'online';
      await refresh();
      await page.waitForFunction(() => !document.querySelector('[data-buy="fivem"]').dataset.statusBlocked); checks++;
    }
    await page.goto('https://scooby.test/');
    await page.waitForFunction(() => [...document.querySelectorAll('.catalog-card')].some(el => el.getAttribute('href') === '/products/l4d/' && el.querySelector('[data-availability]')?.textContent === 'Disabled')); checks++;
    feed.products['tf2-classified'].state = 'disabled';
    await page.goto('https://scooby.test/products/tf2/');
    await page.waitForFunction(() => document.querySelector('[data-status-message]')?.textContent.includes('TF2 Classified: Disabled')); checks++;
    feed.products.loader.state = 'updating';
    await page.goto('https://scooby.test/download/');
    await page.waitForFunction(() => document.querySelector('#loader-download')?.dataset.statusBlocked === 'true'); checks++;
    console.log(`PASS: ${checks} website status checks; screenshots in build/product-status.`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
