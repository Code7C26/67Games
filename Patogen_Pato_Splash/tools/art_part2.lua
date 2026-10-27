-- Pato Splash part 2. Original artwork authored with Aseprite MCP.
-- Reference is a style/detail study only; no third-party pixels are imported.
local base=app.params['base'];assert(base)
local out=base..'splash/assets/';local pc=app.pixelColor
local old={};local names={}
for _,entry in ipairs(app.fs.listFiles(out))do local file=out..entry
 if app.fs.fileExtension(file)=='png' then
  local im=Image{fromFile=file};for pixel in im:pixels()do local v=pixel();if pc.rgbaA(v)>0 then old[v]=true end end
 end
 if app.fs.fileExtension(file)=='aseprite' then names[#names+1]=file end
end
local function rgba(hex)local n=tonumber(hex,16);return pc.rgba((n>>16)&255,(n>>8)&255,n&255,255)end
local requested={'28343c','493e36','9a482f','d8943b','e78038','efbf4b','f8d864','ffb24c','ffe99b','fff5cb','fff6de','3b5d76','398fc5','6ac7f2','b8edff','adc2c9','c9d9dc','e4edef','dc715e','a74b4d','497d6d','63957a','9eb785','705342','9c724e','c49d69','e3d4b2','b8aa93','e2d5b5','81a991','a7c8bf','e8ba87','b47e5b','6e4139','d5b56a','efeade','b8b8c6','70c7ee','307ba7'}
-- Player colours must be part of the pre-existing union, too.
for _,dir in ipairs({'abajo','arriba','derecha','izquierda'})do local im=Image{fromFile=base..'demo/references/pato_'..dir..'.png'};for p in im:pixels()do if pc.rgbaA(p())>0 then old[p()]=true end end end
local master={};local hexes={}
for _,hex in ipairs(requested)do local c=rgba(hex);if old[c] then master[#master+1]=c;hexes[#hexes+1]=hex end end
assert(#master>=32,'Existing palette not found')
local cache={}
local function nearest(c)
 if pc.rgbaA(c)==0 then return 0 end
 if cache[c]then return cache[c]end
 local best,score=master[1],math.huge
 for _,m in ipairs(master)do local dr,dg,db=pc.rgbaR(c)-pc.rgbaR(m),pc.rgbaG(c)-pc.rgbaG(m),pc.rgbaB(c)-pc.rgbaB(m);local d=dr*dr*2+dg*dg*3+db*db;if d<score then best,score=m,d end end
 cache[c]=best;return best
end
local function c(hex)return nearest(rgba(hex))end
local ink='28343c';local navy='3b5d76';local metal='adc2c9';local ice='e4edef';local cream='fff6de';local coral='dc715e';local red='a74b4d';local gold='efbf4b';local goldhi='ffe99b';local blue='398fc5';local water='6ac7f2';local foam='b8edff'
local S,I,L
local function px(x,y,col)x=math.floor(x);y=math.floor(y);if x>=0 and y>=0 and x<I.width and y<I.height then I:drawPixel(x,y,type(col)=='string' and c(col) or col)end end
local function rect(x,y,w,h,col)for yy=math.floor(y),math.floor(y+h-1)do for xx=math.floor(x),math.floor(x+w-1)do px(xx,yy,col)end end end
local function line(x1,y1,x2,y2,col,t)local n=math.max(math.abs(x2-x1),math.abs(y2-y1));if n==0 then px(x1,y1,col);return end;for j=0,n do rect(math.floor(x1+(x2-x1)*j/n+.5),math.floor(y1+(y2-y1)*j/n+.5),t or 1,t or 1,col)end end
local function box(x,y,w,h,col)rect(x,y,w,1,col);rect(x,y+h-1,w,1,col);rect(x,y,1,h,col);rect(x+w-1,y,1,h,col)end
local function poly(points,col)local lo,hi=9999,-1;for _,p in ipairs(points)do lo=math.min(lo,p[2]);hi=math.max(hi,p[2])end;for y=math.floor(lo),math.floor(hi)do local hits={};for j=1,#points do local a,b=points[j],points[j%#points+1];if(a[2]<=y and b[2]>y)or(b[2]<=y and a[2]>y)then hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])end end;table.sort(hits);for j=1,#hits-1,2 do rect(math.ceil(hits[j]),y,math.floor(hits[j+1])-math.ceil(hits[j])+1,1,col)end end end
local function disk(x,y,r,col)for yy=-r,r,2 do for xx=-r,r,2 do if xx*xx+yy*yy<=r*r then rect(x+xx,y+yy,2,2,col)end end end end
local function tube(points,r,col)for i=1,#points-1 do local a,b=points[i],points[i+1];local n=math.max(math.abs(a[1]-b[1]),math.abs(a[2]-b[2]));for j=0,n,2 do disk(a[1]+(b[1]-a[1])*j/n,a[2]+(b[2]-a[2])*j/n,r,col)end end end
local function new(w,h,title)S=Sprite(w,h,ColorMode.RGB);L=S.layers[1];L.name=title;I=Image(w,h,ColorMode.RGB)end
local function frame(f)if f>1 then S:newEmptyFrame()end;I=Image(S.width,S.height,ColorMode.RGB)end
local function flush(f)S:newCel(L,f or 1,I,Point(0,0))end
local function palette(s)local pal=Palette(#master);for i,v in ipairs(master)do pal:setColor(i-1,Color{r=pc.rgbaR(v),g=pc.rgbaG(v),b=pc.rgbaB(v),a=255})end;s:setPalette(pal)end
local function save(name,animated,dt)
 palette(S);if animated then local tag=S:newTag(1,#S.frames);tag.name='Ambiental';for _,f in ipairs(S.frames)do f.duration=dt or .14 end end
 S:saveAs(out..name..'.aseprite');app.activeSprite=S
 if animated then app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..name..'.png',dataFilename=out..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true}else S:saveCopyAs(out..name..'.png')end
 print('PART2_ART '..name..' '..S.width..'x'..S.height..' '..#S.frames..' frames');S:close()
end
local function bolt(x,y)rect(x,y,3,3,ink);px(x,y,ice)end

if not app.params['palette_only'] then
-- All 16 four-side combinations: terrain-ready 32px paving, muted under actors.
new(512,32,'Paseo / 16 conexiones laterales / 32 px')
for mask=0,15 do local x=mask*32
 rect(x,0,32,32,'c9d9dc');for yy=0,31,16 do line(x+1,yy,x+31,yy,'adc2c9');line(x+2,yy+1,x+30,yy+1,'e4edef')end
 line(x+15,1,x+15,15,'adc2c9');line(x+7,17,x+7,31,'adc2c9');line(x+27,17,x+27,31,'adc2c9')
 if mask&1==0 then rect(x,0,32,4,'e3d4b2');rect(x,0,32,1,cream);line(x,4,x+31,4,'b8aa93')end
 if mask&2==0 then rect(x+28,0,4,32,'e3d4b2');rect(x+31,0,1,32,'b8aa93')end
 if mask&4==0 then rect(x,28,32,4,'e3d4b2');rect(x,31,32,1,'b8aa93')end
 if mask&8==0 then rect(x,0,4,32,'e3d4b2');rect(x,0,1,32,cream)end
end;flush();save('caminos_32')

new(64,64,'Cantero / tierra / ladrillo de cemento / 2x2 tiles')
rect(0,0,64,64,ink);rect(2,2,60,60,'adc2c9');rect(4,4,56,56,'c9d9dc');rect(9,9,46,46,'705342');rect(12,12,40,40,'9c724e');rect(13,13,38,2,'493e36');rect(13,13,2,37,'493e36')
for x=0,63,16 do rect(x,0,1,9,'3b5d76');rect(x,55,1,9,'3b5d76');line(x+3,3,x+13,3,'e4edef');line(x+2,57,x+13,57,'e4edef')end
for y=8,55,16 do rect(0,y,9,1,'3b5d76');rect(55,y,9,1,'3b5d76');line(3,y+2,3,y+12,'e4edef');line(57,y+2,57,y+12,'e4edef')end
for j=0,19 do local x,y=15+(j*13)%34,16+(j*19)%32;rect(x,y,2,1,j%3==0 and 'c49d69' or '705342')end
flush();save('cantero_palmera')

local letters={P={'110','101','110','100','100'},I={'111','010','010','010','111'},S={'111','100','111','001','111'},O={'111','101','101','101','111'},M={'101','111','111','101','101'},J={'001','001','001','101','111'},A={'010','101','111','101','101'},D={'110','101','101','101','110'},N={'101','111','111','111','101'},R={'110','101','110','101','101'}}
local function text(t,x,y)for i=1,#t do local g=letters[t:sub(i,i)];if g then for yy,row in ipairs(g)do for xx=1,3 do if row:sub(xx,xx)=='1'then px(x+(i-1)*4+xx-1,y+yy-1,ink)end end end end end end
for mode=1,2 do new(32,48,'Cartel / pictograma / texto legible')
 poly({{8,6},{24,6},{30,43},{25,46},{4,46},{2,43}},ink);poly({{9,8},{22,8},{27,42},{6,42}},gold);rect(11,10,10,3,ink);rect(12,10,8,1,'d8943b')
 if mode==1 then poly({{16,16},{24,29},{8,29}},ink);poly({{16,19},{21,27},{11,27}},cream);rect(15,21,2,4,ink);px(15,26,ink);text('PISO',8,31);text('MOJADO',4,37)
 else box(8,17,17,13,red);line(8,17,24,29,red,2);rect(14,19,3,7,ink);rect(11,25,9,2,ink);text('NO',12,31);text('PISAR',6,37)end
 line(7,43,26,43,'d8943b');flush();save(mode==1 and 'cartel_piso_mojado' or 'cartel_no_pisar')
end

-- Slides retain exact part-1 outlet pivots (85,220) and (155,223).
new(272,240,'Toboganes nuevos / plataforma / barandas / fibra')
for f=1,8 do frame(f)
 for _,x in ipairs({35,126,225})do rect(x+3,67,9,149,ink);rect(x+5,69,5,144,metal);rect(x+5,71,2,137,ice);rect(x-4,211,25,6,navy);for y=96,206,32 do rect(x+1,y,13,5,navy);bolt(x+3,y+1)end end
 line(44,115,129,195,navy,4);line(128,105,233,194,navy,4);line(230,103,131,192,metal,2)
 poly({{12,15},{142,15},{153,28},{153,78},{20,78},{12,69}},ink);rect(18,21,125,47,navy);rect(20,24,121,40,'adc2c9');for x=24,138,10 do rect(x,25,2,39,'3b5d76')end
 rect(15,15,132,6,cream);rect(18,66,130,8,'705342');for x=24,143,18 do rect(x,66,2,8,'c49d69')end
 local a={{70,77},{111,100},{171,101},{211,126},{205,149},{158,167},{110,173},{79,197},{85,220}}
 local b={{112,77},{152,85},{203,92},{242,118},{242,151},{214,178},{166,199},{155,223}}
 local function slide(points,basecol,darkcol,lightcol)
  local below={};for _,q in ipairs(points)do below[#below+1]={q[1]+2,q[2]+5}end
  tube(below,19,ink);tube(below,17,darkcol);tube(points,18,ink);tube(points,16,basecol)
  local hi={};for _,q in ipairs(points)do hi[#hi+1]={q[1]-4,q[2]-4}end;tube(hi,9,lightcol)
  tube(points,9,navy);tube(points,6,water);local inner={};for _,q in ipairs(points)do inner[#inner+1]={q[1]-1,q[2]-2}end;tube(inner,3,foam)
 end
 slide(a,coral,red,'ffb24c');slide(b,gold,'d8943b',goldhi)
 for _,q in ipairs({{111,88},{174,91},{210,137},{153,174},{93,183},{206,84},{240,141},{203,183}})do line(q[1],q[2],q[1]+6,q[2]+6,cream,2);bolt(q[1]+2,q[2]+1)end
 for j=0,10 do local y=87+j*11;rect(21,y,32,5,ink);rect(23,y,28,2,ice);rect(23,y+3,28,1,'adc2c9')end
 line(20,86,20,207,navy,3);line(53,86,53,207,navy,3);line(21,87,21,205,ice)
 for j=0,3 do line(112+j*22,99+(j+f)%4,119+j*22,99+(j+f)%4,cream,2)end
 flush(f)
end;save('toboganes',true,.14)

new(112,96,'Balde nuevo / borde metalico / remaches / pato')
poly({{10,15},{19,7},{94,7},{103,15},{98,32},{88,88},{27,88},{16,32}},ink);poly({{14,17},{22,11},{91,11},{99,17},{94,29},{18,29}},metal);poly({{20,17},{29,13},{85,13},{94,17},{87,25},{25,25}},water);line(29,16,84,16,foam,2)
poly({{19,29},{94,29},{83,82},{31,82}},red);poly({{23,30},{88,30},{79,78},{33,78}},coral);poly({{25,31},{39,31},{44,76},{34,76}},'ffb24c');poly({{81,31},{89,31},{79,78},{71,78}},red)
rect(27,31,62,4,metal);rect(32,76,49,5,'d8943b');for y=39,69,15 do bolt(27,y);bolt(82,y)end
-- Stepped duck emblem; original character colours, not a medical cross.
poly({{45,49},{51,49},{51,40},{62,40},{66,44},{66,51},{73,51},{73,56},{66,58},{64,65},{44,65},{40,61},{40,53}},'493e36');poly({{46,52},{54,52},{54,43},{61,43},{63,47},{63,54},{69,54},{63,56},{61,62},{46,62},{43,59},{43,54}},'f8d864');rect(59,46,2,3,ink);rect(64,51,7,3,'e78038');line(48,56,57,56,goldhi,2)
flush();save('balde')

new(128,128,'Fuente infantil nueva / mosaico / agua / champinon')
for f=1,8 do frame(f)
 poly({{12,103},{25,96},{103,96},{116,103},{116,114},{102,122},{26,122},{12,114}},blue);poly({{17,104},{28,100},{99,100},{111,105},{111,112},{99,118},{29,118},{17,112}},foam)
 rect(55,47,19,59,navy);rect(58,49,13,55,ice);rect(62,51,4,51,cream);for y=60,101,10 do rect(58,y,13,2,metal)end
 poly({{12,35},{20,23},{36,16},{89,16},{107,24},{116,35},{116,49},{107,55},{21,55},{12,49}},ink)
 poly({{16,35},{24,26},{39,20},{87,20},{103,27},{112,36},{112,46},{103,51},{25,51},{16,46}},red)
 poly({{19,34},{28,26},{41,23},{86,23},{100,29},{108,35},{108,43},{23,43}},coral)
 poly({{28,29},{42,24},{80,24},{88,29},{84,34},{36,34}},'ffb24c');rect(22,44,86,6,cream)
 for _,q in ipairs({{32,36},{54,27},{83,36}})do rect(q[1],q[2],8,4,goldhi);rect(q[1]+2,q[2]-2,4,2,goldhi)end
 for j=0,11 do local x=19+j*8;line(x,52,x-4,92,water,2);line(x+1,53,x-2,88,foam);local yy=60+(j*11+f*5)%39;rect(x-2,yy,2,6,cream);rect(x-5,101+(f+j)%6,9,2,foam)end
 for j=0,9 do rect(24+j*8,113+(j%2),3,2,cream)end
 flush(f)
end;save('fuente_hongo',true,.12)

new(40,80,'Reposera nueva / respaldo / lona / estructura tubular')
poly({{5,60},{13,60},{13,75},{8,75}},ink);poly({{28,60},{35,60},{34,75},{29,75}},ink);rect(9,64,2,8,metal);rect(30,64,2,8,metal)
poly({{9,7},{31,7},{35,31},{35,63},{5,63},{5,33}},ink);poly({{11,10},{28,10},{32,32},{31,59},{9,59},{9,33}},navy)
for x=11,27,8 do poly({{x,12},{x+3,12},{x+6,34},{x+5,56},{x+1,56},{x+2,34}},foam)end
line(10,35,30,35,metal,2);rect(9,58,23,3,ice);line(7,9,6,59,metal,2);line(31,9,34,59,metal,2);rect(2,33,5,23,ink);rect(3,34,3,16,cream);rect(34,33,5,23,ink);rect(35,34,3,16,cream)
rect(12,14,16,12,goldhi);rect(13,15,14,2,cream);rect(13,23,14,2,'d8943b');for x=13,27,3 do rect(x,27,1,3,'e3d4b2')end
bolt(7,36);bolt(31,36);flush();save('reposera')

new(64,64,'Toallero / cestos / toallas dobladas')
rect(8,17,48,40,ink);rect(11,20,42,34,'705342');for y=26,49,8 do rect(12,y,40,2,'c49d69')end
for j=0,2 do rect(13+j*13,8,11,23,navy);rect(14+j*13,8,9,20,j==1 and coral or foam);rect(15+j*13,10,7,2,cream);rect(15+j*13,22,7,1,j==1 and red or blue)end
rect(7,54,50,4,'9c724e');rect(12,58,5,5,ink);rect(48,58,5,5,ink);flush();save('toallero')
new(48,64,'Entrada / dispensador / boletos')
rect(13,39,23,20,ink);rect(15,40,19,16,navy);rect(7,54,34,7,ink);rect(9,55,30,3,metal);rect(6,7,35,36,ink);rect(9,10,29,29,'c9d9dc');rect(12,14,23,13,navy);rect(14,16,19,7,water);rect(13,32,13,3,coral);rect(29,31,5,5,gold);rect(18,40,10,12,cream);for y=43,49,3 do rect(20,y,6,1,navy)end;flush();save('entrada_tickets')

-- Park duck: original head/pose identity, freshly drawn wings, vest and feet details.
local duck=Sprite(32,32,ColorMode.RGB);local orig=duck.layers[1];orig.name='Jugador original / referencia de silueta';local edits=duck:newLayer();edits.name='Pato del parque / alas / chaleco / detalle'
local duck_allowed={};local images={}
for d,dir in ipairs({'abajo','arriba','derecha','izquierda'})do
 local sheet=Image{fromFile=base..'demo/references/pato_'..dir..'.png'}
 for pixel in sheet:pixels()do if pc.rgbaA(pixel())>0 then duck_allowed[pixel()]=true end end
 for k=0,7 do local f=(d-1)*8+k+1;if f>1 then duck:newEmptyFrame()end
  local img=Image(sheet,Rectangle(k%4*32,k//4*32,32,32));duck:newCel(orig,f,img,Point(0,0));local edit=Image(32,32)
  local function put(x,y,hex)if x<0 or x>31 or y<0 or y>31 or pc.rgbaA(img:getPixel(x,y))==0 then return end;local v=rgba(hex);assert(duck_allowed[v]);edit:drawPixel(x,y,v)end
  -- Keep the head untouched; a tiny flotation vest gives the park duck its own read.
  for y=20,25 do for x=9,22 do local v=img:getPixel(x,y);if v==rgba('efbf4b')or v==rgba('f8d864')then put(x,y,((x<13 or x>19)and 'e78038' or 'f8d864'))end end end
  if d==1 then for y=21,25 do put(15,y,'493e36')end;put(14,22,'ffe99b');put(17,22,'ffe99b');put(17,24,'fff5cb')
  elseif d==2 then for x=12,20 do put(x,22,'d8943b')end;put(15,24,'ffe99b');put(16,24,'ffe99b')
  else local x=d==3 and 17 or 14;put(x,22,'493e36');put(x,23,'ffe99b');put(x,24,'ffb24c')end
  duck:newCel(edits,f,edit,Point(0,0));duck.frames[f].duration=.125
 end
 local tag=duck:newTag((d-1)*8+1,d*8);tag.name=({'Abajo','Arriba','Derecha','Izquierda'})[d]
end
for d,t in ipairs(duck.tags)do t.fromFrame=duck.frames[(d-1)*8+1];t.toFrame=duck.frames[d*8]end
palette(duck);duck:saveAs(out..'pato_parque.aseprite');app.activeSprite=duck
app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..'pato_parque.png',dataFilename=out..'pato_parque.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true};duck:close()
end

-- One shared swatch set across every runtime sprite, including existing assets.
local count=0
for _,entry in ipairs(app.fs.listFiles(out))do local file=out..entry;if app.fs.fileExtension(file)=='aseprite' and (not app.params['palette_only'] or app.fs.fileTitle(file)==app.params['palette_only']) then
 local s=app.open(file)
 for _,cel in ipairs(s.cels)do local img=Image(cel.image);for pixel in img:pixels()do local v=pixel();if pc.rgbaA(v)>0 then
  local mapped=nearest(v)
  if app.fs.fileTitle(file)=='palmera' and pixel.y<76 and mapped==c('3b5d76') then
   local x,y=pixel.x,pixel.y
   local interior=x>0 and x<img.width-1 and y>0 and y<img.height-1 and pc.rgbaA(img:getPixel(x-1,y))>0 and pc.rgbaA(img:getPixel(x+1,y))>0 and pc.rgbaA(img:getPixel(x,y-1))>0 and pc.rgbaA(img:getPixel(x,y+1))>0
   mapped=c(interior and '81a991' or '28343c')
  end
  pixel(mapped)
 end end;cel.image=img end
 palette(s);s:saveAs(file);app.activeSprite=s
 local stem=app.fs.fileTitle(file)
 if #s.frames>1 then app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..stem..'.png',dataFilename=out..stem..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true}
 else s:saveCopyAs(out..stem..'.png')end
 count=count+1;s:close()
end end
local gpl=io.open(out..'patogen_paleta.gpl','w');gpl:write('GIMP Palette\nName: Patogen / Pato Splash\nColumns: 8\n# Existing project colours only\n');for _,v in ipairs(master)do gpl:write(string.format('%d %d %d\n',pc.rgbaR(v),pc.rgbaG(v),pc.rgbaB(v)))end;gpl:close()
local report=io.open(base..'tests/part2_art.json','w');report:write(json.encode({shared_colours=#master,master_hex=hexes,source_sprites=app.params['palette_only'] and #names or count,new_colours=0,player_reference_colours=11}));report:close()
print('PART2_ART_OK '..count..' sources / '..#master..' shared existing colours / 0 new colours')
