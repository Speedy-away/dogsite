const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const {marked} = require('marked');
const {applyMetadata} = require('./seo-metadata');
const {applyBranding} = require('./site-branding');
const root = path.resolve(__dirname, '..');
const destination = '/api/l4d_api_reference.html';
const check = process.argv.includes('--check');
const argument = name => {
  const index = process.argv.indexOf(name);
  if (index < 0) return null;
  if (!process.argv[index + 1] || process.argv[index + 1].startsWith('--')) throw new Error('Missing value for ' + name);
  return path.resolve(process.argv[index + 1]);
};
const host = argument('--l4d-root') || path.resolve(root, '../Scooby-Op/source/L4D-Debug');
const ui = argument('--ui-root') || path.resolve(host, '../../simple-base/UI');
const outputs = new Map();
const sourceFiles = {
  'game-api.md': path.join(host, 'docs/L4D_LUA_API.md'),
  'snippets.md': path.join(host, 'docs/L4D_LUA_SNIPPETS.md'),
  'ui-api.md': path.join(ui, 'docs/LUA_API.md')
};
const sourceText = Object.fromEntries(Object.entries(sourceFiles).map(([name,file]) => [name,fs.readFileSync(file,'utf8').replace(/\r\n/g,'\n')]));
const hash = content => crypto.createHash('sha256').update(content).digest('hex');
const manifest = {schema:1, hostApi:'1.0', nativeApi:'1.1', uiApi:'1.1', files:{}};
for (const [name,text] of Object.entries(sourceText)) {
  outputs.set('docs/l4d/'+name,text);
  manifest.files[name]=hash(text);
}
const templates=fs.readdirSync(path.join(host,'assets/scripts')).filter(name=>name.endsWith('.lua')).sort();
for(const name of templates) {
  const content=fs.readFileSync(path.join(host,'assets/scripts',name),'utf8').replace(/\r\n/g,'\n');
  outputs.set('docs/l4d/templates/'+name,content);
  manifest.files['templates/'+name]=hash(content);
}
outputs.set('docs/l4d/sources.json',JSON.stringify(manifest,null,2)+'\n');
const esc = value => value.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const plain = value => value.replace(/<[^>]*>/g,'').replace(/&amp;/g,'&').replace(/&#39;/g,"'").replace(/&quot;/g,'"');
const anchorsPath=path.join(root,'docs/l4d/anchors.json');
const anchors=fs.existsSync(anchorsPath)?JSON.parse(fs.readFileSync(anchorsPath,'utf8')):{};
const previousSearch=JSON.parse(fs.readFileSync(path.join(root,'assets/data/docs-search.json'),'utf8'));
for(const entry of previousSearch) {
  const match=entry.href.match(/^\/api\/l4d_api_reference\.html#(snippets|game-api|ui-api)-(\d+)$/);
  if(match) {
    anchors[match[1]] ||= {};
    anchors[match[1]][entry.title] ||= match[1]+'-'+match[2];
  }
}
const search=previousSearch.filter(entry=>!entry.href.startsWith('/docs/l4d/')&&!entry.href.startsWith(destination));
const sources=[['snippets','Code snippets','snippets.md'],['game-api','L4D host API','game-api.md'],['ui-api','UI, features and rendering','ui-api.md']];
let navigation='';
const sections=sources.map(([id,title,file])=>{
  const md=sourceText[file];
  const html=marked.parse(md.replace(/^# /gm,'## '));
  const headings=[...html.matchAll(/<h([2-6])>([\s\S]*?)<\/h\1>/g)];
  anchors[id] ||= {};
  let next=Math.max(0,...Object.values(anchors[id]).map(value=>Number(value.split('-').at(-1))))+1;
  const entries=headings.map((heading,index)=>{
    const headingTitle=plain(heading[2]);
    const anchor=anchors[id][headingTitle] ||= id+'-'+next++;
    const body=html.slice(heading.index+heading[0].length,headings[index+1]?.index??html.length)
      .replace(/<table>([\s\S]*?)<\/table>/g,'<div class="table-wrap"><table>$1</table></div>');
    search.push({game:'Left 4 Dead 1 & 2',title:headingTitle,href:destination+'#'+anchor,text:plain(body),newTab:true});
    return {anchor,title:heading[2],html:`<article class="reference-entry"><h3 id="${anchor}">${heading[2]} <a class="permalink" href="#${anchor}" aria-label="Link to ${esc(headingTitle)}">#</a></h3>${body}</article>`};
  });
  navigation+=`<div class="nav-group" data-section="${id}"><a class="sect" href="#${id}">${title}</a>${entries.map(entry=>`<a class="entry" href="#${entry.anchor}">${entry.title}</a>`).join('\n')}</div>`;
  search.push({game:'Left 4 Dead 1 & 2',title,href:destination+'#'+id,text:md.replace(/[`#*|]/g,' ').slice(0,8000),newTab:true});
  return `<section class="reference-section lua-reference" id="${id}"><header><h2>${title}</h2><a class="download-source" href="/docs/l4d/${file}" download>Download Markdown</a></header>${entries.map(entry=>entry.html).join('\n')}</section>`;
}).join('\n');
const title='Left 4 Dead Lua API Reference - Scooby Developer Docs';
const description='L4D1 and L4D2 Lua API: native function hooks, pattern scans, console diagnostics, entity snapshots, UI controls and copyable examples.';
const structured={"@context":"https://schema.org","@type":"WebPage",url:'https://scoobymenu.cc'+destination,name:title,description};
const html=`<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title><meta name="description" content="${description}">
<meta name="robots" content="index, follow, max-image-preview:large">
<link rel="canonical" href="https://scoobymenu.cc${destination}">
<link rel="shortcut icon" href="/assets/images/logo.png">
<meta property="og:type" content="website"><meta property="og:site_name" content="Scooby Menu">
<meta property="og:url" content="https://scoobymenu.cc${destination}"><meta property="og:title" content="${title}">
<meta property="og:description" content="${description}"><meta property="og:image" content="https://scoobymenu.cc/background-home.jpg">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="${title}">
<meta name="twitter:description" content="${description}"><meta name="twitter:image" content="https://scoobymenu.cc/background-home.jpg">
<meta name="twitter:url" content="https://scoobymenu.cc${destination}">
<meta name="keywords" content="Scooby, L4D Lua API, native hooks, pattern scanning, Lua console, stack trace">
<script type="application/ld+json" id="seo-page-structure">${JSON.stringify(structured).replace(/</g,'\\u003c')}</script>
<link rel="stylesheet" href="/assets/css/l4d-api-reference.css">
<script defer src="/assets/js/l4d-docs.js"></script><script defer src="/assets/js/l4d-api-reference.js"></script>
<noscript><style>.menu-toggle,.search-tools{display:none!important}.sidebar{position:static!important;width:auto!important;height:auto!important}.content{margin-left:0!important}#sidebar-nav{display:block!important;max-height:none!important}</style></noscript>
<script src="/lang/i18n.js"></script>
</head><body>
<a class="skip-link" href="#main-content">Skip to reference</a>
<aside class="sidebar" aria-label="L4D API navigation">
<div class="sidebar-heading"><a class="brand" href="/docs/">Scooby <span>API</span></a><button class="menu-toggle" type="button" aria-expanded="false" aria-controls="sidebar-nav">Sections</button></div>
<p class="game-label">LEFT 4 DEAD 1 &amp; 2</p>
<div class="search-tools"><label for="api-search">Search the reference</label><div class="search-row"><input id="api-search" type="search" placeholder="Function, topic or example…" autocomplete="off"><button type="button" id="clear-search" aria-label="Clear search" hidden>Clear</button></div><p id="search-status" role="status" aria-live="polite"></p></div>
<nav id="sidebar-nav">${navigation}<div class="resources"><a href="/docs/">All API references ↗</a><a href="/guides/l4d/">L4D setup guide ↗</a></div></nav>
</aside>
<main class="content" id="main-content" tabindex="-1">
<header class="page-header"><p class="page-title">Scooby <span>API Reference</span></p><h1>Left 4 Dead Lua API</h1><p class="version">L4D1 &amp; L4D2 <span>Host API 1.0 · Native hooks 1.1 · UI API 1.1</span></p><p class="intro">Build your own hooks, overlays, controls and tools with the Scooby Lua editor. Search for a function, or copy an example to get started.</p><p class="session-note">Native hooks require an updated host with <code>l4d.native</code> 1.1. Updating these docs does not update your installed DLL. Check <code>l4d.native.available()</code> before installation.</p></header>
<p id="no-results" hidden>No matching topics. Try a function such as <code>l4d.native.hook</code>, or clear your search.</p>
<section class="reference-downloads"><h2>Script templates</h2><p>The native hook template stays inactive until you supply a verified pattern and signature.</p><ul>${templates.map(name=>`<li><a href="/docs/l4d/templates/${encodeURIComponent(name)}" download>${esc(name)}</a></li>`).join('')}</ul></section>
${sections}
<footer><a href="/docs/">All API references</a><a href="/products/l4d/">Left 4 Dead product page</a><a href="#main-content">Back to top ↑</a></footer>
</main></body></html>
`;
outputs.set(destination.slice(1),html);
// Other generators may move their own entries; only compare this reference's entries.
const l4dEntries = entries => entries.filter(entry => entry.href.startsWith('/docs/l4d/') || entry.href.startsWith(destination));
if (JSON.stringify(l4dEntries(previousSearch)) !== JSON.stringify(l4dEntries(search))) {
  outputs.set('assets/data/docs-search.json',JSON.stringify(search,null,2)+'\n');
}
outputs.set('docs/l4d/anchors.json',JSON.stringify(anchors,null,2)+'\n');
outputs.set('docs/l4d/index.html',`<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Left 4 Dead Lua API</title><meta name="robots" content="noindex, follow"><link rel="canonical" href="https://scoobymenu.cc${destination}"><script>location.replace('${destination}' + location.search + location.hash);</script><script src="/lang/i18n.js"></script>
</head><body><p>The L4D API reference has moved. <a href="${destination}">Open the Left 4 Dead Lua API reference</a>.</p></body></html>
`);
for (const [name, content] of outputs) {
  if (name.endsWith('.html')) outputs.set(name, applyMetadata(name, applyBranding(content)));
}
const changed=[];
for(const [name,content] of outputs) {
  const file=path.join(root,name);
  if(!fs.existsSync(file)||fs.readFileSync(file,'utf8').replace(/\r\n/g,'\n')!==content) {
    changed.push(name);
    if(!check) { fs.mkdirSync(path.dirname(file),{recursive:true}); fs.writeFileSync(file,content); }
  }
}
console.log(JSON.stringify({check,changed,topics:search.filter(entry=>entry.href.startsWith(destination)).length,templates:templates.length}));
if(check&&changed.length) process.exitCode=1;
