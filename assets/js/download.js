// Download page (/download/): the loader link appears once the visitor's portal
// session checks out; everyone else gets a sign-in button that brings them back.
(function () {
  // Same endpoint and key as the portal (portal/index.html: #apiUrl, #portalKey).
  var API = 'https://proudlyauthentication.com/api/portal/v1/pk_gri2butNfQ28AWQqNTD5xLtQKwer2MNv';
  // Keep in step with the dashboard download dialog in portal/index.html.
  var LOADER_URL = 'https://filego.at/bucket/f013dc38-3b97-4031-9d51-0c1e023ce713';

  var card = document.getElementById('loader-card');
  var status = document.getElementById('loader-status');
  var views = card.querySelectorAll('[data-view]');
  document.getElementById('loader-download').href = LOADER_URL;

  function show(state, name) {
    card.classList.toggle('checking', state === 'checking');
    for (var i = 0; i < views.length; i++) views[i].hidden = views[i].getAttribute('data-view') !== state;
    if (state === 'checking') status.textContent = 'Checking your sign-in';
    if (state === 'guest') status.textContent = 'Sign in to unlock the loader download.';
    if (state === 'error') status.textContent = 'We could not reach the sign-in service. Check your connection and try again.';
    if (state === 'member') {
      status.textContent = '';
      if (name) {
        status.appendChild(document.createTextNode('Signed in as '));
        var who = document.createElement('strong');
        who.textContent = name;                    // never parsed as HTML
        status.appendChild(who);
        status.appendChild(document.createTextNode('. Your download is ready.'));
      } else {
        status.textContent = 'You are signed in. Your download is ready.';
      }
    }
  }

  function token() {
    try { return localStorage.getItem('portalSessionToken') || ''; } catch (e) { return ''; }
  }

  function check() {
    var t = token();
    if (!t) { show('guest'); return; }
    show('checking');
    var ctrl = window.AbortController ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctrl) ctrl.abort(); }, 10000);
    fetch(API + '/auth/session', { headers: { Authorization: 'Bearer ' + t }, signal: ctrl ? ctrl.signal : undefined })
      .then(function (r) {
        return r.json().catch(function () { return {}; }).then(function (d) { return { status: r.status, ok: r.ok, data: d }; });
      })
      .then(function (res) {
        clearTimeout(timer);
        if (res.ok && res.data && res.data.valid) {
          var c = res.data.customer || {};
          show('member', c.display_name || c.username || '');
        } else if (res.status >= 500) {
          show('error');
        } else {
          show('guest');                           // expired or signed out
        }
      })
      .catch(function () { clearTimeout(timer); show('error'); });
  }

  document.getElementById('loader-retry').addEventListener('click', check);
  check();

  // Mobile menu.
  var burger = document.getElementById('hamburger');
  var links = document.getElementById('navLinks');
  burger.addEventListener('click', function () {
    var open = links.classList.toggle('open');
    burger.classList.toggle('active', open);
    burger.setAttribute('aria-expanded', String(open));
  });
})();
