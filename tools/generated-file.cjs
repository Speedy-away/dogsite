'use strict';
const fs = require('node:fs');
const path = require('node:path');

// Preserve modification dates when rebuilding identical public content.
function writeIfChanged(file, content) {
  const bytes = Buffer.isBuffer(content) ? content : Buffer.from(content);
  if (fs.existsSync(file) && fs.readFileSync(file).equals(bytes)) return false;
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, bytes);
  return true;
}
module.exports = { writeIfChanged };
