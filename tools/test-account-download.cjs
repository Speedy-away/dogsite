/* Isolated portal browser checks; credentials and account responses are synthetic. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const site = process.env.SCOOBY_PORTAL_ROOT || path.resolve(__dirname, '..');
const staged = process.env.SCOOBY_PORTAL_STAGE;
const { chromium } = require(path.join(site, 'node_modules/playwright'));
const server = http.createServer((req, res) => {
    const relative = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    let file = path.resolve(site, '.' + relative);
    if (!file.startsWith(path.resolve(site) + path.sep)) return res.writeHead(403).end();
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    if (staged && /\/portal\/(index\.html|account-download\.(?:js|css))$/.test(file.replaceAll('\\', '/'))) {
        file = path.join(staged, path.basename(file));
    }
    if (!fs.existsSync(file)) return res.writeHead(404).end();
    const type = { '.js': 'text/javascript', '.css': 'text/css', '.html': 'text/html' }[path.extname(file)] || 'application/octet-stream';
    res.setHeader('Content-Type', type + (type.startsWith('text/') ? '; charset=utf-8' : ''));
    fs.createReadStream(file).pipe(res);
});
async function main() {
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const origin = `http://127.0.0.1:${server.address().port}`;
    const browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) });
    const errors = [], outbound = [];
    try {
        const context = await browser.newContext({ viewport: { width: 1440, height: 1100 }, acceptDownloads: true });
        await context.route('**/*', route => {
            const request = route.request();
            outbound.push(request.url() + (request.postData() || ''));
            const url = new URL(request.url());
            if (url.origin === origin) return route.continue();
            if (url.hostname !== 'proudlyauthentication.com') return route.abort();
            const customer = { id: 42, username: 'Portal fixture', subscription_types: [] };
            let data = {};
            if (url.pathname.endsWith('/info')) data = { portal: { name: 'Scooby', settings: {} } };
            if (url.pathname.endsWith('/auth/session')) data = { valid: true, customer };
            if (url.pathname.endsWith('/subscriptions')) data = { subscriptions: [] };
            return route.fulfill({ json: data });
        });
        await context.addInitScript(() => {
            localStorage.setItem('scooby.lang', 'en');
            localStorage.setItem('portalSessionToken', 'synthetic-session');
            window.accountBlobUrls = { created: 0, released: 0 };
            const create = URL.createObjectURL.bind(URL), release = URL.revokeObjectURL.bind(URL);
            URL.createObjectURL = blob => { ++window.accountBlobUrls.created; return create(blob); };
            URL.revokeObjectURL = url => { ++window.accountBlobUrls.released; release(url); };
        });
        const page = await context.newPage();
        page.on('pageerror', error => errors.push(error.message));
        await page.goto(origin + '/portal/#dashboard');
        const form = page.locator('#consoleAccountForm');
        await form.waitFor({ state: 'visible' });
        const user = page.locator('#consoleAccountUsername'), pass = page.locator('#consoleAccountPassword');
        const button = page.locator('#consoleAccountDownload');
        await button.waitFor({ state: 'visible' });
        assert.equal(await button.isEnabled(), true);
        assert.equal(await pass.getAttribute('type'), 'password');
        assert.match(await page.locator('#consoleAccountNote').textContent(), /Console \/ PS4 only.*not needed for PC/);
        assert.equal(await form.locator('[name]').count(), 0);
        assert.equal(await page.evaluate(() => document.querySelector('#dashboardRedeemForm').compareDocumentPosition(document.querySelector('#consoleAccountForm')) & Node.DOCUMENT_POSITION_FOLLOWING), 4);
        await button.click();
        assert.equal(await page.evaluate(() => window.accountBlobUrls.created), 0);
        const username = 'console_fixture_العربية';
        const password = ' fake_"quote"\\slash_秘密_🔑 ';
        await user.fill('  ' + username + '  ');
        await pass.fill(password);
        const pending = page.waitForEvent('download');
        await button.click();
        const download = await pending;
        assert.equal(download.suggestedFilename(), 'account.json');
        const payload = fs.readFileSync(await download.path(), 'utf8');
        assert.deepEqual(JSON.parse(payload), { username, password });
        assert.equal(await pass.inputValue(), '');
        assert.match(await page.locator('#consoleAccountStatus').textContent(), /Download started/);
        await page.waitForFunction(() => window.accountBlobUrls.released === 1);
        assert.equal(await page.locator('a[download="account.json"]').count(), 0);
        // Browser validation must not accept whitespace-only credentials or oversized UTF-8.
        await user.fill('   '); await pass.fill('   '); await button.click();
        assert.equal(await user.evaluate(input => input.validity.valid), false);
        assert.equal(await page.evaluate(() => window.accountBlobUrls.created), 1);
        await user.fill('界'.repeat(44)); await pass.fill('valid'); await button.click();
        assert.equal(await user.evaluate(input => input.validity.valid), false);
        await user.fill(username); await pass.fill('界'.repeat(86)); await button.click();
        assert.equal(await pass.evaluate(input => input.validity.valid), false);
        // A browser download failure must clear the password and leave retry available.
        await pass.fill(password);
        await page.evaluate(() => { window.realCreate = URL.createObjectURL; URL.createObjectURL = () => { throw new Error('synthetic failure'); }; });
        await button.click();
        assert.equal(await pass.inputValue(), '');
        assert.equal(await page.locator('#consoleAccountStatus').getAttribute('data-tone'), 'error');
        await page.evaluate(() => { URL.createObjectURL = window.realCreate; delete window.realCreate; });
        await pass.fill(password);
        const retry = page.waitForEvent('download'); await pass.press('Enter'); await retry;
        assert.equal(await pass.inputValue(), '');
        // No credentials in either storage, URLs or any request body.
        const storage = await page.evaluate(() => JSON.stringify([Object.entries(localStorage), Object.entries(sessionStorage)]));
        for (const secret of [username, password]) {
            assert.equal(storage.includes(secret), false);
            assert.equal(outbound.some(value => value.includes(secret) || value.includes(encodeURIComponent(secret))), false);
        }
        for (const width of [1440, 390, 320]) {
            await page.setViewportSize({ width, height: 1100 });
            await button.scrollIntoViewIfNeeded();
            const bounds = await form.boundingBox();
            assert.ok(bounds.x >= 0 && bounds.x + bounds.width <= width + 1, `form fits ${width}px`);
        }
        await page.setViewportSize({ width: 1440, height: 1100 });
        if (process.env.SCOOBY_PORTAL_SCREENSHOT) await page.locator('[aria-labelledby="dashboardRedeemHeading"]').screenshot({ path: process.env.SCOOBY_PORTAL_SCREENSHOT });
        await pass.fill(password);
        await page.evaluate(() => window.dispatchEvent(new PageTransitionEvent('pagehide')));
        assert.equal(await pass.inputValue(), '');
        await user.fill(username); await pass.fill(password);
        await page.evaluate(() => document.querySelector('#page-dashboard').classList.remove('active'));
        await page.waitForFunction(() => !document.querySelector('#consoleAccountPassword').value);
        assert.equal(await user.inputValue(), '');
        assert.deepEqual(errors, []);
        await context.close();
        console.log('PASS: account.json download, exact Unicode/escaped credentials, validation, retry/Enter, no credential requests/storage, cleanup, desktop/mobile bounds.');
    } finally { await browser.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => server.close());
