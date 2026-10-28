from pathlib import Path
import hashlib
import json
import subprocess
from PIL import Image, ImageDraw, ImageFont

project = Path(__file__).resolve().parents[1]
artifacts = project/'tests'/'visual_artifacts'
captures = artifacts/'captures'
comparisons = artifacts/'comparisons'
comparisons.mkdir(exist_ok=True)
font = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf',26)
for name in ['Shopping','Laboratorio','PatoSplash']:
    pair = Image.new('RGB',(3840,1132),'#14232b')
    pair.paste(Image.open(captures/f'{name}_coherence_before.png'),(0,52))
    pair.paste(Image.open(captures/f'{name}_coherence_after.png'),(1920,52))
    draw = ImageDraw.Draw(pair)
    draw.text((24,12),name+' / antes',font=font,fill='white')
    draw.text((1944,12),name+' / fuentes de luz coherentes',font=font,fill='#b5e4d5')
    pair.save(comparisons/f'{name}_coherence.png')
protected = ['scripts/Mapa.gd','scripts/Bot.gd','scripts/Pato.gd','scripts/match_hud.gd','scripts/npc_readability.gd','shaders/npc_outline.gdshader']
hashes = {}
for name in protected:
    before = subprocess.check_output(['git','show','7b84c5d:pato-gen/'+name],cwd=project).replace(b'\r\n',b'\n')
    after = (project/name).read_bytes().replace(b'\r\n',b'\n')
    assert before==after,name
    hashes[name] = hashlib.sha256(after).hexdigest()
report = {'protected_files_sha256':hashes,'benchmarks':[],'tests':{}}
for path in sorted((artifacts/'benchmarks').glob('*_coherence.json')): report['benchmarks'].append(json.loads(path.read_text()))
for path in sorted(artifacts.glob('coherence-*.log')):
    content = path.read_text(encoding='utf-8',errors='replace')
    report['tests'][path.stem] = [line for line in content.splitlines() if any(term in line for term in ['RESULT','VISUAL_COHERENCE','MAP_TESTS','MAP_FLOW','NPC_NAVIGATION','FAIL '])]
(artifacts/'coherence_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
print('VISUAL_COHERENCE_REPORT',artifacts/'coherence_report.json')
