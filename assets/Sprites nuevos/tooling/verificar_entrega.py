from pathlib import Path
from PIL import Image
import re,json,hashlib
root=Path(r"C:\Users\feliv\.codex\.chatgpt-projects\g-p-6ac7d270eca08191830907d9c9abeba3\output\patogen-infectados-oct21")
errors=[]
types=["atletico","area","exponencial_endgame"]
refs=0
for kind in types:
 folder=root/"npcs"/kind
 tres=(folder/"NPC2.tres").read_text(encoding="utf-8")
 resources={}
 for idp,path in re.findall(r'\[ext_resource type="Texture2D" path="([^"]+)" id="([^"]+)"\]',tres):
  rel=idp.split("res://assets/patogen-infectados-oct21/",1)[1]
  im=Image.open(root/rel)
  assert im.mode=="RGBA",(kind,im.mode)
  assert im.size==(128,128),(kind,im.size)
  resources[path]=im
 for tex,x,y,w,h in re.findall(r'atlas = ExtResource\("([^"]+)"\)\nregion = Rect2\((\d+), (\d+), (\d+), (\d+)\)',tres):
  x,y,w,h=map(int,(x,y,w,h));im=resources[tex]
  assert (w,h)==(32,32) and x+w<=im.width and y+h<=im.height
  refs+=1
 assert tres.count('"speed": 10.0')==4 and tres.count('"loop": true')==4
 assert set(re.findall(r'"name": &"([^"]+)"',tres))=={"Abajo","Arriba","Derecha","Izquierda"}
 atlas=Image.open(folder/"NPC.png")
 assert atlas.size==(512,128)
 data=json.loads((folder/"NPC.json").read_text(encoding="utf-8"))
 assert len(data["frames"])==64
 for i,fr in enumerate(data["frames"].values()):
  assert fr["sourceSize"]=={"w":32,"h":32}
  assert fr["duration"]==100
  assert not fr["trimmed"] and not fr["rotated"]
 for d,di in enumerate(["abajo","arriba","derecha","izquierda"]):
  directional=Image.open(folder/f"NPC 2 {di}.png")
  for f in range(16):
   tile=directional.crop(((f%4)*32,(f//4)*32,(f%4+1)*32,(f//4+1)*32))
   other=atlas.crop((f*32,d*32,(f+1)*32,(d+1)*32))
   assert tile.tobytes()==other.tobytes(),(kind,di,f)
for f in ["comparacion","cuatro_direcciones","escala_real"]:
 im=Image.open(root/"previews"/(f+".gif"))
 assert im.n_frames==16,(f,im.n_frames)
 assert im.info["loop"]==0
 durations=[]
 for n in range(im.n_frames):
  im.seek(n);durations.append(im.info.get("duration"))
 assert durations==[100]*16,(f,durations)
original=json.loads((root/"originales_sha256.json").read_text(encoding="utf-8-sig"))
for item in original:
 p=Path(item["path"])
 assert p.exists()
 assert hashlib.sha256(p.read_bytes()).hexdigest().lower()==item["sha256"].lower(),str(p)
html=(root/"VISTA_PREVIA.html").read_text(encoding="utf-8")
script=html.split("<script>",1)[1].split("</script>",1)[0]
(root/"tooling"/"validar_vista.js").write_text(script,encoding="utf-8")
report={"status":"ok","godot_animation_names":["Abajo","Arriba","Derecha","Izquierda"],"godot_atlas_regions_verified":refs,"png_rgba_and_dimensions":"ok","full_atlas_equals_directional_sheets":"ok","animated_previews":{"frames_each":16,"ms_per_frame":100,"loop":True},"original_files_unchanged":len(original),"runtime_game_test":"not_run_no_game_project"}
(root/"validacion_entrega.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(report,ensure_ascii=False))

