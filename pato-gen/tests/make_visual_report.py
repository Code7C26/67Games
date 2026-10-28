from pathlib import Path
import hashlib
import json
import subprocess
from PIL import Image, ImageDraw, ImageFont

project = Path(__file__).resolve().parents[1]
artifacts = project / 'tests' / 'visual_artifacts'
captures = artifacts / 'captures'
comparisons = artifacts / 'comparisons'
comparisons.mkdir(exist_ok=True)
font = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 26)
maps = ['Shopping', 'Laboratorio', 'PatoSplash']
stages = ['baseline', 'phase1', 'phase2', 'phase3']
for name in maps:
    for previous, phase in zip(stages, stages[1:]):
        before = Image.open(captures / f'{name}_{previous}.png').convert('RGB')
        after = Image.open(captures / f'{name}_{phase}.png').convert('RGB')
        pair = Image.new('RGB', (3840, 1132), '#14232b')
        pair.paste(before, (0, 52))
        pair.paste(after, (1920, 52))
        draw = ImageDraw.Draw(pair)
        draw.text((24, 12), f'{name} / {previous}', font=font, fill='#dce8ed')
        draw.text((1944, 12), f'{name} / {phase}', font=font, fill='#b5e4d5')
        pair.save(comparisons / f'{name}_{phase}.png')
    pair = Image.new('RGB', (3840,1132),'#14232b')
    pair.paste(Image.open(captures / f'{name}_baseline.png'),(0,52))
    pair.paste(Image.open(captures / f'{name}_phase3.png'),(1920,52))
    ImageDraw.Draw(pair).text((24,12),f'{name} / antes',font=font,fill='white')
    ImageDraw.Draw(pair).text((1944,12),f'{name} / final',font=font,fill='#b5e4d5')
    pair.save(comparisons / f'{name}_final.png')

protected = ['scripts/Mapa.gd','scripts/Bot.gd','scripts/Pato.gd','scripts/match_hud.gd','scripts/npc_readability.gd','shaders/npc_outline.gdshader','patogen_onboarding/profile.gd','project.godot']
hashes = {}
for relative in protected:
    original = subprocess.check_output(['git','show','8e829a1:pato-gen/'+relative],cwd=project)
    current = (project/relative).read_bytes()
    assert original.replace(b'\r\n',b'\n') == current.replace(b'\r\n',b'\n'), f'Protected gameplay/actor/project file changed: {relative}'
    hashes[relative] = hashlib.sha256(current.replace(b'\r\n',b'\n')).hexdigest()

benchmarks = [json.loads(p.read_text()) for p in sorted((artifacts/'benchmarks').glob('*.json'))]
test_summaries = {}
for path in sorted(artifacts.glob('checks-*.log')):
    content = path.read_text(encoding='utf-8',errors='replace')
    test_summaries[path.stem] = [line for line in content.splitlines() if any(s in line for s in ['RESULT','MAP_TESTS','MAP_FLOW','NPC_NAVIGATION','VISUAL_TESTS','FAIL '])]
report = {'protected_files_sha256':hashes,'benchmarks':benchmarks,'tests':test_summaries,
          'performance_note':'The presentation rate settled at 30 FPS, including an empty control scene with zero draw calls and 0.22 ms GPU p95. Actual GPU frame time with 65 bots was 3.6–7.3 ms p95. 60 FPS presentation is not confirmed in this session.',
          'baseline_commit':'8e829a1','comparisons':[p.name for p in comparisons.glob('*.png')]}
(artifacts/'report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
html = ['<!doctype html><html lang="es"><meta charset="utf-8"><title>Patogen · Calidad visual</title><style>body{background:#14232b;color:#dce8ed;font:18px system-ui;margin:30px}img{width:100%;image-rendering:pixelated}a{color:#b5e4d5}section{margin-bottom:40px}table{border-collapse:collapse}td,th{padding:10px;border:1px solid #506570}</style><h1>Patogen · Comparaciones visuales</h1><p>Imágenes del motor a 1920×1080. Izquierda: antes. Derecha: resultado.</p>']
for name in maps:
    html.append(f'<section><h2>{name}</h2><a href="comparisons/{name}_final.png"><img src="comparisons/{name}_final.png"></a><p>Fases: ')
    for phase in stages[1:]: html.append(f'<a href="comparisons/{name}_{phase}.png">{phase}</a> · ')
    html.append(f'<a href="captures/{name}_phase3_reduced.png">Movimiento reducido</a></p></section>')
html.append('<p><a href="report.json">Pruebas, mediciones y hashes de archivos protegidos</a></p></html>')
(artifacts/'index.html').write_text(''.join(html),encoding='utf-8')
print('VISUAL_REPORT', artifacts/'index.html', 'comparisons', len(report['comparisons']))
