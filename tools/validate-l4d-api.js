const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const http = require('http');

(async () => {
  const root = path.resolve(__dirname,'..');
  const output = path.resolve(process.argv[2] || 'build/l4d-api-validation');
  fs.mkdirSync(output,{recursive:true});
  let server;
  let base = process.env.L4D_API_BASE;
  if (!base) {
    server = http.createServer((request,response) => {
      let file = path.resolve(root,'.'+decodeURIComponent(new URL(request.url,'http://localhost').pathname));
      if (!file.startsWith(root+path.sep)) { response.writeHead(403); response.end(); return; }
      try {
        if (fs.statSync(file).isDirectory()) file=path.join(file,'index.html');
        const mime={'.html':'text/html; charset=utf-8','.css':'text/css','.js':'text/javascript','.json':'application/json','.png':'image/png','.webp':'image/webp','.md':'text/plain; charset=utf-8'};
        response.writeHead(200,{'Content-Type':mime[path.extname(file)] || 'application/octet-stream'});
        response.end(fs.readFileSync(file));
      } catch { response.writeHead(404); response.end(); }
    });
    await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
    base='http://127.0.0.1:'+server.address().port;
  }
  const browser=await chromium.launch({channel:'msedge',headless:true});
  try {
    const context=await browser.newContext({viewport:{width:1440,height:1000},permissions:['clipboard-read','clipboard-write']});
    // A language already chosen keeps the first-visit picker from covering the page.
    await context.addInitScript(()=>{try{localStorage.setItem('scooby.lang','en');}catch{}});
    const errors=[];
    context.on('page',p=>p.on('pageerror',e=>errors.push(e.message)));
    const page=await context.newPage();
    await page.goto(base+'/docs/',{waitUntil:'networkidle'});
    const sidebarLink=page.locator('.wiki-sidebar a[href="/api/l4d_api_reference.html"]');
    assert.equal(await sidebarLink.getAttribute('target'),'_blank');
    const [api]=await Promise.all([context.waitForEvent('page'),sidebarLink.click()]);
    await api.waitForLoadState('networkidle');
    assert.equal(new URL(page.url()).pathname,'/docs/');
    assert.equal(new URL(api.url()).pathname,'/api/l4d_api_reference.html');
    assert.equal(await api.evaluate(()=>window.opener),null);
    assert.equal(await api.locator('h1').textContent(),'Left 4 Dead Lua API');
    const allCount=await api.locator('.reference-entry').count();
    assert.ok(allCount>30);
    const broken=await api.evaluate(()=>[...document.querySelectorAll('a[href^="#"]')].filter(a=>!document.getElementById(a.hash.slice(1))).map(a=>a.hash));
    assert.deepEqual(broken,[]);
    await api.screenshot({path:path.join(output,'api-desktop.png')});
    await api.locator('.lua-reference pre button').first().click();
    await api.getByRole('button',{name:'Copied',exact:true}).waitFor();
    assert.ok((await api.evaluate(()=>navigator.clipboard.readText())).includes('ui.overlay'));
    const input=api.getByRole('searchbox',{name:'Search the reference'});
    await input.fill('l4d.session');
    assert.ok(await api.locator('.reference-entry:visible').count()>0);
    assert.ok(await api.locator('.reference-entry:visible').count()<allCount);
    assert.ok((await api.locator('.reference-entry:visible').allTextContents()).every(t=>t.toLowerCase().includes('l4d.session')));
    await api.screenshot({path:path.join(output,'api-search.png')});
    await input.fill('no_such_function_93847');
    assert.equal(await api.locator('.reference-entry:visible').count(),0);
    assert.ok(await api.locator('#no-results').isVisible());
    await api.getByRole('button',{name:'Clear search',exact:true}).click();
    assert.equal(await api.locator('.reference-entry:visible').count(),allCount);
    await api.goto(base+'/docs/l4d/?from=bookmark#game-api-5',{waitUntil:'networkidle'});
    assert.equal(new URL(api.url()).pathname,'/api/l4d_api_reference.html');
    assert.equal(new URL(api.url()).search,'?from=bookmark');
    assert.equal(new URL(api.url()).hash,'#game-api-5');
    assert.ok(await api.locator('#game-api-5').isVisible());
    await api.setViewportSize({width:390,height:844});
    await api.goto(base+'/api/l4d_api_reference.html',{waitUntil:'networkidle'});
    assert.equal(await api.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
    const toggle=api.getByRole('button',{name:'Sections',exact:true});
    await toggle.click(); assert.equal(await toggle.getAttribute('aria-expanded'),'true');
    await api.locator('#sidebar-nav a[href="#game-api-5"]').click();
    assert.equal(await toggle.getAttribute('aria-expanded'),'false');
    await api.screenshot({path:path.join(output,'api-mobile.png')});
    for(const route of ['/products/l4d/','/guides/l4d/','/guides/l4d/menu-settings/']) {
      await page.goto(base+route,{waitUntil:'domcontentloaded'});
      const attrs=await page.locator('a[href="/api/l4d_api_reference.html"]').evaluateAll(links=>links.map(a=>({target:a.target,rel:a.rel})));
      assert.ok(attrs.length>0,route); assert.ok(attrs.every(a=>a.target==='_blank'&&a.rel.includes('noopener')),route);
    }
    await page.goto(base+'/docs/',{waitUntil:'networkidle'});
    await page.locator('[data-search-open]').click();
    await page.locator('#guide-search').fill('l4d.session');
    await page.locator('#guide-results a[href^="/api/l4d_api_reference.html"]').first().waitFor();
    assert.equal(await page.locator('#guide-results a').first().getAttribute('target'),'_blank');
    await api.goto(base+'/api/l4d_api_reference.html',{waitUntil:'networkidle'});
    for(const a of await api.locator('a[download]').all()){
      const response=await context.request.get(base+await a.getAttribute('href')); assert.equal(response.status(),200);
    }
    assert.deepEqual(errors,[]);
    const report={passed:true,topics:allCount,checks:['new tab and isolated opener','original docs tab retained','reference anchors','clipboard copy','search and no-results reset','old URL/query/bookmark redirect','mobile navigation and overflow','product/guide new-tab links','docs search new-tab links','Markdown downloads','no page errors']};
    fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
  } finally { await browser.close(); if(server)await new Promise(resolve=>server.close(resolve)); }
})().catch(error=>{console.error(error);process.exitCode=1;});
