const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const base=process.env.MEGABONK_SITE_BASE||'http://127.0.0.1:8207';
const out=path.resolve(__dirname,'../project/build/megabonk-site-validation');
const routes=['/products/megabonk/','/features-list/megabonk-features/','/guides/megabonk/',...['getting-started','menu-settings','languages','lua-scripts','spawner-unlocks','troubleshooting'].map(x=>'/guides/megabonk/'+x+'/')];
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({reducedMotion:'reduce'}),page=await context.newPage();
 const errors=[],links=new Set();let checks=0;
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base+'/')&&r.status()>=400)errors.push(r.status()+' '+r.url());});
 const go=async route=>{const r=await page.goto(base+route,{waitUntil:'networkidle'});assert.equal(r.status(),200);const en=page.getByRole('button',{name:'Continue in English',exact:true});if(await en.isVisible())await en.click();};
 try{
  for(const width of [1440,375]){
   await page.setViewportSize({width,height:1000});
   for(const route of routes){
    await go(route);assert.equal(await page.locator('h1').count(),1,route+' title');checks++;
    assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),route+' overflow '+width);checks++;
    const ids=await page.locator('[id]').evaluateAll(es=>es.map(e=>e.id));assert.equal(ids.length,new Set(ids).size,route+' duplicate IDs');checks++;
    assert.equal(await page.locator('link[rel="canonical"]').getAttribute('href'),'https://scoobymenu.cc'+route);checks++;
    if(width===1440)for(const href of await page.locator('a[href],img[src],script[src],link[rel="stylesheet"]').evaluateAll(es=>es.map(e=>e.getAttribute('href')||e.getAttribute('src')))){
     const u=new URL(href,base+route);if(u.origin===base)links.add(u.pathname+u.search+u.hash);
    }
    if(['/products/megabonk/','/features-list/megabonk-features/','/guides/megabonk/','/guides/megabonk/languages/'].includes(route))await page.screenshot({path:path.join(out,route.split('/').filter(Boolean).join('-')+'-'+width+'.png'),fullPage:true});
   }
  }
  await page.setViewportSize({width:1440,height:1000});await go('/products/megabonk/');
  assert.equal(await page.getByRole('link',{name:/download launcher/i}).count(),0);checks++;
  await page.getByRole('link',{name:/view all features/i}).first().click();await page.waitForURL('**/features-list/megabonk-features/');checks++;
  assert.equal(await page.locator('.feature-item').count(),55);checks++;
  for(const term of ['languages','Lua','unlocks']){
   await page.locator('#feature-search').fill(term);
   await page.waitForFunction(()=>document.querySelector('#result-count').textContent.includes('match your search'));
   await page.waitForFunction(t=>new URL(location.href).searchParams.get('q')===t,term);
   assert(await page.locator('.feature-item:visible').count()>0,term+' search');checks++;
  }
  await page.locator('#feature-search').fill('no-such-megabonk-feature-321');await page.locator('#feature-empty').waitFor({state:'visible'});checks++;
  await page.locator('#reset-search').click();await page.locator('#expand-all').click();assert.equal(await page.locator('.feature-item:visible').count(),55);checks++;
  await page.locator('#collapse-all').click();assert.equal(await page.locator('.feature-category[open]').count(),0);checks++;
  await go('/guides/');await page.keyboard.press('Control+k');await page.locator('#guide-search').fill('Megabonk languages');
  await page.locator('#guide-results a[href="/guides/megabonk/languages/"]').first().waitFor();checks++;
  await page.keyboard.press('Escape');await page.locator('#search-dialog').waitFor({state:'hidden'});checks++;
  await go('/guides/megabonk/');for(const theme of ['light','dark']){await page.locator('#theme-select').selectOption(theme);assert.equal(await page.locator('html').getAttribute('data-theme'),theme);checks++;}
  await page.setViewportSize({width:375,height:900});await page.getByRole('button',{name:'Menu',exact:true}).click();
  assert.equal(await page.getByRole('button',{name:'Menu',exact:true}).getAttribute('aria-expanded'),'true');checks++;
  await page.locator('[data-megabonk-nav] a[href="/guides/megabonk/languages/"]').click();await page.waitForURL('**/guides/megabonk/languages/');checks++;
  await page.screenshot({path:path.join(out,'wiki-dark-mobile.png'),fullPage:true});
  for(const relative of links){const u=new URL(relative,base),r=await context.request.get(u.origin+u.pathname+u.search);assert.equal(r.status(),200,'Broken local link '+relative);if(u.hash&&r.headers()['content-type']?.includes('text/html')){const html=await r.text(),id=decodeURIComponent(u.hash.slice(1));assert(html.includes('id="'+id+'"')||html.includes("id='"+id+"'"),'Missing anchor '+relative);}checks++;}
  for(const name of ['status','controls','pickups','run-hud']){const r=await context.request.get(base+'/guides/megabonk/lua-scripts/examples/'+name+'.lua');assert.equal(r.status(),200);assert((await r.text()).includes('megabonk.'));checks++;}
  const noJs=await browser.newContext({javaScriptEnabled:false,viewport:{width:375,height:900}}),staticPage=await noJs.newPage();
  await staticPage.goto(base+'/guides/megabonk/');assert(await staticPage.locator('main a[href="/guides/megabonk/getting-started/"]').first().isVisible());checks++;
  await staticPage.goto(base+'/features-list/megabonk-features/');await staticPage.locator('.feature-category summary').first().click();assert(await staticPage.locator('.feature-item').first().isVisible());checks++;await noJs.close();
  assert.deepEqual(errors,[]);checks++;fs.writeFileSync(path.join(out,'result.json'),JSON.stringify({passed:checks,local_links:links.size,routes,errors},null,2));console.log('PASS: '+checks+' Megabonk website checks');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
