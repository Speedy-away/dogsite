/* Existing game marks and official Steam logo assets, shared by preview cards. */
const BRAND_LOGO = '/assets/images/brand/scooby-logo.png';
const logo = (src, alt, white = false) => ({ src, alt, white });
const gameLogos = {
  gta5: [logo('/assets/images/store/gta5-logo-transparent.png', 'Grand Theft Auto V')],
  rdr2: [logo('/assets/images/store/rdr2-logo-transparent.png', 'Red Dead Redemption II')],
  fivem: [logo('/portal/images/product-logos/fivem.png', 'FiveM')],
  redm: [logo('/portal/images/product-logos/redm.png', 'RedM')],
  cs2: [logo('/portal/images/product-logos/cs2.png', 'Counter-Strike 2')],
  gmod: [logo('/assets/images/source-games/gmod-logo.png', 'Garry’s Mod')],
  l4d: [logo('/assets/images/source-games/l4d-logo.png', 'Left 4 Dead')],
  sbox: [logo('/portal/images/reference-logos/sbox.webp', 'S&box')],
  megabonk: [logo('/assets/images/game-logos/megabonk.png', 'Megabonk')],
  'last-of-us': [logo('/assets/images/store/last-of-us-logo.png', 'The Last of Us', true)],
  'half-life-1': [logo('/assets/images/source-games/half-life-logo.webp', 'Half-Life')],
  'half-life-2': [logo('/assets/images/source-games/half-life-2-logo.webp', 'Half-Life 2')],
  'half-life-2-deathmatch': [logo('/assets/images/game-logos/half-life-2-deathmatch.png', 'Half-Life 2: Deathmatch')],
  tf2: [logo('/assets/images/tf2/tf2-logo-transparent-v1.png', 'Team Fortress 2'), logo('/assets/images/tf2/tf2-classified-logo.png', 'TF2 Classified')],
  css: [logo('/assets/images/game-logos/css.png', 'Counter-Strike: Source')],
  portal: [logo('/assets/images/game-logos/portal-1.png', 'Portal'), logo('/assets/images/game-logos/portal-2.png', 'Portal 2')],
  'day-of-defeat-source': [logo('/assets/images/game-logos/day-of-defeat-source.png', 'Day of Defeat: Source')],
  'black-mesa': [logo('/assets/images/game-logos/black-mesa.png', 'Black Mesa')],
  'team-fortress-classic': [logo('/assets/images/source-games/tfc-logo-original.png', 'Team Fortress Classic')],
  'counter-strike': [logo('/assets/images/game-logos/counter-strike.png', 'Counter-Strike')],
  'day-of-defeat': [logo('/assets/images/game-logos/day-of-defeat.png', 'Day of Defeat')],
  bodycam: [logo('/assets/images/bodycam/logo.webp', 'Bodycam')],
  pubg: [logo('/assets/images/game-logos/pubg.png', 'PUBG')],
  r6: [logo('/assets/images/game-logos/r6.png', 'Rainbow Six Siege')],
  spoofer: [logo('/portal/images/product-logos/spoofer.png', 'HWID Spoofer & Cleaner')],
};
const all = Object.keys(gameLogos);
const source = ['cs2','gmod','l4d','sbox','tf2','half-life-1','half-life-2','half-life-2-deathmatch','css','portal','day-of-defeat-source','black-mesa','team-fortress-classic','counter-strike','day-of-defeat'];
const collections = {
  home: all, store: all, free: all, compare: all, directory: all,
  guides: all, docs: all, features: all, videos: all,
  source, 'more-games': ['last-of-us','megabonk'],
};
function logosFor(card) {
  if (card.id.startsWith('game-')) {
    const logos = gameLogos[card.id.slice(5)];
    if (!logos) throw new Error('Missing game logo: ' + card.id);
    return logos;
  }
  return (collections[card.id] || []).flatMap(id => gameLogos[id]);
}
module.exports = { BRAND_LOGO, gameLogos, logosFor };
