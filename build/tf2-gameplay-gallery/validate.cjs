const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),assert=require('node:assert/strict'),crypto=require('node:crypto'),{spawn}=require('node:child_process');
const {chromium}=require('playwright');
const root=process.cwd(),output=path.join(root,'build/tf2-gameplay-gallery');
const types={'.html':'text/html','.css':'text/css','.js':'text/javascript','.json':'application/json','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.woff2':'font/woff2'};
const server=http.createServer((req,res)=>{try{let file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(!file.startsWith(root+path.sep)&&file!==root){res.writeHead(403).end();return;}if(fs.statSync(file).isDirectory())file=path.join(file,'index.html');res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(res);}catch{res.writeHead(404).end();}});
(async()=>{let browser;await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;const errors=[];let checked=0;
try{
 const manifest=JSON.parse(fs.readFileSync('tools/previews/tf2.json','utf8'));
 for(const shot of manifest.screenshots){assert.equal(shot.kind,'in-game');for(const file of [shot,...shot.variants])assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file.file))).digest('hex'),file.sha256);checked++;}
 browser=await chromium.launch({channel:'msedge',headless:true});const page=await browser.newPage({reducedMotion:'reduce'});await page.addInitScript(()=>localStorage.setItem('scooby.lang','en'));page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().startsWith(base)&&r.status()>=400)errors.push(r.status()+' '+r.url());});
 for(const width of [1440,375,320]){
  await page.setViewportSize({width,height:1000});await page.goto(base+'/products/tf2/',{waitUntil:'networkidle'});
  const gallery=page.locator('.screenshot-gallery'),links=page.locator('[data-tf2-preview]');assert.equal(await links.count(),manifest.screenshots.length);
  assert.equal(await gallery.locator('.preview-caption').count(),0);assert.equal(await page.locator('#lightbox figcaption,#lightbox-caption').count(),0);
  assert.equal(await gallery.innerText(),'');assert(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1));
  for(let i=0;i<manifest.screenshots.length;i++){
   const a=links.nth(i),img=a.locator('img'),shot=manifest.screenshots[i];await a.scrollIntoViewIfNeeded();await img.evaluate(i=>i.decode());
   assert.equal(await a.getAttribute('href'),shot.file);assert.equal(await img.getAttribute('alt'),shot.alt);
   assert(await img.evaluate(i=>i.complete && i.naturalWidth>0 && i.naturalHeight>0));await a.click();await page.locator('#lightbox-img').evaluate(i=>i.decode());assert.deepEqual(await page.locator('#lightbox-img').evaluate(i=>[i.naturalWidth,i.naturalHeight]),shot.dimensions);assert.equal(await page.locator('#lightbox-img').getAttribute('src'),new URL(shot.file,base).href);
   await page.keyboard.press('ArrowRight');assert.equal(await page.locator('#lightbox-img').getAttribute('src'),new URL(manifest.screenshots[(i+1)%manifest.screenshots.length].file,base).href);
   await page.keyboard.press('Escape');assert(!await page.locator('#lightbox').isVisible());assert(await a.evaluate(e=>e===document.activeElement));checked++;
  }
  await page.evaluate(()=>document.activeElement?.blur());await page.mouse.move(0,0);await gallery.screenshot({path:path.join(output,'gallery-'+width+'.png')});checked++;
 }
 assert.deepEqual(errors,[]);fs.writeFileSync(path.join(output,'gallery-validation.json'),JSON.stringify({passed:checked,widths:[1440,375,320],images:manifest.screenshots.length,visibleCaptions:0,errors},null,2));
 await browser.close();browser=null;
 await new Promise((resolve,reject)=>{const child=spawn(process.execPath,['tools/validate-tf2.js'],{cwd:root,env:{...process.env,TF2_SITE_BASE:base},stdio:'pipe'});const out=fs.createWriteStream(path.join(output,'product-validation.log'));child.stdout.pipe(out);child.stderr.pipe(out);child.on('exit',code=>code===0?resolve():reject(new Error('Product validation failed: '+code)));child.on('error',reject);});
 console.log('PASS: '+checked+' gallery checks; existing full TF2 product validation passed.');
}finally{if(browser)await browser.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;server.close();});
