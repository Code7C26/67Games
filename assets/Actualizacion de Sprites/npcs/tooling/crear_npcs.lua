
local root=app.params.output or app.fs.currentPath..'/generated/patogen-infecciones-proporciones-oct15'
local output=root..'/npcs'
app.fs.makeAllDirectories(output..'/previews')
local img
local function color(s,a) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),a or 255) end
local function key(c) return string.format('%02x%02x%02x',app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c)) end
local function p(x,y,c) x,y=math.floor(x+.5),math.floor(y+.5);if x>=0 and y>=0 and x<img.width and y<img.height then img:drawPixel(x,y,type(c)=='string' and color(c) or c) end end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
local function line(x,y,x2,y2,c)
 x,y,x2,y2=math.floor(x+.5),math.floor(y+.5),math.floor(x2+.5),math.floor(y2+.5)
 local dx,sx=math.abs(x2-x),x<x2 and 1 or -1;local dy,sy=-math.abs(y2-y),y<y2 and 1 or -1;local e=dx+dy
 while true do p(x,y,c);if x==x2 and y==y2 then break end;local v=2*e;if v>=dy then e=e+dy;x=x+sx end;if v<=dx then e=e+dx;y=y+sy end end
end
local function oval(x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do if ((xx+.5-x-w/2)/(w/2))^2+((yy+.5-y-h/2)/(h/2))^2<=1 then p(xx,yy,c) end end end
end
local function poly(pts,c)
 local ymin,ymax=999,-999;for _,q in ipairs(pts) do ymin=math.min(ymin,q[2]);ymax=math.max(ymax,q[2]) end
 for y=math.ceil(ymin),math.floor(ymax) do local nodes={};local j=#pts
  for i=1,#pts do local a,b=pts[i],pts[j];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then nodes[#nodes+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end;j=i end
  table.sort(nodes);for i=1,#nodes-1,2 do for x=math.ceil(nodes[i]),math.floor(nodes[i+1]) do p(x,y,c) end end
 end
end
local function mixed(a,b,t)
 local function ch(s,i) return tonumber(s:sub(i,i+1),16) end
 return string.format('%02x%02x%02x',math.floor(ch(a,1)*(1-t)+ch(b,1)*t+.5),math.floor(ch(a,3)*(1-t)+ch(b,3)*t+.5),math.floor(ch(a,5)*(1-t)+ch(b,5)*t+.5))
end
local palettes={
 {c81414='b84f56',ae163e='813d50',ffffff='efeade',e6d0cd='b8b8c6',['81979b']='7b8898',['76788c']='4d5d73',aea735='bc995c',['8ea631']='77634d'},
 {a5ed43='96b96b',['49e46a']='51846e',['430909']='6e4139',['320808']='452e37',ac7a7a='98756f',['8a6161']='644f61',ffffff='d9d5c9',efe1e1='99969c'},
 {fff559='d5b56a',e4db45='9a8050',e245e4='a875bc',d33b92='75537f',['3bfff8']='6aafb2',['369aec']='456f93',['5f5858']='3b3b4c',['8c8585']='797989'},
 {['0a5c0a']='365b47',['57760e']='768155'},
 {cf00ff='9774c3',['9f00ea']='674a91',['430909']='6c403a',['320808']='3b2936',['76788c']='748195',['8c8585']='4b566d',f7bbf5='dec9dd',d3b2e6='93829f'}
}
local shirts={{c81414=true,ae163e=true},{a5ed43=true,['49e46a']=true},{e245e4=true,d33b92=true},{['0a5c0a']=true,['57760e']=true},{cf00ff=true,['9f00ea']=true}}
local types={'sano_retoque','atletico','area','exponencial'}
local infection={
 atletico={skin='c5ad8a',shadow='8c7158',tint='997653',eye='f6dfa1'},
 area={skin='bfb19a',shadow='8b7b66',tint='a38967',eye='cbbd90'},
 exponencial={skin='bbb0d0',shadow='827197',tint='8a73ae',eye='b8f4de'}
}
local dirs={{'abajo','Abajo',2},{'arriba','Arriba',2},{'derecha','Derecha',4},{'izquierda','Izquierda',4}}
local sources={}
for id=1,5 do sources[id]={}
 for _,d in ipairs(dirs) do
  local im=Image{fromFile=root..'/referencias/npc/NPC '..id..' '..d[1]..'.png'}
  local list={}
  local cols=im.width//32
  for f=1,d[3] do local small=Image(32,32,ColorMode.RGB)
   for y=0,31 do for x=0,31 do small:drawPixel(x,y,im:getPixel(((f-1)%cols)*32+x,math.floor((f-1)/cols)*32+y)) end end
   list[f]=small
  end;sources[id][d[1]]=list
 end
end
local function retouch(src,id,kind)
 local out=Image(32,32,ColorMode.RGB)
 for y=0,31 do for x=0,31 do
  local c=src:getPixel(x,y)
  if app.pixelColor.rgbaA(c)>0 then
   local k=key(c);local s=palettes[id][k] or k
   if k=='000000' then s='292638'
   elseif k=='ffc46f' then s=(infection[kind] and infection[kind].skin) or 'e8ba87'
   elseif k=='de9f5f' then s=(infection[kind] and infection[kind].shadow) or 'b47e5b'
   elseif infection[kind] then
    local amount=(y>=15 and shirts[id][k]) and .37 or .13
    s=mixed(s,infection[kind].tint,amount)
   end
   if y>=17 and y<=21 and shirts[id][k] and x>0 then
    local prev=src:getPixel(x-1,y)
    if key(prev)~=k and app.pixelColor.rgbaA(src:getPixel(math.min(31,x+1),y))>0 then s=mixed(s,'f6e9d5',.12) end
   end
   out:drawPixel(x,y,color(s))
  end
 end end
 if kind=='atletico' or kind=='area' then for yy=0,23 do for xx=0,31 do out:drawPixel(xx,yy,0) end end end
 return out
end
local function onbody(src,x,y,c)
 if x>=0 and y>=0 and x<32 and y<32 and app.pixelColor.rgbaA(src:getPixel(x,y))>0 then p(x,y,c) end
end
local function bodyline(src,x,y,x2,y2,c)
 local dx,dy=x2-x,y2-y;local n=math.max(math.abs(dx),math.abs(dy))
 for i=0,n do local xx,yy=math.floor(x+dx*i/math.max(1,n)+.5),math.floor(y+dy*i/math.max(1,n)+.5);onbody(src,xx,yy,c) end
end
local function plate(x,y,flip)
 local f=flip or 1
 poly({{x-f*3,y-2},{x+f*1,y-2},{x+f*2,y},{x+f*1,y+3},{x-f*2,y+2}},'442b40')
 poly({{x-f*2,y-1},{x+f*1,y},{x,y+2},{x-f*2,y+1}},'9d5263')
 line(x-f*2,y-1,x+f*1,y,'e78d81')
 p(x-f*1,y+1,'be6570')
end
local function sac(x,y,r,phase)
 oval(x-r,y-r,r*2+1,r*2+1,'29473b')
 oval(x-r+1,y-r,r*2-1,r*2,'56875b')
 oval(x-r+1,y-r+1,r*2-1,r*2-1,'85b970')
 p(x,y,phase%2==0 and 'cce994' or 'aed17b')
 p(x-1,y-1,'b8dd8b');p(x+1,y+1,'466f55')
end
local function node(x,y,r,phase)
 oval(x-r,y-r,r*2+1,r*2+1,'34304f')
 oval(x-r+1,y-r,r*2-1,r*2,'80619e')
 p(x,y,phase%2==0 and 'aaf2d8' or '79cbb9')
 p(x-1,y-1,'c4a7dc')
end
local function mutations(src,kind,dir,f)
 if kind=='sano_retoque' then return end
 local side=dir=='derecha' or dir=='izquierda'
 local back=dir=='arriba'
 local facing=dir=='derecha' and 1 or -1
 local bob=(f-1)%2
 if kind=='atletico' then
  if side then
   plate(17,17,dir=='derecha' and -1 or 1)
   bodyline(src,16,19,19,22,'bd6e78')
   bodyline(src,13,21,16,23,'e5a18b')
  else
   plate(8,17,1);plate(24,17,-1)
   bodyline(src,12,18,14,21,'b65e6b');bodyline(src,20,18,18,21,'b65e6b')
   if back then
    bodyline(src,16,15,16,22,'6a3b53')
    for y=16,21,2 do onbody(src,16,y,'e59086');onbody(src,15,y,'ad586a') end
   else
    bodyline(src,14,21,18,21,'e0a08a');onbody(src,16,19,'c67779')
   end
  end
  -- Tendon patches follow the hands from the original animation.
  for y=18,24 do for x=0,31 do local k=key(src:getPixel(x,y))
   if k=='ffc46f' or k=='de9f5f' then p(x,y,(x+y)%3==0 and 'd39283' or '98616c') end
  end end
 elseif kind=='area' then
  if side then
   local x=dir=='derecha' and 10 or 22
   sac(x,16,2,f);sac(x,20,2,f+1);sac(x+facing,12,1,f)
   bodyline(src,16,21,19,23,'668f59')
  else
   sac(7,17,2,f);sac(24,17,2,f+1)
   if back then sac(16,18,3,f);sac(13,21,1,f+1);sac(20,20,1,f)
   else sac(11,15,1,f);sac(21,15,1,f+1);onbody(src,16,21,'a1c873');onbody(src,15,22,'56875b') end
  end
  for x=11,21,3 do onbody(src,x,23,'4e7753');onbody(src,x,22,'85ad67') end
 else
  if side then
   local x=dir=='derecha' and 11 or 21
   node(x,16,2,f);node(x-facing*2,19,1,f+1)
   bodyline(src,x,17,17,21,'9279b7');bodyline(src,17,21,19,22,'a2dccb')
   node(17,21,1,f)
  else
   if back then
    bodyline(src,16,14,16,22,'635083');bodyline(src,12,17,19,21,'b297d0')
    node(14,17,2,f);node(19,19,2,f+1);node(15,22,1,f)
   else
    bodyline(src,13,17,17,22,'6b538e');bodyline(src,20,18,17,22,'b6a1d6')
    node(10,17,2,f);node(22,18,1,f+1);node(17,21,1,f)
   end
  end
 end
end
local function living(src,kind,dir,f)
 if kind=='sano_retoque' then return end
 local eye=infection[kind].eye
 if dir~='arriba' then
  for y=9,14 do for x=2,29 do
   local c=src:getPixel(x,y)
   if app.pixelColor.rgbaA(c)>0 and key(c)=='000000' then
    local a,b=key(src:getPixel(x-1,y)),key(src:getPixel(x+1,y))
    if (a=='ffc46f' or a=='de9f5f') and (b=='ffc46f' or b=='de9f5f') then p(x,y,eye) end
   end
  end end
 end
 if kind=='area' then
  local phase=(f-1)%2
  p(4+phase,12-phase,color('a4d28a',165));p(27-phase,14+phase,color('cadf9b',145))
  p(6,9+phase,color('688f68',115))
 elseif kind=='exponencial' then
  if dir=='arriba' then p(14,17,'d1f8e7');p(19,19,'a7ded0')
  elseif dir=='abajo' then p(10,17,'c0f0dd');p(17,21,'d1f8e7')
  else p(dir=='derecha' and 11 or 21,16,'c0f0dd') end
 elseif dir~='arriba' then
  bodyline(src,12,14,14,15,'b76776')
 end
end

-- Redesign from the supplied references: warm flesh, sports helmet and fungal armor.
local A={ink='3b302c',shade='8c7158',skin='c5ad8a',light='e5cba7',crease='a18b6c',red='b43637',redshade='6f292f',redlight='e7735e',metal='a5afb0',steel='535d65',white='eee4ce'}
local F={ink='453b32',shade='8b7b66',skin='bfb19a',light='deceb1',rust='b67e51',rim='e0b07b',dark='704d39',pore='563c30'}
local function mirror_current()
 local old=img;local flipped=Image(old.width,old.height,ColorMode.RGB)
 for y=0,old.height-1 do for x=0,old.width-1 do flipped:drawPixel(old.width-1-x,y,old:getPixel(x,y)) end end
 img=flipped
end

-- Compact silhouette pass: readable anatomy at 32 px, with distinct directional poses.
local function helmet(dir)
 if dir=='abajo' or dir=='arriba' then
  oval(6,2,20,12,A.ink);oval(7,3,18,10,A.redshade);oval(8,3,16,8,A.red)
  poly({{9,5},{12,3},{19,3},{23,6},{18,5},{11,6}},A.redlight)
  rect(15,3,2,6,A.white);p(15,3,'fff0d7')
  if dir=='arriba' then
   rect(15,9,2,3,'d2c9b8');line(9,10,11,10,A.redlight);line(21,10,23,10,A.redlight)
   rect(12,13,8,1,A.steel);rect(14,13,4,1,A.metal)
  else
   poly({{9,8},{22,8},{23,11},{21,14},{11,14},{8,11}},A.ink)
   rect(10,9,12,4,A.skin)
   line(11,9,13,10,'614b37');line(18,10,21,9,'614b37')
   p(12,10,'eacb83');p(20,10,'eacb83')
   rect(13,12,7,2,'654331');p(14,12,'e7d0a8');p(18,12,'e7d0a8');p(17,13,'b16f58')
   line(8,10,9,14,A.steel);line(23,10,22,14,A.steel)
   line(9,11,22,11,A.steel);line(10,14,21,14,A.metal)
   p(10,13,A.white);p(21,13,A.white)
  end
 else
  oval(11,2,16,12,A.ink);oval(12,3,14,10,A.redshade);oval(13,3,12,8,A.red)
  poly({{13,5},{16,3},{21,3},{24,6},{18,5}},A.redlight)
  line(18,3,21,6,A.white);p(19,3,'f3e5cc')
  poly({{21,7},{25,7},{26,9},{27,10},{26,12},{23,13},{21,11}},A.ink)
  rect(22,8,4,4,A.skin);p(26,10,A.light);p(24,9,'eacb83')
  p(25,12,'e7d0a8');p(24,12,'704635')
  rect(20,9,2,3,A.redshade);p(20,10,A.metal)
  line(22,11,27,11,A.steel);line(27,11,26,14,A.metal);line(22,14,26,14,A.steel)
  p(14,6,'db9d81')
 end
end
local function athletic(src,id,dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 local step=({0,1,0,-1})[(f-1)%4+1]
 local cloth=({'b84f56','96b96b','a875bc','768155','9774c3'})[id]
 if side then
  poly({{14,13},{20,13},{23,17},{21,23},{19,24},{11,24},{11,18}},A.ink)
  poly({{14,14},{19,14},{21,17},{20,22},{13,23},{12,18}},A.shade)
  poly({{15,15},{19,15},{21,18},{19,21},{14,21},{13,18}},A.skin)
  line(17,16,20,17,A.light);line(14,21,19,22,A.crease)
  -- Far arm trails behind; near arm drives the running pose.
  poly({{11,15},{14,16},{13,20},{11-step,23},{9-step,22},{10,19}},A.ink)
  line(11,17,11,20,A.skin);rect(10-step,21,3,3,A.skin);p(10-step,21,A.light)
  poly({{19,15},{22,16},{23,19},{25+step,20},{25+step,23},{22+step,23},{21,20},{19,19}},A.ink)
  line(20,16,22,19,A.skin);line(22,19,23+step,21,A.skin)
  rect(22+step,21,3,3,A.skin);p(23+step,21,A.light)
  poly({{13,14},{16,14},{15,17},{13,16}},'d7d1bf');p(14,14,'eee3ce')
  line(13,23,20,23,cloth)
 else
  poly({{11,13},{20,13},{23,17},{22,23},{10,23},{9,17}},A.ink)
  poly({{12,14},{19,14},{21,17},{20,22},{11,22},{10,17}},A.shade)
  poly({{12,15},{19,15},{20,18},{19,22},{12,22},{11,18}},A.skin)
  if dir=='arriba' then
   line(15,15,16,21,A.crease);line(12,17,14,18,A.light);line(18,18,20,17,A.light)
   poly({{11,14},{14,14},{13,16},{11,16}},'d7d1bf')
   p(19,15,'d7d1bf');p(20,16,'bbb39f')
  else
   line(12,16,14,16,A.light);line(18,16,20,16,A.light)
   p(16,17,A.shade);line(13,19,15,20,A.crease);line(18,20,20,19,A.crease)
   poly({{11,14},{13,14},{12,17},{10,16}},'d7d1bf')
   poly({{19,14},{21,15},{21,17},{19,16}},'d7d1bf')
  end
  -- Hanging arms avoid the previous horizontal, over-wide forearm bar.
  oval(6,15,5,7,A.ink);oval(7,16,3,5,A.skin);p(7,16,A.light)
  oval(21,15,5,7,A.ink);oval(22,16,3,5,A.skin);p(23,16,A.light)
  rect(7+step,21,4,4,A.ink);rect(8+step,21,2,3,A.skin);p(8+step,21,A.light)
  rect(21-step,20,4,4,A.ink);rect(22-step,20,2,3,A.skin);p(22-step,20,A.light)
  line(11,23,21,23,cloth)
 end
 -- A short neck is mostly hidden by helmet and shoulders.
 rect(14,13,4,3,A.shade);helmet(dir)
 if dir=='izquierda' then mirror_current() end
end
local function growth(x,y,w,h)
 -- Small scalloped clusters rather than parallel horizontal armor bands.
 poly({{x,y+2},{x+1,y},{x+3,y+1},{x+4,y},{x+w-2,y+1},{x+w-1,y+h-2},{x+w-3,y+h},{x+2,y+h-1}},F.dark)
 oval(x+1,y+1,w-2,h-1,F.rust)
 line(x+1,y+1,x+3,y+2,F.rim);p(x+w-3,y+1,'cea374')
 p(x+2,y+h-2,'835b40');p(x+w-3,y+h-1,'ad754e')
end
local function pore(x,y)
 p(x-1,y,F.dark);p(x,y-1,F.dark);p(x+1,y,F.dark);p(x,y+1,F.dark)
 p(x,y,'b28559');p(x-1,y-1,'d4b382')
end
local function fungal(src,id,dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 local step=({0,1,0,-1})[(f-1)%4+1]
 local cloth=({'b84f56','96b96b','a875bc','768155','9774c3'})[id]
 if side then
  poly({{14,13},{20,13},{23,16},{23,23},{19,25},{11,24},{10,18}},F.ink)
  oval(11,14,12,11,F.shade);oval(13,15,9,8,F.skin)
  line(15,17,20,17,F.light);line(16,20,21,20,'cab99c')
  oval(9,16,5,7,F.ink);oval(10,17,3,5,F.skin)
  oval(21,16,5,7,F.ink);oval(22,17,3,5,F.skin)
  rect(22+step,21,5,4,F.ink);rect(23+step,21,3,3,F.skin);p(24+step,21,F.light)
  growth(9,14,7,4);pore(11,19);growth(15,20,6,4)
  oval(11,3,15,13,F.ink);oval(13,5,12,10,F.shade)
  poly({{20,7},{24,8},{25,10},{27,11},{25,12},{24,14},{20,14},{18,11}},F.skin)
  p(24,9,'725c3f');p(25,11,F.light);p(24,13,'655140')
  growth(13,2,7,4);growth(10,5,8,4);growth(13,8,7,4);pore(15,6)
  line(13,24,20,24,cloth)
 else
  poly({{11,13},{21,13},{24,17},{23,23},{20,25},{10,25},{8,20},{8,16}},F.ink)
  oval(9,14,14,11,F.shade);oval(10,15,12,9,F.skin)
  line(12,16,15,17,F.light);line(18,17,21,16,F.light)
  line(12,20,15,21,'cbbc9e');line(18,21,21,20,'cbbc9e')
  line(16,16,16,22,'99866a')
  oval(5,15,6,8,F.ink);oval(6,16,4,6,F.skin)
  oval(22,15,5,8,F.ink);oval(23,16,3,6,F.skin)
  rect(6+step,21,5,4,F.ink);rect(7+step,22,3,3,F.skin)
  rect(22-step,21,5,4,F.ink);rect(23-step,22,3,3,F.skin)
  growth(5,13,8,4);pore(8,18);growth(18,20,7,4)
  if dir=='arriba' then growth(12,15,8,4);pore(20,17) else p(12,18,F.shade);p(20,18,F.shade) end
  oval(8,3,17,13,F.ink);oval(9,4,15,11,F.shade)
  if dir=='arriba' then
   oval(10,5,13,9,F.skin);growth(9,2,8,4);growth(16,4,8,4);growth(9,8,8,4)
   pore(19,10);line(14,13,18,13,F.shade)
  else
   oval(13,7,10,8,F.skin);p(20,10,'765c3f');p(21,10,'c6b183')
   line(18,13,20,13,'78634c');p(22,12,'d3c2a2')
   growth(9,2,8,4);growth(16,3,7,4);growth(7,6,8,4);growth(11,10,7,4)
   pore(11,7);p(17,8,F.dark)
  end
  line(11,24,21,24,cloth)
 end
 if dir=='izquierda' then mirror_current() end
end
local function endgame_head(dir,f)
 local ink='332d41';local skin='b6a8c6';local shade='867896';local light='d0bfd7'
 local hair='50343a';local hairhi='735057';local eye='bdebd7'
 local pulse=(f==2 or f==3) and 1 or 0
 if dir=='abajo' or dir=='arriba' then
  -- One continuous cranium, two shallow lobes and a very small central cleft.
  poly({{14,4},{18,2},{22,3},{25,3},{29,2},{33,3},{35,6},{36,10},{34,14},{30,16},{25,16},{23,15},{20,16},{15,14},{12,10},{12,7}},ink)
  oval(13,5,13,11,shade);oval(23,5,12,11,shade)
  rect(21,7,6,7,shade)
  if dir=='arriba' then
   poly({{14,5},{18,3},{23,4},{28,3},{33,5},{34,9},{32,13},{27,15},{21,15},{16,13},{14,10}},hair)
   line(16,6,21,8,hairhi);line(27,7,32,6,hairhi);line(17,10,21,12,'65434d')
   line(24,5,23,9,'3e2d3a');line(23,9,24,13,'3e2d3a')
   p(24,9+ pulse,'956879');p(25,13,'a18caa')
  else
   oval(14,7,11,9,skin);oval(24,7,10,9,skin);rect(22,8,4,7,skin)
   p(15,12,shade);p(32,12,shade);line(18,14,20,14,shade);line(28,14,30,14,shade)
   p(17,10,ink);p(21,10,ink);p(26,10,ink);p(30,10,ink)
   p(17,11,eye);p(21,11,eye);p(26,11,eye);p(30,11,eye)
   p(21,13,'9c89ab');p(27,13,'9c89ab')
   poly({{13,6},{15,3},{18,1},{21,2},{24,3},{27,2},{30,2},{33,4},{35,7},{32,8},{28,7},{25,7},{23,6},{20,8},{16,8}},hair)
   line(16,4,20,3,hairhi);line(28,4,32,5,hairhi)
   line(24,4,23,7,'745060');line(23,7,24,10,'977083');line(24,10,24-pulse,13,'a58199')
   p(25,8,light);p(25,12,'c5acc7')
  end
 else
  poly({{15,4},{19,2},{25,2},{28,3},{31,3},{34,5},{35,8},{36,10},{35,12},{33,12},{32,15},{28,16},{23,16},{19,14},{15,11},{14,8}},ink)
  poly({{20,6},{28,7},{30,11},{28,15},{23,15},{20,12}},shade)
  poly({{27,7},{33,8},{34,10},{35,11},{33,12},{32,14},{28,15},{26,11}},skin)
  oval(19,7,9,8,skin)
  p(25,10,eye);p(32,11,eye);p(24,9,ink);p(31,10,ink)
  p(27,12,light);p(34,12,light);p(24,14,shade);p(31,14,shade)
  poly({{15,6},{17,3},{20,1},{25,2},{28,3},{31,3},{34,6},{34,8},{30,7},{28,8},{25,7},{22,8},{18,7}},hair)
  line(18,4,22,3,hairhi);line(29,5,32,6,hairhi)
  line(28,5,27,8,'745060');line(27,8,28,10,'977083');p(28-pulse,12,'b297b4')
 end
 if dir=='izquierda' then mirror_current() end
end

local previous_mutations=mutations
mutations=function(src,kind,dir,f)
 if kind=='atletico' then athletic(src,active_id or 2,dir,f)
 elseif kind=='area' then fungal(src,active_id or 2,dir,f)
 else previous_mutations(src,kind,dir,f) end
end

local previous_living=living
living=function(src,kind,dir,f)
 if kind=='atletico' then return
 elseif kind=='area' then
  local phase=(f-1)%2;p(5+phase,10-phase,color('bfa372',125));p(26-phase,14+phase,color('c1af83',105))
 else previous_living(src,kind,dir,f) end
end

local catalog={};local render={}
for _,kind in ipairs(types) do
 app.fs.makeAllDirectories(output..'/'..kind)
 render[kind]={}
 for id=1,5 do
  local sp=Sprite(32,32,ColorMode.RGB)
  sp.layers[1].name='Base retocada';sp:newLayer().name='Mutacion morfologica';sp:newLayer().name='Detalles vivos'
  for f=2,12 do sp:newEmptyFrame(f) end
  local frame=1;render[kind][id]={}
  local item={id=id,type=kind,source='NPC '..id,frames=12,frame_size={32,32},fps=5,directions={}}
  for _,d in ipairs(dirs) do
   local list={};local sw=d[3]==2 and 32 or 64;local sheet=Image(sw,64,ColorMode.RGB)
   local first=frame
   for f=1,d[3] do
    local src=sources[id][d[1]][f]
    active_id=id
    local base=retouch(src,id,kind);sp:newCel(sp.layers[1],frame,base,Point(0,0))
    img=Image(32,32,ColorMode.RGB);mutations(src,kind,d[1],f);sp:newCel(sp.layers[2],frame,img,Point(0,0))
    img=Image(32,32,ColorMode.RGB);living(src,kind,d[1],f);sp:newCel(sp.layers[3],frame,img,Point(0,0))
    sp.frames[frame].duration=.2
    local flat=Image(32,32,ColorMode.RGB);flat:drawSprite(sp,frame)
    list[f]=flat
    sheet:drawImage(flat,Point(((f-1)%(sw//32))*32,math.floor((f-1)/(sw//32))*32))
    frame=frame+1
   end
   local tag=sp:newTag(first,frame-1);tag.name=d[2];tag.aniDir=AniDir.FORWARD
   local filename='NPC '..id..' '..d[1]..'.png'
   sheet:saveAs(output..'/'..kind..'/'..filename)
   item.directions[d[1]]={file=filename,frames=d[3],size={sw,64},from=first,to=frame-1}
   render[kind][id][d[1]]=list
  end
  sp.gridBounds=Rectangle(0,0,32,32)
  sp:saveAs(output..'/'..kind..'/NPC_'..id..'.aseprite')
  sp:close();catalog[#catalog+1]=item
 end
 -- A static index matching the original NPC.png layout: five rows, four directions.
 local overview=Image(128,160,ColorMode.RGB)
 local overview_dirs={'abajo','izquierda','derecha','arriba'}
 for id=1,5 do for d,dir in ipairs(overview_dirs) do overview:drawImage(render[kind][id][dir][1],Point((d-1)*32,(id-1)*32)) end end
 overview:saveAs(output..'/'..kind..'/NPC.png')
 print('Creado '..kind..': 5 NPC, 4 direcciones, 60 frames originales retocados')
end

-- Endgame is an additional form. Original exponential sets remain available.
local endKind='exponencial_endgame'
app.fs.makeAllDirectories(output..'/'..endKind)
render[endKind]={}
for _,id in ipairs({2}) do
 local sp=Sprite(48,32,ColorMode.RGB)
 sp.layers[1].name='Cuerpo exponencial'
 sp:newLayer().name='Bifurcacion y tejido'
 sp:newLayer().name='Dos cabezas'
 for f=2,12 do sp:newEmptyFrame(f) end
 render[endKind][id]={}
 local frame=1
 local item={id=id,type=endKind,source='NPC '..id,frames=12,frame_size={48,32},fps=5,head_count=2,body_offset={8,0},directions={}}
 for _,d in ipairs(dirs) do
  local sw=d[3]==2 and 48 or 96
  local sheet=Image(sw,64,ColorMode.RGB);local list={};local first=frame
  for f=1,d[3] do
   local original=sources[id][d[1]][f]
   local exp=render.exponencial[id][d[1]][f]
   local body=Image(48,32,ColorMode.RGB)
   for y=16,31 do for x=0,31 do body:drawPixel(x+8,y,exp:getPixel(x,y)) end end
   sp:newCel(sp.layers[1],frame,body,Point(0,0))


   img=Image(48,32,ColorMode.RGB)
   -- A short central attachment sits inside the original collar.
   rect(22,14,5,3,'867896');rect(22,15,5,1,'ac9cba')
   line(20,17,28,17,'4f445d')
   sp:newCel(sp.layers[2],frame,img,Point(0,0))
   img=Image(48,32,ColorMode.RGB)
   endgame_head(d[1],f)
   sp:newCel(sp.layers[3],frame,img,Point(0,0));sp.frames[frame].duration=.2
   local flat=Image(48,32,ColorMode.RGB);flat:drawSprite(sp,frame)
   sheet:drawImage(flat,Point(((f-1)%(sw//48))*48,math.floor((f-1)/(sw//48))*32))
   list[f]=flat;frame=frame+1
  end
  local tag=sp:newTag(first,frame-1);tag.name=d[2];tag.aniDir=AniDir.FORWARD
  local filename='NPC '..id..' '..d[1]..'.png'
  sheet:saveAs(output..'/'..endKind..'/'..filename)
  render[endKind][id][d[1]]=list
  item.directions[d[1]]={file=filename,frames=d[3],size={sw,64},from=first,to=frame-1}
 end
 sp.gridBounds=Rectangle(0,0,48,32);sp:saveAs(output..'/'..endKind..'/NPC_'..id..'.aseprite');sp:close()
 catalog[#catalog+1]=item
end
local overview=Image(192,32,ColorMode.RGB)
local overview_dirs={'abajo','izquierda','derecha','arriba'}
for d,dir in ipairs(overview_dirs) do overview:drawImage(render[endKind][2][dir][1],Point((d-1)*48,0)) end
overview:saveAs(output..'/'..endKind..'/NPC.png')
print('Creado exponencial_endgame: un modelo NPC 2, dos cabezas, lienzos 48x32, pies conservados')

local file=io.open(output..'/catalogo.json','w');file:write(json.encode(catalog));file:close()
local glyphs={
 A={'01110','10001','10001','11111','10001','10001','10001'},B={'11110','10001','10001','11110','10001','10001','11110'},
 C={'01111','10000','10000','10000','10000','10000','01111'},D={'11110','10001','10001','10001','10001','10001','11110'},
 E={'11111','10000','10000','11110','10000','10000','11111'},F={'11111','10000','10000','11110','10000','10000','10000'},
 G={'01111','10000','10000','10111','10001','10001','01110'},H={'10001','10001','10001','11111','10001','10001','10001'},
 I={'11111','00100','00100','00100','00100','00100','11111'},J={'00111','00010','00010','00010','10010','10010','01100'},
 L={'10000','10000','10000','10000','10000','10000','11111'},M={'10001','11011','10101','10101','10001','10001','10001'},
 N={'10001','11001','10101','10011','10001','10001','10001'},O={'01110','10001','10001','10001','10001','10001','01110'},
 P={'11110','10001','10001','11110','10000','10000','10000'},R={'11110','10001','10001','11110','10100','10010','10001'},
 S={'01111','10000','10000','01110','00001','00001','11110'},T={'11111','00100','00100','00100','00100','00100','00100'},
 U={'10001','10001','10001','10001','10001','10001','01110'},V={'10001','10001','10001','10001','10001','01010','00100'},
 X={'10001','10001','01010','00100','01010','10001','10001'},Y={'10001','10001','01010','00100','00100','00100','00100'},Z={'11111','00001','00010','00100','01000','10000','11111'},
 ['0']={'01110','10001','10011','10101','11001','10001','01110'},['1']={'00100','01100','00100','00100','00100','00100','01110'},
 ['2']={'01110','10001','00001','00010','00100','01000','11111'},['3']={'11110','00001','00001','01110','00001','00001','11110'},
 ['4']={'00010','00110','01010','10010','11111','00010','00010'},['5']={'11111','10000','10000','11110','00001','00001','11110'},
 ['6']={'01110','10000','10000','11110','10001','10001','01110'},['7']={'11111','00001','00010','00100','01000','01000','01000'},
 ['8']={'01110','10001','10001','01110','10001','10001','01110'},['9']={'01110','10001','10001','01111','00001','00001','01110'},
 ['/']={'00001','00001','00010','00100','01000','10000','10000'},['.']={'00000','00000','00000','00000','00000','00100','00100'},
 ['-']={'00000','00000','00000','11111','00000','00000','00000'},['+']={'00000','00100','00100','11111','00100','00100','00000'}
}
local function text(s,x,y,c,scale)
  scale=scale or 1
  for i=1,#s do
    local g=glyphs[s:sub(i,i)]
    if g then for yy=1,7 do for xx=1,5 do if g[yy]:sub(xx,xx)=='1' then rect(x+(i-1)*6*scale+(xx-1)*scale,y+(yy-1)*scale,scale,scale,c) end end end end
  end
end



local labels={'SANO','ATLETICO','DE AREA','EXPONENCIAL','ENDGAME'}
local subtitle={'RETOQUE BASE','CASCO / SALVAJE','PLACAS FUNGICAS','ESTRATEGA','MITOSIS'}
local accents={'bac4d0','e59187','b5d783','b7a5e1','b3ecdc'}
local previewTypes={'sano_retoque','atletico','area','exponencial'}
local function scaled(im,x,y,scale)
 for yy=0,im.height-1 do for xx=0,im.width-1 do local c=im:getPixel(xx,yy)
  if app.pixelColor.rgbaA(c)>0 then rect(x+xx*scale,y+yy*scale,scale,scale,c) end
 end end
end
local preview=Sprite(960,1040,ColorMode.RGB)
for f=2,16 do preview:newEmptyFrame(f) end
for f=1,16 do
 img=Image(960,1040,ColorMode.RGB);rect(0,0,960,1040,'1b2331')
 text('PATOGEN / NPC INFECTADOS',28,23,color('ece7dc'),3)
 text('5 PERSONAJES / 3 TIPOS / 4 DIRECCIONES',28,58,color('91a4bd'),1)
 for col,kind in ipairs(previewTypes) do
  local x=100+(col-1)*211
  rect(x-9,88,196,690,color('242f40'))
  rect(x-9,88,196,2,color(accents[col]))
  text(labels[col],x+3,102,color(accents[col]),2)
  text(subtitle[col],x+3,125,color('8d9db2'),1)
  for id=1,5 do
   local dir=dirs[math.floor((f-1)/4)+1][1]
   local list=render[kind][id][dir]
   local step=(f-1)%#list+1
   scaled(list[step],x+(kind=='exponencial_endgame' and 17 or 41),149+(id-1)*124,3)
  end
 end
 for id=1,5 do text('NPC '..id,25,190+(id-1)*124,color('93a4ba'),1) end
 rect(28,840,904,168,color('24363d'));rect(28,840,904,2,color('b3ecdc'))
 text('ENDGAME / EXPONENCIAL',52,870,color('b3ecdc'),2)
 text('CRANEO COMPARTIDO / DIVISION',52,904,color('b3c8cd'),1)
 text('BASE NPC 2 / CUATRO DIRECCIONES',52,926,color('8fa7b3'),1)
 local endDir=dirs[math.floor((f-1)/4)+1][1]
 local endFrames=render.exponencial_endgame[2][endDir]
 scaled(endFrames[(f-1)%#endFrames+1],650,856,4)
 text('FRAMES ORIGINALES / FUENTES EDITABLES / VARIANTE ENDGAME INDEPENDIENTE',28,1024,color('91a4bd'),1)
 preview:newCel(preview.layers[1],f,img,Point(0,0));preview.frames[f].duration=.2
end
preview:saveAs(output..'/previews/npc_variantes.aseprite')
local still=Image(960,1040,ColorMode.RGB);still:drawSprite(preview,1);still:saveAs(output..'/previews/npc_variantes.png')
preview:close()
print('Catalogo y comparacion de NPC listos')



local focus=Sprite(1008,420,ColorMode.RGB)
for f=2,16 do focus:newEmptyFrame(f) end
for f=1,16 do
 img=Image(1008,420,ColorMode.RGB);rect(0,0,1008,420,'1b2331')
 text('PATOGEN / REDISENO DE INFECTADOS',28,20,color('ede5d6'),2)
 local focusTypes={'atletico','area','exponencial_endgame'}
 local focusLabels={'ATLETICO','DE AREA','ENDGAME'}
 local focusSub={'CASCO AJUSTADO / CUERPO AGIL','HONGOS / SILUETA COMPACTA','CRANEO COMPARTIDO EN DIVISION'}
 for i,kind in ipairs(focusTypes) do
  local x=16+(i-1)*336
  rect(x,64,320,332,color('273344'));rect(x,64,320,2,color(i==1 and 'df977b' or i==2 and 'd9b989' or 'b3dfcb'))
  text(focusLabels[i],x+16,82,color('e5d7bd'),2)
  text(focusSub[i],x+16,109,color('a3b1c1'),1)
  local dir=dirs[math.floor((f-1)/4)+1][1];local list=render[kind][2][dir];local im=list[(f-1)%#list+1]
  local zoom=kind=='exponencial_endgame' and 6 or 8
  scaled(im,x+(320-im.width*zoom)/2,134+(256-im.height*zoom)/2,zoom)
 end
 focus:newCel(focus.layers[1],f,img,Point(0,0));focus.frames[f].duration=.2
end
focus:saveAs(output..'/previews/rediseno_infectados.aseprite')
local still=Image(1008,420,ColorMode.RGB);still:drawSprite(focus,1);still:saveAs(output..'/previews/rediseno_infectados.png')
focus:close()

