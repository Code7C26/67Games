from pathlib import Path
import zipfile, json
root=Path(__file__).resolve().parents[1]
workspace=root.parents[1]
validation_path=next(root/name for name in ['tests/part5_validation.json','tests/giro360_validation.json','tests/part4_validation.json','tests/part3_validation.json','tests/part2_validation.json','tests/validation.json'] if (root/name).exists())
validation=json.loads(validation_path.read_text(encoding='utf8'))
assert validation['passed'], validation['failures']
if validation_path.name=='part5_validation.json':
 for name in ['part5_art.json','part5_preservation.json','part5_debug.json']:
  report=json.loads((root/'tests'/name).read_text(encoding='utf-8-sig'))
  assert report['passed'],report
 assert (root/'scenes/asset_showcase.tscn').exists()
if validation_path.name=='giro360_validation.json':
 for name in ['giro360_art.json','giro360_preservation.json','giro360_debug.json']:
  report=json.loads((root/'tests'/name).read_text(encoding='utf-8-sig'))
  assert report['passed'],report
if validation_path.name=='part4_validation.json':
 for name in ['part4_art.json','part4_preservation.json','part4_debug.json']:
  report=json.loads((root/'tests'/name).read_text(encoding='utf-8-sig'))
  assert report['passed'],report
palette_path=root/'tests/part2_palette_check.json'
if validation_path.name in {'part2_validation.json','part3_validation.json'}:
 palette=json.loads(palette_path.read_text(encoding='utf8'))
 assert palette['passed'] and palette['off_palette_pixels']==0 and palette['new_colour_pixels']==0,palette
if validation_path.name=='part3_validation.json':
 art=json.loads((root/'tests/part3_art.json').read_text(encoding='utf8'))
 assert art['passed'] and art['shared_colours']==37 and art['off_palette_pixels']==0,art
 visual=json.loads((root/'tests/part3_visual_validation.json').read_text(encoding='utf8'))
 assert visual['passed'] and visual['structural_pixels_changed']==0,visual
 revision_file=root/'tests/visual_revision_validation.json'
 if revision_file.exists():
  for report_name in ['visual_revision_validation.json','visual_revision_art.json','visual_revision_preservation.json']:
   result=json.loads((root/'tests'/report_name).read_text(encoding='utf8'))
   assert result['passed'],result
 else:
  preservation=json.loads((root/'tests/part3_preservation.json').read_text(encoding='utf8'))
  assert preservation['passed'],preservation
ases=list((root/'splash/assets').glob('*.aseprite'))
for ase in ases:assert ase.with_suffix('.png').exists(),ase
destination=workspace/'outputs/Patogen_Pato_Splash.zip';destination.parent.mkdir(exist_ok=True)
included=[]
with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
 for file in root.rglob('*'):
  if not file.is_file():continue
  rel=file.relative_to(root)
  if any(part in {'.godot','.runtime','frames','parte3_frames','parte4_frames','giro360_frames','parte5_frames','antes_revision','__pycache__'} for part in rel.parts):continue
  if file.suffix in {'.import','.tmp'}:continue
  if file.name in {'import.log','pato_original_ampliado.png'}:continue
  if rel.parts[0] not in {'project.godot','LEEME.md','.gitignore','splash','demo','tools','tests','docs','captures','scenes'}:continue
  z.write(file,Path('Patogen_Pato_Splash')/rel);included.append(str(rel))
with zipfile.ZipFile(destination) as z:assert z.testzip() is None
print(json.dumps({'zip':str(destination),'bytes':destination.stat().st_size,'files':len(included),'aseprite_sources':len(ases),'validation':validation_path.name,'validation_passed':True},ensure_ascii=False))
