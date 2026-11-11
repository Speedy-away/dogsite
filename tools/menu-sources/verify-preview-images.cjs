'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const catalog = require('../../community/data/menu-resources.json');
const output = path.join(ROOT, 'project/community-menu-sources/menu-image-checks.json');
const checks = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
function extension(bytes) {
  if (bytes[0] === 255 && bytes[1] === 216) return '.jpg';
  if (bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) return '.png';
  if (bytes.subarray(0, 3).toString() === 'GIF') return '.gif';
  if (bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP') return '.webp';
  return '';
}
(async () => {
  const urls = [...new Set([...catalog.items, ...catalog.libraryOverrides].filter(item => item.previewVerified && /^https:/.test(item.preview)).map(item => item.preview))];
  for (let index = 0; index < urls.length; index += 3) {
    await Promise.all(urls.slice(index, index + 3).map(async url => {
      if (checks[url]?.localPath) return;
      if (new URL(url).hostname !== 'raw.githubusercontent.com') return;
      try {
        const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
        if (response.status === 429) throw Error('Rate limited; stop and retry later');
        checks[url] = { status: response.status, verified: false };
        if (!response.ok || !/image\//.test(response.headers.get('content-type') || '')) { await response.body?.cancel(); return; }
        const bytes = Buffer.from(await response.arrayBuffer()), ext = extension(bytes);
        if (!ext || bytes.length > 8 * 1024 * 1024) return;
        const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
        const relative = `project/community-menu-sources/assets/verified-previews/${sha256.slice(0, 20)}${ext}`;
        fs.mkdirSync(path.dirname(path.join(ROOT, relative)), { recursive: true });
        fs.writeFileSync(path.join(ROOT, relative), bytes);
        checks[url] = { status: 200, verified: true, localPath: relative, size: bytes.length, sha256 };
      } catch (error) { checks[url] = { verified: false, error: error.message }; }
    }));
    fs.writeFileSync(output, JSON.stringify(checks, null, 2) + '\n');
    if (urls.slice(index, index + 3).some(url => /Rate limited/.test(checks[url]?.error || ''))) break;
  }
  console.log(JSON.stringify({ requested: urls.length, verified: Object.values(checks).filter(check => check.verified).length, unavailable: Object.values(checks).filter(check => !check.verified).length }));
})();
