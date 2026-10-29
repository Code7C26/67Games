-- New, editable proposal assets. Run with PATOGEN_ROOT via Aseprite MCP.
local root=assert(PATOGEN_ROOT).."lab/expanded/assets/"
app.fs.makeAllDirectories(root)
local pc=app.pixelColor
local function C(s)
  s=s:gsub("#","")
  return pc.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),255)
end
local P={ink=C("142b3a"),shadow=C("304957"),steel=C("6c8e9a"),rim=C("9ebcc4"),white=C("dce8e7"),light=C("f2f6ec"),glass=C("193d4c"),cyan=C("74e0df"),green=C("a5d68c"),amber=C("dcb36d"),red=C("c87783"),blue=C("7bafc8")}
local function pixel(im,x,y,c)
  if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,c) end
end
local function rect(im,x,y,w,h,c)
  for yy=y,y+h-1 do for xx=x,x+w-1 do pixel(im,xx,yy,c) end end
end
local function box(im,x,y,w,h,c)
  rect(im,x,y,w,h,P.ink)
  rect(im,x+1,y+1,w-2,h-2,c)
  rect(im,x+1,y+1,w-2,1,P.light)
  rect(im,x+1,y+h-2,w-2,1,P.steel)
end
local chars={['0']={7,5,5,5,7},['1']={2,6,2,2,7},['2']={7,1,7,4,7},['3']={7,1,7,1,7},['7']={7,1,2,2,2},['C']={7,4,4,4,7},['O']={7,5,5,5,7},['A']={2,5,7,5,5},['V']={5,5,5,5,2},['.']={0,0,0,0,2}}
local function text(im,str,x,y,color)
  for i=1,#str do
    local glyph=chars[str:sub(i,i)]
    if glyph then for yy=1,5 do for xx=0,2 do if math.floor(glyph[yy]/(2^(2-xx)))%2==1 then pixel(im,x+(i-1)*4+xx,y+yy-1,color) end end end end
  end
end
local function bottle(im,x,y,color,wide)
  local w=wide and 9 or 6
  rect(im,x+2,y, w-4,2,P.ink)
  rect(im,x+1,y+2,w-2,2,P.rim)
  rect(im,x,y+4,w,9,P.ink)
  rect(im,x+1,y+4,w-2,8,color)
  rect(im,x+1,y+4,1,7,P.light)
  rect(im,x+2,y+7,w-4,3,P.white)
end
local function dish(im,x,y,color)
  rect(im,x+1,y,10,1,P.rim)
  rect(im,x,y+1,12,3,P.shadow)
  rect(im,x+1,y+1,10,2,color)
  rect(im,x+2,y+1,7,1,P.light)
  rect(im,x+1,y+4,10,1,P.steel)
end
local function save(id,frames,w,h)
  local source=Sprite(w,h,ColorMode.RGB)
  source.layers[1].name="Metal, vidrio y material de laboratorio"
  local sheet=Image(w*#frames,h,ColorMode.RGB)
  for i,im in ipairs(frames) do
    if i>1 then source:newEmptyFrame() end
    source:newCel(source.layers[1],source.frames[i],im,Point(0,0))
    source.frames[i].duration=0.18
    sheet:drawImage(im,Point((i-1)*w,0))
  end
  source:saveAs(root..id..".aseprite")
  local export=Sprite(sheet.width,sheet.height,ColorMode.RGB)
  export:newCel(export.layers[1],export.frames[1],sheet,Point(0,0))
  export:saveAs(root..id..".png")
  export:close();source:close()
end
local incubation={}
for frame=1,8 do
  local im=Image(96,112,ColorMode.RGB)
  -- Stainless chamber: insulated body, black gasket and thick glass door.
  box(im,4,5,88,102,P.rim)
  rect(im,8,9,80,93,P.white)
  rect(im,8,9,80,3,P.light)
  rect(im,8,99,80,4,P.steel)
  rect(im,10,1,76,5,P.shadow)
  for x=14,82,5 do rect(im,x,2,2,2,P.rim) end
  box(im,26,16,59,82,P.shadow)
  rect(im,29,20,52,74,P.glass)
  rect(im,31,22,48,69,C("244d59"))
  rect(im,31,22,2,69,C("5b8b94"))
  rect(im,77,22,2,69,C("112f3e"))
  rect(im,31,23,1,67,C("ddd7fa"))
  rect(im,32,22,45,1,C("e8e4ff"))
  for row=0,3 do
    local y=35+row*17
    rect(im,32,y+7,45,3,P.ink)
    rect(im,32,y+7,45,1,P.rim)
    rect(im,34,y+8,41,1,P.steel)
    dish(im,35,y+2,row%2==0 and P.red or P.blue)
    dish(im,53,y+2,row%2==0 and P.amber or P.blue)
    if row==0 or row==2 then
      rect(im,68,y-4,6,10,P.shadow)
      rect(im,69,y-3,4,8,P.amber)
      rect(im,69,y-5,4,2,P.rim)
      rect(im,69,y-2,1,5,P.light)
    end
  end
  -- A narrow reflection in the glass, fixed under reduced motion.
  for y=24,90 do
    local x=70-math.floor((y-24)*0.43)
    if x>33 then pixel(im,x,y,C("6d969f")); pixel(im,x+1,y,C("567f8d")) end
  end
  rect(im,11,17,12,37,P.shadow)
  rect(im,12,19,10,13,P.ink)
  text(im,"37",13,21,C("e8e4ff"))
  rect(im,13,28,7,1,C("b7afec"))
  rect(im,13,38,3,3,P.light)
  rect(im,18,38,3,3,frame%4==0 and P.shadow or C("b7afec"))
  for y=45,68,6 do rect(im,13,y,7,2,P.steel) end
  text(im,"CO2",10,77,P.shadow)
  text(im,"AV07",10,90,P.shadow)
  -- Hinges and a vertical pull handle, matching the photographic reference.
  box(im,85,23,5,9,P.steel)
  box(im,85,80,5,9,P.steel)
  rect(im,83,44,5,27,P.ink)
  rect(im,84,45,3,25,P.rim)
  rect(im,84,45,1,24,P.light)
  rect(im,12,107,12,4,P.ink); rect(im,73,107,12,4,P.ink)
  incubation[#incubation+1]=im
end
save("incubator",incubation,96,112)

for _,sink in ipairs({false,true}) do
  local h=sink and 88 or 80
  local im=Image(192,h,ColorMode.RGB)
  local top=sink and 34 or 26
  -- Full-width black worktop, pale storage modules and recessed toe kick.
  rect(im,4,top+4,184,h-top-8,P.ink)
  rect(im,7,top+9,178,h-top-16,P.white)
  rect(im,7,h-10,178,5,P.shadow)
  rect(im,4,top,184,9,P.ink)
  rect(im,5,top,182,2,P.steel)
  rect(im,8,top+2,176,3,C("334750"))
  rect(im,8,top+7,176,1,P.light)
  for col=0,2 do
    local x=8+col*59
    box(im,x,top+11,57,h-top-23,P.rim)
    rect(im,x+2,top+13,53,h-top-27,P.white)
    if col==0 then
      rect(im,x+3,top+24,50,1,P.steel)
      rect(im,x+3,top+36,50,1,P.steel)
    else rect(im,x+28,top+13,1,h-top-27,P.steel) end
    rect(im,x+10,top+16,14,2,P.shadow)
    rect(im,x+35,top+16,14,2,P.shadow)
  end
  if sink then
    -- Recessed stainless basin and a curved tap drawn with crisp pixels.
    box(im,57,top+1,66,7,P.rim)
    rect(im,62,top+3,56,3,P.shadow)
    rect(im,85,top-15,5,19,P.steel)
    rect(im,85,top-18,21,4,P.rim)
    rect(im,103,top-15,4,7,P.rim)
    rect(im,84,top-15,1,17,P.light)
    rect(im,74,top-2,5,4,P.green)
    rect(im,95,top-2,5,4,P.green)
    bottle(im,146,top-13,P.blue,true)
    rect(im,159,top-7,17,8,P.cyan)
    rect(im,161,top-9,13,2,P.light)
  else
    -- Shelf posts, reagent boxes, tube rack, flasks and pipette stand.
    rect(im,9,4,3,top,P.steel); rect(im,180,4,3,top,P.steel)
    rect(im,7,10,178,4,P.ink); rect(im,7,10,178,1,P.rim)
    for i=0,4 do
      local colors={P.blue,P.red,P.amber,P.white,P.green}
      box(im,17+i*30,2,24,8,colors[i+1])
      rect(im,21+i*30,5,11,2,P.light)
    end
    bottle(im,20,top-13,P.amber,true)
    bottle(im,36,top-13,P.blue,false)
    rect(im,64,top-5,31,5,P.steel)
    for x=67,91,6 do rect(im,x,top-13,3,10,P.rim);rect(im,x,top-13,3,2,P.red);rect(im,x,top-7,3,3,P.green) end
    rect(im,121,top-16,3,16,P.rim)
    rect(im,111,top-17,23,2,P.steel)
    for x=113,129,8 do rect(im,x,top-14,2,11,P.white); rect(im,x,top-14,2,3,P.blue) end
    box(im,149,top-9,22,9,P.blue)
    rect(im,153,top-8,13,2,P.light)
  end
  save(sink and "sink_bench" or "wet_bench",{im},192,h)
end

local shelf=Image(128,112,ColorMode.RGB)
rect(shelf,5,5,118,102,P.ink)
rect(shelf,9,8,110,96,C("647f88"))
for x=7,119,112 do rect(shelf,x,5,3,102,P.rim);rect(shelf,x,5,1,102,P.light) end
for row=0,2 do
  local y=32+row*32
  rect(shelf,10,y,108,6,P.ink)
  rect(shelf,10,y,108,2,P.white)
  for col=0,3 do
    local x=16+col*25
    if row==1 then bottle(shelf,x,y-16,col%2==0 and P.amber or P.blue,true)
    else
      box(shelf,x,y-18,20,18,col%2==0 and P.white or P.rim)
      rect(shelf,x+2,y-17,16,3,row==0 and P.red or P.blue)
      rect(shelf,x+5,y-10,11,4,P.light)
      rect(shelf,x+7,y-8,6,1,P.shadow)
    end
  end
end
rect(shelf,10,107,10,4,P.ink);rect(shelf,108,107,10,4,P.ink)
save("supply_shelf",{shelf},128,112)
print("PROPOSAL_ASSETS incubator: 8 frames + 3 laboratory fixtures; editable Aseprite sources")
