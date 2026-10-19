-- Run inside Aseprite. All drawing, animation and compositing use its native API.
local root = app.params.output or (app.fs.currentPath .. '/generated/patogen-infecciones-refinadas-oct15/zonas')
local reference = app.params.reference or (app.fs.currentPath .. '/generated/textures/mall-prueba-01/01_piso_ceramica_blanca.png')
app.fs.makeAllDirectories(root .. '/assets')
app.fs.makeAllDirectories(root .. '/previews')
local N, SIZE, SCALE = 48, 192, 2
local TAU = math.pi * 2
local img
local function color(hex, alpha)
  return app.pixelColor.rgba(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16), alpha or 255)
end
local function p(x,y,c)
  x,y=math.floor(x+.5),math.floor(y+.5)
  if x>=0 and y>=0 and x<img.width and y<img.height then img:drawPixel(x,y,c) end
end
local function rect(x,y,w,h,c)
  for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end
end
local function line(x,y,x1,y1,c,width)
  x,y,x1,y1=math.floor(x+.5),math.floor(y+.5),math.floor(x1+.5),math.floor(y1+.5)
  local dx,sx=math.abs(x1-x),x<x1 and 1 or -1
  local dy,sy=-math.abs(y1-y),y<y1 and 1 or -1
  local err=dx+dy
  while true do
    if width and width>1 then rect(x-math.floor(width/2),y-math.floor(width/2),width,width,c) else p(x,y,c) end
    if x==x1 and y==y1 then break end
    local e2=2*err
    if e2>=dy then err=err+dy;x=x+sx end
    if e2<=dx then err=err+dx;y=y+sy end
  end
end
local function poly(pts,c)
  local ymin,ymax=999,-999
  for _,q in ipairs(pts) do ymin=math.min(ymin,q[2]);ymax=math.max(ymax,q[2]) end
  for y=math.ceil(ymin),math.floor(ymax) do
    local nodes={};local j=#pts
    for i=1,#pts do
      local a,b=pts[i],pts[j]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then nodes[#nodes+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end
      j=i
    end
    table.sort(nodes)
    for i=1,#nodes-1,2 do for x=math.ceil(nodes[i]),math.floor(nodes[i+1]) do p(x,y,c) end end
  end
end
local function diamond(x,y,r,c)
  for dy=-r,r do local w=r-math.abs(dy);line(x-w,y+dy,x+w,y+dy,c) end
end
local function star(x,y,r,c)
  line(x-r,y,x+r,y,c);line(x,y-r,x,y+r,c)
  if r>=3 then p(x-1,y-1,c);p(x+1,y+1,c);p(x+1,y-1,c);p(x-1,y+1,c) end
end
local function roundrect(x,y,w,h,c)
  rect(x+2,y,w-4,h,c);rect(x,y+2,w,h-4,c);rect(x+1,y+1,w-2,h-2,c)
end
local function arc(radius,c,start,finish)
  start,finish=start or 0,finish or TAU
  local steps=math.max(1,math.ceil((finish-start)*radius*2))
  local last
  for i=0,steps do
    local a=start+(finish-start)*i/steps
    local x,y=95.5+math.cos(a)*radius,95.5+math.sin(a)*radius
    if last then line(last[1],last[2],x,y,c) end
    last={x,y}
  end
end
local function upscale(small)
  local out=Image(small.width*SCALE,small.height*SCALE,ColorMode.RGB)
  for y=0,small.height-1 do for x=0,small.width-1 do
    local c=small:getPixel(x,y)
    if app.pixelColor.rgbaA(c)>0 then
      for yy=0,SCALE-1 do for xx=0,SCALE-1 do out:drawPixel(x*SCALE+xx,y*SCALE+yy,c) end end
    end
  end end
  return out
end
local function newanim(w,h,n,names)
  local sp=Sprite(w,h,ColorMode.RGB);sp.layers[1].name=names[1]
  for i=2,#names do sp:newLayer().name=names[i] end
  for f=2,n do sp:newEmptyFrame(f) end
  for f=1,n do sp.frames[f].duration=(f%4==0) and .07 or .06 end
  return sp
end

-- V3: padded particle and atmosphere effects. No emblem or sprite occupies the centre.
local C=95.5
local P={
 caliente={deep='a93645',outer='e4524c',mid='ff9851',light='ffe29b',white='fff3c7',halo='ef654d',accent='ef9071'},
 fria={deep='3b609c',outer='608acf',mid='71cee8',light='b9f7ff',white='edffff',halo='4e9adb',accent='aca3e4'}
}
local function mix(a,b,t,opacity)
 local function channel(s,i) return tonumber(s:sub(i,i+1),16) end
 t=math.max(0,math.min(1,t))
 return app.pixelColor.rgba(math.floor(channel(a,1)*(1-t)+channel(b,1)*t+.5),math.floor(channel(a,3)*(1-t)+channel(b,3)*t+.5),math.floor(channel(a,5)*(1-t)+channel(b,5)*t+.5),math.floor(opacity+.5))
end
local function polar(r,a) return C+math.cos(a)*r,C+math.sin(a)*r end
local function ease(x) x=math.max(0,math.min(1,x));return x*x*(3-2*x) end
local function glow(x,y,r,c,alpha)
 for yy=math.floor(y-r),math.ceil(y+r) do for xx=math.floor(x-r),math.ceil(x+r) do
  local d=((xx-x)^2+(yy-y)^2)/(r*r)
  if d<1 then p(xx,yy,color(c,math.floor(alpha*(1-d)^2))) end
 end end
end
local function halo(kind,phase)
 local pal=P[kind];local hot=kind=='caliente'
 for y=0,SIZE-1 do for x=0,SIZE-1 do
  local dx,dy=x-C,y-C;local r=math.sqrt(dx*dx+dy*dy)
  if r>32 and r<67.2 then
   local a=math.atan(dy,dx)
   local swell=.78+.22*math.sin(a*3+phase)^2
   local broad=math.exp(-((r-58)/7.5)^2)*30*swell
   local edge=math.exp(-((r-61)/3.4)^2)*46
   local inside=ease((r-32)/23)*5
   local fade=ease((67.2-r)/3)
   local alpha=(broad+edge+inside)*fade
   -- Sparse, stationary dither keeps the halo in the pixel-art vocabulary.
   if (x*17+y*31)%19==0 then alpha=alpha*.85 end
   p(x,y,mix(pal.outer,pal.halo,.5+.3*math.sin(a*2-phase),alpha))
  end
 end end
end
local function rim(kind,phase)
 local pal=P[kind];local hot=kind=='caliente'
 for y=0,SIZE-1 do for x=0,SIZE-1 do
  local dx,dy=x-C,y-C;local r=math.sqrt(dx*dx+dy*dy);local a=math.atan(dy,dx)
  local rr=60.5+(hot and .55 or .22)*math.sin(a*(hot and 7 or 12)+phase)
  local d=r-rr
  if math.abs(d)<2.2 then
   local shine=math.exp(-(d/.63)^2)
   local energy=.72+.28*math.sin(a*3-phase)^2
   local alpha=(115+112*shine)*energy
   local tone=math.max(0,1-math.abs(d+0.5)/1.9)
   p(x,y,mix(pal.deep,pal.mid,tone,alpha))
   if math.abs(d)<.48 then p(x,y,mix(pal.mid,pal.light,.3+.4*math.sin(a*4+phase)^2,185+35*energy)) end
  end
 end end
 for k=0,2 do
  local a=k*TAU/3+(hot and .15 or -.15)*math.sin(phase)
  arc(55.5,color(pal.outer,65),a+.1,a+1.0)
  arc(54.5,color(pal.mid,35),a+.2,a+.85)
 end
end
local function currents(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 for k=0,2 do
  local start=k*TAU/3+(hot and phase or -phase)
  local last
  for j=0,95 do
   local u=j/95
   local a=start+u*1.26
   local r=58.4+(hot and 1.3 or .7)*math.sin(a*4+phase)+(u-.5)*2.2
   local x,y=polar(r,a)
   local alpha=math.floor((math.sin(u*math.pi)^.7)*220)
   if last then
    line(last[1],last[2],x,y,color(pal.mid,alpha*.7),2)
    if u>.35 then line(last[1],last[2],x,y,mix(pal.light,pal.white,u,alpha)) end
   end
   last={x,y}
  end
 end
 -- Short detached flow lines give depth without closing off the centre.
 for k=0,8 do
  local start=k*2.399963+phase*(hot and 1 or -1)
  local radius=50.5+3*math.sin(k*1.7+phase)
  local a=math.floor(50+38*(math.sin(k+phase)^2))
  arc(radius,color(pal.mid,a),start,start+.22)
  arc(radius-1,color(pal.light,math.floor(a*.6)),start+.07,start+.18)
 end
 for k=0,1 do
  local u=(t+k*.5)%1
  local r=43+u*16
  local alpha=math.floor(45*math.sin(math.pi*u))
  for j=0,2 do
   local a=j*TAU/3+(hot and .25 or -.25)*math.sin(phase)+k
   arc(r,color(pal.mid,alpha),a,a+.9)
  end
 end
end
local function thermal_wisps(phase)
 local pal=P.caliente
 for k=0,8 do
  local a=k*TAU/9+.15*math.sin(phase+k)
  local r=52+3*math.sin(phase+k*1.3)
  local bx,by=polar(r,a);local last
  for j=0,11 do
   local u=j/11
   local x=bx+1.6*math.sin(u*math.pi*2+phase+k)
   local y=by-u*7
   local alpha=math.floor(66*math.sin(math.pi*u))
   if last then line(last[1],last[2],x,y,color(pal.accent,alpha)) end
   last={x,y}
  end
 end
 -- Warm irregular fragments sit along the rim; none are flame symbols.
 for i=0,22 do
  local a=i*2.399963
  local r=59+1.3*math.sin(a*5+phase)
  local x,y=polar(r,a)
  local alpha=math.floor(90+65*(math.sin(phase+i)^2))
  line(x,y,x+math.cos(a+.9)*2,y+math.sin(a+.9)*2,color(pal.light,alpha))
 end
end
local function frost(phase)
 local pal=P.fria
 for i=0,18 do
  local a=i*2.399963+.12*math.sin(i*3.1)
  local dx,dy=math.cos(a),math.sin(a);local tx,ty=-dy,dx
  local r=60.8
  local len=3.5+(i*7%8)
  local width=1.2+(i*3%4)*.35
  local function q(rad,w) return {C+dx*rad+tx*w,C+dy*rad+ty*w} end
  local b1,b2,tip,back=q(r,-width),q(r+1.2,width),q(r-len,.3),q(r+2,0)
  local glint=.5+.5*math.sin(phase+i*1.7)
  poly({b1,back,b2,tip},color(pal.deep,145))
  poly({b1,back,tip},color(pal.mid,150+math.floor(glint*35)))
  poly({back,b2,tip},color(pal.light,110+math.floor(glint*65)))
  local mid=q(r+.5,0)
  line(mid[1],mid[2],tip[1],tip[2],color(pal.white,150+math.floor(glint*70)))
  -- A tiny offset facet creates clustered, asymmetrical frost.
  if i%3==0 then
   local a1,a2,a3=q(r-1,width+1),q(r-5,width+3),q(r+1,width+2)
   poly({a1,a2,a3},color(pal.accent,100))
   line(a1[1],a1[2],a2[1],a2[2],color(pal.light,175))
  end
 end
 for k=0,31 do
  local a=k*2.399963
  local r=62+(k%3)*.7
  local x,y=polar(r,a)
  p(x,y,color(pal.light,95+math.floor(65*(math.sin(phase+k)^2))))
 end
end
local function motes(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 local count=hot and 36 or 30
 for i=0,count-1 do
  local u=(t+i*.61803398875)%1
  local a=i*2.399963+(hot and .23 or -.18)*math.sin(phase+i*.7)
  local r=hot and (63-u*15) or (49+u*14)
  local x,y=polar(r,a)
  y=y+(hot and -4*u or 2*math.sin(phase+i))
  local opacity=math.floor((math.sin(math.pi*u)^1.1)*215)
  if i%6==0 then glow(x,y,2.5,pal.mid,math.floor(opacity*.4)) end
  if hot then
   line(x,y,x+.8*math.sin(a),y+1+(i%3),color(pal.outer,math.floor(opacity*.55)))
   p(x,y,color(i%4==0 and pal.white or pal.light,opacity))
   if i%8==0 then p(x+1,y,color(pal.mid,opacity)) end
  else
   if i%5==0 then
    line(x-1,y,x+1,y,color(pal.light,opacity))
    p(x,y-1,color(pal.white,opacity))
   else
    p(x,y,color(i%3==0 and pal.accent or pal.light,opacity))
   end
  end
 end
end
local function glints(kind,phase)
 local hot=kind=='caliente';local pal=P[kind]
 for i=0,7 do
  local a=i*TAU/8+.3
  local r=hot and 59.5 or (57+(i%3)*2)
  local x,y=polar(r,a)
  local intensity=math.max(0,math.sin(phase*2+i*1.7))^7
  local opacity=math.floor(235*intensity)
  if opacity>8 then
   glow(x,y,3.1,pal.mid,math.floor(opacity*.4))
   if hot then
    p(x,y,color(pal.white,opacity));p(x-1,y,color(pal.light,math.floor(opacity*.65)))
   else
    local z=intensity>.7 and 2 or 1
    line(x-z,y,x+z,y,color(pal.light,math.floor(opacity*.75)))
    line(x,y-z,x,y+z,color(pal.light,math.floor(opacity*.75)))
    p(x,y,color(pal.white,opacity))
   end
  end
 end
end

-- Atmospheric V3 effects extend outside the gameplay circle into a padded canvas.
local function cloud(x,y,rx,ry,c,opacity)
 for yy=math.floor(y-ry),math.ceil(y+ry) do for xx=math.floor(x-rx),math.ceil(x+rx) do
  local d=((xx-x)/rx)^2+((yy-y)/ry)^2
  if d<1 and xx>=0 and yy>=0 and xx<SIZE and yy<SIZE then
   local a=math.floor(opacity*(1-d)^2)
   if (xx*13+yy*7)%11==0 then a=math.floor(a*.8) end
   if a>app.pixelColor.rgbaA(img:getPixel(xx,yy)) then p(xx,yy,color(c,a)) end
  end
 end end
end
local function atmosphere(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 for i=0,13 do
  local u=(t*2+i*.41421356237)%1
  local a=i*2.399963+(hot and .12 or -.16)*math.sin(phase+i)
  local interior=i%4==0
  local x,y=polar(interior and (52+u*5) or (58+u*11),a)
  x=x+math.sin(math.pi*u)*3*(hot and 1 or -1)
  y=y-(hot and (interior and 4 or 10)*u or 3*math.sin(math.pi*u))
  local alpha=math.floor((hot and 145 or 140)*math.sin(math.pi*u)^1.3)
  cloud(x,y,7+u*4,4+u*4,hot and pal.outer or pal.accent,alpha)
  cloud(x-1,y-1,3+u*3,1.5+u*2,pal.mid,math.floor(alpha*.55))
  -- Broken drifting wisps provide a visible wind direction.
  local last
  for j=0,10 do
   local v=j/10
   local xx=x+(v-.5)*9
   local yy=y+math.sin(v*math.pi*2+phase+i)*1.4-v*(hot and 2.5 or 0)
   if last then line(last[1],last[2],xx,yy,color(pal.light,math.floor(alpha*.65*math.sin(v*math.pi)))) end
   last={xx,yy}
  end
 end
end
local function comet_position(hot,i,u)
 local a=i*2.399963+(hot and .28 or -.65)*u
 local x,y=polar(57+u*(hot and 22 or 23),a)
 x=x+math.sin(u*math.pi+i)*u*2
 y=y-(hot and 9*u or 0)
 return x,y
end
local function streaks(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 local count=hot and 13 or 11
 for i=0,count-1 do
  local u=(t*2+i*.41421356237)%1
  local life=math.sin(math.pi*u)^.8
  local x,y=comet_position(hot,i,u)
  local last
  for j=0,11 do
   local age=math.max(0,u-.15+.15*j/11)
   local xx,yy=comet_position(hot,i,age)
   local alpha=math.floor(life*(j/11)^1.6*205)
   if last then
    line(last[1],last[2],xx,yy,color(pal.outer,math.floor(alpha*.65)),3)
    line(last[1],last[2],xx,yy,mix(pal.mid,pal.light,j/11,alpha),1)
   end
   last={xx,yy}
  end
  glow(x,y,3.8,pal.mid,math.floor(95*life))
  if hot then
   diamond(x,y,2,color(pal.deep,math.floor(220*life)))
   diamond(x,y,1,color(pal.mid,math.floor(250*life)))
   line(x,y-1,x,y+1,color(pal.light,math.floor(250*life)))
   p(x,y,color(pal.white,math.floor(252*life)))
  else
   local px,py=comet_position(hot,i,math.max(0,u-.04))
   local vx,vy=x-px,y-py;local mag=math.sqrt(vx*vx+vy*vy)
   if mag<.001 then vx,vy,mag=0,1,1 end
   vx,vy=vx/mag,vy/mag
   local tx,ty=-vy,vx
   local back={x-vx*3,y-vy*3}
   local tip={x+vx*3.5,y+vy*3.5}
   local left={x+tx*1.5,y+ty*1.5}
   local right={x-tx*1.5,y-ty*1.5}
   poly({back,left,tip,right},color(pal.deep,math.floor(220*life)))
   poly({back,left,tip},color(pal.mid,math.floor(235*life)))
   poly({back,right,tip},color(pal.light,math.floor(240*life)))
   line(back[1],back[2],tip[1],tip[2],color(pal.white,math.floor(250*life)))
  end
 end
end
local function showers(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 local count=hot and 56 or 46
 for i=0,count-1 do
  local u=(t*3+i*.75487766625)%1
  local a=i*2.399963+(hot and .22 or -.3)*u
  local r=54+u*29
  local x,y=polar(r,a)
  x=x+math.sin(u*math.pi)*2*math.sin(i)
  y=y-(hot and 7*u or 1.5*math.sin(u*math.pi))
  local alpha=math.floor(235*math.sin(math.pi*u)^.85)
  if i%7==0 then glow(x,y,3.3,pal.mid,math.floor(alpha*.45)) end
  if hot then
   if i%4==0 then
    line(x,y,x-.6,y+3,color(pal.deep,math.floor(alpha*.8)),2)
    line(x,y,x,y+2,color(pal.mid,alpha))
    diamond(x,y,1,color(pal.light,alpha))
   else
    p(x,y,color(i%3==0 and pal.white or pal.light,alpha))
    if i%3==0 then p(x,y+1,color(pal.outer,alpha)) end
   end
  elseif i%5==0 then
   -- Four-point glints stay small; there is no central snowflake emblem.
   star(x,y,2,color(pal.light,math.floor(alpha*.8)));p(x,y,color(pal.white,alpha))
  elseif i%3==0 then
   poly({{x,y-2.5},{x+1.5,y},{x,y+2},{x-1.5,y}},color(pal.deep,alpha))
   poly({{x,y-2.5},{x+1.5,y},{x,y+2}},color(pal.mid,alpha))
   line(x,y-2,x,y+1,color(pal.white,alpha))
  else diamond(x,y,1,color(i%2==0 and pal.light or pal.accent,alpha)) end
 end
end
local function pulses(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 for i=0,2 do
  local u=(t+i/3)%1
  local radius=52+u*32
  local alpha=math.floor((hot and 160 or 145)*math.sin(math.pi*u)^2)
  for k=0,5 do
   local start=k*TAU/6+(hot and .16 or -.16)*math.sin(phase)+i*.37
   local last
   for j=0,36 do
    local v=j/36;local a=start+v*.78
    local r=radius+(hot and .55 or .2)*math.sin(a*8+phase)
    local x,y=polar(r,a)
    local aa=math.floor(alpha*math.sin(math.pi*v)^.4)
    if last then
     line(last[1],last[2],x,y,color(pal.outer,math.floor(aa*.5)),3)
     line(last[1],last[2],x,y,color(pal.mid,aa))
    end
    last={x,y}
   end
  end
 end
end


local function interior_particles(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 for i=0,(hot and 73 or 77) do
  local seed1=(math.sin(i*12.9898+4.71)*43758.5453)%1
  local seed2=(math.sin(i*78.233+.1)*12345.6789)%1
  local u=(t*(hot and 2 or 1)+seed2)%1
  local dx=-50+seed1*100+1.2*math.sin(phase+i)
  local extent=math.sqrt(math.max(0,52^2-dx^2))
  local x=C+dx
  local y=C+extent*(hot and (1-2*u) or (2*u-1))
  local alpha=math.floor((hot and 210 or 195)*math.sin(math.pi*u)^.85)
  if i%9==0 then glow(x,y,2.4,pal.mid,math.floor(alpha*.3)) end
  if hot then
   line(x,y,x+.4*math.sin(i),y+2,color(pal.deep,math.floor(alpha*.7)))
   if i%6==0 then diamond(x,y,1,color(pal.mid,alpha)) end
   p(x,y,color(i%3==0 and pal.light or pal.mid,alpha))
   if i%5==0 then p(x,y-1,color(pal.white,alpha)) end
  else
   if i%7==0 then
    diamond(x,y,1,color(pal.outer,math.floor(alpha*.85)))
    p(x,y,color(pal.white,alpha))
   elseif i%11==0 then
    line(x-1,y,x+1,y,color(pal.mid,alpha));line(x,y-1,x,y+1,color(pal.light,alpha))
   else
    p(x,y,color(i%3==0 and pal.mid or pal.light,alpha))
    if i%4==0 then p(x+1,y-1,color(pal.outer,math.floor(alpha*.7))) end
   end
  end
 end
end
local function interior_air(kind,phase,t)
 local hot=kind=='caliente';local pal=P[kind]
 for i=0,5 do
  local a=i*2.399963+.15*math.sin(phase+i)
  local r=12+(i*17%31)
  local x,y=polar(r,a)
  y=y+math.sin(phase+i)*(hot and 3 or 2)
  cloud(x,y,8+(i%3)*2,3+(i%2),hot and pal.accent or pal.halo,hot and 32 or 35)
  local last
  for j=0,18 do
   local u=j/18
   local xx=x+(u-.5)*17
   local yy=y+math.sin(u*TAU+phase+i)*1.1
   local aa=math.floor((hot and 36 or 32)*math.sin(u*math.pi))
   if last then line(last[1],last[2],xx,yy,color(pal.mid,aa)) end
   last={xx,yy}
  end
 end
end

local sprites={}
for _,kind in ipairs({'caliente','fria'}) do
 local sp=newanim(384,384,N,{'Halo exterior','Aro de temperatura','Corrientes y pulsos',kind=='caliente' and 'Distorsion termica' or 'Facetas de escarcha','Particulas del aro','Reflejos',kind=='caliente' and 'Vapor termico' or 'Niebla glacial','Estelas exteriores','Emision de particulas','Ondas de expansion','Particulas interiores','Atmosfera interior'})
 sp.gridBounds=Rectangle(0,0,2,2)
 for f=1,N do
  local t=(f-1)/N;local phase=t*TAU
  for layer=1,12 do
   img=Image(SIZE,SIZE,ColorMode.RGB)
   if layer==1 then halo(kind,phase)
   elseif layer==2 then rim(kind,phase)
   elseif layer==3 then currents(kind,phase,t)
   elseif layer==4 then if kind=='caliente' then thermal_wisps(phase) else frost(phase) end
   elseif layer==5 then motes(kind,phase,t)
   elseif layer==6 then glints(kind,phase)
   elseif layer==7 then atmosphere(kind,phase,t)
   elseif layer==8 then streaks(kind,phase,t)
   elseif layer==9 then showers(kind,phase,t)
   elseif layer==10 then pulses(kind,phase,t)
   elseif layer==11 then interior_particles(kind,phase,t)
   else interior_air(kind,phase,t) end
   if layer>=11 then for yy=0,SIZE-1 do for xx=0,SIZE-1 do if (xx-C)^2+(yy-C)^2>58^2 then img:drawPixel(xx,yy,0) end end end end
   sp:newCel(sp.layers[layer],f,upscale(img),Point(0,0))
  end
 end
 local tag=sp:newTag(1,N);tag.name='bucle';tag.aniDir=AniDir.FORWARD
 local sl=sp:newSlice(Rectangle(57,57,270,270));sl.name='area_logica_270';sl.pivot=Point(135,135)
 sp:saveAs(root..'/assets/zona_'..kind..'.aseprite')
 sprites[kind]=sp
 print('Zona '..kind..': particulas interiores y exteriores, 48 frames, 12 capas')
end
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


local floor=Image{fromFile=reference}
local function backdrop(dark)
 local out=Image(960,600,ColorMode.RGB);img=out
 rect(0,0,960,600,color('171f2c'))
 rect(28,24,3,30,color('7fc6d5'))
 text('PATOGEN',44,24,color('f1ecdf'),3)
 text('ZONAS DE TEMPERATURA',246,31,color('94a8c1'),2)
 text('CALOR',40,84,color('ffbe7c'),2)
 text('FRIO',508,84,color('a0dfea'),2)
 text('BRASAS / ESTELAS / VAPOR',40,111,color('b39e9d'),1)
 text('CRISTALES / RAFAGAS / ESCARCHA',508,111,color('9ab2c9'),1)
 for _,x in ipairs({24,492}) do
  roundrect(x,132,444,416,color('0c1420'))
  for yy=0,409 do for xx=0,437 do
   local c=floor:getPixel(xx%floor.width,yy%floor.height)
   if dark then
    local r=app.pixelColor.rgbaR(c);local g=app.pixelColor.rgbaG(c);local b=app.pixelColor.rgbaB(c)
    c=app.pixelColor.rgba(math.floor(r*.13+9),math.floor(g*.15+13),math.floor(b*.18+19),255)
   end
   out:drawPixel(x+3+xx,135+yy,c)
  end end
 end
 text('PARTICULAS INTERIORES Y EXTERIORES',28,574,color('8b9cb4'),1)
 text('48 FRAMES / 3 S / FONDO TRANSPARENTE',510,574,color('8b9cb4'),1)
 return out
end
for _,dark in ipairs({true,false}) do
 local base=backdrop(dark)
 local preview=newanim(960,600,N,{'Presentacion'})
 for f=1,N do
  local im=Image(base)
  for i,kind in ipairs({'caliente','fria'}) do
   local effect=Image(384,384,ColorMode.RGB);effect:drawSprite(sprites[kind],f)
   im:drawImage(effect,Point(i==1 and 54 or 522,150))
  end
  preview:newCel(preview.layers[1],f,im,Point(0,0))
 end
 local name=dark and 'zonas_caliente_y_fria' or 'sobre_piso_claro'
 preview:saveAs(root..'/previews/'..name..'.aseprite')
 local still=Image(960,600,ColorMode.RGB);still:drawSprite(preview,13)
 still:saveAs(root..'/previews/'..name..'.png')
 preview:close()
end
for _,s in pairs(sprites) do s:close() end
print('Vistas con particulas completas sobre piso claro y oscuro listas')




