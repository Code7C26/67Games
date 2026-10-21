local root=[[C:/Users/feliv/.codex/.chatgpt-projects/g-p-6ac7d270eca08191830907d9c9abeba3/output/patogen-infectados-oct21]]
local dirs={'abajo','arriba','derecha','izquierda'}
local types={'atletico','area','exponencial_endgame'}
local results={types={},total_frames=0,png_mismatches=0,edge_pixels=0}
local pc=app.pixelColor
local function flat(s,f) local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,f);return im end
local function sig(im) local a={} for y=0,31 do for x=0,31 do a[#a+1]=string.pack('<I4',im:getPixel(x,y)) end end;return table.concat(a) end
local function diff(a,b) local n=0 for y=0,31 do for x=0,31 do if a:getPixel(x,y)~=b:getPixel(x,y) then n=n+1 end end end;return n end
local function components(im,ymax)
 local seen={};local count=0
 local function live(x,y) return x>=0 and x<32 and y>=0 and y<=ymax and pc.rgbaA(im:getPixel(x,y))>0 end
 for y=0,ymax do for x=0,31 do local k=y*32+x
 if live(x,y) and not seen[k] then
 count=count+1;local queue={{x,y}};seen[k]=true;local j=1
 while j<=#queue do local a=queue[j];j=j+1
 for dy=-1,1 do for dx=-1,1 do local xx,yy=a[1]+dx,a[2]+dy;local kk=yy*32+xx
 if live(xx,yy) and not seen[kk] then seen[kk]=true;queue[#queue+1]={xx,yy} end end end end
 end end end
 return count
end
for _,kind in ipairs(types) do
 local s=app.open(root..'/npcs/'..kind..'/NPC_2.aseprite')
 local t={width=s.width,height=s.height,frames=#s.frames,layers=#s.layers,directions={},duration_ms=0,head_components={}}
 local all=Image(512,128,ColorMode.RGB);local palette={}
 for d,dir in ipairs(dirs) do
 local png=app.open(root..'/npcs/'..kind..'/NPC 2 '..dir..'.png');local sheet=flat(png,1);png:close()
 local frames={};local unique={};local edges=0;local heights={};local widths={};local particleMass={}
 for f=0,15 do
 local idx=(d-1)*16+f+1;local im=flat(s,idx);frames[f+1]=im;unique[sig(im)]=true
 t.duration_ms=t.duration_ms+math.floor(s.frames[idx].duration*1000+.5)
 local minx,maxx,maxy=99,-1,-1;local mismatches=0
 for y=0,31 do for x=0,31 do local v=im:getPixel(x,y);local alpha=pc.rgbaA(v)
 local e=sheet:getPixel((f%4)*32+x,math.floor(f/4)*32+y)
 if v~=e then mismatches=mismatches+1 end
 if alpha>0 then
 palette[pc.rgbaR(v)..','..pc.rgbaG(v)..','..pc.rgbaB(v)]=true
 minx=math.min(x,minx);maxx=math.max(x,maxx);maxy=math.max(y,maxy)
 if x==0 or y==0 or x==31 or y==31 then edges=edges+1 end
 end end end
 results.png_mismatches=results.png_mismatches+mismatches
 heights[#heights+1]=maxy
 if kind=='atletico' then
 local cel=s.layers[2]:cel(idx);local a,b=99,-1
 for y=14,23 do for x=0,31 do if pc.rgbaA(cel.image:getPixel(x,y))>0 then a=math.min(a,x);b=math.max(b,x) end end end
 widths[#widths+1]=b-a+1
 end
 if kind=='exponencial_endgame' then
 local n=components(im,14);t.head_components[#t.head_components+1]=n
 end
 if kind=='area' then
 local cel=s.layers[4]:cel(idx);local mass=0
 for y=0,31 do for x=0,31 do mass=mass+pc.rgbaA(cel.image:getPixel(x,y)) end end
 particleMass[#particleMass+1]=mass
 end
 all:drawImage(im,Point(f*32,(d-1)*32))
 end
 local ud=0;for _ in pairs(unique) do ud=ud+1 end
 local deltas={};for f=1,16 do deltas[f]=diff(frames[f],frames[f%16+1]) end
 t.directions[dir]={unique_frames=ud,edge_pixels=edges,feet_y=heights,changed_pixels_to_next=deltas,muscle_width=widths,particle_alpha_mass=particleMass}
 results.edge_pixels=results.edge_pixels+edges
 results.total_frames=results.total_frames+16
 end
 local pal={};for v in pairs(palette) do pal[#pal+1]=v end;table.sort(pal)
 local g=io.open(root..'/npcs/'..kind..'/paleta.gpl','w')
 g:write('GIMP Palette\nName: Patogen '..kind..'\nColumns: 8\n#\n')
 for i,v in ipairs(pal) do local r,gg,b=v:match('(%d+),(%d+),(%d+)');g:write(r..' '..gg..' '..b..' color_'..i..'\n') end;g:close()
 t.colors=#pal;results.types[kind]=t;s:close()
end
local f=io.open(root..'/validacion_visual_y_exportacion.json','w');f:write(json.encode(results));f:close();print(json.encode(results))

