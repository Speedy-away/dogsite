const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { siteRoot, repoRoot, publicEntries } = require('./site-layout.cjs');
const { build } = require('./package-site.cjs');
const { createServer } = require('./preview.cjs');
const { pages } = require('./seo-metadata');
const digest = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');

test('publishing package preserves every public file and excludes project/tooling folders', () => {
  const { publishRoot, files } = build();
  assert(files.length > 500);
  for (const relative of files) assert.equal(digest(path.join(publishRoot, relative)), digest(path.join(siteRoot, relative)), relative);
  for (const privatePath of ['tools','project','build','node_modules','.git','.agents','output','hidden_files']) assert(!fs.existsSync(path.join(publishRoot, privatePath)), privatePath);
  for (const file of Object.keys(pages)) assert(fs.existsSync(path.join(publishRoot, file)), 'Public page missing: ' + file);
  assert(fs.existsSync(path.join(publishRoot, 'products/mta-sa/index.html')));
  assert.equal(fs.readFileSync(path.join(publishRoot, 'CNAME'),'utf8'), fs.readFileSync(path.join(siteRoot,'CNAME'),'utf8'));
  assert.equal(siteRoot, repoRoot);
  assert(fs.existsSync(path.join(repoRoot, 'index.html')));
});

test('preview keeps old routes, redirects, custom 404s, MIME types, and HEAD responses', async () => {
  const server=createServer();
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const base='http://127.0.0.1:'+server.address().port;
  try {
    for(const file of Object.keys(pages)) {
      const route=file==='index.html'?'/':'/'+file.replace(/index\.html$/,'');
      assert.equal((await fetch(base+route)).status,200,route);
    }
    const redirect=await fetch(base+'/products/mta-sa',{redirect:'manual'});
    assert.equal(redirect.status,301);assert.equal(redirect.headers.get('location'),'/products/mta-sa/');
    const css=await fetch(base+'/assets/css/product-layout.css',{method:'HEAD'});
    assert.equal(css.status,200);assert.equal(css.headers.get('content-type'),'text/css');assert.equal(await css.text(),'');
    const expected=fs.readFileSync(path.join(siteRoot,'404.html'),'utf8');
    for(const route of ['/missing-page/','/tools/seo-metadata.js','/project/DEV.md','/.git/config','/build/','/assets/','/site/index.html']) {
      const response=await fetch(base+route);
      assert.equal(response.status,404,route);assert.equal(await response.text(),expected,route);
    }
    assert.equal((await fetch(base+'/%E0%A4%A')).status,400);
    assert.equal((await fetch(base+'/',{method:'POST'})).status,405);
  } finally { await new Promise(resolve=>server.close(resolve)); }
});
