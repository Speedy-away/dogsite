/* Rebuildable media pack: only public images, no source files or prompts. */
const fs=require('node:fs'),path=require('node:path'),zlib=require('node:zlib'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),out=path.join(root,'assets/downloads'),bannerDir=path.join(out,'product-banners');
const imageRE=/\.(png|jpe?g|webp|svg|gif|avif)$/i;
const hash=data=>crypto.createHash('sha256').update(data).digest('hex');
const escape=s=>s.replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
function files(dir){if(!fs.existsSync(dir))return[];return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):[path.join(dir,e.name)]).sort();}
const table=Array.from({length:256},(_,i)=>{for(let n=0;n<8;n++)i=i&1?0xedb88320^(i>>>1):i>>>1;return i>>>0;});
function crc32(data){let c=0xffffffff;for(const b of data)c=table[(c^b)&255]^(c>>>8);return(c^0xffffffff)>>>0;}
function zip(entries){let offset=0;const body=[],central=[];for(const [name,data]of entries){const n=Buffer.from(name),packed=zlib.deflateRawSync(data,{level:6}),crc=crc32(data);const local=Buffer.alloc(30);local.writeUInt32LE(0x04034b50);local.writeUInt16LE(20,4);local.writeUInt16LE(0x800,6);local.writeUInt16LE(8,8);local.writeUInt16LE(33,12);local.writeUInt32LE(crc,14);local.writeUInt32LE(packed.length,18);local.writeUInt32LE(data.length,22);local.writeUInt16LE(n.length,26);body.push(local,n,packed);const head=Buffer.alloc(46);head.writeUInt32LE(0x02014b50);head.writeUInt16LE(20,4);head.writeUInt16LE(20,6);head.writeUInt16LE(0x800,8);head.writeUInt16LE(8,10);head.writeUInt16LE(33,14);head.writeUInt32LE(crc,16);head.writeUInt32LE(packed.length,20);head.writeUInt32LE(data.length,24);head.writeUInt16LE(n.length,28);head.writeUInt32LE(offset,42);central.push(head,n);offset+=local.length+n.length+packed.length;}const cd=Buffer.concat(central),end=Buffer.alloc(22);end.writeUInt32LE(0x06054b50);end.writeUInt16LE(entries.length,8);end.writeUInt16LE(entries.length,10);end.writeUInt32LE(cd.length,12);end.writeUInt32LE(offset,16);return Buffer.concat([...body,cd,end]);}
function dataUri(file){const ext=path.extname(file).slice(1).toLowerCase();return 'data:image/'+({jpg:'jpeg',svg:'svg+xml'}[ext]||ext)+';base64,'+fs.readFileSync(file).toString('base64');}
function build(){
 fs.mkdirSync(bannerDir,{recursive:true});const entries=new Map(),manifest=[];
 function add(name,file){if(!fs.existsSync(file)||!imageRE.test(file))return;const data=fs.readFileSync(file);entries.set(name,data);manifest.push({path:name,source:path.relative(root,file).replace(/\\/g,'/'),sha256:hash(data)});}
 for(const name of ['scooby-logo.png','scooby-mark.svg','scooby-logo-blue.png','scooby-logo-joined.png','scooby-logo-refined.png']) add('brand/'+name,path.join(root,'assets/images/brand',name));
 const mark=dataUri(path.join(root,'assets/images/brand/scooby-logo.png'));
 const products=fs.readdirSync(path.join(root,'products'),{withFileTypes:true}).filter(e=>e.isDirectory()&&fs.existsSync(path.join(root,'products',e.name,'index.html'))).map(e=>e.name).sort();
 for(const slug of products){
  const html=fs.readFileSync(path.join(root,'products',slug,'index.html'),'utf8');
  const title=(html.match(/<h1[^>]*>(.*?)<\/h1>/s)?.[1]||slug).replace(/<[^>]+>/g,'').replace(/&amp;/g,'&').replace(/\s+(?:Cheats?|Mod Menu|Mods|Premium|External|Internal)\b.*$/i,'').trim();
  const media=new Set(files(path.join(root,'assets/images/previews',slug)).filter(f=>imageRE.test(f)));
  for(const match of html.matchAll(/(?:src|srcset|content)=["']([^"']+)["']/g)){
   const url=match[1].replace(/^https:\/\/scoobymenu.cc/,'').split(/[ ,]/)[0];
   if(!url.startsWith('/')||!imageRE.test(url)||/\/(brand|payments|backgrounds)\//.test(url)||/logo\.(png|svg)$/.test(url))continue;
   const f=path.resolve(root,'.'+url);if(f.startsWith(root+path.sep)&&fs.existsSync(f))media.add(f);
  }
  for(const f of [...media].sort()){const rel=path.relative(root,f).replace(/\\/g,'/');add('products/'+slug+'/'+(rel.includes('/previews/')?'screenshots/'+path.basename(f):'artwork/'+rel),f);}
  const cover=[...media].find(f=>f.includes(path.join('products','images')))||[...media].find(f=>/\.(jpg|jpeg|webp|png)$/i.test(f)&&!f.includes('social'));
  const titleSize=title.length>23?48:title.length>16?62:82;
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900"><defs><linearGradient id="shade"><stop stop-color="#080b12"/><stop offset=".58" stop-color="#080b12" stop-opacity=".9"/><stop offset="1" stop-color="#080b12" stop-opacity=".15"/></linearGradient></defs><rect width="1600" height="900" fill="#0b1019"/>${cover?`<image href="${dataUri(cover)}" x="520" width="1080" height="900" preserveAspectRatio="xMidYMid slice"/>`:''}<rect width="1600" height="900" fill="url(#shade)"/><path d="M80 270H144" stroke="#bda6f5" stroke-width="5"/><image href="${mark}" x="72" y="58" width="78" height="88" preserveAspectRatio="xMidYMid meet"/><g font-family="Arial,Helvetica,sans-serif" fill="#f1f4fa"><text x="168" y="118" font-size="44" font-weight="800" letter-spacing="-1">SCOOBY</text><text x="80" y="360" font-size="20" letter-spacing="5" fill="#bda6f5">GAME COLLECTION</text><text x="76" y="480" font-size="${titleSize}" font-weight="700" letter-spacing="-2">${escape(title)}</text><text x="80" y="548" font-size="28" fill="#b6c0d0">Your game. More possibilities.</text><text x="80" y="808" font-size="23" fill="#c4cddd">scoobymenu.cc</text></g><path d="M80 744H1520" stroke="#ffffff" stroke-opacity=".2"/></svg>`;
  const banner=path.join(bannerDir,slug+'.svg');fs.writeFileSync(banner,svg);add('products/'+slug+'/banners/'+slug+'-1600x900.svg',banner);
  // Include raster exports only when they match the current banner source.
  const png=path.join(bannerDir,slug+'.png'),stamp=png+'.sha256';
  if(fs.existsSync(png)&&fs.existsSync(stamp)&&fs.readFileSync(stamp,'utf8')===hash(Buffer.from(svg)))add('products/'+slug+'/banners/'+slug+'-1600x900.png',png);
 }
 entries.set('README.txt',Buffer.from('SCOOBY RESELLER MEDIA PACK\n\nbrand/ — Scooby logos and mark\nproducts/<game>/screenshots/ — game screenshots\nproducts/<game>/artwork/ — product artwork and existing social banners\nproducts/<game>/banners/ — new self-contained 1600x900 SVG banners and current PNG exports\n\nUse these assets for Scooby product listings. Keep product claims and prices current; check the official product pages.\nThe pack contains images only, plus this guide and an asset manifest.\nRebuilt from the current website assets. Replaced or deleted source files are not retained.\n'));
 const digest=hash(Buffer.from(JSON.stringify(manifest)));entries.set('manifest.json',Buffer.from(JSON.stringify({sourceDigest:digest,products,assets:manifest},null,2)));
 const archive=zip([...entries].sort(([a],[b])=>a.localeCompare(b)));fs.writeFileSync(path.join(out,'scooby-reseller-media.zip'),archive);
 fs.writeFileSync(path.join(out,'reseller-media.json'),JSON.stringify({products:products.length,files:entries.size,bytes:archive.length,sourceDigest:digest}));
 console.log(`Media pack: ${products.length} products, ${entries.size} files, ${(archive.length/1048576).toFixed(1)} MB`);return {entries,products,bytes:archive.length};
}
if(require.main===module)build();module.exports={build,zip,crc32};
