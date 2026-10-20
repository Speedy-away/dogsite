// Source-backed GTA5/RDR2 Lua references. Local generation only; no publication.
// node tools/build-rockstar-lua-docs.cjs [--check] [--game GTA5|RDR2]
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),cp=require('node:child_process');
const {marked}=require('marked');
const site=path.resolve(__dirname,'..'),args=process.argv.slice(2),check=args.includes('--check');
const flag=(key,fallback)=>{const i=args.indexOf(key);return i<0?fallback:args[i+1]};
const family=path.resolve(site,'../Scooby-Op'),selected=flag('--game','both');
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const outputs=new Map(),summaries=[],searchRows=[];
const put=(file,data)=>outputs.set(file,Buffer.isBuffer(data)?data:Buffer.from(data));
const games=[{game:'GTA5',slug:'gta5',label:'GTA 5',root:flag('--gta-root',path.join(family,'GTA5/EE/GTA - Main Src')),route:'/api/gta5_api_reference.html',examples:'examples/lua',runtime:'LuaJIT · Lua 5.1 syntax'},
 {game:'RDR2',slug:'rdr2',label:'RDR2',root:flag('--rdr2-root',path.join(family,'RDR2/Scooby-RDR2-old - before-UI-update - working')),route:'/api/rdr2/',examples:'scripts/examples',runtime:'Lua 5.4.6 / LuaJIT 2.1'}].filter(g=>selected==='both'||g.game===selected);
if(!games.length)throw Error('Expected --game GTA5 or RDR2');
function zip(files){
 const chunks=[],central=[];let offset=0;
 const crc=b=>{let c=0xffffffff;for(const byte of b){c^=byte;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(c^0xffffffff)>>>0};
 for(const [name,data]of files){const n=Buffer.from(name),h=Buffer.alloc(30),c=Buffer.alloc(46),sum=crc(data);
  h.writeUInt32LE(0x04034b50);h.writeUInt16LE(20,4);h.writeUInt16LE(0x800,6);h.writeUInt16LE(33,12);h.writeUInt32LE(sum,14);h.writeUInt32LE(data.length,18);h.writeUInt32LE(data.length,22);h.writeUInt16LE(n.length,26);
  c.writeUInt32LE(0x02014b50);c.writeUInt16LE(20,4);c.writeUInt16LE(20,6);c.writeUInt16LE(0x800,8);c.writeUInt16LE(33,14);c.writeUInt32LE(sum,16);c.writeUInt32LE(data.length,20);c.writeUInt32LE(data.length,24);c.writeUInt16LE(n.length,28);c.writeUInt32LE(offset,42);
  chunks.push(h,n,data);central.push(c,n);offset+=h.length+n.length+data.length;
 }const cd=Buffer.concat(central),end=Buffer.alloc(22);end.writeUInt32LE(0x06054b50);end.writeUInt16LE(files.length,8);end.writeUInt16LE(files.length,10);end.writeUInt32LE(cd.length,12);end.writeUInt32LE(offset,16);return Buffer.concat([...chunks,cd,end]);
}
function shell(g,title,route,body,extra=''){
 const description=`${g.label} Lua API: ListUI and ClickUI pages, native themes, shared feature state, custom ImGui interfaces and game-specific developer references.`;
 return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(title)} | Scooby</title><meta name="description" content="${esc(description)}"><link rel="canonical" href="https://scoobymenu.cc${route}"><link rel="icon" href="/assets/images/brand/scooby-logo.png"><meta property="og:type" content="website"><meta property="og:title" content="${esc(title)}"><meta property="og:description" content="${esc(description)}"><meta property="og:url" content="https://scoobymenu.cc${route}"><meta property="og:image" content="https://scoobymenu.cc/assets/images/social/docs-v2.png"><link rel="stylesheet" href="/assets/css/l4d-api-reference.css"><link rel="stylesheet" href="/assets/css/tf2-docs.css"><link rel="stylesheet" href="/assets/css/rockstar-lua-docs.css">${extra}</head><body class="game-${g.slug}${route.startsWith('/docs/')?' guide':''}"><a class="skip-link" href="#main-content">Skip to documentation</a>${body}</body></html>\n`;
}
function links(g){const base='/docs/'+g.slug;return `<a href="${g.route}">API reference</a><a href="${base}/custom-ui/">ListUI, ClickUI &amp; custom GUI</a><a href="${base}/imgui-porting/">C++ ImGui porting</a><a href="${base}/developer-files/">Developer files</a><a href="${base}/examples.zip" download>Lua examples</a><a href="${base}/developer-files.zip" download>Developer references</a>`}
function guide(g,title,route,html){return shell(g,title,route,`<header class="guide-nav"><a class="brand" href="/docs/">Scooby <span>Docs</span></a><nav><a href="/docs/${g.slug}/">${g.label} Lua</a><a href="${g.route}">API reference</a></nav></header><main id="main-content" class="guide-content"><p class="page-title">${g.label} / LUA</p>${html}<footer>${links(g)}</footer></main>`)}
for(const g of games){
 const root=path.resolve(g.root),base='docs/'+g.slug,inputs={};
 const read=(relative)=>{const b=fs.readFileSync(path.join(root,relative));inputs[relative]=sha(b);return b};
 // Regenerate into build/, never infer truth from a stale site JSON or editor stub.
 const generated=path.join(root,'build/site-lua-docs/generated');
 const cache=fs.readFileSync(path.join(root,g.game==='GTA5'?'build/x64-MSVC/CMakeCache.txt':'build/x64/vs2022/CMakeCache.txt'),'utf8');
 const python=flag('--python',cache.match(/^_Python3_EXECUTABLE:INTERNAL=(.*)$/m)?.[1]?.trim()||'python');
 cp.execFileSync(python,[path.join(root,'tools/generate_lua_developer_files.py'),'--root',root,'--output',generated],{stdio:'inherit'});
 read('tools/generate_lua_developer_files.py');
 const docs=fs.readFileSync(path.join(generated,'Documentation.json')),catalog=JSON.parse(docs),rows=[];
 if(catalog._meta.game!==g.game||!catalog._meta.references_only)throw Error('Wrong game catalog');
 for(const [ns,members]of Object.entries(catalog).sort(([a],[b])=>a.localeCompare(b))){if(ns.startsWith('_')||!members||Array.isArray(members)||typeof members!=='object')continue;
  for(const [name,e]of Object.entries(members).sort(([a],[b])=>a.localeCompare(b)))if(e&&typeof e==='object')rows.push([ns,name,e.Signature||`${ns}.${name}`,e.Example||'',e.Description||'',e.Available!==false,e.Reason||'',e.Kind||'']);
 }
 for(const name of ['list','get','set','call','add_page','remove_page'])if(!catalog.features?.[name]?.Available)throw Error('Missing features.'+name);
 const generatedManifest=JSON.parse(fs.readFileSync(path.join(generated,'manifest.json'),'utf8'));
 const native=rows.filter(r=>r[7]==='native'),stats={entries:rows.length,available:rows.filter(r=>r[5]).length,native_declarations:generatedManifest.native_total,native_supported:native.filter(r=>r[5]).length};
 const data={schema:1,game:g.game,revision:'2026.10.20',runtime:g.runtime,source_sha256:sha(docs),stats,rows};
 put(base+'/catalog.json',JSON.stringify(data)+'\n');
 const references=[];
 for(const name of ['Documentation.json','DataNodes.lua','natives.lua']){const b=fs.readFileSync(path.join(generated,name));if(b.toString().toLowerCase().includes('cherax'))throw Error('Unexpected source branding in developer export');put(base+'/developer/'+name,b);references.push([name,b]);}
 put(base+'/developer-files.zip',zip(references));
 const examples=[];
 for(const name of ['SharedFeatureUI.lua','NativeFeaturePage.lua','ImGuiCppDemo.lua']){const b=read(g.examples+'/'+name);put(base+'/examples/'+name,b);examples.push([name,b]);}
 put(base+'/examples.zip',zip(examples));
 const guides=[['LUA_CUSTOM_UI.md','custom-ui','ListUI, ClickUI and custom interfaces'],['lua-imgui-porting.md','imgui-porting','Porting C++ ImGui interfaces'],['LUA_DEVELOPER_FILES.md','developer-files','Generated developer references']];
 for(const [file,slug,title]of guides){const md=read('docs/'+file).toString().replace(/\r\n?/g,'\n');put(base+'/'+file,md);
  let html=marked.parse(md);for(const [target,targetSlug]of guides)html=html.replaceAll(`href="${target}"`,`href="/docs/${g.slug}/${targetSlug}/"`);
  put(base+'/'+slug+'/index.html',guide(g,title,`/docs/${g.slug}/${slug}/`,html));
  searchRows.push({game:g.label,title,href:`/docs/${g.slug}/${slug}/`,text:md.replace(/[`#*]/g,'').slice(0,9000),tags:['Lua','ListUI','ClickUI','ImGuiCpp']});
 }
 // Keep existing RDR2 host-topic deep links and the practical runtime contract.
 const topics=[];
 if(g.game==='RDR2'){
  for(const [file,target]of [['lua-runtime-api.md','runtime-api.md'],['lua-api-reference.md','api-reference.md'],['lua-porting-compatibility.md','porting-compatibility.md']])put(base+'/'+target,read('docs/'+file));
  const reference=marked.parse(read('docs/lua-api-reference.md').toString()),heads=[...reference.matchAll(/<h2>([\s\S]*?)<\/h2>/g)];
  heads.forEach((h,i)=>{const title=h[1].replace(/<[^>]*>/g,'');const html=reference.slice(h.index+h[0].length,heads[i+1]?.index??reference.length);const code=[...html.matchAll(/<pre>[\s\S]*?<\/pre>|<table>[\s\S]*?<\/table>/g)].map(m=>m[0]).join('');if(code)topics.push({id:'host-'+title.toLowerCase().replace(/[^a-z0-9]+/g,'-'),title,html:code})});
  const nativeText=read('build/x64/vs2022/generated/lua/lua-native-catalog.json');put(base+'/native-catalog.json',nativeText);
 }
 const topicHtml=topics.map(t=>`<details class="reference-entry" id="${t.id}"><summary>${esc(t.title)}</summary><div class="entry-body">${t.html}</div></details>`).join('');
 const body=`<aside class="sidebar" aria-label="${g.label} Lua navigation"><div class="sidebar-heading"><a class="brand" href="/docs/">Scooby <span>API</span></a><button class="menu-toggle" type="button" aria-expanded="false" aria-controls="sidebar-nav">Sections</button></div><p class="game-label">${g.label} LUA</p><nav id="sidebar-nav"><a href="#catalog-browser">Search all API entries</a>${links(g)}${topics.map(t=>`<a href="#${t.id}">${esc(t.title)}</a>`).join('')}</nav></aside><main class="content" id="main-content" tabindex="-1"><header class="page-header"><p class="page-title">Scooby API Reference</p><h1>${g.label} Lua API</h1><p class="version">Reference 2026.10.20 <span>${g.runtime}</span></p><div class="quick-links"><a href="/docs/${g.slug}/custom-ui/">ListUI + ClickUI + custom GUI</a><a href="/docs/${g.slug}/examples.zip" download>Working examples</a><a href="/docs/${g.slug}/developer-files.zip" download>Editor references</a></div></header><section id="catalog-browser" data-catalog="/docs/${g.slug}/catalog.json"><div class="catalog-filters"><label for="api-search">Search names, signatures and examples</label><input id="api-search" type="search" placeholder="features.set, ui_theme, ImGuiCpp…" autocomplete="off"><div class="catalog-selects"><label for="api-namespace">Namespace</label><select id="api-namespace"><option value="">All namespaces</option></select><label class="availability"><input id="include-unavailable" type="checkbox"> Include unavailable</label><button id="clear-search" type="button">Clear</button></div></div><p id="search-status" role="status" aria-live="polite">Loading source catalog…</p><div id="api-entries"></div><p id="no-results" hidden>No matching API entries.</p><button id="show-more" type="button" hidden>Show more entries</button><noscript><p>JavaScript powers the searchable catalog. Download <a href="/docs/${g.slug}/developer/Documentation.json">Documentation.json</a> or use the guides.</p></noscript></section>${topicHtml?`<section id="host-topics"><h2>Runtime examples</h2>${topicHtml}</section>`:''}<footer><a href="/docs/${g.slug}/source-manifest.json">Source manifest</a><a href="/docs/${g.slug}/developer/Documentation.json" download>Complete JSON reference</a><a href="/docs/">All documentation</a></footer></main>`;
 put(g.route.endsWith('/')?g.route.slice(1)+'index.html':g.route.slice(1),shell(g,g.label+' Lua API',g.route,body,'<script defer src="/assets/js/rockstar-lua-docs.js"></script>'));
 const landing=`<h1>Build your ${g.label} interface.</h1><p class="intro">Extend ListUI and ClickUI, design a standalone ImGui window, and control the same features as the main menu.</p><div class="quick-links">${links(g)}</div><section class="quick-start"><h2>Start with working scripts</h2><ul><li><a href="/docs/${g.slug}/examples/NativeFeaturePage.lua" download>NativeFeaturePage.lua</a> adds existing features to both native frontends.</li><li><a href="/docs/${g.slug}/examples/SharedFeatureUI.lua" download>SharedFeatureUI.lua</a> demonstrates shared state, search, command types and themes.</li><li><a href="/docs/${g.slug}/examples/ImGuiCppDemo.lua" download>ImGuiCppDemo.lua</a> demonstrates C++ style ImGui calls.</li></ul><p>Copy a chosen script into this game's Lua folder, refresh the script list and enable it. Read the script's comments for its controls.</p></section><section class="quick-start"><h2>Developer reference files</h2><p>The host creates Documentation.json, DataNodes.lua and natives.lua automatically. The two Lua files are editor annotations and cannot execute or load as modules. Gameplay scripts use the built-in API.</p><p>These downloads describe this game's supported bindings. GTA5 node schemas are not RDR2 layouts; unavailable entries retain their reason.</p></section><section class="quick-start"><h2>Runtime and availability</h2><p>${g.runtime}. ${stats.native_supported.toLocaleString('en-US')} supported typed native signatures from ${stats.native_declarations.toLocaleString('en-US')} declarations. Host access checks and game-callback requirements apply to feature commands.</p><p>Source and contract validation do not establish live in-game behavior, input or performance. Check each API signature and availability badge before using it.</p></section><section class="quick-start"><h2>Standalone toolbox</h2><p>The existing Vesper package remains available.</p><a href="/docs/${g.slug}/${g.game==='GTA5'?'Vesper':'Frontier'}.zip" download>Download Vesper</a> · <a href="/docs/${g.slug}/${g.game==='GTA5'?'Vesper':'Frontier'}/README.md">Package setup</a></section>`;
 put(base+'/index.html',guide(g,g.label+' Lua documentation',`/docs/${g.slug}/`,landing));
 // The manifest fingerprints the exact source catalogs/guides/examples used.
 put(base+'/source-manifest.json',JSON.stringify({schema:2,game:g.game,revision:'2026.10.20',runtime:g.runtime,source_catalog_sha256:sha(docs),...stats,inputs,
  exports:Object.fromEntries(references.map(([name,b])=>[name,sha(b)])),examples:Object.fromEntries(examples.map(([name,b])=>[name,sha(b)])),
  runtime_acceptance:'Not established by documentation generation'},null,2)+'\n');
 searchRows.push({game:g.label,title:g.label+' Lua API',href:g.route,text:`${stats.entries} catalog entries. features list get set call add_page remove_page ui_theme ListUI ClickUI ImGuiCpp native references`});
 for(const ns of ['features','ui_theme','ImGuiCpp','ImGuiKey','script','Native','natives'])if(catalog[ns])searchRows.push({game:g.label,title:ns+' · '+g.label,href:g.route+'?namespace='+encodeURIComponent(ns),text:ns+' '+Object.keys(catalog[ns]).join(' '),newTab:true});
 summaries.push({game:g.game,route:g.route,...stats});
}
const owned=e=>games.some(g=>e.href===g.route||e.href.startsWith(g.route+'?')||e.href.startsWith(g.route+'#')||e.href.startsWith('/docs/'+g.slug+'/')||g.game==='RDR2'&&e.href.startsWith('/api/rdr2/'));
const searchPath=path.join(site,'assets/data/docs-search.json');
const search=JSON.parse(fs.readFileSync(searchPath,'utf8')).filter(e=>!owned(e));search.push(...searchRows);
put('assets/data/docs-search.json',JSON.stringify(search,null,2)+'\n');
const hubPath=path.join(site,'docs/index.html');let hub=fs.readFileSync(hubPath,'utf8');
for(const g of games){const route=g.route.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');const stats=summaries.find(s=>s.game===g.game);
 hub=hub.replace(new RegExp(`(<a class="topic-card docs-card" href="${route}">)[\\s\\S]*?(</a>)`),match=>match
  .replace(/(<p>)[\s\S]*?(<\/p>)/,'$1ListUI, ClickUI, native themes, shared feature state, ImGuiCpp and game-specific references.$2')
  .replace(/(<span class="docs-card-foot">)[^<]*/,'$1'+stats.available.toLocaleString('en-US')+' available entries'))}
put('docs/index.html',hub);
const changed=[];
for(const [relative,data]of outputs){const target=path.join(site,relative),current=fs.existsSync(target)?fs.readFileSync(target):null;
 if(current?.equals(data))continue;changed.push(relative);if(!check){fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,data)}}
console.log(JSON.stringify({localOnly:true,games:summaries,changed},null,2));
if(check&&changed.length)process.exitCode=1;
