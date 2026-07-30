(function () {
  var TYPES = /\b(const|int|float|BOOL|Hash|Ped|Entity|Vehicle|Object|Cam|Vector3|Any|ScrHandle|Blip|Pickup|Player|FireId|Interior|Group|Texture|TextureDict|CoverPoint|AnimScene|ItemSet|PersChar|PropSet|Prompt|Volume|Train|PopZone|uint|uint64|void|char)(\*?)(?=\s)/g;

  function highlightParams() {
    var spans = document.querySelectorAll('.app > section .entry > a > span');
    spans.forEach(function (span) {
      if (span.dataset.highlighted) return;
      var text = span.textContent;
      if (!text || text.indexOf('(') === -1) return;
      var html = text.replace(TYPES, '<em class="param-type">$1$2</em>');
      if (html !== text) {
        span.innerHTML = html;
        span.dataset.highlighted = '1';
      }
    });
  }

  var observer = new MutationObserver(function () {
    requestAnimationFrame(highlightParams);
  });

  function init() {
    var target = document.querySelector('.app > section');
    if (target) {
      observer.observe(target, { childList: true, subtree: true });
      highlightParams();
    } else {
      setTimeout(init, 100);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
