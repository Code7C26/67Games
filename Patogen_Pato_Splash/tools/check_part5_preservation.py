"""Audit the part 5 revision against its pre-edit backup, without editing art or scenes."""
from pathlib import Path
import hashlib, json, re, sys

root=Path(__file__).resolve().parents[1]
backup=Path(sys.argv[1])
digest=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
old_sources=list((backup/'splash/assets').glob('*.aseprite'))
unchanged=[path.name for path in old_sources if digest(path)==digest(root/'splash/assets'/path.name)]
preserved=['project.godot','splash/assets/patogen_paleta.gpl','splash/assets/PressStart2P.ttf','splash/assets/press_start_2p.tres','demo/explorer.gd']
checks={name:digest(root/name)==digest(backup/name) for name in preserved}

def geometry(path):
    text=path.read_text(encoding='utf8')
    blocks=re.findall(r'(?m)^(\[[^\n]+\])\n([^\[]*)',text)
    shapes={}
    for header,body in blocks:
        if header.startswith('[sub_resource') and 'Shape2D' in header:
            shapes[re.search(r'id="([^"]+)"',header).group(1)]=body.strip()
    result={}
    for header,body in blocks:
        if not header.startswith('[node '):continue
        name=re.search(r'name="([^"]+)"',header).group(1)
        parent=re.search(r'parent="([^"]+)"',header)
        key=(parent.group(1)+'/' if parent else '')+name
        if key.startswith('09_GranChapuzon/'):continue
        if 'CollisionShape2D' not in header and 'StaticBody2D' not in header and name not in {'Colision','Shape'}:continue
        lines=[]
        for line in body.strip().splitlines():
            if line.startswith('shape = SubResource('):
                shape_id=re.search(r'"([^"]+)"',line).group(1)
                line='shape = '+shapes.get(shape_id,shape_id)
            lines.append(line)
        result[key]='\n'.join(lines)
    return result

original_geometry=geometry(backup/'splash/scenes/PatoSplash.tscn')
current_geometry=geometry(root/'splash/scenes/PatoSplash.tscn')
modified_geometry=[key for key in original_geometry.keys()|current_geometry.keys() if original_geometry.get(key)!=current_geometry.get(key)]
prefabs=list((backup/'splash/scenes/objetos').glob('*.tscn'))
prefabs_unchanged=all(digest(path)==digest(root/'splash/scenes/objetos'/path.name) for path in prefabs)
report={'passed':len(unchanged)==len(old_sources)==57 and all(checks.values()) and not modified_geometry and prefabs_unchanged,
        'backup':str(backup),'original_aseprite_sources_unchanged':len(unchanged),'new_aseprite_sources':len(list((root/'splash/assets').glob('*.aseprite')))-len(old_sources),
        'preserved_files':checks,'solid_geometry_nodes_checked':len(original_geometry),'modified_solid_geometry':modified_geometry,'prefabs_unchanged':prefabs_unchanged}
(root/'tests/part5_preservation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report));assert report['passed'],report

