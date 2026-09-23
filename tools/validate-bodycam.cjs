const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
(async () => {
 const output=path.resolve(process.argv[2] || 'artifacts/bodycam');fs.mkdirSync(output,{recursive:true});
 const base=process.env.BODYCAM_PREVIEW_URL || 'http://127.0.0.1:8195';
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const page=await browser.newPage();const errors=[];const failed=[];let checks=0;
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.url().startsWith(base) && r.status()>=400) failed.push(r.url()+': '+r.status());});
 const check=(value,msg)=>{assert.ok(value,msg);checks++;};
 try {
  for(const viewport of [{width:1440,height:1000},{width:390,height:844}]) {
   await page.setViewportSize(viewport);await page.goto(base+'/products/bodycam/',{waitUntil:'networkidle'});
   check(await page.title()==='Bodycam — Free · Coming Soon - Scooby','Bodycam title');
   check(await page.getByRole('heading',{name:'Bodycam',exact:true}).count()===1,'One Bodycam heading');
   check(await page.getByRole('button',{name:'Coming soon',exact:true}).isDisabled(),'Unavailable product has no purchase/load action');
   check(await page.locator('.bodycam-free').innerText()==='Free','Explicit free access');
   const images=await page.locator('.bodycam-hero img').evaluateAll(els=>els.every(e=>e.complete && e.naturalWidth>0));
   check(images,'Both Bodycam art layers load');
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow');
   await page.screenshot({path:path.join(output,'bodycam-site-'+viewport.width+'.png'),fullPage:true});
   if(viewport.width<600) {
    const toggle=page.locator('#hamburgerBtn');await toggle.click();
    check(await toggle.getAttribute('aria-expanded')==='true','Mobile menu opens');
    check(await page.locator('#navLinks a[href="/#products"]').isVisible(),'Mobile products link visible');
    await toggle.click();
   }
  }
  await page.setViewportSize({width:1440,height:1000});
  await page.goto(base+'/',{waitUntil:'networkidle'});
  const language=page.getByRole('button',{name:'Continue in English'});
  if(await language.isVisible()) await language.click();
  const card=page.locator('a[data-product="bodycam"]');await card.scrollIntoViewIfNeeded();
  check((await card.innerText()).includes('Free access') && (await card.innerText()).includes('Coming soon'),'Homepage card has correct status');
  await card.screenshot({path:path.join(output,'bodycam-home-card.png')});
  await card.click();await page.waitForURL('**/products/bodycam/');check(true,'Homepage opens Bodycam page');
  await page.goto(base+'/products/free/',{waitUntil:'networkidle'});
  const upcoming=page.locator('article[data-product="bodycam"]');await upcoming.scrollIntoViewIfNeeded();
  check(await upcoming.locator('a').getAttribute('href')==='/products/bodycam/','Upcoming free card routes to Bodycam');
  await upcoming.screenshot({path:path.join(output,'bodycam-free-card.png')});
  check(failed.length===0,'No failed local assets: '+failed.join(', '));check(errors.length===0,'No page errors: '+errors.join(', '));
  fs.writeFileSync(path.join(output,'site-validation.json'),JSON.stringify({checks,failed,errors,viewports:[1440,390],url:base+'/products/bodycam/'},null,2));
  console.log('PASS: '+checks+' Bodycam site checks.');
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
