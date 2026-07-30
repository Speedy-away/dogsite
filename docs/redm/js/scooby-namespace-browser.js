(function () {
  var STORAGE_KEY = 'scooby-redm-namespace-view';
  var NAMESPACE_VALUE = 'namespaces';
  var groups = [];
  var currentMode = NAMESPACE_VALUE;
  var bulkToggle = false;
  var searchQuery = '';
  var apiSetBound = false;

  function defaultGame() {
    return window.location.pathname.toLowerCase().indexOf('/fivem') !== -1 ? 'gta5' : 'rdr3';
  }

  function onReady(fn) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', fn);
    } else {
      fn();
    }
  }

  function getNativeName(native) {
    return native.name || native.hash || '';
  }

  function formatParams(native) {
    if (!native.params || !native.params.length) return '';
    return native.params.map(function (param) {
      return [param.type, param.name].filter(Boolean).join(' ');
    }).join(', ');
  }

  function normalize(value) {
    return (value || '').toString().toLowerCase().trim();
  }

  function parseSearch() {
    var query = normalize(searchQuery);
    var match = query.match(/^(namespace|namespaces|ns|native|natives|name|hash|description|descriptions|desc|docs):\s*(.+)$/);
    if (!match) return { kind: 'all', value: query };

    var kind = match[1];
    if (kind === 'namespaces' || kind === 'ns') kind = 'namespace';
    if (kind === 'natives' || kind === 'name' || kind === 'hash') kind = 'native';
    if (kind === 'descriptions' || kind === 'desc' || kind === 'docs') kind = 'description';
    return { kind: kind, value: normalize(match[2]) };
  }

  function paramsText(native) {
    return (native.params || []).map(function (param) {
      return [param.type, param.name, param.description].filter(Boolean).join(' ');
    }).join(' ');
  }

  function nativeText(native, namespace) {
    return normalize([
      namespace,
      native.namespace,
      native.ns,
      native.name,
      native.hash,
      native.results,
      native.description,
      native.resultsDescription,
      paramsText(native)
    ].filter(Boolean).join(' '));
  }

  function nativeNameText(native) {
    return normalize([
      native.name,
      native.hash,
      native.results,
      paramsText(native)
    ].filter(Boolean).join(' '));
  }

  function nativeDescriptionText(native) {
    return normalize([
      native.description,
      native.resultsDescription,
      (native.params || []).map(function (param) {
        return param.description || '';
      }).join(' ')
    ].filter(Boolean).join(' '));
  }

  function formatNativeCode(native) {
    return '// ' + getNativeName(native) + '\n'
      + (native.results || 'void') + ' ' + getNativeName(native) + '(' + formatParams(native) + ');';
  }

  function appendInfo(container, label, value, className) {
    if (!value) return;
    var item = document.createElement('span');
    item.className = className || '';

    var labelEl = document.createElement('span');
    labelEl.textContent = label + ': ';
    item.appendChild(labelEl);
    item.appendChild(document.createTextNode(value));
    container.appendChild(item);
  }

  function renderDescription(container, native) {
    var desc = document.createElement('div');
    desc.className = 'desc';

    if (native.params && native.params.length) {
      var params = document.createElement('div');
      params.className = 'parameters';

      var strong = document.createElement('strong');
      strong.textContent = 'Parameters:';
      params.appendChild(strong);
      params.appendChild(document.createElement('br'));

      var list = document.createElement('ul');
      native.params.forEach(function (param) {
        var item = document.createElement('li');
        var name = document.createElement('strong');
        name.textContent = param.name || 'param';
        item.appendChild(name);
        item.appendChild(document.createTextNode(': ' + (param.type || 'Any')));
        if (param.description) {
          item.appendChild(document.createTextNode(' - ' + param.description));
        }
        list.appendChild(item);
      });

      params.appendChild(list);
      desc.appendChild(params);
    }

    if (native.results && native.results !== 'void') {
      var returns = document.createElement('div');
      returns.className = 'returns';
      var returnLabel = document.createElement('strong');
      returnLabel.textContent = 'Returns: ';
      returns.appendChild(returnLabel);
      returns.appendChild(document.createTextNode(native.results));
      desc.appendChild(returns);
    }

    if (native.description) {
      var text = document.createElement('p');
      text.textContent = native.description;
      desc.appendChild(text);
    }

    container.appendChild(desc);
  }

  function renderNativeDetails(native) {
    var aside = document.querySelector('.app.type-natives aside');
    if (!aside) return;

    var oldDetails = aside.querySelector('.details');
    var details = document.createElement('div');
    details.className = 'details scooby-ns-details';

    var info = document.createElement('div');
    info.className = 'info';
    appendInfo(info, 'Namespace', native.namespace || native.ns, 'namespace');
    appendInfo(info, 'API set', native.apiset || 'client', 'apiset');
    appendInfo(info, 'Game', native.game || defaultGame(), 'game');
    details.appendChild(info);

    var heading = document.createElement('h2');
    heading.title = getNativeName(native);
    heading.textContent = getNativeName(native);
    details.appendChild(heading);

    var hash = document.createElement('div');
    hash.className = 'hash';
    var hashSpan = document.createElement('span');
    var hashPre = document.createElement('pre');
    hashPre.textContent = native.hash;
    hashSpan.appendChild(hashPre);
    hash.appendChild(hashSpan);
    details.appendChild(hash);

    var code = document.createElement('div');
    code.className = 'code';
    var pre = document.createElement('pre');
    pre.style.display = 'block';
    pre.style.overflowX = 'auto';
    pre.style.padding = '0.5em';
    pre.style.background = '#F0F0F0';
    pre.style.color = '#444';
    var codeEl = document.createElement('code');
    codeEl.className = 'language-cpp';
    codeEl.style.whiteSpace = 'pre';
    codeEl.textContent = formatNativeCode(native);
    pre.appendChild(codeEl);
    code.appendChild(pre);
    details.appendChild(code);

    renderDescription(details, native);

    if (oldDetails) oldDetails.replaceWith(details);
    else aside.insertBefore(details, aside.firstChild);

    if (window.innerWidth <= 900) {
      aside.classList.add('show');
    }
  }

  function getActiveApiSet() {
    var active = document.querySelector('nav .toggles:first-child li.active');
    return active && active.getAttribute('data-name') ? active.getAttribute('data-name') : 'all';
  }

  function matchesApiSet(native) {
    var apiset = getActiveApiSet();
    if (apiset === 'all') return true;
    if (native.apiset === 'shared') return true;
    if (native.apiset === apiset) return true;
    return apiset === 'client' && !native.apiset;
  }

  function sortedGroups(data) {
    return Object.keys(data || {}).sort(function (a, b) {
      return a.localeCompare(b);
    }).map(function (namespace) {
      var natives = data[namespace] || {};
      return {
        namespace: namespace,
        natives: Object.keys(natives).map(function (hash) {
          var native = natives[hash] || {};
          return Object.assign({}, native, {
            hash: native.hash || hash,
            namespace: native.namespace || native.ns || namespace
          });
        }).sort(function (a, b) {
          return getNativeName(a).localeCompare(getNativeName(b));
        })
      };
    }).filter(function (group) {
      return group.natives.length > 0;
    });
  }

  function visibleNatives(group) {
    return group.natives.filter(matchesApiSet);
  }

  function filteredNatives(group) {
    var query = parseSearch();
    var natives = visibleNatives(group);
    if (!query.value) return natives;

    var namespaceText = normalize(group.namespace);
    if (query.kind === 'namespace') {
      return namespaceText.indexOf(query.value) !== -1 ? natives : [];
    }

    if (query.kind === 'native') {
      return natives.filter(function (native) {
        return nativeNameText(native).indexOf(query.value) !== -1;
      });
    }

    if (query.kind === 'description') {
      return natives.filter(function (native) {
        return nativeDescriptionText(native).indexOf(query.value) !== -1;
      });
    }

    if (namespaceText.indexOf(query.value) !== -1) return natives;
    return natives.filter(function (native) {
      return nativeText(native, group.namespace).indexOf(query.value) !== -1;
    });
  }

  function currentHash() {
    var query = window.location.search || '';
    return query.charAt(0) === '?' && query.charAt(1) === '_' ? query.slice(2) : '';
  }

  function findNative(hash) {
    if (!hash) return null;
    for (var i = 0; i < groups.length; i++) {
      for (var j = 0; j < groups[i].natives.length; j++) {
        if (groups[i].natives[j].hash === hash) return groups[i].natives[j];
      }
    }
    return null;
  }

  function firstVisibleNative() {
    for (var i = 0; i < groups.length; i++) {
      var natives = filteredNatives(groups[i]);
      if (natives.length) return natives[0];
    }
    return null;
  }

  function ensurePanel() {
    var app = document.querySelector('.app.type-natives');
    var section = app && app.querySelector('section');
    if (!app || !section) return null;

    var panel = section.querySelector('.scooby-namespace-browser');
    if (!panel) {
      panel = document.createElement('div');
      panel.className = 'scooby-namespace-browser';
      panel.hidden = true;
      section.appendChild(panel);
    }

    return panel;
  }

  function makeIconButton(icon, title, onClick) {
    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'scooby-ns-icon-button';
    button.title = title;
    button.setAttribute('aria-label', title);
    button.addEventListener('click', onClick);

    var span = document.createElement('span');
    span.className = 'material-icons-outlined';
    span.textContent = icon;
    button.appendChild(span);

    return button;
  }

  function renderNativeList(container, group) {
    if (container.getAttribute('data-rendered') === 'true') return;

    var natives = filteredNatives(group);
    if (!natives.length) {
      var empty = document.createElement('div');
      empty.className = 'scooby-ns-empty';
      empty.textContent = 'No natives for the active API set.';
      container.appendChild(empty);
      container.setAttribute('data-rendered', 'true');
      return;
    }

    natives.forEach(function (native) {
      var row = document.createElement('a');
      row.className = 'scooby-ns-native';
      row.href = '?_' + native.hash;
      row.setAttribute('data-hash', native.hash);
      if (native.hash === currentHash()) row.classList.add('active');
      row.addEventListener('click', function (event) {
        event.preventDefault();
        selectNative(native);
      });

      var name = document.createElement('span');
      name.className = 'scooby-ns-native-name';
      name.textContent = getNativeName(native);
      row.appendChild(name);

      var hash = document.createElement('span');
      hash.className = 'scooby-ns-native-hash';
      hash.textContent = native.hash;
      row.appendChild(hash);

      var params = formatParams(native);
      if (params) {
        var paramText = document.createElement('span');
        paramText.className = 'scooby-ns-native-params';
        paramText.textContent = '(' + params + ')';
        row.appendChild(paramText);
      }

      container.appendChild(row);
    });

    container.setAttribute('data-rendered', 'true');
  }

  function renderGroup(group, open) {
    var details = document.createElement('details');
    details.className = 'scooby-ns-group';
    details.setAttribute('data-namespace', group.namespace);
    details.open = !!open;

    var natives = filteredNatives(group);
    var summary = document.createElement('summary');
    summary.className = 'scooby-ns-summary';

    var name = document.createElement('span');
    name.className = 'scooby-ns-summary-name';
    name.textContent = group.namespace;
    summary.appendChild(name);

    var count = document.createElement('span');
    count.className = 'scooby-ns-summary-count';
    count.textContent = natives.length + ' natives';
    summary.appendChild(count);

    var list = document.createElement('div');
    list.className = 'scooby-ns-list';

    details.appendChild(summary);
    details.appendChild(list);
    details.addEventListener('toggle', function () {
      if (!details.open) return;
      renderNativeList(list, group);
      if (!bulkToggle && !searchQuery && details.parentElement) {
        details.parentElement.querySelectorAll('details.scooby-ns-group').forEach(function (other) {
          if (other !== details) other.open = false;
        });
      }
    });

    if (details.open) renderNativeList(list, group);
    return details;
  }

  function renderPanel() {
    var app = document.querySelector('.app.type-natives');
    var panel = ensurePanel();
    if (!app || !panel) return;
    var openNamespaces = {};
    panel.querySelectorAll('details.scooby-ns-group[open]').forEach(function (details) {
      if (details.getAttribute('data-namespace')) openNamespaces[details.getAttribute('data-namespace')] = true;
    });

    if (!currentMode) {
      app.classList.remove('scooby-namespace-active');
      panel.hidden = true;
      panel.replaceChildren();
      return;
    }

    app.classList.add('scooby-namespace-active');
    panel.hidden = false;
    panel.replaceChildren();

    var header = document.createElement('div');
    header.className = 'scooby-ns-header';

    var title = document.createElement('div');
    title.className = 'scooby-ns-title';
    title.textContent = 'Namespaces';
    header.appendChild(title);

    var actions = document.createElement('div');
    actions.className = 'scooby-ns-actions';
    actions.appendChild(makeIconButton('unfold_more', 'Expand all namespaces', function () {
      bulkToggle = true;
      panel.querySelectorAll('details.scooby-ns-group').forEach(function (details) {
        details.open = true;
      });
      bulkToggle = false;
    }));
    actions.appendChild(makeIconButton('unfold_less', 'Collapse all namespaces', function () {
      panel.querySelectorAll('details.scooby-ns-group').forEach(function (details) {
        details.open = false;
      });
    }));
    header.appendChild(actions);
    panel.appendChild(header);

    var content = document.createElement('div');
    content.className = 'scooby-ns-content';
    var matchedGroups = 0;
    groups.forEach(function (group) {
      var natives = filteredNatives(group);
      if (!natives.length) return;
      matchedGroups++;
      content.appendChild(renderGroup(group, !!searchQuery || !!openNamespaces[group.namespace]));
    });

    if (!matchedGroups) {
      var empty = document.createElement('div');
      empty.className = 'scooby-ns-empty';
      empty.textContent = 'No namespace matches.';
      content.appendChild(empty);
    }

    panel.appendChild(content);
  }

  function updateActiveNative(hash) {
    document.querySelectorAll('.scooby-ns-native').forEach(function (row) {
      row.classList.toggle('active', row.getAttribute('data-hash') === hash);
    });
  }

  function syncSelectedNative() {
    var native = findNative(currentHash()) || firstVisibleNative();
    if (!native) return;
    updateActiveNative(native.hash);
    renderNativeDetails(native);
  }

  function selectNative(native) {
    if (!native || !native.hash) return;
    history.pushState({ scoobyNative: native.hash }, '', '?_' + native.hash);
    updateActiveNative(native.hash);
    renderNativeDetails(native);
  }

  window.addEventListener('popstate', function () {
    if (currentMode !== NAMESPACE_VALUE) return;
    syncSelectedNative();
  });

  function initBrowser() {
    var nav = document.querySelector('nav');
    bindSearch();

    try {
      localStorage.setItem(STORAGE_KEY, NAMESPACE_VALUE);
    } catch (e) {}

    if (nav && !apiSetBound) {
      apiSetBound = true;
      nav.addEventListener('click', function (event) {
      if (event.target && event.target.closest('.toggles:first-child li')) {
        setTimeout(renderPanel, 0);
      }
      });
    }

    renderPanel();
    syncSelectedNative();
  }

  function bindSearch() {
    var input = document.querySelector('header input[name="search"]');
    if (!input || input.getAttribute('data-scooby-ns-search') === 'true') return;

    input.setAttribute('data-scooby-ns-search', 'true');
    searchQuery = input.value || '';
    input.addEventListener('input', function () {
      searchQuery = input.value || '';
      if (currentMode === NAMESPACE_VALUE) renderPanel();
    });
    input.addEventListener('search', function () {
      searchQuery = input.value || '';
      if (currentMode === NAMESPACE_VALUE) renderPanel();
    });
  }

  onReady(function () {
    Promise.resolve(window.__NATIVES__ || {}).then(function (data) {
      groups = sortedGroups(data);
      [0, 250, 1000].forEach(function (delay) {
        setTimeout(function () {
          bindSearch();
          initBrowser();
        }, delay);
      });
    });
  });
})();
