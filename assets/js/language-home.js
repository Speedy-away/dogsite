/* A language chosen through its URL carries over to the existing page translator. */
(function () {
  'use strict';
  function save(language) {
    try { localStorage.setItem('scooby.lang', language); } catch (error) { /* Storage is optional. */ }
  }
  var language = document.documentElement.getAttribute('data-site-language');
  if (language) save(language);
  document.addEventListener('click', function (event) {
    var link = event.target.closest && event.target.closest('a[data-site-language]');
    if (link && event.button === 0 && !event.ctrlKey && !event.metaKey && !event.shiftKey && !event.altKey) save(link.getAttribute('data-site-language'));
  });
})();
