// Backward-compatible entry point; both games use the source-backed generator.
const cp=require('node:child_process'),path=require('node:path');
const result=cp.spawnSync(process.execPath,[path.join(__dirname,'build-rockstar-lua-docs.cjs'),'--game','RDR2',...process.argv.slice(2)],{stdio:'inherit'});
if(result.error)throw result.error;process.exitCode=result.status??1;
