const { chromium } = require('playwright');
const { createServer } = require('./preview.cjs');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

(async () => {
  const output = path.resolve('project/build/fivem-validation');
  fs.mkdirSync(output, { recursive: true });
  const server = createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  let browser;
  const errors = [];
  try {
    browser = await chromium.launch({ channel: 'msedge', headless: true });
    for (const viewport of [{ width: 1440, height: 900 }, { width: 390, height: 844 }]) {
      const page = await browser.newPage({ viewport });
      await page.addInitScript(() => localStorage.setItem('scooby.lang', 'en'));
      page.on('pageerror', error => errors.push(error.message));
      page.on('response', response => {
        if (response.url().startsWith(base) && response.status() >= 400) errors.push(`${response.status()} ${response.url()}`);
      });
      await page.goto(base + '/products/fivem/', { waitUntil: 'domcontentloaded' });
      const language = page.locator('.i18n-modal-overlay.show button[data-lang="en"]');
      if (await language.isVisible()) await language.click();
      await page.locator('.product-intro').first().waitFor();
      await page.locator('[data-live-status]').waitFor();
      await page.locator('.i18n-modal-overlay.show').waitFor({ state: 'hidden' });
      assert.equal(await page.locator('.free-btn').getAttribute('aria-disabled'), 'true');
      assert.equal(await page.locator('[data-buy="fivem"]').getAttribute('aria-disabled'), null);
      assert.match(await page.locator('.product-intro').first().innerText(), /Players, NPCs and Self/);
      for (const img of await page.locator('.screenshot-item img').all()) {
        await img.scrollIntoViewIfNeeded();
        await img.evaluate(node => node.decode());
      }
      await page.evaluate(() => scrollTo(0, 0));
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 2), false);
      await page.screenshot({ path: path.join(output, `product-${viewport.width}.png`), fullPage: true });
      await page.getByRole('link', { name: 'View All Features', exact: true }).click();
      await page.waitForURL('**/fivem-features/');
      await page.locator('#feature-search').fill('weapon icons');
      await page.waitForFunction(() => document.querySelector('#result-count').textContent.includes('match your search'));
      assert.equal(await page.locator('.feature-item:visible').count(), 1);
      assert.match(await page.locator('.feature-item:visible').innerText(), /Free/);
      await page.locator('#clear-search').click();
      if (viewport.width < 600) await page.locator('#category-select').selectOption('scripting');
      else await page.locator('.category-nav a[data-section="scripting"]').click();
      await page.locator('#expand-all').click();
      assert.equal(await page.locator('.feature-item:visible').count(), 6);
      assert.equal(await page.locator('.feature-item:visible .feature-type').allTextContents().then(values => values.every(value => value === 'Premium')), true);
      await page.locator('#collapse-all').click();
      assert.equal(await page.locator('.feature-category[open]').count(), 0);
      await page.locator('#feature-search').fill('no-such-feature');
      await page.locator('#feature-empty').waitFor();
      await page.locator('#reset-search').click();
      await page.locator('#expand-all').click();
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 2), false);
      await page.evaluate(() => { document.activeElement.blur(); scrollTo(0, 0); });
      await page.screenshot({ path: path.join(output, `features-${viewport.width}.png`), fullPage: true });
      await page.goto(base + '/fivem-features/#subtab-0-0');
      assert.equal(await page.locator('#subtab-0-0').getAttribute('open'), '');
      await page.getByRole('link', { name: 'View product' }).click();
      await page.waitForURL('**/products/fivem/');
      await page.close();
    }
    assert.deepEqual(errors, []);
    console.log('FiveM desktop/mobile: product link, search, tiers, category filters, expand/collapse, empty/reset, legacy anchor, return link and overflow checks passed.');
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
