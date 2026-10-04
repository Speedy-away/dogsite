/* Bind dynamic account values without treating them as HTML or translation keys. */
(function () {
  'use strict';
  var bindings = new WeakMap();
  var i18n = window.__scoobyI18n;
  function render(element, binding) {
    element.textContent = i18n.t(binding.key, typeof binding.params === 'function' ? binding.params() : binding.params);
  }
  window.portalText = function (element, key, params) {
    var binding = { key: key, params: params };
    element.setAttribute('data-i18n-skip', '');
    element.setAttribute('data-portal-i18n', '');
    bindings.set(element, binding);
    render(element, binding);
  };
  window.portalDuration = function (seconds) {
    var unit = seconds >= 86400 ? 'day' : seconds >= 3600 ? 'hour' : seconds >= 60 ? 'minute' : 'second';
    var divisor = { day: 86400, hour: 3600, minute: 60, second: 1 }[unit];
    return new Intl.NumberFormat(i18n.get(), { style: 'unit', unit: unit, unitDisplay: 'short' }).format(Math.ceil(seconds / divisor));
  };
  window.addEventListener('scooby:langchange', function () {
    document.querySelectorAll('[data-portal-i18n]').forEach(function (element) {
      var binding = bindings.get(element);
      if (binding) render(element, binding);
    });
  });
})();
