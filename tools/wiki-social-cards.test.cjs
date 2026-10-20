const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {cards,cardFor,GUIDE_VERSION}=require('./social-cards');
const root=path.resolve(__dirname,'..');
test('all original Wiki artwork is a compact 1200 by 630 PNG',()=>{
 const wiki=Object.values(cards).filter(c=>c.layout==='wiki');assert.equal(wiki.length,26);
 for(const c of wiki){const png=fs.readFileSync(path.join(root,'assets/images/social/'+c.id+'-'+GUIDE_VERSION+'.png'));
  assert.equal(png.subarray(1,4).toString(),'PNG');assert.equal(png.readUInt32BE(16),1200,c.id);assert.equal(png.readUInt32BE(20),630,c.id);assert(png.length<1024*1024,c.id);
 }
});
test('guide topics get the correct illustration and retain game-specific identities',()=>{
 const examples={
  'guides/index.html':'guides','guides/loading/index.html':'wiki-loading',
  'guides/general/free-key/index.html':'wiki-free-key','guides/general/faq/index.html':'wiki-antivirus',
  'guides/general/connection/index.html':'wiki-connection','guides/general/hwid/index.html':'wiki-hwid',
  'guides/gta5/plus-setup/index.html':'wiki-plus','guides/gta5/hypervisor-vbs/index.html':'wiki-vbs',
  'guides/fivem/fivem-inject/index.html':'wiki-game-fivem','guides/redm/redm-inject/index.html':'wiki-game-redm',
  'guides/tf2/getting-started/index.html':'wiki-game-tf2','guides/mta-sa/index.html':'wiki-game-mta-sa'
 };
 for(const [file,id] of Object.entries(examples))assert.equal(cardFor(file).id,id);
 assert.equal(cardFor('store/index.html').path,'/assets/images/social/store-v2.png');
 assert.equal(cardFor('docs/index.html').path,'/assets/images/social/docs-v2.png');
 assert(cards['wiki-free-key'].subtitle.includes('24 hours'));
});
test('every Wiki page exposes the matching fresh preview to crawlers without JavaScript',()=>{
 const files=[];function scan(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const f=path.join(dir,e.name);if(e.isDirectory())scan(f);else if(f.endsWith('.html'))files.push(f);}}scan(path.join(root,'guides'));
 assert.equal(files.length,90);
 for(const file of files){const relative=path.relative(root,file).replaceAll('\\','/'),card=cardFor(relative),html=fs.readFileSync(file,'utf8');
  const tags=[...html.matchAll(/<meta\b[^>]*>/g)].map(m=>Object.fromEntries([...m[0].matchAll(/([\w:-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]])));
  for(const key of ['og:image','og:image:secure_url','twitter:image']){const matches=tags.filter(t=>(t.name||t.property)===key);assert.equal(matches.length,1,relative+' '+key);assert.equal(matches[0].content,'https://scoobymenu.cc'+card.path,relative);}
  for(const [key,value] of [['og:image:width','1200'],['og:image:height','630'],['og:image:type','image/png'],['twitter:card','summary_large_image']])assert.equal(tags.find(t=>(t.name||t.property)===key).content,value,relative);
  for(const key of ['og:image:alt','twitter:image:alt'])assert(tags.find(t=>(t.name||t.property)===key).content.length>20,relative);
 }
});
