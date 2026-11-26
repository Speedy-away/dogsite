const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const root=process.env.SCOOBY_PORTAL_ROOT||path.resolve(__dirname,'..');
test('console switch is a public literal endpoint at the exact requested URL',async()=>{
 const {isPublic}=require(path.join(root,'tools/site-layout.cjs'));
 assert.equal(isPublic('scoobyps4switch.html'),true);
 assert.equal(fs.readdirSync(root).includes('scoobyps4switch.html'),true);
 const expected=fs.readFileSync(path.join(root,'scoobyps4switch.html'),'utf8');
 assert.match(expected,/^[01]\r?\n?$/);
 const {walk}=require(path.join(root,'tools/seo-metadata.js'));
 assert(!walk(root).includes(path.join(root,'scoobyps4switch.html')),'Literal switch must not be processed or indexed as HTML');
 const {createServer}=require(path.join(root,'tools/preview.cjs'));
 const server=createServer(root);await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 try {const response=await fetch(`http://127.0.0.1:${server.address().port}/scoobyps4switch.html`);assert.equal(response.status,200);assert.equal(await response.text(),expected);}
 finally {await new Promise(resolve=>server.close(resolve));}
});
