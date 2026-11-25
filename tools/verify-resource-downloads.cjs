'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { chromium } = require('playwright');
const { createServer } = require('./preview.cjs');
const root = path.resolve(__dirname, '..');
const sovereign = require('../community/data/menu-resources.json').items.find(item => item.id === 'cherax-lua-sovereign');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

(async () => {
  const server = createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  let browser;
  try {
    browser = await chromium.launch({ channel: 'msedge', headless: true });
    const context = await browser.newContext({ acceptDownloads: true });
    let failDownload = false;
    let failMenuBundle = false, failPackedBundles = false;
    const catalogRequests = [];
    await context.route('**/*', async route => {
      const url = new URL(route.request().url());
      if (/^\/community\/data\/games\/[a-z0-9-]+\.json(?:\.gz)?$/.test(url.pathname)) {
        catalogRequests.push(url.pathname);
        if (failMenuBundle && url.pathname === '/community/data/games/gta5-cherax.json.gz' ||
            failPackedBundles && url.pathname.endsWith('.gz')) return route.fulfill({ status: 404, body: 'Unavailable bundle' });
      }
      const raw = url.origin === 'https://raw.githubusercontent.com' && url.pathname.startsWith('/Speedy-away/dogsite/main/assets/');
      const download = raw ? url.pathname.slice('/Speedy-away/dogsite/main'.length) : url.pathname;
      if (download.startsWith('/assets/downloads/cherax/')) {
        if (failDownload) return route.fulfill({ status: 503, body: 'Unavailable' });
        const file = path.join(root, download);
        return route.fulfill({ contentType: 'application/octet-stream', headers: { 'Access-Control-Allow-Origin': '*' }, body: fs.readFileSync(file) });
      }
      if (raw) return route.fulfill({ body: fs.readFileSync(path.join(root, download)) });
      if (url.origin === base) return route.continue();
      return route.abort();
    });
    const siteTabs = () => context.pages().filter(tab => tab.url() !== 'edge://downloads-hub/');
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.addInitScript(() => {
      window.downloadOrder = [];
      const click = HTMLAnchorElement.prototype.click, open = window.open;
      HTMLAnchorElement.prototype.click = function () {
        if (this.hasAttribute('download')) window.downloadOrder.push('file');
        return click.call(this);
      };
      window.open = function (...args) {
        window.downloadOrder.push('ad');
        return open.apply(this, args);
      };
    });
    await page.goto(base + '/resources/gta5/cherax/lua/?q=Sovereign');
    await page.locator('#grid .card').waitFor();
    assert(catalogRequests.includes('/community/data/games/gta5-cherax.json.gz'), 'Cherax must use its smaller menu bundle');
    assert(!catalogRequests.includes('/community/data/games/gta5.json.gz'), 'The complete catalog should not load on the normal path');
    assert.equal(await page.locator('#grid .card').count(), 1, 'Sovereign must appear once');
    const button = page.locator('#grid [data-resource-download]');
    async function transfer(file) {
      const originalURL = page.url();
      const [download] = await Promise.all([page.waitForEvent('download'), button.click()]);
      assert.equal(download.suggestedFilename(), file.name);
      assert.equal(hash(fs.readFileSync(await download.path())), file.sha256, 'Saved bytes must match the selected file');
      await button.getByText('Download started', { exact: true }).waitFor();
      assert.equal(page.url(), originalURL, 'Downloading stays on the resource card');
      assert.equal(siteTabs().length, 1, 'Downloads must stay in the original tab');
    }
    await transfer(sovereign.files[0]);
    assert.deepEqual(await page.evaluate(() => window.downloadOrder), ['file']);
    await page.locator('#grid .version-download select').selectOption('1');
    await transfer(sovereign.files[1]);
    assert.deepEqual(await page.evaluate(() => window.downloadOrder), ['file', 'file']);

    failDownload = true;
    await button.click();
    await button.getByText('Retry download', { exact: true }).waitFor();
    assert.equal(await page.locator('#grid .download-error').count(), 1);
    assert.deepEqual(await page.evaluate(() => window.downloadOrder), ['file', 'file']);
    failDownload = false;
    await transfer(sovereign.files[1]);
    assert.equal(await page.locator('#grid .download-error').count(), 0);

    await page.goto(base + '/resources/gta5/cherax/lua/#resource-cherax-lua-thread-1561386308000026736');
    await page.locator('#preview[open]').waitFor();
    assert.match(await page.locator('#preview').innerText(), /Sovereign/);

    // Exercise the real static-page handler with catalog enhancement unavailable.
    await page.route(base + '/resources/', route => route.fulfill({ status: 503, body: 'Offline catalog' }));
    await page.goto(base + '/resources/gta5/cherax/lua/');
    const staticButton = page.locator('button[data-download-file]:visible').first();
    await staticButton.waitFor();
    const staticFile = JSON.parse(await staticButton.getAttribute('data-download-file'));
    const [staticDownload] = await Promise.all([page.waitForEvent('download'), staticButton.click()]);
    assert.equal(staticDownload.suggestedFilename(), staticFile.name);
    assert.equal(fs.statSync(await staticDownload.path()).size, staticFile.size);
    assert.deepEqual(await page.evaluate(() => window.downloadOrder), ['file']);
    assert.equal(siteTabs().length, 1, 'Static downloads must stay in the original tab');

    await page.unroute(base + '/resources/');
    failMenuBundle = true;
    catalogRequests.length = 0;
    await page.goto(base + '/resources/gta5/cherax/lua/?q=Sovereign');
    await page.locator('#grid .card').waitFor();
    assert.equal(await page.locator('#grid .card').count(), 1);
    assert(catalogRequests.includes('/community/data/games/gta5.json.gz'), 'Missing menu data must fall back to the full compressed catalog');
    failPackedBundles = true;
    catalogRequests.length = 0;
    await page.reload();
    await page.locator('#grid .card').waitFor();
    assert.equal(await page.locator('#grid .card').count(), 1);
    assert(catalogRequests.includes('/community/data/games/gta5.json'), 'Missing compressed data must fall back to the plain catalog');
    failMenuBundle = false;
    failPackedBundles = false;
    for (const [game, menu, collection] of [
      ['rdr2', 'scooby', '/resources/rdr2/'], ['rdr2', 'nenyoo', '/resources/rdr2/nenyoo/'],
      ['cs2', 'scooby', '/resources/cs2/'], ['fivem', 'scooby', '/resources/fivem/'],
      ['redm', 'scooby', '/resources/redm/'], ['l4d', 'scooby', '/resources/l4d/']
    ]) {
      catalogRequests.length = 0;
      await page.goto(base + collection);
      await page.locator('#grid[aria-busy="false"]').waitFor();
      assert(await page.locator('#grid .card').count() > 0, `${game}/${menu}: resources must load`);
      const expected = `/community/data/games/${game}${game === 'rdr2' ? '-' + menu : ''}.json.gz`;
      assert(catalogRequests.includes(expected), `${game}/${menu}: use its compressed catalog`);
      assert(!catalogRequests.some(url => url.includes('/gta5')), `${game}/${menu}: do not fetch GTA 5 data`);
    }
    assert.equal(errors.length, 0, errors.join('\n'));
    console.log('PASS: compressed catalogs across all six games, compressed/plain fallbacks, direct downloads without popups, retries, old bookmarks, and static-page downloads.');
    await context.close();
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
