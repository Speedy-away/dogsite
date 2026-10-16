const assert=require('node:assert/strict'),fs=require('node:fs');
const {chromium}=require('playwright');
const {createServer}=require('./preview.cjs');
(async()=>{
 const server=createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const origin='http://127.0.0.1:'+server.address().port;let browser;
 fs.mkdirSync('build/reseller',{recursive:true});
 try{
  browser=await chromium.launch({headless:true,channel:'msedge'});
  for(const width of [1440,390,320]){
   const context=await browser.newContext({viewport:{width,height:1000},permissions:['clipboard-read','clipboard-write']});
   const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.goto(origin+'/resellers/become/');
   const total=()=>page.locator('#order-total').textContent(),profit=()=>page.locator('#order-profit').textContent();
   assert.equal(await total(),'£112.50');assert.equal(await profit(),'£52.50');assert.ok(await page.locator('#order-profit').isVisible());
   await page.locator('#selling-preset').selectOption('25');assert.equal(await profit(),'£75.00');
   await page.locator('#market').selectOption('brazil');assert.equal(await total(),'£90.00');assert.equal(await profit(),'£60.00');assert.equal(await page.locator('#premium-base').textContent(),'£12.00 base · Lifetime');
   await page.locator('#premium-qty').fill('50');assert.equal(await total(),'£360.00');assert.equal(await page.locator('#discount-label').textContent(),'40% discount');
   await page.locator('#premium-qty').fill('1001');assert.equal(await page.locator('#discount-label').textContent(),'65% discount');
   await page.locator('#premium-qty').fill('9');assert.ok(await page.locator('#copy-order').isDisabled());
   await page.locator('#market').selectOption('standard');await page.locator('#selling-preset').selectOption('10');
   for(const id of ['premium','plus','rdr2','fivem','redm'])await page.locator('#'+id+'-qty').fill('2');
   assert.equal(await total(),'£135.00');assert.equal(await profit(),'£63.00');
   await page.locator('#selling-preset').selectOption('custom');await page.locator('#premium-sell').fill('1');assert.equal(await profit(),'£32.00');
   await page.locator('#copy-order').click();const copied=await page.evaluate(()=>navigator.clipboard.readText());
   for(const name of ['GTA 5 Premium','GTA 5 Plus','RDR2','FiveM','RedM','BTC or LTC only','Standard / other countries'])assert.ok(copied.includes(name));
   await page.locator('#premium-qty').fill('1.5');assert.equal(await total(),'—');assert.equal(await profit(),'—');assert.ok(await page.locator('#copy-order').isDisabled());
   await page.locator('#premium-qty').fill('2');await page.locator('#selling-preset').selectOption('10');await page.locator('.selling-options summary').click();
   assert.equal(await page.locator('a[href="https://t.me/whatwhatboy"]').count(),1);
   const directory=page.getByRole('link',{name:'Check out our resellers'});assert.equal(await directory.getAttribute('href'),'/resellers/');
   assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));
   await page.screenshot({path:`build/reseller/page-${width}.png`,fullPage:true});
   await page.locator('#open-media-pack').click();const dialog=page.locator('#media-dialog');assert.ok(await dialog.isVisible());
   assert.ok(await dialog.evaluate(el=>el.scrollWidth<=el.clientWidth));
   for(const url of await dialog.locator('a[download]').evaluateAll(links=>links.map(a=>a.href))){const result=await page.request.head(url);assert.equal(result.status(),200,url);assert.equal(result.headers()['content-type'],'application/zip');}
   await page.screenshot({path:`build/reseller/downloads-${width}.png`});
   await page.keyboard.press('Escape');assert.ok(!await dialog.isVisible());assert.ok(await page.locator('#open-media-pack').evaluate(el=>el===document.activeElement));
   assert.deepEqual(errors,[]);await context.close();
  }
  console.log('PASS: regional pricing, new discount milestones, profit presets, custom prices, validation, contacts, directory link, download popup/ZIPs, mobile layout and keyboard close.');
 }finally{await browser?.close();await new Promise(r=>server.close(r));}
})().catch(e=>{console.error(e);process.exitCode=1});
