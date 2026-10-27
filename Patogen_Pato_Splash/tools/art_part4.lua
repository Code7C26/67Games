-- Aseprite authoring: existing 37-colour palette, new cannon poses and overhead water FX.
local base=assert(app.params['base']);local out=base..'splash/assets/';local pc=app.pixelColor
local swatches={};for line in io.lines(out..'patogen_paleta.gpl')do local r,g,b=line:match('^(%d+)%s+(%d+)%s+(%d+)');if r then swatches[#swatches+1]=Color{r=tonumber(r),g=tonumber(g),b=tonumber(b)}end end
local palette=Palette(#swatches);for i,c in ipairs(swatches)do palette:setColor(i-1,c)end
local allowed={};for i=0,#palette-1 do local c=palette:getColor(i);allowed[pc.rgba(c.red,c.green,c.blue,255)]=true end
local function color(hex)local n=tonumber(hex,16);return pc.rgba((n>>16)&255,(n>>8)&255,n&255,255)end
local im
local function rect(x,y,w,h,c)for yy=y,y+h-1 do for xx=x,x+w-1 do if xx>=0 and yy>=0 and xx<im.width and yy<im.height then im:drawPixel(xx,yy,color(c))end end end end
local function poly(q,c)local low,high=999,-999;for _,a in ipairs(q)do low=math.min(low,a[2]);high=math.max(high,a[2])end
 for y=low,high do local hits={};for j=1,#q do local a,b=q[j],q[j%#q+1];if(a[2]<=y and b[2]>y)or(b[2]<=y and a[2]>y)then hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])end end;table.sort(hits);for j=1,#hits-1,2 do rect(math.ceil(hits[j]),y,math.floor(hits[j+1])-math.ceil(hits[j])+1,1,c)end end
end
local function ellipse(cx,cy,rx,ry,c)for y=math.floor(cy-ry),math.ceil(cy+ry)do for x=math.floor(cx-rx),math.ceil(cx+rx)do if((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then rect(x,y,1,1,c)end end end end
local audit={assets={},off_palette_pixels=0,passed=true,shared_colours=#palette}
local function export(s,name)
 s:setPalette(palette);s:saveAs(out..name..'.aseprite');app.activeSprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..name..'.png',dataFilename=out..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true}
 for f=1,#s.frames do local a=Image(s.width,s.height);a:drawSprite(s,f);for it in a:pixels()do if pc.rgbaA(it())>0 and not allowed[it()]then audit.off_palette_pixels=audit.off_palette_pixels+1 end end end
 audit.assets[#audit.assets+1]={name=name,width=s.width,height=s.height,frames=#s.frames};s:close()
end
local old=app.open(out..'pato_gigante.aseprite');local original=Image(160,144);original:drawSprite(old,1);old:close()
local duck=Sprite(160,144,ColorMode.RGB);duck.layers[1].name='Posturas del canon / normal, inflado, pico abierto'
for f=1,3 do
 if f>1 then duck:newEmptyFrame()end
 im=Image(160,144)
 for y=0,143 do for x=0,159 do
  local sx=x;local sy=y
  if f==2 and y<125 then sx=math.floor(80+(x-80)/1.04+.5);sy=math.floor(80+(y-80)/.97+.5)end
  if sx>=0 and sx<160 and sy>=0 and sy<144 then im:drawPixel(x,y,original:getPixel(sx,sy))end
 end end
 if f==2 then rect(106,40,11,3,'d8943b');rect(111,44,5,11,'493e36');rect(112,45,2,3,'fff5cb');poly({{103,56},{113,53},{122,58},{122,66},{111,69},{102,65}},'ffe99b')end
 if f==3 then
  -- Open jaw: upper lip, dark mouth and lowered lower lip in separate planes.
  poly({{115,56},{134,54},{145,58},{153,64},{153,77},{145,85},{128,86},{115,79},{109,66}},'493e36')
  poly({{116,60},{133,58},{144,61},{149,65},{146,68},{121,67}},'ffb24c')
  rect(123,60,15,2,'ffe99b');rect(136,62,3,2,'9a482f')
  poly({{117,69},{145,70},{148,74},{141,80},{128,81},{116,76}},'28343c')
  poly({{118,78},{132,82},{145,79},{143,83},{129,84},{118,81}},'e78038')
  rect(124,73,17,3,'6ac7f2');rect(133,72,11,2,'b8edff')
 end
 duck:newCel(duck.layers[1],f,im);duck.frames[f].duration=.15
 local tag=duck:newTag(f,f);tag.name=({'normal','inflado','pico_abierto'})[f]
end
export(duck,'pato_canon')
local function make(name,w,h,count,draw)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name='Pixel art / paleta Patogen'
 for f=1,count do if f>1 then s:newEmptyFrame()end;im=Image(w,h);draw(f);s:newCel(s.layers[1],f,im);s.frames[f].duration=.1 end
 export(s,name)
end
make('gota_canon',4,6,1,function()rect(1,0,2,2,'b8edff');rect(0,2,4,3,'6ac7f2');rect(1,5,2,1,'398fc5');rect(1,2,1,2,'e4edef')end)
make('burbuja_canon',8,8,1,function()ellipse(3.5,3.5,3.5,3.5,'6ac7f2');ellipse(3.5,3.5,2.5,2.5,'b8edff');for y=2,5 do for x=2,5 do im:drawPixel(x,y,0)end end;rect(2,1,2,1,'e4edef')end)
make('splash_deck',48,28,4,function(f)
 local rx=9+f*3;local ry=3+f;ellipse(24,22,rx,ry,'6ac7f2');ellipse(24,21,rx-2,ry-2,'b8edff');ellipse(24,21,rx-5,math.max(1,ry-3),'398fc5')
 if f<4 then local y=({14,4,9})[f];rect(22,y,3,19-y,'b8edff');rect(12,y+4,3,3,'b8edff');rect(33,y+2,3,3,'e4edef');rect(5,14+f,2,3,'6ac7f2');rect(40,13+f,2,2,'b8edff')end
end)
make('charco_deck',64,24,3,function(f)
 poly({{5,11},{12,6},{24,5},{31,2+f},{43,5},{54,6},{60,11},{56,16},{45,18},{34,21},{22,19},{10,17}},'28343c')
 rect(16,7,12,1,'6ac7f2');rect(11,9,4,1,'6ac7f2');rect(38,16,12,1,'b8edff');rect(51,14,4,1,'6ac7f2')
end)
make('npc_empapado',32,40,4,function(f)
 for k=0,4 do local x=3+k*6;local y=(k*7+f*5)%32;rect(x,y,2,4,'6ac7f2');rect(x,y,1,2,'b8edff')end
end)
make('npc_cubrirse',32,32,1,function()
 poly({{3,17},{4,11},{9,7},{12,8},{10,12},{7,14},{7,18}},'493e36');poly({{4,15},{5,12},{10,8},{11,9},{8,13},{6,16}},'e8ba87')
 poly({{19,8},{23,7},{28,11},{29,17},{25,18},{24,13},{20,12}},'493e36');poly({{21,9},{23,8},{27,12},{28,15},{26,16},{25,12}},'e8ba87')
end)
audit.passed=audit.off_palette_pixels==0 and #palette==37
local file=assert(io.open(base..'tests/part4_art.json','w'));file:write(json.encode(audit));file:close();assert(audit.passed);print(json.encode(audit))
