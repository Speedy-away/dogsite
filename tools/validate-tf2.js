const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const base=process.env.TF2_SITE_BASE||'http://127.0.0.1:8198';
const output=path.resolve(__dirname,'../build/tf2-free-key');
(async()=>{
 fs.mkdirSync(output,{recursive:true});const browser=await chromium.launch({channel:'msedge',headless:true});
 try {
 const page=await browser.newPage({reducedMotion:'reduce'});await page.addInitScript(()=>localStorage.setItem('scooby.lang','en'));const errors=[];
 page.on('pageerror',error=>errors.push(error.message));
 page.on('response',response=>{if(response.url().startsWith(base+'/')&&response.status()>=400)errors.push(response.status()+' '+response.url());});
 let checks=0;
 for(const width of [1440,768,375,320]){
  await page.setViewportSize({width,height:1000});await page.goto(base+'/products/tf2/',{waitUntil:'networkidle'});
  assert.equal(await page.locator('h1').count(),1);
  assert.equal(await page.locator('.purchase-card img,.purchase-card select,#tf2-edition,#tf2-about').count(),0);
  assert((await page.locator('.price-note').innerText()).includes('TF2 & TF2 Classified'));
  assert.equal(await page.locator('#getFreeKey').innerText(),'GET FREE KEY');
  assert.equal(await page.locator('#getFreeKey').getAttribute('href'),'https://scoobymenu.cc/scoobyontop.html');
  assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),'Overflow at '+width);checks+=6;
  await page.screenshot({path:path.join(output,'product-'+width+'.png'),fullPage:true});
  await page.locator('.purchase-card').screenshot({path:path.join(output,'access-card-'+width+'.png')});
  await page.locator('#getFreeKey').click();assert(await page.locator('#freeKeyModal').isVisible());
  assert.equal(await page.locator('#freeKeyModal').evaluate(el=>getComputedStyle(el).opacity),'1');assert.equal(await page.locator('#freeKeyModal .freekey-modal').evaluate(el=>getComputedStyle(el).transform),'none');checks+=2;
  assert.equal(await page.locator('#freeKeyBtn').getAttribute('aria-disabled'),'true');
  await page.locator('#freeKeyBtn[aria-disabled="false"]').waitFor();
  assert.equal(await page.locator('#freeKeyBtn').getAttribute('href'),'https://scoobymenu.cc/scoobyontop.html');
  assert.equal(await page.locator('#freeKeyCountdown').innerText(),'✓');
  if(width===375)await page.screenshot({path:path.join(output,'free-key-mobile.png')});
  await page.keyboard.press('Escape');assert(!await page.locator('#freeKeyModal').isVisible());
  assert(await page.locator('#getFreeKey').evaluate(el=>el===document.activeElement));checks+=6;
  await page.locator('[data-tf2-preview]').first().click();assert(await page.locator('#lightbox').isVisible());
  await page.keyboard.press('ArrowRight');assert((await page.locator('#lightbox-caption').innerText()).startsWith('2 /'));
  await page.keyboard.press('Escape');assert(!await page.locator('#lightbox').isVisible());checks+=3;
 }
 for(const edition of ['tf2-classified','invalid']){await page.goto(base+'/products/tf2/?edition='+edition);assert.equal(await page.locator('#tf2-edition,#tf2-logo').count(),0);assert(await page.locator('#getFreeKey').isVisible());checks+=2;}
 await page.goto(base+'/store/',{waitUntil:'networkidle'});assert.equal(await page.locator('[data-product="tf2"] [data-free]').count(),1);await page.locator('[data-product="tf2"] [data-free]').click();assert(await page.getByRole('dialog').isVisible());checks+=2;
 await page.goto(base+'/products/free/',{waitUntil:'networkidle'});assert.equal(await page.locator('[data-product="tf2"] a').getAttribute('href'),'/products/tf2/');checks++;
 await page.goto(base+'/source-games/',{waitUntil:'networkidle'});await page.getByRole('searchbox',{name:'Search games'}).fill('Classified');assert.equal(await page.locator('[data-game]:visible').count(),1);checks++;
 const noJs=await browser.newPage({javaScriptEnabled:false});await noJs.goto(base+'/products/tf2/');assert(await noJs.locator('#getFreeKey').isVisible());assert.equal(await noJs.locator('#getFreeKey').getAttribute('href'),'https://scoobymenu.cc/scoobyontop.html');assert(!await noJs.locator('#freeKeyModal').isVisible());checks+=3;await noJs.close();
 assert.deepEqual(errors,[]);checks++;fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({passed:checks,errors},null,2));console.log('PASS: '+checks+' TF2 free-key, gallery and layout checks');
 } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
