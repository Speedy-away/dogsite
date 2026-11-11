'use strict';

// Public cached-catalog acquisition only. Never runs/extracts packages, reads
// credentials, copies repository source, or writes the publishing checkout.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const ROOT = path.resolve(__dirname, '../..');
const STAGE_REL = 'project/community-menu-sources/cherax-downloads';
const STAGE = path.join(ROOT, STAGE_REL);
const INDEX = path.join(STAGE, 'asset-index.json');
const SNAPSHOT_REL = 'project/community-marketplace/modverse.json';
const MAX_BYTES = 100 * 1024 * 1024;
const CONCURRENCY = 3;
const HOSTS = new Set(['github.com', 'raw.githubusercontent.com', 'release-assets.githubusercontent.com', 'objects.githubusercontent.com', 'github-releases.githubusercontent.com']);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const slash = value => value.replace(/\\/g, '/');
const snapshotBytes = fs.readFileSync(path.join(ROOT, SNAPSHOT_REL));
const snapshot = JSON.parse(snapshotBytes.toString('utf8'));
const snapshotHash = hash(snapshotBytes);
const modes = process.argv.slice(2);
let paused = null;
let dirtyRecords = 0;

function publicUrl(value) {
  const parsed = new URL(value);
  assert.ok(parsed.protocol === 'https:' && HOSTS.has(parsed.hostname) && !parsed.username && !parsed.password, 'Unexpected public asset host');
  return parsed;
}
function safeName(value) {
  const base = path.posix.basename(String(value).replace(/\\/g, '/'));
  const result = base.normalize('NFKD').replace(/[^A-Za-z0-9._-]/g, '_').replace(/^\.+/, '').slice(0, 200);
  assert.ok(result && !/^(?:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)/i.test(result), 'Unsafe source asset basename');
  return result;
}
function insideStage(relative) {
  assert.ok(relative && !relative.includes('\\') && !path.posix.isAbsolute(relative) && !relative.split('/').some(x => !x || x === '.' || x === '..' || x.includes(':')), 'Unsafe staged path');
  const resolved = path.resolve(STAGE, relative);
  assert.ok(resolved.startsWith(STAGE + path.sep), 'Asset escaped staging directory');
  return resolved;
}
function noLinks(absolute) {
  assert.ok(absolute === STAGE || absolute.startsWith(STAGE + path.sep));
  let cursor = STAGE;
  for (const part of ['', ...path.relative(STAGE, absolute).split(path.sep)].filter((x, i) => i === 0 || x)) {
    if (part) cursor = path.join(cursor, part);
    if (fs.existsSync(cursor)) assert.ok(!fs.lstatSync(cursor).isSymbolicLink(), 'Linked staging path rejected');
  }
}
function setupStage() {
  // The nested ignore applies only to this task's temporary acquisition folder.
  noLinks(STAGE); fs.mkdirSync(STAGE, { recursive: true });
  const ignore = path.join(STAGE, '.gitignore'); noLinks(ignore);
  if (!fs.existsSync(ignore)) fs.writeFileSync(ignore, '*\n!.gitignore\n');
}
function buildPlan() {
  const knownPaths = new Set(snapshot.paths), plan = [], ids = new Set();
  assert.equal(snapshot.repository, 'xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace');
  assert.match(snapshot.revision, /^[a-f0-9]{40}$/);
  const raw = `https://raw.githubusercontent.com/${snapshot.repository}/${snapshot.revision}/`;
  const repo = `https://github.com/${snapshot.repository}`;
  function add(value) {
    assert.ok(!ids.has(value.assetKey)); ids.add(value.assetKey);
    publicUrl(value.sourceURL);
    assert.ok(/^[A-Za-z0-9_-]+$/.test(value.sourceId), 'Unexpected resource identity');
    plan.push({ ...value, safeName:safeName(value.originalName), status:'pending' });
  }
  for (const catalog of snapshot.catalogs) {
    const kind = catalog.path.split('/')[1], category = kind === 'dlcs' ? 'dlc' : kind;
    assert.ok(['themes','vehicles','outfits','dlcs'].includes(kind));
    for (const row of catalog.data.items) {
      if (typeof row.name !== 'string' || !row.name.trim()) continue;
      const common = { resourceId:`gta5-modverse-${kind}-${row.id}`, sourceId:row.id, category, name:row.name,
        sourceCatalog:catalog.path, sourceMenu:'Cherax' };
      const payloads = kind === 'themes' ? row.files.map(file => ({ sourceURL:file.download_url,
        originalName:file.asset_name, publisherSha256:file.sha256, publisherSize:file.size_bytes, expectedKind:'archive' })) : (() => {
          const options = [`marketplace/${kind}/files/${row.id}.json`, `marketplace/${kind}/files/${row.filename}`];
          const file = options.find(candidate => knownPaths.has(candidate));
          const sourceURL = row.download_url || (row.release_tag && row.asset_name
            ? `${repo}/releases/download/${encodeURIComponent(row.release_tag)}/${encodeURIComponent(row.asset_name)}`
            : file ? raw + file : null);
          assert.ok(sourceURL, 'No source payload path: '+row.id);
          return [{ sourceURL, originalName:row.filename || row.asset_name, publisherSha256:row.sha256,
            publisherSize:row.size_bytes, expectedKind:kind === 'dlcs' ? 'rpf' : 'json' }];
        })();
      payloads.forEach((file,index) => add({ ...common, ...file, role:'payload', assetKey:`${kind}:${row.id}:payload:${index}` }));
      const candidates = [row.thumbnail, ...['jpg','png','webp'].map(ext=>`marketplace/${kind}/thumbnails/${row.id}.${ext}`), `${row.id}.jpg`].filter(Boolean);
      const thumbnail = candidates.find(candidate=>knownPaths.has(candidate));
      const imageURL = row.thumbnail_url || (thumbnail ? raw + thumbnail : null);
      assert.ok(imageURL, 'No source thumbnail path: '+row.id);
      add({ ...common, role:'thumbnail', assetKey:`${kind}:${row.id}:thumbnail`, expectedKind:'image', sourceURL:imageURL,
        originalName:path.posix.basename(new URL(imageURL).pathname), publisherSha256:row.thumbnail_sha256 || null, publisherSize:null,
        publisherThumbnailKind:row.thumbnail_kind || 'unspecified',
        previewEligible:['original_discord_screenshot','source_theme_artwork','source_image'].includes(row.thumbnail_kind),
        visualReview:row.thumbnail_kind === 'catalog_cover' || row.thumbnail_kind === 'generated_text_placeholder'
          ? 'Generated cover/label retained as an associated asset; never a real resource preview.'
          : row.thumbnail_kind ? 'Publisher source-image classification; downloading validates image bytes, not their visual semantics.'
          : 'Unclassified source thumbnail; image bytes do not establish screenshot provenance.' });
    }
  }
  plan.sort((a,b)=>a.assetKey.localeCompare(b.assetKey,'en'));
  assert.equal(plan.filter(x=>x.role==='payload').length,3162);
  assert.equal(plan.filter(x=>x.role==='thumbnail').length,3162);
  return plan;
}
function inspect(bytes, asset, mime = '') {
  assert.ok(bytes.length > 0 && bytes.length <= MAX_BYTES, 'Empty asset or GitHub 100 MiB per-file cap exceeded');
  const head = bytes.subarray(0,512).toString('utf8').trimStart();
  assert.ok(!/^(?:<!doctype\s+html|<html|<head|<body|<script|<\?xml|<svg)\b/i.test(head), 'HTML/XML/script body rejected');
  assert.ok(!/text\/html|application\/(?:x-msdownload|x-dosexec|x-executable|vnd.microsoft.portable-executable|javascript)|text\/javascript/i.test(mime), 'Executable/HTML MIME rejected');
  assert.ok(bytes.subarray(0,2).toString() !== 'MZ' && !bytes.subarray(0,4).equals(Buffer.from([0x7f,0x45,0x4c,0x46])) && bytes[0] !== 0x1b, 'Executable or Lua bytecode rejected');
  let detected;
  if (bytes[0]===0xff && bytes[1]===0xd8 && bytes[2]===0xff) detected={magic:'JPEG',extension:'.jpg'};
  else if(bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) detected={magic:'PNG',extension:'.png'};
  else if(/^GIF8[79]a$/.test(bytes.subarray(0,6).toString())) detected={magic:'GIF',extension:'.gif'};
  else if(bytes.subarray(0,4).toString()==='RIFF' && bytes.subarray(8,12).toString()==='WEBP') detected={magic:'WEBP',extension:'.webp'};
  else if(['504b0304','504b0506','504b0708'].includes(bytes.subarray(0,4).toString('hex'))) detected={magic:'ZIP',extension:'.zip'};
  else if(bytes.subarray(0,7).equals(Buffer.from([0x52,0x61,0x72,0x21,0x1a,0x07,0x00])) || bytes.subarray(0,8).equals(Buffer.from([0x52,0x61,0x72,0x21,0x1a,0x07,0x01,0x00]))) detected={magic:'RAR',extension:'.rar'};
  else if(bytes.subarray(0,6).equals(Buffer.from([0x37,0x7a,0xbc,0xaf,0x27,0x1c]))) detected={magic:'7Z',extension:'.7z'};
  // Scooby AddonArchive.cpp Read32(header) compares native little-endian
  // 0x52504637, whose stored bytes are 37 46 50 52 ("7FPR"). OPEN is the
  // little-endian 0x4E45504F field at offset 12, stored as ASCII "OPEN".
  else if(bytes.length>=16 && bytes.readUInt32LE(0)===0x52504637) detected={
    magic:'RPF7',extension:'.rpf',byteOrder:'little-endian',rpfMagicValue:'0x52504637',
    rpfEncryptionTag:bytes.subarray(12,16).toString('ascii'),rpfEncryptionValue:'0x'+bytes.readUInt32LE(12).toString(16).padStart(8,'0'),
    rpfEntryCount:bytes.readUInt32LE(4),rpfNamesLength:bytes.readUInt32LE(8)};
  if(asset.expectedKind==='json') {
    assert.ok(!detected, 'Binary body returned for entity JSON');
    const json=JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/,''));
    assert.ok(json && typeof json==='object' && !Array.isArray(json), 'Entity JSON must be an object');
    assert.equal(json.format,'Cherax Entity','Unexpected JSON format');
    assert.equal(json.type,asset.category==='vehicles'?1:2,'Unexpected entity type');
    assert.ok(Number.isSafeInteger(json.model) && json.model!==0 && json.model>=-2147483648 && json.model<=4294967295,'Invalid entity model');
    const object=value=>Boolean(value && typeof value==='object');
    if(asset.category==='vehicles')assert.ok(object(json.mods),'Vehicle JSON lacks mods structure');
    else assert.ok(object(json.components) && object(json.props),'Outfit JSON lacks clothing/props structures');
    return {magic:'JSON',extension:'.json',jsonFormat:json.format,entityType:json.type,model:json.model,jsonKeys:Object.keys(json)};
  }
  assert.ok(detected,'Unrecognized expected asset magic');
  if(asset.expectedKind==='image')assert.ok(['JPEG','PNG','GIF','WEBP'].includes(detected.magic),'Non-image body returned for thumbnail');
  if(asset.expectedKind==='archive')assert.ok(['ZIP','RAR','7Z'].includes(detected.magic),'Non-archive body returned for theme');
  if(asset.expectedKind==='rpf'){
    assert.equal(detected.magic,'RPF7','Non-RPF body returned for DLC');
    assert.equal(bytes.readUInt32LE(12),0x4e45504f,'DLC is not an OPEN-format RPF7 archive');
  }
  return detected;
}
function targetFor(asset, digest, extension) {
  assert.match(digest,/^[a-f0-9]{64}$/); assert.match(extension,/^\.(?:json|jpg|png|gif|webp|zip|rar|7z|rpf)$/);
  // Match the parent's content-addressed menus namespace to avoid duplicates.
  return `${asset.role==='thumbnail'?'previews':'downloads'}/gta5/menus/cherax/${digest.slice(0,20)}${extension}`;
}
function loadIndex(plan) {
  const previous=fs.existsSync(INDEX)?JSON.parse(fs.readFileSync(INDEX,'utf8')):null;
  if(previous)assert.equal(previous.snapshot.sha256,snapshotHash,'Snapshot changed; review before replacing the acquisition index');
  const saved=new Map((previous?.assets||[]).map(asset=>[asset.assetKey,asset]));
  return {schemaVersion:1,sourceMenu:'Cherax',snapshot:{path:SNAPSHOT_REL,repository:snapshot.repository,revision:snapshot.revision,sha256:snapshotHash},
    stageDirectory:STAGE_REL,concurrency:CONCURRENCY,maximumAssetBytes:MAX_BYTES,
    policy:{lua:'Not acquired; all Lua downloads remain pending.',archives:'Stored intact, never extracted or executed.',
      publication:'Index targetRelativePath is relative to the publishing checkout; no publishing checkout is written here.',
      exactBytes:'Publishing must preserve served JSON bytes. Add a narrow -text .gitattributes rule in downloads/gta5/menus/cherax; do not apply a global rule.',
      checksums:'actual.sha256/size describe served bytes. Publisher byte claims remain separate, including mismatches.',
      thumbnailSemantics:'All associated thumbnails are acquired, including generated covers. Only explicit original/source-image classifications are preview candidates; no pixel classification is inferred from image magic.'},
    pause:previous?.pause||null,assets:plan.map(asset=>{
      const prior=saved.get(asset.assetKey);
      const combined=prior&&prior.sourceURL===asset.sourceURL?{...prior,...asset,status:prior.status}:asset;
      if(asset.publisherSize>MAX_BYTES)return {...combined,status:'rejected',error:'Publisher size exceeds GitHub 100 MiB per-file cap; explicit acquisition gap.'};
      return combined;
    })};
}
function summary(index) {
  return {assets:index.assets.length,payloads:index.assets.filter(x=>x.role==='payload').length,thumbnails:index.assets.filter(x=>x.role==='thumbnail').length,
    statuses:index.assets.reduce((o,x)=>(o[x.status]=(o[x.status]||0)+1,o),{}),actualBytes:index.assets.filter(x=>x.status==='downloaded').reduce((n,x)=>n+x.actual.size,0),
    publisherHashMismatches:index.assets.filter(x=>x.status==='downloaded'&&x.publisherChecksumMatches===false).length,
    uniqueTargetPaths:new Set(index.assets.filter(x=>x.status==='downloaded').map(x=>x.targetRelativePath)).size,pause:index.pause,
    gaps:index.assets.filter(x=>['failed','rejected'].includes(x.status)).map(x=>({assetKey:x.assetKey,sourceURL:x.sourceURL,error:x.error})).slice(0,30)};
}
function save(index) {
  index.summary=summary(index);
  noLinks(INDEX);const tmp=insideStage('asset-index.json.partial');noLinks(tmp);
  fs.writeFileSync(tmp,JSON.stringify(index,null,2)+'\n');fs.renameSync(tmp,INDEX);
}
function verifySaved(asset) {
  assert.equal(asset.status,'downloaded');
  const file=insideStage(asset.stagedRelativePath);noLinks(file);
  const stat=fs.statSync(file);assert.ok(stat.isFile() && stat.size<=MAX_BYTES);
  const bytes=fs.readFileSync(file),digest=hash(bytes),detected=inspect(bytes,asset,asset.actual.contentType);
  assert.equal(bytes.length,asset.actual.size);assert.equal(digest,asset.actual.sha256);
  assert.equal(asset.targetRelativePath,targetFor(asset,digest,detected.extension));
  return true;
}
function ratePause(response) {
  const retry=response.headers.get('retry-after'),reset=response.headers.get('x-ratelimit-reset');
  let until=retry&&/^\d+$/.test(retry)?Date.now()+Number(retry)*1000:retry?Date.parse(retry):NaN;
  if(!Number.isFinite(until)&&reset&&/^\d+$/.test(reset))until=Number(reset)*1000;
  if(!Number.isFinite(until)||until<Date.now())until=Date.now()+15*60*1000;
  paused={status:response.status,retryAfter:retry,until:new Date(until).toISOString(),reason:'Public host requested throttling; no new requests issued. Resume after this time.'};
}
async function request(url,signal) {
  let current=publicUrl(url);
  for(let redirects=0;redirects<=5;redirects++){
    if(paused)throw Error('Public acquisition paused');
    const response=await fetch(current,{redirect:'manual',credentials:'omit',headers:{'User-Agent':'Scooby-Public-Resource-Acquisition','Accept':'*/*'},signal});
    if(response.status===429 || (response.status===403&&response.headers.get('x-ratelimit-remaining')==='0') || (response.status===503&&response.headers.has('retry-after'))){ratePause(response);if(response.body)await response.body.cancel();throw Error('Rate limited; acquisition paused');}
    if([301,302,303,307,308].includes(response.status)){
      const next=response.headers.get('location');if(response.body)await response.body.cancel();assert.ok(next,'Redirect without location');current=publicUrl(new URL(next,current).href);continue;
    }
    return response;
  }
  throw Error('Public redirect limit exceeded');
}
async function download(asset,index) {
  if(asset.status==='downloaded'){
    try{verifySaved(asset);return;}catch(error){asset.status='pending';asset.error='Local cached bytes need reacquisition: '+error.message;}
  }
  if(asset.status==='rejected'||paused)return;
  asset.attempts=(asset.attempts||0)+1;
  try{
    const response=await request(asset.sourceURL,AbortSignal.timeout(180000));
    if(!response.ok){if(response.body)await response.body.cancel();throw Error('HTTP '+response.status);}
    const mime=response.headers.get('content-type')||'';
    const declared=Number(response.headers.get('content-length'));
    if(declared>MAX_BYTES){if(response.body)await response.body.cancel();asset.status='rejected';throw Error('HTTP size exceeds GitHub 100 MiB per-file cap');}
    assert.ok(response.body,'Missing asset response body');
    const reader=response.body.getReader(),chunks=[];let size=0;
    while(true){const result=await reader.read();if(result.done)break;size+=result.value.length;if(size>MAX_BYTES){await reader.cancel();asset.status='rejected';throw Error('Stream exceeds GitHub 100 MiB per-file cap');}chunks.push(Buffer.from(result.value));}
    const bytes=Buffer.concat(chunks,size),detected=inspect(bytes,asset,mime),digest=hash(bytes);
    const targetRelativePath=targetFor(asset,digest,detected.extension),stagedRelativePath='assets/'+targetRelativePath;
    const file=insideStage(stagedRelativePath);noLinks(file);fs.mkdirSync(path.dirname(file),{recursive:true});
    if(fs.existsSync(file))assert.equal(hash(fs.readFileSync(file)),digest,'Content-addressed destination has different bytes');
    else {const partial=file+'.partial';noLinks(partial);fs.writeFileSync(partial,bytes);fs.renameSync(partial,file);}
    Object.assign(asset,{status:'downloaded',targetRelativePath,stagedRelativePath,localPath:slash(path.relative(ROOT,file)),
      actual:{size,sha256:digest,contentType:mime,...detected},publisherChecksumMatches:asset.publisherSha256?digest===asset.publisherSha256:null,
      publisherSizeMatches:Number.isSafeInteger(asset.publisherSize)?size===asset.publisherSize:null});
    delete asset.error;
  }catch(error){if(asset.status!=='rejected')asset.status=paused?'rate_limited':'failed';asset.error=error.message;}
  index.pause=paused||index.pause;dirtyRecords++;
  // Full indexes are several MiB. Persist bounded batches rather than rewriting
  // thousands of complete indexes; validated payload files are already atomic.
  if(dirtyRecords>=25||paused||asset.status==='failed'||asset.status==='rejected'){save(index);dirtyRecords=0;}
}
async function main() {
  assert.equal(modes.length,1,'Choose exactly one mode: --inventory, --download, or --check');
  assert.ok(['--inventory','--download','--check'].includes(modes[0]),'Unknown mode');
  const plan=buildPlan(),index=loadIndex(plan);
  if(modes[0]==='--check'){
    const problems=[];
    for(const asset of index.assets){try{verifySaved(asset);}catch(error){problems.push({assetKey:asset.assetKey,status:asset.status,error:error.message});}}
    console.log(JSON.stringify({mode:'check',...summary(index),verified:index.assets.length-problems.length,problems:problems.slice(0,30)},null,2));
    if(problems.length)process.exitCode=1;return;
  }
  setupStage();
  if(modes[0]==='--inventory'){save(index);console.log(JSON.stringify({mode:'inventory',index:slash(path.relative(ROOT,INDEX)),...summary(index)},null,2));return;}
  if(index.pause?.until && Date.parse(index.pause.until)>Date.now()){console.log(JSON.stringify({mode:'download',status:'paused',pause:index.pause},null,2));process.exitCode=75;return;}
  index.pause=null;save(index);let cursor=0,completed=0;
  async function worker(){while(!paused&&cursor<index.assets.length){const asset=index.assets[cursor++];await download(asset,index);completed++;if(completed%50===0)console.log(JSON.stringify({processed:completed,...summary(index),gaps:undefined}));}}
  await Promise.all(Array.from({length:CONCURRENCY},worker));index.pause=paused;save(index);
  console.log(JSON.stringify({mode:'download',index:slash(path.relative(ROOT,INDEX)),...summary(index)},null,2));
  if(paused)process.exitCode=75;else if(index.assets.some(x=>x.status!=='downloaded'))process.exitCode=1;
}
module.exports={buildPlan,inspect,targetFor,MAX_BYTES};
if(require.main===module)main().catch(error=>{console.error(error.message);process.exitCode=1;});
