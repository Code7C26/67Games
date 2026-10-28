-- Run through Aseprite MCP with PATOGEN_ROOT pointing to the project folder.
-- Read-only originals: all exports are separate, dimension/alpha-identical PNGs.
local root = assert(PATOGEN_ROOT, "Set PATOGEN_ROOT before running")
local output = root.."visuals/lab_upgrade/props/"
app.fs.makeAllDirectories(output)
local pc = app.pixelColor
local function clamp(x) return math.max(0,math.min(255,math.floor(x+0.5))) end
local function rgba(r,g,b,a) return pc.rgba(clamp(r),clamp(g),clamp(b),a or 255) end
local function blend(a,b,t)
  return rgba(pc.rgbaR(a)*(1-t)+pc.rgbaR(b)*t,pc.rgbaG(a)*(1-t)+pc.rgbaG(b)*t,pc.rgbaB(a)*(1-t)+pc.rgbaB(b)*t,pc.rgbaA(a))
end
local specs={}
for _,path in ipairs(app.fs.listFiles(root.."lab/scenes/objetos/")) do
  if app.fs.fileExtension(path)=="tscn" then
    if not app.fs.isFile(path) then path=root.."lab/scenes/objetos/"..path end
    local f=io.open(path,"r")
    local text=f:read("*a"); f:close()
    local id=text:match('metadata/asset_id%s*=%s*"([^"]+)"')
    local w,h=text:match('metadata/size%s*=%s*Vector2%((%d+),%s*(%d+)%)')
    if id and w then specs[id]={tonumber(w),tonumber(h)} end
  end
end
-- The service-facing variants are polished along with the front views.
for _,path in ipairs(app.fs.listFiles(root.."visuals/lighting_coherence/lab_backviews/")) do
  if app.fs.fileExtension(path)=="png" then
    if not app.fs.isFile(path) then path=root.."visuals/lighting_coherence/lab_backviews/"..path end
    local id=app.fs.fileTitle(path)
    specs[id]={0,0,path}
  end
end
local count=0
for id,spec in pairs(specs) do
  local source=spec[3] or root.."lab/assets/"..id..".png"
  if app.fs.isFile(source) then
    local s=app.open(source)
    local original=Image(s.width,s.height,ColorMode.RGB)
    original:drawSprite(s,1)
    local image=Image(original)
    local fw=spec[1]>0 and spec[1] or s.width
    local fh=s.height
    local rear=id:match("_back$")~=nil
    local capsule=id:match("^capsula_")~=nil
    local screen=id=="muro_monitores" or id=="consola_control" or id=="mesa_secuenciador" or id=="consola_capsulas"
    local function opaque(x,y)
      if x<0 or x>=s.width or y<0 or y>=fh then return false end
      return pc.rgbaA(original:getPixel(x,y))>200
    end
    local function paint(x,y,color,amount)
      if opaque(x,y) then image:drawPixel(x,y,blend(image:getPixel(x,y),color,amount or 1)) end
    end
    -- Deeper navy recesses, cleaner cool alloys, richer glass and culture green.
    for y=0,fh-1 do for x=0,s.width-1 do
      local p=original:getPixel(x,y)
      if pc.rgbaA(p)>0 then
        local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
        local v=math.max(r,g,b)
        local q
        if g>r*1.35 and b>r*1.20 then
          q=rgba(r*0.82,g*1.07,b*1.16,pc.rgbaA(p))
        elseif g>r*1.08 and g>b*1.18 then
          q=rgba(r*0.91,g*1.07,b*0.94,pc.rgbaA(p))
        else
          local k=v<105 and 0.90 or 1.04
          q=rgba(r*k-3,g*k+1,b*k+6,pc.rgbaA(p))
        end
        -- Pixel bevel on the existing silhouette; never expands its alpha.
        if v>60 and v<220 and not opaque(x,y-1) then q=blend(q,rgba(189,228,236),0.48)
        elseif v>60 and not opaque(x,y+1) then q=blend(q,rgba(18,39,57),0.40) end
        image:drawPixel(x,y,q)
      end
    end end
    for frame=0,math.floor(s.width/fw)-1 do
      local ox=frame*fw
      -- Small inset service fasteners on metal, consistent across frames.
      if id~="planta" then
        for _,xx in ipairs({6,fw-7}) do
          for _,yy in ipairs({8,fh-9}) do
            local p=original:getPixel(ox+xx,yy)
            local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
            if pc.rgbaA(p)>240 and math.max(r,g,b)-math.min(r,g,b)<75 then
              paint(ox+xx,yy,rgba(26,49,65))
              paint(ox+xx+1,yy+1,rgba(173,215,226),0.8)
            end
          end
        end
      end
      if capsule then
        -- Glass thickness and paired cool rim strips; no animated sun glare.
        for y=34,fh-30 do
          paint(ox+21,y,rgba(162,250,246),0.65)
          paint(ox+22,y,rgba(104,223,229),0.40)
          paint(ox+fw-23,y,rgba(32,93,114),0.45)
        end
        for x=18,fw-19 do
          paint(ox+x,fh-27,rgba(12,43,64),0.50)
          if x<34 or x>fw-35 then paint(ox+x,fh-23,rgba(99,229,235),0.75) end
        end
        -- A small technical indicator, safely below the specimen.
        for x=0,5 do paint(ox+fw-29+x,fh-15,rgba(104,221,232),0.75) end
      elseif id=="biorreactor" then
        for y=36,82 do
          paint(ox+18,y,rgba(161,229,191),0.52)
          paint(ox+fw-20,y,rgba(28,69,64),0.45)
        end
        for x=28,67 do paint(ox+x,91,rgba(103,232,153),0.60) end
      elseif screen then
        -- Fine instrument grid plus status indicators inside the existing panel.
        for y=16,math.min(fh-24,46),8 do for x=16,fw-16 do
          local p=original:getPixel(ox+x,y)
          if pc.rgbaR(p)<65 and pc.rgbaG(p)<125 and pc.rgbaB(p)<140 then
            paint(ox+x,y,rgba(58,125,142),0.26)
          end
        end end
        for x=12,math.min(fw-12,54),7 do
          paint(ox+x,fh-15,rgba(90,224,211),0.8)
          paint(ox+x+1,fh-15,rgba(90,224,211),0.8)
        end
      elseif rear then
        -- Service views stay non-emissive: metal bevels and brass identifiers.
        for x=math.floor(fw*0.62),math.floor(fw*0.62)+8 do
          paint(ox+x,math.max(7,fh-13),rgba(185,147,79),0.70)
        end
      end
    end
    local result=Sprite(s.width,s.height,ColorMode.RGB)
    result:newCel(result.layers[1],result.frames[1],image,Point(0,0))
    result:saveAs(output..id..".png")
    result:close(); s:close()
    count=count+1
  end
end
print("LAB_POLISHED_ASSETS "..count)
