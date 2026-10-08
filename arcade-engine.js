// Deterministic scenes and Plinko paths shared with the authenticated server.
function arcadeRandom(seed){let v=seed>>>0;return()=>{v=(Math.imul(v,1664525)+1013904223)>>>0;return v/4294967296;};}
const arcadePots=[12,3,1.2,.6,.35,.6,1.2,3,12];
const arcadeLadder=[0,.35,.6,.9,1.2,1.6,2.2,3,4.5];
function arcadeOutcome(game,seed,options={}){const r=arcadeRandom(seed);
 if(game==='plinko'){const count=[1,2,3].includes(options.balls)?options.balls:1,discount=count===1?1:count===2?.9:.8;const paths=Array.from({length:count},()=>Array.from({length:8},()=>r()<.5?0:1));const bins=paths.map(p=>p.reduce((a,b)=>a+b,0));return{paths,bins,balls:count,discount,multi:Math.round(bins.reduce((a,b)=>a+arcadePots[b],0)/count*discount*10000)/10000};}
 if(game==='mecha'){const mirror=!!(seed&1);const boxes=[[.105,.145,.052,.093],[.376,.106,.046,.067],[.608,.205,.033,.083],[.864,.123,.049,.081],[.171,.598,.042,.105],[.419,.665,.027,.117],[.658,.564,.044,.147],[.868,.714,.049,.101]];return{sceneSeed:seed,mirror,targets:boxes.map(([u,v,w,h],id)=>({id,u:mirror?1-u-w:u,v,w,h})),multi:0};}
 if(game==='sahur'){const names=['lantern','drum','dome','dates','parcel','moon','soup','book'];const grid=Array.from({length:5},()=>Array.from({length:3},()=>{const v=r();return v<.025?'wild':names[Math.min(7,Math.floor((v-.025)/.975*8))];}));let multi=0,line=null;for(const path of [[0,0,0,0,0],[1,1,1,1,1],[2,2,2,2,2],[0,1,2,1,0],[2,1,0,1,2]]){const target=path.map((row,c)=>grid[c][row]).find(s=>s!=='wild')||'wild';let n=0;for(let c=0;c<5;c++){const s=grid[c][path[c]];if(s!==target&&s!=='wild')break;n++;}const pay=n>=5?18:n===4?6:n===3?2:0;if(pay>multi){multi=pay;line=path.slice(0,n);}}return{grid,multi,line};}
 if(game==='fishing'){const value=r(),fish=value<.36?0:value<.66?1:value<.84?2:value<.94?3:value<.99?4:5;return{fish,names:['Tilápia','Pargo','Atum','Peixe-vela','Arraia mística','Tesouro submerso'],multi:[.4,.75,1.2,2.2,4,7][fish],bite:2+r()*2,window:1.25};}
 throw Error('Jogo desconhecido');
}

