'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { writeIfChanged } = require('./generated-file.cjs');

test('unchanged generation preserves the last content modification date used by sitemaps', t => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'scooby-seo-date-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const file = path.join(directory, 'page.html');
  writeIfChanged(file, '<h1>Download</h1>');
  const date = new Date('2026-01-01T12:00:00Z');
  fs.utimesSync(file, date, date);
  assert.equal(writeIfChanged(file, '<h1>Download</h1>'), false);
  assert.equal(fs.statSync(file).mtime.getTime(), date.getTime());
  assert.equal(writeIfChanged(file, '<h1>New download</h1>'), true);
  assert.notEqual(fs.statSync(file).mtime.getTime(), date.getTime());
  assert.equal(fs.readFileSync(file, 'utf8'), '<h1>New download</h1>');
});
