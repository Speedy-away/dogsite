/* Render code-native social graphics. Requires Playwright and Microsoft Edge. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const { cards, VERSION, WIDTH, HEIGHT } = require('./social-cards');
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'assets/images/social');
const artwork = 'data:image/webp;base64,' +
  fs.readFileSync(path.join(ROOT, 'assets/images/brand/social-preview-base.webp')).toString('base64');
const escape = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');

function render(card) {
  const home = card.id === 'home';
  const longestLine = Math.max(...card.lines.map(line => line.length));
  const titleSize = Math.min(76, Math.floor(930 / Math.max(longestLine, 12)));
  const copy = home ? '' : '<div class="copy"><p class="label">' + escape(card.label) +
    '</p><h1>' + card.lines.map(line => '<span>' + escape(line) + '</span>').join('') +
    '</h1><p class="subtitle">' + escape(card.subtitle) +
    '</p></div><footer>scoobymenu.cc</footer>';
  return '<!doctype html><html><meta charset="utf-8"><style>' +
    'html,body{margin:0;width:1200px;height:630px;font-family:"Segoe UI",Arial,sans-serif;background:#0c0d10;color:#f5f6f8}' +
    'main{position:relative;height:100%;overflow:hidden;isolation:isolate}' +
    'img{position:absolute;z-index:-1;width:100%;height:100%;object-fit:cover;inset:0}' +
    '.section img{left:auto;right:-18px;width:596px;object-position:center;mask-image:linear-gradient(90deg,transparent,#000 26%)}' +
    '.copy{position:absolute;left:68px;top:50%;transform:translateY(-54%);width:590px}' +
    '.label{color:' + card.accent + ';font-size:21px;font-weight:750;letter-spacing:.13em;margin:0 0 23px}' +
    'h1{font-size:' + titleSize + 'px;line-height:1.06;letter-spacing:-.035em;margin:0}h1 span{display:block}' +
    '.subtitle{font-size:25px;line-height:1.25;max-width:540px;color:#c5c7d1;margin:24px 0 0}' +
    'footer{position:absolute;bottom:40px;left:68px;color:#a8adba;font-size:19px;letter-spacing:.05em}' +
    '</style><main class="' + (home ? 'home' : 'section') + '"><img alt="" src="' + artwork + '">' +
    copy + '</main></html>';
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ channel: process.env.SOCIAL_CARD_BROWSER || 'msedge', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: WIDTH, height: HEIGHT }, deviceScaleFactor: 1 });
    const selected = Object.values(cards).filter(card => (!process.argv.includes('--wiki-only') || card.layout === 'wiki') &&
      (!process.argv.includes('--home-only') || card.id === 'home') &&
      (!process.argv.includes('--resources-only') || /^resources(?:-|$)/.test(card.id)));
    for (const card of selected) {
      await page.setContent(render(card));
      await page.evaluate(async () => {
        await document.fonts.ready;
        await Promise.all([...document.images].map(image => image.decode()));
      });
      const fits = await page.evaluate(() => [...document.querySelectorAll('h1 span,.subtitle')].every(el => el.scrollWidth <= el.clientWidth));
      if (!fits) throw new Error('Social card text overflows: ' + card.id);
      await page.screenshot({ path: path.join(OUT, `${card.id}-${card.version || VERSION}.png`) });
    }
    console.log(`Rendered ${selected.length} Scooby social cards at ${WIDTH} × ${HEIGHT}.`);
  } finally { await browser.close(); }
}
if (require.main === module) main().catch(error => { console.error(error); process.exitCode = 1; });
module.exports = { render };
