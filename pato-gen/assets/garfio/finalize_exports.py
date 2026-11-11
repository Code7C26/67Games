"""Package Aseprite's exported pixels without changing or redrawing them."""
import json
from pathlib import Path
from PIL import Image

HERE=Path(__file__).resolve().parent
data=json.loads((HERE/'poses.json').read_text(encoding='utf-8'))
sheet=Image.open(HERE/'garfio_sheet.png').convert('RGBA')
assert sheet.size == (32*len(data['frames']),32), sheet.size
for n,rows in enumerate(data['frames']):
    frame=sheet.crop((32*n,0,32*(n+1),32))
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            px=frame.getpixel((x,y))
            expected=tuple(bytes.fromhex(data['legend'][ch][1:]))
            if len(expected)==3: expected+= (255,)
            assert px==expected, (n,x,y,px,expected)
for a in data['animations']:
    if a['name'].startswith('caminar_'):
        sheet.crop((a['start']*32,0,(a['start']+a['count'])*32,32)).save(HERE/('garfio_'+a['name'][8:]+'.png'))
sheet.crop((0,0,32,32)).save(HERE/'retrato.png')

parts=['[gd_resource type="SpriteFrames" load_steps=34 format=3]', '', '[ext_resource type="Texture2D" path="res://assets/garfio/garfio_sheet.png" id="1"]','']
for i in range(32):
    parts += ['[sub_resource type="AtlasTexture" id="cuadro_%d"]'%(i+1),'atlas = ExtResource("1")','region = Rect2(%d, 0, 32, 32)'%(i*32),'']
parts += ['[resource]','animations = [']
anims=[]
for a in data['animations']:
    frames=', '.join('{"duration": 1.0, "texture": SubResource("cuadro_%d")}'%(a['start']+j+1) for j in range(a['count']))
    anims.append('{"frames": ['+frames+'], "loop": '+str(a['loop']).lower()+', "name": &"'+a['name']+'", "speed": '+str(a['speed'])+'}')
parts += [',\n'.join(anims),']','']
(HERE.parents[1]/'resources'/'animations'/'garfio.tres').write_text('\n'.join(parts),encoding='utf-8')
print('Verified 32 Aseprite frames; exported four 128x32 walk sheets, portrait and synchronized SpriteFrames.')
