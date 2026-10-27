-- Pato Splash: original raster artwork, authored and exported in Aseprite.
local base=app.params['base']
assert(base,'Pass --script-param base=<project/>')
local out=base..'splash/assets/'
local pc=app.pixelColor
local C={}
local function color(s) if C[s] then return C[s] end local v=tonumber(s,16);local c=pc.rgba((v>>16)&255,(v>>8)&255,v&255,255);C[s]=c;return c end
local S,I,L
local ink='30384c';local navy='3b5d76';local blue='398fc5';local sky='6ac7f2';local pale='b8edff';local white='fff2d6';local cream='e3d4b2';local shadow='b8aa93';local coral='dc715e';local red='a74b4d';local yellow='f6cb5c';local green='588878'
local function px(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and y>=0 and x<I.width and y<I.height then I:drawPixel(x,y,type(c)=='string' and color(c) or c) end end
local function rect(x,y,w,h,c) for yy=math.floor(y),math.floor(y+h-1) do for xx=math.floor(x),math.floor(x+w-1) do px(xx,yy,c) end end end
local function line(x1,y1,x2,y2,c,thick) local n=math.max(math.abs(x2-x1),math.abs(y2-y1));if n==0 then px(x1,y1,c);return end for k=0,n do rect(math.floor(x1+(x2-x1)*k/n+.5),math.floor(y1+(y2-y1)*k/n+.5),thick or 1,thick or 1,c) end end
local function ell(x,y,w,h,c) local step=(w>24 and h>16) and 2 or 1;for yy=0,h-1,step do for xx=0,w-1,step do if ((xx-(w-1)/2)/(w/2))^2+((yy-(h-1)/2)/(h/2))^2<=1 then rect(x+xx,y+yy,step,step,c) end end end end
local function box(x,y,w,h,c)rect(x,y,w,1,c);rect(x,y+h-1,w,1,c);rect(x,y,1,h,c);rect(x+w-1,y,1,h,c)end
local function poly(points,c) local lo,hi=9999,0;for _,p in ipairs(points) do lo=math.min(lo,p[2]);hi=math.max(hi,p[2]) end;for y=lo,hi do local hits={};for n=1,#points do local a,b=points[n],points[n%#points+1];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end end;table.sort(hits);for n=1,#hits-1,2 do rect(math.ceil(hits[n]),y,math.floor(hits[n+1])-math.ceil(hits[n])+1,1,c) end end end
local function new(w,h,name)S=Sprite(w,h,ColorMode.RGB);L=S.layers[1];L.name=name;I=Image(w,h,ColorMode.RGB)end
local function frame(f)if f>1 then S:newEmptyFrame()end;I=Image(S.width,S.height,ColorMode.RGB)end
local function flush(f)S:newCel(L,f or 1,I,Point(0,0))end
local function material_pass(name)
 if name=='agua_celeste' or name=='chorro_balde' or name=='pato_gigante' then return end
 local source=L;local detail=S:newLayer();detail.name='Materiales / vetas / costuras / desgaste localizado'
 local cloth=(name=='sombrilla' or name=='kiosco' or name=='banderin' or name=='reposera')
 local wood=(name=='vestuarios' or name=='banco' or name=='mesa' or name=='palmera')
 local tile=(name=='tiles_parque' or name:find('pileta')~=nil or name=='duchas')
 for f=1,#S.frames do
  local img=source:cel(f).image;local details=Image(S.width,S.height,ColorMode.RGB)
  for y=2,S.height-3 do for x=2,S.width-3 do
   local p=img:getPixel(x,y);local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
   if pc.rgbaA(p)>0 and p~=color(shadow) and p~=color(ink) and math.max(r,g,b)>90 then
    local factor=nil;local seed=(x*17+y*31)%157
    local iswood=wood and r>g*1.08 and g>b*1.08
    if iswood and ((y+math.floor(math.sin(x*.11)*2))%9==0) and x%19<13 then factor=.83
    elseif cloth and r>g*1.15 and (x+y)%13==0 and x%4<2 then factor=.88
    elseif tile and seed<2 then factor=.91
    elseif not tile and not cloth and seed<2 then factor=1.11 end
    if not tile and pc.rgbaA(img:getPixel(x+2,y))==0 then factor=.72 end
    if not tile and pc.rgbaA(img:getPixel(x,y+2))==0 then factor=.74 end
    if factor then details:drawPixel(x,y,pc.rgba(math.min(255,math.floor(r*factor)),math.min(255,math.floor(g*factor)),math.min(255,math.floor(b*factor)),255))end
   end
  end end
  I=details
  if name=='kiosco' then
   for y=126,139,5 do line(20,y,169,y,'5f8f91');line(22,y+1,167,y+1,'bbd2bf')end
   for x=23,164,24 do rect(x,117,3,3,ink);px(x,117,white)end
   for j=0,2 do rect(108,80+j*7,4,4,({'e79873','8ab2bd','cfb071'})[j+1]);rect(118,81+j*7,34-j*6,1,'71867e')end
   rect(66,72,5,34,'a7c8bf');rect(67,74,2,25,white);line(28,105,60,79,'82a6a8');rect(11,138,5,8,'496b71');rect(175,138,5,8,'496b71')
  elseif name=='torre_balde' then
   for _,x in ipairs({20,162})do for _,y in ipairs({43,103,136})do rect(x-2,y,15,7,'476775');rect(x,y+1,11,4,'99b4b6');px(x+1,y+2,white);px(x+8,y+2,white)end end
   rect(37,17,116,2,'bdcfc9');for x=42,147,21 do rect(x,20,3,3,'6b8d97')end
  elseif name=='balde' then
   for y=34,74,12 do rect(23,y,3,3,'f4bb8d');rect(86,y,3,3,'794749')end
   line(28,75,35,77,'f0a17e',2);line(75,77,84,74,'8e4245',2);rect(44,53,31,3,'dcad50')
  elseif name=='duchas' then
   for j=0,2 do local x=13+j*37;for y=27,62,15 do line(x+1,y,x+27,y,'8badb4');line(x+2,y+1,x+27,y+1,'d6e4d5')end;line(x+14,14,x+14,25,'8badb4');line(x+14,47,x+14,66,'8badb4');rect(x+1,14,2,53,'8eadb3')end
  elseif name=='casilleros' then
   for j=0,3 do local x=7+j*29;rect(x+1,61,23,3,'547484');rect(x+21,13,2,12,'c8d7cd');rect(x+19,35,1,7,white);rect(x+10,32,2,3,'4d6370');rect(x+9,57,4,1,'799395')end
  elseif name=='silla_salvavidas' then
   box(17,19,29,18,'ad554f');line(19,21,44,21,'f0aa83');for y=25,35,5 do rect(19,y,23,1,'cd6256')end
   for y=61,87,9 do rect(21,y,19,1,'a6bdb6')end;rect(12,46,42,2,white)
  elseif name=='flotador' then
   local dy=math.floor(math.sin((f-1)*math.pi/4));for _,q in ipairs({{10,9},{31,9},{9,25},{31,25}})do rect(q[1],q[2]+dy,3,1,'993f49')end;rect(9,17+dy,3,3,'be8661')
  elseif name=='banderin' then
   for y=41,80,12 do rect(7,y,4,3,'749298')end;rect(10,14,1,18,'f3b489');rect(11,17,4,2,'b0524a')
  elseif name=='filtro' then
   for x=17,46,6 do line(x,25,x,44,'557788')end;for y=25,44,6 do line(16,y,46,y,'557788')end
   for _,q in ipairs({{8,12},{52,12},{8,58},{52,58}})do rect(q[1],q[2],2,2,ink);px(q[1],q[2],white)end
  elseif name=='papelera' then
   rect(6,30,20,3,'4d7182');rect(7,10,2,18,'a7c0bc');px(24,12,white);px(24,28,white);line(10,5,21,5,'a1bdbb')
  elseif name=='escalera' then
   for y=6,35,9 do for x=10,22,4 do rect(x,y+1,2,1,navy)end end;rect(4,38,4,5,'5f8ca3');rect(24,38,4,5,'5f8ca3')
  elseif name=='fuente_hongo' then
   for _,q in ipairs({{30,30},{83,28},{62,37}})do rect(q[1],q[2],8,4,'ffc184');rect(q[1]+2,q[2]-2,4,2,'ffc184')end
   line(28,44,99,44,'ad504d',2);rect(59,68,3,31,'b2c9bc');rect(67,67,3,36,'768c8c')
  elseif name:find('pileta') then
   for x=25,S.width-35,32 do rect(x,3,5,3,'64a6c4');rect(x,S.height-16,5,3,'64a6c4')end
   for y=24,S.height-40,32 do rect(3,y,3,5,'64a6c4');rect(S.width-14,y,3,5,'64a6c4')end
  end
  S:newCel(detail,f,details,Point(0,0))
 end
end
local function save(name,anim,dt)
 if app.params['only'] and app.params['only']~=name then S:close();return end
 material_pass(name)
 if anim then local t=S:newTag(1,#S.frames);t.name='Ambiental';for _,f in ipairs(S.frames)do f.duration=dt or .16 end end
 S:saveAs(out..name..'.aseprite');app.activeSprite=S
 if anim then app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..name..'.png',dataFilename=out..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true}
 else S:saveCopyAs(out..name..'.png')end
 print('ART '..name..' '..S.width..'x'..S.height..' frames='..#S.frames);S:close()
end
local function panel(x,y,w,h,c)rect(x+4,y+5,w,h,shadow);rect(x,y,w,h,ink);rect(x+2,y+2,w-4,h-4,c);rect(x+3,y+3,w-6,2,white)end
local function tube(points,r,c,hi)
 for k=1,#points-1 do local a,b=points[k],points[k+1];local n=math.max(math.abs(a[1]-b[1]),math.abs(a[2]-b[2]));for j=0,n do local x=a[1]+(b[1]-a[1])*j/n;local y=a[2]+(b[2]-a[2])*j/n;ell(x-r,y-r,r*2,r*2,c);ell(x-r+3,y-r+3,r*2-6,r*2-6,hi)end end
end

new(256,96,'Materiales / baldosas, madera, cesped, goma')
local materials={{'e2d5b5','cebea0','eee4c9'},{'c9d9dc','adc2c9','e4edef'},{'c49a72','ad805d','d9b18a'},{'81a991','719c83','96b49a'},{'cfad9c','bd9788','e0beab'},{'91bdd0','78a5bd','afd3df'},{'e5ca89','cbb375','efdcab'},{'d1c7ac','bdb297','e3d7bd'}}
for row=0,2 do for k=0,7 do local x,y=k*32,row*32;local m=materials[k+1];rect(x,y,32,32,m[1]);if k==3 then for j=0,12 do local xx=(j*17+row*7)%31;local yy=(j*11+row*9)%31;line(x+xx,y+yy,x+xx+1,y+yy-2,j%2==0 and m[2] or m[3])end elseif k==2 then for yy=0,31,8 do line(x,y+yy,x+31,y+yy,m[2]);line(x+1,y+yy+1,x+30,y+yy+1,m[3]);line(x+5,y+yy+4,x+18,y+yy+4,m[2])end else rect(x,y,32,1,m[2]);rect(x,y,1,32,m[2]);rect(x+1,y+1,31,1,m[3]);if row==1 then rect(x+5,y+7,4,1,m[3]);rect(x+22,y+24,3,1,m[2])elseif row==2 then rect(x+12,y+11,2,2,m[2]);rect(x+7,y+25,5,1,m[3])end end end end;flush();save('tiles_parque')

new(128,128,'Agua celeste / reflejos continuos')
for f=1,12 do frame(f);rect(0,0,128,128,'70c7ee');local t=(f-1)*math.pi/6
 for y=0,127 do for x=0,127 do local u=x*math.pi/64;local v=y*math.pi/64;local field=math.sin(u+math.sin(v+t)*.8+t)+math.cos(v*2-t)+.25*math.sin((u+v)*3+t);if field>1.45 then px(x,y,'83cff0')elseif field< -1.4 then px(x,y,'65bfea')end;if field>1.72 and field<1.79 then px(x,y,'a4e0f8')end end end
 for j=0,7 do local x=(j*41+f)%128;local y=(j*29+math.floor(math.sin(t+j)*3))%128;line(x,y,x+4,y,'9cdcf5');px((x+5)%128,(y+1)%128,'9cdcf5')end
 flush(f)end;save('agua_celeste',true,.18)

local function pool(name,w,h)
 new(w,h,'Borde ceramico / profundidad / rejilla');rect(5,7,w-5,h-7,shadow);rect(0,0,w-6,h-7,ink);rect(2,2,w-10,h-11,cream);rect(3,3,w-12,4,white);rect(7,9,w-20,h-25,blue);rect(12,14,w-30,h-36,navy);rect(16,18,w-38,h-44,sky)
 for x=8,w-12,16 do line(x,2,x,8,'b3c5ca');line(x,h-18,x,h-10,'b3c5ca')end
 for y=16,h-22,16 do line(2,y,9,y,'b3c5ca');line(w-17,y,w-9,y,'b3c5ca')end
 rect(13,15,w-32,3,pale);rect(13,18,3,h-43,'99d8f4');rect(15,h-28,w-36,4,'3594ca');flush();save(name)
end
pool('pileta_central',512,256);pool('pileta_lateral',320,176);pool('pileta_balde',288,144)

new(160,144,'Pato inflable / costuras / reflejos')
for f=1,8 do frame(f);local dy=math.floor(math.sin((f-1)*math.pi/4)*2);ell(9,112,143,22,'489fcb');ell(18,109,124,17,'9cdef7');ell(17,66+dy,125,57,'9c783f');ell(20,63+dy,120,55,'e7b54f');ell(25,60+dy,110,50,yellow);ell(34,67+dy,88,38,'f9d979');ell(72,22+dy,64,65,'b18a40');ell(75,19+dy,58,64,yellow);ell(79,21+dy,47,45,'ffdf82');ell(87,26+dy,20,8,white);poly({{24,83+dy},{7,61+dy},{12,96+dy},{33,104+dy}},yellow);ell(43,80+dy,48,27,'dba345');ell(43,78+dy,45,24,'efc560');line(49,85+dy,73,84+dy,'ffdf82',2);ell(115,57+dy,36,18,red);ell(117,55+dy,34,14,'f29a57');line(124,62+dy,149,62+dy,'cd6945');ell(112,38+dy,8,10,ink);rect(113,39+dy,2,3,white);rect(45,111+dy,5,4,'c7933c');line(27,106+dy,40,111+dy,'e0ad45');flush(f)end;save('pato_gigante',true,.2)

new(272,240,'Toboganes dobles / torre / agua')
for f=1,8 do frame(f);ell(12,208,243,26,shadow);for _,x in ipairs({35,126,225})do rect(x,73,9,137,navy);rect(x+2,75,3,132,'8ab8c6');rect(x-5,207,20,6,ink)end
 panel(16,12,130,76,navy);rect(22,18,118,45,'719aab');for x=25,139,14 do rect(x,18,3,45,white)end;rect(13,11,137,5,white);rect(19,62,125,8,cream)
 tube({{70,77},{109,100},{177,99},{216,126},{210,151},{163,166},{111,170},{80,197},{90,221}},20,red,coral)
 tube({{112,77},{148,83},{202,88},{245,116},{246,153},{219,181},{170,198},{160,225}},18,'b89642',yellow)
 tube({{70,81},{111,105},{177,104},{211,127},{205,147},{162,161},{110,166},{75,196},{85,220}},7,blue,sky)
 tube({{112,81},{151,88},{201,93},{239,118},{240,150},{215,176},{165,194},{155,223}},6,blue,pale)
 for j=0,10 do local yy=88+j*11;rect(23,yy,28,3,white);rect(21,yy-2,3,8,ink);rect(50,yy-2,3,8,ink)end
 for j=0,7 do local xx=80+(j*19)%94;local yy=210+(j*7+f*3)%22;ell(xx,yy,7,3,j%2==0 and white or pale)end;flush(f)end;save('toboganes',true,.14)

new(192,160,'Torre del gran chapuzon / estructura')
rect(10,149,174,7,blue);for _,x in ipairs({20,162})do rect(x,17,11,136,ink);rect(x+2,19,6,130,'c8dde0');rect(x-7,146,24,8,navy)end;rect(17,14,160,12,ink);rect(20,16,154,7,white);rect(26,27,144,5,coral);for x=32,163,16 do rect(x,27,8,5,yellow)end;rect(30,47,139,8,ink);rect(32,48,135,3,'c5d9db');rect(17,109,16,6,coral);rect(159,109,16,6,coral);flush();save('torre_balde')
new(112,96,'Balde / metal pintado / agua');ell(9,8,93,29,ink);ell(12,10,87,24,white);poly({{12,23},{100,23},{89,87},{25,87}},ink);poly({{16,25},{96,25},{85,83},{28,83}},coral);poly({{20,28},{41,28},{45,80},{30,80}},'fa9b77');poly({{81,28},{94,28},{83,81},{74,81}},red);ell(16,14,80,20,sky);ell(20,15,72,13,pale);rect(49,40,24,29,white);rect(42,49,38,11,white);rect(52,43,18,23,yellow);rect(46,52,30,5,yellow);ell(24,78,62,9,'ad5550');flush();save('balde')

new(96,88,'Sombrilla / tela al viento')
for f=1,8 do frame(f);local sway=math.floor(math.sin((f-1)*math.pi/4));ell(10,65,78,17,shadow);rect(46,35,4,43,navy);ell(4,9+sway,87,49,ink);ell(6,7+sway,83,47,coral);poly({{47,7+sway},{17,45+sway},{39,52+sway},{47,17+sway}},white);poly({{47,7+sway},{57,51+sway},{80,45+sway},{49,15+sway}},white);line(47,7+sway,6,31+sway,red);line(48,7+sway,88,31+sway,red);ell(43,5+sway,9,7,yellow);rect(44,75,8,3,ink);flush(f)end;save('sombrilla',true,.22)
new(40,80,'Reposera / lona rayada');rect(8,66,5,10,navy);rect(29,66,5,10,navy);panel(5,10,30,55,white);rect(8,14,24,43,'7fbed6');for x=9,30,8 do rect(x,15,3,41,pale)end;line(8,37,31,37,navy);rect(2,31,4,31,white);rect(34,31,4,31,white);rect(10,17,20,7,cream);rect(6,63,30,5,navy);flush();save('reposera')
new(96,128,'Palmera / hojas al viento')
for f=1,8 do frame(f);local sw=math.floor(math.sin((f-1)*math.pi/4)*2);ell(21,111,57,12,shadow);poly({{44,113},{55,113},{53,36},{44,37}},'a67a53');for y=52,110,9 do line(45,y,53,y-2,'d6ad76',2)end
 local cx,cy=48+sw,33;for k=0,6 do local a=k*math.pi*2/7;local ex=cx+math.cos(a)*43;local ey=cy+math.sin(a)*25;poly({{cx,cy-4},{ex-6,ey-8},{ex,ey+12},{cx+2,cy+6}},k%2==0 and '497d6d' or '63957a');line(cx,cy,ex,ey,'9bb58a',2)end;ell(cx-7,cy-2,14,11,'9d7953');ell(cx-4,cy,5,5,'d5aa72');flush(f)end;save('palmera',true,.22)
new(192,160,'Kiosco / helados / toldo')
for f=1,8 do frame(f);panel(9,49,174,100,'c4d7cf');rect(18,70,155,42,navy);rect(23,75,67,33,'597b86');for j=0,5 do rect(28+j*10,91-(j%3)*5,7,16+(j%3)*5,({'f4d282','e98b78','b9dfe5'})[j%3+1])end;rect(98,75,68,32,'f0e6cb');rect(104,81,51,3,coral);rect(104,88,36,2,navy);rect(104,94,44,2,navy);rect(6,112,180,10,ink);rect(8,112,176,5,white);rect(18,124,154,18,'9dbdb9');for x=24,166,18 do rect(x,126,2,14,'83a7a9')end;poly({{17,21},{176,21},{190,60},{3,60}},ink);poly({{19,23},{174,23},{186,57},{7,57}},white);for x=20,168,28 do poly({{x,23},{x+13,23},{x+17,57},{x-3,57}},coral)end;for x=7,181,14 do rect(x,57,13,6+(f+x)%2,x%28==7 and white or coral)end;panel(60,2,75,22,yellow);ell(76,6,13,13,white);poly({{79,16},{86,16},{83,22}},'b98158');rect(99,9,24,3,navy);rect(99,15,18,2,navy);flush(f)end;save('kiosco',true,.2)
new(128,96,'Duchas / chorros celestes')
for f=1,8 do frame(f);panel(2,5,122,79,'9ebfc9');for j=0,2 do local x=13+j*37;rect(x,12,29,58,'bcd5d7');line(x+8,57,x+8,23,navy,3);line(x+8,23,x+20,23,navy,3);rect(x+15,26,11,4,white);for k=0,2 do for y=34,65,7 do rect(x+16+k*3,y+(f*2+k)%6,1,3,k==1 and white or pale)end end;ell(x+6,68,22,7,sky)end;rect(6,83,116,8,navy);for x=10,119,5 do rect(x,85,2,4,'9fb5bb')end;flush(f)end;save('duchas',true,.12)
new(128,80,'Casilleros / puertas numeradas');panel(2,4,122,68,navy);for j=0,3 do local x=7+j*29;rect(x,9,25,55,j%2==0 and '96bdc6' or 'd7c9a8');rect(x+2,11,21,2,white);for y=17,23,3 do rect(x+5,y,15,1,navy)end;rect(x+19,34,3,9,ink);rect(x+8,31,7,5,white);box(x,9,25,55,ink)end;flush();save('casilleros')
new(64,104,'Silla de salvavidas / aro');for _,x in ipairs({13,45})do rect(x,45,5,53,white);rect(x+1,46,2,50,navy)end;for y=57,92,9 do rect(18,y,27,3,cream)end;panel(10,12,43,42,white);rect(14,16,35,24,coral);rect(12,48,42,7,navy);rect(6,37,4,23,white);rect(55,37,4,23,white);ell(37,57,23,24,red);ell(40,60,17,18,white);ell(45,65,7,8,navy);rect(45,59,6,4,coral);rect(45,77,6,4,coral);flush();save('silla_salvavidas')
new(48,40,'Flotador / flotacion')
for f=1,8 do frame(f);local dy=math.floor(math.sin((f-1)*math.pi/4));ell(2,20,44,13,'429dcd');ell(3,8+dy,40,24,red);ell(4,6+dy,38,23,coral);ell(13,12+dy,20,11,ink);ell(14,13+dy,18,10,sky);rect(18,6+dy,9,5,white);rect(18,25+dy,9,4,white);rect(4,14+dy,8,7,white);rect(35,14+dy,7,7,white);line(10,10+dy,15,8+dy,'ffc0a2');flush(f)end;save('flotador',true,.2)
new(48,96,'Banderin / viento')
for f=1,8 do frame(f);rect(7,9,4,80,navy);rect(8,9,1,78,white);ell(4,85,11,6,shadow);local dy=math.floor(math.sin((f-1)*math.pi/4)*3);poly({{11,12},{43,18+dy},{29,29+dy},{11,34}},coral);poly({{11,14},{34,19+dy},{11,22}},yellow);ell(6,5,6,7,yellow);flush(f)end;save('banderin',true,.15)
new(64,72,'Filtro / ventilador / indicador')
for f=1,8 do frame(f);panel(4,8,54,55,'a5bfc4');ell(11,18,39,32,ink);ell(14,21,33,26,navy);local a=(f-1)*math.pi/4;for j=0,3 do local aa=a+j*math.pi/2;line(30,34,30+math.cos(aa)*13,34+math.sin(aa)*10,'acc9cc',4)end;ell(26,30,9,9,cream);rect(12,54,20,3,navy);rect(41,54,8,3,f%4<2 and yellow or coral);flush(f)end;save('filtro',true,.12)
new(32,40,'Papelera');ell(4,5,24,9,ink);rect(4,9,24,25,navy);rect(7,11,18,21,'7196a3');for x=9,25,5 do rect(x,13,1,17,cream)end;ell(4,3,24,8,white);ell(9,5,14,4,ink);flush();save('papelera')
new(64,32,'Banco de parque');rect(8,22,5,8,ink);rect(51,22,5,8,ink);panel(3,5,58,18,'bc926a');for y=9,20,5 do rect(6,y,52,2,'e2ba85')end;flush();save('banco')
new(64,48,'Mesa / bebidas');ell(4,27,56,15,shadow);rect(28,20,6,23,navy);ell(3,4,58,30,ink);ell(5,3,54,27,cream);ell(8,5,48,20,white);rect(17,9,7,10,coral);rect(18,8,5,3,pale);line(21,4,21,10,navy);rect(39,13,8,10,blue);rect(40,12,6,2,pale);line(44,8,43,14,coral);flush();save('mesa')
new(32,48,'Escalera pileta');for _,x in ipairs({4,24})do rect(x,1,4,44,ink);rect(x+1,2,2,39,white)end;for y=6,35,9 do rect(8,y,16,3,'b9d5df');rect(8,y,16,1,white)end;flush();save('escalera')

new(128,128,'Fuente hongo / cortina de agua')
for f=1,8 do frame(f);ell(9,103,110,20,'4da7d4');ell(15,101,98,16,pale);ell(23,105,82,9,sky);rect(57,43,15,66,navy);rect(60,44,9,62,cream);ell(8,20,112,48,navy);ell(11,16,106,48,coral);ell(19,17,90,31,'f39a78');ell(36,18,46,11,yellow);rect(11,47,106,6,white)
 for j=0,12 do local x=10+j*8;local h=35+(j*7+f*4)%20;line(x,54,x-4+math.floor(math.sin(f+j)*2),54+h,pale,2);line(x+2,56,x+3,54+h-6,sky);ell(x-5,105+(j+f)%5,11,3,j%2==0 and white or pale)end
 flush(f)end;save('fuente_hongo',true,.12)
new(192,128,'Descarga / chorro / espuma')
for f=1,12 do frame(f);local t=(f-1)/11;local width=12+math.floor(math.sin(t*math.pi)*44);local length=math.min(100,math.floor(t*240));local cx=97-math.floor(math.sin(t*math.pi)*30)
 if f<10 then poly({{cx-9,3},{cx+10,3},{cx+width,3+length},{cx-width,3+length}},'77cef2');poly({{cx-4,4},{cx+5,4},{cx+width-8,3+length},{cx-width+12,3+length}},'b8ecfb');for j=0,8 do local yy=8+(j*19+f*9)%math.max(10,length);line(cx-5+(j*11)%18,yy,cx-1+(j*11)%18,yy+12,white,2)end end
 local spread=math.floor(math.sin(math.min(1,t*1.5)*math.pi/2)*81)
 for j=0,18 do local x=96+math.cos(j*2.4)*spread;local y=102+math.sin(j*2.4)*15-(f+j)%4;ell(x-6,y,12,4,j%2==0 and pale or white)end
 flush(f)end;save('chorro_balde',true,.16)

dofile(base..'tools/refined_shapes.lua')({new=new,frame=frame,rect=rect,px=px,line=line,ell=ell,poly=poly,box=box,flush=flush,save=save,panel=panel,tube=tube})
if not app.params['only'] or app.params['only']=='toboganes' then dofile(base..'tools/build_slide_water.lua') end
if not app.params['only'] then dofile(base..'tools/build_npcs.lua') end
