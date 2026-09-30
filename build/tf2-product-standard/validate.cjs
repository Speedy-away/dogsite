const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=process.cwd(),base='http://127.0.0.1:8198',out=path.join(root,'build/tf2-product-standard');
const shots=JSON.parse(fs.readFileSync('tools/previews/tf2.json','utf8')).screenshots;
(async()=>{
 let checks=0;const errors=[];const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({reducedMotion:'reduce'});await context.addInitScript(()=>localStorage.setItem('scooby.lang','en'));
 const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().startsWith(base)&&r.status()>=400)errors.push(r.status()+' '+r.url());});
 try {
  for(const shot of shots){assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,shot.file))).digest('hex'),shot.sha256);assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.resolve(root,shot.source))).digest('hex'),shot.source_sha256);checks+=2;}
  for(const width of [1440,375,320]){
   await page.setViewportSize({width,height:1000});await page.goto(base+'/products/tf2/',{waitUntil:'networkidle'});
   const lang=page.getByRole('button',{name:'Continue in English',exact:true});if(await lang.isVisible())await lang.click();
   assert.equal(await page.locator('body.product-detail').count(),1);assert.equal(await page.locator('.content-grid>.sidebar .purchase-card').count(),1);checks+=2;
   assert.equal(await page.locator('[data-tf2-preview]').count(),5);assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1));checks+=2;
   for(let i=0;i<shots.length;i++){
    const link=page.locator('[data-tf2-preview]').nth(i);await link.click();await page.locator('#lightbox-img').evaluate(i=>i.decode());
    assert.equal(await page.locator('#lightbox-img').getAttribute('alt'),shots[i].alt);checks++;
    const bounds=await page.locator('#lightbox-img').boundingBox();assert(bounds.x>=-1&&bounds.x+bounds.width<=width+1);checks++;
    await page.keyboard.press('ArrowRight');await page.locator('#lightbox-img').evaluate(i=>i.decode());assert((await page.locator('#lightbox-caption').innerText()).startsWith(((i+1)%5+1)+' / 5'));checks++;
    if(i===0&&width===1440)await page.screenshot({path:path.join(out,'gallery-desktop.png')});
    await page.keyboard.press('Escape');await page.locator('#lightbox').waitFor({state:'hidden'});assert(await link.evaluate(e=>e===document.activeElement));checks++;
   }
   await page.evaluate(()=>scrollTo(0,0));await page.screenshot({path:path.join(out,'product-'+width+'.png'),fullPage:true});
   await page.getByRole('link',{name:'View all features',exact:true}).first().click();assert(new URL(page.url()).pathname==='/features-list/tf2-features/');checks++;
   assert.equal(await page.locator('.feature-item').count(),123);assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1));checks+=2;
   await page.locator('#feature-search').fill('MvM');await page.waitForFunction(()=>document.querySelector('#result-count').textContent.includes('matching')||document.querySelectorAll('.feature-item[hidden]').length>0);
   assert((await page.locator('.feature-item:visible').count())>=3);assert((await page.locator('.feature-item:visible').allTextContents()).every(t=>t.includes('Retail only')));checks+=2;
   await page.locator('#feature-search').fill('no-such-feature-948');await page.locator('#feature-empty').waitFor({state:'visible'});checks++;
   await page.getByRole('button',{name:'Clear all filters'}).click();await page.locator('#feature-empty').waitFor({state:'hidden'});await page.locator('#expand-all').click();assert.equal(await page.locator('.feature-item:visible').count(),123);checks++;
   await page.screenshot({path:path.join(out,'features-'+width+'.png'),fullPage:true});
  }
  await page.goto(base+'/',{waitUntil:'networkidle'});const cards=await page.locator('.catalog-card').evaluateAll(a=>a.map(e=>e.getAttribute('href')));assert.equal(cards[cards.indexOf('/products/l4d/')+1],'/products/tf2/');checks++;
  await page.locator('.catalog-card[href="/products/tf2/"]').scrollIntoViewIfNeeded();await page.screenshot({path:path.join(out,'homepage-order.png')});
  for(const route of ['/','/products/tf2/','/features-list/tf2-features/']){await page.goto(base+route);for(const selector of ['meta[name="keywords"]','meta[property="og:description"]','meta[name="twitter:description"]'])assert((await page.locator(selector).getAttribute('content')).includes('TF2'));checks+=3;}
  for(const code of Object.keys(require(path.join(root,'tools/search-locales.json')))){
   await page.goto(base+'/lang/'+code+'/');const links=await page.locator('.game-card h3 a').evaluateAll(a=>a.map(e=>e.getAttribute('href')));assert.equal(links[links.indexOf('/products/l4d/')+1],'/products/tf2/');checks++;
  }
  for(const route of ['/products/tf2/','/features-list/tf2-features/']){
   await page.goto(base+route);const hrefs=await page.locator('a[href],img[src],link[rel="stylesheet"]').evaluateAll(nodes=>nodes.map(n=>n.getAttribute('href')||n.getAttribute('src')));
   for(const href of new Set(hrefs)){const url=new URL(href,base+route);if(url.origin!==base)continue;const r=await context.request.get(url.origin+url.pathname+url.search);assert.equal(r.status(),200,href);if(url.hash){const html=await r.text();assert(html.includes('id="'+decodeURIComponent(url.hash.slice(1))+'"'),'Missing anchor '+href);}checks++;}
  }
  const noJs=await browser.newContext({javaScriptEnabled:false});const fallback=await noJs.newPage();await fallback.goto(base+'/products/tf2/');await fallback.locator('[data-tf2-preview]').first().click();await fallback.waitForURL(base+shots[0].file);assert(new URL(fallback.url()).pathname===shots[0].file);checks++;await noJs.close();
  assert.deepEqual(errors,[]);checks++;fs.writeFileSync(path.join(out,'browser-results.json'),JSON.stringify({passed:checks,features:123,screenshots:shots.length,native_gameplay_screenshots:3,errors},null,2));console.log('PASS: '+checks+' TF2 product, gallery, features and homepage checks');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
