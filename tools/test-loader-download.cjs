const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const http = require('node:http');
const { createHash } = require('node:crypto');
const { chromium } = require('playwright');
const { createServer: createPreview } = require('./preview.cjs');
const { createServer: createDownloads } = require('./loader-download/server.cjs');
const { isPublic } = require('./site-layout.cjs');

async function main() {
    const filePath = path.resolve('tools/loader-download/private/ScoobyLoader.exe');
    const expectedHash = createHash('sha256').update(await fs.readFile(filePath)).digest('hex');
    let valid = true, available = true, checks = 0;
    const auth = http.createServer((req, res) => {
        checks++;
        if (!available) { res.writeHead(503).end('{}'); return; }
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ valid, customer: valid ? { id: 42 } : null }));
    });
    const preview = createPreview();
    await Promise.all([auth, preview].map(server => new Promise(resolve => server.listen(0, '127.0.0.1', resolve))));
    const origin = `http://127.0.0.1:${preview.address().port}`;
    const downloads = createDownloads({ filePath, sessionUrl: `http://127.0.0.1:${auth.address().port}`, allowedOrigins: [origin] });
    await new Promise(resolve => downloads.listen(0, '127.0.0.1', resolve));
    const downloadUrl = `http://127.0.0.1:${downloads.address().port}/loader`;
    let browser;
    try {
        browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || 'msedge' });
        const context = await browser.newContext({ reducedMotion: 'reduce', acceptDownloads: true });
        await context.route('**/*', route => {
            const url = new URL(route.request().url());
            if (url.origin === origin || url.origin === new URL(downloadUrl).origin) return route.continue();
            if (url.hostname !== 'proudlyauthentication.com') return route.abort();
            let data = {};
            if (url.pathname.endsWith('/info')) data = { portal: { name: 'Scooby', settings: { tickets_enabled: false } } };
            if (url.pathname.endsWith('/auth/session')) data = { valid: true, customer: { id: 42, username: 'whatwhatboy', subscription_types: [] } };
            if (url.pathname.endsWith('/subscriptions')) data = { subscriptions: [] };
            return route.fulfill({ json: data });
        });
        await context.addInitScript(() => {
            localStorage.setItem('scooby.lang', 'en');
            localStorage.setItem('portalSessionToken', 'valid-session');
        });
        const page = await context.newPage();
        page.setDefaultTimeout(10000);
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        await page.goto(origin + '/portal/#dashboard');
        await page.locator('#accountMenuToggle').waitFor({ state: 'visible' });
        await page.evaluate(url => { window.scoobyLoaderDownloadUrl = url; }, downloadUrl);
        await page.locator('#dashboardDownloadButton').click();
        const names = new Set();
        for (let i = 0; i < 2; i++) {
            const pending = page.waitForEvent('download');
            await page.locator('#portalLoaderDownloadButton').click();
            const download = await pending;
            assert.match(download.suggestedFilename(), /^[a-f0-9]{32}\.exe$/);
            names.add(download.suggestedFilename());
            const bytes = await fs.readFile(await download.path());
            assert.equal(createHash('sha256').update(bytes).digest('hex'), expectedHash);
        }
        assert.equal(names.size, 2);
        assert.equal(checks, 2);
        console.log('PASS: two real executable downloads, different random names, unchanged SHA-256, server rechecks each session');
        available = false;
        await page.locator('#portalLoaderDownloadButton').click();
        await page.waitForFunction(() => document.getElementById('portalLoaderDownloadStatus').textContent.includes('temporarily unavailable'));
        assert.equal(await page.locator('#portalLoaderDownloadButton').isEnabled(), true);
        available = true; valid = false;
        await page.locator('#portalLoaderDownloadButton').click();
        await page.locator('#page-login').waitFor({ state: 'visible' });
        assert.equal(await page.evaluate(() => localStorage.getItem('portalSessionToken')), null);
        assert.equal(await page.locator('#dashboardDownloadDialog').evaluate(dialog => dialog.open), false);
        assert.equal(await page.locator('#dashboardDownloadButton').isDisabled(), true);
        assert.deepEqual(errors, []);
        console.log('PASS: outages show a retry message; expired sessions return to login without downloading');
        for (const route of ['/tools/loader-download/private/ScoobyLoader.exe', '/assets/downloads/ScoobyLoader.exe']) {
            const response = await fetch(origin + route);
            assert.equal(response.status, 404); await response.arrayBuffer();
        }
        assert.equal(isPublic('tools/loader-download/private/ScoobyLoader.exe'), false);
        const rejected = await fetch(origin + '/api/loader/download');
        assert.equal(rejected.status, 401); await rejected.arrayBuffer();
        console.log('PASS: executable excluded from public assets and unsigned local download requests rejected');
        await page.setViewportSize({ width: 375, height: 812 });
        await page.goto(origin + '/portal/#dashboard');
        await page.reload();
        await page.locator('#accountMenuToggle').waitFor({ state: 'visible' });
        await page.locator('#dashboardDownloadButton').click();
        const bounds = await page.locator('#dashboardDownloadDialog').boundingBox();
        assert.ok(bounds.x >= 0 && bounds.x + bounds.width <= 375);
        await page.keyboard.press('Escape');
        console.log('PASS: mobile download dialog remains within the viewport');
    } finally {
        if (browser) await browser.close();
        for (const server of [preview, downloads, auth]) server.closeAllConnections();
        await Promise.all([preview, downloads, auth].map(server => new Promise(resolve => server.close(resolve))));
    }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
