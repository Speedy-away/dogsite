const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { chromium } = require('playwright');
const { createServer: createPreview } = require('./preview.cjs');
const { isPublic } = require('./site-layout.cjs');

async function main() {
    const bytes = await fs.readFile(path.resolve('assets/downloads/ScoobyLoader.exe'));
    const digest = value => createHash('sha256').update(value).digest('hex');
    const expectedHash = digest(bytes);
    let valid = true, available = true, fileAvailable = true, checks = 0, fileRequests = 0;
    let preview, browser;
    let origin = process.env.LOADER_TEST_ORIGIN;
    if (!origin) {
        preview = createPreview();
        await new Promise(resolve => preview.listen(0, '127.0.0.1', resolve));
        origin = `http://127.0.0.1:${preview.address().port}`;
    }
    origin = new URL(origin).origin;
    try {
        browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || 'msedge' });
        const context = await browser.newContext({ reducedMotion: 'reduce', acceptDownloads: true });
        await context.route('**/*', route => {
            const url = new URL(route.request().url());
            if (url.origin === origin) {
                if (url.pathname === '/assets/downloads/ScoobyLoader.exe') {
                    fileRequests++;
                    assert.equal(route.request().headers().authorization, undefined);
                    if (!fileAvailable) return route.fulfill({ status: 503 });
                }
                return route.continue();
            }
            if (url.hostname !== 'proudlyauthentication.com') return route.abort();
            let data = {};
            if (url.pathname.endsWith('/info')) data = { portal: { name: 'Scooby', settings: { tickets_enabled: false } } };
            if (url.pathname.endsWith('/auth/session')) {
                checks++;
                if (!available) return route.fulfill({ status: 503, json: {} });
                data = { valid, customer: valid ? { id: 42, username: 'whatwhatboy', subscription_types: [] } : null };
            }
            if (url.pathname.endsWith('/subscriptions')) data = { subscriptions: [] };
            return route.fulfill({ json: data });
        });
        await context.addInitScript(() => {
            localStorage.setItem('scooby.lang', 'en');
            localStorage.setItem('portalSessionToken', 'test-session');
        });
        const page = await context.newPage();
        page.setDefaultTimeout(15000);
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        await page.goto(origin + '/portal/#dashboard');
        await page.locator('#accountMenuToggle').waitFor({ state: 'visible' });
        await page.locator('#dashboardDownloadButton').click();
        const names = new Set();
        for (let i = 0; i < 2; i++) {
            const priorChecks = checks;
            const pending = page.waitForEvent('download');
            await page.locator('#portalLoaderDownloadButton').click();
            const download = await pending;
            assert.match(download.suggestedFilename(), /^[a-f0-9]{32}\.exe$/);
            names.add(download.suggestedFilename());
            assert.equal(digest(await fs.readFile(await download.path())), expectedHash);
            assert.ok(checks > priorChecks, 'each download must recheck sign-in');
        }
        assert.equal(names.size, 2);
        assert.equal(fileRequests, 2);
        console.log('PASS: two downloads, fresh random .exe names, original SHA-256, sign-in rechecked, no token sent to asset host');
        fileAvailable = false;
        await page.locator('#portalLoaderDownloadButton').click();
        await page.waitForFunction(() => document.getElementById('portalLoaderDownloadStatus').textContent.includes('temporarily unavailable'));
        assert.equal(await page.locator('#portalLoaderDownloadButton').isEnabled(), true);
        fileAvailable = true; available = false;
        const previousFiles = fileRequests;
        await page.locator('#portalLoaderDownloadButton').click();
        await page.waitForFunction(() => !document.getElementById('portalLoaderDownloadButton').disabled);
        assert.equal(fileRequests, previousFiles, 'auth service outages must not fetch the file');
        available = true; valid = false;
        await page.locator('#portalLoaderDownloadButton').click();
        await page.locator('#page-login').waitFor({ state: 'visible' });
        assert.equal(await page.evaluate(() => localStorage.getItem('portalSessionToken')), null);
        assert.equal(await page.locator('#dashboardDownloadDialog').evaluate(dialog => dialog.open), false);
        assert.equal(await page.locator('#dashboardDownloadButton').isDisabled(), true);
        assert.equal(fileRequests, previousFiles, 'expired sessions must not fetch the file');
        console.log('PASS: file errors and auth outages can be retried; expired sessions return to login without fetching the EXE');
        await page.goto(origin + '/download/');
        await page.locator('[data-view="guest"] .btn').waitFor({ state: 'visible' });
        assert.equal(await page.locator('[data-view="guest"] .btn').getAttribute('href'), '/portal/#login');
        valid = true;
        await page.reload();
        await page.locator('#loader-download').waitFor({ state: 'visible' });
        assert.equal(await page.locator('#loader-download').getAttribute('href'), '/portal/');
        assert.equal(fileRequests, previousFiles);
        console.log('PASS: download page directs guests to login and members to the portal without downloading a file');
        await page.setViewportSize({ width: 375, height: 812 });
        await page.goto(origin + '/portal/#dashboard');
        await page.locator('#accountMenuToggle').waitFor({ state: 'visible' });
        await page.locator('#dashboardDownloadButton').click();
        const bounds = await page.locator('#dashboardDownloadDialog').boundingBox();
        assert.ok(bounds.x >= 0 && bounds.x + bounds.width <= 375);
        await page.keyboard.press('Escape');
        assert.deepEqual(errors, []);
        assert.equal(isPublic('assets/downloads/ScoobyLoader.exe'), true);
        assert.equal(isPublic('tools/loader-download/private/ScoobyLoader.exe'), false);
        console.log('PASS: mobile dialog fits, no browser errors; file is public as requested');
    } finally {
        if (browser) await browser.close();
        if (preview) { preview.closeAllConnections(); await new Promise(resolve => preview.close(resolve)); }
    }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
