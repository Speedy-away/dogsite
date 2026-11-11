'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const { createPlan, runPush, parseArgs } = require('./push-large-assets.cjs');

const root = path.resolve(__dirname, '../..');
const fixtureRoot = path.join(root, 'project/community-menu-sources/cherax-push-test');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const env = {
  ...process.env, GIT_OPTIONAL_LOCKS: '0',
  GIT_AUTHOR_NAME: 'Local fixture', GIT_AUTHOR_EMAIL: 'fixture@localhost',
  GIT_COMMITTER_NAME: 'Local fixture', GIT_COMMITTER_EMAIL: 'fixture@localhost',
};
function git(cwd, args, input) {
  const result = spawnSync('git', args, { cwd, env, windowsHide: true, input, maxBuffer: 16 * 1024 * 1024 });
  if (result.error) throw result.error;
  assert.equal(result.status, 0, `git ${args[0]}: ${result.stderr}`);
  return result.stdout;
}
const text = (cwd, args) => git(cwd, args).toString('utf8').trim();

test('explicit push mode cannot be confused with a read-only plan', () => {
  assert.deepEqual(parseArgs(['--plan', '--repo', '../cool-repo']), { plan: true, repo: '../cool-repo' });
  assert.throws(() => parseArgs(['--plan', '--push']), /Choose/);
  assert.throws(() => parseArgs(['--resume', 'state.json']), /explicit --push/);
});

test('chunk seeding preserves user HEAD/index/worktree, handles historical blobs, resumes, and cleans only its own ref', () => {
  fs.mkdirSync(fixtureRoot, { recursive: true });
  fs.writeFileSync(path.join(fixtureRoot, '.gitignore'), '*\n');
  const run = fs.mkdtempSync(path.join(fixtureRoot, 'run-'));
  const repo = path.join(run, 'work'), bare = path.join(run, 'remote.git'), scratch = path.join(run, 'state');
  fs.mkdirSync(repo);
  git(run, ['init', '--bare', '--initial-branch=main', bare]);
  git(repo, ['init', '--initial-branch=main']);
  git(repo, ['remote', 'add', 'origin', bare]);
  fs.writeFileSync(path.join(repo, 'base.txt'), 'base\n');
  git(repo, ['add', 'base.txt']); git(repo, ['commit', '-m', 'base']);
  git(repo, ['push', '-u', 'origin', 'main']);
  const baseline = text(repo, ['rev-parse', 'main']);
  git(repo, ['push', 'origin', `${baseline}:refs/heads/codex/asset-upload-protected`]);
  const duplicate = crypto.randomBytes(24 * 1024);
  fs.writeFileSync(path.join(repo, 'one.bin'), duplicate);
  fs.writeFileSync(path.join(repo, 'duplicate.bin'), duplicate);
  fs.writeFileSync(path.join(repo, 'two.bin'), crypto.randomBytes(24 * 1024));
  fs.writeFileSync(path.join(repo, 'history-only.bin'), crypto.randomBytes(25 * 1024));
  git(repo, ['add', '.']); git(repo, ['commit', '-m', 'assets version one']);
  const historyOnlyBlob = text(repo, ['rev-parse', 'HEAD:history-only.bin']);
  fs.unlinkSync(path.join(repo, 'history-only.bin'));
  fs.writeFileSync(path.join(repo, 'one.bin'), crypto.randomBytes(26 * 1024));
  fs.writeFileSync(path.join(repo, 'three.bin'), crypto.randomBytes(27 * 1024));
  git(repo, ['add', '-A']); git(repo, ['commit', '-m', 'assets final']);
  const target = text(repo, ['rev-parse', 'main']);
  // Deliberately retain staged, unstaged and untracked state throughout upload.
  fs.writeFileSync(path.join(repo, 'base.txt'), 'staged local edit\n'); git(repo, ['add', 'base.txt']);
  fs.writeFileSync(path.join(repo, 'base.txt'), 'unstaged local edit\n');
  fs.writeFileSync(path.join(repo, 'untracked.txt'), 'leave this alone\n');
  const indexPath = path.join(repo, '.git/index');
  const before = {
    head: text(repo, ['rev-parse', 'HEAD']), branch: text(repo, ['symbolic-ref', 'HEAD']),
    index: hash(fs.readFileSync(indexPath)), status: text(repo, ['status', '--porcelain=v1', '--untracked-files=all']),
    base: fs.readFileSync(path.join(repo, 'base.txt'), 'utf8'), untracked: fs.readFileSync(path.join(repo, 'untracked.txt'), 'utf8'),
  };
  const beforeObjectCount = text(repo, ['count-objects', '-v']);
  const beforeRefs = text(repo, ['show-ref']);
  const plan = createPlan({ repo, chunkBytes: 50 * 1024 });
  assert.equal(text(repo, ['count-objects', '-v']), beforeObjectCount, 'read-only planning wrote Git objects');
  assert.equal(text(repo, ['show-ref']), beforeRefs, 'read-only planning changed refs');
  assert.equal(hash(fs.readFileSync(indexPath)), before.index, 'read-only planning refreshed/changed user index');
  assert.equal(plan.targetOid, target); assert.equal(plan.baselineOid, baseline);
  assert.equal(plan.unpublishedCommits, 2);
  assert(plan.chunks.length >= 3);
  assert(plan.chunks.every(chunk => chunk.bytes <= 50 * 1024));
  assert(plan.historicalOnlyBlobs >= 1);
  assert(plan.chunks.flatMap(chunk => chunk.objects).some(object => object.oid === historyOnlyBlob), 'deleted ancestor blob omitted');
  assert.equal(new Set(plan.chunks.flatMap(chunk => chunk.objects).map(object => object.oid)).size, plan.pendingBlobs);
  assert.throws(() => createPlan({ repo, chunkBytes: 1 }), /exceeds/);
  let stateFile;
  assert.throws(() => runPush(plan, {
    scratch,
    log(event) {
      if (event.stateFile) stateFile = event.stateFile;
      if (event.event === 'seed-push-complete' && event.chunk === 1) throw new Error('Simulated interruption after first seeded chunk');
    },
  }), /Simulated interruption/);
  assert(stateFile);
  const interrupted = JSON.parse(fs.readFileSync(stateFile));
  assert.equal(interrupted.completedChunks, 1);
  assert.equal(text(bare, ['rev-parse', 'refs/heads/main']), baseline, 'main published before all chunks seeded');
  assert.equal(text(bare, ['rev-parse', interrupted.tempRef]), interrupted.seedHead);
  assert.equal(hash(fs.readFileSync(indexPath)), before.index);
  const events = [];
  const result = runPush(plan, { resume: stateFile, log: event => events.push(event) });
  assert.equal(result.completedChunks, plan.chunks.length);
  assert.equal(text(bare, ['rev-parse', 'refs/heads/main']), target);
  assert.equal(text(bare, ['rev-parse', 'refs/heads/codex/asset-upload-protected']), baseline, 'unrelated remote ref changed');
  assert.deepEqual(text(bare, ['for-each-ref', '--format=%(refname)', 'refs/heads/codex/']).split(/\r?\n/).filter(Boolean), ['refs/heads/codex/asset-upload-protected'], 'task seed ref not cleaned or protected ref changed');
  for (const object of plan.chunks.flatMap(chunk => chunk.objects)) git(bare, ['cat-file', '-e', `${object.oid}^{blob}`]);
  const after = {
    head: text(repo, ['rev-parse', 'HEAD']), branch: text(repo, ['symbolic-ref', 'HEAD']),
    index: hash(fs.readFileSync(indexPath)), status: text(repo, ['status', '--porcelain=v1', '--untracked-files=all']),
    base: fs.readFileSync(path.join(repo, 'base.txt'), 'utf8'), untracked: fs.readFileSync(path.join(repo, 'untracked.txt'), 'utf8'),
  };
  assert.deepEqual(after, before, 'upload altered user HEAD, index or working tree');
  assert.equal(text(bare, ['rev-list', '--count', 'main']), '3', 'seed commits leaked into main history');
  const state = JSON.parse(fs.readFileSync(stateFile));
  assert(state.mainPublished && state.cleaned);
  let seed = state.seedHead;
  for (let i = plan.chunks.length - 1; i >= 0; i--) {
    const raw = text(repo, ['cat-file', '-p', seed]);
    const tree = raw.match(/^tree ([0-9a-f]+)$/m)[1];
    const blobIds = git(repo, ['ls-tree', '-r', '--format=%(objectname)', tree]).toString('utf8').trim().split(/\r?\n/).filter(Boolean);
    assert.deepEqual([...blobIds].sort(), plan.chunks[i].objects.map(object => object.oid).sort(), 'seed tree has blobs outside its bounded chunk');
    seed = raw.match(/^parent ([0-9a-f]+)$/m)[1];
  }
  assert.equal(seed, baseline, 'seed commit chain did not start at original remote main');
  git(root, ['check-ignore', '--quiet', path.relative(root, path.join(run, 'work/base.txt')).replace(/\\/g, '/')]);
  const summary = {
    testedAt: new Date().toISOString(), fixture: run, remoteKind: 'local-bare-only', realRemoteWrites: 0,
    assertions: ['read-only plan writes no refs/objects/index', 'all pending blobs include deleted unpublished ancestor data', 'bounded subset trees and chained parents', 'dirty HEAD/index/worktree preserved byte-for-byte', 'interrupted seed upload resumes', 'main uses exact original target/history', 'only task-created temporary ref is removed', 'all blob objects arrive at bare remote', 'fixture is ignored by parent repository'],
    chunks: plan.chunks.length, pendingBlobs: plan.pendingBlobs, pendingBlobBytes: plan.pendingBlobBytes,
    mainTarget: target, stateFile, result: 'passed',
  };
  fs.writeFileSync(path.join(root, 'project/community-menu-sources/cherax-push-test-results.json'), JSON.stringify(summary, null, 2) + '\n');
});
