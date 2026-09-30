const fs=require('node:fs'),path=require('node:path');
const root=process.cwd(),{applyMetadata}=require('../../tools/seo-metadata');
const changed=JSON.parse(fs.readFileSync('build/tf2-site/changed-pages.json','utf8'));
for(const file of changed.filter(x=>x.endsWith('.html'))){
 const p=path.join(root,file),before=fs.readFileSync(p,'utf8'),after=applyMetadata(file,before);
 if(before!==after)fs.writeFileSync(p,after);
}
console.log('Applied metadata to the changed page set.');
