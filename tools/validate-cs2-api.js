const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const http = require('http');

(async () => {
  const root = path.resolve(__dirname,'..');
  const output = path.resolve(process.argv[2] || 'build/cs2-api-validation');
  fs.mkdirSync(output,{recursive:true});
  let server;
  let base = process.env.CS2_API_BASE;
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
    const sidebarLink=page.locator('.wiki-sidebar a[href="/api/cs2/"]');
    assert.equal(await sidebarLink.getAttribute('target'),'_blank');
    const [api]=await Promise.all([context.waitForEvent('page'),sidebarLink.click()]);
    await api.waitForLoadState('networkidle');
    assert.equal(new URL(page.url()).pathname,'/docs/');
    assert.equal(new URL(api.url()).pathname,'/api/cs2/');
    assert.equal(await api.evaluate(()=>window.opener),null);
    assert.equal(await api.locator('h1').textContent(),'CS2 Lua API');
    const allCount=await api.locator('.reference-entry').count();
    assert.ok(allCount>30);
    const broken=await api.evaluate(()=>[...document.querySelectorAll('a[href^="#"]')].filter(a=>!document.getElementById(a.hash.slice(1))).map(a=>a.hash));
    assert.deepEqual(broken,[]);
    await api.screenshot({path:path.join(output,'api-desktop.png')});
    await api.locator('.lua-reference pre button').first().click();
    await api.getByRole('button',{name:'Copied',exact:true}).waitFor();
    assert.ok((await api.evaluate(()=>navigator.clipboard.readText())).includes('ui.overlay'));
    assert.ok(await api.locator('details.reference-entry:not([open])').count()>0);
    const input=api.getByRole('searchbox',{name:'Search the reference'});
    await input.fill('entity.get_local_player');
    assert.ok(await api.locator('.reference-entry:visible').count()>0);
    assert.ok(await api.locator('.reference-entry:visible').count()<allCount);
    assert.ok((await api.locator('.reference-entry:visible').allTextContents()).every(t=>t.toLowerCase().includes('entity.get_local_player')));
    await api.screenshot({path:path.join(output,'api-search.png')});
    await input.fill('native.hook');
    assert.ok(await api.locator('.reference-entry:visible').count()>0);
    assert.ok((await api.locator('.reference-entry:visible').allTextContents()).some(t=>t.includes('callback_source')));
    const nativeEntry=api.locator('#host-native-hook');
    if(await nativeEntry.getAttribute('open')===null)await nativeEntry.locator('summary').click();
    await nativeEntry.locator('pre button').click();
    assert.ok((await api.evaluate(()=>navigator.clipboard.readText())).includes('native.hook'));
    await api.screenshot({path:path.join(output,'native-hook.png')});
    for(const term of ['commands.create','inventory.finishes','model_preview.draw','fs.load','http.request','cs2.permissions','console.trace','mathx.damp','utils.base64_decode','json.null','imgui.with_style_vars','widgets.selectable']) {
      await input.fill(term);
      assert.ok(await api.locator('.reference-entry:visible').count()>0,term);
    }
    await input.fill('Console diagnostics');
    const diagnostic=api.locator('#host-console-diagnostics');
    if(await diagnostic.getAttribute('open')===null)await diagnostic.locator('summary').click();
    assert.ok((await diagnostic.textContent()).includes('stack trace'));
    await api.screenshot({path:path.join(output,'diagnostics.png')});
    const catalog=await (await context.request.get(base+'/docs/cs2/api-catalog.json')).json();
    assert.equal(catalog.host_api,'2.4');assert.ok(catalog.functions.length>=247);
    const editor=await (await context.request.get(base+'/docs/cs2/cs2_v2.lua')).text();
    for(const entry of catalog.functions)assert.ok(editor.includes('function '+entry.name+'('),entry.name);
    const coverage=await (await context.request.get(base+'/docs/cs2/coverage.md')).text();
    assert.ok(coverage.includes('Not exposed')&&coverage.includes('not drop-in compatibility'));
    await input.fill('no_such_function_93847');
    assert.equal(await api.locator('.reference-entry:visible').count(),0);
    assert.ok(await api.locator('#no-results').isVisible());
    await api.getByRole('button',{name:'Clear search',exact:true}).click();
    assert.equal(await api.locator('.reference-entry:visible').count(),allCount);
    await api.goto(base+'/api/cs2/#host-entity-get-local-player',{waitUntil:'networkidle'});
    assert.ok(await api.locator('#host-entity-get-local-player').getAttribute('open')!==null);
    await api.setViewportSize({width:390,height:844});
    await api.goto(base+'/api/cs2/',{waitUntil:'networkidle'});
    assert.equal(await api.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
    const toggle=api.getByRole('button',{name:'Sections',exact:true});
    await toggle.click(); assert.equal(await toggle.getAttribute('aria-expanded'),'true');
    await api.locator('#sidebar-nav a[href="#host-entity-get-local-player"]').click();
    assert.equal(await toggle.getAttribute('aria-expanded'),'false');
    await api.screenshot({path:path.join(output,'api-mobile.png')});
    await page.goto(base+'/docs/cs2/',{waitUntil:'networkidle'});
    await page.screenshot({path:path.join(output,'templates-desktop.png')});
    for(const a of await page.locator('a[download]').all()){
      const response=await context.request.get(base+await a.getAttribute('href'));assert.equal(response.status(),200);
    }
    await page.setViewportSize({width:390,height:844});
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
    await page.screenshot({path:path.join(output,'templates-mobile.png'),fullPage:true});
    await page.setViewportSize({width:1440,height:1000});
    await page.goto(base+'/docs/',{waitUntil:'networkidle'});
    await page.locator('[data-search-open]').click();
    await page.locator('#guide-search').fill('entity.get_local_player');
    await page.locator('#guide-results a[href^="/api/cs2/"]').first().waitFor();
    assert.equal(await page.locator('#guide-results a').first().getAttribute('target'),'_blank');
    await api.goto(base+'/api/cs2/',{waitUntil:'networkidle'});
    for(const a of await api.locator('a[download]').all()){
      const response=await context.request.get(base+await a.getAttribute('href')); assert.equal(response.status(),200);
    }
    // Every local route in the two pages resolves, including API source downloads.
    const routes=new Set();
    for(const route of ['/api/cs2/','/docs/cs2/']) {
      await page.goto(base+route,{waitUntil:'networkidle'});
      for(const href of await page.locator('a[href^="/"]').evaluateAll(links=>links.map(a=>a.getAttribute('href')))) routes.add(href);
    }
    for(const route of routes){const response=await context.request.get(base+route);assert.equal(response.status(),200,route);}
    assert.deepEqual(errors,[]);
    const report={passed:true,topics:allCount,checks:['new tab and isolated opener','original docs tab retained','reference anchors','clipboard copy','native hook search and example copy','diagnostics utility animation and widget search','all catalog editor definitions','explicit coverage gaps','search and no-results reset','collapsed entry deep link opens','mobile navigation and overflow','template downloads and mobile layout','docs search new-tab links','Markdown downloads','no page errors']};
    fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
  } finally { await browser.close(); if(server)await new Promise(resolve=>server.close(resolve)); }
})().catch(error=>{console.error(error);process.exitCode=1;});
