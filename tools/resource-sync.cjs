'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync, spawn } = require('node:child_process');
const ROOT = path.resolve(__dirname, '..');
const DEFAULT_CONFIG = path.join(ROOT, 'project/resource-sources.json');
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
const stable = value => JSON.stringify(value, (key, item) => item && typeof item === 'object' && !Array.isArray(item) ? Object.fromEntries(Object.keys(item).sort().map(name => [name, item[name]])) : item);
const read = file => JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
function atomic(file, bytes) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(temporary, bytes);
  fs.renameSync(temporary, file);
}
function filesUnder(input) {
  if (!fs.existsSync(input)) return [];
  const stat = fs.lstatSync(input);
  if (stat.isSymbolicLink()) return [];
  if (stat.isFile()) return [input];
  if (!stat.isDirectory()) return [];
  return fs.readdirSync(input, { withFileTypes: true }).filter(entry => !entry.name.startsWith('.') && !['node_modules', 'build', 'bin', 'obj', '__pycache__'].includes(entry.name))
    .sort((a, b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => filesUnder(path.join(input, entry.name)));
}
function loadConfig(file = DEFAULT_CONFIG, root = ROOT) {
  const config = read(file);
  if (config.version !== 1 || !Array.isArray(config.sources)) throw Error('Invalid resource source registry');
  const seen = new Set();
  for (const source of config.sources) {
    if (!source.id || seen.has(source.id) || !['native', 'menus', 'inbox'].includes(source.kind) || !Array.isArray(source.paths)) throw Error('Invalid resource source');
    seen.add(source.id);
  }
  return { ...config, root, configFile: path.resolve(file), target: path.resolve(root, config.downloadRepository), stateFile: path.resolve(root, 'project/build/resource-sync/state.json') };
}
function manifestAssets(file, config) {
  const sourceRoot = path.resolve(config.root, 'project/community-menu-sources');
  const within = value => value.startsWith(sourceRoot + path.sep);
  if (!within(file) || path.extname(file).toLowerCase() !== '.json') return [];
  const assets = new Set();
  const visit = value => {
    if (!value || typeof value !== 'object') return;
    for (const [key, child] of Object.entries(value)) {
      if (['localPath', 'preview'].includes(key) && typeof child === 'string' && child.replaceAll('\\', '/').startsWith('project/community-menu-sources/')) {
        const candidate = path.resolve(config.root, child);
        if (within(candidate) && (!fs.existsSync(candidate) || (within(fs.realpathSync(candidate)) && fs.statSync(candidate).isFile()))) assets.add(candidate);
      } else if (child && typeof child === 'object') visit(child);
    }
  };
  visit(read(file));
  return [...assets].sort();
}
function snapshot(config, previous = {}) {
  const memo = {}, sources = [], oldMemo = previous.files || {};
  for (const source of config.sources) {
    const paths = source.paths.map(value => path.resolve(config.root, value));
    const missing = source.required && !fs.existsSync(path.resolve(config.root, source.required));
    const entries = [];
    const inputs = [...paths], visited = new Set();
    for (const input of inputs) {
      const files = filesUnder(input);
      if (!files.length) entries.push([input, fs.existsSync(input) ? 'empty' : 'missing']);
      for (const file of files) {
        if (visited.has(file)) continue;
        visited.add(file);
        const stat = fs.statSync(file), key = `${stat.size}:${stat.mtimeMs}:${stat.ctimeMs}`;
        const sha256 = oldMemo[file]?.key === key ? oldMemo[file].sha256 : digest(fs.readFileSync(file));
        memo[file] = { key, sha256 };
        if (source.kind === 'menus' && paths.includes(input)) {
          const dependencies = oldMemo[file]?.key === key && Array.isArray(oldMemo[file].dependencies) ? oldMemo[file].dependencies : manifestAssets(file, config);
          memo[file].dependencies = dependencies;
          inputs.push(...dependencies.filter(candidate => !visited.has(candidate)));
        }
        entries.push([file, sha256]);
      }
    }
    entries.sort((a, b) => a[0].localeCompare(b[0], 'en'));
    const fingerprint = digest(JSON.stringify(entries));
    const emptyInbox = source.kind === 'inbox' && paths.some(input => fs.existsSync(input) && fs.statSync(input).isDirectory());
    sources.push({ ...source, paths, available: !missing && (emptyInbox || entries.some(([, value]) => !['empty', 'missing'].includes(value))), fingerprint, changed: previous.sources?.[source.id] !== fingerprint });
  }
  return { files: memo, sources, registryHash: digest(fs.readFileSync(config.configFile)) };
}
function inventory(config) {
  const previous = fs.existsSync(config.stateFile) ? read(config.stateFile) : {};
  const current = snapshot(config, previous);
  const registryChanged = previous.registryHash !== current.registryHash;
  const changed = current.sources.filter(source => source.available && (source.changed || registryChanged));
  return { previous, current, changed, unavailable: current.sources.filter(source => !source.available).map(source => source.id) };
}
function runNode(config, script, args = []) {
  execFileSync(process.execPath, [path.join(config.root, script), ...args], { cwd: config.root, stdio: 'inherit', windowsHide: true, env: { ...process.env, SCOOBY_RESOURCE_SYNC: '1' } });
}
function catalogEntries(root) {
  const entries = new Map();
  for (const relative of ['community/data/library.json', 'community/data/menu-resources.json']) {
    const file = path.join(root, relative);
    if (!fs.existsSync(file)) continue;
    const catalog = read(file);
    for (const item of catalog.items || []) entries.set(item.id, item);
    for (const item of catalog.libraryOverrides || []) entries.set(item.id, { ...entries.get(item.id), ...item });
  }
  return entries;
}
function syncOnce(options = {}) {
  const config = options.config || loadConfig(options.configFile, options.root || ROOT);
  const publicRefreshErrors = [];
  if (options.refreshPublic && !options.check) for (const action of config.publicRefresh || []) {
    if (typeof action.script !== 'string' || !action.script.startsWith('tools/') || action.script.split('/').includes('..') || !Array.isArray(action.args)) throw Error('Invalid public source refresh action');
    try { runNode(config, action.script, action.args); }
    catch (error) { publicRefreshErrors.push({ script: action.script, error: error.message }); }
  }
  const plan = inventory(config);
  if (options.force) plan.changed = plan.current.sources.filter(source => source.available);
  const report = { checkedAt: new Date().toISOString(), changedSources: plan.changed.map(source => source.id), unavailable: plan.unavailable, publicRefreshErrors, updated: false, actions: [] };
  if (options.check) return report;
  if (!fs.existsSync(config.target)) {
    report.skipped = 'Download repository unavailable; using the prepared website catalogs.';
    return report;
  }
  if (!plan.changed.length) {
    if (JSON.stringify(plan.previous.files) !== JSON.stringify(plan.current.files)) atomic(config.stateFile, JSON.stringify({ ...plan.previous, files: plan.current.files }, null, 2));
    return report;
  }
  const stateDirectory = path.dirname(config.stateFile), lock = path.join(stateDirectory, 'sync.lock');
  fs.mkdirSync(stateDirectory, { recursive: true });
  let descriptor;
  try { descriptor = fs.openSync(lock, 'wx'); fs.writeFileSync(descriptor, JSON.stringify({ pid: process.pid, started: report.checkedAt })); }
  catch (error) {
    if (error.code !== 'EEXIST') throw error;
    let active = false;
    try { const pid = read(lock).pid; if (Number.isSafeInteger(pid) && pid > 0) { active = true; process.kill(pid, 0); } } catch (status) { active = active && status.code !== 'ESRCH'; }
    if (active) throw Error('A resource update is already running; retry after it finishes.');
    fs.unlinkSync(lock);
    descriptor = fs.openSync(lock, 'wx'); fs.writeFileSync(descriptor, JSON.stringify({ pid: process.pid, started: report.checkedAt }));
  }
  const protectedFiles = ['community/data/library.json', 'community/data/menu-resources.json'].map(file => path.join(config.root, file))
    .concat(['catalog/library.json', 'catalog/menu-resources.json'].map(file => path.join(config.target, file)));
  const backups = protectedFiles.map(file => [file, fs.existsSync(file) ? fs.readFileSync(file) : null]);
  const execute = options.run || ((script, args) => runNode(config, script, args));
  const before = catalogEntries(config.root);
  try {
    const native = plan.changed.filter(source => source.kind === 'native');
    if (native.length) {
      const games = [...new Set(native.flatMap(source => source.games || []))];
      const args = ['--target', config.target, '--source-root', path.resolve(config.root, config.sourceRoot), '--refresh-catalog'];
      if (games.length) execute('tools/build-community-library.cjs', [...args, '--refresh-games', games.join(',')]);
      if (native.some(source => !source.games?.length)) execute('tools/build-community-library.cjs', args);
      report.actions.push('native catalogs');
    }
    if (plan.changed.some(source => source.kind === 'inbox')) {
      execute('tools/import-resource-inbox.cjs', ['--inbox', path.resolve(config.root, config.inbox)]);
      report.actions.push('resource inbox');
    }
    execute('tools/build-menu-resources.cjs', ['--target', config.target, '--publish-assets']);
    report.actions.push('menu resources and previews');
    if (options.seo !== false) { execute('tools/build-resource-seo.cjs', []); report.actions.push('guides and sitemaps'); }
    const afterEntries = catalogEntries(config.root), describe = item => ({ id: item.id, name: item.name, game: item.game, category: item.category });
    report.resources = {
      added: [...afterEntries.values()].filter(item => !before.has(item.id)).map(describe),
      updated: [...afterEntries.values()].filter(item => before.has(item.id) && stable(item) !== stable(before.get(item.id))).map(describe),
      removed: [...before.values()].filter(item => !afterEntries.has(item.id)).map(describe),
      totalCatalogEntries: afterEntries.size
    };
    // Checkpoint only the inputs observed before importing. Edits made during a
    // build must remain pending, even if the importer happened to see some of them.
    atomic(config.stateFile, JSON.stringify({ version: 1, checkedAt: report.checkedAt, registryHash: plan.current.registryHash, sources: Object.fromEntries(plan.current.sources.map(source => [source.id, source.fingerprint])), files: plan.current.files }, null, 2));
    report.updated = true;
    atomic(path.join(stateDirectory, 'last-run.json'), JSON.stringify(report, null, 2));
    return report;
  } catch (error) {
    for (const [file, bytes] of backups) {
      if (bytes !== null) atomic(file, bytes);
      else if (fs.existsSync(file)) fs.unlinkSync(file);
    }
    throw error;
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    if (fs.existsSync(lock)) fs.unlinkSync(lock);
  }
}
function watchSources(options = {}) {
  const config = options.config || loadConfig(options.configFile, options.root || ROOT);
  let timer, stopped = false;
  const watchers = [];
  const update = () => {
    if (stopped) return;
    clearTimeout(timer);
    timer = setTimeout(() => {
      try { const currentConfig = options.config || loadConfig(config.configFile, config.root); const report = syncOnce({ ...options, config: currentConfig }); if (report.updated) console.log('[resources]', JSON.stringify(reportSummary(report))); }
      catch (error) { console.error('[resources]', error.message); }
    }, 900);
  };
  const roots = [...new Set([config.configFile, ...config.sources.flatMap(source => source.paths.map(value => path.resolve(config.root, value)))])];
  for (const input of roots) {
    if (!fs.existsSync(input)) continue;
    try { const watcher = fs.watch(input, { recursive: fs.statSync(input).isDirectory(), persistent: true }, update); watcher.on('error', update); watchers.push(watcher); }
    catch { /* The periodic source scan also catches unavailable watch backends. */ }
  }
  const poll = setInterval(update, 30000);
  update();
  return () => { stopped = true; clearTimeout(timer); clearInterval(poll); watchers.forEach(watcher => watcher.close()); };
}
function startPreviewWatcher() {
  const child = spawn(process.execPath, [__filename, '--watch'], { cwd: ROOT, stdio: 'inherit', windowsHide: true, env: { ...process.env, SCOOBY_RESOURCE_SYNC: '1' } });
  return () => { if (!child.killed) child.kill(); };
}
function reportSummary(report) {
  const { resources, ...summary } = report;
  return { ...summary, ...(resources ? { resources: { added: resources.added.length, updated: resources.updated.length, removed: resources.removed.length, totalCatalogEntries: resources.totalCatalogEntries } } : {}) };
}
module.exports = { loadConfig, snapshot, inventory, syncOnce, watchSources, startPreviewWatcher, reportSummary };
if (require.main === module) {
  try {
    const args = process.argv.slice(2);
    if (args.includes('--help')) { console.log('Usage: node tools/resource-sync.cjs [--check | --watch] [--force] [--refresh-public] [--config FILE]\nLocal changes are imported once by default. --check makes no changes; --watch continues until stopped.'); process.exit(0); }
    for (let i = 0; i < args.length; i++) {
      if (args[i] === '--config') { if (!args[++i] || args[i].startsWith('--')) throw Error('--config requires a file path'); }
      else if (!['--check', '--dry-run', '--watch', '--force', '--refresh-public'].includes(args[i])) throw Error(`Unknown resource update option: ${args[i]}`);
    }
    const index = process.argv.indexOf('--config'), options = { ...(index >= 0 ? { configFile: process.argv[index + 1] } : {}), check: args.includes('--check') || args.includes('--dry-run'), force: args.includes('--force'), refreshPublic: args.includes('--refresh-public') };
    if (args.includes('--watch') && (options.check || options.refreshPublic || options.force)) throw Error('--watch cannot be combined with --check, --force or --refresh-public. Run a one-time refresh separately.');
    if (process.argv.includes('--watch')) {
      const close = watchSources(options);
      for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => { close(); process.exit(); });
      console.log('Watching configured resource sources. Ctrl+C stops the watcher.');
    } else console.log(JSON.stringify(reportSummary(syncOnce(options)), null, 2));
  } catch (error) { console.error(error.stack || error.message); process.exitCode = 1; }
}
