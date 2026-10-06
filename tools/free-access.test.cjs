const { test } = require('node:test');
const assert = require('node:assert/strict');
const { chromium } = require('playwright');
const { createServer } = require('./preview.cjs');

test('free access: clean, network-blocked, cosmetic-blocked, retry and redirect', async () => {
    const server = createServer();
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const origin = `http://127.0.0.1:${server.address().port}`;
    let browser;
    try {
        browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) });
        const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
        let blocked = false;
        let destination;
        await page.route('**/*', route => {
            const url = route.request().url();
            if (url.startsWith(origin)) return route.continue();
            if (url.includes('whatwhatboy.com/scoobyontop.html')) {
                destination = url;
                return route.fulfill({ contentType: 'text/html', body: 'Key system' });
            }
            if (url.includes('pagead2.googlesyndication.com') && blocked) return route.abort('blockedbyclient');
            return route.fulfill({ status: 200, body: '' });
        });
        for (const path of ['/products/free/', '/freekey.html']) {
            await page.goto(origin + path);
            assert.equal(await page.evaluate(() => window.scoobyFreeAccess.check()), true);
            assert.equal(await page.locator('.free-access-dialog').isVisible(), false);
            blocked = true;
            assert.equal(await page.evaluate(() => window.scoobyFreeAccess.check()), false);
            assert.equal(await page.locator('.free-access-dialog').isVisible(), true);
            await page.keyboard.press('Escape');
            assert.equal(await page.locator('.free-access-dialog').isVisible(), true);
            assert.equal(await page.locator('.free-access-dialog').evaluate(el => el.scrollWidth <= el.clientWidth), true);
            blocked = false;
            await page.getByRole('button', { name: 'I turned it off' }).click();
            await page.waitForFunction(() => !document.querySelector('.free-access-dialog').open);
            const style = await page.addStyleTag({ content: '.adsbox { display:none !important; }' });
            assert.equal(await page.evaluate(() => window.scoobyFreeAccess.check()), false);
            assert.match(await page.locator('.free-access-status').textContent(), /still active/);
            await style.evaluate(el => el.remove());
            await page.getByRole('button', { name: 'I turned it off' }).click();
            await page.waitForFunction(() => !document.querySelector('.free-access-dialog').open);
        }
        blocked = true;
        await page.goto(origin + '/scoobyontop.html?product=cs2');
        await page.locator('.free-access-dialog').waitFor({ state: 'visible' });
        assert.equal(destination, undefined);
        blocked = false;
        await page.getByRole('button', { name: 'I turned it off' }).click();
        await page.waitForURL('https://whatwhatboy.com/scoobyontop.html?product=cs2');
        assert.equal(destination, 'https://whatwhatboy.com/scoobyontop.html?product=cs2');
    } finally {
        await browser?.close();
        await new Promise(resolve => server.close(resolve));
    }
});
