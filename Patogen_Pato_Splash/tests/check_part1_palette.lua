local base=app.params['base'];local backup=app.params['backup'];local pc=app.pixelColor
local function pixels(path)
 local s=app.open(path);local result={}
 for _,layer in ipairs(s.layers)do for _,cel in ipairs(layer.cels)do for p in cel.image:pixels()do local v=p();if pc.rgbaA(v)>0 then result[v]=true end end end end
 s:close();return result
end
local original=pixels(backup..'splash/assets/toboganes.aseprite')
local slide=pixels(base..'splash/assets/toboganes.aseprite')
local water=pixels(base..'splash/assets/salida_tobogan.aseprite')
local new_colors=0
for v in pairs(slide)do if not original[v] then new_colors=new_colors+1 end end
for v in pairs(water)do if not original[v] then new_colors=new_colors+1 end end
assert(new_colors==0,'New colours introduced')
local file=io.open(base..'tests/part1_palette.json','w');file:write('{"new_colours":0,"passed":true}');file:close()
print('PART1_PALETTE_OK: no new colours in slides or outlet water')
