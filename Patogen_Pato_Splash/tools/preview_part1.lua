local base=app.params['base'];local sprite=Sprite(336,110,ColorMode.RGB)
sprite.layers[1].name='Capturas reales Godot / salidas independientes'
for f=1,8 do
 if f>1 then sprite:newEmptyFrame()end
 local image=Image{fromFile=base..'captures/parte1_salida_'..string.format('%02d',f-1)..'.png'}
 sprite:newCel(sprite.layers[1],f,image,Point(0,0));sprite.frames[f].duration=.1
end
sprite:resize(672,220)
sprite:saveCopyAs(base..'captures/parte1_toboganes.gif')
sprite:close();print('PART1_PREVIEW_OK')
