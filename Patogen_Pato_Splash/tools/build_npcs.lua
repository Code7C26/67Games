local base=app.params['base'];local pc=app.pixelColor
local function hex(s)local v=tonumber(s,16);return pc.rgba((v>>16)&255,(v>>8)&255,v&255,255)end
local tops={{'b84f56','813d50','8f5260','bf6165'},{'96b96b','51846e','65907a','a2bf78'},{'a875bc','75537f','846589','b183bf'}}
local trousers={{'4d5d73','7b8898'},{'644f61','98756f'},{'456f93','6aafb2'}}
local shoes={{'77634d','bc995c'},{'99969c','d9d5c9'},{'797989','3b3b4c'}}
local dirs={'abajo','arriba','derecha','izquierda'};local tags={'Abajo','Arriba','Derecha','Izquierda'}
local counters={frames=0,head_changed=0,alpha_changed=0}
for role=1,3 do for n=1,3 do
 local name=({'banador','salvavidas','staff'})[role]..'_'..n
 local s=Sprite(32,32,ColorMode.RGB);local orig=s.layers[1];orig.name='Original Patogen / conservado';local clothing=s:newLayer();clothing.name=({'Piel y banador / sandalias','Uniforme salvavidas / cruz / silbato','Staff / polo / credencial'})[role]
 local index=0
 for d,dir in ipairs(dirs)do
  local source=Image{fromFile=base..'demo/references/NPC '..n..' '..dir..'.png'};local count=(source.width//32)*(source.height//32)
  for k=0,count-1 do
   index=index+1;if index>1 then s:newEmptyFrame()end
   local img=Image(source,Rectangle(k%(source.width//32)*32,k//(source.width//32)*32,32,32));local edit=Image(32,32);local result=Image(img)
   s:newCel(orig,index,img,Point(0,0));local shirt={};for j,c in ipairs(tops[n])do shirt[hex(c)]=j end
   local miny,maxy,minx,maxx=32,0,32,0
   for y=0,31 do for x=0,31 do if shirt[img:getPixel(x,y)] then miny=math.min(miny,y);maxy=math.max(maxy,y);minx=math.min(minx,x);maxx=math.max(maxx,x)end end end
   local skin={'e8ba87','b47e5b','cb976b','f4cd98'}
   local uniforms=role==2 and {'ee7664','ac494b','cb5b55','ffad87'} or {'f0cf71','b8934e','cfad5c','ffe4a0'}
   local function put(x,y,c) if x<0 or x>31 or y<miny or y>31 then return end;local p=img:getPixel(x,y);if pc.rgbaA(p)==0 then return end;local q=type(c)=='string' and hex(c) or c;edit:drawPixel(x,y,q);result:drawPixel(x,y,q)end
   for y=miny,31 do for x=0,31 do local p=img:getPixel(x,y);local si=shirt[p]
    if si then
     if role==1 then
      -- Bare torso for 1/3, a contrasting one-piece swimsuit for 2.
      if n==2 and x>minx+3 and x<maxx-2 then put(x,y,({'d97665','9f494e','bd5c57','edaa86'})[si])else put(x,y,skin[si])end
     else put(x,y,uniforms[si])end
    elseif p==hex(trousers[n][1]) or p==hex(trousers[n][2]) then
     local hi=p==hex(trousers[n][2])
     if role==1 and y>maxy+2 then put(x,y,hi and skin[1] or skin[2])
     else local shorts=role==1 and (n==3 and {'4e8fa6','83c6d4'} or {'3b687d','6799ad'}) or (role==2 and {'a8474a','e97865'} or {'3b596d','6f8b99'});put(x,y,shorts[hi and 2 or 1])end
    elseif role==1 and (p==hex(shoes[n][1]) or p==hex(shoes[n][2]))then put(x,y,p==hex(shoes[n][2]) and skin[1] or '3c6278')end
   end end
   local cx=math.floor((minx+maxx)/2)
   if role==2 then
    if d<=2 then for yy=miny+2,miny+6 do put(cx,yy,'fff5dc');put(cx+1,yy,'fff5dc')end;for xx=cx-2,cx+3 do put(xx,miny+4,'fff5dc')end
    else put(cx,miny+3,'fff5dc');put(cx,miny+4,'fff5dc');put(cx-1,miny+4,'fff5dc');put(cx+1,miny+4,'fff5dc')end
    if d==1 then put(cx+4,miny+2,'405d70');put(cx+4,miny+3,'dce3d6')end
   elseif role==3 then
    if d==1 then for yy=miny+1,miny+5 do put(cx,yy,'426c80')end;put(cx,miny+5,'fff5dc');put(cx+1,miny+5,'fff5dc');put(cx,miny+6,'fff5dc');put(cx+1,miny+6,'fff5dc')
    elseif d==2 then for xx=cx-3,cx+3 do put(xx,miny+3,'416a7b')end
    else put(cx,miny+4,'fff5dc');put(cx,miny+5,'426c80')end
   elseif n~=2 and d==1 then put(cx,miny+6,'b47e5b')end
   for y=0,31 do for x=0,31 do local p,q=img:getPixel(x,y),result:getPixel(x,y);if y<miny and p~=q then counters.head_changed=counters.head_changed+1 end;if pc.rgbaA(p)~=pc.rgbaA(q)then counters.alpha_changed=counters.alpha_changed+1 end end end
   s:newCel(clothing,index,edit,Point(0,0));s.frames[index].duration=.2;counters.frames=counters.frames+1
  end
 end
 for d=1,4 do local t=s:newTag(({1,3,5,9})[d],({2,4,8,12})[d]);t.name=tags[d]end
 s:saveAs(base..'splash/assets/'..name..'.aseprite');app.activeSprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=base..'splash/assets/'..name..'.png',dataFilename=base..'splash/assets/'..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true}
 print('NPC '..name..' 12 frames / 4 directions');s:close()
end end
assert(counters.head_changed==0 and counters.alpha_changed==0)
local file=io.open(base..'tests/npc_preservation.json','w');file:write('{"frames":'..counters.frames..',"changed_head_pixels":0,"changed_alpha_pixels":0}');file:close()
print('NPC_PRESERVATION_OK '..counters.frames..' frames')
