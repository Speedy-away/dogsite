/* Rebuild after image/page additions, edits and deletions during local preview. */
const fs=require('node:fs'),path=require('node:path');
const {build}=require('./build-reseller-media.cjs');
function watchMedia(){let timer;const root=path.resolve(__dirname,'..');const watchers=['assets/images','products'].map(dir=>fs.watch(path.join(root,dir),{recursive:true},()=>{clearTimeout(timer);timer=setTimeout(()=>{try{build();}catch(error){console.error('Media pack refresh failed:',error.message);}},1500);}));return()=>{clearTimeout(timer);watchers.forEach(w=>w.close());};}
module.exports={watchMedia};
