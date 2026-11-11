const fs = require('node:fs');
const path = require('node:path');
const { siteRoot, repoRoot, publicEntries, isPublic } = require('./site-layout.cjs');
const publishRoot = path.join(repoRoot, 'project', 'build', 'publish');
const cheraxGitHub = 'https://raw.githubusercontent.com/Speedy-away/dogsite/main';
const cheraxAssets = new Set(['assets/downloads/cherax', 'assets/images/resource-previews/cherax']);
const cheraxURL = /\/assets\/(?:downloads|images\/resource-previews)\/cherax\/[a-f0-9]{20}\.(?:lua|json|zip|rar|7z|webp)\b/g;

function build() {
  if (!process.env.SCOOBY_RESOURCE_SYNC) require('./resource-sync.cjs').syncOnce({ seo: false });
  require('./build-resource-seo.cjs').build();
  require('./build-reseller-media.cjs').build();
  // Validate the fixed output and all source entries before replacing output.
  if (path.resolve(publishRoot) !== path.resolve(repoRoot, 'project/build/publish')) throw Error('Unexpected output path');
  for (const ancestor of [path.dirname(publishRoot), publishRoot]) {
    if (fs.existsSync(ancestor) && fs.lstatSync(ancestor).isSymbolicLink()) throw Error('Output must not be a link: ' + ancestor);
  }
  const files = [];
  function collect(relative) {
    const publicPath = relative.split(path.sep).join('/');
    if (cheraxAssets.has(publicPath) || !isPublic(relative)) return;
    const source = path.join(siteRoot, relative), stat = fs.lstatSync(source);
    if (stat.isSymbolicLink()) throw Error('Public files must not be symlinks: ' + relative);
    if (stat.isDirectory()) for (const name of fs.readdirSync(source)) collect(path.join(relative, name));
    else if (stat.isFile()) files.push(relative);
  }
  for (const entry of publicEntries) collect(entry);
  fs.rmSync(publishRoot, { recursive: true, force: true });
  fs.mkdirSync(publishRoot, { recursive: true });
  for (const relative of files) {
    const destination = path.join(publishRoot, relative);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    const source = path.join(siteRoot, relative);
    const publicPath = relative.split(path.sep).join('/');
    if (publicPath === 'community/data/menu-resources.json' || (publicPath.startsWith('resources/') && publicPath.endsWith('.html'))) {
      const markup = fs.readFileSync(source, 'utf8');
      fs.writeFileSync(destination, markup.replace(cheraxURL, url => cheraxGitHub + url));
    } else fs.copyFileSync(source, destination);
  }
  console.log(`Packaged ${files.length} files into ${publishRoot}`);
  return { publishRoot, files };
}
if (require.main === module) build();
module.exports = { build, publishRoot };
