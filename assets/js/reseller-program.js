/* Shared calculation core: GBP pence, with each discounted line rounded once. */
(function(root){
  const BASE = [1500,2500];
  function calculate(quantities,sellPence){
    if(quantities.length!==2 || sellPence.length!==2 || ![...quantities,...sellPence].every(Number.isSafeInteger) || quantities.some(n=>n<0||n>1000000) || sellPence.some(n=>n<0||n>100000000)) throw new RangeError('Invalid quantity or selling price');
    const count=quantities.reduce((a,b)=>a+b,0), eligible=count>=10;
    const discount=eligible ? 30 + (Math.min(count,1000)-10)*35/990 : 0;
    // Integer ratio avoids floating-point drift at penny boundaries.
    const numerator=eligible ? 69300-(Math.min(count,1000)-10)*35 : 99000;
    const lines=quantities.map((qty,i)=>({qty,unit:BASE[i]*numerator/99000,subtotal:Math.round(BASE[i]*qty*numerator/99000)}));
    const base=quantities.reduce((total,n,i)=>total+n*BASE[i],0), total=lines.reduce((sum,line)=>sum+line.subtotal,0);
    const revenue=quantities.reduce((sum,n,i)=>sum+n*sellPence[i],0);
    return {count,eligible,discount,lines,base,total,revenue,savings:base-total,profit:revenue-total};
  }
  if(typeof module==='object'&&module.exports) module.exports={calculate};
  if(!root.document) return;
  const $=id=>document.getElementById(id), ids=['premium','plus'];
  const money=pence=>new Intl.NumberFormat('en-GB',{style:'currency',currency:'GBP'}).format(pence/100);
  const percentage=n=>new Intl.NumberFormat('en-GB',{maximumFractionDigits:2}).format(n)+'%';
  function update(){
    $('copy-status').textContent='';
    const inputs=ids.flatMap(id=>[$(id+'-qty'),$(id+'-sell')]);
    const valid=inputs.every(el=>el.value.trim()!==''&&el.checkValidity());
    $('copy-order').disabled=true;
    if(!valid){
      $('order-status').textContent='Enter whole key quantities and valid selling prices (zero or more, up to £1,000,000).';
      $('order-status').classList.add('is-error');
      for(const id of ['order-total','retail-total','order-savings','sales-total','order-profit','premium-unit','plus-unit','premium-subtotal','plus-subtotal','premium-count','plus-count','key-count','discount-label']) $(id).textContent='—';
      $('discount-progress').value=0; $('order-text').value='Enter valid quantities and prices to prepare your order.'; return;
    }
    const quantities=ids.map(id=>Number($(id+'-qty').value));
    const sell=ids.map(id=>Math.round(Number($(id+'-sell').value)*100));
    const result=calculate(quantities,sell);
    $('discount-label').textContent=percentage(result.discount)+' discount';
    $('discount-progress').value=result.discount;
    $('key-count').textContent=result.count.toLocaleString('en-GB')+' keys';
    ids.forEach((id,i)=>{ $(id+'-count').textContent=quantities[i].toLocaleString('en-GB')+' keys'; $(id+'-unit').textContent=money(result.lines[i].unit); $(id+'-subtotal').textContent=money(result.lines[i].subtotal); });
    for(const [id,key] of Object.entries({'order-total':'total','retail-total':'base','order-savings':'savings','sales-total':'revenue','order-profit':'profit'})) $(id).textContent=money(result[key]);
    $('order-profit').classList.toggle('negative',result.profit<0);
    $('order-status').textContent=result.eligible?(result.count>=1000?'Maximum 65% discount reached. Larger orders keep this rate.':'Your order qualifies for bulk pricing.'):`Add ${10-result.count} more ${10-result.count===1?'key':'keys'} to reach the 10-key minimum.`;
    $('order-status').classList.toggle('is-error',!result.eligible);
    $('copy-order').disabled=!result.eligible;
    $('order-text').value=result.eligible?[
      'Scooby GTA 5 reseller order — GBP',
      ...ids.map((id,i)=>`${id==='plus'?'Plus':'Premium'}: ${quantities[i]} keys | subtotal ${money(result.lines[i].subtotal)} | my selling price ${money(sell[i])}/key`),
      `Total keys: ${result.count}`,`Bulk discount: ${percentage(result.discount)} (rounded for display)`,`Estimated order total: ${money(result.total)} GBP`,
      'Payment: BTC or LTC only. Please confirm the crypto amount and payment details.',
      `Potential sales revenue: ${money(result.revenue)}`,`Estimated gross profit before fees and taxes: ${money(result.profit)}`
    ].join('\n'):'Minimum order: 10 keys. Add more keys to prepare your order summary.';
  }
  ids.forEach(id=>['qty','sell'].forEach(suffix=>$(id+'-'+suffix).addEventListener('input',update)));
  $('copy-order').addEventListener('click',async()=>{
    if($('copy-order').disabled) return;
    try{await navigator.clipboard.writeText($('order-text').value);$('copy-status').textContent='Copied. Send your order summary to us on Discord.';}
    catch{ $('order-text-details').open=true; $('order-text').focus(); $('order-text').select(); $('copy-status').textContent='Select and copy the order summary below.'; }
  });
  update();
})(typeof window==='undefined'?globalThis:window);
