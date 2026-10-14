/* Refresh GTA 5 source data and both public pages together. No game-source writes. */
const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const root = path.resolve(__dirname,'../..');
const manifestPath = path.join(__dirname,'features-gta5.json');
const flatten = manifest => manifest.tabs.flatMap(tab=>tab.categories.flatMap(category=>category.groups.flatMap(group=>group.items)));
const before = fs.existsSync(manifestPath) ? flatten(JSON.parse(fs.readFileSync(manifestPath,'utf8'))) : [];
execFileSync(process.execPath,[path.join(__dirname,'extract-gta5.js')],{cwd:root,stdio:'inherit'});
const manifest = JSON.parse(fs.readFileSync(manifestPath,'utf8'));
const after = flatten(manifest);
const product = path.join(root,'products/gta5/index.html');
let html = fs.readFileSync(product,'utf8');
const comparison = /<!-- GTA5 COMPARISON START -->[\s\S]*?<!-- GTA5 COMPARISON END -->/;
if (!comparison.test(html)) throw new Error('GTA comparison markers missing');
html = html.replace(comparison,'<!-- GTA5 COMPARISON START -->\n'+require('./gta5-editions.cjs').renderComparison()+'\n<!-- GTA5 COMPARISON END -->');
html = html.replace(/[\d,]+ features (?:&amp;|&) settings/g,manifest.stats.features.toLocaleString('en-US')+' features &amp; settings')
  .replace(/[\d,]+ features and settings across \d+ sections/g,`${manifest.stats.features.toLocaleString('en-US')} features and settings across ${manifest.stats.tabs} sections`);
fs.writeFileSync(product,html);
execFileSync(process.execPath,[path.join(__dirname,'build-features-page.js'),'--only','gta5','--apply'],{cwd:root,stdio:'inherit'});
const previousIds = new Set(before.map(i=>i.id)), currentIds = new Set(after.map(i=>i.id));
console.log('Added:',after.filter(i=>!previousIds.has(i.id)).map(i=>i.label).join(', ') || 'none');
console.log('Removed:',before.filter(i=>!currentIds.has(i.id)).map(i=>i.label).join(', ') || 'none');
