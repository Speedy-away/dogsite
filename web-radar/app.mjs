import {drawRadar} from './render.mjs';
const $=id=>document.getElementById(id);
const match=location.pathname.match(/^\/web-radar\/([a-f0-9]{32})\/?$/);
const id=match?.[1];
let frame=null, stream=null, image=null, imageKey='', lastFrame=0, ended=false, weapons={};
let rosterKey='';
const avatars=new Map();
function publicSteamId(value) {
  if(typeof value!=='string'||!/^7656[0-9]{13}$/.test(value))return '';
  const id=BigInt(value),base=76561197960265728n;
  return id>base&&id<=base+0xffffffffn?value:'';
}
const weaponName=id=>weapons[id]??(id?`Weapon ${id}`:'â€”');
fetch('/web-radar/weapons.json').then(r=>r.ok?r.json():{}).then(data=>{weapons=data;rosterKey='';render();}).catch(()=>{});
function state(title,description,connection='Waiting') {
  $('state-panel').hidden=false;$('state-title').textContent=title;$('state-description').textContent=description;
  $('status').textContent=connection;$('status-dot').className='';
  frame=null;rosterKey='';imageKey='';image=null;render();
  $('map-name').textContent='Your match, in view.';$('map-label').textContent='SCOOBY / RADAR';
  $('entity-count').textContent='Host-powered radar';$('freshness').textContent='No live data';
}
function paintAvatar(card) {
  const image=avatars.get(card.dataset.steamId),img=card.querySelector('.steam-avatar');
  if(!image||img.dataset.image===image)return;
  img.dataset.image=image;img.src=image;
}
function receiveAvatar(data) {
  if(ended||!frame)return;
  let a;try{a=JSON.parse(data);}catch{return;}
  if(!a||!publicSteamId(a.steamId)||!frame.entities.some(e=>e.kind===0&&e.steamId===a.steamId)||
     typeof a.image!=='string'||a.image.length>6000||!/^data:image\/png;base64,iVBORw0KGgo[A-Za-z0-9+/]*={0,2}$/.test(a.image))return;
  avatars.set(a.steamId,a.image);
  for(const card of document.querySelectorAll('.player'))if(card.dataset.steamId===a.steamId)paintAvatar(card);
}
function roster(team,el) {
  const players=frame?.entities.filter(e=>e.kind===0&&e.team===team).sort((a,b)=>a.id-b.id)??[];
  $(team===2?'t-alive':'ct-alive').textContent=players.length ? `${players.filter(e=>e.alive).length} / ${players.length}` : '—';
  if(!players.length) {
    el.replaceChildren();const p=document.createElement('p');p.className='empty-roster';
    p.textContent='Waiting for players';el.append(p);return;
  }
  el.querySelector('.empty-roster')?.remove();
  const cards=new Map([...el.children].map(card=>[Number(card.dataset.id),card]));
  for(const card of cards.values())if(!players.some(e=>e.id===Number(card.dataset.id)))card.remove();
  players.forEach((e,index)=>{
    let card=cards.get(e.id);
    if(!card) {
      card=document.createElement('article');card.dataset.id=e.id;
      // Static markup only; every publisher string is assigned with textContent.
      card.innerHTML='<div class="player-title"><span class="you"></span></div><div class="player-stats"><span class="hp"></span><span class="armor"></span><span class="money"></span></div><div class="health"><span></span></div><div class="loadout"><span class="weapon"></span><span class="bomb-tag"></span></div>';
    }
    card.className=`player${e.alive?'':' dead'}`;
    const steamId=publicSteamId(e.steamId);
    if(card.dataset.steamId!==steamId) {
      card.dataset.steamId=steamId;
      const profile=document.createElement(steamId?'a':'div');profile.className='player-profile';
      profile.innerHTML='<span class="avatar"><svg class="avatar-fallback" viewBox="0 0 32 32" aria-hidden="true"><circle cx="16" cy="11" r="5"/><path d="M6 29v-3a10 10 0 0 1 20 0v3z"/></svg><img class="steam-avatar" width="32" height="32" alt="" hidden><span class="player-number" aria-hidden="true"></span></span><span class="profile-copy"><span class="player-name"></span><span class="profile-hint"></span></span>';
      if(steamId) {profile.href=`https://steamcommunity.com/profiles/${steamId}/`;profile.target='_blank';profile.rel='noopener noreferrer';}
      profile.querySelector('.profile-hint').textContent=steamId?'Steam profile \u2197':'No Steam profile';
      const img=profile.querySelector('.steam-avatar'),fallback=profile.querySelector('.avatar-fallback');
      img.onload=()=>{img.hidden=false;fallback.setAttribute('hidden','');};
      img.onerror=()=>{img.hidden=true;fallback.removeAttribute('hidden');};
      card.querySelector('.player-profile')?.remove();card.querySelector('.player-title').prepend(profile);
    }
    const set=(selector,value)=>card.querySelector(selector).textContent=value;
    set('.player-number',String(e.id).padStart(2,'0'));set('.player-name',e.name||'Player');set('.you',e.local?'HOST':'');
    card.querySelector('.player-name').title=e.name;
    if(steamId)card.querySelector('.player-profile').setAttribute('aria-label',`Open ${e.name||'player'} on Steam (new tab)`);
    set('.hp',e.alive?`${e.health} HP`:'ELIMINATED');set('.armor',`${e.armor} AR`);set('.money',`$${e.money.toLocaleString()}`);
    card.querySelector('.health span').style.width=`${Math.min(100,Math.max(0,e.health))}%`;
    set('.weapon',weaponName(e.weapon));set('.bomb-tag',e.bomb?'C4':'');paintAvatar(card);
    // Avoid replacing focused links or reloading images on every stat update.
    if(el.children[index]!==card)el.insertBefore(card,el.children[index]??null);
  });
}
function render() {
  const base=frame?.map??'';
  const chosen=$('floor').value;
  const hasFloors=['de_nuke','de_train','de_vertigo','ar_baggage'].includes(base);
  $('floor').disabled=!hasFloors;
  const key=frame ? (chosen==='auto'?frame.layer:(hasFloors&&chosen==='lower'?`${base}_lower`:base)) : '';
  if(key!==imageKey) {
    imageKey=key;image=null;$('map-warning').hidden=true;
    if(key && /^[a-zA-Z0-9_-]+$/.test(key)) {
      const loading=new Image();
      loading.onload=()=>{if(imageKey===key){image=loading;render();}};
      loading.onerror=()=>{if(imageKey===key){$('map-warning').textContent='Map image unavailable. Positions use the hostâ€™s calibration.';$('map-warning').hidden=false;}};
      loading.src=`/web-radar/maps/${key}.png`;
    }
  }
  if(frame&&!frame.calibration?.scale) {$('map-warning').textContent='This map has no overview calibration. Player roster is still live.';$('map-warning').hidden=false;}
  drawRadar($('radar'),frame,image,{names:$('names').checked,drops:$('drops').checked,utility:$('utility').checked,layer:key},weaponName);
  const next=JSON.stringify(frame?.entities.filter(e=>e.kind===0).map(e=>[e.id,e.name,e.alive,e.health,e.armor,e.money,e.weapon,e.bomb,e.team,e.local,e.steamId]));
  if(next!==rosterKey){rosterKey=next;roster(2,$('t-roster'));roster(3,$('ct-roster'));}
  if(!frame)$('map-warning').hidden=true;
}
function receive(data) {
  if(ended)return;
  let f;try{f=JSON.parse(data);}catch{return;}
  if(f.version!==1||!Array.isArray(f.entities))return;
  lastFrame=performance.now();
  if(f.state!=='live'){avatars.clear();state('Waiting for the next match','The host is between games. This link will reconnect automatically.','Waiting for host');return;}
  const present=new Set(f.entities.filter(e=>e.kind===0).map(e=>e.steamId));
  for(const steamId of avatars.keys())if(!present.has(steamId))avatars.delete(steamId);
  frame=f;$('state-panel').hidden=true;$('status').textContent='Live';$('status-dot').className='live';
  $('map-name').textContent=f.map.replace(/^(de_|cs_|ar_)/,'').replaceAll('_',' ').replace(/\b\w/g,c=>c.toUpperCase());
  $('map-label').textContent=f.map.toUpperCase();
  $('entity-count').textContent=`${f.entities.filter(e=>e.kind===0).length} players`;
  $('footer-status').textContent='Anyone with this link can view. The host controls when sharing ends.';
  render();
}
function finish(reason) {
  ended=true;avatars.clear();stream?.close();$('copy').disabled=true;
  state('This radar has ended',reason==='expired'?'The host disconnected or the session expired. Ask the host for a new link.':'The host stopped sharing. Ask the host for a new link.','Ended');
}
async function connect() {
  if(!id)return;
  $('copy').disabled=false;
  state('Connecting to the host','The radar will appear as soon as the host sends a live match.','Connecting');
  stream=new EventSource(`/web-radar/api/session/${id}/events`);
  stream.addEventListener('frame',e=>receive(e.data));
  stream.addEventListener('avatar',e=>receiveAvatar(e.data));
  stream.addEventListener('status',e=>{let s;try{s=JSON.parse(e.data);}catch{return;}
    if(s.state==='offline')state('Host disconnected','Waiting for the host to reconnect. Old positions have been cleared.','Reconnecting');
    else if(s.state==='waiting')state('Waiting for a match','The host is connected. The radar will start when they join a game.','Waiting for host');
  });
  stream.addEventListener('ended',e=>{let s;try{s=JSON.parse(e.data);}catch{s={};}finish(s.reason);});
  let checking=false;
  stream.onerror=async()=>{
    if(ended)return;
    state('Connection interrupted','Reconnecting to the host. Old positions have been cleared.','Reconnecting');
    if(checking)return;checking=true;
    try {
      // Abort after headers: this endpoint is a stream. Detect ended/full rooms.
      const controller=new AbortController();const timeout=setTimeout(()=>controller.abort(),5000);
      try { const r=await fetch(`/web-radar/api/session/${id}/events`,{signal:controller.signal,cache:'no-store'});
        if(r.status===404||r.status===410)finish('expired');
        if(r.status===429)state('This radar is full','The viewer limit has been reached. Reconnecting shortly.','Viewer limit');
        controller.abort();
      } finally {clearTimeout(timeout);}
    } catch {} finally {checking=false;}
  };
}
new ResizeObserver(render).observe($('radar'));
for(const name of ['floor','names','drops','utility'])$(name).addEventListener('change',render);
$('copy').addEventListener('click',async()=>{
  try{await navigator.clipboard.writeText(`${location.origin}/web-radar/${id}`);$('copy').textContent='Copied';setTimeout(()=>$('copy').textContent='Copy link',1800);}
  catch{$('copy').textContent='Copy from address bar';}
});
$('fullscreen').addEventListener('click',async()=>{
  try{if(document.fullscreenElement)await document.exitFullscreen();else await document.querySelector('.overview').requestFullscreen();}
  catch{$('fullscreen').textContent='Fullscreen unavailable';}
});
document.addEventListener('fullscreenchange',()=>$('fullscreen').textContent=document.fullscreenElement?'Exit fullscreen':'Fullscreen');
setInterval(()=>{
  if(!frame)return;
  const age=performance.now()-lastFrame;
  if(age>3500)state('Waiting for the host','No recent updates. Old positions have been cleared.','Reconnecting');
  else $('freshness').textContent=age<1000?'Updated just now':`Updated ${(age/1000).toFixed(1)}s ago`;
},500);
addEventListener('pagehide',()=>stream?.close());
addEventListener('pageshow',e=>{if(e.persisted&&!ended)connect();});
connect();
