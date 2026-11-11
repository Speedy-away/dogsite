'use strict';

// Official CLI wrapper only. No Discord HTTP calls, app-state reads, token args,
// credential files, source execution, or unrelated guild/channel exports.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {spawn}=require('node:child_process');
const {StringDecoder}=require('node:string_decoder');
const ROOT=path.resolve(__dirname,'../..');
const SOURCE=path.join(ROOT,'project/community-menu-sources');
const CLI=path.join(SOURCE,'cherax-cli/DiscordChatExporter.Cli.exe');
const PROOF=path.join(SOURCE,'cherax-cli/cli-sha256.json');
const EXPORTS=path.join(SOURCE,'cherax-exports');
const CHANNELS=path.join(SOURCE,'cherax-export-channels.json');
const STATUS=path.join(SOURCE,'cherax-export-status.json');
const EXPECTED=['lua-scripts','outfit-shares','dlc-shares','theme-shares','json-vehicles','translation-shares','cherax-wallpaper','outfit-shares-old','dlc-shares-old','cherax-wallpaper-old','json-vehicles-old','translation-shares-old','theme-shares-old'];
const official='https://github.com/Tyrrrz/DiscordChatExporter/tree/2.48/DiscordChatExporter.Cli/Commands';
let credential='',activeChild=null;
const relative=file=>path.relative(ROOT,file).replace(/\\/g,'/');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const ansi=/\x1b\[[0-?]*[ -/]*[@-~]/g;
function redact(value){let text=String(value);if(credential)text=text.split(credential).join('[REDACTED]');return text.replace(ansi,'').replace(/mfa\.[A-Za-z0-9_-]{20,}/g,'[REDACTED]').replace(/\b[A-Za-z0-9_-]{23,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{20,}\b/g,'[REDACTED]');}
function output(value){process.stdout.write(redact(JSON.stringify(value))+'\n');}
function save(file,value){const text=redact(JSON.stringify(value,null,2))+'\n';fs.writeFileSync(file+'.partial',text);fs.renameSync(file+'.partial',file);}
function verifyCLI(){
  const proof=JSON.parse(fs.readFileSync(PROOF,'utf8'));
  if(proof.version!=='2.48'||!/^https:\/\/github\.com\/Tyrrrz\/DiscordChatExporter\/releases\/download\/2\.48\//.test(proof.sourceUrl)||!/^[a-f0-9]{64}$/.test(proof.exeSha256))throw Error('Official CLI SHA proof is missing or invalid.');
  if(fs.lstatSync(CLI).isSymbolicLink()||sha(fs.readFileSync(CLI))!==proof.exeSha256)throw Error('CLI executable SHA256 does not match its reviewed proof.');
  return {version:proof.version,exeSha256:proof.exeSha256,proof:relative(PROOF),sourceUrl:proof.sourceUrl};
}
function ensureExports(){
  if(fs.existsSync(EXPORTS)&&fs.lstatSync(EXPORTS).isSymbolicLink())throw Error('Export directory must not be a link.');
  fs.mkdirSync(EXPORTS,{recursive:true});const ignore=path.join(EXPORTS,'.gitignore');
  if(!fs.existsSync(ignore))fs.writeFileSync(ignore,'*\n!.gitignore\n');
}
function stdinCredential(){
  return new Promise((resolve,reject)=>{
    let buffer='',done=false;const stdin=process.stdin,rawBefore=Boolean(stdin.isRaw);
    if(stdin.isTTY&&typeof stdin.setRawMode==='function')stdin.setRawMode(true);
    const finish=(error,value)=>{if(done)return;done=true;stdin.removeListener('data',data);stdin.removeListener('end',ended);stdin.removeListener('error',failed);stdin.pause();if(stdin.isTTY&&typeof stdin.setRawMode==='function')stdin.setRawMode(rawBefore);buffer='';error?reject(error):resolve(value);};
    const ended=()=>finish(Error('stdin closed before a credential line was supplied.'));
    const failed=()=>finish(Error('stdin credential input failed.'));
    function data(chunk){
      for(const char of chunk.toString('utf8')){
        if(char==='\r'||char==='\n'){
          const value=buffer.trim();if(!value||value.length>4096||/\s/.test(value)){finish(Error('A nonempty single credential line is required.'));return;}
          finish(null,value);return;
        }
        if(char==='\u0003'){finish(Error('Credential input cancelled.'));return;}
        if(char==='\u0004'){ended();return;}
        if(char==='\u007f'||char==='\b')buffer=buffer.slice(0,-1);else buffer+=char;
        if(buffer.length>4096){finish(Error('Credential line exceeds the allowed input bound.'));return;}
      }
    }
    stdin.on('data',data);stdin.once('end',ended);stdin.once('error',failed);stdin.resume();
    output({status:'waiting-for-stdin-credential',inputEcho:false});
  });
}
function tableRows(text){return text.split(/[\r\n]+/).map(line=>line.replace(ansi,'').match(/^\s*(\d{15,22})\s*\|\s*(.+?)\s*$/)).filter(Boolean).map(match=>({id:match[1],name:match[2]}));}
function guildKey(value){return value.normalize('NFKC').replace(/[^\p{L}\p{N}]/gu,'').toLowerCase();}
function channelLeaf(value){return value.split(/\s+\/\s+/).at(-1).trim();}
function channelName(value){
  const leaf=channelLeaf(value).normalize('NFKC').replace(/[\u2010-\u2015\u2212]/g,'-').toLowerCase();
  return EXPECTED.find(name=>{const at=leaf.indexOf(name);return at>=0&&!/[\p{L}\p{N}]/u.test(leaf.slice(0,at))&&!/[\p{L}\p{N}]/u.test(leaf.slice(at+name.length));})||null;
}
function runCLI(args,{captureOnly=false,log=null,onLine=()=>{}}={}){
  return new Promise((resolve,reject)=>{
    // This is the only destination of the in-memory credential.
    const env={...process.env,DISCORD_TOKEN:credential,NO_COLOR:'1',TERM:'dumb',DOTNET_CLI_TELEMETRY_OPTOUT:'1'};
    delete env.DISCORD_TOKEN_BOT;
    const child=spawn(CLI,args,{cwd:ROOT,env,windowsHide:true,shell:false,stdio:['ignore','pipe','pipe']});
    activeChild=child;let captured='',finished=false;
    const logStream=log?fs.createWriteStream(log,{flags:'a'}):null;
    function line(raw,stream){const value=redact(raw);if(captureOnly){captured+=value+'\n';if(captured.length>4*1024*1024){child.kill();reject(Error('Bounded CLI discovery output exceeded.'));return;}}else{if(logStream)logStream.write(`[${stream}] ${value}\n`);onLine(value,stream);}}
    for(const stream of ['stdout','stderr']){
      const decoder=new StringDecoder('utf8');let pending='';
      child[stream].on('data',chunk=>{pending+=decoder.write(chunk);const lines=pending.split(/\r\n|\r|\n/);pending=lines.pop();for(const value of lines)line(value,stream);if(pending.length>1024*1024){child.kill();reject(Error('Bounded CLI line length exceeded.'));}});
      child[stream].on('end',()=>{pending+=decoder.end();if(pending)line(pending,stream);});
    }
    child.once('error',()=>{if(logStream)logStream.end();reject(Error('Official CLI process failed to start.'));});
    child.once('close',(code,signal)=>{activeChild=null;if(finished)return;finished=true;const complete=()=>resolve({code,signal,captured});if(logStream)logStream.end(complete);else complete();});
  });
}
function fileInventory(guildId=null,selected=[],startedAt=null){
  const result={files:0,bytes:0,jsonExportFiles:0,exportedMessages:0,currentRunJSONExports:0,mediaFiles:0,foreignOrUnclassifiedJSON:0,invalidExportFiles:[],exports:[]};
  if(!fs.existsSync(EXPORTS))return result;
  const known=new Set(selected.map(x=>x.id));
  const visit=directory=>{for(const entry of fs.readdirSync(directory,{withFileTypes:true})){
    const file=path.join(directory,entry.name);if(entry.isSymbolicLink())throw Error('Linked export path rejected.');if(entry.isDirectory()){visit(file);continue;}if(!entry.isFile()||entry.name==='.gitignore'||entry.name.endsWith('.log'))continue;
    const stat=fs.statSync(file);result.files++;result.bytes+=stat.size;
    // DCE places JSON attachments in per-export media directories.
    if(directory!==EXPORTS||!/\.json$/i.test(entry.name)){result.mediaFiles++;continue;}
    if(stat.size>256*1024*1024){result.invalidExportFiles.push({path:relative(file),reason:'Export exceeds bounded JSON inspection limit; manual review required.'});continue;}
    try{
      const data=JSON.parse(fs.readFileSync(file,'utf8').replace(/^\uFEFF/,''));
      if(!data.guild?.id||!data.channel?.id||!Array.isArray(data.messages)){result.mediaFiles++;continue;}
      const channel=data.channel,isThread=/Thread$/.test(channel.type||'');
      if((guildId&&data.guild.id!==guildId)||(known.size&&!known.has(isThread?channel.categoryId:channel.id))){result.foreignOrUnclassifiedJSON++;continue;}
      const current=startedAt&&(Date.parse(data.exportedAt)>=Date.parse(startedAt)-5000||stat.mtimeMs>=Date.parse(startedAt)-2000);
      result.jsonExportFiles++;result.exportedMessages+=data.messages.length;if(current)result.currentRunJSONExports++;
      result.exports.push({path:relative(file),bytes:stat.size,channelId:channel.id,parentId:isThread?channel.categoryId:null,type:channel.type,messageCount:data.messages.length,declaredMessageCount:data.messageCount??null,exportedAt:data.exportedAt||null,modifiedAt:stat.mtime.toISOString(),currentRun:Boolean(current)});
      if(data.messageCount!==undefined&&data.messageCount!==data.messages.length)result.invalidExportFiles.push({path:relative(file),reason:'Declared/actual message counts differ.'});
    }catch(error){result.invalidExportFiles.push({path:relative(file),reason:error.code==='EBUSY'?'Exporter is still writing this file.':'Invalid export JSON.'});}
  }};
  visit(EXPORTS);return result;
}
async function main(){
  const args=process.argv.slice(2);
  if(!args.length||(args.length===1&&args[0]==='--help')){output({usage:'node tools/menu-sources/export-cherax-cli.cjs --run | --inventory',authentication:'Only --run reads one non-echoed stdin line; no credential arguments/files are accepted.',channels:EXPECTED,cliVersion:'2.48',source:official});return;}
  if(args.length!==1||!['--run','--inventory'].includes(args[0]))throw Error('Choose only --run or --inventory; credentials are accepted on stdin only.');
  const cliProof=verifyCLI();
  if(args[0]==='--inventory'){
    const selected=fs.existsSync(CHANNELS)?JSON.parse(fs.readFileSync(CHANNELS,'utf8')):null;
    const inventory=fileInventory(selected?.guild?.id,selected?.channels||[]);
    output({mode:'inventory',cliProof,inventory:{...inventory,exports:undefined,invalidExportFiles:inventory.invalidExportFiles.slice(0,30)}});return;
  }
  ensureExports();credential=await stdinCredential();
  const startedAt=new Date().toISOString(),runId=startedAt.replace(/[:.]/g,'-')+'-'+process.pid;
  const status={schemaVersion:1,startedAt,runId,status:'discovering',complete:false,cliProof,exportDirectory:relative(EXPORTS),source:official,errors:[],warnings:[],counts:{fetchedThreads:null,plannedChannels:null,successfulChannels:null},scope:'Exact Cherax guild and the thirteen explicitly allowed share channels, with their accessible active/archived threads.'};
  save(STATUS,status);
  try{
    const guilds=await runCLI(['guilds','--respect-rate-limits','true'],{captureOnly:true});
    if(guilds.code!==0)throw Error('Official CLI guild discovery failed; no server list was saved.');
    const matches=tableRows(guilds.captured).filter(row=>guildKey(row.name)==='cherax');guilds.captured='';
    if(matches.length!==1)throw Error('Expected exactly one exact Cherax server match; no unrelated server metadata was saved.');
    const guild=matches[0];status.guild=guild;save(STATUS,status);output({status:'selected-guild',guild});
    const listing=await runCLI(['channels','-g',guild.id,'--include-threads','None','--respect-rate-limits','true'],{captureOnly:true});
    if(listing.code!==0)throw Error('Official CLI channel discovery failed; no unrelated channel list was saved.');
    const selected=tableRows(listing.captured).map(row=>({...row,canonical:channelName(row.name)})).filter(row=>row.canonical);listing.captured='';
    const duplicates=EXPECTED.filter(name=>selected.filter(row=>row.canonical===name).length!==1);
    if(duplicates.length)throw Error('Missing or ambiguous allowed share channels: '+duplicates.join(', '));
    const previous = fs.existsSync(CHANNELS) ? JSON.parse(fs.readFileSync(CHANNELS, 'utf8')) : null;
    const channels=EXPECTED.map(name=>{const row=selected.find(value=>value.canonical===name);return {id:row.id,name,guildId:guild.id,exportName:channelLeaf(row.name),hierarchicalName:row.name,collection:name.endsWith('-old')?'archival':'current',evidence:'Official DiscordChatExporter 2.48 channels output; exact Cherax guild and strict thirteen-name allowlist matched, without other channels/threads being selected.'};});
    for (const channel of channels) {
      const verified = previous?.channels?.find(row => row.id === channel.id && row.guildId === guild.id && row.name === channel.name && row.cliExportName);
      if (verified) Object.assign(channel, verified);
    }
    if(new Set(channels.map(x=>x.id)).size!==13)throw Error('Duplicate selected channel ID.');
    save(CHANNELS,{schemaVersion:1,reviewedAt:new Date().toISOString(),guild,channels,expectedChannels:EXPECTED,selection:'Strict exact-name allowlist after Unicode decorators; discussions/staff/unrelated channels excluded.',cliProof,source:official});
    status.status='exporting';status.channelMap=relative(CHANNELS);status.selectedChannels=channels.length;
    const parallel = 6;
    const exportArgs=['export','-c',...channels.map(x=>x.id),'--include-threads','All','-f','Json','-o',EXPORTS+path.sep,'--media','true','--reuse-media','true','--parallel',String(parallel),'--utc','true','--respect-rate-limits','true'];
    status.commandArguments=exportArgs;status.log=relative(path.join(EXPORTS,`cli-${runId}.log`));save(STATUS,status);
    let errorSection=false,warningSection=false;
    const onLine=(line,stream)=>{
      let match;
      if((match=line.match(/Fetched\s+(\d+)\s+thread\(s\)/i)))status.counts.fetchedThreads=Number(match[1]);
      if((match=line.match(/^Exporting\s+(\d+)\s+channel\(s\)/i)))status.counts.plannedChannels=Number(match[1]);
      if((match=line.match(/Successfully exported\s+(\d+)\s+channel\(s\)/i)))status.counts.successfulChannels=Number(match[1]);
      if(stream==='stderr'){
        if(/Failed to export the following channel/i.test(line)){errorSection=true;warningSection=false;status.reportedChannelErrors=true;}
        else if(/Warnings reported for the following channel/i.test(line)){warningSection=true;errorSection=false;}
        else if(!line.trim()){warningSection=false;errorSection=false;}
        else if(errorSection)status.errors.push(line.trim());else if(warningSection)status.warnings.push(line.trim());
        else if(/error|exception|failed|unauthorized|forbidden/i.test(line))status.errors.push(line.trim());
      }
      if(/Fetching threads|Fetched\s+\d+\s+thread|^Exporting\s+\d+\s+channel|Successfully exported|Failed to export the following|Warnings reported/.test(line)){save(STATUS,status);output({status:'export-progress',counts:status.counts,reportedChannelErrors:Boolean(status.reportedChannelErrors)});}
    };
    output({status:'export-started',channels:channels.length,includeThreads:'All',media:true,parallel});
    const ticker=setInterval(()=>output({status:'export-running',counts:status.counts}),30000);
    let exported;try{exported=await runCLI(exportArgs,{log:path.join(ROOT,status.log),onLine});}finally{clearInterval(ticker);}
    status.exitCode=exported.code;status.signal=exported.signal;status.finishedAt=new Date().toISOString();status.inventory=fileInventory(guild.id,channels,startedAt);
    const expectedNonempty=Math.max(0,(status.counts.plannedChannels??0)-status.warnings.length);
    status.complete=exported.code===0&&!exported.signal&&!status.reportedChannelErrors&&!status.errors.length&&status.counts.plannedChannels!==null&&status.counts.successfulChannels===status.counts.plannedChannels&&!status.inventory.invalidExportFiles.length&&status.inventory.currentRunJSONExports>=expectedNonempty;
    status.status=status.complete?'export-finished-without-reported-channel-errors':'partial-or-failed';
    status.completenessBasis='Official CLI result plus counts and current-run scoped JSON inventory. Accessible archived threads are requested; inaccessible/deleted content and later messages are not implied.';
    save(STATUS,status);output({status:status.status,complete:status.complete,counts:status.counts,exitCode:status.exitCode,errors:status.errors.length,warnings:status.warnings.length,inventory:{files:status.inventory.files,bytes:status.inventory.bytes,jsonExportFiles:status.inventory.jsonExportFiles,currentRunJSONExports:status.inventory.currentRunJSONExports,exportedMessages:status.inventory.exportedMessages},summary:relative(STATUS)});
    if(!status.complete)process.exitCode=1;
  }catch(error){status.status='failed';status.complete=false;status.finishedAt=new Date().toISOString();status.errors.push(redact(error.message));save(STATUS,status);throw error;}
  finally{credential='';}
}
process.on('SIGINT',()=>{if(activeChild)activeChild.kill('SIGINT');else process.exitCode=130;});
module.exports={tableRows,guildKey,channelName,channelLeaf};
if(require.main===module)main().catch(error=>{output({status:'failed',error:redact(error.message)});credential='';process.exitCode=1;});
