/* Store copy follows the public product page, including access and availability. */
function text(html) {
  return html.replace(/<(script|style|svg)\b[^>]*>[\s\S]*?<\/\1>/gi,'')
    .replace(/<br\s*\/?\s*>/gi,' ').replace(/<[^>]+>/g,'')
    .replace(/&(#x[\da-f]+|#\d+|amp|quot|apos|lt|gt|nbsp|ndash|mdash);/gi,(all,entity)=>{
      if(entity[0]==='#') { const code=entity[1].toLowerCase()==='x'?parseInt(entity.slice(2),16):Number(entity.slice(1));return code>0&&code<=0x10ffff?String.fromCodePoint(code):all; }
      return {amp:'&',quot:'"',apos:"'",lt:'<',gt:'>',nbsp:' ',ndash:'–',mdash:'—'}[entity.toLowerCase()];
    }).replace(/\s+/g,' ').trim();
}
function attrs(tag) {
  return Object.fromEntries([...tag.matchAll(/([\w:-]+)\s*=\s*(["'])(.*?)\2/g)].map(m=>[m[1].toLowerCase(),m[3]]));
}
// Match complete nested elements instead of stopping at an inner closing div.
function elements(html,predicate) {
  const matches=[],tags=/<([a-z][\w-]*)\b[^>]*>/gi;
  let match;
  while((match=tags.exec(html))) {
    if(!predicate(match[1].toLowerCase(),attrs(match[0])))continue;
    const start=tags.lastIndex,closing=new RegExp('<(/?)'+match[1]+'\\b[^>]*>','gi');
    closing.lastIndex=start;let depth=1,end;
    while((end=closing.exec(html))) { depth+=end[1]?-1:1;if(!depth)break; }
    if(end)matches.push({html:html.slice(start,end.index),start:match.index,end:closing.lastIndex});
  }
  return matches;
}
const byClass=(html,name)=>elements(html,(_,a)=>(a.class||'').split(/\s+/).includes(name));
const tag=(html,name)=>elements(html,t=>t===name);
const unique=items=>[...new Set(items.filter(Boolean))];

function describeProduct(slug,html) {
  const main=tag(html,'main')[0]?.html||html;
  const title=text(tag(main,'h1')[0]?.html||slug);
  const output=['SCOOBY — '+title.toUpperCase()];
  const heading=byClass(main,'product-heading')[0]?.html||'';
  const status=unique(byClass(heading,'product-status').map(el=>text(el.html)));
  const unavailable=status.some(s=>/coming soon|dead|development|queued/i.test(s));
  if(status.length)output.push('AVAILABILITY\n'+status.join(' · '));
  const details=byClass(main,'description-content')[0]?.html||'';
  const grids=elements(details||main,(_,a)=>(a.class||'').split(/\s+/).some(name=>['product-feature-grid','tlou-feature-grid'].includes(name)));
  const overviewHtml=grids.length?details.slice(0,grids[0].start):details;
  const intro=byClass(main,'product-intro')[0];
  const overview=unique([intro&&text(intro.html),...tag(overviewHtml,'p').map(p=>text(p.html))])
    .filter(p=>!/^Browse |^Explore the .*feature list|^Settings directory:/i.test(p));
  if(!overview.length) {
    const meta=[...html.matchAll(/<meta\b[^>]*>/gi)].map(m=>attrs(m[0])).find(a=>a.name?.toLowerCase()==='description');
    if(meta?.content)overview.push(text(meta.content));
  }
  if(overview.length)output.push('PRODUCT OVERVIEW\n'+overview.join('\n\n'));

  if(slug==='gta5') output.push('EDITIONS & MULTIPLAYER\n'+[
    'Free: Free features; BattlEye disabled. Play Freemode, missions and heists with other modders.',
    'Premium: Lifetime access to Free and Premium features. BattlEye disabled; multiplayer requires you to be session host.',
    'Plus: Lifetime access to all Premium features, plus BattlEye Enabled multiplayer. Play with others without the session-host restriction.',
    'Supports GTA 5 Legacy and Enhanced on PC. Individual features can depend on the game edition and session.'
  ].map(line=>'- '+line).join('\n'));
  else {
    const access=unique([...byClass(main,'price-label'),...byClass(main,'price-note')].map(el=>text(el.html)));
    if(access.length)output.push((['fivem','redm','rdr2'].includes(slug)?'PREMIUM ACCESS':'ACCESS')+'\n'+access.map(line=>'- '+line).join('\n'));
  }

  const featureSections=[];
  if(!unavailable) {
    for(const grid of grids)for(const section of tag(grid.html,'section')) {
      const name=text(tag(section.html,'h3')[0]?.html||'');
      if(!name)continue;
      const access=byClass(section.html,'feature-access').map(el=>text(el.html)).join(' · ');
      const content=[...section.html.matchAll(/<(p|li)\b[^>]*>([\s\S]*?)<\/\1>/gi)]
        .map(m=>({kind:m[1].toLowerCase(),value:text(m[2])}))
        .filter(item=>item.value&&!/^\d[\d,]* features? & settings$/i.test(item.value));
      if(content.length)featureSections.push(name+(access?' ['+access+']':'')+'\n'+content.map(item=>(item.kind==='li'?'- ':'')+item.value).join('\n'));
    }
    if(featureSections.length)output.push('FEATURES & COMPATIBILITY\n\n'+featureSections.join('\n\n'));
    else {
      const highlights=unique(byClass(main,'features-list').flatMap(el=>tag(el.html,'li').map(li=>text(li.html))));
      if(highlights.length)output.push('FEATURE HIGHLIGHTS\n'+highlights.map(line=>'- '+line).join('\n'));
    }
  } else output.push('RELEASE INFORMATION\nThis product is not currently available for sale. Released features and compatibility have not been confirmed on its product page.');

  if(grids.length) {
    const notes=unique(tag(details.slice(grids[grids.length-1].end),'p').map(p=>text(p.html)))
      .filter(p=>!/^Browse |^Explore |^View the /i.test(p));
    if(notes.length)output.push('ADDITIONAL PRODUCT DETAILS\n'+notes.join('\n\n'));
  }

  const links=[...html.matchAll(/href=["']([^"']+)["']/g)].map(m=>m[1]);
  const featureLink=links.find(url=>url.startsWith('/features-list/'));
  const guideLink=links.find(url=>url.startsWith('/guides/'));
  output.push('PRODUCT INFORMATION\nProduct page: https://scoobymenu.cc/products/'+slug+'/'
    +(featureLink?'\nFull feature list: https://scoobymenu.cc'+featureLink:'')
    +(guideLink?'\nSetup guide: https://scoobymenu.cc'+guideLink:''));
  return output.join('\n\n')+'\n';
}
module.exports={describeProduct};
