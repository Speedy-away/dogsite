(function () {
  var enumDefs = {};

  function extractEnums(natives) {
    var enumRe = /enum\s+(e[A-Za-z0-9_]+)\s*\{([^}]+)\}/g;
    var valueListRe = /(\d+)\s*[-=:]\s*([^\n,]+)/g;

    for (var ns in natives) {
      if (!Object.prototype.hasOwnProperty.call(natives, ns)) continue;
      var group = natives[ns];
      for (var hash in group) {
        if (!Object.prototype.hasOwnProperty.call(group, hash)) continue;
        var n = group[hash];
        if (!n || !n.description) continue;
        var desc = n.description;

        var match;
        while ((match = enumRe.exec(desc)) !== null) {
          var name = match[1];
          var body = match[2];
          if (!enumDefs[name]) {
            enumDefs[name] = [];
            var vals = body.split(',');
            for (var i = 0; i < vals.length; i++) {
              var v = vals[i].trim();
              if (v) enumDefs[name].push(v);
            }
          }
        }

        var valMatch;
        while ((valMatch = valueListRe.exec(desc)) !== null) {
          var key = valMatch[1];
          var val = valMatch[2].trim();
          if (!enumDefs['_inline_' + hash]) {
            enumDefs['_inline_' + hash] = [];
          }
          enumDefs['_inline_' + hash].push(key + ' = ' + val);
        }
      }
    }
  }

  function injectEnumInfo() {
    var descEl = document.querySelector('.details .desc');
    if (!descEl) return;

    var params = document.querySelector('.details .parameters');
    if (!params) return;

    var existingBox = document.querySelector('.enum-info-box');
    if (existingBox) existingBox.remove();

    var paramText = params.textContent || '';
    var found = [];

    for (var enumName in enumDefs) {
      if (enumName.indexOf('_inline_') === 0) continue;
      if (paramText.indexOf(enumName) !== -1 || descEl.textContent.indexOf(enumName) !== -1) {
        found.push({ name: enumName, values: enumDefs[enumName] });
      }
    }

    if (found.length === 0) return;

    var box = document.createElement('div');
    box.className = 'enum-info-box';
    box.innerHTML = '<strong>Enum Values:</strong>';

    for (var i = 0; i < found.length; i++) {
      var e = found[i];
      var section = document.createElement('div');
      section.innerHTML = '<em>' + e.name + '</em><pre>' + e.values.join('\n') + '</pre>';
      box.appendChild(section);
    }

    descEl.parentNode.insertBefore(box, descEl.nextSibling);
  }

  function init() {
    Promise.resolve(window.__NATIVES__).then(function (natives) {
      extractEnums(natives);
      var observer = new MutationObserver(function () {
        requestAnimationFrame(injectEnumInfo);
      });
      var details = document.querySelector('.details');
      if (details) {
        observer.observe(details, { childList: true, subtree: true });
      } else {
        var app = document.querySelector('.app');
        if (app) {
          var appObs = new MutationObserver(function () {
            var d = document.querySelector('.details');
            if (d) {
              appObs.disconnect();
              observer.observe(d, { childList: true, subtree: true });
              injectEnumInfo();
            }
          });
          appObs.observe(app, { childList: true, subtree: true });
        }
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
