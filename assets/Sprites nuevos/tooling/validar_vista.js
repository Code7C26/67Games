
const dirs=['abajo','arriba','derecha','izquierda'],kinds=['atletico','area','exponencial_endgame'];
const names={atletico:'Atlético',area:'De área',exponencial_endgame:'Exponencial'};
const concepts={
 atletico:['Hipertrofia','Casco rojo y cintura estrecha bajo hombros y antebrazos sobredesarrollados.','La musculatura pasa de 26 a 30 píxeles de ancho y vuelve al reposo. El paso firme y la tensión del cuerpo acompañan la expansión.'],
 area:['Fuelles biológicos','Una cabeza humana pequeña se adelanta entre grandes órganos de emisión. Los poros oscuros y las membranas infladas definen su función.','Los lóbulos se abren en fases distintas. Las esporas nacen en sus aperturas, flotan hacia afuera y se desvanecen. La marcha es más lenta y pesada.'],
 exponencial_endgame:['Gemación','Dos cráneos con mandíbula propia, separados por aire, se unen a un torso mediante dos cuellos bifurcados. En los perfiles se escalonan en profundidad.','Cada cabeza se mueve a destiempo. Una cicatriz de división pulsa sobre el pecho y un brazo incompleto emerge del flanco y se reabsorbe.']
};
const $=id=>document.getElementById(id),imgs={},nativeCanvases=[];
let playing=true,timeMs=0,last=performance.now(),loaded=false;
function image(path){return new Promise((resolve,reject)=>{let im=new Image;im.onload=()=>resolve(im);im.onerror=()=>reject(new Error(path));im.src=path})}
function buildNative(){
 const root=$('native');root.append(document.createElement('span'));
 for(let d of dirs){let a=document.createElement('span');a.className='dir';a.textContent=d;root.append(a)}
 for(let k of kinds){let a=document.createElement('span');a.textContent=names[k];root.append(a);for(let d of dirs){let cv=document.createElement('canvas');cv.width=cv.height=32;cv.setAttribute('aria-label',names[k]+' '+d+' 32 por 32');root.append(cv);nativeCanvases.push({k,d,cv})}}
}
function settings(){
 const k=$('kind').value,c=concepts[k];$('conceptTitle').textContent=c[0];$('conceptText').textContent=c[1];$('motionText').textContent=c[2];
 $('oldSize').textContent=k==='exponencial_endgame'?'/ 48 × 32':'/ 32 × 32';
 $('oldNote').textContent=k==='area'?'Original: ocho cuadros por dirección a 10 FPS.':'Original: dos cuadros de frente/espalda y cuatro de perfil, a 5 FPS.';
 $('editable').href='npcs/'+k+'/NPC_2.aseprite';$('godot').href='npcs/'+k+'/NPC2.tres';
 document.body.dataset.bg=$('background').value;
 const scale=+$('zoom').value;
 for(let id of ['old','new']){$(id).width=48*scale;$(id).height=32*scale;$(id).style.width=48*scale+'px';$(id).style.height=32*scale+'px'}
 render();
}
const mask=document.createElement('canvas');mask.width=mask.height=32;
function paint(cv,k,d,frame,newVersion,scale,silhouette=false){
 let ctx=cv.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,cv.width,cv.height);
 let im,sx,sy,w=32;
 if(newVersion){im=imgs[k+'_'+d];sx=(frame%4)*32;sy=Math.floor(frame/4)*32}
 else{
 im=imgs['old_'+k];w=k==='exponencial_endgame'?48:32;
 let di=dirs.indexOf(d),n=k==='area'?8:(di<2?2:4);
 let oldFrame=Math.floor(timeMs/(k==='area'?100:200))%n;
 let offset=k==='area'?di*8:([0,2,4,8][di]);let ix=offset+oldFrame,cols=k==='area'?8:4;
 sx=(ix%cols)*w;sy=Math.floor(ix/cols)*32;
 }
 let dx=Math.floor((cv.width-w*scale)/2);
 if(silhouette){
 let m=mask.getContext('2d');m.clearRect(0,0,32,32);m.globalCompositeOperation='source-over';m.drawImage(im,sx,sy,32,32,0,0,32,32);m.globalCompositeOperation='source-in';m.fillStyle=$('background').value==='light'?'#21342d':'#e0ebd4';m.fillRect(0,0,32,32);m.globalCompositeOperation='source-over';ctx.drawImage(mask,dx,0,32*scale,32*scale);
 }else ctx.drawImage(im,sx,sy,w,32,dx,0,w*scale,32*scale);
}
function render(){
 if(!loaded)return;
 let f=Math.floor(timeMs/100)%16,k=$('kind').value,d=$('dir').value,s=+$('zoom').value;
 $('scrub').value=f;$('frameNum').textContent=String(f+1).padStart(2,'0')+' / 16';
 paint($('old'),k,d,f,false,s);paint($('new'),k,d,f,true,s,$('silhouette').checked);
 for(let a of nativeCanvases)paint(a.cv,a.k,a.d,f,true,1,$('silhouette').checked);
}
function tick(now){let dt=now-last;last=now;if(playing)timeMs+=Math.min(dt,100);render();requestAnimationFrame(tick)}
function pause(){playing=false;$('play').textContent='Reproducir'}
$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pausar':'Reproducir'};
$('next').onclick=()=>{pause();timeMs=(Math.floor(timeMs/100)+1)*100;render()};
$('scrub').oninput=()=>{pause();timeMs=+$('scrub').value*100;render()};
for(let id of ['kind','dir','zoom','background','silhouette'])$(id).onchange=settings;
buildNative();settings();
const tasks=[];
for(let k of kinds){let oldName=k==='exponencial_endgame'?'exponencial':k;tasks.push(image('previews/original_'+oldName+'.png').then(im=>imgs['old_'+k]=im));for(let d of dirs)tasks.push(image('npcs/'+k+'/NPC 2 '+d+'.png').then(im=>imgs[k+'_'+d]=im))}
Promise.all(tasks).then(()=>{loaded=true;$('status').textContent='PNG con transparencia · Vecino más cercano';settings();requestAnimationFrame(tick)}).catch(e=>{$('status').className='error';$('status').textContent='No se pudo cargar: '+e.message+'. Conservá la estructura de carpetas.'});
