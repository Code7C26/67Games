-- Original yaw views and pixel water crowns, authored in Aseprite's native images.
local base=assert(app.params['base']);local out=base..'splash/assets/';local pc=app.pixelColor
local colours={};local allowed={}
for l in io.lines(out..'patogen_paleta.gpl')do local r,g,b=l:match('^(%d+)%s+(%d+)%s+(%d+)');if r then local c=pc.rgba(tonumber(r),tonumber(g),tonumber(b),255);colours[#colours+1]=c;allowed[c]=true end end
local pal=Palette(#colours);for i,c in ipairs(colours)do pal:setColor(i-1,Color(c))end
local function col(h)local n=tonumber(h,16);return pc.rgba((n>>16)&255,(n>>8)&255,n&255,255)end
local im
local function rect(x,y,w,h,c)x=math.floor(x+.5);y=math.floor(y+.5);for yy=y,y+h-1 do for xx=x,x+w-1 do if xx>=0 and yy>=0 and xx<im.width and yy<im.height then im:drawPixel(xx,yy,col(c))end end end end
local function poly(points,c)
 local lo,hi=999,-999;for _,v in ipairs(points)do lo=math.min(lo,v[2]);hi=math.max(hi,v[2])end
 for y=math.floor(lo),math.ceil(hi)do local hits={};for i=1,#points do local a,b=points[i],points[i%#points+1];if(a[2]<=y and b[2]>y)or(b[2]<=y and a[2]>y)then hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])end end;table.sort(hits);for i=1,#hits-1,2 do rect(math.ceil(hits[i]),y,math.floor(hits[i+1])-math.ceil(hits[i])+1,1,c)end end
end
local function facet(cx,cy,rx,ry,c)
 local q={};for i=0,11 do local t=i*math.pi/6;q[#q+1]={math.floor((cx+math.cos(t)*rx)/2+.5)*2,math.floor((cy+math.sin(t)*ry)/2+.5)*2}end;poly(q,c)
end
local function ellipse(cx,cy,rx,ry,c)
 for y=math.floor(cy-ry),math.ceil(cy+ry)do for x=math.floor(cx-rx),math.ceil(cx+rx)do if((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then rect(x,y,1,1,c)end end end
end
local audit={assets={},off_palette_pixels=0,shared_colours=#colours,passed=true}
local function export(s,name)
 s:setPalette(pal);s:saveAs(out..name..'.aseprite');app.activeSprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..name..'.png',dataFilename=out..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true}
 for f=1,#s.frames do local image=Image(s.width,s.height);image:drawSprite(s,f);for it in image:pixels()do if pc.rgbaA(it())>0 and not allowed[it()]then audit.off_palette_pixels=audit.off_palette_pixels+1 end end end
 audit.assets[#audit.assets+1]={name=name,width=s.width,height=s.height,frames=#s.frames};s:close()
end
local duck=Sprite(160,144,ColorMode.RGB);duck.layers[1].name='Giro vertical / 16 vistas / sin rotar el lienzo'
local anchors={}
for f=0,15 do
 if f>0 then duck:newEmptyFrame()end;im=Image(160,144)
 local a=f*math.pi/8;local c,s=math.cos(a),math.sin(a)
 local hx,hy=80+20*c,46+10*s
 local rx=math.sqrt((51*c)^2+(35*s)^2);local ry=math.sqrt((27*c)^2+(33*s)^2)
 -- Stable water contact and stepped vinyl silhouette.
 facet(80,129,rx+10,11,'307ba7');rect(43,139,23,1,'6ac7f2');rect(107,136,16,1,'b8edff')
 poly({{hx-17,hy+14},{hx+16,hy+12},{hx+23,101},{hx+13,117},{hx-24,110}},'493e36')
 poly({{hx-12,hy+16},{hx+11,hy+15},{hx+17,100},{hx+8,111},{hx-18,108}},'efbf4b')
 local tx,ty=80-48*c,104-21*s
 poly({{tx-7,ty+7},{tx-12*c,ty-19},{tx+9,ty+8}},'493e36')
 poly({{tx-3,ty+4},{tx-8*c,ty-12},{tx+5,ty+5}},'f8d864')
 facet(80,104,rx,ry,'493e36');facet(80,103,rx-4,ry-4,'d8943b')
 facet(79,99,rx-7,ry-8,'efbf4b');facet(77,96,rx-12,ry-11,'f8d864')
 poly({{80-rx+13,94},{80-rx+22,87},{78,84},{85,88},{63,92},{80-rx+16,100}},'ffe99b')
 -- Near wing panel follows the visible side of the body.
 local side=c>=0 and 1 or -1
 local wx=80-21*s*side-5*c;local wy=104+5*math.abs(c)
 local wr=11+13*math.abs(c)
 poly({{wx-wr,wy-7},{wx-8,wy-15},{wx+8,wy-13},{wx+wr,wy-4},{wx+wr-5,wy+3},{wx+7,wy+12},{wx-8,wy+10},{wx-wr,wy+2}},'d8943b')
 poly({{wx-wr+4,wy-6},{wx-6,wy-11},{wx+6,wy-9},{wx+wr-5,wy-3},{wx+7,wy+7},{wx-6,wy+5}},'ffe99b')
 poly({{wx-wr+6,wy-3},{wx-3,wy-6},{wx+wr-8,wy-1},{wx+4,wy+4},{wx-5,wy+2}},'f8d864')
 for x=58,99,8 do rect(x,124,3,1,'ffe99b')end
 rect(111-12*math.abs(s),117,6,5,'493e36');rect(112-12*math.abs(s),118,3,2,'e78038')
 local function head()
  poly({{hx-17,hy-10},{hx-12,hy-20},{hx-5,hy-24},{hx-9,hy-33},{hx-2,hy-28},{hx+2,hy-36},{hx+9,hy-25},{hx+17,hy-18},{hx+22,hy-7},{hx+21,hy+10},{hx+13,hy+20},{hx-8,hy+21},{hx-18,hy+12},{hx-21,hy}},'493e36')
  facet(hx,hy,18,22,'d8943b');facet(hx-1,hy-2,15,19,'efbf4b');facet(hx-3,hy-4,12,16,'f8d864')
  poly({{hx-14,hy-8},{hx-8,hy-18},{hx+2,hy-20},{hx+10,hy-15},{hx+7,hy-11},{hx-2,hy-14},{hx-8,hy-7},{hx-10,hy+3},{hx-14,hy+2}},'ffe99b')
  rect(hx-5,hy-20,7,2,'fff5cb')
 end
 head()
 local bx,by=hx+27*c,hy+11+13*s
 if s>-.76 then
  local bw=10+9*math.abs(s);local bh=6+2*math.abs(s)
  facet(bx,by,bw+4,bh+5,'493e36');facet(bx,by+3,bw,bh,'e78038')
  facet(bx,by-3,bw+1,bh-1,'ffb24c');rect(bx-bw+3,by-6,math.max(4,math.floor(bw)),2,'ffe99b')
  poly({{bx-bw+1,by},{bx+bw-1,by},{bx+bw-3,by+4},{bx-bw+3,by+5}},'28343c')
  rect(bx-3,by+1,6,2,'6ac7f2')
  local ex=hx+(c>=0 and 7 or -12)
  rect(ex,hy-7,8,13,'493e36');rect(ex+1,hy-6,5,9,'fff5cb');rect(ex+(c>=0 and 4 or 1),hy-3,4,9,'493e36');rect(ex+3,hy-5,2,2,'fff5cb')
  if s>.65 then local other=hx+(c>=0 and -12 or 7);rect(other,hy-6,6,11,'493e36');rect(other+1,hy-5,3,7,'fff5cb');rect(other+2,hy-2,3,8,'493e36')end
 else
  -- Back of the head: seam, no eyes or beak pasted through it.
  rect(hx+9,hy-11,2,19,'d8943b');rect(hx+10,hy+9,2,4,'ffe99b')
 end
 duck:newCel(duck.layers[1],f+1,im);duck.frames[f+1].duration=.1
 anchors[#anchors+1]={mouth={bx,by},head={hx,hy-26}}
 -- The visible mouth center is the emission anchor; hidden bill emerges behind the head.
 anchors[#anchors].mouth={bx+(s>-.76 and (c>=0 and 3 or -3) or 0),by+2}
end
export(duck,'pato_giro')
local file=assert(io.open(out..'pato_giro_anchors.json','w'));file:write(json.encode(anchors));file:close()
-- Hollow, stepped water crown: flat footprint, high rear crest, lower front wall.
local crown=Sprite(64,48,ColorMode.RGB);crown.layers[1].name='Corona / agua celeste y espuma escalonada'
for f=1,4 do
 if f>1 then crown:newEmptyFrame()end;im=Image(64,48)
 if f<4 then
  local h=({8,19,11})[f];local lift=function(y)return 38-(38-y)*h/19 end
  local rear={{7,33},{9,lift(18)},{13,lift(20)},{14,lift(11)},{18,lift(15)},{22,lift(16)},{24,lift(7)},{28,lift(13)},{34,lift(15)},{36,lift(5)},{39,lift(13)},{45,lift(16)},{48,lift(10)},{51,lift(18)},{55,lift(17)},{58,33},{51,38},{15,38}}
  poly(rear,'6ac7f2')
  for j=2,17 do local a,b=rear[j],rear[j+1];poly({a,b,{b[1],b[2]+4},{a[1],a[2]+4}},'b8edff')end
  for _,v in ipairs({{14,11},{24,7},{36,5},{48,10}})do rect(v[1],lift(v[2]),3,3,'e4edef')end
  -- The transparent opening leaves the floor visible inside the splash.
  for y=27,36 do for x=11,53 do if((x-32)/21)^2+((y-31)/5)^2<1 then im:drawPixel(x,y,0)end end end
  local front={{7,32},{11,lift(23)},{15,lift(27)},{19,lift(29)},{23,lift(22)},{28,lift(30)},{33,lift(25)},{38,lift(29)},{43,lift(24)},{48,lift(28)},{53,lift(22)},{57,32},{54,38},{44,42},{22,43},{11,38}}
  poly(front,'398fc5')
  local band={};for j=1,12 do band[#band+1]=front[j]end;for j=12,1,-1 do band[#band+1]={front[j][1],front[j][2]+5}end;poly(band,'b8edff')
  rect(22,37,17,3,'6ac7f2');rect(13,33,4,3,'6ac7f2');rect(45,34,5,4,'6ac7f2')
  if f==2 then rect(5,16,3,4,'b8edff');rect(56,13,3,4,'e4edef')end
 else
  ellipse(32,39,27,7,'6ac7f2');ellipse(32,38,23,5,'b8edff')
  for y=35,41 do for x=13,51 do if((x-32)/19)^2+((y-38)/3)^2<1 then im:drawPixel(x,y,0)end end end
  rect(8,34,7,2,'e4edef');rect(46,41,8,2,'b8edff')
 end
 crown:newCel(crown.layers[1],f,im);crown.frames[f].duration=.12
end
export(crown,'splash_corona')
audit.passed=audit.off_palette_pixels==0 and #colours==37
file=assert(io.open(base..'tests/giro360_art.json','w'));file:write(json.encode(audit));file:close();assert(audit.passed);print(json.encode(audit))
