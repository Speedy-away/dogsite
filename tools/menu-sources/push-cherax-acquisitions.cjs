'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

const target = path.resolve(__dirname, '../../../cool-repo');
const scratch = path.resolve(__dirname, '../../project/community-menu-sources/cherax-push-state');
const catalogPath = 'catalog/cherax-acquired-assets.json';
const namespaces = ['downloads/gta5/menus/cherax', 'previews/gta5/menus/cherax'];
const attributes = namespaces.map(directory => directory + '/.gitattributes');
const assetPath = /^(?:downloads|previews)\/gta5\/menus\/cherax\/[0-9a-f]{20}\.[a-z0-9]+$/;
const batchLimit = 100 * 1024 * 1024;
const postBuffer = 120 * 1024 * 1024;
const commitTitle = 'Add Cherax acquisition batch';
const origin = 'https://github.com/Speedy-away/cool-repo.git';

function runGit(args, options = {}) {
  return execFileSync('git', ['-c', 'safe.directory=' + target.split(path.sep).join('/'), ...args], {
    cwd: target, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024, windowsHide: true,
    stdio: [options.input ? 'pipe' : 'ignore', 'pipe', 'pipe'],
    input: options.input,
    env: { ...process.env, GCM_INTERACTIVE: '0', GIT_TERMINAL_PROMPT: '0', ...options.env },
  }).trimEnd();
}

function git(...args) { return runGit(args); }

function sha256(bytes) {
  return crypto.createHash('sha256').update(bytes).digest('hex');
}

function file(name) {
  return path.join(target, name);
}

function names(output) {
  return output.split('\0').filter(Boolean);
}

function pendingBatches(assets, tracked) {
  const pending = [...assets].filter(([name]) => !tracked.has(name));
  pending.sort((a, b) => b[1].size - a[1].size || a[0].localeCompare(b[0]));
  const batches = [];
  for (const row of pending) {
    const size = row[1].size;
    let batch = batches.find(item => item.bytes + size <= batchLimit);
    if (!batch) {
      batch = { bytes: 0, rows: [] };
      batches.push(batch);
    }
    batch.rows.push(row);
    batch.bytes += size;
  }
  return batches;
}

function verifyFile(name, expected) {
  const stat = fs.lstatSync(file(name));
  const canonical = fs.realpathSync(file(name));
  const relative = path.relative(fs.realpathSync(target), canonical).split(path.sep).join('/');
  if (!stat.isFile() || stat.isSymbolicLink() || relative !== name || stat.size !== expected.size) throw new Error('Acquired file changed: ' + name);
  const bytes = fs.readFileSync(canonical);
  if (sha256(bytes) !== expected.sha256) throw new Error('Acquired file changed: ' + name);
  return crypto.createHash('sha1').update('blob ' + bytes.length + '\0').update(bytes).digest('hex');
}

function readCatalog() {
  const bytes = fs.readFileSync(file(catalogPath));
  const data = JSON.parse(bytes);
  if (data.schema !== 'cherax-acquired-assets.v1' || !Array.isArray(data.assets)) throw new Error('Invalid Cherax acquisition catalog');
  const assets = new Map();
  for (const row of data.assets) {
    const name = row.path;
    const actual = row.actual;
    if (!assetPath.test(name) || !/^[0-9a-f]{64}$/.test(actual?.sha256) ||
        !name.endsWith('/' + actual.sha256.slice(0, 20) + actual.extension) ||
        !Number.isSafeInteger(actual.size) || actual.size <= 0 || actual.size >= batchLimit) {
      throw new Error('Unexpected acquisition file: ' + name);
    }
    const previous = assets.get(name);
    if (previous && (previous.size !== actual.size || previous.sha256 !== actual.sha256)) throw new Error('Conflicting acquisition: ' + name);
    assets.set(name, actual);
  }
  return { assets, catalogHash: sha256(bytes) };
}

function main() {
  const args = process.argv.slice(2);
  if (args.length > 1 || (args.length && !['--plan', '--push'].includes(args[0]))) throw new Error('Use --plan or --push');
  const push = args[0] === '--push';
  if (git('remote', 'get-url', '--push', 'origin') !== origin || git('branch', '--show-current') !== 'main') throw new Error('Expected cool-repo origin and main branch');
  const { assets, catalogHash } = readCatalog();
  const remoteHead = () => git('ls-remote', '--heads', 'origin', 'main').split(/\s+/)[0];
  let base = push ? remoteHead() : git('rev-parse', 'refs/remotes/origin/main');
  if (!/^[0-9a-f]{40}$/.test(base)) throw new Error('Expected a GitHub main commit');
  if (push && git('rev-parse', 'refs/remotes/origin/main') !== base) git('fetch', '--no-tags', 'origin', 'main');
  if (push && git('rev-parse', 'refs/remotes/origin/main') !== base) throw new Error('GitHub main changed while planning. Run again from the new tip.');
  if (push) git('merge-base', '--is-ancestor', 'HEAD', base);

  function publish(commit, parent) {
    for (let attempt = 1; attempt <= 3; attempt++) {
      let failure;
      try {
        git('-c', 'http.version=HTTP/1.1', '-c', 'http.postBuffer=' + postBuffer, 'push', 'origin', commit + ':refs/heads/main');
      } catch (error) { failure = error; }
      const remote = remoteHead();
      if (remote === commit) {
        console.log(JSON.stringify({ event: 'batch-published', commit }));
        return;
      }
      if (remote !== parent) throw new Error(`GitHub main advanced to ${remote} during upload. Run again from the new tip.`);
      if (attempt === 3 || (failure && !/HTTP (?:408|429|5\d\d)|connection reset|remote end hung up|early EOF/i.test(failure.stderr || failure.message))) {
        throw failure || new Error('GitHub main did not advance after three upload attempts.');
      }
      console.log(JSON.stringify({ event: 'batch-retry', commit, attempt }));
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 4000 * attempt);
    }
  }
  const tracked = new Set(names(git('ls-tree', '-r', '--name-only', '-z', base)));
  const batches = pendingBatches(assets, tracked);
  console.log(JSON.stringify({ event: 'batch-plan', assets: assets.size, batchLimit,
    batches: push ? batches.length : batches.map(batch => ({ files: batch.rows.length, bytes: batch.bytes })),
    bytes: batches.reduce((total, batch) => total + batch.bytes, 0),
  }));
  if (!push) return;

  fs.mkdirSync(scratch, { recursive: true });
  const temporary = fs.mkdtempSync(path.join(scratch, 'acquisition-'));
  const indexFile = path.join(temporary, 'index');
  const indexGit = (args, input) => runGit(args, { input, env: { GIT_INDEX_FILE: indexFile } });
  function commit(paths, label, expectedBlobs = new Map()) {
    indexGit(['read-tree', base]);
    indexGit(['add', '--pathspec-from-file=-', '--pathspec-file-nul'], paths.join('\0') + '\0');
    const actual = names(indexGit(['diff', '--cached', '--name-only', '-z', base]));
    const requested = new Set(paths);
    if (!actual.length) return;
    if (actual.some(name => !requested.has(name))) throw new Error('The batch included an unexpected path');
    if (expectedBlobs.size) {
      const indexed = new Map(names(indexGit(['ls-files', '--stage', '-z', '--', ...namespaces])).map(row => {
        const [metadata, name] = row.split('\t');
        return [name, metadata.split(' ')[1]];
      }));
      for (const [name, blob] of expectedBlobs) if (indexed.get(name) !== blob) {
        throw new Error('Git transformed the acquired file while staging: ' + name);
      }
    }
    const tree = indexGit(['write-tree']);
    const next = git('commit-tree', tree, '-p', base, '-m', commitTitle + ' ' + label);
    publish(next, base);
    base = next;
  }

  try {
    for (const [index, batch] of batches.entries()) {
      const expectedBlobs = new Map(batch.rows.map(([name, actual]) => [name, verifyFile(name, actual)]));
      const paths = batch.rows.map(([name]) => name);
      if (index === 0) paths.push(...attributes);
      console.log(JSON.stringify({ event: 'batch-start', batch: index + 1, total: batches.length, bytes: batch.bytes, files: paths.length }));
      commit(paths, (index + 1) + '/' + batches.length, expectedBlobs);
    }
    if (sha256(fs.readFileSync(file(catalogPath))) !== catalogHash) throw new Error('Acquisition catalog changed during upload. Run again for the newer assets.');
    commit([catalogPath], 'catalog');
    if (remoteHead() !== base) throw new Error('GitHub main advanced before final verification. Run again from the new tip.');
    console.log(JSON.stringify({ event: 'publication-finished', assets: assets.size, commit: base }));
  } finally {
    fs.rmSync(indexFile, { force: true });
    if (fs.readdirSync(temporary).length === 0) fs.rmdirSync(temporary);
  }
}

try { main(); } catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
