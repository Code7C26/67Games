from pathlib import Path
import os
import subprocess
import sys
import tempfile

project = Path(__file__).resolve().parents[1]
engine = Path(r'C:\Users\feliv\OneDrive\Desktop\Patogen\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
artifacts = project / 'tests' / 'visual_artifacts'
artifacts.mkdir(exist_ok=True)
env = os.environ.copy()
# Short disposable runtime path avoids Windows' 260-character shader cache limit.
env['APPDATA'] = str(Path(tempfile.gettempdir()) / 'patogen_visual_runtime')
Path(env['APPDATA']).mkdir(exist_ok=True)
log = artifacts / (sys.argv[1] + '.log')
with log.open('w', encoding='utf-8') as stream:
    result = subprocess.run([str(engine), '--path', str(project), '--audio-driver', 'Dummy', *sys.argv[2:]], env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=300)
content = log.read_text(encoding='utf-8', errors='replace')
errors = [line for line in content.splitlines() if 'SCRIPT ERROR:' in line or 'SHADER ERROR:' in line or line.startswith('ERROR:') and 'resources still in use' not in line]
summaries = [line for line in content.splitlines() if any(term in line for term in ['RESULT', 'MAP_TESTS', 'MAP_FLOW', 'NPC_NAVIGATION', 'VISUAL_', 'CAPTURE '])]
print(log.name, 'exit', result.returncode, '\n' + '\n'.join(summaries[-12:]), '\n' + '\n'.join(errors[:12]))
sys.exit(result.returncode or bool(errors))
