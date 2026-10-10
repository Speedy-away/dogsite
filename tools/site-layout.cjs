const path = require('node:path');
const siteRoot = path.resolve(__dirname, '..');
const repoRoot = siteRoot;
// Public URL roots. Tooling and project artifacts are deliberately absent.
const publicEntries = [
  'api','assets','best-mod-menu','changelog','docs','download','features-list',
  'fivem-features','guides','lang','more-games','portal','products','resellers',
  'revolution','scooby-features','sitemap','rockstar-classics','source-games','store','tos','videos',
  'web-radar','.nojekyll','404.html','background-home.jpg','background-home5.png',
  'changelog.json','changelog.txt','CNAME','discord.html','freekey.html','index.html',
  'indexnow-key.txt','logo.png','playerF.webp','robots.txt','scoobyontop.html','sitemap.xml'
];
function isPublic(relative) {
  const parts = relative.split(/[\\/]/).filter(Boolean);
  return parts.length > 0 && publicEntries.includes(parts[0]) &&
    parts.every(part => !part.startsWith('.') || part === '.nojekyll') &&
    !parts.some(part => ['node_modules', '__pycache__'].includes(part));
}
module.exports = { siteRoot, repoRoot, publicEntries, isPublic };
