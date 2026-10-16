const test=require('node:test'),assert=require('node:assert/strict');
const {calculate,basePrices,sellingPrices}=require('../assets/js/reseller-program.js');
const {zip,crc32}=require('./build-reseller-media.cjs');
const base=basePrices();
const quantities=n=>[n,0,0,0,0];
test('discount milestones, smooth segments, mixed products and cap',()=>{
 assert.equal(calculate(quantities(9),base).eligible,false);
 for(const [keys,rate] of [[10,25],[30,32.5],[50,40],[525,52.5],[1000,65],[1001,65]]) assert.equal(calculate(quantities(keys),base).discount,rate);
 assert.equal(calculate(quantities(10),base).total,11250);
 assert.equal(calculate(quantities(50),base).total,45000);
 const mixed=calculate([2,2,2,2,2],base);
 assert.equal(mixed.count,10);assert.equal(mixed.base,18000);assert.equal(mixed.total,13500);
 assert.deepEqual(mixed.lines.map(line=>line.subtotal),[2250,3750,1500,2250,3750]);
});
test('Brazil reduction is applied before volume discounts; presets use regional base',()=>{
 assert.deepEqual(basePrices('brazil'),[1200,2000,800,1200,2000]);
 assert.deepEqual(sellingPrices('brazil',10),[1320,2200,880,1320,2200]);
 const br=calculate(quantities(10),sellingPrices('brazil',25),'brazil');
 assert.equal(br.base,12000);assert.equal(br.total,9000);assert.equal(br.revenue,15000);assert.equal(br.profit,6000);
 assert.equal(calculate(quantities(1000),basePrices('brazil'),'brazil').total,420000);
 assert.equal(calculate(quantities(10),sellingPrices('standard',10)).profit,5250);
 assert.equal(calculate(quantities(10),sellingPrices('standard',25)).profit,7500);
});
test('custom selling prices affect revenue only; invalid entries rejected',()=>{
 const cheap=[100,2500,1000,1500,2500];
 assert.ok(calculate(quantities(10),cheap).profit<0);
 assert.equal(calculate(quantities(10),cheap).total,calculate(quantities(10),base).total);
 for(const qty of [-1,1.2,Infinity,NaN,1000001])assert.throws(()=>calculate(quantities(qty),base));
 assert.throws(()=>calculate([10,0],[1500,2500]));
 assert.throws(()=>calculate(quantities(10),base,'unknown'));
 assert.throws(()=>sellingPrices('standard',-10));
});
test('ZIP entries roundtrip with valid deflate payload and CRC',()=>{
 const data=Buffer.from('Scooby media pack'),archive=zip([['products/gta5/test.txt',data]]);
 assert.equal(archive.readUInt32LE(0),0x04034b50);
 const length=archive.readUInt16LE(26),size=archive.readUInt32LE(18);
 assert.deepEqual(require('zlib').inflateRawSync(archive.subarray(30+length,30+length+size)),data);
 assert.equal(archive.readUInt32LE(14),crc32(data));
});
