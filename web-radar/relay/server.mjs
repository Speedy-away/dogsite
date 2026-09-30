import http from 'node:http';
import { timingSafeEqual, createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import {publicSteamId,validateAvatars,avatarPng} from './avatars.mjs';

const ID = '[a-f0-9]{32}';
const route = new RegExp(`^/web-radar/api/session/(${ID})(/events)?$`);
const sessionPage = new RegExp(`^/web-radar/(${ID})/?$`);
const keyPattern = /^Bearer ([a-f0-9]{64})$/;
const text = (v, n) => typeof v === 'string' && v.length <= n;
const number = (v, min, max) => typeof v === 'number' && Number.isFinite(v) && v >= min && v <= max;
const integer = (v, min, max) => Number.isInteger(v) && number(v, min, max);
const bool = v => typeof v === 'boolean';
const mapName = v => text(v,64) && /^[a-zA-Z0-9_-]*$/.test(v);

export function validateFrame(f) {
  if (!f || f.version !== 1 || !integer(f.seq,1,Number.MAX_SAFE_INTEGER) ||
      !['live','waiting'].includes(f.state) || !bool(f.keepLink) || !mapName(f.map) || !mapName(f.layer) ||
      !Array.isArray(f.entities) || f.entities.length > 512 || (f.state === 'waiting' && f.entities.length)) return null;
  const c = f.calibration;
  if (!c || !number(c.x,-100000,100000) || !number(c.y,-100000,100000) || !number(c.scale,0,100) ||
      !integer(c.size,1,8192) || !number(c.offsetX,-10,10) || !number(c.offsetY,-10,10) || !number(c.zoom,0.05,10)) return null;
  const entities = [];
  const ids = new Set();
  for (const e of f.entities) {
    if (!e || !integer(e.id,0,20000) || ids.has(e.id) || !integer(e.kind,0,7) || !integer(e.team,0,3) ||
        !number(e.x,-100000,100000) || !number(e.y,-100000,100000) || !number(e.z,-100000,100000) ||
        !number(e.yaw,-10000,10000) || !integer(e.health,0,10000) || !integer(e.armor,0,10000) ||
        !integer(e.money,0,1000000) || !integer(e.weapon,0,65535) || !integer(e.grenade,0,5) ||
        !number(e.radius,0,10000) || !number(e.timer,-1000,1000) || !text(e.name,64) ||
        !bool(e.alive) || !bool(e.local) || !bool(e.bomb) || !bool(e.defusing)) return null;
    const steamId=e.steamId ?? '';
    if(steamId!=='' && (e.kind!==0 || !publicSteamId(steamId))) return null;
    ids.add(e.id);
    // Pick known fields; never relay arbitrary publisher JSON or credentials.
    entities.push(Object.fromEntries(['id','kind','team','x','y','z','yaw','health','armor','money','weapon',
      'grenade','radius','timer','alive','local','bomb','defusing','name'].map(k=>[k,e[k]])));
    entities.at(-1).steamId=steamId;
  }
  if(entities.filter(e=>e.kind===0).length>64) return null;
  const avatars=validateAvatars(f.avatars,entities);
  if(!avatars) return null;
  return {version:1,seq:f.seq,state:f.state,keepLink:f.keepLink,map:f.map,layer:f.layer,
    calibration:Object.fromEntries(['x','y','scale','size','offsetX','offsetY','zoom'].map(k=>[k,c[k]])),entities,avatars};
}

export function createRadarServer(options = {}) {
  const root = options.root ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const siteRoot = path.dirname(root);
  const now = options.now ?? Date.now;
  const staleMs = options.staleMs ?? 3000, expireMs = options.expireMs ?? 30000;
  const idleMs = options.idleMs ?? 30*60*1000, lifetimeMs = options.lifetimeMs ?? 12*60*60*1000;
  const maxRooms = options.maxRooms ?? 200, maxViewers = options.maxViewers ?? 32;
  const maxTotalViewers = options.maxTotalViewers ?? 256;
  const rooms = new Map(), tombstones = new Map(), limits = new Map();
  const allowedOrigins = new Set(options.origins ?? ['https://scoobymenu.cc','https://www.scoobymenu.cc']);
  const security = {'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer',
    'X-Robots-Tag':'noindex, nofollow','Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"};
  const reply = (res,code,message) => { res.writeHead(code,{...security,'Content-Type':'application/json'}); res.end(message ? JSON.stringify({error:message}) : undefined); };
  function event(res, name, value) {
    if(res.destroyed || res.writableEnded) return;
    // Slow readers are disconnected instead of growing an unbounded queue.
    if(res.writableLength > 512*1024) { res.destroy(); return; }
    res.write(`event: ${name}\ndata: ${JSON.stringify(value)}\n\n`);
  }
  function broadcast(room, name, value) { for(const res of room.viewers) event(res,name,value); }
  function close(id, reason) {
    const room=rooms.get(id); if(!room) return;
    broadcast(room,'ended',{reason});
    for(const res of room.viewers) res.end();
    rooms.delete(id);
    tombstones.set(id,now()+lifetimeMs);
    if(tombstones.size>10000) tombstones.delete(tombstones.keys().next().value);
  }
  function sweep() {
    const t=now();
    for(const [id,r] of rooms) {
      if(t-r.lastSeen>=expireMs || t-r.lastLive>=idleMs || t-r.created>=lifetimeMs) { close(id,'expired'); continue; }
      if(t-r.lastSeen>=staleMs && !r.stale) {
        r.stale=true; r.frame=null;
        broadcast(r,'status',{state:'offline'});
      }
    }
    for(const [id,until] of tombstones) if(t>=until) tombstones.delete(id);
    for(const [ip,l] of limits) if(t-l.start>=60000) limits.delete(ip);
  }
  function admit(ip) {
    let l=limits.get(ip);
    if(!l || now()-l.start>=60000) {
      if(limits.size>=10000) return false;
      limits.set(ip,l={start:now(),count:0});
    }
    return ++l.count<=10;
  }
  async function body(req) {
    if(Number(req.headers['content-length'] ?? 0)>256*1024) throw 413;
    let size=0; const chunks=[];
    for await(const chunk of req) { size+=chunk.length; if(size>256*1024) throw 413; chunks.push(chunk); }
    try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { throw 400; }
  }
  async function handler(req,res) {
    const url = new URL(req.url,'http://localhost');
    const match = url.pathname.match(route);
    if(match) {
      const [,id,events] = match;
      const origin=req.headers.origin;
      if(origin && !allowedOrigins.has(origin)) return reply(res,403,'Origin not allowed');
      sweep();
      let room=rooms.get(id);
      if(req.method==='GET' && events) {
        if(!room) return reply(res,tombstones.has(id)?410:404,'Session ended or not found');
        if(room.viewers.size>=maxViewers || [...rooms.values()].reduce((n,r)=>n+r.viewers.size,0)>=maxTotalViewers) return reply(res,429,'Viewer limit reached');
        res.writeHead(200,{...security,'Content-Type':'text/event-stream','Connection':'keep-alive','X-Accel-Buffering':'no'});
        res.write('retry: 1500\n\n');
        room.viewers.add(res);
        event(res,'status',{state:room.stale?'offline':room.frame?.state ?? 'waiting'});
        if(room.frame) {
          event(res,'frame',{...room.frame,receivedAt:room.lastSeen});
          for(const [steamId,a] of room.avatars) event(res,'avatar',{steamId,image:a.image});
        }
        res.on('close',()=>room.viewers.delete(res));
        return;
      }
      if(events || !['PUT','POST','DELETE'].includes(req.method)) return reply(res,405,'Method not allowed');
      const token=keyPattern.exec(req.headers.authorization ?? '')?.[1];
      if(!token) return reply(res,401,'Publisher credential required');
      const keyHash=createHash('sha256').update(token).digest();
      if(room && !timingSafeEqual(room.keyHash,keyHash)) return reply(res,403,'Invalid publisher credential');
      if(req.method==='DELETE') { if(room) close(id,'stopped'); return reply(res,204); }
      if(!room && req.method!=='PUT') return reply(res,404,'Session ended');
      if(!room && tombstones.has(id)) return reply(res,410,'Generate a new link');
      if(!req.headers['content-type']?.startsWith('application/json')) return reply(res,415,'JSON required');
      if(!room) {
        // Only trust this header when a loopback-only service is behind the documented proxy.
        const ip=options.trustProxy ? (req.headers['x-forwarded-for'] ?? req.socket.remoteAddress).split(',')[0].trim() : req.socket.remoteAddress;
        if(rooms.size>=maxRooms || !admit(ip) || [...rooms.values()].filter(r=>r.ip===ip).length>=5) return reply(res,429,'Session limit reached');
        room={ip,keyHash,viewers:new Set(),created:now(),lastSeen:now(),lastLive:now(),lastPublish:0,seq:0,stale:false,frame:null,avatars:new Map()};
        // Reserve before awaiting a body so concurrent PUTs cannot replace the owner.
        rooms.set(id,room);
      }
      if(room.pending || (room.lastPublish && now()-room.lastPublish<40)) return reply(res,429,'Publish rate exceeded');
      room.pending=true;
      try {
        const frame=validateFrame(await body(req));
        if(!frame) return reply(res,400,'Invalid snapshot');
        if(rooms.get(id)!==room) return reply(res,410,'Session ended');
        if(frame.seq<=room.seq) return reply(res,409,'Stale snapshot');
        const wasStale=room.stale;
        const present=new Set(frame.entities.filter(e=>e.kind===0).map(e=>e.steamId));
        for(const steamId of room.avatars.keys()) if(!present.has(steamId)) room.avatars.delete(steamId);
        const changed=new Set();
        for(const a of frame.avatars) {
          if(room.avatars.get(a.steamId)?.rgba===a.rgba) continue;
          room.avatars.set(a.steamId,{rgba:a.rgba,image:avatarPng(a.rgba)});changed.add(a.steamId);
        }
        delete frame.avatars;
        room.seq=frame.seq; room.lastSeen=now(); room.lastPublish=now(); room.stale=false;
        if(frame.state==='live') room.lastLive=now();
        room.frame=frame;
        broadcast(room,'frame',{...frame,receivedAt:room.lastSeen});
        for(const steamId of (wasStale?room.avatars.keys():changed))
          broadcast(room,'avatar',{steamId,image:room.avatars.get(steamId).image});
        return reply(res,204);
      } finally { room.pending=false; }
    }
    if(!['GET','HEAD'].includes(req.method)) return reply(res,405,'Method not allowed');
    // Explicit public assets only. Never expose relay source, tests or config.
    let target;
    if(url.pathname==='/web-radar' || url.pathname==='/web-radar/' || sessionPage.test(url.pathname)) target=path.join(root,'index.html');
    else if(/^\/web-radar\/(app\.mjs|radar\.css|render\.mjs|weapons\.json|maps\/[a-z0-9_]+\.png)$/.test(url.pathname)) target=path.join(root,url.pathname.slice('/web-radar/'.length));
    else if(['/assets/css/site-brand.css','/assets/images/brand/scooby-mark.svg','/assets/images/brand/scooby-logo.png'].includes(url.pathname)) target=path.join(siteRoot,url.pathname.slice(1));
    if(!target) return reply(res,404,'Not found');
    try {
      const data=await readFile(target);
      const types={'.html':'text/html; charset=utf-8','.css':'text/css','.mjs':'text/javascript','.json':'application/json','.png':'image/png','.svg':'image/svg+xml'};
      res.writeHead(200,{...security,'Content-Type':types[path.extname(target)],'Content-Length':data.length});
      res.end(req.method==='HEAD'?undefined:data);
    } catch { reply(res,404,'Not found'); }
  }
  const server=http.createServer((req,res)=>handler(req,res).catch(error=>{
    if(!res.headersSent) reply(res,Number.isInteger(error)?error:500,'Request rejected'); else res.destroy();
  }));
  server.requestTimeout=5000; server.headersTimeout=5000; server.keepAliveTimeout=65000;
  const timer=setInterval(sweep,1000); timer.unref();
  const heartbeat=setInterval(()=>{for(const r of rooms.values()) broadcast(r,'heartbeat',{time:now()});},10000); heartbeat.unref();
  server.on('close',()=>{clearInterval(timer);clearInterval(heartbeat);});
  return {server,sweep,rooms,closeAll:()=>{for(const id of rooms.keys())close(id,'server stopped');}};
}

if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const app=createRadarServer({trustProxy:process.env.RADAR_TRUST_PROXY==='1'});
  const port=Number(process.env.PORT ?? 8787);
  app.server.listen(port,'127.0.0.1',()=>console.log(`Web Radar listening on 127.0.0.1:${port}`));
  for(const signal of ['SIGINT','SIGTERM']) process.on(signal,()=>{app.closeAll();app.server.close();});
}
