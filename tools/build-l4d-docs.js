const fs = require('fs');
const path = require('path');
const {marked} = require('marked');
const root = path.resolve(__dirname, '..');
const sources = [ ['snippets','Code snippets','snippets.md'], ['game-api','L4D host API','game-api.md'], ['ui-api','UI, features and rendering','ui-api.md'] ];
const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
let template = fs.readFileSync(path.join(root,'docs/index.html'),'utf8');
const description = 'Left 4 Dead 1 and 2 Lua API: snapshots, entities, bones, projection, rendering, custom controls, hotkeys and working examples.';
template = template.replace(/<title>.*?<\/title>/, '<title>Left 4 Dead Lua API — Scooby Docs</title>')
 .replace(/(<meta (?:name|property)="(?:description|og:description|twitter:description)" content=")[^"]*/g, '$1'+description)
 .replace(/(<meta (?:name|property)="(?:og:title|twitter:title)" content=")[^"]*/g, '$1Left 4 Dead Lua API — Scooby Docs')
 .replace(/https:\/\/scoobymenu.cc\/docs\//g,'https://scoobymenu.cc/docs/l4d/')
 .replace('class="sidebar-home current" href="/docs/" aria-current="page"','class="sidebar-home" href="/docs/"')
 .replace('<a href="/docs/l4d/">Left 4 Dead 1 &amp; 2</a>','<a href="/docs/l4d/" aria-current="page">Left 4 Dead 1 &amp; 2</a>');
let search=JSON.parse(fs.readFileSync(path.join(root,'assets/data/docs-search.json'),'utf8')).filter(x=>!x.href.startsWith('/docs/l4d/'));
const sections=sources.map(([id,title,file])=>{
 const md=fs.readFileSync(path.join(root,'docs/l4d',file),'utf8');
 let part=marked.parse(md.replace(/^# /gm,'## '));
 let n=0;
 part=part.replace(/<h([2-6])>([\s\S]*?)<\/h\1>/g,(all,level,body)=>{
  const heading=body.replace(/<[^>]*>/g,'');
  const anchor=id+'-'+(++n);
  search.push({game:'Left 4 Dead 1 & 2',title:heading,href:'/docs/l4d/#'+anchor,text:'L4D L4D1 L4D2 Lua '+heading});
  return `<h${level} id="${anchor}">${body}</h${level}>`;
 });
 search.push({game:'Left 4 Dead 1 & 2',title,href:'/docs/l4d/#'+id,text:md.replace(/[`#*|]/g,' ').slice(0,8000)});
 return `<section class="guide-card lua-reference" id="${id}" data-i18n-skip><h2>${title}</h2><p><a href="/docs/l4d/${file}" download>Download Markdown reference</a></p>${part}</section>`;
}).join('\n');
const content=`<div class="breadcrumbs"><a href="/docs/">Documentation</a> / Left 4 Dead</div><h1>Left 4 Dead Lua API</h1><p class="article-intro">L4D1 &amp; L4D2 · Host API 1.0 · UI API 1.0</p><div class="wiki-note"><p>Use these APIs from the Scooby Lua editor. Each snippet runs independently. Game data availability follows the host session checks; nil and empty results are expected while loading. <a href="/guides/l4d/getting-started/">Setup guide →</a></p></div><nav class="lua-section-links" aria-label="API sections">${sources.map(([id,title])=>`<a href="#${id}">${title}</a>`).join('')}</nav>${sections}`;
template=template.replace(/<div class="breadcrumbs">[\s\S]*?(?=<footer class="wiki-footer">)/,content);
template=template.replace(/<aside class="wiki-toc"[\s\S]*?<\/aside>/,`<aside class="wiki-toc" aria-label="On this page"><strong>On this page</strong>${sources.map(([id,title])=>`<a href="#${id}">${title}</a>`).join('')}<a href="/guides/l4d/">Setup &amp; troubleshooting</a></aside>`);
template=template.replace('</head>','<link rel="stylesheet" href="/assets/css/l4d-docs.css"><script defer src="/assets/js/l4d-docs.js"></script></head>');
fs.writeFileSync(path.join(root,'docs/l4d/index.html'),template);
fs.writeFileSync(path.join(root,'assets/data/docs-search.json'),JSON.stringify(search,null,2)+'\n');
console.log('L4D Lua reference built from three Markdown sources.');
