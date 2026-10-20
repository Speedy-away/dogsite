/* Original code-native artwork for the Wiki's link previews. No external requests. */
const fs=require('node:fs'),path=require('node:path');
const {gameLogos}=require('./social-logos');
const root=path.resolve(__dirname,'..');
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const asset=file=>'data:'+(file.endsWith('.svg')?'image/svg+xml':file.endsWith('.webp')?'image/webp':'image/png')+';base64,'+fs.readFileSync(path.join(root,file)).toString('base64');
function logo(slug){
 const marks=gameLogos[slug]||(slug==='mta-sa'?[{src:'/assets/images/mta-sa/launch-artwork.png',alt:'Multi Theft Auto: San Andreas'}]:null);
 if(!marks)throw new Error('Missing wiki game artwork: '+slug);
 return marks.map(l=>`<img class="game-logo${l.white?' white':''}" src="${asset(l.src)}" alt="${escape(l.alt)}">`).join('');
}
function renderWikiCard(card){
 const longest=Math.max(...card.lines.map(s=>s.length));
 const titleSize=longest>18?65:longest>15?73:longest>12?82:94;
 let art;
 if(card.visual==='library')art='<div class="library">'+['gta5','rdr2','fivem','redm','cs2','gmod'].map(slug=>`<div class="game-tile">${logo(slug)}</div>`).join('')+'</div>';
 else if(card.visual==='key')art='<div class="key-art"><svg viewBox="0 0 100 56" fill="none" stroke="currentColor" stroke-width="5"><circle cx="25" cy="28" r="18"/><path d="M43 28h49m-5 0v14m-14-14v10"/></svg><div class="period">24<span>h</span></div><p>One key. Renew daily.</p><div class="key-label">ALL SCOOBY FREE VERSIONS</div></div>';
 else if(card.visual==='game')art=`<div class="game-art"><div class="game-emblem">${logo(card.game)}</div><div class="game-path">${card.steps.map((s,i)=>`<span><b>0${i+1}</b>${escape(s)}</span>`).join('')}</div></div>`;
 else art='<div class="steps-art">'+card.steps.map((step,i)=>`<div class="step"><span class="step-number">0${i+1}</span><span>${escape(step)}</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="m6 12 4 4 8-8"/></svg></div>`).join('')+'</div>';
 return `<!doctype html><html lang="en"><head><meta charset="utf-8"><style>
 *{box-sizing:border-box}html,body{width:1200px;height:630px;margin:0;overflow:hidden}
 body{font-family:"Segoe UI",Arial,sans-serif;color:#f4f5fa;background:#101116}
 .canvas{height:100%;padding:40px 56px;position:relative;background:linear-gradient(115deg,#101116 61%,#161a28)}
 .canvas:after{content:'';position:absolute;left:0;top:0;height:100%;width:7px;background:#9aafff}
 header{display:flex;align-items:center;justify-content:space-between;height:52px}
 .brand{display:flex;align-items:center;gap:15px;font-size:34px;font-weight:740;letter-spacing:-1.3px}
 .brand img{width:39px;height:52px;object-fit:contain}.brand em{font-style:normal;color:#9aafff;font-weight:400}
 .domain{font-size:17px;color:#9a9eae;letter-spacing:.2px}
 .copy{position:absolute;left:56px;top:158px;width:650px;z-index:1}
 .eyebrow{font-size:17px;letter-spacing:2.3px;font-weight:650;color:#b6c4ff;margin:0 0 24px}
 h1{font-size:${titleSize}px;font-weight:720;letter-spacing:-3.8px;line-height:1.055;margin:0 0 24px}
 h1 span{display:block;white-space:nowrap}h1 span+span{color:#9aafff}
 .subtitle{color:#c0c3d0;font-size:23px;line-height:1.5;max-width:610px;margin:0}
 .art{position:absolute;right:56px;top:143px;width:390px;height:365px}
 .library{display:grid;grid-template-columns:1fr 1fr;grid-template-rows:repeat(3,103px);gap:13px;transform:rotate(-4deg);padding:10px 0}
 .game-tile{background:#202330;border:1px solid #34394b;border-radius:13px;display:flex;align-items:center;justify-content:center;padding:18px 22px}
 .game-tile:nth-child(2n){transform:translateY(13px)}
 .game-logo{max-width:100%;max-height:100%;object-fit:contain}.white{filter:brightness(0) invert(1)}
 .game-tile .game-logo{max-height:66px;width:140px}.game-tile:has(img+img){flex-direction:column}
 .steps-art{padding-top:27px}.step{display:flex;align-items:center;gap:18px;padding:25px 0;border-bottom:1px solid #343848;font-size:23px;font-weight:500;line-height:1.3}
 .step-number{font-size:18px;color:#9aafff;font-variant-numeric:tabular-nums}.step svg{margin-left:auto;flex-shrink:0;width:22px;height:22px;color:#9aafff}
 .key-art{padding:10px 0 0 20px}.key-art>svg{width:120px;height:65px;color:#9aafff;margin-left:15px}
 .period{font-size:174px;line-height:1.05;font-weight:650;letter-spacing:-11px;color:#f4f5fa}.period span{font-size:90px;letter-spacing:-4px;color:#9aafff}
 .key-art p{font-size:24px;color:#c0c3d0;margin:5px 0 24px}.key-label{font-size:14px;letter-spacing:1.4px;color:#b6c4ff}
 .game-art{height:365px;background:#1c202c;border-radius:22px;padding:30px 27px 15px;border:1px solid #34394b}
 .game-emblem{height:217px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px}
 .game-emblem .game-logo{max-height:183px;max-width:305px}.game-emblem:has(img+img) img{max-height:83px}
 .game-path{display:flex;gap:0;justify-content:space-between;padding-top:25px;border-top:1px solid #34394b;margin-top:16px}
 .game-path span{font-size:14px;color:#d8dbe5;line-height:1.6;max-width:110px}.game-path b{display:block;font-size:13px;color:#9aafff;font-weight:500}
 footer{position:absolute;left:56px;right:56px;bottom:34px;display:flex;justify-content:space-between;align-items:center;font-size:18px;color:#a7acbc}
 footer strong{font-size:16px;color:#c5cfff;font-weight:500;display:flex;align-items:center;gap:10px}footer svg{width:20px;height:20px}
 </style></head><body><main class="canvas"><header><div class="brand"><img src="${asset('/assets/images/brand/scooby-mark.svg')}" alt="">Scooby <em>Wiki</em></div><span class="domain">scoobymenu.cc/guides</span></header><div class="copy"><p class="eyebrow">${escape(card.label)}</p><h1>${card.lines.map(s=>`<span>${escape(s)}</span>`).join('')}</h1><p class="subtitle">${escape(card.subtitle)}</p></div><div class="art">${art}</div><footer><span>${escape(card.detail)}</span><strong>Open the guide<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M5 19 19 5M5 5h14v14"/></svg></strong></footer></main></body></html>`;
}
module.exports={renderWikiCard};
