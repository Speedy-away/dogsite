const fs=require('fs'),path=require('path'),http=require('http'),assert=require('assert/strict');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..'),out=path.join(root,'build/rdr2-docs-validation');
const mime={'.html':'text/html','.css':'text/css','.js':'text/javascript','.json':'application/json','.png':'image/png','.svg':'image/svg+xml','.webp':'image/webp','.md':'text/plain','.lua':'text/plain','.zip':'application/zip'};
const server=http.createServer((req,res)=>{
 let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname);}catch{res.writeHead(400).end();return;}
 let file=path.resolve(root,'.'+url);
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 try{if(fs.statSync(file).isDirectory())file=path.join(file,'index.html');res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(fs.readFileSync(file));}
 catch{res.writeHead(404).end('Not found');}
});
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const base='http://127.0.0.1:'+server.address().port;
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const errors=[],links=new Set();let checks=0;
 try{
  const context=await browser.newContext({reducedMotion:'reduce'});
  await context.grantPermissions(['clipboard-read','clipboard-write'],{origin:base});
  const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
  for(const width of [1440,375]){
   await page.setViewportSize({width,height:960});
   for(const route of ['/docs/rdr2/','/api/rdr2/']){
    const response=await page.goto(base+route,{waitUntil:'networkidle'});assert.equal(response.status(),200);checks++;
    assert.equal(await page.locator('h1').count(),1);checks++;
    assert(!(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1)),'horizontal overflow');checks++;
    const ids=await page.locator('[id]').evaluateAll(nodes=>nodes.map(n=>n.id));assert.equal(ids.length,new Set(ids).size);checks++;
    assert.equal(await page.locator('link[rel=canonical]').getAttribute('href'),'https://scoobymenu.cc'+route);checks++;
    if(width===1440)for(const url of await page.locator('a[href],script[src],link[rel=stylesheet]').evaluateAll(nodes=>nodes.map(n=>n.getAttribute('href')||n.getAttribute('src')))){
     const u=new URL(url,base+route);if(u.origin===base)links.add(u.pathname+u.hash);
    }
    await page.screenshot({path:path.join(out,route.split('/')[1]+'-'+width+'.png')});
   }
  }
  await page.setViewportSize({width:1440,height:960});
  await page.goto(base+'/api/rdr2/#host-keyboard-and-controller-window-bindings',{waitUntil:'networkidle'});
  assert(await page.locator('#host-keyboard-and-controller-window-bindings').evaluate(n=>n.open));checks++;
  await page.locator('#api-search').fill('Input.createToggle');
  assert.equal(await page.locator('.reference-entry:visible').count(),1);checks++;
  await page.locator('.reference-entry:visible pre button').first().click();
  assert((await page.evaluate(()=>navigator.clipboard.readText())).includes('Input.createToggle'));checks++;
  await page.locator('#api-search').fill('NO_MATCH_XYZ');assert(await page.locator('#no-results').isVisible());checks++;
  await page.locator('#clear-search').click();
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'docs/rdr2/source-manifest.json'),'utf8'));
  assert.equal(await page.locator('.reference-entry').count(),manifest.reference_entries);checks++;
  await page.locator('#api-search').fill('PLAYER_PED_ID');assert(await page.locator('.reference-entry:visible').count()>0);checks++;
  await page.setViewportSize({width:375,height:800});await page.locator('.menu-toggle').click();
  assert.equal(await page.locator('.menu-toggle').getAttribute('aria-expanded'),'true');checks++;
  await page.keyboard.press('Escape');assert.equal(await page.locator('.menu-toggle').getAttribute('aria-expanded'),'false');checks++;
  for(const route of ['/docs/rdr2/Frontier/main.lua','/docs/rdr2/Frontier/frontier/model.lua','/docs/rdr2/Frontier/frontier/view.lua','/docs/rdr2/runtime-api.md','/docs/rdr2/native-catalog.json']){
   const response=await context.request.get(base+route);assert.equal(response.status(),200);assert((await response.body()).length>100);checks++;
  }
  const zip=await context.request.get(base+'/docs/rdr2/Frontier.zip');assert.equal(zip.status(),200);assert.equal((await zip.body()).readUInt32LE(0),0x04034b50);checks++;
  for(const url of links){
   const u=new URL(url,base),response=await context.request.get(base+u.pathname);assert.equal(response.status(),200,'Broken link '+url);checks++;
   if(u.hash&&u.pathname==='/api/rdr2/')assert((await response.text()).includes('id="'+decodeURIComponent(u.hash.slice(1))+'"'));
  }
  await context.close();
  const plain=await browser.newContext({javaScriptEnabled:false});const nojs=await plain.newPage();
  await nojs.goto(base+'/api/rdr2/');assert(await nojs.locator('#sidebar-nav').isVisible());checks++;await plain.close();
  assert.deepEqual(errors,[]);
  fs.writeFileSync(path.join(out,'acceptance.json'),JSON.stringify({checks,errors,api:manifest.api,fixtureOnly:true},null,2));
  console.log('PASS '+checks+' RDR2 docs browser/link/download checks');
 }finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(e=>{console.error(e);server.close();process.exitCode=1});
