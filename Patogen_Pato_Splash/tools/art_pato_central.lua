-- Central inflatable redraw, authored in Aseprite. Existing 160x144 frame/37 swatches.
local base=assert(app.params['base']);local out=base..'splash/assets/';local pc=app.pixelColor
local colors={};local allowed={}
for l in io.lines(out..'patogen_paleta.gpl')do local r,g,b=l:match('^(%d+)%s+(%d+)%s+(%d+)');if r then local v=pc.rgba(tonumber(r),tonumber(g),tonumber(b),255);colors[#colors+1]=v;allowed[v]=true end end
local function c(hex)local n=tonumber(hex,16);local v=pc.rgba((n>>16)&255,(n>>8)&255,n&255,255);assert(allowed[v],hex);return v end
local s=Sprite(160,144,ColorMode.RGB);local water=s.layers[1];water.name='01 / reflejo y ondas'
local body=s:newLayer();body.name='02 / inflable escalonado / volumen'
local detail=s:newLayer();detail.name='03 / cara / ala / costuras / valvula'
local im;local dy=0
local function px(x,y,col)x=math.floor(x);y=math.floor(y+dy);if x>=0 and x<160 and y>=0 and y<144 then im:drawPixel(x,y,c(col))end end
local function rect(x,y,w,h,col)for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,col)end end end
local function line(x,y,xx,yy,col,t)local n=math.max(math.abs(xx-x),math.abs(yy-y));for j=0,n do rect(math.floor(x+(xx-x)*j/math.max(n,1)+.5),math.floor(y+(yy-y)*j/math.max(n,1)+.5),t or 1,t or 1,col)end end
local function poly(q,col)local lo,hi=999,-999;for _,v in ipairs(q)do lo=math.min(lo,v[2]);hi=math.max(hi,v[2])end;for y=lo,hi do local hits={};for j=1,#q do local a,b=q[j],q[j%#q+1];if (a[2]<=y and b[2]>y)or(b[2]<=y and a[2]>y)then hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])end end;table.sort(hits);for j=1,#hits-1,2 do rect(math.ceil(hits[j]),y,math.floor(hits[j+1])-math.ceil(hits[j])+1,1,col)end end end
local ink='493e36';local shade='d8943b';local mid='efbf4b';local gold='f8d864';local light='ffe99b';local cream='fff5cb';local orange='e78038'
for f=1,8 do
 if f>1 then s:newEmptyFrame()end
 im=Image(160,144);dy=0
 poly({{24,121},{38,116},{119,116},{139,122},{143,128},{129,135},{44,137},{21,130}},'307ba7')
 local drift=({0,1,2,1,0,-1,-2,-1})[f]
 line(18,131+drift,31,134+drift,'b8edff');line(40,139,67,139,'6ac7f2');line(124,136-drift,145,130-drift,'b8edff')
 s:newCel(water,f,im,Point(0,0))
 im=Image(160,144);dy=({0,0,1,1,0,0,-1,-1})[f]
 -- Broad breast, short neck and a compact head: intentionally unlike the old tall tube.
 poly({{14,66},{24,74},{35,82},{52,78},{69,79},{77,74},{79,65},{74,58},{72,43},{77,31},{84,27},{82,18},{88,20},{91,12},{98,21},{110,22},{121,29},{127,40},{128,58},{122,70},{116,75},{123,81},{132,91},{136,102},{132,115},{121,124},{102,130},{60,132},{37,127},{24,117},{19,104},{21,92},{15,81}},ink)
 poly({{19,74},{35,89},{53,83},{71,84},{82,77},{84,63},{78,56},{77,44},{82,34},{91,30},{88,24},{95,26},{96,20},{106,27},{117,33},{122,43},{123,57},{117,66},{108,74},{118,84},{127,95},{130,104},{125,114},{115,120},{99,125},{61,127},{40,122},{29,113},{25,104},{27,93},{20,82}},shade)
 poly({{30,92},{49,87},{71,88},{87,79},{89,64},{83,57},{82,44},{88,36},{102,31},{115,37},{118,46},{118,57},{110,64},{102,73},{112,86},{121,95},{123,105},{116,114},{98,120},{62,122},{44,117},{34,110},{29,102}},mid)
 poly({{37,92},{55,89},{73,91},{92,80},{94,65},{88,58},{87,45},{93,38},{105,35},{114,40},{114,53},{105,61},{98,72},{105,84},{114,95},{113,105},{102,113},{64,116},{47,111},{39,103}},gold)
 -- Flat highlight facets read as inflated vinyl without smooth gradients.
 poly({{87,42},{94,35},{105,32},{115,38},{117,44},{112,45},{107,39},{98,39},{93,45},{91,53},{87,52}},light)
 rect(94,33,10,3,cream);rect(84,46,3,9,light)
 poly({{100,78},{106,84},{117,94},{119,102},{115,104},{112,96},{102,88},{97,83}},light)
 poly({{35,94},{44,90},{51,91},{47,94},{38,98}},light)
 -- Two pointed tail panels.
 poly({{20,77},{37,92},{31,100},{25,91}},gold);line(23,81,30,89,light,2)
 s:newCel(body,f,im,Point(0,0))
 im=Image(160,144)
 -- Clearly defined wing panel with three stepped feather tips.
 poly({{40,89},{49,82},{68,83},{91,92},{95,98},{87,103},{86,109},{75,111},{72,116},{57,114},{44,106},{38,96}},shade)
 poly({{44,89},{52,86},{67,88},{87,95},{81,99},{81,104},{70,106},{68,111},{57,109},{46,101}},gold)
 poly({{47,90},{53,88},{66,90},{81,95},{73,96},{63,93},{52,94}},light)
 line(50,99,68,104,mid,2);line(53,104,63,108,shade)
 -- Cheek and expressive eye use the player's warm outline and cream.
 poly({{104,42},{114,42},{120,47},{120,58},{114,64},{103,61},{100,53}},light)
 rect(107,43,10,14,ink);rect(109,44,7,10,cream);rect(112,47,5,10,ink);rect(112,46,2,3,cream)
 rect(105,39,10,2,shade)
 -- A broad double-lipped bill, with nostrils and distinct upper/lower planes.
 poly({{115,57},{134,55},{143,58},{151,64},{151,72},{143,77},{127,78},{115,73},{110,66}},ink)
 poly({{117,60},{133,59},{141,61},{147,65},{146,69},{136,71},{121,69},{115,66}},'ffb24c')
 poly({{120,61},{134,60},{142,63},{139,65},{121,64}},light)
 poly({{118,70},{135,74},{145,71},{142,75},{128,75}},orange)
 line(119,69,135,71,'9a482f');rect(134,62,3,2,'9a482f')
 -- Welded skirt seam, small eyelets and inflation valve.
 line(43,121,60,125,shade);line(61,125,98,123,shade)
 for x=49,101,8 do rect(x,123-(x>88 and 2 or 0),3,1,light)end
 rect(29,107,5,4,ink);rect(30,107,3,2,light)
 rect(111,114,7,6,ink);rect(112,115,4,3,orange);rect(113,115,2,1,cream)
 s:newCel(detail,f,im,Point(0,0));s.frames[f].duration=.2
end
local pal=Palette(#colors);for i,v in ipairs(colors)do pal:setColor(i-1,Color(v))end;s:setPalette(pal)
s:saveAs(out..'pato_gigante.aseprite');app.activeSprite=s
app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..'pato_gigante.png',dataFilename=out..'pato_gigante.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true}
local image=Image(160,144);image:drawSprite(s,1);image:saveAs(base..'captures/pato_central_nuevo.png')
local bad=0;for f=1,8 do local a=Image(160,144);a:drawSprite(s,f);for px in a:pixels()do if pc.rgbaA(px())>0 and not allowed[px()]then bad=bad+1 end end end
assert(bad==0);s:close();print('CENTRAL_DUCK_REDRAW_OK: 160x144 / 8 frames / 3 layers / existing palette')
