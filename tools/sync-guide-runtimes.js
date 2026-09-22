/* Reuse the runtime section in every project requirements/setup guide.
 * node tools/sync-guide-runtimes.js --apply (then python tools/build-guide-search.py)
 * node tools/sync-guide-runtimes.js --check
 * New projects with a requirements/ or <game>-requirements/ guide are discovered automatically.
 */
const fs=require('node:fs'), path=require('node:path');
const root=path.resolve(__dirname,'..');
const block=fs.readFileSync(path.join(__dirname,'partials/vc-runtimes.html'),'utf8').replace(/\r\n/g,'\n').trim();
const fallbacks={gta5:'first-time',rdr2:'rdr2-before'};
const routes=[];
for(const entry of fs.readdirSync(path.join(root,'guides'),{withFileTypes:true})){
 if(!entry.isDirectory()||['source-games','general'].includes(entry.name))continue;
 const topics=fs.readdirSync(path.join(root,'guides',entry.name),{withFileTypes:true}).filter(e=>e.isDirectory()).map(e=>e.name);
 const topic=topics.find(name=>name==='requirements'||name===entry.name+'-requirements')||fallbacks[entry.name];
 if(!topic)throw Error('Choose a setup guide for '+entry.name+' before adding runtime instructions.');
 routes.push('guides/'+entry.name+'/'+topic+'/index.html');
}
routes.push('guides/gta5/free-setup/index.html','guides/general/crashing/index.html');
const updates=[];
for(const file of routes){
 const original=fs.readFileSync(path.join(root,file),'utf8');
 const newline=original.includes('\r\n')?'\r\n':'\n';
 const runtimeBlock=block.replace(/\n/g,newline);
 let html=original;
 let replaced=0;
 html=html.replace(/<div class="requirements-box"[^>]*>[\s\S]*?<\/div>/g,old=>{
  if(!old.includes('visual-c-redistributable-runtime-package'))return old;
  replaced++;
  const directx=old.match(/<p>\s*<strong>DirectX:<\/strong>\s*<\/p>\s*<a[^>]+>[\s\S]*?<\/a>/);
  return runtimeBlock+(directx?newline+'<div class="requirements-box">'+directx[0]+'</div>':'');
 });
 if(replaced>1)throw Error('Duplicate runtime sections in '+file);
 // Replace the short old L4D runtime bullet with the complete shared section.
 if(file==='guides/l4d/requirements/index.html')html=html.replace(/<li>Microsoft Visual C\+\+ runtimes:[\s\S]*?<\/li>/,'');
 html=html.replace(/<p>Before running Scooby on (?:CS2|FiveM|RedM), make sure the <strong>VC Runtimes<\/strong> are installed:<\/p>\s*/,'');
 html=html.replace(/<p>Install those and <strong>restart your PC<\/strong>\.<\/p>\s*/,'');
 if(!replaced){
  const heading=/<div class="guide-card" id="[^"]+">\s*<h2[^>]*>[\s\S]*?<\/h2>/;
  if(!heading.test(html))throw Error('Missing guide content in '+file);
  html=html.replace(heading,match=>match+newline+runtimeBlock+newline);
 }
 if((html.match(/id="vc-runtimes"/g)||[]).length!==1)throw Error('Invalid runtime section count: '+file);
 if(html!==original)updates.push({file,original,html});
}
for(const update of updates){
 const target=path.join(root,update.file);
 if(fs.readFileSync(target,'utf8')!==update.original)throw Error('Guide changed during sync: '+update.file);
 if(process.argv.includes('--apply'))fs.writeFileSync(target,update.html);
}
console.log(JSON.stringify({projects:routes.length-2,guides:routes.length,changed:updates.map(u=>u.file),applied:process.argv.includes('--apply')},null,2));
if(process.argv.includes('--check')&&updates.length)process.exitCode=1;
