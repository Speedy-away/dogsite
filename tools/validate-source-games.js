const {chromium}=require('playwright');
const fs=require('fs'),path=require('path'),assert=require('assert');
(async()=>{
 const output=process.argv[2];fs.mkdirSync(output,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce'});
 await context.addInitScript(()=>localStorage.setItem('scooby-language','en'));
 const page=await context.newPage(),errors=[],failures=[];const base='http://127.0.0.1:8195';
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base)&&r.status()>=400)failures.push(`${r.status()} ${r.url()}`)});

 async function checkGallery(route,width){
  const links=page.locator('[data-hl-preview]'), count=route.startsWith('/products/')?4:2;
  assert.equal(await links.count(),count);
  for(const title of ['Half-Life: Blue Shift','Half-Life: Opposing Force','Half-Life: Source'])
   assert((await page.locator('#main-content').innerText()).includes(title),title+' missing from '+route);
  for(let index=0;index<count;index++){
   const opener=links.nth(index);await opener.click();
   const dialog=page.locator('#hl-lightbox');assert(await dialog.isVisible());
   assert.equal(await page.locator('#hl-lightbox-count').innerText(),(index+1)+' / '+count);
   assert.equal(await page.locator('#hl-lightbox-image').getAttribute('src'),new URL(await opener.getAttribute('href'),base).href);
   assert.equal(await page.locator('#hl-lightbox-image').getAttribute('alt'),await opener.locator('img').getAttribute('alt'));
   await page.locator('#hl-lightbox-image').evaluate(i=>i.decode());
   assert(await dialog.evaluate(d=>{const r=d.getBoundingClientRect();return r.left>=0&&r.right<=innerWidth&&r.top>=0&&r.bottom<=innerHeight}), 'Dialog outside viewport '+width);
   if(index===0){
    await page.keyboard.press('ArrowLeft');assert.equal(await page.locator('#hl-lightbox-count').innerText(),count+' / '+count);
    await page.keyboard.press('ArrowRight');assert.equal(await page.locator('#hl-lightbox-count').innerText(),'1 / '+count);
    await page.getByRole('button',{name:'Next screenshot',exact:true}).click();assert.equal(await page.locator('#hl-lightbox-count').innerText(),'2 / '+count);
    await page.getByRole('button',{name:'Previous screenshot',exact:true}).click();assert.equal(await page.locator('#hl-lightbox-count').innerText(),'1 / '+count);
    await page.screenshot({path:path.join(output,(count===4?'product':'wiki')+'-gallery-open-'+width+'.png')});
   }
   if(index%2===0)await page.keyboard.press('Escape');
   else await page.getByRole('button',{name:'Close screenshot',exact:true}).click();
   assert(!(await dialog.isVisible()));
   assert(await opener.evaluate(e=>e===document.activeElement),'Gallery focus not restored');
  }
  await page.evaluate(()=>scrollTo(0,0));
 }

 for(const width of [1440,375,812]){
  await page.setViewportSize({width,height:width===812?375:1000});
  for(const route of ['/source-games/','/products/half-life-1/','/guides/source-games/','/guides/half-life-1/','/guides/half-life-1/getting-started/','/features-list/half-life-1-features/']){
   await page.goto(base+route,{waitUntil:'networkidle'});
   const modal=page.locator('.i18n-modal-overlay.show button[data-lang="en"]');if(await modal.count())await modal.click();
   assert(!(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+2)),`${route} overflow at ${width}`);
   assert(await page.locator('h1').count(),`No h1 ${route}`);
   for(const img of await page.locator('img[src]:visible').all()) {
    await img.scrollIntoViewIfNeeded();await img.evaluate(i=>i.decode());
   }
   await page.evaluate(()=>scrollTo(0,0));
   if(route==='/products/half-life-1/' || route==='/guides/half-life-1/') await checkGallery(route,width);
   if(width!==812)await page.screenshot({path:path.join(output,route.split('/').filter(Boolean).join('-')+'-'+width+'.png'),fullPage:true});
  }
 }
 await page.setViewportSize({width:1440,height:1000});await page.goto(base+'/source-games/');
 await page.locator('.source-card[href="/products/half-life-1/"]').click();
 assert(page.url().endsWith('/products/half-life-1/'));
 await page.getByRole('link',{name:'View all features',exact:true}).click();
 await page.locator('#feature-search').fill('noclip');
 await page.waitForTimeout(350);assert(await page.locator('.feature-item:visible').count(),'Feature search has no result');
 await page.goto(base+'/guides/gmod/');
 const group=page.locator('[data-source-games-nav]');await group.locator('summary').click();await group.getByRole('link',{name:'Half-Life 1',exact:true}).click();
 assert(page.url().endsWith('/guides/half-life-1/'));await page.getByRole('link',{name:/Getting started →/}).click();assert(page.url().endsWith('/getting-started/'));
 await page.setViewportSize({width:375,height:812});await page.goto(base+'/products/half-life-1/');
 await page.locator('#hamburgerBtn').click();assert.equal(await page.locator('#hamburgerBtn').getAttribute('aria-expanded'),'true');await page.keyboard.press('Escape');assert.equal(await page.locator('#hamburgerBtn').getAttribute('aria-expanded'),'false');
 await page.goto(base+'/guides/');await page.locator('.menu-toggle').click();
 await page.locator('[data-source-games-nav] summary').click();await page.locator('[data-source-games-nav]').getByRole('link',{name:'Half-Life 1',exact:true}).click();
 assert(page.url().endsWith('/guides/half-life-1/'));

 const noJs=await browser.newContext({javaScriptEnabled:false});
 const fallback=await noJs.newPage();await fallback.goto(base+'/products/half-life-1/');
 await fallback.locator('[data-hl-preview]').first().click();
 assert(fallback.url().endsWith('/half-life-esp.jpg'),'No-JS screenshot link failed');
 await noJs.close();
 await browser.close();const result={passed:!errors.length&&!failures.length,errors,failures,checks:['desktop 1440','mobile 375','landscape 812x375','collection to product','feature search','wiki dropdown on existing GMod and home','mobile menu and Escape','images and local requests','full-size product and wiki galleries','all preview images and captions','keyboard navigation and focus restoration','mobile lightbox bounds','no-JavaScript screenshot fallback','all four supported edition names']};
 fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));assert(result.passed);
})().catch(e=>{console.error(e);process.exit(1)});
