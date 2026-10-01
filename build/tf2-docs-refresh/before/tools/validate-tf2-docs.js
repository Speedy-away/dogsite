const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const base=process.env.TF2_SITE_BASE||'http://127.0.0.1:8198';
const out=path.resolve(__dirname,'../build/tf2-site-validation');
const pages=['/products/tf2/','/guides/tf2/','/guides/tf2/getting-started/','/guides/tf2/requirements/','/guides/tf2/editions/','/guides/tf2/menu-settings/','/guides/tf2/lua-scripts/','/guides/tf2/troubleshooting/','/docs/tf2/','/api/tf2/'];
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true});
 let checks=0;const errors=[],links=new Set();const context=await browser.newContext({reducedMotion:'reduce'});
 await context.grantPermissions(['clipboard-read','clipboard-write'],{origin:base});
 const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base+'/')&&r.status()>=400)errors.push(r.status()+' '+r.url());});
 const go=async route=>{const r=await page.goto(base+route,{waitUntil:'networkidle'});if(r)assert.equal(r.status(),200);else assert.equal(new URL(page.url()).pathname,new URL(base+route).pathname);const lang=page.getByRole('button',{name:'Continue in English',exact:true});if(await lang.isVisible())await lang.click();};
 try{
  for(const width of [1440,375]){
   await page.setViewportSize({width,height:1000});
   for(const route of pages){
    await go(route);
    assert.equal(await page.locator('h1').count(),1,route+' has one title');checks++;
    assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),route+' overflow at '+width);checks++;
    const ids=await page.locator('[id]').evaluateAll(nodes=>nodes.map(n=>n.id));assert.equal(ids.length,new Set(ids).size,route+' duplicate IDs');checks++;
    const target=await page.locator('link[rel="canonical"]').getAttribute('href');assert.equal(target,'https://scoobymenu.cc'+route);checks++;
    if(width===1440)for(const href of await page.locator('a[href],img[src],script[src],link[rel="stylesheet"]').evaluateAll(nodes=>nodes.map(n=>n.getAttribute('href')||n.getAttribute('src')))){
     const url=new URL(href,base+route);if(url.origin===base)links.add(url.pathname+url.search+url.hash);
    }
    if(['/guides/tf2/','/docs/tf2/','/api/tf2/','/products/tf2/'].includes(route))await page.screenshot({path:path.join(out,route.split('/')[1]+'-'+width+'.png'),fullPage:true});
   }
  }
  await page.setViewportSize({width:1440,height:1000});
  await go('/api/tf2/');
  assert.equal(await page.locator('.reference-entry').count(),JSON.parse(fs.readFileSync(path.resolve(__dirname,'../docs/tf2/source-manifest.json'),'utf8')).reference_entries);checks++;
  assert.equal(await page.locator('#classified-tf2-skins-page-players .edition-label').innerText(),'Classified');checks++;
  assert.equal(await page.locator('#host-built-in-feature-families .edition-label').innerText(),'Retail');checks++;
  await page.locator('#api-search').fill('tf2.world_to_screen');await page.locator('.reference-entry:visible[open]').first().waitFor();
  assert(await page.locator('.reference-entry:visible pre').count()>0);checks++;
  await page.locator('.reference-entry:visible').getByRole('button',{name:'Copy code',exact:true}).first().click();
  await page.getByRole('button',{name:'Copied',exact:true}).first().waitFor();
  assert((await page.evaluate(()=>navigator.clipboard.readText())).includes('tf2.world_to_screen'));checks++;
  await page.locator('#api-search').fill('not-a-real-tf2-api-123');assert(await page.locator('#no-results').isVisible());checks++;
  await page.getByRole('button',{name:'Clear search'}).click();assert.equal(await page.locator('.reference-entry:visible').count(),JSON.parse(fs.readFileSync(path.resolve(__dirname,'../docs/tf2/source-manifest.json'),'utf8')).reference_entries);checks++;
  await go('/api/tf2/#host-tf2-session');assert(await page.locator('#host-tf2-session').evaluate(e=>e.open));checks++;
  await page.setViewportSize({width:375,height:900});await go('/api/tf2/');
  await page.getByRole('button',{name:'Sections',exact:true}).click();assert.equal(await page.getByRole('button',{name:'Sections',exact:true}).getAttribute('aria-expanded'),'true');checks++;
  await page.locator('#sidebar-nav a.entry[href="#host-tf2-info"]').click();assert(await page.locator('#host-tf2-info').evaluate(e=>e.open));checks++;
  assert.equal(await page.getByRole('button',{name:'Sections',exact:true}).getAttribute('aria-expanded'),'false');checks++;
  await go('/guides/tf2/');
  await page.keyboard.press('Control+k');await page.locator('#guide-search').fill('Classified edition');
  await page.locator('#guide-results a').first().waitFor();assert((await page.locator('#guide-results a').first().getAttribute('href')).startsWith('/guides/tf2/'));checks++;
  await page.keyboard.press('Escape');await page.locator('#search-dialog').waitFor({state:'hidden'});assert(!await page.locator('#search-dialog').evaluate(e=>e.open));checks++;
  for(const theme of ['light','dark']){await page.locator('#theme-select').selectOption(theme);assert.equal(await page.locator('html').getAttribute('data-theme'),theme);checks++;}
  await page.screenshot({path:path.join(out,'wiki-dark-375.png'),fullPage:true});
  await go('/docs/');await page.keyboard.press('Control+k');await page.locator('#guide-search').fill('tf2.entities');
  await page.locator('#guide-results a[href^="/api/tf2/"]').first().waitFor();checks++;
  await go('/');assert.equal(await page.locator('.catalog-card[href="/products/tf2/"]').count(),1);checks++;
  await go('/source-games/');await page.locator('#source-game-search').fill('Classified');assert.equal(await page.locator('[data-game]:visible').count(),1);assert.equal(await page.locator('[data-game="tf2"]').getAttribute('data-status'),'released');checks+=2;
  for(const relative of links){
   const url=new URL(relative,base),r=await context.request.get(url.origin+url.pathname+url.search);assert.equal(r.status(),200,'Broken link '+relative);
   if(url.hash&&r.headers()['content-type']?.includes('text/html')){const html=await r.text(),id=decodeURIComponent(url.hash.slice(1));assert(html.includes('id="'+id+'"')||html.includes("id='"+id+"'"),'Missing anchor '+relative);}
   checks++;
  }
  for(const name of ['TF2 Player HUD','TF2 Player Labels','Edition Info']){
   const r=await context.request.get(base+'/docs/tf2/examples/'+encodeURIComponent(name)+'.lua');assert.equal(r.status(),200);assert((await r.text()).includes('TF2_API_VERSION'));checks++;
  }
  const noJs=await browser.newContext({javaScriptEnabled:false,viewport:{width:375,height:900}});
  const staticPage=await noJs.newPage();await staticPage.goto(base+'/api/tf2/');
  await staticPage.locator('#host-tf2-info summary').click();assert(await staticPage.locator('#host-tf2-info pre').isVisible());checks++;
  await staticPage.goto(base+'/guides/tf2/');assert(await staticPage.locator('main a[href="/guides/tf2/getting-started/"]').isVisible());checks++;
  await noJs.close();assert.deepEqual(errors,[]);checks++;
  fs.writeFileSync(path.join(out,'result.json'),JSON.stringify({passed:checks,unique_local_links:links.size,errors},null,2));
  console.log('PASS: '+checks+' TF2 documentation/site checks');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
