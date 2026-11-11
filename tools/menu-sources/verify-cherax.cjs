'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const directory = path.join(ROOT, 'project/community-menu-sources');
const cacheFile = path.join(directory, 'cherax-network-checks.json');
const audit = JSON.parse(fs.readFileSync(path.join(directory, 'cherax-public-audit.json'), 'utf8'));
const checks = fs.existsSync(cacheFile) ? JSON.parse(fs.readFileSync(cacheFile, 'utf8')) : { checkedAt: null, entries: [] };
const saved = new Map(checks.entries.map(entry => [entry.id, entry]));
const headers = { 'User-Agent': 'Scooby-Resource-Source-Check' };
let throttled = false;
function save() {
  checks.checkedAt = new Date().toISOString();
  checks.entries = [...saved.values()];
  fs.writeFileSync(cacheFile, JSON.stringify(checks, null, 2) + '\n');
}
function imageExtension(bytes) {
  if (bytes[0] === 0xff && bytes[1] === 0xd8) return '.jpg';
  if (bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) return '.png';
  if (bytes.subarray(0, 3).toString() === 'GIF') return '.gif';
  if (bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP') return '.webp';
  return '';
}
async function request(url, method) {
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:' || !['github.com', 'raw.githubusercontent.com'].includes(parsed.hostname)) throw Error('Unsupported public source');
  const response = await fetch(url, { method, headers, signal: AbortSignal.timeout(25000) });
  if ([429, 403].includes(response.status) && /rate|limit/i.test(response.headers.get('x-ratelimit-remaining') || response.headers.get('retry-after') || '')) throttled = true;
  if (response.status === 429) throttled = true;
  return response;
}
async function verify(item) {
  if (saved.get(item.id)?.complete) return;
  const result = { id: item.id, files: [], preview: null, complete: false };
  try {
    for (const file of item.publisherFiles || []) {
      const response = await request(file.download_url, 'HEAD');
      const type = response.headers.get('content-type') || '';
      result.files.push({ url: file.download_url, name: file.asset_name, size: Number(response.headers.get('content-length')) || file.size_bytes, sha256: file.sha256,
        status: response.status, verified: response.ok && !/text\/html/i.test(type), contentType: type });
      if (throttled) break;
    }
    if (!throttled && ['original_discord_screenshot', 'source_theme_artwork'].includes(item.previewKind) && item.preview) {
      const response = await request(item.preview, 'GET');
      if (response.ok && /image\//i.test(response.headers.get('content-type') || '')) {
        const bytes = Buffer.from(await response.arrayBuffer());
        const extension = imageExtension(bytes);
        if (extension && bytes.length <= 8 * 1024 * 1024) {
          const relative = `assets/cherax/previews/${item.id}${extension}`;
          const target = path.join(directory, relative);
          fs.mkdirSync(path.dirname(target), { recursive: true });
          fs.writeFileSync(target, bytes);
          result.preview = { sourceUrl: item.preview, localPath: `project/community-menu-sources/${relative}`, size: bytes.length,
            sha256: crypto.createHash('sha256').update(bytes).digest('hex'), kind: item.previewKind };
        }
      } else if (response.body) await response.body.cancel();
    }
    result.complete = !throttled;
  } catch (error) { result.error = error.message; }
  saved.set(item.id, result);
  save();
}
(async () => {
  const items = audit.items.filter(item => item.category === 'themes');
  for (let index = 0; index < items.length && !throttled; index += 3) {
    await Promise.all(items.slice(index, index + 3).map(verify));
    if (index % 24 === 0) console.log(`Checked ${Math.min(index + 3, items.length)}/${items.length} Cherax themes`);
  }
  save();
  console.log(JSON.stringify({ checked: checks.entries.length, verifiedFiles: checks.entries.flatMap(entry => entry.files).filter(file => file.verified).length,
    previews: checks.entries.filter(entry => entry.preview).length, throttled }));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
