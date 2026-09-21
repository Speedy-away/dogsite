const {chromium}=require('playwright');
const fs=require('fs'),path=require('path');
(async()=>{
 const output=process.argv[2];fs.mkdirSync(output,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000},permissions:['clipboard-read','clipboard-write']});
 const page=await context.newPage();const failures=[];const errors=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.url().startsWith('http://127.0.0.1:8184')&&r.status()>=400)failures.push(r.status()+' '+r.url());});
 const base='http://127.0.0.1:8184';
 await page.goto(base+'/products/l4d/',{waitUntil:'networkidle'});
 if(await page.locator('.i18n-modal-overlay.show').count()) await page.locator('.i18n-modal-overlay.show button[data-lang="en"]').click();
 await page.screenshot({path:path.join(output,'product-desktop.png'),fullPage:true});
 if(!await page.getByRole('heading',{name:'LEFT 4 DEAD',exact:true}).isVisible())throw Error('Missing product title');
 await page.locator('.screenshot-item').first().click();await page.locator('#lightbox.active').waitFor();await page.keyboard.press('Escape');
 await page.getByRole('link',{name:'Get Free Key',exact:true}).click();await page.locator('#freeKeyModal.active').waitFor();await page.locator('#freeKeyBtn:not([disabled])').waitFor();
 if((await page.locator('#freeKeyBtn').getAttribute('href')).includes('product=l4d'))throw Error('Unconfigured L4D key policy');
 await page.keyboard.press('Escape');
 await page.setViewportSize({width:390,height:844});await page.screenshot({path:path.join(output,'product-mobile.png'),fullPage:true});
 const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+2);if(overflow)throw Error('Product mobile horizontal overflow');
 await page.goto(base+'/features-list/l4d-features/',{waitUntil:'networkidle'});await page.locator('#feature-search').fill('witch');
 await page.waitForFunction(()=>document.querySelector('#result-count').textContent.includes('match your search'));
 if(!await page.locator('.feature-item:visible').count())throw Error('No Witch search results');
 await page.screenshot({path:path.join(output,'features-mobile.png'),fullPage:true});
 await page.goto(base+'/docs/l4d/',{waitUntil:'networkidle'});await page.locator('.lua-reference pre button').first().click();
 await page.getByRole('button',{name:'Copied',exact:true}).waitFor();
 const copied=await page.evaluate(()=>navigator.clipboard.readText());if(!copied.includes('ui.overlay'))throw Error('Wrong copied snippet');
 await page.screenshot({path:path.join(output,'docs-mobile.png'),fullPage:false});
 if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+2))throw Error('Docs mobile horizontal overflow');
 for(const route of ['/guides/l4d/','/guides/l4d/getting-started/','/guides/l4d/requirements/','/guides/l4d/menu-settings/','/guides/l4d/troubleshooting/','/docs/','/guides/','/store/','/']){
  await page.goto(base+route,{waitUntil:'domcontentloaded'});
  if(!await page.locator('a[href*="/l4d"]').count())throw Error('No L4D discovery link: '+route);
 }
 await page.setViewportSize({width:1440,height:1000});await page.goto(base+'/products/l4d/',{waitUntil:'networkidle'});
 await page.screenshot({path:path.join(output,'product-overview.png')});
 await browser.close();
 const report={passed:!failures.length&&!errors.length,failures,errors,checks:['product desktop/mobile','in-game gallery lightbox','free-key popup/link','feature search','API snippet copy','wiki and site navigation']};
 fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));if(!report.passed)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
