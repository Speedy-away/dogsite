/* Local browser checks. Requires Playwright and Microsoft Edge.
 * node tools/validate-search-pages.js <output-directory>
 * External requests are blocked: measurements are local transfer checks, not field scores.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '..');
const output = process.argv[2];
if (!output) throw Error('Pass an output directory for screenshots and the JSON report.');
fs.mkdirSync(output, { recursive: true });
const types = { '.html':'text/html', '.css':'text/css', '.js':'application/javascript', '.webp':'image/webp', '.png':'image/png', '.svg':'image/svg+xml', '.json':'application/json', '.woff2':'font/woff2' };
const server = http.createServer((req, res) => {
  let file = path.resolve(root, '.' + decodeURIComponent(new URL(req.url, 'http://localhost').pathname));
  if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(403); return res.end(); }
  try {
    if (fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    const body = fs.readFileSync(file);
    res.setHeader('Content-Type', types[path.extname(file)] || 'application/octet-stream');
    res.end(body);
  } catch { res.writeHead(404); res.end(); }
});
async function main() {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = 'http://127.0.0.1:' + server.address().port;
  let browser;
  const report = { measurements: [], checks: [], errors: [] };
  try {
    browser = await chromium.launch({ channel:'msedge', headless:true });
    for (const mobile of [true, false]) {
      for (const route of ['/', '/store/', '/products/gmod/', '/products/l4d/', '/products/cs2/']) {
        const context = await browser.newContext({ viewport:mobile ? { width:390, height:844 } : { width:1440, height:1000 }, deviceScaleFactor:mobile ? 2 : 1, isMobile:mobile, hasTouch:mobile, reducedMotion:'reduce' });
        await context.route('**/*', request => request.request().url().startsWith(origin) ? request.continue() : request.abort());
        const page = await context.newPage();
        const requested = [];
        page.on('request', request => requested.push(request.url()));
        page.on('pageerror', error => report.errors.push(route + ': ' + error.message));
        page.on('response', response => { if (response.url().startsWith(origin) && response.status() >= 400) report.errors.push(response.status() + ' ' + response.url()); });
        await page.addInitScript(() => {
          Math.random = () => 0.3;
          window.labLcp = 0;
          new PerformanceObserver(list => { window.labLcp = list.getEntries().at(-1).startTime; }).observe({ type:'largest-contentful-paint', buffered:true });
        });
        await page.goto(origin + route);
        await page.waitForTimeout(1500);
        if (await page.locator('.i18n-modal-overlay.show').count()) await page.locator('.i18n-modal-overlay.show button[data-lang="en"]').click();
        const first = await page.evaluate(() => ({ lcpMs:Math.round(window.labLcp), imageBytes:performance.getEntriesByType('resource').filter(x => x.initiatorType === 'img').reduce((n, x) => n + x.encodedBodySize, 0), heroImages:performance.getEntriesByType('resource').filter(x => x.name.includes('/images/hero/')).map(x => new URL(x.name).pathname) }));
        if (route === '/') {
          assert.equal(first.heroImages.length, 1, 'Only initial HTML scene loads while reduced motion pauses playback');
          assert.equal(await page.locator('#scenePause').getAttribute('aria-pressed'), 'true');
        }
        const height = await page.evaluate(() => document.body.scrollHeight);
        for (let y = 0; y < height; y += 700) { await page.evaluate(y => scrollTo(0, y), y); await page.waitForTimeout(65); }
        await page.waitForTimeout(700);
        const full = await page.evaluate(() => ({ imageBytes:performance.getEntriesByType('resource').filter(x => x.initiatorType === 'img').reduce((n, x) => n + x.encodedBodySize, 0), overflow:document.documentElement.scrollWidth > innerWidth + 2, brokenImages:[...document.images].filter(x => x.currentSrc && (!x.complete || !x.naturalWidth)).map(x => x.currentSrc) }));
        assert.equal(full.overflow, false, route + ' horizontal overflow');
        assert.deepEqual(full.brokenImages, [], route + ' unloaded images');
        report.measurements.push({ route, viewport:mobile ? 'mobile' : 'desktop', first, full });
        if (route === '/products/gmod/' || route === '/products/l4d/') {
          const preview = page.locator('.screenshot-gallery img[data-full-src]').first();
          const original = await preview.getAttribute('data-full-src');
          assert.equal(requested.some(url => new URL(url).pathname === original), false, 'Original must not load before enlargement');
          await preview.click();
          await page.locator('#lightbox.active').waitFor();
          await page.waitForFunction(source => { const img = document.getElementById('lightbox-img'); return img.getAttribute('src') === source && img.complete && img.naturalWidth === 1920; }, original);
          await page.keyboard.press('Escape');
          await page.locator('#lightbox.active').waitFor({ state:'hidden' });
        }
        if (route.startsWith('/products/')) {
          const faq = page.locator('.gmod-faq details, .product-faq details').last();
          await faq.locator('summary').click();
          assert.equal(await faq.getAttribute('open'), '');
          for (const href of await page.locator('.gmod-faq a, .product-faq a').evaluateAll(links => links.map(link => link.getAttribute('href')).filter(href => href.startsWith('/')))) {
            const file = path.join(root, href.endsWith('/') ? href + 'index.html' : href);
            assert.ok(fs.existsSync(file), 'FAQ link exists: ' + href);
          }
        }
        await page.evaluate(() => scrollTo(0, 0));
        if (route === '/products/cs2/') await page.locator('.product-faq').scrollIntoViewIfNeeded();
        await page.screenshot({ path:path.join(output, (route === '/' ? 'home' : route.split('/').filter(Boolean).at(-1)) + (mobile ? '-mobile' : '-desktop') + '.png') });
        console.log('PASS ' + (mobile ? 'mobile ' : 'desktop ') + route + ' (' + full.imageBytes + ' image bytes)');
        await context.close();
      }
    }
    const context = await browser.newContext({ viewport:{ width:1440, height:1000 }, reducedMotion:'no-preference' });
    await context.route('**/*', request => request.request().url().startsWith(origin) ? request.continue() : request.abort());
    const page = await context.newPage();
    await page.goto(origin + '/');
    await page.waitForFunction(() => document.querySelector('.hero-scene.is-active').dataset.scene !== 'gta-desert', null, { timeout:20000 });
    await page.emulateMedia({ reducedMotion:'reduce' });
    await page.waitForFunction(() => document.getElementById('scenePause').getAttribute('aria-pressed') === 'true');
    assert.equal(await page.locator('#scenePause').getAttribute('aria-pressed'), 'true');
    const pausedScene = await page.locator('.hero-scene.is-active').getAttribute('data-scene');
    await page.waitForTimeout(10500);
    assert.equal(await page.locator('.hero-scene.is-active').getAttribute('data-scene'), pausedScene, 'Pause prevents automatic transition');
    await context.close();
    assert.deepEqual(report.errors, []);
    report.checks = ['mobile and desktop layout', 'image loading', 'full-resolution lightboxes', 'FAQ disclosures and links', 'reduced motion', 'automatic slideshow and motion preference changes'];
    console.log('PASS slideshow playback and pause');
  } finally {
    fs.writeFileSync(path.join(output, 'browser-results.json'), JSON.stringify(report, null, 2));
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
