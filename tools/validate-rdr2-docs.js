// Backward-compatible RDR2 documentation acceptance command.
const cp=require('node:child_process'),path=require('node:path');
const result=cp.spawnSync(process.execPath,[path.join(__dirname,'validate-rockstar-lua-docs.cjs'),'--game','RDR2',...process.argv.slice(2)],{stdio:'inherit'});
if(result.error)throw result.error;process.exitCode=result.status??1;
