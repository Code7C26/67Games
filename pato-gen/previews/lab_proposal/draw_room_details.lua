-- Aseprite MCP: run after draw_assets.lua. Only writes proposal variants.
local root=assert(PATOGEN_ROOT).."previews/lab_proposal/assets/"
local pc=app.pixelColor
local function c(hex)
 return pc.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
local ink=c("152e3b"); local dark=c("304956"); local steel=c("71939f")
local rim=c("adc9cd"); local white=c("e5ede8"); local bright=c("f4f5e8")
local cyan=c("79c8d1"); local uv=c("bdb5e8"); local amber=c("cfa66f")
local function rect(im,x,y,w,h,color)
 for yy=y,y+h-1 do for xx=x,x+w-1 do
  if xx>=0 and yy>=0 and xx<im.width and yy<im.height then im:drawPixel(xx,yy,color) end
 end end
end
local function box(im,x,y,w,h,color)
 rect(im,x,y,w,h,ink);rect(im,x+1,y+1,w-2,h-2,color)
 rect(im,x+1,y+1,w-2,1,bright);rect(im,x+1,y+h-2,w-2,1,steel)
end
local function disc(im,cx,cy,r,color)
 for y=-r,r do for x=-r,r do if x*x+y*y<=r*r then rect(im,cx+x,cy+y,1,1,color) end end end
end
local function bottle(im,x,y,color)
 rect(im,x+2,y,4,2,ink);rect(im,x+2,y+2,4,3,white)
 box(im,x,y+5,8,13,color);rect(im,x+2,y+10,4,4,white)
end
local function load_image(id)
 local s=app.open(root..id..".png")
 local image=Image(s.width,s.height,ColorMode.RGB);image:drawSprite(s,1)
 s:close();return image
end
local function save(id,image)
 local s=Sprite(image.width,image.height,ColorMode.RGB)
 s.layers[1].name="Detalle de laboratorio"
 s:newCel(s.layers[1],s.frames[1],image,Point(0,0))
 s:saveAs(root..id..".aseprite");s:saveAs(root..id..".png");s:close()
end

local sink=load_image("sink_bench")
bottle(sink,20,15,cyan);bottle(sink,32,15,uv)
box(sink,44,18,18,14,white);rect(sink,47,21,12,6,rim)
rect(sink,49,20,8,8,bright);rect(sink,49,28,8,3,white)
rect(sink,127,30,13,2,steel);rect(sink,127,29,13,1,rim)
for x=130,138,4 do rect(sink,x,23,1,8,white) end
save("sink_bench_detailed",sink)

local prep=load_image("wet_bench")
box(prep,97,12,35,17,white)
rect(prep,102,10,24,9,ink);rect(prep,105,10,18,3,rim)
rect(prep,104,13,20,5,dark);rect(prep,109,14,10,2,cyan)
rect(prep,100,22,12,3,ink);rect(prep,102,23,8,1,cyan)
disc(prep,125,23,2,steel);rect(prep,124,22,1,2,white)
box(prep,43,18,15,9,rim);rect(prep,46,20,9,3,uv)
for x=67,91,6 do rect(prep,x,13,3,2,uv) end
save("prep_bench",prep)

local reagent=load_image("wet_bench")
box(reagent,98,9,38,20,white)
rect(reagent,103,12,19,9,ink);rect(reagent,105,14,15,5,cyan)
for x=107,117,4 do rect(reagent,x,15,1,3,white) end
disc(reagent,129,15,2,steel);disc(reagent,129,23,2,steel)
for x=67,91,6 do rect(reagent,x,13,3,2,amber) end
bottle(reagent,143,9,uv);bottle(reagent,157,9,amber)
save("reagent_bench",reagent)

local utility=Image(64,40,ColorMode.RGB)
box(utility,2,2,60,36,dark)
box(utility,6,6,22,25,white);rect(utility,10,10,14,5,steel)
rect(utility,11,14,12,15,bright);rect(utility,12,29,10,4,white)
box(utility,33,7,13,25,rim);rect(utility,35,11,9,14,white)
rect(utility,36,14,7,8,cyan);rect(utility,38,29,4,4,ink)
rect(utility,50,8,7,4,cyan);rect(utility,50,16,7,2,rim)
rect(utility,50,21,7,2,rim);rect(utility,50,28,7,2,amber)
save("hygiene_station",utility)

local services=Image(96,40,ColorMode.RGB)
box(services,1,1,94,38,dark)
for x=13,81,34 do
 rect(services,x,4,5,30,ink);rect(services,x+1,4,3,29,rim)
 disc(services,x+2,15,9,ink);disc(services,x+2,15,7,steel)
 disc(services,x+2,15,5,white);rect(services,x+2,11,1,6,ink)
 rect(services,x+2,15,4,1,ink);rect(services,x-3,29,11,3,cyan)
 rect(services,x+1,26,3,9,steel)
end
rect(services,20,32,56,3,steel);rect(services,20,32,56,1,rim)
save("wall_services",services)

local board=Image(64,40,ColorMode.RGB)
box(board,2,1,60,38,steel)
for i=0,2 do
 box(board,7+i*17,6,14,25,white)
 rect(board,9+i*17,7,10,3,i==1 and uv or cyan)
 for y=14,24,4 do rect(board,10+i*17,y,8,1,steel) end
 rect(board,12+i*17,28,4,3,amber)
end
rect(board,8,34,48,2,dark)
save("sample_board",board)

local drain=Image(24,16,ColorMode.RGB)
rect(drain,1,3,22,12,ink);rect(drain,2,2,20,11,steel)
rect(drain,3,3,18,9,dark);rect(drain,3,3,18,1,rim)
for x=5,19,3 do rect(drain,x,5,1,6,ink);rect(drain,x+1,5,1,6,steel) end
rect(drain,4,11,16,1,ink)
save("floor_drain",drain)

local cable=Image(96,16,ColorMode.RGB)
rect(cable,1,3,94,11,ink);rect(cable,2,2,92,10,steel)
rect(cable,3,3,90,8,dark);rect(cable,3,4,90,1,cyan)
rect(cable,3,8,90,1,amber)
for x=8,88,16 do rect(cable,x,2,3,11,ink);rect(cable,x+1,2,1,9,rim) end
save("cable_tray",cable)

local transport=Image(48,48,ColorMode.RGB)
rect(transport,5,42,8,5,ink);rect(transport,35,42,8,5,ink)
box(transport,3,10,42,33,rim);box(transport,5,9,38,8,white)
rect(transport,17,4,14,7,ink);rect(transport,19,6,10,4,steel)
rect(transport,7,19,34,18,white);rect(transport,7,19,34,3,cyan)
rect(transport,7,26,5,7,steel);rect(transport,36,26,5,7,steel)
box(transport,16,27,16,9,white)
for y=29,33,2 do for x=18,29,2 do
 if (x+y)%3~=0 then rect(transport,x,y,1,1,ink) end
end end
save("sealed_transport",transport)
print("PROPOSAL_ROOM_DETAILS 9 new editable assets, original footprints preserved")
