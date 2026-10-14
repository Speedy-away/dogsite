/* Shared product / feature-library comparison. Multiplayer terms supplied by product owner. */
function renderComparison() {
  const rows = [
    ['Can play Freemode with others?', 'Yes, with other modders', 'Yes, only as session host', 'Yes, always'],
    ['Can play missions & heists with others?', 'Yes, with other modders', 'Yes, only as session host', 'Yes, always'],
    ['BattlEye mode', 'Disabled', 'Disabled · session host required', 'Enabled'],
    ['Free features', 'Included', 'Included', 'Included'],
    ['Premium features', 'Not included', 'Included', 'Included'],
    ['Instant heist finishes & business sales', 'Not included', 'Included', 'Included'],
    ['Advanced vehicle flight, tricks & tire lights', 'Not included', 'Included', 'Included'],
    ['Black hole, tornado & alien invasion', 'Not included', 'Included', 'Included'],
    ['Price', '$0 · free key', '$15 · Lifetime access', '$25 · Lifetime access'],
  ];
  return `<section class="gta-editions" id="compare-editions" aria-labelledby="gta-editions-title">
<div class="gta-editions-heading"><div><span class="gta-eyebrow">FIND YOUR EDITION</span><h2 id="gta-editions-title"><span class="gta-tier-free">Free</span>, <span class="gta-tier-premium">Premium</span> or <span class="gta-tier-plus">Plus</span>.</h2></div><p>See what is included, and who you can play with.</p></div>
<p class="gta-table-hint" id="gta-table-hint">Compare Free, Premium and Plus side by side.</p>
<div class="gta-table-scroll" tabindex="0" role="region" aria-label="GTA 5 edition comparison" aria-describedby="gta-table-hint"><div class="gta-comparison-wrap"><div class="gta-plan-outlines" aria-hidden="true"><div></div><div></div><div><span>Recommended</span></div></div><table class="gta-comparison" role="table"><caption class="gta-sr-only">GTA 5 Free, Premium and Plus features and multiplayer access</caption><thead role="rowgroup"><tr role="row"><th role="columnheader" scope="col">Your GTA 5 experience</th><th role="columnheader" scope="col">Free<span>Free key access</span><span class="gta-plan-mode">BattlEye Disabled</span></th><th role="columnheader" scope="col">Premium<span>Lifetime access</span><span class="gta-plan-mode">BattlEye Disabled (Host)</span></th><th role="columnheader" scope="col" class="gta-plus">Plus<span>Lifetime access</span><span class="gta-plan-mode">BattlEye Enabled</span></th></tr></thead><tbody role="rowgroup">${rows.map(row=>`<tr role="row"${row[0]==='Price'?' class="gta-price-row"':''}><th role="rowheader" scope="row">${row[0]}</th>${row.slice(1).map((cell,i)=>`<td role="cell"${i===2?' class="gta-plus"':''}>${row[0]==='Price'?`<strong class="gta-plan-price">${cell.split(' · ')[0]}</strong><span class="gta-plan-term">${cell.split(' · ')[1]}</span>`:cell==='Included'?'<span class="gta-included">Included</span>':cell==='Not included'?'<span class="gta-unavailable">Not included</span>':cell}</td>`).join('')}</tr>`).join('')}</tbody><tfoot role="rowgroup"><tr role="row"><th role="rowheader" scope="row">Explore your plan</th><td role="cell"><a href="/scoobyontop.html">Get a free key</a></td><td role="cell"><a href="/products/gta5/?plan=premium" data-gta-plan="premium">Get Premium</a></td><td role="cell" class="gta-plus"><a href="/products/gta5/?plan=premium-plus" data-gta-plan="premium-plus">Get Plus</a><span class="gta-plus-value">Have Premium?</span><a class="gta-upgrade-link" href="/products/gta5/?plan=upgrade" data-gta-plan="upgrade" aria-label="Upgrade Premium to Plus for $10">Upgrade · $10</a></td></tr></tfoot></table></div></div>
<p class="gta-editions-note">Plus is listed as <strong>Premium Plus</strong> at checkout. It includes the Premium menu and adds BattlEye Enabled multiplayer. Free features are included in every plan; <strong>Premium &amp; Plus</strong> labels identify paid features. Individual controls may depend on Legacy or Enhanced and your current session.</p>
<a class="gta-library-link" href="/features-list/gta-features/#explorer">Browse every feature by plan <span aria-hidden="true">→</span></a>
</section>`;
}
module.exports = {renderComparison};
