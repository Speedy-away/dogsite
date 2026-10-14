const test=require('node:test'),assert=require('node:assert/strict');
const {calculate}=require('../assets/js/reseller-program.js');
const {zip,crc32}=require('./build-reseller-media.cjs');
test('minimum, smooth curve, mixed editions and 65% cap',()=>{
 assert.equal(calculate([9,0],[1500,2500]).eligible,false);
 const first=calculate([10,0],[1500,2500]);assert.equal(first.discount,30);assert.equal(first.total,10500);assert.equal(first.profit,4500);
 const mixed=calculate([5,5],[1500,2500]);assert.equal(mixed.total,14000);assert.equal(mixed.count,10);
 assert.equal(calculate([505,0],[1500,2500]).discount,47.5);
 for(const q of [1000,1001,2000])assert.equal(calculate([q,0],[1500,2500]).discount,65);
 assert.equal(calculate([1000,0],[1500,2500]).total,525000);
});
test('custom selling prices affect revenue only; losses and invalid entries handled',()=>{
 const a=calculate([10,10],[1000,2000]);assert.equal(a.revenue,30000);assert.equal(a.total,calculate([10,10],[1500,2500]).total);
 assert.ok(calculate([10,0],[100,2500]).profit<0);
 for(const qty of [-1,1.2,Infinity,NaN,1000001])assert.throws(()=>calculate([qty,0],[1500,2500]));
});
test('ZIP entries roundtrip with valid deflate payload and CRC',()=>{
 const data=Buffer.from('Scooby media pack'),archive=zip([['products/gta5/test.txt',data]]);
 assert.equal(archive.readUInt32LE(0),0x04034b50);
 const length=archive.readUInt16LE(26),size=archive.readUInt32LE(18);
 assert.deepEqual(require('zlib').inflateRawSync(archive.subarray(30+length,30+length+size)),data);
 assert.equal(archive.readUInt32LE(14),crc32(data));
});

