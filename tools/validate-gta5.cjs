const assert = require('node:assert/strict');
const fs = require('node:fs');
const {chromium} = require('playwright');
const {createServer} = require('./preview.cjs');
const manifest = require('./features/features-gta5.json');
const items = manifest.tabs.flatMap(t => t.categories.flatMap(c => c.groups.flatMap(g => g.items)));
(async () => {
  const server = createServer();
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  const origin = 'http://127.0.0.1:'+server.address().port;
  let browser;
  fs.mkdirSync('build/gta5-site',{recursive:true});
  try {
    browser = await chromium.launch({headless:true,channel:'msedge'});
    for (const width of [1440,760,390,320]) {
      const page = await browser.newPage({viewport:{width,height:960}});
      await page.addInitScript(() => { try { localStorage.setItem('scooby.lang','en'); } catch (_) {} });
      // Keep verification deterministic and avoid external analytics, video and font requests.
      await page.route('**/*', route => route.request().url().startsWith(origin) ? route.continue() : route.abort());
      const errors = [];
      page.on('pageerror',error => errors.push(error.message));
      await page.goto(origin+'/products/gta5/');
      const english = page.getByText('Continue in English',{exact:true});
      if (await english.isVisible()) await english.click();
      assert.equal(await page.locator('.gta-comparison thead th').count(),4);
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth+1));
      const checkComparisonFit = async () => {
        if (width > 760) return;
        assert.ok(await page.locator('.gta-table-scroll').evaluate(el => el.scrollWidth <= el.clientWidth + 1), `Comparison must fit at ${width}px`);
        for (const cell of await page.locator('.gta-comparison thead th:not(:first-child), .gta-comparison tfoot a').all()) {
          const bounds = await cell.boundingBox();
          assert.ok(bounds.x >= 0 && bounds.x + bounds.width <= width + 1, `Every plan and button must fit at ${width}px`);
        }
      };
      await checkComparisonFit();
      await page.locator('#compare-editions').scrollIntoViewIfNeeded();
      const screenshotStyle = await page.addStyleTag({content:'#product-nav, .skip-link { visibility: hidden !important; }'});
      await page.locator('#compare-editions').screenshot({path:`build/gta5-site/comparison-${width}.png`});
      await screenshotStyle.evaluate(el => el.remove());
      await page.locator('[data-gta-plan="premium-plus"]').click();
      assert.ok(await page.locator('#paymentModal').evaluate(el => el.classList.contains('active')));
      assert.match(await page.locator('#cardPaymentLink').getAttribute('href'), /scooby-premium-plus-gta/);
      await page.keyboard.press('Escape');
      await page.locator('[data-gta-plan="upgrade"]').click();
      assert.ok(await page.locator('#paymentModal').evaluate(el => el.classList.contains('active')));
      assert.match(await page.locator('#cardPaymentLink').getAttribute('href'), /upgrade-from-premium-to-premium-plus/);
      await page.keyboard.press('Escape');
      await page.getByRole('link',{name:'View all features',exact:true}).click();
      await page.waitForFunction(() => document.querySelector('#access-select'));
      await page.locator('.library-plan-details').evaluate(el => el.open = true);
      await checkComparisonFit();
      assert.equal(await page.locator('.feature-item').count(),items.length);
      await page.locator('.library-plan-details').evaluate(el => el.open = false);
      await page.locator('#explorer').scrollIntoViewIfNeeded();
      await page.screenshot({path:`build/gta5-site/library-overview-${width}.png`});
      if (await page.locator('#category-select').isVisible()) await page.selectOption('#category-select','weapons'); else await page.locator('.category-nav a[data-section=weapons]').click();
      assert.ok(await page.locator('.feature-section:not([hidden])').count() === 1);
      const subcategory = await page.locator('#subcategory-select option').nth(1).getAttribute('value');
      await page.selectOption('#subcategory-select', subcategory);
      assert.equal(await page.locator('.feature-category:not([hidden])').count(),1);
      await page.locator('#expand-all').click();
      assert.ok(await page.locator('.feature-subtab:not([hidden])[open]').count() > 0);
      await page.locator('#collapse-all').click();
      assert.equal(await page.locator('.feature-subtab[open]').count(),0);
      await page.reload();
      assert.equal(await page.locator('#subcategory-select').inputValue(),subcategory);
      if (await page.locator('#category-select').isVisible()) await page.selectOption('#category-select','all'); else await page.locator('.category-nav a[data-section=all]').click();
      await page.selectOption('#access-select','free');
      assert.equal(await page.locator('.feature-item:not([hidden])').count(),items.filter(i=>i.access==='free').length);
      assert.ok(page.url().includes('plan=free'));
      await page.selectOption('#access-select','paid');
      assert.equal(await page.locator('.feature-item:not([hidden])').count(),items.filter(i=>i.access==='premium').length);
      await page.locator('#feature-search').fill('black hole');
      await page.waitForTimeout(250);
      assert.ok(await page.locator('.feature-item:not([hidden])').count() > 0);
      assert.equal(await page.locator('.feature-item[data-access="free"]:not([hidden])').count(),0);
      await page.locator('#explorer').scrollIntoViewIfNeeded();
      await page.screenshot({path:`build/gta5-site/features-${width}.png`});
      await page.selectOption('#access-select','free');
      await page.locator('#feature-search').fill('no-such-feature-qa');
      await page.waitForTimeout(250);
      assert.ok(await page.locator('#feature-empty').isVisible());
      await page.locator('#reset-search').click();
      assert.equal(await page.locator('.feature-item:not([hidden])').count(),items.length);
      for (const tier of ['premium','plus']) {
        await page.selectOption('#access-select',tier);
        assert.equal(await page.locator('.feature-item:not([hidden])').count(),items.length);
      }
      await page.reload();
      assert.equal(await page.locator('#access-select').inputValue(),'plus');
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth+1));
      assert.deepEqual(errors,[]);
      await page.locator('.library-plan-details').evaluate(el => el.open = true);
      await page.locator('[data-gta-plan="upgrade"]').click();
      await page.waitForURL('**/products/gta5/?plan=upgrade');
      assert.ok(await page.locator('#paymentModal').evaluate(el => el.classList.contains('active')));
      assert.match(await page.locator('#cardPaymentLink').getAttribute('href'), /upgrade-from-premium-to-premium-plus/);
      await page.close();
    }
    console.log('PASS: desktop/mobile comparison, checkout routes, search, tier filtering, reset, URL persistence, overflow and JavaScript errors');
  } finally {
    await browser?.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
