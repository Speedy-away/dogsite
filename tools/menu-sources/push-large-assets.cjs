'use strict';

// Seed large asset blobs on a task-owned temporary remote branch, then publish
// the existing target commit with a normal fast-forward push. Never checks out,
// stages, resets, amends or force-pushes the user's branch. --plan is read-only.
//
// node tools/menu-sources/push-large-assets.cjs --plan --repo ../cool-repo
// node tools/menu-sources/push-large-assets.cjs --push --repo ../cool-repo
// node tools/menu-sources/push-large-assets.cjs --push --resume <state.json>
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');

const ROOT = path.resolve(__dirname, '../..');
const MIB = 1024 * 1024;
const DEFAULT_CHUNK_BYTES = 650 * MIB;
const MAX_BLOB_BYTES = 100 * MIB;
const sha256 = value => crypto.createHash('sha256').update(value).digest('hex');
const within = (root, candidate) => {
  const relative = path.relative(root, candidate);
  return relative === '' || (!relative.startsWith('..' + path.sep) && relative !== '..' && !path.isAbsolute(relative));
};

function git(repo, args, options = {}) {
  // Only trust the explicit repository for this one command. Do not modify the
  // user's global safe.directory settings when running inside Codex's sandbox.
  const result = spawnSync('git', ['-c', `safe.directory=${repo.replace(/\\/g, '/')}`, ...args], {
    cwd: repo, windowsHide: true, maxBuffer: 128 * MIB,
    env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', ...options.env },
    input: options.input, encoding: options.binary ? undefined : 'utf8',
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && !options.allowFailure) {
    throw new Error(`git ${args[0]} failed (${result.status}): ${String(result.stderr || '').trim()}`);
  }
  return options.allowFailure ? result : result.stdout;
}

function validateNames(remote, branch) {
  if (!/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(remote)) throw new Error('Use a configured remote name, such as origin.');
  if (!/^[a-zA-Z0-9][a-zA-Z0-9._/-]*$/.test(branch) || branch.includes('..') || branch.endsWith('/')) throw new Error('Invalid target branch name.');
}

function createPlan(options = {}) {
  const repo = fs.realpathSync(path.resolve(options.repo || path.join(ROOT, '../cool-repo')));
  const remote = options.remote || 'origin', branch = options.branch || 'main';
  validateNames(remote, branch);
  git(repo, ['check-ref-format', `refs/heads/${branch}`]);
  const targetRef = `refs/heads/${branch}`, baselineRef = `refs/remotes/${remote}/${branch}`;
  const targetOid = git(repo, ['rev-parse', '--verify', targetRef]).trim();
  const baselineOid = git(repo, ['rev-parse', '--verify', baselineRef]).trim();
  if (git(repo, ['merge-base', '--is-ancestor', baselineOid, targetOid], { allowFailure: true }).status !== 0) {
    throw new Error('The cached remote branch is not an ancestor of the target. Resolve/fetch the branch before planning; this helper never force-pushes.');
  }
  const chunkBytes = options.chunkBytes ?? DEFAULT_CHUNK_BYTES;
  if (!Number.isSafeInteger(chunkBytes) || chunkBytes <= 0 || chunkBytes > DEFAULT_CHUNK_BYTES) throw new Error('Chunk size must be between 1 byte and 650 MiB.');
  const objectIds = git(repo, ['rev-list', '--objects', '--no-object-names', targetOid, '--not', baselineOid]).trim().split(/\r?\n/).filter(Boolean);
  const objectOutput = objectIds.length ? git(repo, ['cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)'], { input: objectIds.join('\n') + '\n' }) : '';
  const objects = objectOutput.trim().split(/\r?\n/).filter(Boolean).map(line => {
    const match = line.match(/^([0-9a-f]+) (blob|tree|commit|tag) (\d+)$/);
    if (!match) throw new Error('Unexpected pending-object metadata.');
    return { oid: match[1], type: match[2], bytes: Number(match[3]) };
  });
  const headPaths = new Map();
  const headEntries = git(repo, ['ls-tree', '-r', '-z', '--long', targetOid], { binary: true }).toString('utf8').split('\0').filter(Boolean);
  for (const entry of headEntries) {
    const match = entry.match(/^\d+ blob ([0-9a-f]+)\s+\d+\t([\s\S]+)$/);
    if (match && !headPaths.has(match[1])) headPaths.set(match[1], match[2]);
  }
  const blobs = objects.filter(object => object.type === 'blob').sort((a, b) => b.bytes - a.bytes || a.oid.localeCompare(b.oid));
  const groups = [];
  for (const blob of blobs) {
    if (blob.bytes > chunkBytes) throw new Error(`A pending blob (${blob.bytes} bytes) exceeds the chosen chunk size: ${headPaths.get(blob.oid) || blob.oid}`);
    let group = groups.find(candidate => candidate.bytes + blob.bytes <= chunkBytes);
    if (!group) groups.push(group = { index: groups.length + 1, bytes: 0, objects: [] });
    group.objects.push(blob); group.bytes += blob.bytes;
  }
  const metadataBytes = objects.filter(object => object.type !== 'blob').reduce((total, object) => total + object.bytes, 0);
  const oversizedBlobs = blobs.filter(blob => blob.bytes >= MAX_BLOB_BYTES).map(blob => ({ ...blob, path: headPaths.get(blob.oid) || null }));
  const dirtyOutput = git(repo, ['status', '--porcelain=v1', '--untracked-files=all']);
  const plan = {
    schemaVersion: 1, repo, remote, branch, targetRef, baselineRef, targetOid, baselineOid,
    currentHead: git(repo, ['rev-parse', 'HEAD']).trim(),
    currentBranch: git(repo, ['symbolic-ref', '--quiet', '--short', 'HEAD'], { allowFailure: true }).stdout.trim() || null,
    unpublishedCommits: Number(git(repo, ['rev-list', '--count', `${baselineOid}..${targetOid}`]).trim()),
    dirtyStatusRecords: dirtyOutput.trim() ? dirtyOutput.trim().split(/\r?\n/).length : 0,
    chunkBytes, pendingObjects: objects.length, pendingBlobs: blobs.length,
    pendingBlobBytes: blobs.reduce((total, object) => total + object.bytes, 0),
    remainingMetadataObjects: objects.length - blobs.length, remainingMetadataBytes: metadataBytes,
    historicalOnlyBlobs: blobs.filter(blob => !headPaths.has(blob.oid)).length,
    trackedHeadEntries: headEntries.length, oversizedBlobs,
    chunks: groups.map(group => ({
      ...group, largest: group.objects.slice(0, 3).map(object => ({ ...object, path: headPaths.get(object.oid) || '[unpublished-history-only blob]' })),
    })),
    safety: {
      planNetworkRequests: 0, planWrites: 0, altersUserHead: false, altersUserIndex: false,
      rewritesHistory: false, forcePush: false,
      note: 'All pending history blobs are seeded, including blobs changed/deleted before the target HEAD. Main is pushed from the original target commit; seed commits are not its ancestors.',
    },
  };
  plan.planHash = sha256(JSON.stringify({ repo, remote, branch, targetOid, baselineOid, chunkBytes, chunks: groups.map(group => group.objects.map(object => object.oid)) }));
  return plan;
}

function planSummary(plan) {
  return { ...plan, chunks: plan.chunks.map(({ objects, ...chunk }) => ({ ...chunk, blobCount: objects.length })) };
}

function remoteHeads(plan, refs) {
  const result = git(plan.repo, ['ls-remote', '--heads', plan.remote, ...refs]);
  return new Map(result.trim().split(/\r?\n/).filter(Boolean).map(line => {
    const [oid, ref] = line.split(/\s+/);
    return [ref, oid];
  }));
}

function saveState(state, stateFile) {
  fs.writeFileSync(stateFile, JSON.stringify(state, null, 2) + '\n');
}

function assertLocalTarget(plan) {
  if (git(plan.repo, ['rev-parse', '--verify', plan.targetRef]).trim() !== plan.targetOid) {
    throw new Error('The local target branch changed after planning. No new target history will be published; the task-owned seed branch is retained for inspection.');
  }
}

function createBridge(plan, seedHead) {
  const seedCommits = git(plan.repo, ['rev-list', '--first-parent', seedHead, '--not', plan.baselineOid]).trim().split(/\r?\n/);
  if (seedCommits.length !== plan.chunks.length || seedCommits[0] !== seedHead) throw new Error('Seed history does not match the completed upload chunks.');
  // Making each seed commit an immediate parent exposes its tree to thin-pack
  // edge traversal. Older seed trees alone are otherwise missed by send-pack.
  const parents = [seedHead, plan.targetOid, ...seedCommits.slice(1)].flatMap(oid => ['-p', oid]);
  const env = {
    GIT_AUTHOR_NAME: 'Codex Asset Upload', GIT_AUTHOR_EMAIL: 'codex-asset-upload@localhost',
    GIT_COMMITTER_NAME: 'Codex Asset Upload', GIT_COMMITTER_EMAIL: 'codex-asset-upload@localhost',
  };
  const bridge = git(plan.repo, ['commit-tree', `${plan.targetOid}^{tree}`, ...parents, '-m', 'Temporary bridge for the asset upload'], { env }).trim();
  const objects = git(plan.repo, ['rev-list', '--objects-edge', '--no-object-names', bridge, '--not', seedHead, plan.baselineOid])
    .trim().split(/\r?\n/).filter(oid => oid && !oid.startsWith('-'));
  const metadata = git(plan.repo, ['cat-file', '--batch-check=%(objecttype) %(objectsize)'], { input: objects.join('\n') + '\n' }).trim().split(/\r?\n/);
  if (metadata.length !== objects.length || metadata.some(row => !/^(commit|tree) \d+$/.test(row))) throw new Error('The bridge would resend asset blobs.');
  const bytes = metadata.reduce((total, row) => total + Number(row.split(' ')[1]), 0);
  if (bytes > DEFAULT_CHUNK_BYTES) throw new Error('Bridge metadata exceeds the upload limit.');
  return { oid: bridge, objects: objects.length, bytes };
}

function runPush(plan, options = {}) {
  const log = options.log || (event => console.log(JSON.stringify(event)));
  if (plan.oversizedBlobs.length) throw new Error('Pending files reach/exceed 100 MiB. Split/package those assets before using the GitHub asset upload helper.');
  if (plan.remainingMetadataBytes > DEFAULT_CHUNK_BYTES) throw new Error('Unseeded commit/tree metadata exceeds 650 MiB; this plan needs a different metadata-seeding strategy.');
  let state, stateFile;
  if (options.resume) {
    stateFile = fs.realpathSync(path.resolve(options.resume));
    state = JSON.parse(fs.readFileSync(stateFile));
    if (state.schemaVersion !== 1 || state.plan.planHash !== plan.planHash || !state.remoteAbsentAtStart ||
      !/^refs\/heads\/codex\/asset-upload-[0-9a-f]{12}-[0-9a-f]{16}$/.test(state.tempRef)) throw new Error('Invalid task-owned upload state.');
    const indexFile = path.resolve(state.indexFile);
    const gitDir = git(plan.repo, ['rev-parse', '--absolute-git-dir']).trim();
    if (indexFile !== path.join(path.dirname(stateFile), 'temporary-index') || within(plan.repo, indexFile) || within(gitDir, indexFile) ||
      (fs.existsSync(indexFile) && fs.lstatSync(indexFile).isSymbolicLink())) throw new Error('Saved temporary index is not safely isolated from the target repository.');
  } else {
    const scratch = path.resolve(options.scratch || path.join(ROOT, 'project/community-menu-sources/cherax-push-state'));
    const gitDir = git(plan.repo, ['rev-parse', '--absolute-git-dir']).trim();
    if (within(plan.repo, scratch) || within(gitDir, scratch)) throw new Error('The temporary index/state directory must be outside the target repository.');
    const token = `${plan.targetOid.slice(0, 12)}-${crypto.randomBytes(8).toString('hex')}`;
    const directory = path.join(scratch, token);
    const tempRef = `refs/heads/codex/asset-upload-${token}`;
    const heads = remoteHeads(plan, [plan.targetRef, tempRef]);
    if (heads.get(plan.targetRef) !== plan.baselineOid && heads.get(plan.targetRef) !== plan.targetOid) throw new Error('Remote main changed since the cached tracking ref. Fetch and re-plan; no remote refs were written.');
    if (heads.has(tempRef)) throw new Error('The unique temporary remote ref already exists; it will not be reused or deleted.');
    fs.mkdirSync(directory, { recursive: true });
    const ignoreFile = path.join(scratch, '.gitignore');
    if (!fs.existsSync(ignoreFile)) fs.writeFileSync(ignoreFile, '*\n');
    stateFile = path.join(directory, 'state.json');
    state = {
      schemaVersion: 1, plan, tempRef, remoteAbsentAtStart: true,
      createdAt: new Date().toISOString(), completedChunks: 0, seedHead: plan.baselineOid,
      pendingSeed: null, ownsTempRef: false, mainPublished: false, cleaned: false,
      indexFile: path.join(directory, 'temporary-index'),
    };
    saveState(state, stateFile);
  }
  log({ event: 'upload-state', stateFile, temporaryRef: state.tempRef, chunks: plan.chunks.length, targetOid: plan.targetOid });
  try {
    assertLocalTarget(plan);
    let heads = remoteHeads(plan, [plan.targetRef, state.tempRef]);
    let remoteSeed = heads.get(state.tempRef);
    if (state.pendingSeed && remoteSeed === state.pendingSeed.oid) {
      state.seedHead = state.pendingSeed.oid;
      state.completedChunks = state.pendingSeed.index;
      state.pendingSeed = null; state.ownsTempRef = true; saveState(state, stateFile);
    }
    if (state.pendingBridge && remoteSeed === state.pendingBridge.oid) {
      state.bridgeHead = state.pendingBridge.oid; state.pendingBridge = null; saveState(state, stateFile);
    }
    const expectedTempHead = () => state.bridgeHead || state.seedHead;
    if (remoteSeed && (!state.ownsTempRef || remoteSeed !== expectedTempHead())) throw new Error('Temporary ref ownership/tip does not match this task. No ref will be deleted.');
    if (!remoteSeed && state.completedChunks && !state.cleaned) throw new Error('A previously seeded temporary ref disappeared; inspect the saved state before retrying.');
    if (heads.get(plan.targetRef) !== plan.baselineOid && heads.get(plan.targetRef) !== plan.targetOid) throw new Error('Remote main advanced. No history will be overwritten; fetch and re-plan.');
    if (heads.get(plan.targetRef) !== plan.targetOid) {
      for (const chunk of plan.chunks.slice(state.completedChunks)) {
        assertLocalTarget(plan);
        const env = {
          GIT_INDEX_FILE: state.indexFile,
          GIT_AUTHOR_NAME: 'Codex Asset Upload', GIT_AUTHOR_EMAIL: 'codex-asset-upload@localhost',
          GIT_COMMITTER_NAME: 'Codex Asset Upload', GIT_COMMITTER_EMAIL: 'codex-asset-upload@localhost',
        };
        git(plan.repo, ['read-tree', '--empty'], { env });
        const indexInfo = chunk.objects.map(object => `100644 ${object.oid}\tobjects/${object.oid}\0`).join('');
        git(plan.repo, ['update-index', '-z', '--index-info'], { env, input: indexInfo });
        const tree = git(plan.repo, ['write-tree'], { env }).trim();
        const seed = git(plan.repo, ['commit-tree', tree, '-p', state.seedHead, '-m', `Temporary asset upload ${plan.planHash.slice(0, 16)} chunk ${chunk.index}/${plan.chunks.length}`], { env }).trim();
        state.pendingSeed = { index: chunk.index, oid: seed }; saveState(state, stateFile);
        log({ event: 'seed-push-start', chunk: chunk.index, chunks: plan.chunks.length, blobCount: chunk.objects.length, rawBlobBytes: chunk.bytes, commit: seed });
        git(plan.repo, ['push', plan.remote, `${seed}:${state.tempRef}`]);
        state.seedHead = seed; state.completedChunks = chunk.index;
        state.pendingSeed = null; state.ownsTempRef = true; saveState(state, stateFile);
        log({ event: 'seed-push-complete', chunk: chunk.index });
      }
      assertLocalTarget(plan);
      heads = remoteHeads(plan, [plan.targetRef, state.tempRef]);
      if (heads.get(plan.targetRef) !== plan.baselineOid && heads.get(plan.targetRef) !== plan.targetOid) throw new Error('Remote main advanced during seeding. Final push withheld; no history was overwritten.');
      if (state.ownsTempRef && heads.get(state.tempRef) !== expectedTempHead()) throw new Error('Task seed branch changed during upload. Final push withheld.');
      if (heads.get(plan.targetRef) !== plan.targetOid) {
        if (state.ownsTempRef && !state.bridgeHead) {
          const bridge = state.pendingBridge || createBridge(plan, state.seedHead);
          state.pendingBridge = bridge; saveState(state, stateFile);
          log({ event: 'bridge-push-start', ...bridge });
          git(plan.repo, ['push', plan.remote, `${bridge.oid}:${state.tempRef}`]);
          if (remoteHeads(plan, [state.tempRef]).get(state.tempRef) !== bridge.oid) throw new Error('GitHub did not advertise the pushed bridge.');
          state.bridgeHead = bridge.oid; state.pendingBridge = null; saveState(state, stateFile);
        }
        assertLocalTarget(plan);
        log({ event: 'main-push-start', targetOid: plan.targetOid, ref: plan.targetRef });
        git(plan.repo, ['push', plan.remote, `${plan.targetOid}:${plan.targetRef}`]);
      }
    }
    heads = remoteHeads(plan, [plan.targetRef, state.tempRef]);
    if (heads.get(plan.targetRef) !== plan.targetOid) throw new Error('Final remote main verification did not match the planned commit. Temporary ref retained.');
    state.mainPublished = true; saveState(state, stateFile);
    log({ event: 'main-push-complete', targetOid: plan.targetOid });
    if (state.ownsTempRef && heads.has(state.tempRef)) {
      if (!state.remoteAbsentAtStart || heads.get(state.tempRef) !== expectedTempHead()) throw new Error('Temporary ref changed. Main succeeded; cleanup withheld to protect unrelated work.');
      git(plan.repo, ['push', plan.remote, `:${state.tempRef}`]);
      if (remoteHeads(plan, [state.tempRef]).has(state.tempRef)) throw new Error('Task temporary ref is still advertised after cleanup.');
    }
    state.cleaned = true; state.finishedAt = new Date().toISOString(); saveState(state, stateFile);
    log({ event: 'upload-complete', stateFile, targetOid: plan.targetOid, seedChunks: state.completedChunks, temporaryRefDeleted: state.ownsTempRef });
    return { stateFile, targetOid: plan.targetOid, temporaryRef: state.tempRef, completedChunks: state.completedChunks, cleaned: true };
  } catch (error) {
    state.lastError = { message: error.message, at: new Date().toISOString() };
    saveState(state, stateFile);
    log({ event: 'upload-stopped', stateFile, temporaryRef: state.tempRef, message: error.message, resume: `node tools/menu-sources/push-large-assets.cjs --push --resume "${stateFile}"` });
    throw error;
  }
}

function parseArgs(args) {
  const options = {};
  const values = new Set(['--repo', '--remote', '--branch', '--chunk-mib', '--scratch', '--resume']);
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--push') options.push = true;
    else if (arg === '--plan') options.plan = true;
    else if (arg === '--help') options.help = true;
    else if (values.has(arg)) {
      const value = args[++i];
      if (!value || value.startsWith('--')) throw new Error(`Missing value for ${arg}`);
      if (arg === '--chunk-mib') options.chunkBytes = Number(value) * MIB;
      else options[arg.slice(2)] = value;
    } else throw new Error(`Unknown argument: ${arg}`);
  }
  if (options.plan && options.push) throw new Error('Choose --plan or --push.');
  if (options.resume && !options.push) throw new Error('--resume requires explicit --push.');
  return options;
}

if (require.main === module) {
  try {
    const options = parseArgs(process.argv.slice(2));
    if (options.help) {
      console.log('Read-only: --plan [--repo <path>] [--remote origin] [--branch main] [--chunk-mib 650]\nPublish existing commits: --push [same options] [--scratch <outside-target-path>]\nResume this task only: --push --resume <state.json>\nNo checkout, staging, history rewrite, force push or global configuration changes.');
    } else {
      const plan = options.resume ? JSON.parse(fs.readFileSync(path.resolve(options.resume))).plan : createPlan(options);
      if (options.push) runPush(plan, options);
      else console.log(JSON.stringify(planSummary(plan), null, 2));
    }
  } catch (error) {
    console.error(error.message); process.exitCode = 1;
  }
}

module.exports = { createPlan, planSummary, runPush, parseArgs };
