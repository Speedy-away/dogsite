// Build public CS2 docs from the shipped host contract and canonical shared UI sources.
// node tools/build-cs2-docs.js [--check] [--cs2-root C:/.../CS2/v2]
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {marked}=require('marked');
const {applyMetadata}=require('./seo-metadata');
const root=path.resolve(__dirname,'..');
const args=process.argv.slice(2),at=args.indexOf('--cs2-root');
const cs2=at>=0?path.resolve(args[at+1]):path.resolve(root,'../Scooby-Op/CS2/v2');
const ui=path.resolve(cs2,'../../simple-base/UI');
const outputs=new Map(),inputs={};
const esc=s=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const plain=s=>s.replace(/<[^>]*>/g,'').replace(/&amp;/g,'&').replace(/&#39;/g,"'").replace(/&quot;/g,'"');
const read=(base,file)=>{const data=fs.readFileSync(path.join(base,file),'utf8').replace(/\r\n/g,'\n').replace(/\r/g,'\n');inputs[(base===cs2?'CS2/v2/':'simple-base/UI/')+file]=crypto.createHash('sha256').update(data).digest('hex');return data.toString('utf8');};
let host=read(cs2,'docs/LUA_API.md').replaceAll('lua/cs2_v2.lua','/docs/cs2/cs2_v2.lua').replaceAll('../../../simple-base/UI/docs/LUA_API.md','/docs/cs2/ui-api.md').replaceAll('LUA_SIMPLE_BASE_REFERENCE.md','/docs/cs2/ui-api.md').replaceAll('LUA_BINDINGS.md','/docs/cs2/bindings.md').replaceAll('LUA_API_COVERAGE.md','/docs/cs2/coverage.md');
const hostVersion=host.match(/^# CS2 v2 Lua API ([0-9.]+)/)?.[1];
if(!hostVersion)throw new Error('Missing CS2 host version');
let shared=read(ui,'docs/LUA_API.md');
for(const file of ['HEALTH_ESP.md','GAME_SIDEBAR.md','ENTITY_COLORS.md']){
 shared=shared.replaceAll(']('+file+')','](/docs/cs2/contracts/'+file+')');
 outputs.set('docs/cs2/contracts/'+file,read(ui,'docs/'+file));
}
outputs.set('docs/cs2/game-api.md',host);outputs.set('docs/cs2/ui-api.md',shared);
outputs.set('docs/cs2/cs2_v2.lua',read(cs2,'docs/lua/cs2_v2.lua'));
const bindings=read(cs2,'docs/LUA_BINDINGS.md').replaceAll('LUA_API.md','/docs/cs2/game-api.md');
const coverage=read(cs2,'docs/LUA_API_COVERAGE.md');
outputs.set('docs/cs2/bindings.md',bindings);
outputs.set('docs/cs2/coverage.md',coverage);
outputs.set('docs/cs2/api-catalog.json',read(cs2,'docs/lua/api-catalog.json'));
const templates=[['Framework - Asset downloads','Asset download manager','Download binary assets, keep each request destination fixed, and inspect saved subfolders.','User URL'],['Framework - Player ESP','Player ESP framework','Draw custom boxes, names and health bars from copied player snapshots without changing built-in ESP settings.','Opt-in'],['Command framework','Command framework','Build custom target selection, recoil correction and firing in an isolated command worker. Enable command permission and reload; starts disabled.','Opt-in'],['Inventory studio','Inventory studio','Browse item finishes, preview a native 3D model, and create or equip local inventory items.','Opt-in'],['Download asset','Download asset','Download binary assets asynchronously into script folders with HTTP and file permission switches.','User URL'],['Native hooks','Native hooks','A typed Win64 hook recipe with original forwarding, shared controls and automatic script cleanup. Fill in a verified pattern/prototype first.','Author configured'],['ImGui Demo','Visual Studio','A standalone UI with crosshair, speed, health ring, player labels and native ESP controls.','F10'],['Standalone Menu','Standalone tools','A compact floating window with speed, crosshair and CS2 visual switches.','F9'],['Crosshair','Crosshair','A small example of custom features, keybinds and scaled drawing.','F7'],['Speed HUD','Speed HUD','Horizontal player speed with frame-rate-independent display smoothing.','No default key']];
if(new Set(templates.map(t=>t[0])).size!==templates.length)throw new Error('Duplicate Lua template entries');
for(const [name] of templates) outputs.set('docs/cs2/templates/'+name+'.lua',read(cs2,'assets/scripts/'+name+'.lua'));
const snippets=`# First script

Create a script from Scripts, paste this example in the editor, and choose Run Lua. Run becomes Unload while the script is active. Open folder and Refresh are in the manager's Other group. Script UI opens custom script pages.

## A toggleable CS2 overlay

\`\`\`lua
local enabled = features.add {
    id = "health", label = "My health overlay", default = true, key = "F8"
}
ui.tab("controls", "My overlay", function()
    ui.feature(enabled)
    ui.keybind(enabled, "Toggle key")
end)
ui.overlay("health_overlay", function()
    local player = entity.get_local_player()
    if not features.active(enabled) or not player or not player.alive then return end
    render.text(24, 120, player.name .. "  " .. player.health .. " HP",
                render.theme().accent, 18)
end)
\`\`\`

## Choose the correct API

CS2 uses host API ${hostVersion} and UI API 1.1 on Lua 5.4.7. Player snapshots and projections can be unavailable during a map change; check for nil. Settings IDs come from settings.list(). CS2 implements its own ESP color settings; shared esp_colors integration is not available. Aimware CSGO scripts need a manual port to these APIs.

## Template controls

Download a template below or use its bundled copy in Scripts. Standalone tools opens with F9 and Visual Studio with F10. Both offer an Open / close key setting and Save preferences. Hidden windows keep their selected overlays running. Unload removes script windows, callbacks and hotkeys. Changes to native CS2 settings persist.
`;
outputs.set('docs/cs2/snippets.md',snippets);
const destination='/api/cs2/';
let search=JSON.parse(fs.readFileSync(path.join(root,'assets/data/docs-search.json'),'utf8')).filter(x=>!x.href.startsWith(destination)&&!x.href.startsWith('/docs/cs2/'));
let navigation='';let count=0;
const sections=[['examples','Start here',snippets,'snippets.md'],['host','CS2 host API',host,'game-api.md'],['bindings','Binding index',bindings,'bindings.md'],['coverage','Coverage & porting',coverage,'coverage.md'],['ui','Shared UI API',shared,'ui-api.md']].map(([id,title,md,file])=>{
 const html=marked.parse(md.replace(/^# /gm,'## '));
 const headings=[...html.matchAll(/<h([2-6])>([\s\S]*?)<\/h\1>/g)],seen={};
 const entries=headings.map((h,i)=>{
  const slug=plain(h[2]).toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
  const n=seen[slug]=(seen[slug]||0)+1,anchor=id+'-'+slug+(n>1?'-'+n:'');
  const body=html.slice(h.index+h[0].length,headings[i+1]?.index??html.length).replace(/<table>([\s\S]*?)<\/table>/g,'<div class="table-wrap"><table>$1</table></div>');
  search.push({game:'Counter-Strike 2',title:plain(h[2]),href:destination+'#'+anchor,text:plain(body),newTab:true});count++;
  return {anchor,title:h[2],html:`<details class="reference-entry" id="${anchor}"${id==='examples'?' open':''}><summary>${h[2]}</summary><div class="entry-body"><a class="permalink" href="#${anchor}" aria-label="Link to ${esc(plain(h[2]))}"># Permalink</a>${body}</div></details>`};
 });
 navigation+=`<div class="nav-group" data-section="${id}"><a class="sect" href="#${id}">${title}</a>${entries.map(e=>`<a class="entry" href="#${e.anchor}">${e.title}</a>`).join('\n')}</div>`;
 return `<section class="reference-section lua-reference" id="${id}"><header><h2>${title}</h2><a class="download-source" href="/docs/cs2/${file}" download>Download Markdown</a></header>${entries.map(e=>e.html).join('\n')}</section>`;
}).join('\n');
function head(title,description,url){return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title} — Scooby Developer Docs</title><meta name="description" content="${description}"><link rel="canonical" href="https://scoobymenu.cc${url}"><link rel="icon" href="/assets/images/logo.png"><meta property="og:type" content="website"><meta property="og:title" content="${title}"><meta property="og:description" content="${description}"><meta property="og:url" content="https://scoobymenu.cc${url}"><meta property="og:image" content="https://scoobymenu.cc/background-home.jpg"><meta name="twitter:card" content="summary_large_image"><link rel="stylesheet" href="/assets/css/l4d-api-reference.css"><link rel="stylesheet" href="/assets/css/cs2-api-reference.css"><script defer src="/assets/js/l4d-docs.js"></script>`;}
outputs.set('api/cs2/index.html',head('CS2 Lua API','Search the Scooby CS2 API: console diagnostics, native hooks, binary utilities, animations, player snapshots and standalone Lua interfaces.',destination)+`<script defer src="/assets/js/cs2-api-reference.js"></script><noscript><style>.search-tools,.menu-toggle{display:none!important}#sidebar-nav{display:block!important}</style></noscript></head><body><a class="skip-link" href="#main-content">Skip to reference</a><aside class="sidebar" aria-label="CS2 API navigation"><div class="sidebar-heading"><a class="brand" href="/docs/">Scooby <span>Docs</span></a><button class="menu-toggle" aria-expanded="false" aria-controls="sidebar-nav">Sections</button></div><p class="game-label">COUNTER-STRIKE 2</p><div class="search-tools"><label for="api-search">Search the reference</label><div class="search-row"><input id="api-search" type="search" placeholder="Function or topic…" autocomplete="off"><button id="clear-search" aria-label="Clear search" hidden>Clear</button></div><p id="search-status" role="status" aria-live="polite"></p></div><nav id="sidebar-nav">${navigation}<div class="resources"><a href="/docs/cs2/">Templates &amp; quick start</a><a href="/docs/">All documentation</a></div></nav></aside><main class="content" id="main-content" tabindex="-1"><header class="page-header"><p class="page-title">Developer reference</p><h1>CS2 Lua API</h1><p class="version">HOST ${hostVersion} <span>UI 1.1 · Lua 5.4.7</span></p><p class="intro">Build custom command logic, player overlays, file modules and standalone interfaces with the API used by the bundled scripts.</p><div class="quick-links"><a href="/docs/cs2/">Get a template →</a><a href="/docs/cs2/cs2_v2.lua" download>Editor definitions ↓</a></div></header><p id="no-results" hidden>No matching topics. Try <code>entity.get_local_player</code> or clear the search.</p>${sections}<footer><a href="/docs/">Developer docs</a><a href="/docs/cs2/">Templates</a><a href="#main-content">Back to top ↑</a></footer></main></body></html>\n`);
const cards=templates.map(([name,title,description,key])=>`<article class="template-card"><p class="eyebrow">LUA TEMPLATE <kbd>${key}</kbd></p><h2>${title}</h2><p>${description}</p><a class="download" href="/docs/cs2/templates/${encodeURIComponent(name)}.lua" download>Download ${name}.lua ↓</a></article>`).join('');
outputs.set('docs/cs2/index.html',head('CS2 Lua scripts','Get started with Scooby CS2 Lua, download standalone visual templates, and browse the host and UI API.','/docs/cs2/')+`</head><body class="guide"><header class="guide-nav"><a class="brand" href="/docs/">Scooby <span>Docs</span></a><nav><a href="/docs/">All docs</a><a href="/api/cs2/">CS2 API →</a></nav></header><main id="main-content" class="guide-content"><p class="page-title">COUNTER-STRIKE 2 / LUA</p><h1>Your tools. Your interface.</h1><p class="intro">Start with a working visual template, make it your own, and keep the CS2 API close by.</p><div class="quick-links"><a href="/api/cs2/">Browse API reference →</a><a href="/docs/cs2/cs2_v2.lua" download>Editor definitions ↓</a></div><p class="version">HOST ${hostVersion} <span>UI 1.1 · Lua 5.4.7</span></p><section class="template-grid" aria-label="Lua templates">${cards}</section><section class="quick-start lua-reference"><h2>Run your first script</h2><ol><li>Open <strong>Scripts → Other → Open folder</strong> and place the downloaded Lua file there.</li><li>Select <strong>Refresh</strong>, choose the file and click <strong>Run</strong>. Its button becomes <strong>Unload</strong>.</li><li>Press <strong>F9</strong> for Standalone tools or <strong>F10</strong> for Visual Studio. Change the open/close key inside the window.</li><li>Use <strong>Edit</strong> to change code, <strong>Script UI</strong> for custom pages, and <strong>Unload</strong> to remove its windows and overlays.</li></ol><p>Save preferences inside either standalone template to restore its controls on the next run. Native ESP settings changed by a template keep their selected values after unload.</p><details class="reference-entry" open><summary>A small health overlay</summary><div class="entry-body">${marked.parse(snippets.split('## A toggleable CS2 overlay')[1].split('## Choose the correct API')[0])}</div></details></section><footer><a href="/api/cs2/">Complete API reference</a><a href="/docs/cs2/game-api.md" download>Host contract</a><a href="/docs/cs2/ui-api.md" download>UI reference</a></footer></main></body></html>\n`);
search.push({game:'Counter-Strike 2',title:'CS2 Lua templates and quick start',href:'/docs/cs2/',text:'Player ESP framework Asset download manager Command framework Inventory studio Download asset Standalone Menu ImGui Demo Visual Studio Crosshair Speed HUD F9 F10 Run Unload'});
outputs.set('assets/data/docs-search.json',JSON.stringify(search,null,2)+'\n');
outputs.set('docs/cs2/source-manifest.json',JSON.stringify({host_api:hostVersion,ui_api:'1.1',source_hash_format:'UTF-8 text with LF line endings',inputs},null,2)+'\n');
for (const [name, content] of outputs) { if (name.endsWith('.html')) outputs.set(name, applyMetadata(name, content)); }
const changed=[];
for(const [name,content] of outputs){const file=path.join(root,name);if(fs.existsSync(file)&&fs.readFileSync(file,'utf8').replace(/\r\n/g,'\n')===content)continue;changed.push(name);if(!args.includes('--check')){fs.mkdirSync(path.dirname(file),{recursive:true});const temp=file+'.'+process.pid+'.tmp';try{fs.writeFileSync(temp,content);fs.renameSync(temp,file);}finally{if(fs.existsSync(temp))fs.unlinkSync(temp);}}}
if(args.includes('--check')&&changed.length)throw new Error('Stale CS2 docs: '+changed.join(', '));
console.log(JSON.stringify({topics:count,updated:changed.length,check:args.includes('--check')}));
