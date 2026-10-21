-- Patogen / rediseño nativo 32x32. Ejecutar con Aseprite 1.3+.
local root=app.params.output or [[C:/Users/feliv/.codex/.chatgpt-projects/g-p-6ac7d270eca08191830907d9c9abeba3/output/patogen-infectados-oct21]]
local srcRoot=[[C:/Users/feliv/OneDrive/Desktop/Sprites]]
local paths={
 atletico=srcRoot..'/patogen-caras-y-patos-oct19/npcs/atletico/NPC_2.aseprite',
 exponencial_endgame=srcRoot..'/patogen-caras-y-patos-oct19/npcs/exponencial_endgame/NPC_2.aseprite',
 area=srcRoot..'/Patogen_Area_Carnoso_Oct19/patogen-area-carnoso-oct19/npcs/area/NPC_2.aseprite'
}
local dirs={'abajo','arriba','derecha','izquierda'}
local tags={'Abajo','Arriba','Derecha','Izquierda'}
local types={'atletico','area','exponencial_endgame'}
local before,after={},{}
local checks={cell={32,32},frames_per_direction=16,frame_duration_ms=100,baseline=30,types={}}
app.fs.makeAllDirectories(root..'/previews')
local img
local function c(s,a)
 if type(s)=='number' then return s end
 s=s:gsub('#','')
 return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),a or 255)
end
local function p(x,y,col) x,y=math.floor(x+.5),math.floor(y+.5)
 if x>=0 and x<img.width and y>=0 and y<img.height then img:drawPixel(x,y,c(col)) end
end
local function rect(x,y,w,h,col)
 x,y,w,h=math.floor(x),math.floor(y),math.floor(w),math.floor(h)
 col=c(col)
 for yy=math.max(0,y),math.min(img.height-1,y+h-1) do for xx=math.max(0,x),math.min(img.width-1,x+w-1) do img:drawPixel(xx,yy,col) end end
end
local function line(x,y,x2,y2,col)
 x,y,x2,y2=math.floor(x+.5),math.floor(y+.5),math.floor(x2+.5),math.floor(y2+.5)
 local dx,sx=math.abs(x2-x),x<x2 and 1 or -1
 local dy,sy=-math.abs(y2-y),y<y2 and 1 or -1;local er=dx+dy
 while true do p(x,y,col);if x==x2 and y==y2 then break end
 local e=2*er;if e>=dy then er=er+dy;x=x+sx end;if e<=dx then er=er+dx;y=y+sy end end
end
local function oval(x,y,w,h,col)
 x,y,w,h=math.floor(x),math.floor(y),math.floor(w),math.floor(h)
 for yy=y,y+h-1 do for xx=x,x+w-1 do
 if ((xx+.5-x-w/2)/(w/2))^2+((yy+.5-y-h/2)/(h/2))^2<=1 then p(xx,yy,col) end
 end end
end
local function poly(pts,col)
 local lo,hi=99,-99
 for _,v in ipairs(pts) do lo=math.min(lo,v[2]);hi=math.max(hi,v[2]) end
 for y=math.ceil(lo),math.floor(hi) do
 local nodes={};local j=#pts
 for i=1,#pts do local a,b=pts[i],pts[j]
 if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then nodes[#nodes+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end;j=i end
 table.sort(nodes);for i=1,#nodes-1,2 do for x=math.ceil(nodes[i]),math.floor(nodes[i+1]) do p(x,y,col) end end
 end
end
local function flip(im)
 local o=Image(im.width,im.height,ColorMode.RGB)
 for y=0,im.height-1 do for x=0,im.width-1 do o:drawPixel(im.width-1-x,y,im:getPixel(x,y)) end end
 return o
end
local function flatten(s,f) local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,f);return im end
local function copyRegion(im,x0,y0,w,h,dx,dy)
 for y=0,h-1 do for x=0,w-1 do local col=im:getPixel(x0+x,y0+y)
 if app.pixelColor.rgbaA(col)>0 then p(dx+x,dy+y,col) end end end
end
-- Read-only original artwork, cached for presentation and ground-contact reference.
local sources={}
for _,kind in ipairs(types) do
 local s=app.open(paths[kind]);sources[kind]={};before[kind]={}
 for i,dir in ipairs(dirs) do
 sources[kind][dir]={};before[kind][dir]={}
 local tag=s.tags[i];local n=tag.toFrame.frameNumber-tag.fromFrame.frameNumber+1
 for f=1,n do sources[kind][dir][f]=flatten(s,tag.fromFrame.frameNumber+f-1) end
 for f=0,15 do local ix=math.floor(f/2)%n+1
 if n==2 then ix=math.floor(f/2)%2+1 end
 if kind=='area' then ix=f%8+1 end
 before[kind][dir][f+1]=sources[kind][dir][ix]
 end
 end
 s:close()
end
local function sourceFrame(kind,dir,f)
 local a=sources[kind][dir];local n=#a
 local ix=n==2 and (math.floor(f/4)%2+1) or (math.floor(f/2)%4+1)
 if kind=='area' then ix=math.floor(f/2)%8+1 end
 return a[ix]
end
local F={ink='302d40',dark='4d4256',pants='68596d',fold='8a7583',shoe='b5adba',toe='dad1d2'}
local function feet(kind,dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 local q=kind=='area' and math.floor(f/2)%8 or f%8
 local dx={0,1,2,1,0,-1,-2,-1};local lift={0,0,0,0,0,1,2,1}
 if side then
 rect(12,25,10,2,F.ink);rect(13,25,8,2,F.pants)
 for leg=0,1 do
 local phase=(q+(leg==0 and 4 or 0))%8+1
 local shift=dx[phase];if kind=='area' then shift=math.floor(shift/2) end
 local x=(leg==0 and 14 or 17)+shift;local y=29-lift[phase]
 poly({{leg==0 and 14 or 17,26},{leg==0 and 18 or 21,26},{x+3,y+1},{x-1,y+1}},F.ink)
 poly({{leg==0 and 15 or 18,26},{leg==0 and 17 or 20,26},{x+2,y},{x,y}},leg==0 and F.dark or F.pants)
 rect(x-1,y,5,2,F.ink);rect(x,y,4,1,leg==0 and F.fold or F.shoe)
 if leg==1 then p(x+3,y,F.toe) end
 end
 if dir=='izquierda' then img=flip(img) end
 else
 rect(10,25,12,2,F.ink);rect(11,25,10,2,F.pants)
 local left={0,0,0,1,2,3,2,0};local right={2,3,2,0,0,0,0,1}
 local spread=kind=='atletico' and 1 or 0
 for leg=0,1 do
 local x=leg==0 and 11-spread or 18+spread
 local h=(leg==0 and left or right)[q+1];if dir=='arriba' then h=(leg==0 and right or left)[q+1] end
 local y=29-h
 rect(x,26,4,math.max(1,y-25),F.ink);rect(x+1,26,2,math.max(1,y-26),F.pants)
 rect(x-1,y,5,2,F.ink);rect(x,y,3,1,F.shoe);p(x+1,y,F.toe)
 if h>=2 then p(x+1,y-1,F.fold) end
 end
 end
end
local A={ink='302b30',deep='6a4b3c',shadow='99764f',skin='c6a777',light='ead2a0',red='b43c3c',
 darkred='722b36',hi='ee7961',cloth='667b58',band='97a17a',pants='665568'}
local swell={0,0,0,1,1,1,2,2,2,2,1,1,1,0,0,0}
local bob={0,0,0,1,1,0,0,0}
local swing={0,0,1,1,0,0,-1,-1}
local function athleteBody(dir,f)
 local s=swell[f+1];local b=bob[f%8+1];local side=dir=='derecha' or dir=='izquierda';local sw=swing[f%8+1]
 if side then
 -- Far shoulder, ribcage, then the near arm in front of the ribs.
 oval(11-s,14+b,7+s,8,A.ink);oval(12-s,15+b,5+s,6,A.shadow);line(12-s,16+b,14,16+b,A.skin)
 poly({{15,13+b},{21,14+b},{24,18},{22,25},{12,25},{10,20},{11,16}},A.ink)
 poly({{15,14+b},{20,15+b},{22,18},{20,24},{13,24},{12,19}},A.shadow)
 poly({{14,15+b},{18,16+b},{20,18},{18,21},{13,20}},A.skin)
 line(13,16+b,16,16+b,A.light);line(13,21,17,22,A.deep)
 line(19,16+b,20,20,A.deep);p(18,23,A.light)
 oval(18,14+b,8+s,8+s,A.ink);oval(19,15+b,6+s,6+s,A.shadow)
 oval(19,15+b,5+s,5,A.skin);line(20,15+b,22+s,16+b,A.light)
 line(21,19+b,24+s,19+b,A.deep)
 oval(21+sw,20,6,6,A.ink);oval(22+sw,20,4,5,A.skin)
 p(22+sw,21,A.light);p(24+sw,23,A.shadow);line(22+sw,24,24+sw,24,A.deep)
 rect(12,24,10,2,A.ink);rect(13,24,8,1,A.cloth);p(18,24,A.band)
 else
 -- Broad relaxed shoulders expand by two pixels per side without shifting joints.
 poly({{9,14+b},{22,14+b},{25,18},{22,24},{20,26},{11,26},{8,22},{6,18}},A.ink)
 poly({{10,15+b},{21,15+b},{23,19},{20,24},{11,24},{8,19}},A.shadow)
 if dir=='arriba' then
 poly({{10,15+b},{14,15+b},{15,19},{12,21},{9,19}},A.skin)
 poly({{17,15+b},{21,15+b},{22,19},{18,21},{16,19}},A.skin)
 line(15,15+b,15,21,A.deep);line(12,22,18,22,A.deep);p(14,23,A.light)
 line(10,16+b,12,16+b,A.light);line(18,16+b,20,16+b,A.light)
 else
 -- Two pectorals, a sternum and distinct abdominal blocks.
 oval(9,15+b,7,5,A.skin);oval(16,15+b,7,5,A.skin)
 line(10,15+b,13,15+b,A.light);line(17,15+b,20,15+b,A.light)
 line(14,17+b,16,18+b,A.deep)
 line(11,20+b,14,20+b,A.deep);line(17,20+b,20,20+b,A.deep)
 rect(13,21,2,2,A.skin);rect(17,21,2,2,A.skin);p(13,21,A.light);p(17,21,A.light)
 line(15,21,15,23,A.deep);line(12,23,19,23,A.shadow)
 end
 for arm=0,1 do
 local x=arm==0 and 3-s or 22;local w=7+s;local yy=15+b
 oval(x,yy,w,8+s,A.ink);oval(x+1,yy+1,w-2,6+s,A.shadow)
 oval(x+1,yy+1,w-3,4+s,A.skin)
 line(x+2,yy+1,x+w-3,yy+1,A.light)
 line(x+2,yy+5+s,x+w-2,yy+4+s,A.deep)
 local hx=arm==0 and 4-sw or 23+sw
 oval(hx,21,5,5,A.ink);rect(hx+1,21,3,4,A.skin)
 p(hx+1,22,A.light);p(hx+3,24,A.shadow)
 end
 rect(10,24,12,2,A.ink);rect(11,24,10,1,A.cloth);rect(14,24,3,1,A.band)
 end
end
local function athleteHead(dir,f)
 local old=sourceFrame('atletico',dir,f);local b=bob[f%8+1]
 -- Helmet and facial guard remain native original pixels, separated from animated muscles.
 copyRegion(old,0,0,32,14,0,b)
 if dir=='abajo' then
 rect(10,9+b,3,1,A.deep);rect(18,9+b,3,1,A.deep);p(12,9+b,'ff745b');p(18,9+b,'ff745b')
 line(13,12+b,18,12+b,A.ink);p(14,12+b,'e5dcc0');p(17,12+b,'e5dcc0')
 elseif dir=='derecha' then p(23,9+b,'ff745b') elseif dir=='izquierda' then p(8,9+b,'ff745b') end
end
local function athleteEffects(dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 local q=f%8
 if dir~='arriba' and q>=2 and q<=5 then
 local x=side and 26 or 20;local y=side and 12 or 13
 p(x,y,'d7e5d4');if q>=3 then p(x,y+1,'8cadad') end
 if q==4 then p(x+1,y+2,c('c8ded5',150)) end
 end
end
-- Area: two respiratory lobes, ribbed diaphragm, forward human head.
local B={ink='273931',deep='425344',shade='66735a',skin='91a07a',light='c4c69c',
 membrane='957365',memdark='634f4a',memlight='c99b7a',rim='a9bc72',core='e0e3a0',
 hole='273b35',cloth='4e685e',clothhi='748876',pants='685967'}
local breath={0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0}
local function vent(x,y,w,h,q)
 local grow=breath[q%16+1];local opening=(q%16>=3 and q%16<=7) and 1 or 0
 x=x-grow;y=y-grow;w=w+grow;h=h+grow
 oval(x,y,w,h,B.ink);oval(x+1,y+1,w-2,h-2,B.memdark)
 oval(x+1,y+1,w-3,h-3,B.membrane)
 line(x+2,y+1,x+w-4,y+1,B.memlight);p(x+1,y+3,B.memlight)
 -- A high contrast tubular aperture with a fleshy rim; not a colored tumor.
 oval(x+2,y+2,w-4,4+opening,B.rim)
 oval(x+3,y+2,w-5,3+opening,B.hole)
 p(x+3,y+2,B.core);if opening==1 then p(x+3,y+5,B.deep) end
 line(x+2,y+h-3,x+w-3,y+h-4,B.memdark)
 p(x+2,y+h-2,B.shade)
end
local function areaBody(dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 local inhale=breath[f+1];local sw=swing[f%8+1]
 if side then
 oval(6,11-inhale,16,15+inhale,B.ink)
 oval(7,12-inhale,14,13+inhale,B.shade)
 poly({{11,13},{18,13},{23,18},{23,25},{10,25},{7,21}},B.cloth)
 oval(9,15,12,9,B.skin);oval(10,16,10,7,B.shade)
 line(10,18,17,19,B.deep);line(11,21,18,22,B.deep)
 line(11,17,16,18,B.light);p(18,20,B.skin)
 oval(19+sw,18,6,8,B.ink);oval(20+sw,19,4,6,B.shade)
 p(20+sw,20,B.skin);p(21+sw,23,B.light)
 rect(10,24,12,2,B.ink);rect(11,24,10,1,B.cloth)
 -- Large dorsal bellows leans over the small face.
 vent(6,6,10,13,f);vent(14,9,7,9,(f+6)%16)
 line(9,17,11,21,B.memdark);p(11,20,B.memlight)
 else
 oval(5,13-inhale,22,14+inhale,B.ink)
 oval(6,14-inhale,20,12+inhale,B.shade)
 poly({{10,15},{22,15},{24,24},{21,26},{9,26},{7,22}},B.cloth)
 if dir=='arriba' then
 oval(8,14,16,11,B.memdark);oval(9,14,14,10,B.membrane)
 line(15,16,16,23,B.ink);line(10,18,14,19,B.memlight);line(18,18,21,17,B.memlight)
 line(10,21,14,22,B.memdark);line(18,22,22,20,B.memdark)
 else
 oval(9,16,14,9,B.skin);oval(10,17,12,7,B.shade)
 line(11,19,14,20,B.deep);line(18,20,21,19,B.deep)
 line(11,22,14,23,B.deep);line(18,23,21,22,B.deep)
 p(11,18,B.light);p(20,18,B.light);p(16,22,B.skin)
 end
 oval(5-sw,20,5,6,B.ink);oval(6-sw,21,3,4,B.skin);p(6-sw,22,B.light)
 oval(23+sw,20,5,6,B.ink);oval(24+sw,21,3,4,B.shade);p(24+sw,22,B.skin)
 rect(10,24,12,2,B.ink);rect(11,24,10,1,B.cloth)
 vent(4,7,9,12,f);vent(21,6,8,12,(f+6)%16)
 if dir=='arriba' then vent(12,10,9,12,(f+3)%16) end
 end
end
local function areaHead(dir,f)
 local side=dir=='derecha' or dir=='izquierda';local lift=breath[(f+2)%16+1]
 if dir=='arriba' then
 oval(13,6,8,7,B.ink);oval(14,7,6,5,B.deep);line(15,7,18,7,B.shade);p(18,10,B.skin)
 elseif side then
 poly({{18,9+lift},{23,9+lift},{25,12+lift},{25,14+lift},{27,15+lift},{25,16+lift},{24,19},{20,19},{17,16}},B.ink)
 poly({{19,10+lift},{22,10+lift},{24,12+lift},{24,16},{23,18},{20,17},{18,14}},B.skin)
 line(19,10+lift,22,10+lift,B.deep);p(24,13+lift,B.deep);p(24,14+lift,B.core)
 p(25,15+lift,B.light);line(22,17,24,17,B.hole);p(23,17,B.memlight)
 line(18,12+lift,18,14+lift,B.shade);p(20,16,B.light)
 else
 oval(12,9+lift,9,10,B.ink);oval(13,10+lift,7,8,B.shade)
 poly({{14,10+lift},{18,10+lift},{20,13+lift},{18,17},{14,17},{13,14}},B.skin)
 line(14,10+lift,17,10+lift,B.deep);p(18,11+lift,B.deep)
 line(13,13+lift,15,13+lift,B.hole);p(14,14+lift,B.core)
 line(18,13+lift,19,13+lift,B.hole);p(18,14+lift,B.core)
 p(16,15+lift,B.light);line(15,17,18,17,B.hole);p(15,17,B.memlight)
 end
end
local alphas={0,65,135,210,230,220,195,160,120,80,45,15,0,0,0,0}
local function areaParticles(dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 -- Births occur during each lobe's opening. Three graded pixels grow then drift and fade.
 local seeds=side and {{9,10,12,-1},{10,11,10,-1},{17,12,2,1},{16,13,0,1}} or {{7,11,12,-1},{8,12,10,-1},{25,10,2,1},{24,11,0,1}}
 for i,v in ipairs(seeds) do
 local age=(f+v[3])%16;local a=alphas[age+1]
 local dx=math.floor(age/4)*v[4];local drift=({0,0,0,1,1,1,0,0,-1,-1,0,0,0,0,0,0})[age+1]
 local x=v[1]+dx+drift;local y=v[2]-math.floor(age*.65)
 if a>0 then
 p(x,y,c(B.core,a))
 if age>=2 and age<=6 then p(x+1,y,c(B.rim,math.floor(a*.75))) end
 if age==4 or age==5 then p(x,y+1,c(B.skin,95)) end
 end
 end
end
-- Exponential: independent crania with negative space, two necks and mitotic limb bud.
local E={ink='302d40',deep='5b4c69',shade='8e7c9e',skin='b2a3c7',light='dfd2e1',
 hair='513b4d',hairhi='785567',eye='ebeed3',mouth='514057',
 cloth='426969',clothhi='79a298',clothdark='304a51',scar='a4e4ca',scarhi='dcf6dd',pants='67596b'}
local nod={0,0,0,-1,-1,-1,0,0,0,0,1,1,1,0,0,0}
local bud={0,0,0,0,1,1,2,3,3,3,2,2,1,1,0,0}
local function expBody(dir,f)
 local side=dir=='derecha' or dir=='izquierda';local sw=swing[f%8+1];local g=bud[f+1]
 if side then
 oval(9,19,5,7,E.ink);oval(10,20,3,5,E.shade)
 poly({{13,16},{20,17},{24,21},{22,26},{11,26},{9,22}},E.ink)
 poly({{13,17},{19,18},{22,21},{20,25},{12,25},{11,21}},E.cloth)
 line(12,19,15,20,E.clothhi);line(12,22,15,23,E.clothdark)
 oval(20+sw,21,5,5,E.ink);oval(21+sw,21,3,4,E.shade);p(21+sw,22,E.skin)
 -- A secondary arm emerges from a skin-lined split, below both heads.
 if g>0 then
 oval(10-g,19,4+g,4,E.ink);oval(11-g,20,2+g,2,E.shade)
 p(11-g,20,E.scar);if g>=2 then p(10-g,21,E.skin);p(10-g,23,E.shade) end
 end
 rect(12,24,9,2,E.ink);rect(13,24,7,1,E.clothhi)
 else
 poly({{10,16},{21,16},{25,20},{23,24},{21,26},{10,26},{7,22},{7,19}},E.ink)
 poly({{11,17},{20,17},{23,20},{21,25},{11,25},{9,21}},E.cloth)
 line(10,19,12,20,E.clothhi);line(20,19,22,20,E.clothhi)
 oval(6-sw,19,5,7,E.ink);oval(7-sw,20,3,5,E.shade);p(7-sw,22,E.skin)
 oval(22+sw,19,5,7,E.ink);oval(23+sw,20,3,5,E.shade);p(23+sw,21,E.light)
 if g>0 then
 oval(24,20,3+g,4+g,E.ink);oval(25,21,1+g,2+g,E.shade)
 line(25,21,25+g,22,E.skin);p(25,20,E.scar)
 if g>=2 then p(26,24,E.skin);p(28,24,E.skin);p(27,25,E.deep) end
 end
 rect(10,24,12,2,E.ink);rect(11,24,10,1,E.clothhi)
 end
 -- The division line echoes the fork of the two necks, with a travelling luminous cell.
 if dir~='arriba' then
 line(15,18,16,21,E.deep);line(18,18,16,21,E.deep);line(16,21,16,24,E.deep)
 line(15,18,16,20,E.scar);p(18,18,E.scar);p(17,19,E.scar)
 p(16,21+(math.floor(f/4)%3),E.scarhi)
 else line(15,17,16,24,E.deep);p(16,20,E.scar);p(17,18,E.clothhi) end
end
local function neck(x,y,toX,toY)
 -- Five-pixel fleshy stalk, tapering into a shared trapezius; never a single-pixel wire.
 poly({{x-2,y},{x+2,y},{toX+3,toY+1},{toX-2,toY+1}},E.ink)
 poly({{x-1,y},{x+1,y},{toX+2,toY},{toX-1,toY}},E.shade)
 line(x,y,toX,toY,E.skin);p(x,y+1,E.light);p(toX,toY,E.scar)
end
local function skull(x,y,back,side,second,f)
 if side then
 poly({{x+2,y},{x+6,y},{x+8,y+3},{x+8,y+5},{x+9,y+6},{x+7,y+7},{x+7,y+10},{x+3,y+10},{x,y+6},{x,y+2}},E.ink)
 poly({{x+2,y+1},{x+6,y+1},{x+7,y+3},{x+7,y+7},{x+6,y+9},{x+3,y+9},{x+1,y+5},{x+1,y+2}},E.shade)
 poly({{x+3,y+2},{x+6,y+2},{x+7,y+4},{x+6,y+8},{x+4,y+8},{x+2,y+5}},E.skin)
 p(x+8,y+6,E.light);rect(x+6,y+4,2,2,E.deep);p(x+7,y+5,E.eye)
 line(x+5,y+8,x+7,y+8,E.mouth);p(x+6,y+8,E.light)
 poly({{x+1,y+1},{x+3,y},{x+6,y},{x+7,y+2},{x+4,y+1},{x+2,y+3},{x,y+3}},E.hair)
 p(x+3,y,E.hairhi);p(x+2,y+5,E.light)
 else
 -- Two broad, independent skulls; a narrow jaw and hollow sockets remain readable at 1x.
 poly({{x+2,y},{x+7,y},{x+9,y+2},{x+9,y+7},{x+7,y+11},{x+2,y+11},{x,y+7},{x,y+2}},E.ink)
 poly({{x+2,y+1},{x+7,y+1},{x+8,y+3},{x+8,y+7},{x+6,y+10},{x+2,y+9},{x+1,y+5},{x+1,y+2}},E.shade)
 if back then
 poly({{x+2,y},{x+7,y},{x+8,y+2},{x+8,y+7},{x+6,y+9},{x+2,y+8},{x+1,y+4}},E.hair)
 line(x+2,y+2,x+4,y+1,E.hairhi);line(x+6,y+4,x+7,y+5,E.hairhi)
 line(x+2,y+9,x+6,y+10,E.skin);p(x+7,y+8,E.shade)
 else
 poly({{x+2,y+2},{x+7,y+2},{x+8,y+4},{x+7,y+8},{x+6,y+10},{x+2,y+9},{x+1,y+5}},E.skin)
 line(x+2,y+2,x+6,y+2,E.light);p(x+1,y+4,E.light)
 rect(x+1,y+4,3,3,E.deep);rect(x+6,y+4,2,3,E.deep)
 p(x+2,y+5,E.eye);p(x+6,y+5,E.eye)
 p(x+4,y+6,E.light);p(x+4,y+7,E.deep);p(x+5,y+7,E.shade)
 line(x+2,y+9,x+6,y+9,E.mouth);p(x+3,y+9,E.light)
 if second then p(x+6,y+10,E.deep) else p(x+2,y+8,E.shade) end
 poly({{x+1,y+1},{x+2,y},{x+7,y},{x+8,y+2},{x+5,y+1},{x+1,y+3}},E.hair)
 p(x+2,y,E.hairhi);p(x+7,y+1,E.hairhi)
 end
 end
end
local function expHeads(dir,f)
 local side=dir=='derecha' or dir=='izquierda'
 local a=nod[f+1];local b=nod[(f+5)%16+1]
 if side then
 neck(11,12+a,15,17);neck(21,16+b,18,20)
 skull(6,2+a,false,true,false,f);skull(18,6+b,false,true,true,f)
 else
 neck(9,13+a,14,18);neck(23,14+b,18,18)
 skull(4,2+a,dir=='arriba',false,false,f)
 skull(18,3+b,dir=='arriba',false,true,f)
 end
end
-- Export native layers and exact 4x4 directional atlases.
local layerNames={
 atletico={'Pasos y apoyo','Torso y musculos','Casco y rostro','Saliva'},
 area={'Pasos y apoyo','Fuelles respiratorios','Cabeza humana','Esporas'},
 exponencial_endgame={'Pasos y apoyo','Torso y gemacion','Dos cuellos y dos cabezas','Efectos'}
}
for _,kind in ipairs(types) do
 local folder=root..'/npcs/'..kind;app.fs.makeAllDirectories(folder)
 local s=Sprite(32,32,ColorMode.RGB);s.layers[1].name=layerNames[kind][1]
 for i=2,4 do s:newLayer().name=layerNames[kind][i] end
 for f=2,64 do s:newEmptyFrame(f) end
 after[kind]={};local stat={frames=64,width=32,height=32,edge_pixels=0}
 for d,dir in ipairs(dirs) do
 after[kind][dir]={}
 for f=0,15 do
 local index=(d-1)*16+f+1
 for l=1,4 do
 img=Image(32,32,ColorMode.RGB)
 -- Left view is mirrored only for new anatomy; original feet and helmet already face left.
 if l==1 then feet(kind,dir,f)
 elseif kind=='atletico' then
 if l==2 then athleteBody(dir,f);if dir=='izquierda' then img=flip(img) end
 elseif l==3 then athleteHead(dir,f)
 elseif l==4 then athleteEffects(dir,f);if dir=='izquierda' then img=flip(img) end end
 elseif kind=='area' then
 if l==2 then areaBody(dir,f) elseif l==3 then areaHead(dir,f) elseif l==4 then areaParticles(dir,f) end
 if dir=='izquierda' then img=flip(img) end
 else
 if l==2 then expBody(dir,f) elseif l==3 then expHeads(dir,f) end
 if dir=='izquierda' then img=flip(img) end
 end
 s:newCel(s.layers[l],index,img,Point(0,0))
 end
 s.frames[index].duration=.1
 local im=flatten(s,index);after[kind][dir][f+1]=im
 for y=0,31 do for x=0,31 do if (x==0 or y==0 or x==31 or y==31) and app.pixelColor.rgbaA(im:getPixel(x,y))>0 then stat.edge_pixels=stat.edge_pixels+1 end end end
 end
 local tag=s:newTag((d-1)*16+1,d*16);tag.name=tags[d];tag.aniDir=AniDir.FORWARD
 local sheet=Image(128,128,ColorMode.RGB)
 for f=0,15 do sheet:drawImage(after[kind][dir][f+1],Point((f%4)*32,math.floor(f/4)*32)) end
 sheet:saveAs(folder..'/NPC 2 '..dir..'.png')
 end
 s.gridBounds=Rectangle(0,0,32,32)
 s:saveAs(folder..'/NPC_2.aseprite')
 -- Full atlas: all 64 frames, 16 columns x 4 direction rows.
 local atlas=Image(512,128,ColorMode.RGB)
 for d,dir in ipairs(dirs) do for f=0,15 do atlas:drawImage(after[kind][dir][f+1],Point(f*32,(d-1)*32)) end end
 atlas:saveAs(folder..'/NPC.png')
 local jf=io.open(folder..'/animacion.json','w')
 local meta={size={32,32},layout={columns=4,rows=4},fps=10,loop=true,origin={16,16},feet_baseline=30,directions=tags,frames_per_direction=16,duration_ms=1600}
 jf:write(json.encode(meta));jf:close()
 checks.types[kind]=stat;s:close()
end
-- Preview typography, nearest-neighbor enlargement only.
local glyphs={
 A={'01110','10001','10001','11111','10001','10001','10001'},B={'11110','10001','10001','11110','10001','10001','11110'},
 C={'01111','10000','10000','10000','10000','10000','01111'},D={'11110','10001','10001','10001','10001','10001','11110'},
 E={'11111','10000','10000','11110','10000','10000','11111'},F={'11111','10000','10000','11110','10000','10000','10000'},
 G={'01111','10000','10000','10111','10001','10001','01110'},H={'10001','10001','10001','11111','10001','10001','10001'},
 I={'11111','00100','00100','00100','00100','00100','11111'},J={'00111','00010','00010','00010','10010','10010','01100'},
 K={'10001','10010','10100','11000','10100','10010','10001'},L={'10000','10000','10000','10000','10000','10000','11111'},
 M={'10001','11011','10101','10101','10001','10001','10001'},N={'10001','11001','10101','10011','10001','10001','10001'},
 O={'01110','10001','10001','10001','10001','10001','01110'},P={'11110','10001','10001','11110','10000','10000','10000'},
 Q={'01110','10001','10001','10001','10101','10010','01101'},R={'11110','10001','10001','11110','10100','10010','10001'},
 S={'01111','10000','10000','01110','00001','00001','11110'},T={'11111','00100','00100','00100','00100','00100','00100'},
 U={'10001','10001','10001','10001','10001','10001','01110'},V={'10001','10001','10001','10001','10001','01010','00100'},
 X={'10001','10001','01010','00100','01010','10001','10001'},Y={'10001','10001','01010','00100','00100','00100','00100'},
 Z={'11111','00001','00010','00100','01000','10000','11111'},
 ['0']={'01110','10001','10011','10101','11001','10001','01110'},['1']={'00100','01100','00100','00100','00100','00100','01110'},
 ['2']={'01110','10001','00001','00010','00100','01000','11111'},['3']={'11110','00001','00001','01110','00001','00001','11110'},
 ['4']={'00010','00110','01010','10010','11111','00010','00010'},['5']={'11111','10000','10000','11110','00001','00001','11110'},
 ['6']={'01110','10000','10000','11110','10001','10001','01110'},['7']={'11111','00001','00010','00100','01000','01000','01000'},
 ['8']={'01110','10001','10001','01110','10001','10001','01110'},['9']={'01110','10001','10001','01111','00001','00001','11110'},
 ['/']={'00001','00001','00010','00100','01000','10000','10000'},['.']={'00000','00000','00000','00000','00000','00100','00100'},
 ['-']={'00000','00000','00000','11111','00000','00000','00000'},['+']={'00000','00100','00100','11111','00100','00100','00000'}
}
local function text(str,x,y,col,k)
 k=k or 1
 for i=1,#str do local g=glyphs[str:sub(i,i)]
 if g then for yy=1,7 do for xx=1,5 do if g[yy]:sub(xx,xx)=='1' then rect(x+(i-1)*6*k+(xx-1)*k,y+(yy-1)*k,k,k,col) end end end end end
end
local function scaled(im,x,y,k,silhouette)
 for yy=0,im.height-1 do for xx=0,im.width-1 do local col=im:getPixel(xx,yy)
 local alpha=app.pixelColor.rgbaA(col)
 if alpha>0 then
 if silhouette then col=c(silhouette)
 elseif alpha<255 then
 local bg=img:getPixel(x+xx*k,y+yy*k);local t=alpha/255
 col=app.pixelColor.rgba(
 math.floor(app.pixelColor.rgbaR(col)*t+app.pixelColor.rgbaR(bg)*(1-t)+.5),
 math.floor(app.pixelColor.rgbaG(col)*t+app.pixelColor.rgbaG(bg)*(1-t)+.5),
 math.floor(app.pixelColor.rgbaB(col)*t+app.pixelColor.rgbaB(bg)*(1-t)+.5),255)
 end
 rect(x+xx*k,y+yy*k,k,k,col)
 end end end
end
local names={atletico='ATLETICO',area='AREA',exponencial_endgame='EXPONENCIAL'}
local desc={atletico='HIPERTROFIA / IMPULSO',area='FUELLES / ESPORAS',exponencial_endgame='DOS CABEZAS / GEMACION'}
local accent={atletico='ec9571',area='ced998',exponencial_endgame='c6b5e0'}
-- Contact sheet: all directions at a legible 5x with a 1x specimen next to each.
local contact=Image(960,700,ColorMode.RGB);img=contact;rect(0,0,960,700,'161e23')
text('PATOGEN / INFECTADOS',24,20,'e9e8d7',3)
text('32 X 32 / 16 FOTOGRAMAS POR DIRECCION / 10 FPS',26,52,'91a5a4',1)
for row,kind in ipairs(types) do
 local y=80+(row-1)*204
 text(names[kind]..' / '..desc[kind],24,y,accent[kind],1)
 for d,dir in ipairs(dirs) do
 local x=24+(d-1)*234
 rect(x,y+19,222,174,'243138')
 scaled(after[kind][dir][7],x+9,y+24,5)
 scaled(after[kind][dir][7],x+180,y+149,1)
 text(tags[d]:upper(),x+171,y+28,'98a9a6',1)
 end
end
contact:saveAs(root..'/previews/cuatro_direcciones.png')
-- A/B comparison: all three on a shared baseline; repeats with all four views.
local board=Sprite(960,740,ColorMode.RGB)
for f=2,16 do board:newEmptyFrame(f) end
for f=1,16 do
 img=Image(960,740,ColorMode.RGB);rect(0,0,960,740,'161e23')
 text('PATOGEN / ANTES Y DESPUES',24,20,'e9e8d7',2)
 local d=1;local dir=dirs[d];local n=(f-1)%16+1
 text(tags[d]:upper()..' / CICLOS DE 1.6 SEGUNDOS',24,47,'9cb0ad',1)
 for row,kind in ipairs(types) do
 local y=74+(row-1)*212
 rect(20,y,920,200,'243138');text(names[kind],34,y+12,accent[kind],2)
 text('ANTES',300,y+12,'91a4a4',1);text('DESPUES',660,y+12,accent[kind],1)
 local old=before[kind][dir][n]
 scaled(old,old.width==48 and 240 or 280,y+30,5)
 scaled(after[kind][dir][n],640,y+30,5)
 scaled(after[kind][dir][n],872,y+152,1)
 text('1X',873,y+190,'a8b8ae',1)
 end
 board:newCel(board.layers[1],f,img,Point(0,0));board.frames[f].duration=.1
end
board:saveAs(root..'/previews/comparacion.aseprite')
flatten(board,1):saveAs(root..'/previews/comparacion.png');board:close()
-- All four directions of each type, animated together; exact-size strip is included.
local preview=Sprite(960,700,ColorMode.RGB)
for f=2,16 do preview:newEmptyFrame(f) end
for f=1,16 do
 img=Image(contact)
 -- Cover specimen area and update only figures, retaining the contact-sheet labels.
 for row,kind in ipairs(types) do
 local y=80+(row-1)*204
 for d,dir in ipairs(dirs) do local x=24+(d-1)*234
 rect(x,y+19,167,174,'243138');rect(x+178,y+145,40,45,'243138')
 scaled(after[kind][dir][f],x+9,y+24,5);scaled(after[kind][dir][f],x+180,y+149,1)
 end end
 preview:newCel(preview.layers[1],f,img,Point(0,0));preview.frames[f].duration=.1
end
preview:saveAs(root..'/previews/cuatro_direcciones.aseprite');preview:close()
local real=Sprite(384,208,ColorMode.RGB)
for f=2,16 do real:newEmptyFrame(f) end
for f=1,16 do
 img=Image(384,208,ColorMode.RGB);rect(0,0,384,208,'19252a')
 text('PATOGEN / 32 X 32 / ESCALA 1X',12,10,'cbd7cc',1)
 for row,kind in ipairs(types) do local y=29+(row-1)*56
 text(names[kind],12,y+13,accent[kind],1)
 for d,dir in ipairs(dirs) do local x=140+(d-1)*57
 rect(x,y,40,40,'30413f');scaled(after[kind][dir][f],x+4,y+4,1)
 if row==3 then text(tags[d]:sub(1,3):upper(),x+9,y+43,'9ab2a4',1) end
 end end
 real:newCel(real.layers[1],f,img,Point(0,0));real.frames[f].duration=.1
end
real:saveAs(root..'/previews/escala_real.aseprite');flatten(real,1):saveAs(root..'/previews/escala_real.png');real:close()
local jf=io.open(root..'/validacion_aseprite.json','w');jf:write(json.encode(checks));jf:close()
print(json.encode(checks))
