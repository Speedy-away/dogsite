/** Build every feature explorer from local manifests. No site-page dependencies.
 * node tools/features/build-features-page.js          (preview sizes)
 * node tools/features/build-features-page.js --apply  (write pages)
 */
const fs = require('fs');
const path = require('path');
const SITE = path.resolve(__dirname, '../..');
const APPLY = process.argv.includes('--apply');
const pages = [
  {slug:'half-life-1',name:'Half-Life 1',short:'Half-Life 1',file:'features-half-life-1.json',out:'features-list/half-life-1-features/index.html',product:'half-life-1',guide:'/guides/half-life-1/',image:'/assets/images/source-games/half-life-logo.webp',description:'Explore Half-Life 1 ESP, animated chams, radar, Lua, profiles and campaign controls. Search features and check their current availability.',notice:'Original Steam Half-Life / Windows x86 / OpenGL. Original Windows campaign features are verified; other editions and Linux have separate support.'},
  {slug:'l4d',name:'Left 4 Dead 1 & 2',short:'L4D',file:'features-l4d.json',out:'features-list/l4d-features/index.html',product:'l4d',image:'/assets/images/l4d/background.webp',description:'Explore infected and pickup ESP, chams, Rage and Legit, triggerbot, movement, world visuals, Lua and settings. Free for free-key and paid accounts.',notice:'Both games use verified 32-bit adapters.'},
  {slug:'cs2',name:'Counter-Strike 2',short:'CS2',file:'features-cs2.json',out:'features-list/cs2-features/index.html',product:'cs2',image:'/assets/images/store/cs2.webp',description:'Explore aim and recoil controls, player visuals, skins, local inventory, custom models, world effects and interface settings. Search the CS2 feature library.',notice:'Inventory additions and case-opening tools manage local items. Feature availability can change after CS2 updates.'},
  {slug:'last-of-us',name:'The Last of Us Part I',short:'The Last of Us',file:'features-last-of-us.json',out:'features-list/last-of-us-features/index.html',product:'last-of-us',description:'Browse Part I combat, NPC and self ESP, movement, weapon controls, spawners and interface settings. Free for free and paid accounts; Part II is coming soon.'},
  {slug:'gmod',name:"Garry's Mod",short:'GMOD',file:'features-gmod.json',out:'features-list/gmod-features/index.html',product:'gmod',guide:'/guides/',description:"Explore Rage and Legit, player visuals, movement, gamemode tools and Lua. Find individual controls and settings in the GMod feature library."},
  {slug:'gta5',name:'GTA 5',file:'features-gta5.json',out:'features-list/gta-features/index.html',product:'gta5',description:'Explore the complete GTA 5 feature list, from vehicles and recovery to world options and player tools.'},
  {slug:'rdr2',name:'Red Dead Redemption 2',short:'RDR2',file:'features-rdr2.json',out:'features-list/rdr2-features/index.html',product:'rdr2',description:'Find your way through the frontier. Browse world options, weapons, players, mounts, and more.'},
  {slug:'fivem',name:'FiveM',file:'features-fivem.json',out:'fivem-features/index.html',product:'fivem',description:'Explore combat, visuals, movement, and server tools, with the settings available for each feature.'},
  {slug:'gta5-highlights',name:'GTA 5 highlights',short:'GTA 5 overview',file:'features-gta5-highlights.json',out:'scooby-features/index.html',product:'gta5',description:'Browse the original GTA 5 feature overview, including vehicles, world options, and superhero abilities.'}
];
const esc = s => String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const slug = s => String(s).toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
function clean(s) {
  let text=String(s||'').split('##')[0].replace(/\s+/g,' ').trim();
  if(text && text===text.toUpperCase() && /[A-Z]{3}/.test(text))text=text.toLowerCase().replace(/\b\w/g,c=>c.toUpperCase());
  return text;
}
const count = tab => tab.categories.reduce((n,c)=>n+c.groups.reduce((n,g)=>n+g.items.length,0),0);
function render(page, manifest = JSON.parse(fs.readFileSync(path.join(__dirname,page.file),'utf8'))) {
  if (manifest.website) page = {...page, description:manifest.website.features.description, notice:manifest.website.notice};
  const total=manifest.tabs.reduce((n,t)=>n+count(t),0);
  const categoryCount=manifest.tabs.reduce((n,t)=>n+t.categories.length,0);
  const url='https://scoobymenu.cc/'+page.out.replace(/index\.html$/,'');
  const image=page.image || (page.slug==='last-of-us'?'/assets/images/store/last-of-us.webp':'/assets/images/logo.png');
  const used=new Set();
  const unique=id=>{let key=id,n=2;while(used.has(key))key=id+'-'+n++;used.add(key);return key;};
  const sections=manifest.tabs.map((tab,ti)=>{
    const key=slug(tab.name),sectionId=unique(tab.legacyId||'section-'+key);
    const categories=tab.categories.map((category,ci)=>{
      const id=unique(category.legacyId||key+'-'+slug(category.name));
      const n=category.groups.reduce((n,g)=>n+g.items.length,0);
      return `<details class="feature-category" id="${esc(id)}" >
<summary><span class="category-chevron" aria-hidden="true">›</span><h3>${esc(clean(category.name))}</h3><span class="category-count" data-total="${n}">${n}</span></summary>
<div class="category-content"><a class="category-permalink" href="#${esc(id)}">Link to this section ↗</a>
${category.groups.map(group=>`<section class="feature-group" data-group="${esc(clean(group.name))}">${category.groups.length>1||!['General','More','Features'].includes(clean(group.name))?`<h4>${esc(clean(group.name))}</h4>`:''}<div class="feature-items">
${group.items.map(item=>`<article class="feature-item"><div class="feature-name-row"><h5>${esc(clean(item.label))}</h5>${page.slug==='fivem' && item.type?`<span class="feature-type">${esc(item.type)}</span>`:''}</div>${item.desc?`<p>${esc(item.desc)}</p>`:''}${item.settings?.length?`<ul class="feature-settings">${item.settings.map(s=>`<li>${esc(s)}</li>`).join('')}</ul>`:''}</article>`).join('\n')}
</div></section>`).join('\n')}</div></details>`;
    }).join('\n');
    return {key,id:sectionId,name:tab.name,total:count(tab),html:`<section class="feature-section" id="${esc(sectionId)}" data-section="${esc(key)}"><div class="section-heading"><h2>${esc(tab.name)}</h2><span>${count(tab).toLocaleString()} features</span></div>${categories}</section>`};
  });
  return `<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(page.name)} Features — Scooby</title><meta name="description" content="${esc(page.description)}"><link rel="canonical" href="${url}"><meta name="robots" content="index, follow">
<meta property="og:type" content="website"><meta property="og:url" content="${url}"><meta property="og:title" content="${esc(page.name)} Features — Scooby"><meta property="og:description" content="${esc(page.description)}"><meta property="og:image" content="https://scoobymenu.cc${image}"><meta name="twitter:card" content="summary_large_image"><meta name="twitter:image" content="https://scoobymenu.cc${image}">
<link rel="icon" href="/assets/images/logo.png"><link rel="stylesheet" href="/assets/css/features.css"><script src="/assets/js/features.js" defer></script><script src="/languages/i18n.js" defer></script><noscript><style>.search-controls,.result-actions,.category-nav a[data-section=all],.mobile-category{display:none!important}.feature-sidebar{display:block!important}.category-nav{display:flex!important}.sidebar-help{display:none}</style></noscript></head>
<body><a class="skip-link" href="#explorer">Skip to features</a><header class="feature-header"><div class="header-inner"><a href="/" class="brand">scooby <span>/ features</span></a><nav aria-label="Main navigation"><a href="/guides/">Guides</a><a href="/docs/">Docs</a><a href="/store/">Store</a></nav><a class="button small" href="/products/${page.product}/">View product ↗</a></div></header>
<main class="feature-shell"><nav class="game-nav" aria-label="Choose feature list">${pages.map(p=>`<a href="/${p.out.replace(/index\.html$/,'')}" ${p.slug===page.slug?'aria-current="page"':''}>${esc(p.short||p.name)}</a>`).join('')}</nav>
<section class="feature-hero"><div class="hero-copy"><span class="eyebrow">THE FEATURE LIBRARY</span><h1>${esc(page.name)}<br><span>Every detail, explored.</span></h1><p>${esc(page.description)}</p><div class="feature-stats"><div><strong>${total.toLocaleString()}</strong><span>listed features</span></div><div><strong>${manifest.tabs.length}</strong><span>sections</span></div><div><strong>${categoryCount}</strong><span>categories</span></div></div></div></section>
${page.notice?`<aside class="feature-notice">${esc(page.notice)}</aside>`:''}
${page.slug==='last-of-us'?'<aside class="feature-notice">Part I features depend on verified game bindings and the loaded scene. Disabled controls explain their requirements. Part II is coming soon.</aside>':''}
${page.slug==='gta5-highlights'?'<aside class="feature-notice">Looking for the complete catalogue? <a href="/features-list/gta-features/">Explore all GTA 5 features →</a></aside>':''}
<div class="explorer-layout" id="explorer"><aside class="feature-sidebar"><div class="sidebar-inner"><span class="eyebrow">BROWSE SECTIONS</span><nav class="category-nav" aria-label="Feature sections"><a href="#explorer" data-section="all" aria-current="true"><span>All features</span><span>${total.toLocaleString()}</span></a>${sections.map(s=>`<a href="#${esc(s.id)}" data-section="${esc(s.key)}"><span>${esc(s.name)}</span><span>${s.total.toLocaleString()}</span></a>`).join('')}</nav><div class="sidebar-help"><strong>Need help getting started?</strong><p>Find setup instructions and common fixes in the wiki.</p><a href="${page.guide||`/guides/${page.product}/`}">Open guide ↗</a></div></div></aside>
<div class="feature-content" data-i18n-skip><div class="explorer-controls"><div class="search-controls"><label for="feature-search" class="sr-only">Search all ${esc(page.name)} features</label><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4 4"/></svg><input id="feature-search" type="search" placeholder="Search names, descriptions, or settings…" autocomplete="off"><button id="clear-search" aria-label="Clear search" hidden>×</button><kbd>/</kbd></div><label class="mobile-category"><span class="sr-only">Filter by section</span><select id="category-select"><option value="all">All features</option>${sections.map(s=>`<option value="${esc(s.key)}">${esc(s.name)}</option>`).join('')}</select></label><div class="results-row"><p id="result-count" role="status">${total.toLocaleString()} features across ${manifest.tabs.length} sections</p><div class="result-actions"><button id="expand-all">Expand all</button><button id="collapse-all">Collapse all</button></div></div></div>
<div id="feature-results">${sections.map(s=>s.html).join('\n')}</div><div class="empty-state" id="feature-empty" hidden><h2>No matching features.</h2><p>Try a shorter search or look across all sections.</p><button class="button" id="reset-search">Clear all filters</button></div>
<div class="feature-bottom"><div><h2>Found what you're looking for?</h2><p>Explore editions, pricing, and setup instructions.</p></div><a class="button" href="/products/${page.product}/">View ${esc(page.short||page.name)} product ↗</a></div></div></div></main>
<footer class="feature-footer feature-shell"><a href="/" class="brand">scooby</a><p>Explore more. Make it yours.</p><nav aria-label="Footer navigation"><a href="/store/">Store</a><a href="/guides/">Guides</a><a href="/tos/">Terms</a></nav></footer></body></html>`;
}
if (require.main === module) {
const onlyIndex = process.argv.indexOf("--only");
const selectedPages = onlyIndex < 0 ? pages : pages.filter(page => page.slug === process.argv[onlyIndex + 1]);
if (!selectedPages.length) throw new Error("Unknown feature page requested");
for(const page of selectedPages){const html=require('../seo-metadata').applyMetadata(page.out,render(page));console.log(`${page.out}: ${Math.round(Buffer.byteLength(html)/1024)} KB`);if(APPLY){const file=path.join(SITE,page.out);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,html.replace(/></g,'>\n<')+'\n');}}
console.log(APPLY?`WROTE ${selectedPages.length} feature pages`:'DRY RUN — use --apply to write');

}
module.exports = {pages, render};
