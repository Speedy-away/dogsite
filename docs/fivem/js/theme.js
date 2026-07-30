(function () {
  var STORAGE_KEY = 'theme';
  var DARK_ICON = '\u2600';   // sun — shown in dark mode (click to go light)
  var LIGHT_ICON = '\u263E';  // moon — shown in light mode (click to go dark)

  function isDark() {
    return document.documentElement.classList.contains('dark');
  }

  function updateButton(btn) {
    if (!btn) return;
    var dark = isDark();
    btn.textContent = dark ? DARK_ICON : LIGHT_ICON;
    btn.setAttribute('aria-label', dark ? 'Switch to light mode' : 'Switch to dark mode');
    btn.setAttribute('title', dark ? 'Switch to light mode' : 'Switch to dark mode');
  }

  function setTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (e) {}
  }

  function createButton() {
    if (document.getElementById('theme-toggle')) return;
    var btn = document.createElement('button');
    btn.id = 'theme-toggle';
    btn.type = 'button';
    updateButton(btn);
    btn.addEventListener('click', function () {
      setTheme(isDark() ? 'light' : 'dark');
      updateButton(btn);
    });
    document.body.appendChild(btn);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createButton);
  } else {
    createButton();
  }
})();
