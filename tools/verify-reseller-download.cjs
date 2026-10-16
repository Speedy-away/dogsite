const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { publishRoot } = require('./package-site.cjs');
const { createServer } = require('./preview.cjs');

async function verify() {
  const relative = 'assets/downloads/scooby-reseller-media.zip';
  const metadata = JSON.parse(fs.readFileSync(path.join(publishRoot, 'assets/downloads/reseller-media.json'), 'utf8'));
  const archive = fs.readFileSync(path.join(publishRoot, relative));
  assert.equal(archive.length, metadata.bytes);
  assert.equal(archive.readUInt32LE(0), 0x04034b50, 'Download must be a ZIP');
  assert.equal(archive.readUInt32LE(archive.length - 22), 0x06054b50, 'ZIP directory must be complete');
  assert.equal(archive.readUInt16LE(archive.length - 12), metadata.files);
  for (const slug of ['gta5','rdr2','redm','fivem','cs2','gmod','l4d','free-games']) {
    assert(metadata.packs.some(pack => pack.slug === slug), 'Missing product pack: ' + slug);
  }
  const server = createServer(publishRoot);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/${relative}`, { method:'HEAD' });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('content-type'), 'application/zip');
    assert.equal(Number(response.headers.get('content-length')), metadata.bytes);
    for (const pack of metadata.packs) {
      const data = fs.readFileSync(path.join(publishRoot, pack.url.slice(1)));
      assert.equal(data.length, pack.bytes, pack.slug);
      assert.equal(data.readUInt32LE(0), 0x04034b50, pack.slug);
      assert.equal(data.readUInt16LE(data.length - 12), pack.files, pack.slug);
      const result = await fetch(`http://127.0.0.1:${server.address().port}${pack.url}`, { method:'HEAD' });
      assert.equal(result.status, 200, pack.slug);
      assert.equal(result.headers.get('content-type'), 'application/zip', pack.slug);
    }
    console.log(`Verified published media download: ${metadata.files} files, ${metadata.bytes} bytes, HTTP 200 application/zip.`);
  } finally { await new Promise(resolve => server.close(resolve)); }
}
if (require.main === module) verify().catch(error => { console.error(error); process.exitCode = 1; });
module.exports = { verify };
