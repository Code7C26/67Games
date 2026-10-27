local base=app.params['base'];local backup=app.params['backup'];local pc=app.pixelColor
local report=json.decode(io.open(base..'tests/part2_art.json'):read('*a'))
local function colour(hex)local v=tonumber(hex,16);return pc.rgba((v>>16)&255,(v>>8)&255,v&255,255)end
local allowed={};for _,hex in ipairs(report.master_hex)do allowed[colour(hex)]=true end
local before={}
for _,entry in ipairs(app.fs.listFiles(backup..'splash/assets/'))do if app.fs.fileExtension(entry)=='png'then local im=Image{fromFile=backup..'splash/assets/'..entry};for p in im:pixels()do if pc.rgbaA(p())>0 then before[p()]=true end end end end
for _,entry in ipairs(app.fs.listFiles(backup..'demo/references/'))do if app.fs.fileExtension(entry)=='png'then local im=Image{fromFile=backup..'demo/references/'..entry};for p in im:pixels()do if pc.rgbaA(p())>0 then before[p()]=true end end end end
local colours,missing,new=0,0,0;local sources=0
for _,entry in ipairs(app.fs.listFiles(base..'splash/assets/'))do if app.fs.fileExtension(entry)=='aseprite'then
 sources=sources+1;local stem=app.fs.fileTitle(entry);local im=Image{fromFile=base..'splash/assets/'..stem..'.png'}
 for p in im:pixels()do local v=p();if pc.rgbaA(v)>0 then colours=colours+1;if not allowed[v]then missing=missing+1 end;if not before[v]then new=new+1 end end end
end end
assert(missing==0 and new==0,'Palette changed unexpectedly')
local alpha_changes,head_colours=0,0
for _,role in ipairs({'banador','salvavidas','staff'})do for n=1,3 do
 local name=role..'_'..n..'.png';local old=Image{fromFile=backup..'splash/assets/'..name};local current=Image{fromFile=base..'splash/assets/'..name}
 for y=0,old.height-1 do for x=0,old.width-1 do local a,b=old:getPixel(x,y),current:getPixel(x,y);if pc.rgbaA(a)~=pc.rgbaA(b)then alpha_changes=alpha_changes+1 end;if y%32<16 and a~=b then head_colours=head_colours+1 end end end
end end
assert(alpha_changes==0)
local result={passed=true,source_sprites=sources,pixels_checked=colours,off_palette_pixels=missing,new_colour_pixels=new,shared_colours=#report.master_hex,npc_alpha_changes=alpha_changes,npc_head_colour_pixels_unified=head_colours}
local f=io.open(base..'tests/part2_palette_check.json','w');f:write(json.encode(result));f:close();print(json.encode(result))
