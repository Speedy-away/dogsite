(() => {
 const links=[...document.querySelectorAll('[data-tf2-preview]')],box=document.getElementById('lightbox');
 if(!box||!links.length)return;
 const image=document.getElementById('lightbox-img'),caption=document.getElementById('lightbox-caption');let index=0,trigger=null;
 const show=i=>{index=(i+links.length)%links.length;image.src=links[index].href;image.alt=links[index].querySelector('img').alt;caption.textContent=(index+1)+' / '+links.length+' · '+links[index].querySelector('.preview-caption').textContent;};
 const close=()=>{box.classList.remove('active');box.setAttribute('aria-hidden','true');document.body.style.overflow='';trigger?.focus();};
 links.forEach((link,i)=>link.addEventListener('click',e=>{e.preventDefault();trigger=link;show(i);box.classList.add('active');box.setAttribute('aria-hidden','false');document.body.style.overflow='hidden';box.querySelector('.lightbox-close').focus();}));
 box.querySelector('.lightbox-close').addEventListener('click',close);box.querySelector('.lightbox-next').addEventListener('click',()=>show(index+1));box.querySelector('.lightbox-prev').addEventListener('click',()=>show(index-1));
 box.addEventListener('click',e=>{if(e.target===box)close();});
 document.addEventListener('keydown',e=>{if(!box.classList.contains('active'))return;if(e.key==='Escape')close();if(e.key==='ArrowRight'){e.preventDefault();show(index+1);}if(e.key==='ArrowLeft'){e.preventDefault();show(index-1);}if(e.key==='Tab'){const buttons=[...box.querySelectorAll('button')],first=buttons[0],last=buttons.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}});
})();

/* Existing product free-key flow, with native dialog focus handling. */
(function () {
        const trigger = document.getElementById('getFreeKey');
        const modal = document.getElementById('freeKeyModal');
        const countdown = document.getElementById('freeKeyCountdown');
        const link = document.getElementById('freeKeyBtn');
        const destination = trigger.href;
        let timer;
        let previousOverflow;
        trigger.addEventListener('click', function (event) {
            event.preventDefault();
            clearInterval(timer);
            let remaining = 3;
            countdown.textContent = remaining;
            link.removeAttribute('href');
            link.setAttribute('disabled', '');
            link.setAttribute('aria-disabled', 'true');
            link.setAttribute('tabindex', '-1');
            link.textContent = 'PLEASE WAIT...';
            previousOverflow = document.body.style.overflow;
            document.body.style.overflow = 'hidden';
            modal.showModal();
            timer = setInterval(function () {
                remaining--;
                countdown.textContent = remaining > 0 ? remaining : '✓';
                if (remaining <= 0) {
                    clearInterval(timer);
                    link.href = destination;
                    link.removeAttribute('disabled');
                    link.removeAttribute('tabindex');
                    link.setAttribute('aria-disabled', 'false');
                    link.textContent = 'CONTINUE TO GET KEY';
                }
            }, 1000);
        });
        modal.querySelector('.freekey-modal-close').addEventListener('click', function () { modal.close(); });
        modal.addEventListener('click', function (event) { if (event.target === modal) modal.close(); });
        modal.addEventListener('close', function () {
            clearInterval(timer);
            document.body.style.overflow = previousOverflow;
        });
        link.addEventListener('click', function (event) {
            if (link.getAttribute('aria-disabled') === 'true') event.preventDefault();
        });
    })();
