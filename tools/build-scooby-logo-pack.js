const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'project/output/scooby-logo-pack');
const generated = 'C:/Users/whatw/.codex/generated_images/01a1084b-2007-7e82-900d-622fe9d497b7';
const items = [
  ['wizard','Wizard','Originals','spoofer-scooby-wizard.png','#b47aff','magic'],
  ['tf2','TF2 Soldier','Games','tf2-scooby.png','#ffad51','nod'],
  ['cs2','CS2 Tactical','Games','cs2-scooby.png','#ff981c','pulse'],
  ['l4d','Left 4 Dead Survivor','Games','l4d-scooby.png','#95d948','sway'],
  ['astronaut','Astronaut','Space','exec-5db64668-aa26-4bd8-8d21-938f0c95c12b.png','#55d9ff','float'],
  ['lunar','Lunar Explorer','Space','exec-9a9b41e9-18af-4c74-9969-e5f513be7f48.png','#ffc767','float'],
  ['alien','Alien Scout','Space','exec-eb07c9f4-bee4-498e-8aed-f4c782415f69.png','#91f870','float'],
  ['commander','Star Commander','Space','exec-4ccfb343-f7f2-4e62-90d7-36282b16e687.png','#6ee7ff','nod'],
  ['nebula','Nebula Mage','Space','exec-cf41e710-3f8a-4977-b5da-653e95a2698b.png','#a681ff','magic'],
  ['cowboy','Frontier Cowboy','Adventure','exec-a6e78f1c-c988-4e0e-a2a8-58ff03c91477.png','#daa05f','nod'],
  ['pirate','Pirate Captain','Adventure','exec-c64eeb95-3e98-470e-a4ed-c9b46b0df290.png','#efbb5b','sway'],
  ['ninja','Shadow Ninja','Adventure','exec-c372e289-6121-4a11-96cb-815864ecc891.png','#ff4b61','sway'],
  ['cyberpunk','Neon Runner','Future','exec-157d549b-8b41-408f-89fb-b94749d6219f.png','#ec59ff','pulse'],
  ['engineer','Workshop Engineer','Adventure','exec-15c212d6-0827-44e5-bd64-d84c74d32939.png','#ffe057','nod'],
  ['diver','Deep-Sea Diver','Adventure','exec-5c44d6af-d806-4084-bdea-c479a6d62f24.png','#45d3d9','float']
];
for (const dir of ['png', 'animated']) fs.mkdirSync(path.join(output, dir), { recursive:true });
const motionCSS = `
.motion{transform-origin:256px 270px;animation:float 5s ease-in-out infinite}
.nod{animation:nod 4.4s ease-in-out infinite}.sway{animation:sway 5.5s ease-in-out infinite}
.magic{animation:float 5s ease-in-out infinite}.pulse{animation:pulse 3.8s ease-in-out infinite}
.spark{transform-box:fill-box;transform-origin:center;animation:twinkle 3.6s ease-in-out infinite}
.spark.two{animation-delay:-1.2s}.spark.three{animation-delay:-2.4s}
.bubble{animation:bubble 5s ease-in-out infinite}.bubble.two{animation-delay:-2.5s}
@keyframes float{0%,100%{transform:translateY(4px) rotate(-1deg)}50%{transform:translateY(-9px) rotate(1deg)}}
@keyframes nod{0%,65%,100%{transform:rotate(0)}35%{transform:rotate(-3deg) translateY(-3px)}}
@keyframes sway{0%,100%{transform:rotate(-2deg)}50%{transform:rotate(2deg)}}
@keyframes pulse{0%,100%{transform:scale(1);opacity:.9}50%{transform:scale(1.025);opacity:1}}
@keyframes twinkle{0%,100%{opacity:.2;transform:scale(.65)}50%{opacity:.9;transform:scale(1)}}
@keyframes bubble{0%{transform:translateY(35px);opacity:0}25%{opacity:.6}100%{transform:translateY(-65px);opacity:0}}
@media(prefers-reduced-motion:reduce){.motion,.spark,.bubble{animation:none!important}}
`;
const manifest = items.map(([id,name,category,file,accent,motion]) => {
  const source = file.startsWith('exec-') ? path.join(generated,file) : path.join(root,'portal/images/product-logos',file);
  const buffer = fs.readFileSync(source);
  fs.copyFileSync(source,path.join(output,'png',id+'.png'));
  let accents = '';
  if (category === 'Space' || motion === 'magic') accents = `<g fill="${accent}"><path class="spark" d="M76 90l4 12 12 4-12 4-4 12-4-12-12-4 12-4z"/><path class="spark two" d="M431 215l3 9 9 3-9 3-3 9-3-9-9-3 9-3z"/><circle class="spark three" cx="95" cy="359" r="4"/></g>`;
  if (id === 'diver') accents = `<g fill="none" stroke="${accent}" stroke-width="2"><circle class="bubble" cx="90" cy="220" r="6"/><circle class="bubble two" cx="430" cy="310" r="9"/></g>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512" role="img" aria-labelledby="title"><title id="title">${name} — animated Scooby logo</title><style>${motionCSS}</style>${accents}<g class="motion ${motion}"><image x="26" y="26" width="460" height="460" href="data:image/png;base64,${buffer.toString('base64')}"/></g></svg>`;
  fs.writeFileSync(path.join(output,'animated',id+'.svg'),svg);
  return { id,name,category,accent,motion,png:`png/${id}.png`,animated:`animated/${id}.svg` };
});
fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2));
fs.copyFileSync(path.join(__dirname,'scooby-pack-prompts.json'),path.join(output,'generation-prompts.json'));
const cards = manifest.map((item,i) => `<article data-category="${item.category}" style="--accent:${item.accent}"><div class="art"><img src="${item.animated}" data-static="${item.png}" data-animated="${item.animated}" alt="${item.name} Scooby logo" width="300" height="300"></div><div class="info"><span class="number">${String(i+1).padStart(2,'0')}</span><div><h2>${item.name}</h2><p>${item.category} / ${item.motion}</p></div></div><div class="downloads"><a href="${item.png}" download>PNG ↓</a><a href="${item.animated}" download>Animated SVG ↓</a></div></article>`).join('\n');
fs.writeFileSync(path.join(output,'index.html'),`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Scooby / The 15 Pack</title><link rel="stylesheet" href="gallery.css"></head><body>
<header><div class="brand">SCOOBY <span>ICON COLLECTION / VOL. 01</span></div><span class="edition">15 DESIGNS · 30 ASSETS</span></header>
<main><section class="intro"><div class="eyebrow">A DIFFERENT HAT. SAME SCOOBY.</div><h1>Meet the whole crew.</h1><p>From the battlefield to the edge of the galaxy. Fifteen transparent logos, each with a little life of its own.</p></section>
<div class="toolbar"><nav aria-label="Filter icons"><button class="active" data-filter="all" aria-pressed="true">All 15</button><button data-filter="Space" aria-pressed="false">Space</button><button data-filter="Games" aria-pressed="false">Games</button><button data-filter="Adventure" aria-pressed="false">Adventure</button></nav><div class="controls"><button id="background" aria-pressed="false">Checkerboard</button><button id="motion" aria-pressed="true">Pause motion</button></div></div>
<section class="grid" aria-label="Logo collection">${cards}</section><footer>Transparent PNG + self-contained animated SVG. Open any SVG in a browser to play it.<br>Motion respects your system’s reduced-motion preference.</footer></main><script src="gallery.js"></script></body></html>`);
fs.writeFileSync(path.join(output,'gallery.css'),`*{box-sizing:border-box}body{margin:0;background:#0b0c10;color:#f2f3f8;font-family:Arial,sans-serif}header,main{max-width:1320px;margin:auto;padding:0 36px}header{height:90px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #24262e}.brand{font-weight:800;font-size:23px;letter-spacing:-1px}.brand span,.edition{font-size:10px;font-weight:500;letter-spacing:2px;color:#8d919f}.brand span{margin-left:22px}.intro{padding:65px 0 40px;max-width:780px}.eyebrow{font-size:11px;letter-spacing:2px;color:#a89afc}h1{font-size:clamp(36px,5vw,64px);letter-spacing:-3px;line-height:1.06;margin:18px 0} .intro p{font-size:17px;line-height:1.7;color:#999ead;max-width:620px}.toolbar{display:flex;justify-content:space-between;gap:18px;flex-wrap:wrap;margin:0 0 24px}nav,.controls{display:flex;gap:8px;flex-wrap:wrap}button,a{font:inherit}button{background:#13151b;color:#b1b5c2;border:1px solid #2a2d37;padding:10px 15px;border-radius:7px;font-size:12px;cursor:pointer}button:hover,button.active{background:#edeef5;color:#13141b}button:focus-visible,a:focus-visible{outline:2px solid #b5a4ff;outline-offset:4px}.grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:16px}article{background:#111319;border:1px solid #292c35;border-radius:12px;overflow:hidden}article[hidden]{display:none}.art{display:grid;place-items:center;aspect-ratio:1;background:radial-gradient(ellipse at 50% 80%,color-mix(in srgb,var(--accent) 9%,transparent),transparent 70%)}.art img{display:block;width:100%;height:auto}.info{padding:10px 16px;display:flex;gap:12px;align-items:flex-start}.number{font:11px monospace;color:#737a8c;padding-top:3px}h2{font-size:13px;margin:0 0 7px;font-weight:600}.info p{font-size:10px;color:#8990a0;margin:0}.downloads{display:flex;gap:15px;padding:15px 16px 18px;border-top:1px solid #20232c;margin-top:8px}.downloads a{font-size:10px;color:#bcc3d5;text-decoration:none}.downloads a:hover{color:white}.checker .art{background-color:#24262e;background-image:linear-gradient(45deg,#333641 25%,transparent 25%),linear-gradient(-45deg,#333641 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#333641 75%),linear-gradient(-45deg,transparent 75%,#333641 75%);background-size:24px 24px;background-position:0 0,0 12px,12px -12px,-12px 0}footer{padding:36px 0 50px;color:#767d8e;font-size:12px;line-height:1.8}@media(max-width:1050px){.grid{grid-template-columns:repeat(3,minmax(0,1fr))}.edition{display:none}}@media(max-width:600px){header,main{padding-left:18px;padding-right:18px}.brand span{display:none}.intro{padding-top:35px}h1{letter-spacing:-1.5px}.grid{grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.info{padding:8px 10px;gap:6px}.downloads{padding:12px 10px;gap:10px}.downloads a{font-size:9px}h2{font-size:12px}}`);
fs.writeFileSync(path.join(output,'gallery.js'),`const motionButton=document.querySelector('#motion');
const preference=matchMedia('(prefers-reduced-motion: reduce)');
let moving=!preference.matches;
function setMotion(){document.querySelectorAll('.art img').forEach(img=>img.src=moving?img.dataset.animated:img.dataset.static);motionButton.textContent=moving?'Pause motion':'Play motion';motionButton.setAttribute('aria-pressed',String(moving));}
setMotion();motionButton.addEventListener('click',()=>{moving=!moving;setMotion();});
preference.addEventListener('change',()=>{moving=!preference.matches;setMotion();});
document.querySelector('#background').addEventListener('click',event=>{const enabled=document.body.classList.toggle('checker');event.currentTarget.setAttribute('aria-pressed',String(enabled));});
document.querySelectorAll('[data-filter]').forEach(button=>button.addEventListener('click',()=>{document.querySelectorAll('[data-filter]').forEach(b=>{b.classList.toggle('active',b===button);b.setAttribute('aria-pressed',String(b===button));});document.querySelectorAll('article').forEach(card=>card.hidden=button.dataset.filter!=='all'&&card.dataset.category!==button.dataset.filter);}));`);
fs.writeFileSync(path.join(output,'README.txt'),`SCOOBY LOGO PACK — 15 DESIGNS\n\nExtract the ZIP, then open index.html for the animated gallery. No server or internet needed.\n\nCONTENTS\npng/: 15 original transparent PNGs, 1280 × 1280.\nanimated/: 15 self-contained 512 × 512 SVG files embedding the PNG artwork.\nindex.html + gallery.css + gallery.js: filterable gallery with motion toggle and transparency checkerboard.\nmanifest.json: names, categories, file paths and motion styles.\ngeneration-prompts.json: prompts for the 11 new variants, generated with the built-in image_gen tool. The four earlier variants are included from the existing project assets.\n\nANIMATION\nGentle float, nod, sway and pulse loops; space and mage designs include twinkling stars; diver has rising bubbles. These are whole-logo motion effects, not frame-by-frame character animation. SVGs retain transparent backgrounds. Reduced-motion preferences disable CSS animation. For a guaranteed static image, use the PNG.\n\nUSE ON A WEBSITE\n<img src="animated/astronaut.svg" width="96" height="96" alt="Scooby astronaut">\nUse PNGs in applications that do not support animated SVG. SVG wrappers contain raster artwork; they are not editable vector drawings.\n\nDESIGNS\n${manifest.map((item,i)=>`${i+1}. ${item.name}`).join('\n')}\n`);
console.log(`Created ${manifest.length} PNGs + ${manifest.length} animated SVGs in ${output}`);
