(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ScoobyEditions = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const labels = Object.freeze({ enhanced: 'Enhanced', legacy: 'Legacy', both: 'Both' });
  const groups = {
    gta5: { label: 'GTA 5 edition', all: 'All editions', options: labels },
    l4d: { label: 'Left 4 Dead game', all: 'All games', options: { l4d1: 'Left 4 Dead', l4d2: 'Left 4 Dead 2' } }
  };
  const group = game => Object.hasOwn(groups, game) ? groups[game] : undefined;
  const choice = (game, value) => Object.hasOwn(group(game)?.options || {}, value) ? value : '';
  function support(entry) {
    if (entry.game !== 'l4d') return choice(entry.game, entry.editionSupport);
    if (entry.edition) return entry.edition === 'both' ? 'both' : choice(entry.game, entry.edition);
    // Scooby ships one translation catalog for both Left 4 Dead games.
    if (entry.category === 'languages' && entry.files?.some(file => file.path?.startsWith('downloads/l4d/languages/'))) return 'both';
    return '';
  }
  function badge(game, edition) {
    if (game === 'l4d') return edition === 'both' ? 'L4D1 & L4D2' : edition.toUpperCase();
    return labels[edition];
  }
  function gameLabel(game, edition) {
    if (game === 'l4d') return edition === 'both' ? 'Left 4 Dead and Left 4 Dead 2' : groups.l4d.options[edition];
    return edition === 'both' ? 'Legacy and Enhanced' : labels[edition];
  }
  const title = (game, edition) => 'Supports ' + (game === 'gta5' ? 'GTA 5 ' : '') + gameLabel(game, edition);
  function matches(entry, filter) {
    if (!filter) return true;
    const verified = support(entry);
    return verified === filter || verified === 'both';
  }
  const withVerification = (entry, catalog) => {
    if (entry.game !== 'gta5' || !Object.hasOwn(catalog.verified || {}, entry.id)) return entry;
    const { editionSupport, editionSource, packageFile } = catalog.verified[entry.id];
    if (!entry.files?.some(file => (file.url || file.path) === packageFile)) return entry;
    return { ...entry, editionSupport, editionSource };
  };
  return { labels, group, choice, support, badge, gameLabel, title, matches, withVerification };
});
