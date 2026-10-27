from pathlib import Path
import json, math, wave, random, struct, hashlib
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
assets={
 'pato_gigante':[160,144,8,.2], 'toboganes':[272,240,8,.14], 'torre_balde':[192,160,1,0],
 'balde':[112,96,1,0], 'sombrilla':[96,88,8,.22], 'reposera':[40,80,1,0],
 'palmera':[96,128,8,.22], 'kiosco':[192,160,8,.2], 'duchas':[128,96,8,.12],
 'casilleros':[128,80,1,0], 'silla_salvavidas':[64,104,1,0], 'flotador':[48,40,8,.2],
 'banderin':[48,96,8,.15], 'filtro':[64,72,8,.12], 'papelera':[32,40,1,0],
 'banco':[64,32,1,0], 'mesa':[64,48,1,0], 'escalera':[32,48,1,0], 'fuente_hongo':[128,128,8,.12], 'vestuarios':[416,144,12,.28]}
props=[]
def p(asset,x,y,solid=True,name=''):
 props.append(dict(asset=asset,x=x,y=y,solid=solid,name=name or f'{asset}_{len(props):02}'))
p('toboganes',232,160,True,'ToboganesDobles')
p('fuente_hongo',1488,377,False,'FuenteInfantil')
p('pato_gigante',868,491,False,'PatoGigante')
p('torre_balde',864,144,False,'TorreBalde')
p('balde',904,145,False,'Balde')
for a in [(427,468),(1424,410),(1614,468),(778,581),(1090,618)]:p('flotador',*a,False)
for a in [(472,360),(732,440),(1136,440),(1664,360)]:p('escalera',*a,False)
p('kiosco',1512,632,True,'KioscoHelados')
p('vestuarios',1360,144,True,'Vestuarios')
p('filtro',1712,468);p('filtro',160,468)
p('silla_salvavidas',554,442);p('silla_salvavidas',1302,442)
for x in [144,256,368]:
 p('sombrilla',x,680);p('reposera',x+10,774);p('reposera',x+55,774)
for x,y in [(1424,854),(1696,846)]:p('sombrilla',x,y);p('mesa',x+13,y+64)
for x,y in [(50,152),(620,140),(1210,140),(1780,152),(48,542),(1788,542),(560,800),(1250,800),(48,820),(1780,832)]:p('palmera',x,y,True)
for x,y in [(630,238),(1210,238),(830,812),(1040,812)]:p('banco',x,y)
for x,y in [(104,648),(1776,678),(1410,692),(484,780)]:p('papelera',x,y)
for x,y in [(686,818),(1174,818),(130,246),(1752,266)]:p('banderin',x,y,False)
pools=[dict(name='PiletaCentral',asset='pileta_central',rect=[704,448,512,256]),dict(name='PiletaToboganes',asset='pileta_lateral',rect=[208,368,320,176]),dict(name='PiletaInfantil',asset='pileta_lateral',rect=[1392,368,320,176]),dict(name='PiletaChapuzon',asset='pileta_balde',rect=[816,176,288,144])]
markers=[['InicioPato_A',592,744,'patogen_spawn'],['InicioPato_B',1328,744,'patogen_spawn']]
for name,x,y in [('Entrada',960,896),('PaseoSurOeste',736,776),('PaseoSurEste',1184,776),('Descanso',432,904),('Heladeria',1592,904),('Oeste',592,616),('Este',1328,616),('Toboganes',368,592),('Infantil',1552,592),('Vestuario',1576,328),('NorteOeste',704,336),('NorteEste',1216,336),('ChapuzonOeste',848,376),('ChapuzonCentro',960,376),('ChapuzonEste',1072,376),('EntradaOeste',192,600),('EntradaEste',1728,600)]:markers.append([name,x,y,'patogen_destination'])
layout=dict(assets=assets,props=props,pools=pools,markers=markers)
(ROOT/'tools/layout.json').write_text(json.dumps(layout,indent=2),encoding='utf8')
# Audio assets synthesized locally: quiet looping water, announcement chime and splash.
def wav(name,duration,fn):
 rate=22050
 with wave.open(str(ROOT/'splash/assets'/name),'wb') as f:
  f.setparams((1,2,rate,0,'NONE','not compressed'))
  f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate,i)))*32767)) for i in range(int(rate*duration))))
rng=random.Random(67);smooth=[0.0]
def water(t,i):
 smooth[0]=smooth[0]*.94+rng.uniform(-1,1)*.06
 env=min(1,t*4,(8-t)*4)
 return env*(smooth[0]*.28+math.sin(t*2*math.pi*180)*.006*(1+math.sin(t*2)))
wav('agua_ambiente.wav',8,water)
def chime(t,i):
 step=int(t/.3);local=t-step*.3
 hz=[523.25,659.25,783.99,1046.5][min(step,3)]
 return math.sin(t*2*math.pi*hz)*math.exp(-local*11)*.10*min(1,local*200)*(1 if t<1.2 else 0)
wav('aviso.wav',1.2,chime)
def splash(t,i):
 return (rng.uniform(-1,1)*.30+math.sin(t*2*math.pi*(82-t*12))*.13)*math.exp(-t*2.7)*min(1,t*35)*min(1,(2-t)*10)
wav('chapuzon.wav',2,splash)
# Contact sheets are previews; the deliverable artwork was generated in Aseprite.
font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',21)
small=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',16)
sheet=Image.new('RGB',(1536,960),'#142b3a');draw=ImageDraw.Draw(sheet)
draw.text((32,22),'PATOGEN / PATO SPLASH — NPCs',font=font,fill='#fff2d3')
for role,role_title in enumerate(['BANADORES','SALVAVIDAS','STAFF']):
 draw.text((32,76+role*286),role_title,font=font,fill='#f4cb6a')
 for n in range(1,4):
  name=['banador','salvavidas','staff'][role]+f'_{n}'
  image=Image.open(ROOT/'splash/assets'/f'{name}.png').convert('RGBA')
  x=32+(n-1)*500;y=112+role*286
  for d,idx in enumerate([0,2,4,8]):
   cell=image.crop((idx*32,0,(idx+1)*32,32)).resize((112,112),Image.Resampling.NEAREST)
   sheet.paste(cell,(x+d*116,y),cell)
  draw.text((x,y+127),f'{name} / 32 px / 12 cuadros',font=small,fill='#c4dce1')
  draw.text((x,y+154),'Abajo · Arriba · Derecha · Izquierda',font=small,fill='#87b1c5')
sheet.save(ROOT/'captures/03_npcs.png')
contact=Image.new('RGB',(1440,1170),'#d9d2ba');dc=ImageDraw.Draw(contact);dc.text((24,18),'PATO SPLASH / ASSETS ORIGINALES',font=font,fill='#33485c')
for idx,(name,a) in enumerate(assets.items()):
 x=20+(idx%6)*235;y=70+(idx//6)*270
 im=Image.open(ROOT/'splash/assets'/f'{name}.png').convert('RGBA').crop((0,0,a[0],a[1]))
 factor=min(1,210/im.width,220/im.height);im=im.resize((int(im.width*factor),int(im.height*factor)),Image.Resampling.NEAREST)
 contact.paste(im,(x+(210-im.width)//2,y),im);dc.text((x,y+230),name,font=small,fill='#33485c')
contact.save(ROOT/'captures/04_assets.png')
sha={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'demo/references').glob('*.png')}
(ROOT/'docs/referencias_sha256.json').write_text(json.dumps(sha,indent=2),encoding='utf8')
print('PREPARED',len(props),'props,',len(markers),'markers, 9 NPC skins, audio and previews')
