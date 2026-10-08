let betFlightAnimation=0;
function betSmoothFlight(round){clearInterval(flightTimer);clearInterval(betFlightPoll);cancelAnimationFrame(betFlightAnimation);const id=round.id;let known=1,updated=performance.now(),ended=false,checking=false,connected=true;
 function draw(t){if(ended||!aviatorRound||page!=='aviator')return;betFlightAnimation=requestAnimationFrame(draw);if(document.hidden)return;const gap=Math.min(1500,Math.max(0,t-updated));flight=Math.min(200,known*Math.pow(1.025,gap/120));$('.multiplier').textContent=flight.toFixed(2)+'×';if(!aviatorRound.cashed)$('#cash').textContent='Sacar '+money(stake*flight);window.dispatchEvent(new CustomEvent('flight-update',{detail:{value:flight,active:true}}));}
 async function check(){if(checking||ended||!aviatorRound)return;checking=true;const start=performance.now();try{const status=await api('flight',{round:id});if(!aviatorRound||ended)return;known=status.value;updated=performance.now()-(performance.now()-start)/2;if(!connected){connected=true;message('Conexão restabelecida.');}if(status.ended){ended=true;cancelAnimationFrame(betFlightAnimation);clearInterval(betFlightPoll);flight=status.value;aviatorRound.crash=status.value;endFlight();}}catch(e){if(connected){connected=false;message('Reconectando ao voo…');}}finally{checking=false;}}
 betFlightAnimation=requestAnimationFrame(draw);betFlightPoll=setInterval(check,600);check();
}
const endBeforeSmooth=endFlight;endFlight=function(){cancelAnimationFrame(betFlightAnimation);clearInterval(betFlightPoll);return endBeforeSmooth();};

