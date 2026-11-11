'use strict';

const categoryPanel = document.querySelector('.guide-categories details');
if (categoryPanel) {
  const compact = matchMedia('(max-width: 900px)');
  categoryPanel.open = !compact.matches;
  compact.addEventListener('change', event => { categoryPanel.open = !event.matches; });
}
