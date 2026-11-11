'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const ROOT = path.resolve(__dirname, '..');
function build() {
  const { build: buildPages, placeHeadAd } = require('./resource-pages.cjs');
  const data = buildPages();
  const { applyMetadata } = require('./seo-metadata');
  const guide = 'resources/guides/index.html';
  const file = path.join(ROOT, guide);
  fs.writeFileSync(file, placeHeadAd(applyMetadata(guide, fs.readFileSync(file, 'utf8'))));
  for (const script of ['seo-directory.js', 'seo-links.js', 'seo-sitemap.js']) {
    execFileSync(process.execPath, [path.join(__dirname, script), '--apply'], { cwd: ROOT, stdio: 'inherit' });
  }
  return data;
}
module.exports = { build };
if (require.main === module) build();
