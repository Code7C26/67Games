-- Independent outlet spray. Uses only colours already present in toboganes.aseprite.
local base=app.params['base'];assert(base)
local pc=app.pixelColor
local original=app.open(base..'splash/assets/toboganes.aseprite')
local allowed={}
for _,layer in ipairs(original.layers) do for _,cel in ipairs(layer.cels) do
 for pixel in cel.image:pixels() do local value=pixel();if pc.rgbaA(value)>0 then allowed[value]=true end end
end end
local function color(hex)
 local v=tonumber(hex,16);local candidate=pc.rgba((v>>16)&255,(v>>8)&255,v&255,255)
 assert(allowed[candidate],'Colour not in current slide palette: '..hex)
 return candidate
end
local dark=color('307ba7');local blue=color('7bc9e8');local light=color('b8edff');local foam=color('fff2d6')
original:close()
local sprite=Sprite(48,56,ColorMode.RGB)
local stream=sprite.layers[1];stream.name='Chorro desde la boca / caida'
local spray=sprite:newLayer();spray.name='Impacto localizado / espuma'
local function rect(image,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do if xx>=0 and yy>=0 and xx<48 and yy<56 then image:drawPixel(xx,yy,c)end end end
end
for f=1,8 do
 if f>1 then sprite:newEmptyFrame()end
 local img=Image(48,56,ColorMode.RGB)
 -- Origin: (24,0). First pixel touches the end of the existing water channel.
 for y=0,33 do
  local center=24+math.floor(y/12);local width=y<12 and 9 or 7
  if y<15 or (y+f*2)%10<7 then
   rect(img,center-width//2,y,width,1,dark)
   rect(img,center-width//2+1,y,width-2,1,blue)
   if (y-f*3)%11<6 then rect(img,center-1,y,2,1,light)end
  end
 end
 sprite:newCel(stream,f,img,Point(0,0))
 local impact=Image(48,56,ColorMode.RGB)
 local t=(f-1)%4;local spread=9+t*3
 rect(impact,26-spread,36+t,spread*2,2,blue)
 rect(impact,26-spread+3,35+t,spread*2-6,2,light)
 for j=0,4 do local x=13+(j*7+f*2)%28;local y=28+(j*5+f*3)%15
  rect(impact,x,y,2,3,j%2==0 and light or foam)
 end
 rect(impact,16+t,42,8,1,light);rect(impact,30-t,43,6,1,blue)
 sprite:newCel(spray,f,impact,Point(0,0));sprite.frames[f].duration=.10
end
local tag=sprite:newTag(1,8);tag.name='Salida'
sprite:saveAs(base..'splash/assets/salida_tobogan.aseprite');app.activeSprite=sprite
app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=base..'splash/assets/salida_tobogan.png',dataFilename=base..'splash/assets/salida_tobogan.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listTags=true,listLayers=true}
print('OUTLET_WATER_OK: 48x56 / 8 frames / unchanged palette / origin 24,0')
sprite:close()
