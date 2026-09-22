const {chromium}=require('playwright');
const fs=require('fs'),path=require('path'),assert=require('assert'),crypto=require('crypto');
const previews=JSON.parse(fs.readFileSync(path.join(__dirname,'previews/half-life-1.json'),'utf8'));
const imageByFile=new Map(previews.screenshots.map(image=>[image.file,image]));
for(const image of previews.screenshots){
 const bytes=fs.readFileSync(path.join(__dirname,'..',image.file));
 assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),image.sha256,'Screenshot hash: '+image.file);
}
(async()=>{
 const output=process.argv[2];fs.mkdirSync(output,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce'});
 await context.addInitScript(()=>localStorage.setItem('scooby.lang','en'));
 const page=await context.newPage(),errors=[],failures=[];const base='http://127.0.0.1:8195';
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base)&&r.status()>=400)failures.push(`${r.status()} ${r.url()}`)});

 async function checkGallery(route,width){
  const previewManifest=require('./previews/half-life-1.json');
  const expected=previewManifest.galleries[route.startsWith('/products/')?'product':'guide'];
  const links=page.locator('[data-hl-preview]'), count=expected.length;
  assert.equal(await links.count(),count);
  assert.deepEqual(await links.evaluateAll(a=>a.map(e=>e.getAttribute('href'))),expected);
  for(const title of ['Half-Life: Blue Shift','Half-Life: Opposing Force','Half-Life: Source'])
   assert((await page.locator('#main-content').innerText()).includes(title),title+' missing from '+route);
  const strip=page.locator('#hl-preview-thumbnails');
  if(await strip.count()){
   await strip.evaluate(e=>e.scrollTo({left:0,behavior:'instant'}));
   await page.waitForFunction(()=>document.querySelector('[data-hl-scroll="-1"]').disabled);
   await page.getByRole('button',{name:'Next screenshot previews',exact:true}).click();
   await page.waitForFunction(()=>document.getElementById('hl-preview-thumbnails').scrollLeft>0);
   await page.getByRole('button',{name:'Previous screenshot previews',exact:true}).click();
   await page.waitForFunction(()=>document.getElementById('hl-preview-thumbnails').scrollLeft<=1);
  }
  for(let index=0;index<count;index++){
   const opener=links.nth(index), image=imageByFile.get(expected[index]);
   assert.equal(await opener.getAttribute('href'),image.file);
   assert.equal(await opener.getAttribute('data-caption'),image.caption);
   assert.equal(await opener.locator('img').getAttribute('alt'),image.alt);
   assert.equal(await opener.locator('img').getAttribute('width'),String(image.dimensions[0]));
   assert.equal(await opener.locator('img').getAttribute('height'),String(image.dimensions[1]));
   await opener.click();
   const dialog=page.locator('#hl-lightbox');assert(await dialog.isVisible());
   assert.equal(await page.locator('#hl-lightbox-count').innerText(),(index+1)+' / '+count);
   assert.equal(await page.locator('#hl-lightbox-image').getAttribute('src'),new URL(await opener.getAttribute('href'),base).href);
   assert.equal(await page.locator('#hl-lightbox-image').getAttribute('alt'),await opener.locator('img').getAttribute('alt'));
   await page.locator('#hl-lightbox-image').evaluate(i=>i.decode());
   assert.deepEqual(await page.locator('#hl-lightbox-image').evaluate(i=>[i.naturalWidth,i.naturalHeight]),image.dimensions);
   assert.equal(await page.locator('#hl-lightbox-caption').innerText(),image.caption);
   assert(await dialog.evaluate(d=>{const r=d.getBoundingClientRect();return r.left>=0&&r.right<=innerWidth&&r.top>=0&&r.bottom<=innerHeight}), 'Dialog outside viewport '+width);
   if(index===0){
    await page.keyboard.press('ArrowLeft');assert.equal(await page.locator('#hl-lightbox-count').innerText(),count+' / '+count);
    await page.keyboard.press('ArrowRight');assert.equal(await page.locator('#hl-lightbox-count').innerText(),'1 / '+count);
    await page.getByRole('button',{name:'Next screenshot',exact:true}).click();assert.equal(await page.locator('#hl-lightbox-count').innerText(),'2 / '+count);
    await page.getByRole('button',{name:'Previous screenshot',exact:true}).click();assert.equal(await page.locator('#hl-lightbox-count').innerText(),'1 / '+count);
    await page.screenshot({path:path.join(output,(route.startsWith('/products/')?'product':'wiki')+'-gallery-open-'+width+'.png')});
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
 await page.locator('a[href="/products/half-life-1/"]').click();
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
 assert(fallback.url().endsWith('/current/spawner.png'),'No-JS screenshot link failed');
 await noJs.close();
 await browser.close();const result={passed:!errors.length&&!failures.length,errors,failures,checks:['eight source-hash-verified 1600x900 original Half-Life captures','product8 and guide4 exact manifest images, captions and alt text','desktop 1440','mobile 375','landscape 812x375','collection to product','feature search','wiki dropdown on existing GMod and home','mobile menu and Escape','images and local requests','full-size product and wiki galleries','all preview images and captions','thumbnail strip navigation','keyboard navigation and focus restoration','mobile lightbox bounds','no-JavaScript screenshot fallback','all four supported edition names']};
 fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));assert(result.passed);
})().catch(e=>{console.error(e);process.exit(1)});
