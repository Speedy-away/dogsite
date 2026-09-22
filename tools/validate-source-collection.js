const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const catalog=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../assets/data/source-games.json'),'utf8'));
const placeholders=catalog.filter(game=>game.status==='placeholder');
const base=process.env.SOURCE_SITE_URL||'http://127.0.0.1:8195';
const output=process.argv[2]||path.resolve(__dirname,'../hidden_files/source-games-validation');
(async()=>{
 fs.mkdirSync(output,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const failures=[],errors=[],checks=[];
 const page=await browser.newPage({reducedMotion:'reduce'});
 page.on('pageerror',error=>errors.push(error.message));
 page.on('response',response=>{if(response.url().startsWith(base)&&response.status()>=400)failures.push(`${response.status()} ${response.url()}`)});
 for(const width of [1440,768,375,320]){
  await page.setViewportSize({width,height:1000});
  await page.goto(base+'/source-games/',{waitUntil:'networkidle'});
  assert.equal(await page.locator('h1').count(),1);
  assert.equal(await page.locator('a[href*="steampowered.com"]').count(),0);
  assert(!(await page.locator('main').innerText()).includes('View on Steam'));
  for(const removed of ['alien-swarm','condition-zero','deathmatch-classic','dota-2','half-life-alyx','hl-deathmatch-source','ricochet'])
   assert.equal(await page.locator(`[data-game="${removed}"]`).count(),0);
  assert.equal(await page.locator('[data-game][target="_blank"]').count(),0);

  assert.equal(await page.locator('[data-game]:visible').count(),15);
  assert.deepEqual(await page.locator('[data-game]').evaluateAll(cards=>cards.slice(0,3).map(c=>c.dataset.game)),['cs2','gmod','l4d']);
  assert.equal(await page.locator('[data-game="portal"]').count(),1);
  assert.equal(await page.locator('[data-game="portal"] h3').innerText(),'Portal 1 & 2');
  assert.deepEqual(await page.locator('[data-catalog-section]').evaluateAll(sections=>sections.map(section=>section.id)),['released','coming-soon']);
  assert.deepEqual(await page.locator('#released [data-game]').evaluateAll(cards=>cards.map(card=>card.dataset.game)),['cs2','gmod','l4d','sbox','half-life-1']);
  assert.equal(await page.locator('#coming-soon [data-game]').count(),10);
  assert.equal(await page.locator('#released .source-availability').filter({hasText:'Released'}).count(),5);
  assert.equal(await page.locator('#coming-soon .source-availability').filter({hasText:'Coming soon'}).count(),10);
  for(const image of await page.locator('img').all()){
   await image.scrollIntoViewIfNeeded();
   await image.evaluate(i=>i.decode());
  }
  assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),`Horizontal overflow at ${width}`);
  for(const [engine,count] of [['source',9],['source2',2],['goldsrc',4]]){
   await page.locator(`[data-engine-filter="${engine}"]`).click();
   assert.equal(await page.locator('[data-game]:visible').count(),count);
   assert.equal(await page.locator(`[data-engine-filter="${engine}"]`).getAttribute('aria-pressed'),'true');
   assert.equal(await page.locator(`[data-game]:not([data-engine="${engine}"]):visible`).count(),0);
  }
  await page.locator('[data-engine-filter="all"]').click();
  const search=page.getByRole('searchbox',{name:'Search games'});
  for(const [query,id] of [['tf2','tf2'],['CS:S','css'],['Garrys mod','gmod'],['portal 2','portal'],['HL2DM','hl2-deathmatch'],['blue shift','half-life-1']]){
   await search.fill(query);
   assert.equal(await page.locator('[data-game]:visible').count(),1,`Search ${query}`);
   assert.equal(await page.locator('[data-game]:visible').getAttribute('data-game'),id);
  }
  await search.fill('zz-no-matching-game');
  assert(await page.locator('#collection-empty').isVisible());
  assert.equal(await page.locator('[data-catalog-section]:visible').count(),0);
  await page.getByRole('button',{name:'Show all games',exact:true}).click();
  assert.equal(await page.locator('[data-game]:visible').count(),15);
  assert(await search.evaluate(el=>el===document.activeElement));
  await page.locator('[data-engine-filter="source2"]').click();
  await page.getByRole('link',{name:'Coming soon',exact:true}).click();
  assert.equal(await page.locator('[data-game]:visible').count(),15);
  assert(await page.locator('#coming-soon').isVisible());
  if(width<=768){
   await page.locator('#hamburgerBtn').click();
   assert.equal(await page.locator('#hamburgerBtn').getAttribute('aria-expanded'),'true');
   await page.keyboard.press('Escape');
   assert.equal(await page.locator('#hamburgerBtn').getAttribute('aria-expanded'),'false');
  }
  await page.evaluate(()=>{document.activeElement.blur();scrollTo(0,0)});
  await page.screenshot({path:path.join(output,`expanded-final-${width}.jpg`),type:'jpeg',quality:75});
  checks.push(`Card order, all images, filters, aliases, empty/reset, anchors and layout at ${width}px`);
 }
 await page.setViewportSize({width:1440,height:1000});
 for(const section of ['released','coming-soon']){
  await page.locator('#'+section).screenshot({path:path.join(output,`expanded-final-${section}.jpg`),type:'jpeg',quality:75,style:'#product-nav,.product-skip-link{visibility:hidden!important}'});
 }
 const links=await page.locator('a[href^="/"]').evaluateAll(nodes=>[...new Set(nodes.map(n=>n.getAttribute('href').split('#')[0]||'/'))]);
 for(const link of links){const response=await page.request.get(base+link);assert(response.ok(),`Local link failed ${link}`)}
 const schema=JSON.parse(await page.locator('script[type="application/ld+json"]').textContent());
 assert.equal(schema.mainEntity.numberOfItems,15);

 assert.equal(placeholders.length,10);
 for(const width of [1440,375,320]){
  await page.setViewportSize({width,height:1000});
  for(const game of placeholders){
   await page.goto(base+'/source-games/',{waitUntil:'networkidle'});
   await page.locator(`[data-game="${game.id}"]`).click();
   assert.equal(new URL(page.url()).pathname,game.href);
   assert.equal(await page.locator('h1').innerText(),game.name);
   assert.equal(await page.locator('.product-status').innerText(),'Coming soon');
   assert.equal(await page.locator('main .purchase-btn').count(),1);
   assert.equal(await page.locator('main .purchase-btn').getAttribute('href'),'/source-games/');
   assert.equal(await page.locator('a[href*="steampowered.com"]').count(),0);
   await page.locator('.placeholder-art img').evaluate(image=>image.decode());
   assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),`${game.href} overflow at ${width}`);
   assert.equal(await page.locator('link[rel="canonical"]').getAttribute('href'),'https://scoobymenu.cc'+game.href);
   if(game.id==='portal') assert((await page.locator('main').innerText()).includes('Portal 1 and Portal 2 share this product page.'));
   if(width!==320 && ['portal','team-fortress-classic','half-life-2-deathmatch'].includes(game.id))
    await page.screenshot({path:path.join(output,`placeholder-${game.id}-${width}.jpg`),type:'jpeg',quality:75,fullPage:true});
   await page.getByRole('link',{name:'Back to Source Games'}).click();
   assert.equal(new URL(page.url()).pathname,'/source-games/');
  }
 }
 checks.push('All ten placeholder cards open local product pages and return; Coming soon, artwork, canonical metadata and 1440/375/320px layouts');
 const noJs=await browser.newContext({javaScriptEnabled:false,reducedMotion:'reduce'});
 const fallback=await noJs.newPage();
 await fallback.goto(base+'/source-games/');
 assert.equal(await fallback.locator('[data-game]:visible').count(),15);
 assert(!await fallback.locator('.collection-tools').isVisible());
 await fallback.getByRole('link',{name:/Browse released/}).click();
 assert(fallback.url().endsWith('#released'));
 await fallback.locator('[data-game="half-life-1"]').click();
 assert(fallback.url().endsWith('/products/half-life-1/'));
 await noJs.close();
 checks.push('All local destinations HTTP 200, structured data, complete no-JavaScript catalog and product navigation');
 assert.deepEqual(errors,[]);assert.deepEqual(failures,[]);
 await browser.close();
 const result={passed:true,checks,errors,failures};
 fs.writeFileSync(path.join(output,'source-collection-results.json'),JSON.stringify(result,null,2));
 console.log(JSON.stringify(result,null,2));
})().catch(error=>{console.error(error);process.exit(1)});
