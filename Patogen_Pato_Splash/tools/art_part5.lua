-- Native Aseprite authoring: original actors retain the established heads and palette.
local base=assert(app.params['base']);local out=base..'splash/assets/';local pc=app.pixelColor
local colours,allowed={},{}
for l in io.lines(out..'patogen_paleta.gpl')do local r,g,b=l:match('^(%d+)%s+(%d+)%s+(%d+)');if r then local c=pc.rgba(tonumber(r),tonumber(g),tonumber(b),255);colours[#colours+1]=c;allowed[c]=true end end
local pal=Palette(#colours);for i,c in ipairs(colours)do pal:setColor(i-1,Color(c))end
local function color(h)local n=tonumber(h,16);return pc.rgba((n>>16)&255,(n>>8)&255,n&255,255)end
local I
local function rect(x,y,w,h,c)for yy=math.floor(y),math.floor(y+h-1)do for xx=math.floor(x),math.floor(x+w-1)do if xx>=0 and yy>=0 and xx<I.width and yy<I.height then I:drawPixel(xx,yy,type(c)=='string' and color(c) or c)end end end end
local function line(x,y,a,b,c,t)local n=math.max(math.abs(a-x),math.abs(b-y));for j=0,math.max(1,n)do local k=j/math.max(1,n);rect(x+(a-x)*k+.5,y+(b-y)*k+.5,t or 1,t or 1,c)end end
local function ellipse(x,y,rx,ry,c)for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx)+yy*yy/(ry*ry)<=1 then rect(x+xx,y+yy,1,1,c)end end end end
local ink='28343c';local skin='e8ba87';local shadow='b47e5b';local white='fff6de';local blue='398fc5';local foam='b8edff'
local images={};local function actor(name,frame,x,y)
 if not images[name]then images[name]=Image{fromFile=out..name..'.png'}end
 local crop=Image(images[name],Rectangle(frame*32,0,32,32));I:drawImage(crop,Point(x,y))
end
local audit={passed=true,shared_colours=#colours,off_palette_pixels=0,assets={}}
local function asset(name,w,h,count,dt,draw)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name='Accion pixel art / paleta Patogen'
 for f=0,count-1 do if f>0 then s:newEmptyFrame()end;I=Image(w,h);draw(f);s:newCel(s.layers[1],f+1,I);s.frames[f+1].duration=dt
  for p in I:pixels()do if pc.rgbaA(p())>0 and not allowed[p()]then audit.off_palette_pixels=audit.off_palette_pixels+1 end end
 end
 s:setPalette(pal);local tag=s:newTag(1,count);tag.name='default';s:saveAs(out..name..'.aseprite');app.activeSprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..name..'.png',dataFilename=out..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true}
 audit.assets[#audit.assets+1]={name=name,width=w,height=h,frames=count,fps=1/dt};s:close();print('PART5_ART '..name)
end
asset('npc_guardia',40,40,8,.24,function(f)
 actor('salvavidas_1',0,4,6);local d=({-2,-1,0,1,2,1,0,-1})[f+1]
 -- Two glass lenses, bridge, bent arms, cap and lanyard.
 line(10,24,12+d,15,shadow,3);line(28,24,26+d,15,skin,3)
 rect(10+d,13,8,6,ink);rect(22+d,13,8,6,ink);rect(17+d,14,6,3,ink)
 rect(11+d,14,5,3,blue);rect(23+d,14,5,3,blue);rect(11+d,14,2,1,foam);rect(23+d,14,2,1,foam)
 rect(14,6,14,2,'dc715e');rect(24,8,6,2,'a74b4d')
end)
asset('npc_silbato',40,40,4,.14,function(f)
 actor('salvavidas_1',0,4,6);line(27,24,25,15,skin,3);rect(25,14,5,3,'adc2c9');line(22,18,23,25,ink)
 if f%2==0 then line(32,12,36,10,white);line(33,16,38,16,white);line(32,20,36,22,white)end
end)
for mode,name in ipairs({'npc_reposera_giro','npc_reposera_protector','npc_reposera_lectura'})do
 asset(name,32,64,8,.3,function(f)
  local shift=(mode==1 and f>=4)and 2 or 0
  -- Reference head cropped at native resolution; reclining body is freshly drawn.
  actor('banador_'..mode,0,0,3)
  rect(7,24,20,23,0);rect(7+shift,25,18-shift,19,shadow);rect(9+shift,25,14-shift,17,skin)
  rect(8+shift,41,16-shift,8,ink);rect(9+shift,42,14-shift,6,mode==2 and 'dc715e' or blue)
  rect(9+shift,49,5,11,shadow);rect(17+shift,49,5,11,shadow);rect(10+shift,49,3,10,skin);rect(18+shift,49,3,10,skin)
  if mode==1 then line(8+shift,29,6+shift,40,skin,3);line(25,29,25-shift,40,skin,3);rect(15+shift,35,2,1,shadow)
  elseif mode==2 then local dy=(f%4)*2;line(24,31,13,28+dy,skin,3);rect(4,32,5,9,white);rect(5,30,3,2,blue);rect(5,35,3,3,'efbf4b');rect(12,30+dy,4,2,white)
  else rect(4,30,24,17,ink);rect(5,31,10,14,white);rect(16,31,11,14,'e3d4b2');line(15,31,15+(f>=4 and 5 or 0),44,'b8aa93');for y=34,42,3 do rect(7,y,6,1,'adc2c9');rect(18,y,6,1,'adc2c9')end;rect(3,37,3,4,skin);rect(26,37,3,4,skin)end
 end)
end
asset('npc_pelota',32,36,6,.2,function(f)
 actor('banador_3',0,0,4);local y=15+(f%3)*2;line(9,23,4,y,skin,3);line(24,23,28,y,skin,3);rect(13,5,9,2,'dc715e')
end)
asset('pelota_playa',20,20,8,.12,function(f)
 ellipse(10,10,9,9,ink);ellipse(10,9,8,8,white)
 for y=-7,7 do for x=-7,7 do if x*x+y*y<58 then local a=math.atan(y,x)+f*math.pi/4;local section=math.floor((a+math.pi*4)/(math.pi/2))%4;if section==0 then rect(10+x,9+y,1,1,'dc715e')elseif section==2 then rect(10+x,9+y,1,1,blue)end end end end
 rect(6,4,4,2,white);rect(9,8,3,3,'efbf4b')
end)
asset('npc_limpieza',48,44,8,.18,function(f)
 actor('staff_2',0,4,8);local x=29+({-5,-2,1,4,6,4,1,-2})[f+1];line(23,24,x,37,'705342',2);line(23,23,x,36,'c49d69');line(14,26,23,27,skin,3)
 rect(x-7,37,16,3,ink);rect(x-6,38,14,2,'adc2c9');for j=0,5 do rect(x-6+j*2,40,1,3,'e4edef')end
 rect(2,33,8,8,blue);rect(3,34,6,2,foam);line(2,34,3,30,ink);line(3,30,8,30,ink)
end)
asset('npc_fotografo',40,40,6,.25,function(f)
 actor('staff_3',0,4,6);rect(11,19,20,11,ink);rect(12,20,18,8,'3b5d76');ellipse(22,24,5,4,ink);ellipse(22,23,3,2,blue);rect(13,17,6,3,'adc2c9');rect(13,18,4,2,white)
 line(10,26,14,22,skin,2);line(30,26,29,22,skin,2);if f>=3 then rect(12,11,15,4,ink);rect(14,12,10,2,'705342')end
end)
asset('flash_camara',32,32,4,.07,function(f)
 local r=({4,13,8,2})[f+1];line(16-r,16,16+r,16,white,2);line(16,16-r,16,16+r,white,2);if f==1 then line(8,8,24,24,foam);line(8,24,24,8,foam)end;rect(13,13,6,6,white)
end)
asset('npc_heladero',40,40,8,.22,function(f)
 actor('staff_1',0,4,6);rect(13,6,16,5,white);rect(15,3,12,4,white);rect(15,21,11,12,white);rect(17,22,7,2,blue)
 local x=27+(f%4);line(25,26,x,20,skin,3);rect(x,18,3,6,'d8943b');ellipse(x+1,17,4,3,'dc715e');rect(x,15,2,1,white)
end)
asset('helado_mano',12,18,4,.25,function(f)
 line(4,9,6,16,'d8943b',2);line(8,9,6,16,'efbf4b');ellipse(6,7,5,4,'dc715e');ellipse(6,3,4,3,white);rect(4,2,3,1,'ffe99b');if f==3 then rect(9,12,1,2,'dc715e')end
end)
asset('npc_tobogan',32,36,4,.15,function(f)
 actor('banador_2',0,0,3);line(8,24,3,14+f,skin,3);line(24,24,28,13+f,skin,3);rect(10,28,6,7,skin);rect(19,28,6,6,skin)
end)
asset('reaccion_alerta',24,32,4,.2,function(f)
 local y=f%2;rect(9,4+y,7,15,ink);rect(10,5+y,5,12,'efbf4b');rect(9,23+y,7,6,ink);rect(10,24+y,5,4,'fff6de')
end)
asset('reaccion_cubrir',32,32,4,.2,function(f)
 line(7,23,13,14+f%2,skin,3);line(25,23,20,14,skin,3);rect(12,13,10,5,'e4edef');rect(14,14,7,3,foam)
end)
asset('huella_mojada',16,12,2,.2,function(f)
 ellipse(4,6,2,4,'307ba7');ellipse(11,6,2,4,'398fc5');rect(f==0 and 3 or 10,1,3,2,'307ba7')
end)
asset('libelula',24,20,4,.15,function(f)
 local d=f%2*3;line(6,5+d,17,13-d,foam,2);line(6,13-d,17,5+d,'e4edef',2);rect(11,5,3,11,'3b5d76');rect(10,4,5,3,'efbf4b');rect(11,16,2,2,blue)
end)
-- One independently controllable cabin. Opaque interior covers the old door;
-- saloon leaves close in front of the customer after they cross the threshold.
asset('puerta_cabina',80,64,5,.15,function(f)
 rect(0,0,80,64,ink);rect(2,3,76,57,'3b5d76');rect(4,53,72,8,'81a991');rect(4,55,72,2,'a7c8bf')
 local width=36-f*7
 for side=0,1 do local x=side==0 and 2 or 78-width
  rect(x,16,width,38,'705342');rect(x+2,18,math.max(1,width-4),33,'c49d69');rect(x+2,13,math.max(1,width-4),5,'c49d69')
  for y=22,46,5 do rect(x+2,y,math.max(1,width-4),2,'9c724e');rect(x+2,y+2,math.max(1,width-4),1,'e3d4b2')end
  rect(side==0 and x+width-4 or x+2,33,2,6,'efbf4b');rect(side==0 and x or x+width-2,21,2,4,'adc2c9')
 end
end)
audit.passed=audit.off_palette_pixels==0;local file=assert(io.open(base..'tests/part5_art.json','w'));file:write(json.encode(audit));file:close();assert(audit.passed)
print('PART5_PALETTE_OK '..#audit.assets..' new sources')
