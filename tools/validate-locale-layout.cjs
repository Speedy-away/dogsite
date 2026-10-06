const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const locales = require('./search-locales.json');
(async () => {
 const browser = await chromium.launch({channel:'msedge', headless:true});
 try {
  const context = await browser.newContext({ reducedMotion:'reduce' });
  await context.route('**/*', route => route.request().url().startsWith('http://127.0.0.1:8199/') ? route.continue() : route.abort());
  await context.addInitScript(() => {
   if (!sessionStorage.getItem('locale-test-seeded')) {
    localStorage.setItem('scooby.lang', 'de');
    sessionStorage.setItem('locale-test-seeded', '1');
   }
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  for (const code of Object.keys(locales)) {
   await page.setViewportSize({width:1440,height:1000});
   await page.goto('http://127.0.0.1:8199/lang/' + code + '/', {waitUntil:'domcontentloaded'});
   await page.waitForFunction(code => window.__scoobyI18n?.get() === code, code);
   await page.locator('.hero .lead').waitFor({state:'visible'});
   assert.equal(await page.locator('.hero .lead').innerText(), locales[code].intro);
   assert.equal(await page.locator('.i18n-modal-overlay').count(), 0);
   assert.equal(await page.locator('html').getAttribute('dir'), locales[code].rtl ? 'rtl' : 'ltr');
   assert.equal(await page.locator('#heroScenes').count(), 1);
   for (const width of [1440,375]) {
    await page.setViewportSize({width,height:900});
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), code + ' overflow at ' + width);
   }
   console.log('PASS ' + code + ': full layout, explicit language, desktop/mobile');
  }
  await page.goto('http://127.0.0.1:8199/lang/th/', {waitUntil:'domcontentloaded'});
  await page.waitForFunction(() => window.__scoobyI18n?.get() === 'th');
  fs.mkdirSync('project/build/locale-layout', {recursive:true});
  await page.screenshot({path:'project/build/locale-layout/th-mobile.png'});
  await page.setViewportSize({width:1440,height:1000});
  await page.screenshot({path:'project/build/locale-layout/th-desktop.png'});
  await page.locator('.btn-hero-primary').click();
  assert(await page.locator('#startModal').isVisible());
  await page.evaluate(() => window.__scoobyI18n.set('fr'));
  await page.waitForURL('**/lang/fr/');
  await page.waitForFunction(() => window.__scoobyI18n?.get() === 'fr');
  await page.evaluate(() => window.__scoobyI18n.set('en'));
  await page.waitForURL('http://127.0.0.1:8199/');
  await page.waitForFunction(() => window.__scoobyI18n?.get() === 'en');
  assert.deepEqual(errors, []);
  const offline = await browser.newContext({javaScriptEnabled:false});
  const nojs = await offline.newPage();
  await nojs.goto('http://127.0.0.1:8199/lang/th/', {waitUntil:'domcontentloaded'});
  assert.equal(await nojs.locator('.hero .lead').innerText(), locales.th.intro);
  assert(await nojs.locator('.hero').isVisible());
  console.log('PASS modal, language switching, no-script localized content; no page errors');
 } finally { await browser.close(); }
})().catch(error => {console.error(error);process.exitCode=1;});
