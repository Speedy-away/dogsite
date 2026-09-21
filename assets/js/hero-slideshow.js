(function () {
  'use strict';

  var hero = document.getElementById('home');
  var stage = document.getElementById('heroScenes');
  var controls = document.getElementById('sceneControls');
  if (!hero || !stage || !controls) return;

  var scenes = [
    { file: 'gta-desert', game: 'Grand Theft Auto V', name: 'Sandy Shores' },
    { file: 'rdr-overlook', game: 'Red Dead Redemption 2', name: 'The overlook' },
    { file: 'rdr-heartlands', game: 'Red Dead Redemption 2', name: 'The Heartlands' },
    { file: 'gta-hills', game: 'Grand Theft Auto V', name: 'Vinewood Hills' },
    { file: 'rdr-forest', game: 'Red Dead Redemption 2', name: 'Into the pines' },
    {"file":"cs2-ancient","game":"Counter-Strike 2","name":"Ancient"},
    {"file":"gmod-sandbox","game":"Garry's Mod","name":"Sandbox stories"},
    {"file":"gta-casino","game":"Grand Theft Auto V","name":"Casino after dark"},
    {"file":"gta-coast","game":"Grand Theft Auto V","name":"Coastal sunset"},
    {"file":"rdr-drifter","game":"Red Dead Redemption 2","name":"The wandering gentleman"},
    { file: 'l4d-railyard', game: 'Left 4 Dead', name: 'The rail yard' }
  ];
  var dwell = 10000;
  var motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  var pauseButton = document.getElementById('scenePause');
  var nextButton = document.getElementById('sceneNext');
  var gameLabel = document.getElementById('sceneGame');
  var nameLabel = document.getElementById('sceneName');
  var stepContainer = controls.querySelector('.scene-steps');
  var steps = scenes.map(function () {
    var step = document.createElement('span');
    step.className = 'scene-step';
    return step;
  });
  stepContainer.replaceChildren.apply(stepContainer, steps);
  var cache = new Map();
  var current = -1;
  var queue = [];
  var position = 0;
  var activeLayer = stage.querySelector('.hero-scene');
  var timer;
  var busy = false;
  var ready = false;
  var visible = true;
  var focused = false;
  var paused = motion.matches;

  // Shuffle a full deck, then consume it for both automatic and manual changes.
  function nextIndex() {
    if (!queue.length) {
      queue = scenes.map(function (_, index) { return index; });
      for (var i = queue.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var swap = queue[i];
        queue[i] = queue[j];
        queue[j] = swap;
      }
      // The first scene of a new cycle must differ from the last scene shown.
      if (queue.length > 1 && queue[0] === current) {
        var first = 1 + Math.floor(Math.random() * (queue.length - 1));
        var previous = queue[0];
        queue[0] = queue[first];
        queue[first] = previous;
      }
    }
    return queue[0];
  }

  function canRun() {
    return ready && !paused && !document.hidden && visible && !focused;
  }

  function schedule() {
    window.clearTimeout(timer);
    hero.classList.toggle('is-paused', !canRun());
    pauseButton.setAttribute('aria-pressed', String(paused));
    pauseButton.setAttribute('aria-label', paused ? 'Play background slideshow' : 'Pause background slideshow');
    pauseButton.title = paused ? 'Play backgrounds' : 'Pause backgrounds';
    if (canRun() && !busy) timer = window.setTimeout(function () { advance(false); }, dwell);
  }

  function loadImage(index) {
    if (cache.has(index)) return cache.get(index);
    var promise = new Promise(function (resolve, reject) {
      var img = new Image();
      var timeout = window.setTimeout(function () { reject(new Error('Artwork timed out')); }, 15000);
      img.alt = '';
      img.width = 1672;
      img.height = 941;
      img.decoding = 'async';
      img.fetchPriority = ready ? 'low' : 'high';
      img.onload = async function () {
        window.clearTimeout(timeout);
        try { await img.decode(); } catch (_) { /* Loaded images can still be displayed. */ }
        resolve(img);
      };
      img.onerror = function () {
        window.clearTimeout(timeout);
        reject(new Error('Artwork unavailable'));
      };
      img.sizes = '(max-width: 760px) 180vh, 100vw';
      img.srcset = '/assets/images/hero/' + scenes[index].file + '-v2-960.webp 960w, /assets/images/hero/' + scenes[index].file + '-v2.webp 1672w';
      img.src = '/assets/images/hero/' + scenes[index].file + '-v2.webp';
    });
    cache.set(index, promise);
    return promise;
  }

  function preloadNext() {
    // Fetch only the next scene, rather than every scene on the initial page load.
    if (ready && !document.hidden && visible) loadImage(nextIndex()).catch(function () {});
  }

  async function advance(manual, initial) {
    if (busy || (!manual && !canRun())) return;
    busy = true;
    nextButton.disabled = true;
    window.clearTimeout(timer);
    try {
      var next;
      var img;
      // A missing asset must not replace the visible scene with an empty frame.
      for (var attempt = 0; attempt < scenes.length; attempt++) {
        next = nextIndex();
        if (next === current) { queue.shift(); continue; }
        try { img = await loadImage(next); break; } catch (_) { queue.shift(); }
      }
      if (!img || (!manual && !canRun())) return;
      // Do not consume the queued scene if playback paused while it was loading.
      queue.shift();
      position = scenes.length - queue.length - 1;
      var previousLayer;
      if (initial) {
        activeLayer.dataset.scene = scenes[next].file;
        activeLayer.replaceChildren(img);
      } else {
        var layer = document.createElement('div');
        layer.className = 'hero-scene';
        layer.dataset.scene = scenes[next].file;
        layer.appendChild(img);
        stage.appendChild(layer);
        // Commit the transparent frame before crossfading the decoded image in.
        void layer.offsetWidth;
        layer.classList.add('is-active');
        activeLayer.classList.add('is-leaving');
        activeLayer.classList.remove('is-active');
        previousLayer = activeLayer;
        activeLayer = layer;
      }
      current = next;
      gameLabel.textContent = scenes[current].game;
      nameLabel.textContent = scenes[current].name;
      steps.forEach(function (step, i) { step.classList.toggle('is-current', i === position); });
      controls.setAttribute('aria-label', 'Background slideshow, scene ' + (position + 1) + ' of ' + scenes.length);
      ready = true;
      if (previousLayer) {
        // Clean up the fade independently so transitions start ten seconds apart.
        window.setTimeout(function () { previousLayer.remove(); }, motion.matches ? 0 : 1650);
      }
      preloadNext();
    } finally {
      busy = false;
      nextButton.disabled = false;
      schedule();
    }
  }

  pauseButton.addEventListener('click', function () { paused = !paused; if (!paused) focused = false; schedule(); });
  nextButton.addEventListener('click', function () { advance(true); });
  controls.addEventListener('focusin', function () { focused = true; schedule(); });
  controls.addEventListener('focusout', function (event) {
    if (!controls.contains(event.relatedTarget)) { focused = false; schedule(); }
  });
  document.addEventListener('visibilitychange', function () { schedule(); preloadNext(); });
  motion.addEventListener('change', function () {
    if (motion.matches) paused = true;
    schedule();
  });
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      visible = entries[0].isIntersecting;
      schedule();
      if (ready) preloadNext();
    }, { threshold: 0 }).observe(hero);
  }

  // Keep the HTML artwork as a no-JavaScript/loading fallback; start on a
  // randomly selected, fully decoded scene once the slideshow is available.
  advance(true, true);
})();
