// node tools/build-rdr2-docs.js [--check] [--rdr2-root PATH]
// Requires marked (same dependency as the existing documentation generators).
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {marked}=require('marked');
const root=path.resolve(__dirname,'..'),args=process.argv.slice(2);
const at=args.indexOf('--rdr2-root');
const host=at<0?path.resolve(root,'../Scooby-Op/RDR2/Scooby-RDR2-old - before-UI-update - working'):path.resolve(args[at+1]);
const pkg=path.resolve(host,'../Lua/Frontier'),outputs=new Map(),inputs={};
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/\s+/g,' ').trim();
function read(base,file,label){
 const data=fs.readFileSync(path.join(base,file),'utf8').replace(/\r\n?/g,'\n');
 inputs[label+'/'+file]=crypto.createHash('sha256').update(data).digest('hex');return data;
}
const version=read(host,'src/core/scripting/LuaRuntime.hpp','host').match(/ApiVersion = "([\d.]+)"/)?.[1];
if(!version)throw Error('Host API version unavailable');
const runtime=read(host,'docs/lua-runtime-api.md','host');
const reference=read(host,'docs/lua-api-reference.md','host');
const porting=read(host,'docs/lua-porting-compatibility.md','host');
const catalogText=read(host,'build/x64/vs2022/generated/lua/lua-native-catalog.json','host');
const catalog=JSON.parse(catalogText),supported=catalog.filter(n=>n.supported).length;
for(const f of ['src/core/scripting/LuaInputScript.hpp','src/core/scripting/LuaVersions.cpp','src/core/scripting/bindings/LuaInput.cpp','src/game/rdr/Natives.hpp'])read(host,f,'host');
outputs.set('docs/rdr2/runtime-api.md',runtime);
outputs.set('docs/rdr2/api-reference.md',reference);
outputs.set('docs/rdr2/porting-compatibility.md',porting);
outputs.set('docs/rdr2/native-catalog.json',catalogText);
const packageFiles=['main.lua','frontier/model.lua','frontier/view.lua','README.md'];
const archive=[];
for(const f of packageFiles){
 const data=read(pkg,f,'Frontier');outputs.set('docs/rdr2/Frontier/'+f,data);
 archive.push(['Frontier/'+f,Buffer.from(data)]);
}
// Deterministic uncompressed ZIP: no npm archive dependency and no timestamps.
function zip(files){
 const chunks=[],central=[];let offset=0;
 function crc(b){let c=0xffffffff;for(const byte of b){c^=byte;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0);}return (c^0xffffffff)>>>0;}
 for(const [name,data] of files){
  const n=Buffer.from(name),h=Buffer.alloc(30),c=Buffer.alloc(46),sum=crc(data);
  h.writeUInt32LE(0x04034b50);h.writeUInt16LE(20,4);h.writeUInt16LE(0x800,6);h.writeUInt16LE(33,12);
  h.writeUInt32LE(sum,14);h.writeUInt32LE(data.length,18);h.writeUInt32LE(data.length,22);h.writeUInt16LE(n.length,26);
  c.writeUInt32LE(0x02014b50);c.writeUInt16LE(20,4);c.writeUInt16LE(20,6);c.writeUInt16LE(0x800,8);c.writeUInt16LE(33,14);
  c.writeUInt32LE(sum,16);c.writeUInt32LE(data.length,20);c.writeUInt32LE(data.length,24);c.writeUInt16LE(n.length,28);c.writeUInt32LE(offset,42);
  chunks.push(h,n,data);central.push(c,n);offset+=h.length+n.length+data.length;
 }
 const cd=Buffer.concat(central),end=Buffer.alloc(22);end.writeUInt32LE(0x06054b50);
 end.writeUInt16LE(files.length,8);end.writeUInt16LE(files.length,10);end.writeUInt32LE(cd.length,12);end.writeUInt32LE(offset,16);
 return Buffer.concat([...chunks,cd,end]);
}
outputs.set('docs/rdr2/Frontier.zip',zip(archive));
let search=JSON.parse(fs.readFileSync(path.join(root,'assets/data/docs-search.json'),'utf8')).filter(x=>!/^\/(api|docs)\/rdr2\//.test(x.href));
let nav='',entryCount=0;
function section(id,title,entries){
 nav+='<div class="nav-group" data-section="'+id+'"><a class="sect" href="#'+id+'">'+esc(title)+'</a>';
 let body='';
 for(const e of entries){
  const anchor=id+'-'+e.slug;entryCount++;
  nav+='<a class="entry" href="#'+anchor+'">'+esc(e.title)+'</a>';
  body+='<details class="reference-entry" id="'+anchor+'"><summary>'+esc(e.title)+'</summary><div class="entry-body"><a class="permalink" href="#'+anchor+'"># Permalink</a>'+e.html+'</div></details>';
  search.push({game:'RDR2',title:e.title,href:'/api/rdr2/#'+anchor,text:plain(e.html),tags:['RDR2','Lua','LuaJIT'],newTab:true});
 }
 nav+='</div>';return '<section class="reference-section lua-reference" id="'+id+'"><header><h2>'+esc(title)+'</h2></header>'+body+'</section>';
}
const parsed=marked.parse(reference),headings=[...parsed.matchAll(/<h2>([\s\S]*?)<\/h2>/g)];
const entries=headings.map((h,i)=>{
 const raw=parsed.slice(h.index+h[0].length,headings[i+1]?.index??parsed.length);
 return {title:plain(h[1]),slug:plain(h[1]).toLowerCase().replace(/[^a-z0-9]+/g,'-'),html:[...raw.matchAll(/<pre>[\s\S]*?<\/pre>|<table>[\s\S]*?<\/table>/g)].map(m=>m[0]).join('\n')};
}).filter(e=>e.html);
let content=section('host','Host API '+version,entries);
const nativeGroups=new Map();
for(const n of catalog.filter(n=>n.supported)){
 const values=nativeGroups.get(n.namespace)||[];values.push(n);nativeGroups.set(n.namespace,values);
}
content+=section('natives','Typed RDR2 natives',Array.from(nativeGroups,([ns,values])=>({
 title:ns+' ('+values.length+')',slug:ns.toLowerCase(),
 html:'<pre><code class="language-lua">'+esc(values.map(n=>ns+'.'+n.name+'('+n.arguments.map((type,i)=>type+' arg'+(i+1)).join(', ')+') -> '+n.returnType).join('\n'))+'</code></pre>'
})));
function head(title,route,description){
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+esc(title)+' | Scooby</title><meta name="description" content="'+esc(description)+'"><link rel="canonical" href="https://scoobymenu.cc'+route+'"><link rel="icon" href="/assets/images/logo.png"><link rel="stylesheet" href="/assets/css/l4d-api-reference.css"><link rel="stylesheet" href="/assets/css/tf2-docs.css"><script defer src="/assets/js/l4d-docs.js"></script>';
}
const api=head('RDR2 Lua API','/api/rdr2/','Scooby RDR2 Lua API '+version+': standalone GUI, controllers, tasks, LuaJIT and typed native signatures.')+
 '<script defer src="/assets/js/tf2-api-reference.js"></script><noscript><style>.menu-toggle,.search-tools{display:none!important}.sidebar{position:static!important;width:auto!important;height:auto!important}.content{margin-left:0!important}#sidebar-nav{display:block!important;max-height:none!important}</style></noscript></head><body><a class="skip-link" href="#main-content">Skip to reference</a><aside class="sidebar" aria-label="RDR2 API navigation"><div class="sidebar-heading"><a class="brand" href="/docs/">Scooby <span>API</span></a><button class="menu-toggle" type="button" aria-expanded="false" aria-controls="sidebar-nav">Sections</button></div><p class="game-label">RED DEAD REDEMPTION 2</p><div class="search-tools"><label for="api-search">Search the reference</label><div class="search-row"><input id="api-search" type="search" placeholder="Function or topic..." autocomplete="off"><button id="clear-search" aria-label="Clear search" hidden>Clear</button></div><p id="search-status" role="status" aria-live="polite"></p></div><nav id="sidebar-nav">'+nav+'<div class="resources"><a href="/docs/rdr2/">Vesper &amp; quick start</a><a href="/guides/rdr2/lua-scripts/">Installing scripts</a><a href="/docs/rdr2/runtime-api.md" download>Runtime contract</a><a href="/docs/rdr2/native-catalog.json" download>Native availability JSON</a></div></nav></aside><main class="content" id="main-content" tabindex="-1"><header class="page-header"><p class="page-title">Scooby <span>API Reference</span></p><h1>RDR2 Lua API</h1><p class="version">API '+version+' <span>Lua 5.4.6 / LuaJIT 2.1</span></p><div class="quick-links"><a href="/docs/rdr2/">Get Vesper</a><a href="/docs/rdr2/runtime-api.md" download>Runtime contract</a><a href="/docs/rdr2/native-catalog.json" download>'+supported+' supported native signatures</a></div></header><p id="no-results" hidden>No matching entries. Clear your search or try PLAYER_PED_ID.</p>'+content+'<footer><a href="/docs/rdr2/">Scripts &amp; examples</a><a href="/docs/">All documentation</a><a href="#main-content">Back to top</a></footer></main></body></html>\n';
outputs.set('api/rdr2/index.html',api);
const quick=head('RDR2 Lua scripts','/docs/rdr2/','Download Vesper, a standalone RDR2 Lua toolbox, and browse Scooby Lua '+version+' documentation.')+
 '</head><body class="guide"><a class="skip-link" href="#main-content">Skip to documentation</a><header class="guide-nav"><a class="brand" href="/docs/">Scooby <span>Docs</span></a><nav><a href="/guides/rdr2/">RDR2 guide</a><a href="/api/rdr2/">API reference</a></nav></header><main id="main-content" class="guide-content"><p class="page-title">RED DEAD REDEMPTION 2 / LUA</p><h1>Your trail. Your tools.</h1><p class="intro">Build your own interface with Scooby Lua, or start with Vesper: a complete standalone toolbox for your player, horse and travels.</p><p class="version">API '+version+' <span>Lua54 + LuaJIT</span></p><div class="quick-links"><a href="/docs/rdr2/Frontier.zip" download>Download Vesper</a><a href="/api/rdr2/">Browse the API</a><a href="/docs/rdr2/runtime-api.md" download>Runtime contract</a></div><div class="template-grid"><article class="template-card"><p class="eyebrow">VESPER <kbd>F7 / LB + DOWN</kbd></p><h2>One window. Five pages.</h2><p>Player and horse recovery actions, live status, saved travel locations, return travel, weather/time controls and a compact HUD.</p><a class="download" href="/docs/rdr2/Frontier.zip" download>Download complete package</a></article><article class="template-card"><p class="eyebrow">MODULES</p><h2>Make it yours.</h2><p>Custom outlined buttons, switches, sliders and vector icons. Separate entry point, feature model and view; game actions run in tasks.</p><a class="download" href="/docs/rdr2/Frontier/README.md">Read package instructions</a></article><article class="template-card"><p class="eyebrow">REFERENCE</p><h2>Check what is available.</h2><p>'+supported+' typed native bindings from '+catalog.length+' declarations. Unsupported signatures and reasons remain visible in the downloadable catalog.</p><a class="download" href="/docs/rdr2/native-catalog.json" download>Download native catalog</a></article></div><section class="quick-start" id="install"><h2>Install Vesper</h2><ol><li>Use the Scooby host with Lua API '+version+' or a compatible newer 2.x version.</li><li>Extract the entire <code>Frontier</code> folder into <code>C:\\scooby\\RDR2\\lua</code>. The entry point is <code>Frontier\\main.lua</code>; keep its <code>frontier</code> subfolder beside it. Vesper retains the Frontier folder identity to preserve existing saved settings.</li><li>Refresh the script list and enable <strong>Vesper</strong>. Refresh discovers files without stopping running scripts. Reload recreates the selected state.</li><li>Press F7 or LB/L1 + D-pad Down. Close the host menu for Vesper controller navigation: LB/RB changes pages, Up/Down selects, A/Cross executes and B/Circle closes.</li></ol></section><section class="quick-start"><h2>Choose your runtime</h2><p>Lua 5.4.6 is the default. The separate LuaJIT 2.1 host uses Lua 5.1 syntax and provides real FFI with compiled traces disabled. Vesper supports both. A LuaJIT host does not parse Lua 5.4 operators or <code>&lt;const&gt;</code> declarations.</p><p>Yim compatibility covers selected host conventions and ImGui adapters. GTA scripts still need their game logic ported to RDR2. <a href="/docs/rdr2/porting-compatibility.md">Read the porting comparison.</a></p></section><section class="quick-start"><h2>Work with game state</h2><p>Travel uses recorded positions, carries your current horse or driven vehicle, and refuses passenger vehicle moves. Weather/time overrides set by Vesper are cleared during normal script unload. The game and other scripts share these settings.</p><p>The shipped tests use fixture game data. Physical controller behavior, game natives, DX12/Vulkan and performance still require acceptance in RDR2 with the exact host build.</p></section><footer><a href="/api/rdr2/">API reference</a><a href="/guides/rdr2/lua-scripts/">Script troubleshooting</a><a href="/docs/rdr2/source-manifest.json">Source manifest</a></footer></main></body></html>\n';
outputs.set('docs/rdr2/index.html',quick);
search.push({game:'RDR2',title:'Vesper standalone GUI and Lua quick start',href:'/docs/rdr2/',text:'API '+version+' Vesper F7 controller Lua54 LuaJIT standalone GUI saved locations horse player world'});
outputs.set('assets/data/docs-search.json',JSON.stringify(search,null,2)+'\n');
outputs.set('docs/rdr2/source-manifest.json',JSON.stringify({schema:1,api:version,runtimes:['Lua54','LuaJIT'],native_declarations:catalog.length,native_supported:supported,reference_entries:entryCount,inputs},null,2)+'\n');
const hub=fs.readFileSync(path.join(root,'docs/index.html'),'utf8');
const card='<a class="topic-card docs-card" href="/api/rdr2/"><span class="docs-kind">Lua · RDR2</span><h3>Red Dead Redemption 2 ↗</h3><p>Standalone GUI, controllers, Lua54/LuaJIT and typed native signatures.</p><span class="docs-card-foot">Host API '+version+'<span>Open reference →</span></span></a>';
const upcoming=/<div class="topic-card docs-card docs-upcoming">\s*<span class="docs-kind">Lua<\/span>\s*<h3>RDR2<\/h3>[\s\S]*?<\/div>/;
outputs.set('docs/index.html',upcoming.test(hub)?hub.replace(upcoming,card):hub.replace(/<a class="topic-card docs-card" href="\/api\/rdr2\/">[\s\S]*?<\/a>/,card));
function ownedSearch(text){return JSON.parse(text).filter(x=>/^\/(api|docs)\/rdr2\//.test(x.href)).sort((a,b)=>a.href.localeCompare(b.href));}
let changed=[];
for(const [relative,data] of outputs){
 const target=path.join(root,relative),bytes=Buffer.isBuffer(data)?data:Buffer.from(data);
 const current=fs.existsSync(target)?fs.readFileSync(target):null;
 const equal=relative==='assets/data/docs-search.json'&&current?JSON.stringify(ownedSearch(current))===JSON.stringify(ownedSearch(bytes)):current?.equals(bytes);
 if(equal)continue;changed.push(relative);
 if(!args.includes('--check')){fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,bytes);}
}
console.log(JSON.stringify({api:version,entries:entryCount,natives:supported,changed},null,2));
if(args.includes('--check')&&changed.length)process.exitCode=1;
