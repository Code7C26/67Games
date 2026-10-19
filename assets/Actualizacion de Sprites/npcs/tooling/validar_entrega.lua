
local root=app.fs.currentPath..'/generated/patogen-infecciones-proporciones-oct15'
local kinds={'sano_retoque','atletico','area','exponencial'}
local dirs={{'abajo','Abajo',2},{'arriba','Arriba',2},{'derecha','Derecha',4},{'izquierda','Izquierda',4}}
local result={npc={sets=21,directional_sheets=84,frames=252,types=5,variants={}},zones={}}
for _,kind in ipairs(kinds) do
 local mismatch,feet,alpha,changed=0,0,0,0
 for id=1,5 do
  local sp=app.open(root..'/npcs/'..kind..'/NPC_'..id..'.aseprite')
  assert(sp.width==32 and sp.height==32 and #sp.frames==12 and #sp.layers==3 and #sp.tags==4)
  local n=1
  for d,entry in ipairs(dirs) do
   local original=Image{fromFile=root..'/referencias/npc/NPC '..id..' '..entry[1]..'.png'}
   local png=Image{fromFile=root..'/npcs/'..kind..'/NPC '..id..' '..entry[1]..'.png'}
   assert(png.width==original.width and png.height==original.height)
   assert(sp.tags[d].name==entry[2] and sp.tags[d].fromFrame.frameNumber==n and sp.tags[d].toFrame.frameNumber==n+entry[3]-1)
   local cols=png.width//32
   for f=1,entry[3] do
    local im=Image(32,32,ColorMode.RGB);im:drawSprite(sp,n)
    assert(math.abs(sp.frames[n].duration-.2)<.001)
    local diff=0
    for y=0,31 do for x=0,31 do
     local px,py=((f-1)%cols)*32+x,math.floor((f-1)/cols)*32+y
     local c=im:getPixel(x,y);local exported=png:getPixel(px,py);local orig=original:getPixel(px,py)
     local a,oa=app.pixelColor.rgbaA(c),app.pixelColor.rgbaA(orig)
     if c~=exported and (a>0 or app.pixelColor.rgbaA(exported)>0) then mismatch=mismatch+1 end
     if y>=26 and a~=oa then feet=feet+1 end
     if kind=='sano_retoque' and a~=oa then alpha=alpha+1 end
     if c~=orig then diff=diff+1 end
    end end
    assert(diff>50);changed=changed+diff;n=n+1
   end
  end
  sp:close()
 end
 assert(mismatch==0 and feet==0 and alpha==0)
 result.npc.variants[kind]={png_source_pixel_mismatches=mismatch,footstep_alpha_mismatches=feet,human_silhouette_alpha_mismatches=alpha,changed_pixels=changed}
end

do
 local sp=app.open(root..'/npcs/exponencial_endgame/NPC_2.aseprite')
 assert(sp.width==48 and sp.height==32 and #sp.frames==12 and #sp.layers==3 and #sp.tags==4)
 local n,mismatch,feet,minConnection=1,0,0,1000
 for d,entry in ipairs(dirs) do
  local original=Image{fromFile=root..'/referencias/npc/NPC 2 '..entry[1]..'.png'}
  local png=Image{fromFile=root..'/npcs/exponencial_endgame/NPC 2 '..entry[1]..'.png'}
  local cols=entry[3]==2 and 1 or 2
  assert(png.width==cols*48 and png.height==64)
  assert(sp.tags[d].name==entry[2] and sp.tags[d].fromFrame.frameNumber==n and sp.tags[d].toFrame.frameNumber==n+entry[3]-1)
  for f=1,entry[3] do
   local im=Image(48,32,ColorMode.RGB);im:drawSprite(sp,n)
   local leftHead,rightHead,connection=0,0,0
   for y=0,31 do for x=0,47 do
    local c=im:getPixel(x,y);local a=app.pixelColor.rgbaA(c)
    local exported=png:getPixel(((f-1)%cols)*48+x,math.floor((f-1)/cols)*32+y)
    if c~=exported and (a>0 or app.pixelColor.rgbaA(exported)>0) then mismatch=mismatch+1 end
    if y<13 and a>0 then if x<24 then leftHead=leftHead+1 else rightHead=rightHead+1 end end
    if x>=21 and x<=26 and y>=6 and y<=14 and a>0 then connection=connection+1 end
    if y>=26 then
     local expected=0
     if x>=8 and x<40 then expected=app.pixelColor.rgbaA(original:getPixel(((f-1)%cols)*32+x-8,math.floor((f-1)/cols)*32+y)) end
     if a~=expected then feet=feet+1 end
    end
   end end
   assert(leftHead>50 and rightHead>50 and connection>25)
   minConnection=math.min(minConnection,connection)
   n=n+1
  end
 end
 assert(mismatch==0 and feet==0)
 result.npc.variants.exponencial_endgame={models=1,base_npc=2,heads=2,conjoined_tissue_pixels_min=minConnection,frame_size={48,32},directions=4,frames=12,png_source_pixel_mismatches=mismatch,footstep_alpha_mismatches=feet,body_offset={8,0}}
 sp:close()
end

for _,kind in ipairs({'caliente','fria'}) do
 local sp=app.open(root..'/zonas/assets/zona_'..kind..'.aseprite')
 local sheet=Image{fromFile=root..'/zonas/assets/zona_'..kind..'_sheet.png'}
 assert(#sp.frames==48 and #sp.layers==12 and sp.width==384 and sp.height==384 and sheet.width==3072 and sheet.height==2304)
 local mismatches,total,minInside,hashes,unique=0,0,100000,{},0
 for f=1,48 do
  total=total+sp.frames[f].duration
  local im=Image(384,384,ColorMode.RGB);im:drawSprite(sp,f)
  local particles=sp.layers[11]:cel(f);local mask=particles.image
  local count=0
  for y=0,mask.height-1 do for x=0,mask.width-1 do
   local xx,yy=x+particles.position.x,y+particles.position.y
   if (xx-191.5)^2+(yy-191.5)^2<100^2 and app.pixelColor.rgbaA(mask:getPixel(x,y))>50 then count=count+1 end
  end end
  minInside=math.min(minInside,count)
  local hash=0
  for y=0,383 do for x=0,383 do
   local c=im:getPixel(x,y);local a=app.pixelColor.rgbaA(c)
   local d=sheet:getPixel(((f-1)%8)*384+x,math.floor((f-1)/8)*384+y)
   if c~=d and (a>0 or app.pixelColor.rgbaA(d)>0) then mismatches=mismatches+1 end
   if x<2 or y<2 or x>381 or y>381 then assert(a==0,'Canvas border must be transparent') end
   if x%2==0 and y%2==0 then hash=(hash*31+c)%2147483647 end
  end end
  if not hashes[tostring(hash)] then unique=unique+1;hashes[tostring(hash)]=true end
 end
 assert(minInside>75 and mismatches==0 and unique==48 and math.abs(total-3)<.001)
 result.zones[kind]={size={384,384},logical_diameter=270,frames=48,layers=12,duration_ms=3000,unique_frames=unique,interior_particle_pixels_min=minInside,png_source_pixel_mismatches=mismatches}
 sp:close()
end
local preview=app.open(root..'/npcs/previews/npc_variantes.gif')
assert(#preview.frames==16)
local contact=Image(preview.width*2,preview.height*2,ColorMode.RGB)
for i,n in ipairs({1,5,9,13}) do
 local im=Image(preview.width,preview.height,ColorMode.RGB);im:drawSprite(preview,n)
 contact:drawImage(im,Point(((i-1)%2)*preview.width,math.floor((i-1)/2)*preview.height))
end
contact:saveAs(root..'/npcs/previews/control_direcciones.png')
preview:close()
for _,name in ipairs({'zonas_caliente_y_fria','sobre_piso_claro'}) do
 local sp=app.open(root..'/zonas/previews/'..name..'.gif')
 local duration=0;for _,f in ipairs(sp.frames) do duration=duration+f.duration end
 assert(#sp.frames==48 and math.abs(duration-3)<.001);sp:close()
end

local focus=app.open(root..'/npcs/previews/rediseno_infectados.gif')
assert(#focus.frames==16)
local contactFocus=Image(focus.width*2,focus.height*2,ColorMode.RGB)
for i,n in ipairs({1,5,9,13}) do
 local im=Image(focus.width,focus.height,ColorMode.RGB);im:drawSprite(focus,n)
 contactFocus:drawImage(im,Point(((i-1)%2)*focus.width,math.floor((i-1)/2)*focus.height))
end
contactFocus:saveAs(root..'/npcs/previews/rediseno_direcciones.png');focus:close()
result.npc.art_direction={athletic='compact red football helmet, warm flesh, lean arms, rebuilt side views',area='narrow human silhouette, localized bone and ochre fungal growth',endgame='one compact shared cranium, central fissure, short neck inside collar'}
local f=io.open(root..'/validacion.json','w');f:write(json.encode(result));f:close()
print(json.encode(result))

