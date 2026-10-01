const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const base=process.argv[2],route='/guides/cs2/custom-models/';
const out=__dirname;let checks=0;const errors=[],links=new Set();
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({locale:'en-US',reducedMotion:'reduce'});
 await context.addInitScript(()=>{localStorage.setItem('scooby.lang','en');});
 const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base)&&r.status()>=400)errors.push(r.status()+' '+r.url());});
 const go=async p=>{const r=await page.goto(base+p,{waitUntil:'networkidle'});assert.equal(r.status(),200);checks++;const choice=page.getByRole('button',{name:'Continue in English',exact:true});if(await choice.isVisible())await choice.click();};
 try{
  for(const width of [1440,375]){
   await page.setViewportSize({width,height:1000});await go(route);
   assert.equal(await page.locator('h1').innerText(),'Custom Models');checks++;
   assert((await page.locator('#main-content').innerText()).includes('C:\\Program Files (x86)\\Steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\'));checks++;
   assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));checks++;
   for(const theme of ['light','dark']){
    await page.locator('#theme-select').selectOption(theme);
    assert.equal(await page.locator('html').getAttribute('data-theme'),theme);checks++;
    await page.screenshot({path:path.join(out,`guide-${theme}-${width}.png`)});
   }
   for(const href of await page.locator('main a[href]').evaluateAll(es=>es.map(e=>e.getAttribute('href'))))if(href.startsWith('/')||href.startsWith('#'))links.add(href);
   await page.locator('.guide-contents a[href="#self"]').click();assert.equal(new URL(page.url()).hash,'#self');checks++;
   assert(await page.locator('#self').isVisible());checks++;
   await go('/guides/cs2/');const card=page.locator('main .topic-card[href="'+route+'"]');assert(await card.isVisible());checks++;
   await card.click();assert.equal(new URL(page.url()).pathname,route);checks++;
   if(width===375){await page.locator('.menu-toggle').click();assert(await page.locator('#wiki-sidebar a[href="'+route+'"]').isVisible());checks++;await page.keyboard.press('Escape');}
   for(const query of ['custom models','hands','game csgo']){
    await page.keyboard.press('Control+k');await page.locator('#guide-search').fill(query);
    await page.locator('#guide-results a[href="'+route+'"]').waitFor();checks++;
    await page.keyboard.press('Escape');await page.locator('#search-dialog').waitFor({state:'hidden'});
   }
  }
  await page.setViewportSize({width:1440,height:1000});await go('/guides/');
  const hub=page.locator('main .topic-card[href="'+route+'"]');assert(await hub.isVisible());checks++;
  await hub.click();assert.equal(new URL(page.url()).pathname,route);checks++;
  for(const href of links){const url=new URL(href.startsWith('#')?route+href:href,base);const res=await context.request.get(url.origin+url.pathname);assert.equal(res.status(),200);checks++;
   if(url.hash){const html=await res.text();assert(html.includes('id="'+decodeURIComponent(url.hash.slice(1))+'"'));checks++;}}
  const noJs=await browser.newContext({javaScriptEnabled:false,viewport:{width:375,height:1000}});const staticPage=await noJs.newPage();await staticPage.goto(base+route);
  assert(await staticPage.locator('#install-folder').isVisible());assert(await staticPage.locator('#wiki-sidebar a[href="'+route+'"]').isVisible());checks+=2;
  await staticPage.locator('.guide-contents a[href="#players"]').click();assert.equal(new URL(staticPage.url()).hash,'#players');checks++;await noJs.close();
  assert.deepEqual(errors,[]);checks++;
  fs.writeFileSync(path.join(out,'browser-result.json'),JSON.stringify({checks,passed:true,localLinks:links.size,errors,base,route},null,2));
  console.log('PASS:',checks,'guide layout, theme, mobile navigation, search, links and no-JavaScript checks');
 }finally{await context.close();await browser.close();}
})().catch(e=>{fs.writeFileSync(path.join(out,'browser-failure.txt'),String(e.stack||e));console.error(e);process.exitCode=1;});
