(function () {
  var REMOTE_URL = 'https://raw.githubusercontent.com/VORPCORE/RDR3natives/main/rdr3natives.json';
  var TIMEOUT_MS = 10000;

  var TYPE_ALT = 'int|BOOL|float|char\\*|Hash\\*?|Ped\\*?|Entity\\*?|Vehicle\\*?|Object\\*?|Cam|Vector3\\*?|Any\\*?|ScrHandle|Blip|Pickup|Player|FireId|Interior|Group|Texture|TextureDict|CoverPoint|uint|void';
  var ARG = '(?:' + TYPE_ALT + ')\\s+[A-Za-z_][A-Za-z0-9_]*';
  var ARG_LIST_RE = new RegExp('(^|[^`\\w(])(' + ARG + '(?:\\s*,\\s*' + ARG + ')+)(?![\\w)])', 'g');

  function enhanceDescription(desc) {
    if (!desc || typeof desc !== 'string') return desc;
    if (desc.indexOf('```') !== -1) return desc;
    var out = desc;

    out = out.replace(
      /(^|[^`\w])([A-Za-z_][\w-]*\.(?:meta|xml|ymt|ymap|ytyp|ycd|rpf))\b/g,
      function (_m, pre, file) { return pre + '`' + file + '`'; }
    );

    out = out.replace(ARG_LIST_RE, function (_m, pre, args) {
      return pre + '`' + args.trim() + '`';
    });

    out = out.replace(
      /(^|[^`])(<\?xml[\s\S]*?<\/[A-Za-z][\w:-]*>)/g,
      function (_m, pre, block) { return pre + '\n\n```xml\n' + block.trim() + '\n```\n\n'; }
    );

    out = out.replace(
      /(^|[^`])((?:enum|struct|class|union)\s+[A-Za-z_][A-Za-z0-9_]*\s*\{[^{}]*\}\s*;?)/g,
      function (_m, pre, block) { return pre + '\n\n```cpp\n' + block.trim() + '\n```\n\n'; }
    );

    return out;
  }

  function enhanceAll(data) {
    if (!data) return data;
    for (var ns in data) {
      if (!Object.prototype.hasOwnProperty.call(data, ns)) continue;
      var natives = data[ns];
      if (!natives) continue;
      for (var hash in natives) {
        if (!Object.prototype.hasOwnProperty.call(natives, hash)) continue;
        var n = natives[hash];
        if (n && typeof n.description === 'string') {
          n.description = enhanceDescription(n.description);
        }
      }
    }
    return data;
  }

  var fallback = enhanceAll(window.__NATIVES__ || {});

  function transform(data) {
    var out = {};
    for (var ns in data) {
      if (!Object.prototype.hasOwnProperty.call(data, ns)) continue;
      var natives = data[ns];
      var outNs = {};
      for (var hash in natives) {
        if (!Object.prototype.hasOwnProperty.call(natives, hash)) continue;
        var n = natives[hash] || {};
        var mapped = {
          name: n.name,
          params: n.params || [],
          results: n.return_type !== undefined ? n.return_type : n.results,
          description: n.comment !== undefined ? n.comment : n.description,
          examples: n.examples || [],
          hash: hash,
          ns: ns,
          apiset: n.apiset || '',
          build: n.build || ''
        };
        if (n.aliases) mapped.aliases = n.aliases;
        for (var k in n) {
          if (!Object.prototype.hasOwnProperty.call(n, k)) continue;
          if (k === 'return_type' || k === 'comment' || k === 'game') continue;
          if (!(k in mapped)) mapped[k] = n[k];
        }
        outNs[hash] = mapped;
      }
      out[ns] = outNs;
    }
    return out;
  }

  function fetchRemote() {
    return new Promise(function (resolve, reject) {
      if (typeof fetch !== 'function') {
        reject(new Error('fetch unavailable'));
        return;
      }
      var timer = setTimeout(function () { reject(new Error('timeout')); }, TIMEOUT_MS);
      fetch(REMOTE_URL, { cache: 'no-cache' })
        .then(function (r) {
          if (!r.ok) throw new Error('HTTP ' + r.status);
          return r.json();
        })
        .then(function (data) {
          clearTimeout(timer);
          resolve(data);
        })
        .catch(function (err) {
          clearTimeout(timer);
          reject(err);
        });
    });
  }

  var promise = fetchRemote()
    .then(function (data) {
      var transformed = enhanceAll(transform(data));
      var nsCount = Object.keys(transformed).length;
      if (nsCount === 0) {
        console.warn('[natives] remote returned empty data, using local fallback');
        return fallback;
      }
      try {
        console.log('[natives] loaded remote: ' + nsCount + ' namespaces from VORPCORE/RDR3natives');
      } catch (e) {}
      return transformed;
    })
    .catch(function (err) {
      try {
        console.warn('[natives] remote fetch failed, using local fallback:', err && err.message ? err.message : err);
      } catch (e) {}
      return fallback;
    });

  window.__NATIVES__ = promise;
})();
