import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {createRadarServer,validateFrame} from './server.mjs';
import {project,floorFor} from '../render.mjs';

export const marker=(id=1,kind=0)=>({id,kind,team:2,x:100,y:-200,z:0,yaw:90,health:100,armor:50,money:1000,weapon:7,grenade:0,radius:0,timer:-1,alive:true,local:false,bomb:false,defusing:false,name:'Test player'});
export const fixture=(seq=1)=>({version:1,seq,state:'live',keepLink:true,map:'de_mirage',layer:'de_mirage',calibration:{x:-3230,y:1713,scale:5,size:1024,offsetX:0,offsetY:0,zoom:1},entities:[marker()]});
test('schema excludes unknown fields, rejects invalid coordinates, paths and duplicate entities',()=>{
  const f=fixture();f.secret='must not be relayed';f.entities[0].token='private';
  assert.equal(validateFrame(f).secret,undefined);assert.equal(validateFrame(f).entities[0].token,undefined);
  for(const bad of [NaN,Infinity,'1']) {const v=fixture();v.entities[0].x=bad;assert.equal(validateFrame(v),null);}
  const invalid=fixture();invalid.map='../../secret';assert.equal(validateFrame(invalid),null);
  const dup=fixture();dup.entities.push(marker());assert.equal(validateFrame(dup),null);
  const waiting=fixture();waiting.state='waiting';assert.equal(validateFrame(waiting),null);
  const oversize=fixture();oversize.entities=Array.from({length:513},(_,i)=>marker(i));assert.equal(validateFrame(oversize),null);
});
test('same canonical projection and split floors',()=>{
  const c=fixture().calibration;
  assert.deepEqual(project({x:-3230,y:1713},c),[0,0]);
  assert.deepEqual(project({x:-670,y:-847},c),[.5,.5]);
  assert.deepEqual(project({x:-670,y:-847},{...c,offsetX:.1,offsetY:-.2}),[.6,.3]);
  assert.equal(project({x:0,y:0},{...c,scale:0}),null);
  assert.equal(floorFor('de_nuke',-496),'de_nuke_lower');
  assert.equal(floorFor('de_nuke',-494),'de_nuke');
  assert.equal(floorFor('de_vertigo',11600),'de_vertigo_lower');
});

test('authenticated publishing, real SSE, stale clearing, transitions and revocation',async t=>{
  let clock=100000;
  const app=createRadarServer({now:()=>clock});
  await new Promise(r=>app.server.listen(0,'127.0.0.1',r));
  t.after(()=>{app.closeAll();app.server.closeAllConnections();app.server.close();});
  const base=`http://127.0.0.1:${app.server.address().port}`;
  const id=randomBytes(16).toString('hex'), token=randomBytes(32).toString('hex');
  const endpoint=`${base}/web-radar/api/session/${id}`;
  const publish=(method='POST',f=fixture(),key=token,extra={})=>fetch(endpoint,{method,headers:{'Content-Type':'application/json',Authorization:`Bearer ${key}`,...extra},body:method==='DELETE'?undefined:JSON.stringify(f)});
  assert.equal((await publish('PUT',fixture(),'bad')).status,401);
  assert.equal((await publish('PUT')).status,204);
  assert.equal((await publish('POST',fixture(2),'a'.repeat(64))).status,403);
  assert.equal((await publish('DELETE',fixture(),'b'.repeat(64))).status,403);
  assert.equal((await publish('POST',fixture(2),token,{Origin:'https://hostile.example'})).status,403);
  const ac=new AbortController();t.after(()=>ac.abort());
  const response=await fetch(endpoint+'/events',{signal:ac.signal});
  assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');
  const reader=response.body.getReader();let pending='';
  async function until(needle) {
    const timer=setTimeout(()=>ac.abort(),4000);
    try{while(!pending.includes(needle)){const r=await reader.read();assert.equal(r.done,false);pending+=new TextDecoder().decode(r.value);}
      const result=pending;pending='';return result;
    }finally{clearTimeout(timer);}
  }
  assert.match(await until('Test player'),/event: frame/);
  assert.equal((await publish('POST',fixture(2))).status,429);
  clock+=100;assert.equal((await publish('POST',fixture(1))).status,409);
  const update=fixture(2);update.entities.push({...marker(200,3),radius:144});
  assert.equal((await publish('POST',update)).status,204);
  assert.match(await until('"radius":144'),/"kind":3/);
  clock+=100;const waiting={...fixture(3),state:'waiting',map:'',layer:'',entities:[]};
  assert.equal((await publish('POST',waiting)).status,204);
  assert.match(await until('"state":"waiting"'),/"entities":\[\]/);
  clock+=100;const next=fixture(4);next.map=next.layer='ar_shoots';
  assert.equal((await publish('POST',next)).status,204);
  assert.match(await until('ar_shoots'),/event: frame/);
  clock+=3100;app.sweep();
  assert.match(await until('offline'),/event: status/);
  assert.equal(app.rooms.get(id).frame,null);
  clock+=100;assert.equal((await publish('POST',fixture(5))).status,204);
  await until('"seq":5');
  assert.equal((await publish('DELETE')).status,204);
  assert.match(await until('stopped'),/event: ended/);
  assert.equal((await fetch(endpoint+'/events')).status,410);
  assert.equal((await publish('PUT',fixture(6))).status,410);
  assert.equal((await fetch(base+'/web-radar/relay/server.mjs')).status,404);
  assert.equal((await fetch(base+'/web-radar/'+id)).status,200);
});

test('expiry, bounded rooms, viewer limit and creation limits',async t=>{
  let clock=10000;const app=createRadarServer({now:()=>clock,maxRooms:1,maxViewers:1});
  await new Promise(r=>app.server.listen(0,'127.0.0.1',r));
  t.after(()=>{app.closeAll();app.server.closeAllConnections();app.server.close();});
  const base=`http://127.0.0.1:${app.server.address().port}/web-radar/api/session/`;
  const token='b'.repeat(64), id='a'.repeat(32);
  const put=id=>fetch(base+id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(fixture())});
  assert.equal((await put(id)).status,204);assert.equal((await put('c'.repeat(32))).status,429);
  const ac=new AbortController();t.after(()=>ac.abort());
  assert.equal((await fetch(base+id+'/events',{signal:ac.signal})).status,200);
  assert.equal((await fetch(base+id+'/events')).status,429);
  clock+=30001;app.sweep();assert.equal(app.rooms.size,0);
  assert.equal((await fetch(base+id+'/events')).status,410);
});


test('oversized bodies, malformed data, methods and concurrent ownership are rejected',async t=>{
  const app=createRadarServer();await new Promise(r=>app.server.listen(0,'127.0.0.1',r));
  t.after(()=>{app.closeAll();app.server.closeAllConnections();app.server.close();});
  const root=`http://127.0.0.1:${app.server.address().port}/web-radar/api/session/`;
  const headers={'Content-Type':'application/json',Authorization:`Bearer ${'d'.repeat(64)}`};
  assert.equal((await fetch(root+'e'.repeat(32),{method:'PUT',headers,body:'{bad'})).status,400);
  assert.equal((await fetch(root+'f'.repeat(32),{method:'PUT',headers,body:JSON.stringify({padding:'x'.repeat(270000)})})).status,413);
  assert.equal((await fetch(root+'1'.repeat(32),{method:'PUT',headers:{Authorization:headers.Authorization},body:'x'})).status,415);
  assert.equal((await fetch(root+'2'.repeat(32),{method:'PATCH',headers})).status,405);
  const id='3'.repeat(32);
  const attempts=await Promise.all(['a','b'].map(c=>fetch(root+id,{method:'PUT',headers:{...headers,Authorization:`Bearer ${c.repeat(64)}`},body:JSON.stringify(fixture())})));
  assert.deepEqual(attempts.map(r=>r.status).sort(),[204,403]);
});

test('waiting sessions expire and viewer links never contain the publisher key',async t=>{
  let clock=1000;const app=createRadarServer({now:()=>clock,idleMs:1000});
  await new Promise(r=>app.server.listen(0,'127.0.0.1',r));
  t.after(()=>{app.closeAll();app.server.closeAllConnections();app.server.close();});
  const token='d'.repeat(64),id='e'.repeat(32),url=`http://127.0.0.1:${app.server.address().port}/web-radar/api/session/${id}`;
  const f={...fixture(),state:'waiting',entities:[],map:'',layer:''};
  assert.equal((await fetch(url,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify(f)})).status,204);
  assert.equal(JSON.stringify(app.rooms.get(id).frame).includes(token),false);
  clock+=1001;app.sweep();assert.equal((await fetch(url+'/events')).status,410);
});
