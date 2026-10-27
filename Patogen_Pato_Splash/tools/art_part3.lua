-- Ambient sprites authored/exported through Aseprite MCP; existing palette only.
local base=assert(app.params['base']);local out=base..'splash/assets/';local pc=app.pixelColor
local master={};local allowed={}
for line in io.lines(out..'patogen_paleta.gpl') do
 local r,g,b=line:match('^(%d+)%s+(%d+)%s+(%d+)')
 if r then local c=pc.rgba(tonumber(r),tonumber(g),tonumber(b),255);master[#master+1]=c;allowed[c]=true end
end
assert(#master==37)
local function c(hex)local n=tonumber(hex,16);local v=pc.rgba((n>>16)&255,(n>>8)&255,n&255,255);assert(allowed[v],hex);return v end
local S,I,L;local names={}
local function new(w,h,name)S=Sprite(w,h,ColorMode.RGB);L=S.layers[1];L.name=name end
local function frame(f)if f>1 then S:newEmptyFrame()end;I=Image(S.width,S.height)end
local function px(x,y,col)x=math.floor(x);y=math.floor(y);if x>=0 and y>=0 and x<I.width and y<I.height then I:drawPixel(x,y,c(col))end end
local function rect(x,y,w,h,col)for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,col)end end end
local function line(x,y,xx,yy,col)local n=math.max(math.abs(xx-x),math.abs(yy-y));if n==0 then px(x,y,col);return end;for j=0,n do px(x+(xx-x)*j/n+.5,y+(yy-y)*j/n+.5,col)end end
local function flush(f)S:newCel(L,f,I,Point(0,0));S.frames[f].duration=.20 end
local function save(name)
 local pal=Palette(#master);for i,v in ipairs(master)do pal:setColor(i-1,Color(v))end;S:setPalette(pal)
 S:saveAs(out..name..'.aseprite');app.activeSprite=S
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..name..'.png',dataFilename=out..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true}
 names[#names+1]={name=name,width=S.width,height=S.height,frames=#S.frames};S:close()
end

-- Sparse, seamless 32px glints. No background, displacement or new colours.
new(32,32,'Destellos / cuatro fases / tile 32 px')
for f=1,4 do frame(f)
 for k=0,3 do
  local x=(3+k*9)%32;local y=(5+k*11)%32;local phase=(f+k)%4
  if phase==0 then px(x,y,'b8edff')
  elseif phase==1 then line(x-1,y,x+1,y,'b8edff');px(x,y-1,'6ac7f2');px(x,y+1,'6ac7f2')
  elseif phase==2 then line(x-2,y,x+2,y,'b8edff');line(x,y-2,x,y+2,'b8edff');px(x,y,'fff6de')
  else line(x,y,x+1,y,'b8edff')end
 end
 -- A short broken caustic curve, shifting by one pixel between phases.
 for k=0,4 do local x=(17+k*2+f)%32;local y=(23+math.floor(math.sin(k*.9+f*.7)*2))%32;px(x,y,'b8edff')end
 flush(f)
end;save('destellos_agua')

new(24,16,'Hoja de palmera / cuatro orientaciones sin rotacion filtrada')
for f=1,4 do frame(f)
 local dy=({0,1,0,-1})[f];local tilt=({0,2,0,-2})[f]
 line(3,11+dy,20,4+dy,'705342')
 for k=0,6 do local x=5+k*2;local y=10-math.floor(k*.8)+dy
  line(x,y,x-2,y-3+(k%2)+tilt,'81a991');line(x,y,x+1,y+2+math.floor(tilt*.5),'9eb785')
 end
 line(4,11+dy,20,4+dy,'a7c8bf');flush(f)
end;save('hoja_palmera')

-- Preserve pole and palette; four original wave poses from the existing flag.
local source=app.open(out..'banderin.aseprite');local originals={}
for _,f in ipairs({1,3,5,7})do local im=Image(source.width,source.height);im:drawSprite(source,f);originals[#originals+1]=im end;source:close()
new(48,96,'Bandera / cuatro poses de ondeo / mastil inmovil')
for f=1,4 do frame(f);I:drawImage(originals[f],Point(0,0));flush(f)end;save('bandera_viento')

new(48,32,'Mini splash / gotas / burbujas / ocho fases')
for f=1,8 do frame(f)
 for j=0,4 do local x=4+j*9;local y=3+(j*7+f*3)%18
  rect(x,y,1,3,'b8edff');px(x,y-1,'fff6de')
 end
 for j=0,2 do local x=8+j*14;local y=23-((f+j*3)%7);local r=1+(f+j)%2
  line(x-r,y-r,x+r,y-r,'b8edff');line(x-r,y+r,x+r,y+r,'6ac7f2');px(x-r,y,'b8edff');px(x+r,y,'b8edff');px(x-1,y-1,'fff6de')
 end
 local span=8+f*2;line(24-span,28,24-span+5,28,'b8edff');line(24+span-5,28,24+span,28,'b8edff')
 flush(f)
end;save('fuente_burbujas')

local glyph={H={'101','101','111','101','101'},E={'111','100','110','100','111'},L={'100','100','100','100','111'},A={'010','101','111','101','101'},D={'110','101','101','101','110'},O={'010','101','101','101','010'},S={'111','100','010','001','111'}}
new(80,26,'Heladeria / letrero luminoso / cuatro estados suaves')
for f=1,4 do frame(f)
 rect(1,2,78,23,'28343c');rect(3,3,74,20,'d8943b');rect(4,4,72,17,f==3 and 'efbf4b' or 'ffe99b');rect(4,21,72,2,'705342')
 -- Ice-cream pictogram, plus text that remains legible in every state.
 for y=6,13 do for x=8,19 do if (x-13.5)^2/36+(y-10)^2/20<=1 then px(x,y,f==3 and 'fff5cb' or 'fff6de')end end end
 for y=14,20 do line(10+math.floor((y-14)/2),y,17-math.floor((y-14)/2),y,'e78038')end
 local word='HELADOS'
 for j=1,#word do local g=glyph[word:sub(j,j)];for y=1,5 do for x=1,3 do if g[y]:sub(x,x)=='1'then rect(26+(j-1)*6+x,y+7,1,1,'3b5d76')end end end end
 for x=27,68,7 do px(x,17,f==3 and 'd8943b' or 'fff6de')end
 if f==2 or f==4 then local x=f==2 and 70 or 6;line(x-2,6,x+2,6,'fff6de');line(x,4,x,8,'fff6de')end
 flush(f)
end;save('letrero_helados')

local bad=0;local pixels=0
for _,entry in ipairs(names)do local im=Image{fromFile=out..entry.name..'.png'};for p in im:pixels()do if pc.rgbaA(p())>0 then pixels=pixels+1;if not allowed[p()]then bad=bad+1 end end end end
assert(bad==0)
local report=io.open(base..'tests/part3_art.json','w');report:write(json.encode({assets=names,shared_colours=#master,off_palette_pixels=bad,opaque_pixels=pixels,passed=true}));report:close()
print('PART3_ART_OK: 5 editable ambient sources, 37 existing colours, 0 off-palette pixels')
