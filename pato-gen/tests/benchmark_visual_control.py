from pathlib import Path
import os
import shutil
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
artifacts = project/'tests'/'visual_artifacts'
control = artifacts/'baseline_control'
assert (control/'project.godot').is_file()
env = os.environ.copy()
env['APPDATA'] = str(Path(tempfile.gettempdir())/'patogen_visual_runtime')
engine = r'C:\Users\feliv\OneDrive\Desktop\Patogen\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
for name in ['Shopping','PatoSplash']:
    with (artifacts/('control-fps-'+name+'.log')).open('w',encoding='utf-8') as stream:
        result = subprocess.run([engine,'--path',str(control),'--audio-driver','Dummy','--disable-vsync','--max-fps','0','--script','res://tests/benchmark_visuals.gd','--',name,'control_baseline'],env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=90)
    assert result.returncode==0
for path in (control/'tests'/'visual_artifacts'/'benchmarks').glob('*.json'):
    shutil.copy2(path,artifacts/'benchmarks'/path.name)
print('VISUAL_CONTROL_BENCHMARKS complete')
