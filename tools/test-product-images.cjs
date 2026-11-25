const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const { createServer } = require('./preview.cjs');
const { check } = require('./optimize-product-images.cjs');

async function main() {
    check();
    const manifest = JSON.parse(fs.readFileSync(path.resolve('assets/data/product-display-images.json'), 'utf8'));
    let server, browser, origin = process.env.PRODUCT_IMAGES_TEST_ORIGIN;
    if (!origin) {
        server = createServer();
        await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
        origin = `http://127.0.0.1:${server.address().port}`;
    }
    origin = new URL(origin).origin;
    const report = [];
    try {
        browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || 'msedge' });
        const context = await browser.newContext({ reducedMotion: 'reduce', deviceScaleFactor: 1 });
        await context.addInitScript(() => { try { localStorage.setItem('scooby.lang', 'en'); } catch (_) {} });
        await context.route('**/*', route => new URL(route.request().url()).origin === origin ? route.continue() : route.abort());
        const routes = manifest.pages.filter(page => /<img\b|<video\b/.test(fs.readFileSync(path.resolve(page), 'utf8'))).map(page => '/' + page.replace(/index\.html$/, ''));
        for (const width of [1440, 375]) {
            for (const route of routes) {
                const product = route.startsWith('/products/') ? route.split('/')[2] : route;
                const page = await context.newPage();
                await page.setViewportSize({ width, height: 1000 });
                const requests = new Set(), errors = [];
                page.on('request', request => requests.add(new URL(request.url()).pathname));
                page.on('pageerror', error => errors.push(error.message));
                await page.goto(origin + route, { waitUntil: 'load' });
                const backgrounds = page.locator('.product-backdrop img[srcset*="/assets/images/display/"]');
                if (await backgrounds.count()) {
                    await backgrounds.first().evaluate(image => image.decode());
                    assert.match(await backgrounds.first().evaluate(image => image.currentSrc), /\/assets\/images\/display\/.+\.webp$/);
                }
                const images = page.locator('img[srcset*="/assets/images/display/"]:not(.product-backdrop img)');
                if (!await images.count()) {
                    const poster = page.locator('video[data-full-poster]');
                    if (await poster.count()) assert.match(await poster.first().getAttribute('poster'), /^\/assets\/images\/display\/.+\.webp$/);
                    assert.deepEqual(errors, [], `browser errors: ${product}`);
                    report.push({ product, viewport: width, backgrounds: await backgrounds.count(), posters: await poster.count() });
                    await page.close();
                    continue;
                }
                await images.first().scrollIntoViewIfNeeded();
                await images.first().evaluate(image => image.decode());
                const image = await images.first().evaluate(image => ({
                    src: new URL(image.src).pathname,
                    current: new URL(image.currentSrc).pathname,
                    width: image.getBoundingClientRect().width,
                    naturalWidth: image.naturalWidth,
                }));
                assert.match(image.current, /^\/assets\/images\/display\/.+\.webp$/);
                const variant = manifest.images[image.src].variants.find(variant => variant.src === image.current);
                assert.ok(variant.width >= Math.min(image.width, manifest.images[image.src].width) - 1, `adequate resolution: ${product} at ${width}: ${JSON.stringify(image)}`);
                assert.ok(!requests.has(image.src), `full-size image not downloaded for the page: ${image.src}`);
                assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false);
                if (product === 'tf2') {
                    const previews = page.locator('[data-tf2-preview] img');
                    assert.equal(await previews.first().getAttribute('loading'), 'eager');
                    assert.equal(await previews.first().getAttribute('fetchpriority'), 'high');
                    assert.equal(await previews.nth(1).getAttribute('loading'), 'lazy');
                    const original = await page.locator('[data-tf2-preview]').first().getAttribute('href');
                    await page.locator('[data-tf2-preview]').first().click();
                    await page.locator('#lightbox-img').evaluate(image => image.decode());
                    assert.equal(await page.locator('#lightbox-img').evaluate(image => new URL(image.src).pathname), original);
                    assert.ok(requests.has(original));
                    await page.keyboard.press('Escape');
                    assert.equal(await page.locator('#lightbox').isVisible(), false);
                }
                assert.deepEqual(errors, [], `browser errors: ${product}`);
                report.push({ product, viewport: width, originalBytes: manifest.images[image.src].bytes, displayBytes: variant.bytes, displayWidth: variant.width });
                await page.close();
            }
        }
        console.log(JSON.stringify({ routes: routes.length, viewportChecks: report.length, consoleRoutes: routes.filter(route => route.startsWith('/console/')).length }));
        console.log('PASS: every product/catalogue route on desktop/mobile, responsive images and backgrounds, optimized posters, original TF2 lightbox and keyboard dismissal');
    } finally {
        if (browser) await browser.close();
        if (server) { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
    }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
