/* node tools/test-portal-i18n.js — isolated browser checks, no live account calls. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const vm = require('node:vm');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '..');
const sandbox = { window: {} };
vm.runInNewContext(fs.readFileSync(path.join(root, 'portal/portal-translations.js'), 'utf8'), sandbox);
const tables = sandbox.window.__scoobyPortalTranslations;
assert.equal(Object.keys(tables).length, 21);
for (const [code, table] of Object.entries(tables)) {
  for (const [key, value] of Object.entries(table)) {
    assert.ok(value.trim(), `${code}: ${key}`);
    assert.deepEqual(value.match(/\{\w+\}/g) || [], key.match(/\{\w+\}/g) || [], `${code}: placeholders in ${key}`);
  }
}
const server = http.createServer((req, res) => {
  let file = path.resolve(root, '.' + decodeURIComponent(new URL(req.url, 'http://localhost').pathname));
  if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  if (!fs.existsSync(file)) { res.writeHead(404).end(); return; }
  const type = { '.js':'text/javascript', '.html':'text/html', '.css':'text/css', '.png':'image/png' }[path.extname(file)] || 'application/octet-stream';
  res.setHeader('Content-Type', type + (type.startsWith('text/') ? '; charset=utf-8' : ''));
  fs.createReadStream(file).pipe(res);
});
async function main() {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHANNEL ? { channel:process.env.PLAYWRIGHT_CHANNEL } : {}) });
  try {
    const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
    const user = { id: 42, username: 'Active', display_name: 'Active', subscription_types: ['demo'],
      subscription_grants: [{ public_id:'demo', status:'active', expires_at:'2030-12-20T00:00:00Z' }],
      hwid_policy: { enabled:true }, hwid_state: { can_reset:true, manual_reset_count:2 } };
    let cooldown = false, offline = false;
    const writes = [];
    await context.route('**/*', route => {
      const url = new URL(route.request().url());
      if (url.origin === origin) return route.continue();
      if (url.hostname !== 'proudlyauthentication.com') return route.abort();
      let data = {};
      if (url.pathname.endsWith('/info')) data = { portal:{ name:'Scooby', settings:{ tickets_enabled:true } } };
      if (url.pathname.endsWith('/auth/session')) {
        if (offline) return route.fulfill({ status:503, json:{} });
        data = { valid:true, customer:{ ...user, hwid_state:cooldown ? { status:'cooldown', can_reset:false, cooldown_remaining_seconds:120 } : user.hwid_state } };
      }
      if (url.pathname.endsWith('/subscriptions')) data = { subscriptions:[{ public_id:'demo', name:'Active', display_name:'Active' }] };
      if (route.request().method() === 'POST') writes.push(url.pathname);
      return route.fulfill({ json:data });
    });
    await context.addInitScript(() => {
      if (!localStorage.getItem('scooby.lang')) localStorage.setItem('scooby.lang','en');
      localStorage.setItem('portalSessionToken','test-only');
    });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(origin + '/portal/#dashboard');
    await page.locator('.dashboard-product-name').waitFor();
    async function language(code) {
      await page.evaluate(code => window.__scoobyI18n.set(code), code);
      await page.waitForFunction(code => document.documentElement.lang === code, code);
    }
    for (const [code, table] of Object.entries(tables)) {
      await language(code);
      assert.equal((await page.locator('#dashboardRedeemHeading').textContent()).trim(), table['Redeem license key']);
      assert.equal(await page.locator('#dashboardTitle').textContent(), table['Welcome, {name}!'].replace('{name}', 'Active'));
      assert.equal(await page.locator('#dashboardLicenseKey').getAttribute('placeholder'), table['Enter your license key']);
      assert.equal(await page.locator('.dashboard-product-name').textContent(), 'Active');
      assert.equal(await page.locator('#headerUsername').textContent(), 'Active');
      assert.equal(await page.locator('#dashboardHwidStatus').textContent(), table['Ready to reset']);
      assert.equal(await page.locator('.i18n-toggle').getAttribute('aria-label'), table['Change language']);
      assert.ok((await page.locator('.dashboard-product-meta').textContent()).startsWith(table['Expires: {date}'].split('{date}')[0]));
      assert.equal(await page.locator('html').getAttribute('dir'), ['ar','he'].includes(code) ? 'rtl' : 'ltr');
    }
    await language('es');
    await page.reload();
    await page.locator('.dashboard-product-name').waitFor();
    assert.equal(await page.locator('html').getAttribute('lang'), 'es');
    assert.equal(await page.title(), tables.es['Scooby Dashboard']);
    // Existing text nodes and attributes can be updated by portal scripts.
    await page.evaluate(() => {
      const el = document.createElement('p'); el.id = 'liveTranslation'; el.textContent = 'Active'; document.body.append(el);
    });
    await page.waitForFunction(() => document.querySelector('#liveTranslation').textContent === 'Activo');
    await page.evaluate(() => document.querySelector('#liveTranslation').firstChild.nodeValue = 'Expired');
    await page.waitForFunction(() => document.querySelector('#liveTranslation').textContent === 'Caducado');
    await language('en');
    assert.equal(await page.locator('#liveTranslation').textContent(), 'Expired');
    await page.evaluate(() => document.querySelector('#liveTranslation').remove());
    await page.locator('.i18n-toggle').focus();
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('End');
    assert.equal(await page.locator(':focus').getAttribute('data-lang'), 'he');
    await page.keyboard.press('Home');
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => document.documentElement.lang === 'es');
    assert.equal(await page.locator(':focus').getAttribute('class'), 'i18n-toggle');
    for (const width of [375, 768, 1440]) {
      await page.setViewportSize({ width, height:800 });
      await page.locator('.i18n-toggle').click();
      const box = await page.locator('.i18n-menu').boundingBox();
      assert.ok(box.x >= 0 && box.x + box.width <= width + 1 && box.y + box.height <= 800, `menu fits ${width}`);
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `page fits ${width}`);
      assert.equal(await page.locator('.i18n-option').count(), 22);
      if (process.env.PORTAL_SCREENSHOTS) {
        fs.mkdirSync(process.env.PORTAL_SCREENSHOTS, { recursive:true });
        await page.screenshot({ path:path.join(process.env.PORTAL_SCREENSHOTS, `portal-es-${width}.png`) });
      }
      await page.keyboard.press('Escape');
      assert.equal(await page.locator('.i18n-toggle').getAttribute('aria-expanded'), 'false');
    }
    await page.locator('#dashboardDownloadButton').click();
    assert.equal(await page.locator('#dashboardDownloadTitle').textContent(), tables.es['Download loader']);
    await page.keyboard.press('Escape');
    await page.locator('#dashboardLicenseKey').fill('DEMO-TEST');
    await page.locator('#dashboardRedeemButton').click();
    await page.waitForFunction(() => document.querySelector('#dashboardRedeemMessage').textContent === 'Licencia canjeada correctamente.');
    assert.equal(writes.filter(url => url.endsWith('/auth/redeem-key')).length, 1);
    cooldown = true;
    await page.reload();
    await page.waitForFunction(() => document.querySelector('#dashboardHwidStatus').textContent.startsWith('Disponible en'));
    await language('fr');
    await page.waitForFunction(() => document.querySelector('#dashboardHwidStatus').textContent.startsWith('Disponible dans'));
    await language('ar');
    await page.setViewportSize({ width:375, height:800 });
    await page.locator('.i18n-toggle').click();
    const rtlBox = await page.locator('.i18n-menu').boundingBox();
    assert.ok(rtlBox.x >= 0 && rtlBox.x + rtlBox.width <= 376, 'RTL menu fits');
    if (process.env.PORTAL_SCREENSHOTS) await page.screenshot({ path:path.join(process.env.PORTAL_SCREENSHOTS, 'portal-ar-375.png') });
    await page.keyboard.press('Escape');
    await language('fr');
    offline = true;
    await page.evaluate(() => showPage('dashboard'));
    await page.waitForFunction(() => document.querySelector('.dashboard-empty strong').textContent === 'Compte indisponible');
    await language('en');
    assert.equal(await page.locator('.dashboard-empty strong').textContent(), 'Account unavailable');
    await page.evaluate(() => showPage('login'));
    assert.ok(await page.locator('.i18n-toggle').isVisible(), 'selector remains accessible on login');
    await language('es');
    assert.equal((await page.locator('#loginForm button[type="submit"]').textContent()).trim(), tables.es['Sign In']);
    // The same runtime also powers non-portal pages. Their dictionaries remain unchanged.
    const shared = await context.newPage();
    await shared.route(origin + '/i18n-fixture', route => route.fulfill({ contentType:'text/html', body:'<!doctype html><html><head><title>Fixture</title></head><body><p id="label">Home</p><input id="field" placeholder="Home"><script src="/lang/i18n.js"></script></body></html>' }));
    await shared.goto(origin + '/i18n-fixture');
    await shared.waitForFunction(() => document.querySelector('#label').textContent === 'Inicio');
    assert.equal(await shared.locator('#field').getAttribute('placeholder'), 'Inicio');
    await shared.evaluate(() => document.querySelector('#field').placeholder = 'Support');
    await shared.waitForFunction(() => document.querySelector('#field').placeholder === 'Soporte');
    await shared.evaluate(() => window.__scoobyI18n.set('en'));
    await shared.waitForFunction(() => document.documentElement.lang === 'en');
    assert.equal(await shared.locator('#field').getAttribute('placeholder'), 'Support');
    assert.equal(await shared.locator('#label').textContent(), 'Home');
    await shared.close();
    assert.deepEqual(errors, []);
    console.log('PASS: 21 dictionaries, 22 languages, dynamic text, persistence, RTL, keyboard, mobile bounds, download dialog, redeem and cooldown/error states.');
    await context.close();
  } finally { await browser.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => server.close());
