import {deflateSync} from 'node:zlib';

// Public individual desktop accounts only. Keep IDs as strings across JSON.
export function publicSteamId(value) {
  if(typeof value!=='string' || !/^7656[0-9]{13}$/.test(value)) return false;
  const id=BigInt(value), base=76561197960265728n;
  return id>base && id<=base+0xffffffffn;
}
export function validateAvatars(input,entities) {
  if(input===undefined) return [];
  if(!Array.isArray(input) || input.length>2) return null;
  const roster=new Set(entities.filter(e=>e.kind===0).map(e=>e.steamId)),seen=new Set();
  const updates=[];
  for(const a of input) {
    if(!a || !publicSteamId(a.steamId) || !roster.has(a.steamId) || seen.has(a.steamId) ||
       typeof a.rgba!=='string' || a.rgba.length!==5464 || !/^[A-Za-z0-9+/]{5462}==$/.test(a.rgba)) return null;
    const pixels=Buffer.from(a.rgba,'base64');
    if(pixels.length!==4096 || pixels.toString('base64')!==a.rgba) return null;
    seen.add(a.steamId);updates.push({steamId:a.steamId,rgba:a.rgba});
  }
  return updates;
}
const crcTable=Uint32Array.from({length:256},(_,i)=>{
  for(let bit=0;bit<8;++bit) i=(i&1)?0xedb88320^(i>>>1):i>>>1;
  return i>>>0;
});
function chunk(type,data) {
  const body=Buffer.concat([Buffer.from(type),data]),out=Buffer.alloc(body.length+8);
  let crc=0xffffffff;
  for(const byte of body) crc=crcTable[(crc^byte)&255]^(crc>>>8);
  out.writeUInt32BE(data.length);body.copy(out,4);out.writeUInt32BE((crc^0xffffffff)>>>0,out.length-4);
  return out;
}
// Fixed 32x32 RGBA input: no external URLs, image decoders or publisher metadata.
export function avatarPng(rgba) {
  const pixels=Buffer.from(rgba,'base64');
  if(pixels.length!==4096) throw new RangeError('Expected 32x32 RGBA pixels');
  const header=Buffer.alloc(13);header.writeUInt32BE(32);header.writeUInt32BE(32,4);header[8]=8;header[9]=6;
  const scanlines=Buffer.alloc(32*129);
  for(let y=0;y<32;++y) pixels.copy(scanlines,y*129+1,y*128,(y+1)*128);
  const png=Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),
    chunk('IDAT',deflateSync(scanlines)),chunk('IEND',Buffer.alloc(0))]);
  return `data:image/png;base64,${png.toString('base64')}`;
}
