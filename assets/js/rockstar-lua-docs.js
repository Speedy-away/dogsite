(() => {
 'use strict';
 const $=id=>document.getElementById(id),browser=$('catalog-browser');if(!browser)return;
 const input=$('api-search'),namespace=$('api-namespace'),unavailable=$('include-unavailable'),entries=$('api-entries'),more=$('show-more'),status=$('search-status');
 const toggle=document.querySelector('.menu-toggle'),nav=$('sidebar-nav');
 const close=()=>{document.body.classList.remove('menu-open');toggle.setAttribute('aria-expanded','false')};
 toggle.addEventListener('click',()=>toggle.setAttribute('aria-expanded',String(document.body.classList.toggle('menu-open'))));
 nav.addEventListener('click',e=>{if(e.target.closest('a'))close()});
 document.addEventListener('keydown',e=>{const typing=e.target.closest('input,textarea,[contenteditable=true]');if(e.key==='/'&&!typing&&!e.ctrlKey&&!e.altKey&&!e.metaKey){e.preventDefault();input.focus()}if(e.key==='Escape')close()});
 let rows=[],matches=[],shown=0,index=new Map();
 const id=row=>'api-'+encodeURIComponent(row[0]+'.'+row[1]);
 function code(parent,label,text){if(!text)return;const heading=document.createElement('h3');heading.textContent=label;const pre=document.createElement('pre'),value=document.createElement('code'),copy=document.createElement('button');value.textContent=text;copy.type='button';copy.className='copy-code';copy.textContent='Copy';copy.addEventListener('click',async()=>{try{await navigator.clipboard.writeText(text);copy.textContent='Copied'}catch{copy.textContent='Copy unavailable'}setTimeout(()=>copy.textContent='Copy',1400)});pre.append(value,copy);parent.append(heading,pre)}
 function append(){const fragment=document.createDocumentFragment();for(const row of matches.slice(shown,shown+100)){
  const detail=document.createElement('details'),summary=document.createElement('summary'),title=document.createElement('code');detail.className='reference-entry';detail.id=id(row);title.textContent=row[0]+'.'+row[1];summary.append(title);
  if(!row[5]){const badge=document.createElement('span');badge.className='unavailable';badge.textContent='Unavailable';summary.append(badge)}
  const body=document.createElement('div');body.className='entry-body';const link=document.createElement('a');link.className='permalink';link.href='#'+detail.id;link.textContent='# Permalink';body.append(link);
  code(body,'Signature',row[2]);code(body,'Example',row[3]);if(row[4]){const p=document.createElement('p');p.textContent=row[4];body.append(p)}if(!row[5]){const p=document.createElement('p');p.className='unavailable';p.textContent=row[6]||'Not exposed by this host.';body.append(p)}detail.append(summary,body);fragment.append(detail)
 }entries.append(fragment);shown=Math.min(shown+100,matches.length);status.textContent=`${matches.length.toLocaleString()} entries · ${shown.toLocaleString()} shown`;more.hidden=shown>=matches.length;$('no-results').hidden=matches.length!==0}
 function filter(updateUrl=true){const words=input.value.trim().toLowerCase().split(/\s+/).filter(Boolean);matches=rows.filter(row=>(unavailable.checked||row[5])&&(!namespace.value||row[0]===namespace.value)&&words.every(w=>row.search.includes(w)));entries.replaceChildren();shown=0;append();if(updateUrl){const url=new URL(location.href);if(input.value)url.searchParams.set('q',input.value);else url.searchParams.delete('q');if(namespace.value)url.searchParams.set('namespace',namespace.value);else url.searchParams.delete('namespace');if(unavailable.checked)url.searchParams.set('unavailable','1');else url.searchParams.delete('unavailable');history.replaceState(null,'',url.pathname+url.search+url.hash)}}
 function reveal(){let anchor;try{anchor=decodeURIComponent(location.hash.slice(1))}catch{return}if(!anchor)return;
  if(anchor.startsWith('api-')){let key;try{key=decodeURIComponent(anchor.slice(4))}catch{return}const row=index.get(key);if(row){input.value=key;namespace.value=row[0];unavailable.checked=!row[5];filter(false);const detail=document.getElementById(id(row));if(detail){detail.open=true;requestAnimationFrame(()=>detail.scrollIntoView())}return}}
  // Legacy namespace bookmarks continue to open the appropriate current catalog.
  if(/^(cat-|natives-)/.test(anchor)){const key=anchor.replace(/^(cat-|natives-)/,'').toLowerCase();const ns=[...namespace.options].find(o=>o.value.toLowerCase()===key);if(ns){namespace.value=ns.value;input.value='';filter(false);browser.scrollIntoView();return}}
  const target=document.getElementById(anchor);if(target){if(target.tagName==='DETAILS')target.open=true;requestAnimationFrame(()=>target.scrollIntoView())}
 }
 let timer;input.addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(()=>filter(),100)});namespace.addEventListener('change',()=>filter());unavailable.addEventListener('change',()=>filter());more.addEventListener('click',append);$('clear-search').addEventListener('click',()=>{input.value='';namespace.value='';unavailable.checked=false;filter();input.focus()});window.addEventListener('hashchange',reveal);
 fetch(browser.dataset.catalog).then(r=>{if(!r.ok)throw Error('Catalog request failed ('+r.status+')');return r.json()}).then(data=>{
  rows=data.rows;for(const row of rows){row.search=row.slice(0,5).join(' ').toLowerCase();index.set(row[0]+'.'+row[1],row)}for(const ns of [...new Set(rows.map(r=>r[0]))].sort()){const option=document.createElement('option');option.value=option.textContent=ns;namespace.append(option)}
  const params=new URLSearchParams(location.search);input.value=params.get('q')||'';namespace.value=params.get('namespace')||'';unavailable.checked=params.get('unavailable')==='1';filter(false);reveal();browser.dataset.loaded='true';
 }).catch(error=>{status.textContent='Could not load the API catalog. Download Documentation.json or reload this page.';status.dataset.error=error.message});
})();
