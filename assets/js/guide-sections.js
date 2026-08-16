/* Guide pages: turn the "On this page" sidebar into a section switcher.
 *
 * Picking a topic shows that section on its own rather than scrolling through
 * one long page. Deep links (/guides/general/#universal), the back button and
 * in-body cross-links all keep working, and a "Show all sections" toggle
 * restores the old single-page view for anyone who wants to Ctrl+F the lot.
 *
 * Progressive enhancement: without this file every section stays visible.
 */
(function () {
    var main = document.querySelector('.guide-main');
    var nav = document.querySelector('.guide-nav');
    if (!main || !nav) return;

    // Map each sidebar link to the direct child of .guide-main that holds it.
    var sections = [];
    var byId = {};
    [].slice.call(nav.querySelectorAll('a[href^="#"]')).forEach(function (link) {
        var id = link.getAttribute('href').slice(1);
        if (!id || byId[id]) return;
        var el = resolve(id);
        if (!el) return;
        var section = { id: id, el: el, link: link, label: link.textContent.trim() };
        byId[id] = section;
        sections.push(section);
    });
    if (sections.length < 2) return;

    function resolve(id) {
        var el = document.getElementById(id);
        if (!el || !main.contains(el)) return null;
        while (el.parentElement && el.parentElement !== main) el = el.parentElement;
        return el.parentElement === main ? el : null;
    }

    // Which section owns an arbitrary fragment, even one pointing mid-section.
    function sectionFor(id) {
        if (byId[id]) return byId[id];
        var el = resolve(id);
        if (!el) return null;
        for (var i = 0; i < sections.length; i++) {
            if (sections[i].el === el) return sections[i];
        }
        return null;
    }

    document.body.classList.add('guide-sections-on');
    main.classList.add('guide-sections');
    sections.forEach(function (s) { s.el.classList.add('is-guide-section'); });

    var progress = document.createElement('p');
    progress.className = 'guide-progress';
    nav.parentElement.appendChild(progress);

    var toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'guide-show-all';
    toggle.setAttribute('aria-pressed', 'false');
    toggle.textContent = 'Show all sections';
    nav.parentElement.appendChild(toggle);

    var stepNav = document.createElement('div');
    stepNav.className = 'guide-step-nav';
    main.appendChild(stepNav);

    var current = sections[0];
    var showingAll = false;

    function scrollTo(el, instant) {
        var top = el.getBoundingClientRect().top + window.pageYOffset - 110;
        window.scrollTo({ top: top > 0 ? top : 0, behavior: instant ? 'auto' : 'smooth' });
    }

    function markActive(section) {
        sections.forEach(function (s) {
            var on = s === section;
            s.link.classList.toggle('active', on);
            if (on) s.link.setAttribute('aria-current', 'true');
            else s.link.removeAttribute('aria-current');
        });
    }

    function step(section, dir) {
        var a = document.createElement('a');
        a.className = 'guide-step-' + dir;
        a.href = '#' + section.id;
        var kicker = document.createElement('span');
        kicker.className = 'step-dir';
        kicker.textContent = dir === 'prev' ? '← Previous' : 'Next →';
        var label = document.createElement('span');
        label.className = 'step-label';
        label.textContent = section.label;
        a.appendChild(kicker);
        a.appendChild(label);
        return a;
    }

    function show(id, opts) {
        var section = byId[id];
        if (!section) return;
        opts = opts || {};
        current = section;

        sections.forEach(function (s) { s.el.classList.toggle('is-active', s === section); });
        markActive(section);

        var index = sections.indexOf(section);
        progress.textContent = 'Section ' + (index + 1) + ' of ' + sections.length;

        while (stepNav.firstChild) stepNav.removeChild(stepNav.firstChild);
        if (index > 0) stepNav.appendChild(step(sections[index - 1], 'prev'));
        if (index < sections.length - 1) stepNav.appendChild(step(sections[index + 1], 'next'));

        if (opts.scroll) scrollTo(main, opts.instant);
    }

    function setShowAll(on) {
        showingAll = on;
        main.classList.toggle('guide-sections', !on);
        stepNav.style.display = on ? 'none' : '';
        progress.style.display = on ? 'none' : '';
        toggle.setAttribute('aria-pressed', on ? 'true' : 'false');
        toggle.textContent = on ? 'Show one section at a time' : 'Show all sections';
        if (on) scrollTo(current.el);
        else show(current.id, { scroll: true });
    }

    toggle.addEventListener('click', function () { setShowAll(!showingAll); });

    // Any same-page fragment link - sidebar rows, the stepper, cross-references
    // buried in the copy - switches sections rather than scrolling.
    document.addEventListener('click', function (e) {
        if (e.defaultPrevented || e.button !== 0) return;
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
        if (!e.target.closest) return;
        var a = e.target.closest('a');
        if (!a) return;
        var href = a.getAttribute('href') || '';
        if (href.charAt(0) !== '#' || href.length < 2) return;
        var target = sectionFor(href.slice(1));
        if (!target) return;

        e.preventDefault();
        if (window.history && history.pushState) history.pushState(null, '', '#' + target.id);
        else location.hash = target.id;

        if (showingAll) {
            markActive(target);
            current = target;
            scrollTo(target.el);
        } else {
            show(target.id, { scroll: true });
        }
    });

    // Back/forward, and hashes typed straight into the address bar.
    window.addEventListener('hashchange', function () {
        var target = sectionFor((location.hash || '').slice(1));
        if (!target) return;
        if (showingAll) {
            markActive(target);
            current = target;
            scrollTo(target.el);
        } else {
            show(target.id, { scroll: true });
        }
    });

    // In show-all mode the sidebar tracks whichever section is on screen.
    window.addEventListener('scroll', function () {
        if (!showingAll) return;
        var best = sections[0];
        for (var i = 0; i < sections.length; i++) {
            if (sections[i].el.getBoundingClientRect().top <= 140) best = sections[i];
        }
        if (best !== current) { current = best; markActive(best); }
    }, { passive: true });

    // A deep link lands on its section; anything else opens at the first one.
    var initial = sectionFor((location.hash || '').slice(1));
    show(initial ? initial.id : sections[0].id, { scroll: !!initial, instant: true });
})();
