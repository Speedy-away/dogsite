// A source change requires a human review of the feature descriptions before updating hashes.
// node tools/check-tf2-features.js [--tf2-root PATH]
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const args=process.argv.slice(2),at=args.indexOf('--tf2-root');
const family=at<0?path.resolve(__dirname,'../../Scooby-Op/source/TF2'):path.resolve(args[at+1]);
const data=JSON.parse(fs.readFileSync(path.join(__dirname,'features/features-tf2.json'),'utf8'));
const errors=[],ids=new Set();let count=0;
for(const [file,expected] of Object.entries(data.source_hashes)){
 const source=path.resolve(family,file);
 if(!fs.existsSync(source)){errors.push('Missing feature source: '+file);continue;}
 const hash=crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex');
 if(hash!==expected)errors.push('Review changed feature source: '+file);
}
for(const tab of data.tabs)for(const category of tab.categories)for(const group of category.groups)for(const item of group.items){
 if(!item.id||!item.label||!item.desc||ids.has(item.id))errors.push('Missing or duplicate feature: '+item.id);
 ids.add(item.id);count++;
 if((item.id.startsWith('skins.')||item.id.startsWith('inventory.'))&&!item.desc.startsWith('Retail TF2 only.'))errors.push('Missing retail scope: '+item.id);
}
if(ids.has('skins.enabled'))errors.push('Removed Classified skins control is still advertised.');
for(const id of ['view.freecam','movement.rev_jump','movement.prespeed','vfx.no_fog','inventory.native','settings.capture_protection'])if(!ids.has(id))errors.push('Missing current feature: '+id);
if(errors.length){console.error(errors.join('\n'));process.exitCode=1;}else console.log(`TF2 catalog verified: ${count} entries, ${Object.keys(data.source_hashes).length} source hashes.`);