/* Local video filters; the complete library remains available without JavaScript. */
(() => {
 const input=document.getElementById('video-filter'),game=document.getElementById('video-game');
 const cards=[...document.querySelectorAll('.watch-card')],sections=[...document.querySelectorAll('.video-section')];
 function filter(){
  const words=input.value.toLowerCase().trim().split(/\s+/).filter(Boolean);let count=0;
  cards.forEach(card=>{card.hidden=!(game.value==='all'||card.dataset.game===game.value)||!words.every(w=>card.dataset.search.includes(w));if(!card.hidden)count++;});
  sections.forEach(section=>{const items=[...section.querySelectorAll('.watch-card')];section.hidden=items.length?!items.some(c=>!c.hidden):!!words.length||(game.value!=='all'&&game.value!==section.id);});
  document.getElementById('video-results-count').textContent=count+' matching video'+(count===1?'':'s');
  document.getElementById('video-empty').hidden=count>0||sections.some(s=>!s.hidden&&!s.querySelector('.watch-card'));
 }
 function reset(){input.value='';game.value='all';filter();}
 input.addEventListener('input',filter);game.addEventListener('change',filter);document.getElementById('video-reset').addEventListener('click',reset);
 function revealHash(){const target=document.getElementById(location.hash.slice(1));if(target&&(target.matches('.watch-card,.video-section'))){reset();requestAnimationFrame(()=>target.scrollIntoView({block:'start'}));}}
 window.addEventListener('hashchange',revealHash);
 document.querySelectorAll('.wiki-sidebar a,.wiki-toc a').forEach(a=>a.addEventListener('click',()=>{if(a.hash)reset();}));
 revealHash();
})();
