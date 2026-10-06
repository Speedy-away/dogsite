const motionButton=document.querySelector('#motion');
const preference=matchMedia('(prefers-reduced-motion: reduce)');
let moving=!preference.matches;
function setMotion(){document.querySelectorAll('.art img').forEach(img=>img.src=moving?img.dataset.animated:img.dataset.static);motionButton.textContent=moving?'Pause motion':'Play motion';motionButton.setAttribute('aria-pressed',String(moving));}
setMotion();motionButton.addEventListener('click',()=>{moving=!moving;setMotion();});
preference.addEventListener('change',()=>{moving=!preference.matches;setMotion();});
document.querySelector('#background').addEventListener('click',event=>{const enabled=document.body.classList.toggle('checker');event.currentTarget.setAttribute('aria-pressed',String(enabled));});
document.querySelectorAll('[data-filter]').forEach(button=>button.addEventListener('click',()=>{document.querySelectorAll('[data-filter]').forEach(b=>{b.classList.toggle('active',b===button);b.setAttribute('aria-pressed',String(b===button));});document.querySelectorAll('article').forEach(card=>card.hidden=button.dataset.filter!=='all'&&card.dataset.category!==button.dataset.filter);}));