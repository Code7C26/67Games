"""Compare the visual revision against its pre-edit backup; never changes assets."""
from pathlib import Path
import hashlib, json, sys, zipfile

root = Path(__file__).resolve().parents[1]
backup = Path(sys.argv[1])
font_archive = Path(sys.argv[2])
digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
unchanged, changed = [], []
for source in (root / 'splash/assets').glob('*.aseprite'):
    relative = source.relative_to(root)
    (unchanged if digest(source) == digest(backup / relative) else changed).append(source.name)
preserved = ['project.godot', 'splash/assets/patogen_paleta.gpl',
             'splash/scripts/splash_event.gd', 'demo/visitor.gd', 'demo/routes.gd', 'demo/explorer.gd']
checks = {name: digest(root/name) == digest(backup/name) for name in preserved}
with zipfile.ZipFile(font_archive) as archive:
    entries = [name for name in archive.namelist() if name.lower().endswith('.ttf')]
    exact_font = len(entries) == 1 and archive.read(entries[0]) == (root/'splash/assets/PressStart2P.ttf').read_bytes()
report = {'passed': len(unchanged) == 47 and changed == ['pato_gigante.aseprite'] and all(checks.values()) and exact_font,
          'unchanged_aseprite_sources': len(unchanged), 'redrawn_sources': changed,
          'preserved_files': checks, 'font_exactly_matches_user_zip': exact_font,
          'backup': str(backup)}
(root/'tests/visual_revision_preservation.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print(json.dumps(report))
assert report['passed'], report
