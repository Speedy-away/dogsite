const assert = require('node:assert/strict');
const fs = require('node:fs');
const { chromium } = require('playwright');
const { createServer } = require('./preview.cjs');

const SPONSOR = 'https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd';
const R6 = '/console/products/r6/';
const MANAGER = '/console/products/scooby-manager/';
const FREE = '/products/free/';

(async () => {
  const server = process.env.SPONSOR_TEST_ORIGIN ? null : createServer();
  if (server) await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = process.env.SPONSOR_TEST_ORIGIN || `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  let checks = 0;
  async function setup(options = {}) {
    const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
    await context.route('**/*', route => {
      const url = new URL(route.request().url());
      if (url.origin === origin) return route.continue();
      if (url.hostname === 'github.com' && /\.(sprx|zip|pkg)$/.test(url.pathname)) {
        return route.fulfill({ contentType: 'application/octet-stream',
          headers: { 'Content-Disposition': `attachment; filename="${url.pathname.split('/').pop()}"` },
          body: 'mock console release' });
      }
      // No real sponsored impressions or clicks during integration testing.
      return route.fulfill({ contentType: 'text/html', body: '<!doctype html><title>Mock external request</title>' });
    });
    await context.addInitScript(({ blocked, storageBlocked }) => {
      window.sponsorOpens = [];
      const open = window.open.bind(window);
      window.open = (...args) => {
        window.sponsorOpens.push(args);
        if (blocked) throw new Error('Mock blocked popup');
        return open(...args);
      };
      if (storageBlocked) {
        Object.defineProperty(window, 'sessionStorage', { get() { throw new Error('Mock denied storage'); } });
      }
    }, options);
    return { context, page: await context.newPage() };
  }
  async function download(page, locator, keyboard = false) {
    const pending = page.waitForEvent('download');
    if (keyboard) { await locator.focus(); await page.keyboard.press('Enter'); }
    else await locator.click();
    const file = await pending;
    assert.equal(fs.readFileSync(await file.path(), 'utf8'), 'mock console release');
    return file.suggestedFilename();
  }
  async function opens(page, count) {
    const calls = await page.evaluate(() => window.sponsorOpens);
    assert.equal(calls.length, count);
    for (const call of calls) assert.deepEqual(call, [SPONSOR, '_blank', 'noopener,noreferrer']);
  }
  try {
    for (const [path, filename, keyboard] of [
      [R6, 'ScoobyR6.sprx', false], [R6, 'ScoobyR6-CUSA01788-03.71.zip', false],
      [MANAGER, 'Scooby-Manager-1.0.0.pkg', true]
    ]) {
      const { context, page } = await setup();
      try {
        await page.goto(origin + path);
        await page.locator('h1').click();
        await page.locator('a[download]').first().evaluate(el => {
          el.addEventListener('click', event => event.preventDefault(), { once: true });
          el.click();
        });
        await opens(page, 0); // Synthetic clicks cannot generate ads.
        const control = page.locator(`a[data-download-sponsor][download="${filename}"]`);
        assert.equal(await download(page, control, keyboard), filename);
        await opens(page, 1);
        assert.equal(await page.locator('.free-key-sponsor-note').count(), 0);
        assert.equal(await download(page, control), filename);
        await opens(page, 1);
        await page.goto(origin + FREE);
        await page.locator('.purchase-btn.free-btn').click();
        await page.waitForFunction(() => document.getElementById('freeKeyModal').classList.contains('active'));
        await opens(page, 0); // Shared session cap survives navigation to free access.
        checks++;
      } finally { await context.close(); }
    }
    for (const options of [{ blocked: true }, { storageBlocked: true }, {}]) {
      const { context, page } = await setup(options);
      try {
        await page.goto(origin + '/download/#console');
        const links = page.locator('a[data-download-sponsor]');
        await download(page, links.first());
        await opens(page, 1);
        await download(page, links.last());
        await opens(page, 1);
        checks++;
      } finally { await context.close(); }
    }
    {
      const { context, page } = await setup();
      try {
        await page.goto(origin + FREE);
        await page.locator('.purchase-btn.free-btn').click();
        await page.waitForFunction(() => document.getElementById('freeKeyModal').classList.contains('active'));
        await opens(page, 1);
        await page.goto(origin + '/console/products/fortnite/');
        assert.equal(await page.locator('a[data-download-sponsor]').count(), 0);
        assert.equal(await page.locator('.free-key-sponsor-note').count(), 0);
        assert.equal(await page.locator('.purchase-btn[disabled]').count(), 1);
        await opens(page, 0);
        checks++;
      } finally { await context.close(); }
    }
    console.log(`Passed ${checks} browser scenarios: console downloads, keyboard access, free-key modal, shared cap, blocked popups and storage, unavailable downloads.`);
  } finally {
    await browser.close();
    if (server) {
      server.closeAllConnections();
      await new Promise(resolve => server.close(resolve));
    }
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
