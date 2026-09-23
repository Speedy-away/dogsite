const fs = require('fs');
const path = require('path');
const {marked} = require('marked');
const root = path.resolve(__dirname, '..');
const destination = '/l4d_api_reference.html';
const sources = [['snippets','Code snippets','snippets.md'], ['game-api','L4D host API','game-api.md'], ['ui-api','UI, features and rendering','ui-api.md']];
const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const plain = s => s.replace(/<[^>]*>/g,'').replace(/&amp;/g,'&').replace(/&#39;/g,"'").replace(/&quot;/g,'"');
let search = JSON.parse(fs.readFileSync(path.join(root,'assets/data/docs-search.json'),'utf8'))
  .filter(x => !x.href.startsWith('/docs/l4d/') && !x.href.startsWith(destination));
let navigation = '';
const sections = sources.map(([id,title,file]) => {
  const md = fs.readFileSync(path.join(root,'docs/l4d',file),'utf8');
  const html = marked.parse(md.replace(/^# /gm,'## '));
  const headings = [...html.matchAll(/<h([2-6])>([\s\S]*?)<\/h\1>/g)];
  const entries = headings.map((heading,i) => {
    const anchor = id + '-' + (i+1); // Preserve the previous reference's bookmarks.
    const body = html.slice(heading.index + heading[0].length, headings[i+1]?.index ?? html.length)
      .replace(/<table>([\s\S]*?)<\/table>/g,'<div class="table-wrap"><table>$1</table></div>');
    search.push({game:'Left 4 Dead 1 & 2',title:plain(heading[2]),href:destination+'#'+anchor,text:plain(body),newTab:true});
    return {anchor,title:heading[2],html:`<article class="reference-entry"><h3 id="${anchor}">${heading[2]} <a class="permalink" href="#${anchor}" aria-label="Link to ${esc(plain(heading[2]))}">#</a></h3>${body}</article>`};
  });
  navigation += `<div class="nav-group" data-section="${id}"><a class="sect" href="#${id}">${title}</a>${entries.map(e=>`<a class="entry" href="#${e.anchor}">${e.title}</a>`).join('\n')}</div>`;
  search.push({game:'Left 4 Dead 1 & 2',title,href:destination+'#'+id,text:md.replace(/[`#*|]/g,' ').slice(0,8000),newTab:true});
  return `<section class="reference-section lua-reference" id="${id}"><header><h2>${title}</h2><a class="download-source" href="/docs/l4d/${file}" download>Download Markdown</a></header>${entries.map(e=>e.html).join('\n')}</section>`;
}).join('\n');
const title = 'Left 4 Dead Lua API Reference - Scooby Developer Docs';
const description = 'Scooby Lua API for Left 4 Dead 1 and 2. Search functions, entity snapshots, rendering, UI controls, hotkeys and copyable Lua examples.';
const html = `<!DOCTYPE html>
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
<link rel="stylesheet" href="/assets/css/l4d-api-reference.css">
<script defer src="/assets/js/l4d-docs.js"></script><script defer src="/assets/js/l4d-api-reference.js"></script>
<noscript><style>.menu-toggle,.search-tools{display:none!important}.sidebar{position:static!important;width:auto!important;height:auto!important}.content{margin-left:0!important}#sidebar-nav{display:block!important;max-height:none!important}</style></noscript>
</head><body>
<a class="skip-link" href="#main-content">Skip to reference</a>
<aside class="sidebar" aria-label="L4D API navigation">
<div class="sidebar-heading"><a class="brand" href="/docs/">Scooby <span>API</span></a><button class="menu-toggle" type="button" aria-expanded="false" aria-controls="sidebar-nav">Sections</button></div>
<p class="game-label">LEFT 4 DEAD 1 &amp; 2</p>
<div class="search-tools"><label for="api-search">Search the reference</label><div class="search-row"><input id="api-search" type="search" placeholder="Function, topic or example…" autocomplete="off"><button type="button" id="clear-search" aria-label="Clear search" hidden>Clear</button></div><p id="search-status" role="status" aria-live="polite"></p></div>
<nav id="sidebar-nav">${navigation}<div class="resources"><a href="/docs/">All API references ↗</a><a href="/guides/l4d/">L4D setup guide ↗</a></div></nav>
</aside>
<main class="content" id="main-content" tabindex="-1">
<header class="page-header"><p class="page-title">Scooby <span>API Reference</span></p><h1>Left 4 Dead Lua API</h1><p class="version">L4D1 &amp; L4D2 <span>Host API 1.0 · UI API 1.0</span></p><p class="intro">Build your own overlays, controls and tools with the Scooby Lua editor. Browse the host and UI APIs, search for a function, or copy an example to get started.</p><p class="session-note">Game data follows the host session checks. While a map is loading, queries may return nil or empty results.</p></header>
<p id="no-results" hidden>No matching topics. Try a function such as <code>l4d.entities</code>, or clear your search.</p>
${sections}
<footer><a href="/docs/">All API references</a><a href="/products/l4d/">Left 4 Dead product page</a><a href="#main-content">Back to top ↑</a></footer>
</main></body></html>\n`;
fs.writeFileSync(path.join(root,destination.slice(1)),html);
fs.writeFileSync(path.join(root,'assets/data/docs-search.json'),JSON.stringify(search,null,2)+'\n');
fs.writeFileSync(path.join(root,'docs/l4d/index.html'),`<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Left 4 Dead Lua API</title><meta name="robots" content="noindex, follow"><link rel="canonical" href="https://scoobymenu.cc${destination}"><script>location.replace('${destination}' + location.search + location.hash);</script></head><body><p>The L4D API reference has moved. <a href="${destination}">Open the Left 4 Dead Lua API reference</a>.</p></body></html>\n`);
console.log('Built standalone L4D API reference, compatible redirect and search index from three Markdown sources.');
