'use strict';

function recordResourceAdditions(catalog, previous = {}) {
  const known = new Map((previous.items || []).map(item => [item.id, item]));
  const addedAt = new Date().toISOString();
  for (const item of catalog.items) {
    const prior = known.get(item.id);
    if (prior?.addedAt) item.addedAt = prior.addedAt;
    else if (!prior) item.addedAt ??= addedAt;
  }
}

module.exports = { recordResourceAdditions };
