/* Render code-native social graphics. Requires Playwright and Microsoft Edge. */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const { cards, VERSION, WIDTH, HEIGHT } = require('./social-cards');
const { logosFor } = require('./social-logos');
const { buildBrandMask } = require('./build-brand-assets');
const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'assets/images/social');
const escape = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const icons = {
  book: '<path d="M12 5C8 2 4 3 2 4v16c4-2 7-1 10 1m0-16c4-3 8-2 10-1v16c-4-2-7-1-10 1V5Z"/>',
  code: '<path d="m7 6-6 6 6 6m10-12 6 6-6 6M14 3l-4 18"/>',
  grid: '<rect x="2" y="2" width="8" height="8" rx="2"/><rect x="14" y="2" width="8" height="8" rx="2"/><rect x="2" y="14" width="8" height="8" rx="2"/><rect x="14" y="14" width="8" height="8" rx="2"/>',
  help: '<circle cx="12" cy="12" r="10"/><path d="M9 8a3 3 0 1 1 4 3c-1 .5-1 1-1 3m0 3h.01"/>',
  sliders: '<path d="M2 5h6m4 0h10M2 12h12m4 0h4M2 19h3m4 0h13"/><circle cx="10" cy="5" r="2"/><circle cx="16" cy="12" r="2"/><circle cx="7" cy="19" r="2"/>',
  history: '<path d="M3 10a9 9 0 1 1 1 7M3 3v7h7m2-4v6l4 2"/>',
  download: '<path d="M12 2v13m-5-5 5 5 5-5M3 16v5h18v-5"/>',
  play: '<circle cx="12" cy="12" r="10"/><path d="m10 7 7 5-7 5V7Z"/>',
  globe: '<circle cx="12" cy="12" r="10"/><ellipse cx="12" cy="12" rx="4" ry="10"/><path d="M2 12h20"/>',
  key: '<circle cx="8" cy="8" r="6"/><path d="m12 12 10 10m-3-3 3-3m-6 0 3-3"/>',
  game: '<path d="M7 6h10c3 0 4 3 5 11 0 3-3 3-5 0l-2-2H9l-2 2c-2 3-5 3-5 0C3 9 4 6 7 6Z"/><path d="M8 9v5m-2.5-2.5h5m5.5-.5h.01m3 2h.01"/>',
};

const dataUrls = new Map();
function assetUrl(file) {
  if (!dataUrls.has(file)) {
    const mime = file.endsWith('.svg') ? 'image/svg+xml' : file.endsWith('.webp') ? 'image/webp' : file.endsWith('.jpg') ? 'image/jpeg' : 'image/png';
    dataUrls.set(file, 'data:' + mime + ';base64,' + fs.readFileSync(path.join(ROOT, file)).toString('base64'));
  }
  return dataUrls.get(file);
}
function logoImage(logo) {
  return '<img class="game-logo' + (logo.white ? ' game-logo--white' : '') + '" src="' + assetUrl(logo.src) + '" alt="' + escape(logo.alt) + '">';
}
function render(card) {
  const logos = logosFor(card);
  const collage = logos.length > 2;
  const art = collage ? '<div class="logo-collage">' + logos.map(logo => '<div class="logo-tile">' + logoImage(logo) + '</div>').join('') + '</div>'
    : '<div class="orbit"><i class="spark"></i><div class="symbol' + (logos.length ? ' symbol--logos' : '') + '">' + (logos.length ? '<div class="game-marks">' + logos.map(logoImage).join('') + '</div>' : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">' + icons[card.icon] + '</svg>') + '</div></div>';
  const longest = Math.max(...card.lines.map(line => line.length));
  const fontSize = longest > 16 ? 64 : longest > 14 ? 72 : 82;
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><style>
    *{box-sizing:border-box}html,body{margin:0;width:${WIDTH}px;height:${HEIGHT}px;overflow:hidden}
    body{font-family:Arial,Helvetica,sans-serif;background:#080d18;color:#f1f5ff}
    .card{position:relative;width:100%;height:100%;padding:54px 64px;--accent:${card.accent};background:radial-gradient(ellipse at 100% 0%,${card.accent}19,transparent 55%)}
    .grid{position:absolute;inset:0;background-image:linear-gradient(#ffffff04 1px,transparent 1px),linear-gradient(90deg,#ffffff04 1px,transparent 1px);background-size:64px 64px;mask-image:linear-gradient(to right,transparent,#000)}
    .top{display:flex;align-items:center;justify-content:space-between;position:relative;z-index:1}
    .brand{font-weight:800;letter-spacing:-1.5px;font-size:34px;display:flex;align-items:center;gap:14px}
    .mark{display:block;width:43px;height:52px;background:#f1f5ff;mask-image:url("${assetUrl('/assets/images/brand/scooby-mark.svg')}");mask-mode:alpha;mask-size:contain;mask-position:center;mask-repeat:no-repeat}
    .domain{font-size:18px;letter-spacing:1px;color:#96a8c8}
    .copy{position:absolute;left:64px;top:167px;width:700px;z-index:1}
    .label{font-size:15px;font-weight:700;letter-spacing:3px;color:var(--accent);margin:0 0 23px;display:flex;align-items:center;gap:12px}
    .label:before{content:'';display:block;width:26px;height:2px;background:var(--accent)}
    h1{font-size:${fontSize}px;font-weight:700;line-height:1.05;letter-spacing:-3.5px;margin:0 0 24px}
    h1 span{display:block}h1 span+span{color:var(--accent)}
    .subtitle{font-size:23px;line-height:1.4;color:#bac9e1;margin:0;white-space:nowrap}
    .orbit{position:absolute;top:132px;left:836px;width:352px;height:352px;border:1px solid ${card.accent}24;border-radius:50%;display:grid;place-items:center}
    .orbit:before{content:'';position:absolute;inset:-52px;border:1px solid ${card.accent}10;border-radius:50%}
    .orbit:after{content:'';position:absolute;inset:39px;border:1px solid ${card.accent}20;border-radius:50%}
    .symbol{display:grid;place-items:center;width:188px;height:188px;border:1px solid ${card.accent}48;border-radius:44px;transform:rotate(-8deg);background:linear-gradient(135deg,${card.accent}15,#0a1222);box-shadow:0 20px 60px #0004}
    .symbol svg{width:88px;height:88px;color:var(--accent);stroke-width:1.25;transform:rotate(8deg)}
    .symbol--logos{width:252px;height:220px;border-radius:36px}
    .game-marks{width:212px;height:178px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:22px;transform:rotate(8deg)}
    .game-logo{display:block;max-width:100%;min-height:0;object-fit:contain;filter:drop-shadow(0 3px 8px #0004)}
    .game-marks .game-logo{width:100%;max-height:154px}
    .game-marks:has(img+img) .game-logo{max-height:74px}
    .game-logo--white{filter:brightness(0) invert(1)}
    .logo-collage{position:absolute;left:794px;top:116px;width:352px;height:392px;display:grid;grid-template-columns:repeat(4,1fr);grid-auto-rows:48px;gap:9px;align-content:center;transform:rotate(-5deg)}
    .logo-tile{display:flex;align-items:center;justify-content:center;padding:7px;background:linear-gradient(135deg,#ffffff09,#ffffff03);border:1px solid #ffffff20;border-radius:11px;box-shadow:0 8px 20px #0002}
    .logo-tile:nth-child(4n+2),.logo-tile:nth-child(4n+4){transform:translateY(8px)}
    .logo-tile .game-logo{width:100%;max-height:35px}
    .spark{position:absolute;background:var(--accent);width:9px;height:9px;border-radius:50%;top:64px;left:27px;box-shadow:0 0 20px ${card.accent}60}
    footer{position:absolute;bottom:40px;left:64px;right:64px;border-top:1px solid #ffffff14;padding-top:22px;display:flex;justify-content:space-between;align-items:center;color:#91a2be;font-size:18px}
    footer .arrow{font-size:27px;color:var(--accent);line-height:1}
  </style></head><body><main class="card"><div class="grid"></div><div class="top"><div class="brand"><span class="mark" aria-hidden="true"></span>Scooby</div><span class="domain">scoobymenu.cc</span></div><div class="copy"><p class="label">${escape(card.label)}</p><h1>${card.lines.map(line => `<span>${escape(line)}</span>`).join('')}</h1><p class="subtitle">${escape(card.subtitle)}</p></div>${art}<footer><span>${escape(card.detail)}</span><span class="arrow">↗</span></footer></main></body></html>`;
}

async function main() {
  buildBrandMask();
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ channel: process.env.SOCIAL_CARD_BROWSER || 'msedge', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: WIDTH, height: HEIGHT }, deviceScaleFactor: 1 });
    for (const card of Object.values(cards)) {
      await page.setContent(render(card));
      await page.evaluate(async () => {
        await document.fonts.ready;
        await Promise.all([...document.images].map(image => image.decode()));
      });
      const fits = await page.evaluate(() => [...document.querySelectorAll('h1 span,.subtitle')].every(el => el.scrollWidth <= el.clientWidth));
      if (!fits) throw new Error('Social card text overflows: ' + card.id);
      await page.screenshot({ path: path.join(OUT, `${card.id}-${VERSION}.png`) });
    }
    console.log(`Rendered ${Object.keys(cards).length} Scooby social cards at ${WIDTH} × ${HEIGHT}.`);
  } finally { await browser.close(); }
}
if (require.main === module) main().catch(error => { console.error(error); process.exitCode = 1; });
module.exports = { render };
