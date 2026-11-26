/* Scoped read-only browser checks: no site generators, real downloads or ads. */
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),http=require('node:http'),crypto=require('node:crypto');
const site=process.env.SCOOBY_SITE_ROOT||path.resolve(__dirname,'..');
const stage=process.env.SCOOBY_SITE_STAGE;
const update=process.env.SCOOBY_UPDATE_ROOT||path.resolve(site,'../scooby-manager-update');
const {chromium}=require(path.join(site,'node_modules/playwright'));
const {isPublic}=require(path.join(site,'tools/site-layout.cjs'));
const server=http.createServer((req,res)=>{
 const relative=decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/^\/+/, '');
 if(!isPublic(relative)){res.writeHead(404).end();return;}
 let file=path.resolve(site,relative);if(!file.startsWith(path.resolve(site)+path.sep)){res.writeHead(403).end();return;}
 if(fs.existsSync(file)&&fs.statSync(file).isDirectory())file=path.join(file,'index.html');
 if(stage){const candidate=path.join(stage,path.relative(site,file));if(fs.existsSync(candidate))file=candidate;}
 if(!fs.existsSync(file)){res.writeHead(404).end();return;}
 const type={'.html':'text/html','.js':'text/javascript','.css':'text/css','.json':'application/json','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.svg':'image/svg+xml','.woff2':'font/woff2'}[path.extname(file)]||'application/octet-stream';
 res.setHeader('Content-Type',type);fs.createReadStream(file).pipe(res);
});
async function main(){
 const release=JSON.parse(fs.readFileSync(path.join(update,'games/r6/version.json'),'utf8'));assert.equal(release.version,'1.0.3');assert.equal(release.files.length,2);
 for(const file of release.files){const url=new URL(file.url),relative=url.pathname.replace(/^\/scooby-manager-update\//,'');const bytes=fs.readFileSync(path.join(update,relative));assert.equal(bytes.length,file.bytes);assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),file.sha256);}
 const rdr2=JSON.parse(fs.readFileSync(path.join(update,'games/rdr2/version.json')));assert.equal(rdr2.version,'1.0.0');
 const rdr2Path=new URL(rdr2.url).pathname.replace(/^\/scooby-manager-update\//,'');const rdr2Bytes=fs.readFileSync(path.join(update,rdr2Path));assert.equal(rdr2Bytes.length,rdr2.bytes);assert.equal(crypto.createHash('sha256').update(rdr2Bytes).digest('hex'),rdr2.sha256);
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const origin=`http://127.0.0.1:${server.address().port}`;
 const browser=await chromium.launch({channel:'msedge',headless:true});
 try{const context=await browser.newContext({viewport:{width:1440,height:1100},acceptDownloads:true});
  await context.route('**/*',route=>{const url=new URL(route.request().url());if(url.origin===origin){if(route.request().resourceType()==='media')return route.abort();return route.continue();}
   if(url.hostname==='github.com'&&/\.(sprx|zip)$/.test(url.pathname))return route.fulfill({contentType:'application/octet-stream',headers:{'Content-Disposition':`attachment; filename="${path.basename(url.pathname)}"`},body:'synthetic download bytes'});
   return route.fulfill({contentType:'text/html',body:'<!doctype html><title>Blocked external request</title>'});
  });
  const page=await context.newPage(),errors=[];page.on('pageerror',error=>errors.push(error.message));
  await page.goto(origin+'/console/products/r6/');
  assert.match(await page.locator('.product-heading').innerText(),/1\.0\.3/);assert.equal(await page.locator('.price-label').innerText(),'Scooby PS4 v1.0.3');
  const links=page.locator('.purchase-card a[download]');assert.equal(await links.count(),2);
  for(let i=0;i<2;++i){const link=links.nth(i),href=await link.getAttribute('href');assert.match(href,/games\/r6\/sprx\/1\.0\.3\/[a-f0-9]{12}\//);assert.ok(!href.includes('/menus/'));
   const pending=page.waitForEvent('download');await link.click();assert.equal((await pending).suggestedFilename(),await link.getAttribute('download'));
  }
  assert.match(await page.locator('meta[property="og:image:alt"]').getAttribute('content'),/1\.0\.3/);
  for(const width of [1440,390,320]){await page.setViewportSize({width,height:1100});assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`R6 fits ${width}`);}
  await page.goto(origin+'/download/#console');assert.match(await page.locator('.console-download').innerText(),/1\.0\.3/);
  await page.goto(origin+'/console/products/rdr2/');assert.match(await page.locator('.product-heading').innerText(),/Free \+ Premium[\s\S]*1\.0\.0/);
  assert.match(await page.locator('.purchase-card .price').innerText(),/\$15[\s\S]*\$10/);
  const free=page.locator('.purchase-card a[download]');assert.equal(await free.count(),1);assert.match(await free.innerText(),/Download Free Version/i);
  assert.equal(new URL(await free.getAttribute('href')).pathname.replace('/ScoobyP98/scooby-manager-update/raw/refs/heads/main/',''),rdr2Path);
  const pending=page.waitForEvent('download');await free.click();assert.equal((await pending).suggestedFilename(),'ScoobyRDR2.sprx');
  assert.match(await page.locator('#release-status').innerText(),/CUSA08519[\s\S]*01\.32/);assert.match(await page.locator('#account-setup').innerText(),/account\.json/);
  const trigger=page.locator('[data-payment-open]'),modal=page.locator('#paymentModal'),close=modal.locator('[data-payment-close]');
  assert.equal(await modal.isVisible(),false);await trigger.focus();await page.keyboard.press('Enter');assert.equal(await modal.isVisible(),true);assert.equal(await modal.getAttribute('aria-hidden'),'false');assert.equal(await trigger.getAttribute('aria-expanded'),'true');assert.equal(await close.evaluate(el=>el===document.activeElement),true,JSON.stringify(await page.evaluate(()=>({active:document.activeElement.outerHTML.slice(0,400),parent:document.getElementById('paymentModal').parentElement.tagName,close:document.querySelector('[data-payment-close]').outerHTML,hidden:document.querySelector('[data-payment-close]').checkVisibility()}))));
  assert.equal(await page.locator('main').evaluate(el=>!!el.closest('[inert]')),true);
  const paymentLinks=modal.locator('a[href]');assert.equal(await paymentLinks.count(),3);assert.equal(await page.locator('#cardPaymentLink').getAttribute('href'),'https://zscooby.myshopify.com/products/scooby-rdr2');
  for(const link of await paymentLinks.all()){assert.match(await link.getAttribute('href'),/^https:\/\//);assert.equal(await link.getAttribute('target'),'_blank');assert.match(await link.getAttribute('rel'),/noopener/);}
  await page.keyboard.press('Shift+Tab');assert.equal(await paymentLinks.last().evaluate(el=>el===document.activeElement),true);await page.keyboard.press('Tab');assert.equal(await close.evaluate(el=>el===document.activeElement),true);
  await page.keyboard.press('Escape');assert.equal(await modal.isVisible(),false);assert.equal(await trigger.evaluate(el=>el===document.activeElement),true);assert.equal(await page.locator('main').evaluate(el=>!!el.closest('[inert]')),false);assert.equal(await page.locator('body').evaluate(el=>el.style.overflow),'');
  await trigger.click();await close.click();assert.equal(await modal.isVisible(),false);await trigger.click();await modal.click({position:{x:3,y:3}});assert.equal(await modal.isVisible(),false);
  const imageUrl=await page.locator('meta[property="og:image"]').getAttribute('content');assert.match(imageUrl,/console-rdr2-v1\.0\.0\.png$/);
  const image=await fetch(origin+new URL(imageUrl).pathname);assert.equal(image.status,200);assert.equal(Buffer.from(await image.arrayBuffer()).readUInt32BE(16),1200);
  for(const width of [1440,390,320]){await page.setViewportSize({width,height:800});assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'RDR2 fits '+width);await trigger.click();await page.waitForFunction(()=>getComputedStyle(document.querySelector('#paymentModal .payment-modal-content')).opacity==='1');const bounds=await modal.locator('.payment-modal-content').boundingBox();assert.ok(bounds.x>=0&&bounds.x+bounds.width<=width&&bounds.y>=0&&bounds.y+bounds.height<=800,'Popup fits viewport');await page.keyboard.press('Escape');}
  await page.evaluate(()=>{document.activeElement.blur();window.scrollTo({top:0,behavior:'instant'});});
  if(process.env.SCOOBY_RELEASE_SCREENSHOTS){fs.mkdirSync(process.env.SCOOBY_RELEASE_SCREENSHOTS,{recursive:true});await page.setViewportSize({width:1440,height:1100});await page.screenshot({path:path.join(process.env.SCOOBY_RELEASE_SCREENSHOTS,'rdr2-desktop.png'),fullPage:true});await page.locator('.purchase-card').screenshot({path:path.join(process.env.SCOOBY_RELEASE_SCREENSHOTS,'rdr2-card.png')});await trigger.click();await page.waitForFunction(()=>getComputedStyle(document.querySelector('#paymentModal .payment-modal-content')).opacity==='1');await page.screenshot({path:path.join(process.env.SCOOBY_RELEASE_SCREENSHOTS,'rdr2-purchase.png')});await page.keyboard.press('Escape');await page.goto(origin+'/console/products/r6/');await page.locator('.purchase-card').screenshot({path:path.join(process.env.SCOOBY_RELEASE_SCREENSHOTS,'r6-card.png')});}
  assert.deepEqual(errors,[]);await context.close();console.log('PASS: R6 1.0.3 labels, matching hashed SPRX/archive links and sponsored-download behavior; RDR2 verified free download and accessible shared-product purchase popup; desktop/mobile bounds and social cards.');
 }finally{await browser.close();}
}
main().catch(error=>{console.error(error);process.exitCode=1}).finally(()=>server.close());
