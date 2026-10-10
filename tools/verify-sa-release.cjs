/* Verify the exact public artifact before importing it into the site catalog. */
const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const root = path.resolve(__dirname, '..');
const base = 'https://raw.githubusercontent.com/Rendererrr/Rendererrr.github.io/main/scooby/rockstar-classics/GTA/SA/';
const version = process.argv[2];
if (!/^\d{4}\.\d{2}\.\d{2}-free-beta\.\d+$/.test(version || '')) throw new Error('Pass the expected SA free beta version');
async function get(url) {
  const response = await fetch(url, {headers: {'Cache-Control': 'no-cache'}, signal: AbortSignal.timeout(120000)});
  if (!response.ok) throw new Error(`${response.status}: ${url}`);
  return response;
}
(async () => {
  const release = await (await get(`${base}release.json?site_release=${version}&verified_at=${Date.now()}`)).json();
  if (release.id !== 'gta-sa' || release.version !== version || release.access !== 'free' || release.channel !== 'beta' || release.runtimeAccepted !== false) throw new Error('Release metadata does not match expected free beta');
  if (release.url !== `${base}Scooby-SA-${version}.zip` || release.manifest !== `${version}/manifest.json`) throw new Error('Unexpected artifact path');
  if (!/^[a-f0-9]{64}$/.test(release.sha256) || !/^[a-f0-9]{64}$/.test(release.manifestSha256)) throw new Error('Invalid release hashes');
  const manifestBytes = Buffer.from(await (await get(`${base}${release.manifest}?site_release=${version}`)).arrayBuffer());
  if (createHash('sha256').update(manifestBytes).digest('hex') !== release.manifestSha256) throw new Error('Manifest hash mismatch');
  const manifest = JSON.parse(manifestBytes.toString('utf8'));
  if (manifest.id !== 'gta-sa' || manifest.release !== version || manifest.edition !== 'classic' || manifest.runtimeAccepted !== false || !/^[a-f0-9]{64}$/.test(manifest.gameSha256)) throw new Error('Unexpected compatibility manifest');
  const response = await get(`${release.url}?release_sha256=${release.sha256}`);
  const digest = createHash('sha256');
  let bytes = 0;
  for await (const block of response.body) { bytes += block.length; digest.update(block); }
  if (bytes !== release.bytes || digest.digest('hex') !== release.sha256) throw new Error('ZIP hash or size mismatch');
  const catalogPath = path.join(root, 'assets/data/rockstar-classics.json');
  const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
  const game = catalog.games.find(game => game.id === 'gta-sa');
  game.state = 'beta'; game.runtimeAccepted = false; game.releaseArtifact = release;
  game.releaseNote = 'Free beta release; live gameplay and performance acceptance pending.';
  fs.writeFileSync(catalogPath, JSON.stringify(catalog, null, 2) + '\n');
  const receipt = {verifiedAt: new Date().toISOString(), version, bytes, sha256: release.sha256, manifestSha256: release.manifestSha256, url: release.url};
  fs.mkdirSync(path.join(root, 'project/build/sa-site'), {recursive: true});
  fs.writeFileSync(path.join(root, 'project/build/sa-site/release-verification.json'), JSON.stringify(receipt, null, 2) + '\n');
  console.log(JSON.stringify(receipt, null, 2));
})().catch(error => {console.error(error.message); process.exitCode = 1;});
