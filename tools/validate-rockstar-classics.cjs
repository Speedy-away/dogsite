const assert = require('node:assert/strict');
const fs = require('node:fs');
const { createServer } = require('./preview.cjs');
const { chromium } = require('playwright');
const catalog = require('../assets/data/rockstar-classics.json');
(async () => {
  assert.deepEqual(catalog.games.map(g => g.id), ['gta-sa','gta-vc','gta3','gta4','rdr1']);
  assert.deepEqual(catalog.excluded, ['mta-sa']);
  assert.equal(new Set(catalog.games.map(g => g.settingsDirectory)).size, 5);
  for (const game of catalog.games) {
    assert.equal(game.runtimeAccepted, false);
    const html = fs.readFileSync(`products/${game.id}/index.html`, 'utf8');
    if (game.id !== 'gta-sa') assert(html.includes(game.settingsDirectory));
    if (game.id === 'gta-sa') {
      assert.equal(game.state, 'beta');
      assert.equal(game.releaseArtifact.channel, 'beta');
      assert.equal(game.releaseArtifact.runtimeAccepted, false);
      assert(html.includes(game.releaseArtifact.url));
      assert(!html.includes('class="classic-release"'));
      assert(html.includes('Online'));
      assert(html.includes('Live gameplay and performance acceptance are pending'));
    } else {
      assert.equal(game.releaseArtifact, null);
      assert(!/download=|\.dll|\.exe|data-free|data-product=/.test(html));
    }
  }
  const server = createServer();
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  let browser;
  try {
    browser = await chromium.launch({channel:'msedge',headless:true});
    const page = await browser.newPage();
    const errors=[];
    page.on('pageerror', error=>errors.push(error.message));
    const base=`http://127.0.0.1:${server.address().port}`;
    fs.mkdirSync('project/build/rockstar-classics',{recursive:true});
    for(const width of [1440,390]) {
      await page.setViewportSize({width,height:900});
      await page.goto(base+'/rockstar-classics/');
      await page.locator('.collection-tools').waitFor({state:'visible'});
      assert.equal(await page.locator('[data-game]:visible').count(),5);
      await page.getByRole('button',{name:'Released',exact:true}).click();
      assert.equal(await page.locator('[data-game]:visible').count(),1);
      assert.equal(await page.locator('[data-game]:visible').getAttribute('data-game'),'gta-sa');
      await page.getByRole('button',{name:'Coming soon',exact:true}).click();
      assert.equal(await page.locator('[data-game]:visible').count(),4);
      await page.getByRole('button',{name:'All games',exact:true}).click();
      await page.getByRole('searchbox').fill('Vice City');
      assert.equal(await page.locator('[data-game]:visible').count(),1);
      await page.getByRole('searchbox').fill('not-a-title');
      assert.equal(await page.locator('#collection-empty').isVisible(),true);
      await page.getByRole('button',{name:'Show all games'}).click();
      assert.equal(await page.locator('[data-game]:visible').count(),5);
      assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
      await page.evaluate(()=>{document.activeElement.blur();window.scrollTo({top:0,behavior:'instant'});});
      await page.screenshot({path:`project/build/rockstar-classics/collection-${width}.png`,fullPage:true});
      for(const game of catalog.games) {
        assert.equal((await page.goto(base+`/products/${game.id}/`)).status(),200);
        assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
        assert(await page.locator('.classic-artwork img').evaluateAll(images=>images.length===2 && images.every(image=>image.complete && image.naturalWidth>0)));
        assert.equal(await page.getByRole('heading',{name:game.name,exact:true}).count(),1);
        if(game.id === 'gta-sa') {
          assert.equal(await page.getByRole('link',{name:'Download SA (ZIP)',exact:false}).getAttribute('href'),game.releaseArtifact.url);
          await page.screenshot({path:`project/build/rockstar-classics/sa-${width}.png`,fullPage:true});
          await page.getByRole('link',{name:'Get Free Key',exact:true}).click();
          assert(await page.locator('#freeKeyModal').isVisible());
          await page.screenshot({path:`project/build/rockstar-classics/free-key-${width}.png`});
          assert.equal(await page.locator('#freeKeyBtn').getAttribute('aria-disabled'),'true');
          await page.waitForFunction(()=>document.querySelector('#freeKeyBtn').getAttribute('aria-disabled')==='false');
          assert.equal(await page.locator('#freeKeyBtn').getAttribute('href'),'https://scoobymenu.cc/scoobyontop.html');
          await page.keyboard.press('Escape');
          assert.equal(await page.locator('#freeKeyModal').isVisible(),false);
          await page.getByRole('link',{name:'View All Features',exact:true}).click();
          await page.locator('#feature-search').fill('Teleport to waypoint');
          await page.getByRole('heading',{name:'Teleport to waypoint',exact:true}).waitFor({state:'visible'});
          assert((await page.locator('.feature-item:visible').count()) > 0);
          assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
          await page.screenshot({path:`project/build/rockstar-classics/features-${width}.png`,fullPage:true});
        } else {
          assert.equal(await page.getByRole('button',{name:'Coming soon',exact:true}).isDisabled(),true);
          assert.equal(await page.locator('#getFreeKey').count(),0);
        }
      }
    }
    const noJS=await browser.newPage({javaScriptEnabled:false});
    await noJS.goto(base+'/rockstar-classics/');
    assert.equal(await noJS.locator('[data-game]:visible').count(),5);
    await noJS.goto(base+'/products/gta-sa/');
    assert.equal(await noJS.getByRole('link',{name:'Get Free Key',exact:true}).getAttribute('href'),'https://scoobymenu.cc/scoobyontop.html');
    for (const game of catalog.games) {
      await page.goto(base+`/rockstar-classics/${game.id}/`);
      await page.waitForURL(base+`/products/${game.id}/`);
    }
    assert.equal(errors.length,0,errors.join('\n'));
    console.log('Catalog, availability, desktop/mobile routes, filters, search, empty state and no-JS checks passed.');
  } finally {if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(error=>{console.error(error);process.exitCode=1;});
