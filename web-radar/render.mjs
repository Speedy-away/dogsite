export function project(e,c) {
  if(!c || !(c.scale>0) || !(c.size>0)) return null;
  return [.5+((e.x-c.x)/(c.scale*c.size)-.5)*c.zoom+c.offsetX,
    .5+((c.y-e.y)/(c.scale*c.size)-.5)*c.zoom+c.offsetY];
}
export function floorFor(map,z) {
  const cut={de_nuke:-495,de_train:-50,de_vertigo:11700,ar_baggage:-5}[map];
  return cut!==undefined && z<=cut ? `${map}_lower` : map;
}
export function drawRadar(canvas,frame,image,options,weaponName) {
  const ctx=canvas.getContext('2d'), side=1024;
  const screenSide=Math.max(250,Math.min(canvas.clientWidth,canvas.clientHeight));
  const ui=Math.max(1,Math.min(3,side/screenSide));
  ctx.clearRect(0,0,side,side);
  if(!frame || frame.state!=='live') return;
  if(image?.complete && image.naturalWidth) {
    ctx.globalAlpha=.85; ctx.drawImage(image,0,0,side,side); ctx.globalAlpha=1;
  }
  const c=frame.calibration;
  if(!c?.scale) return;
  const label=(text,x,y,color='#eaf1f8',size=15)=>{
    ctx.font=`600 ${size*ui}px "Segoe UI",sans-serif`;ctx.textAlign='center';ctx.lineWidth=3*ui;
    ctx.strokeStyle='#080a0e';ctx.strokeText(text,x,y);ctx.fillStyle=color;ctx.fillText(text,x,y);
  };
  for(const e of frame.entities) {
    if(e.kind===0 || (e.kind===6&&!options.drops) || ([3,4,5].includes(e.kind)&&!options.utility)) continue;
    const uv=project(e,c); if(!uv) continue;
    const [x,y]=uv.map(v=>v*side);
    const color=e.kind===3?'#b5cbd6':e.kind===4?'#ff9862':e.kind===1||e.kind===2?'#ffc08c':'#e4e7eb';
    ctx.save();ctx.strokeStyle=color;ctx.fillStyle=color;
    if((e.kind===3||e.kind===4)&&e.radius>0) {
      const r=e.radius/(c.scale*c.size)*c.zoom*side;
      ctx.globalAlpha=.22;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();
      ctx.globalAlpha=.7;ctx.lineWidth=2;ctx.stroke();ctx.globalAlpha=1;
    }
    if(e.kind===1||e.kind===2) {
      ctx.fillStyle='#251c16';ctx.fillRect(x-17*ui,y-12*ui,34*ui,23*ui);label('C4',x,y+5*ui,color,14);
      if(e.kind===1) label(`${e.defusing?'DEFUSING Â· ':''}${e.timer>=0?e.timer.toFixed(1)+'s':'PLANTED'}`,x,y+27*ui,color,11);
    } else if(e.kind===6) {
      ctx.translate(x,y);ctx.rotate(Math.PI/4);ctx.lineWidth=2;ctx.strokeRect(-5,-5,10,10);ctx.rotate(-Math.PI/4);
      label(weaponName(e.weapon),0,22*ui,color,10);
    } else if(e.kind===5) {
      ctx.beginPath();ctx.arc(x,y,5,0,Math.PI*2);ctx.fill();
      label(['GRENADE','HE','FLASH','SMOKE','FIRE','DECOY'][e.grenade]||'GRENADE',x,y-12*ui,color,10);
    } else if(e.kind===7) label('H',x,y,color,18);
    ctx.restore();
  }
  for(const e of frame.entities) {
    if(e.kind!==0||!e.alive) continue;
    const uv=project(e,c); if(!uv) continue;
    const [x,y]=uv.map(v=>v*side), color=e.team===2?'#e6bb69':'#72c5f3';
    ctx.save();
    if(options.layer && floorFor(frame.map,e.z)!==options.layer) ctx.globalAlpha=.35;
    ctx.translate(x,y);ctx.rotate(-e.yaw*Math.PI/180);
    ctx.fillStyle=color;ctx.globalAlpha*=.18;ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(42,-20);ctx.lineTo(42,20);ctx.closePath();ctx.fill();ctx.globalAlpha/= .18;
    ctx.beginPath();ctx.moveTo(19,0);ctx.lineTo(8,-5);ctx.lineTo(8,5);ctx.closePath();ctx.fill();
    ctx.rotate(e.yaw*Math.PI/180);ctx.lineWidth=(e.local?3:2)*ui;ctx.strokeStyle=e.local?'#ffffff':'#080a0e';
    ctx.beginPath();ctx.arc(0,0,8*ui,0,Math.PI*2);ctx.fill();ctx.stroke();
    label(String(e.id),0,3*ui,'#0c121a',10);
    if(options.names) label(screenSide<500?e.name.slice(0,10):e.name,0,-17*ui,'#edf2f7',11);
    if(e.bomb) label('C4',0,24*ui,'#ffc08c',10);
    ctx.restore();
  }
}
