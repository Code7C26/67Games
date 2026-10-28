from pathlib import Path
import io
import os
import shutil
import subprocess
import tempfile
import zipfile

project = Path(__file__).resolve().parents[1]
artifacts = project / 'tests' / 'visual_artifacts'
control = artifacts / 'baseline_control'
assert control.is_relative_to(artifacts) and not (control/'project.godot').exists()
data = subprocess.check_output(['git','archive','--format=zip','8e829a1:pato-gen'],cwd=project.parent)
control.mkdir(exist_ok=True)
with zipfile.ZipFile(io.BytesIO(data)) as archive:
    for info in archive.infolist():
        target = (control/info.filename).resolve()
        assert target.is_relative_to(control.resolve())
    archive.extractall(control)
shutil.copytree(project/'.godot'/'imported',control/'.godot'/'imported',dirs_exist_ok=True)
for name in ['uid_cache.bin','global_script_class_cache.cfg']:
    if (project/'.godot'/name).exists(): shutil.copy2(project/'.godot'/name,control/'.godot'/name)
shutil.copy2(project/'tests'/'benchmark_visuals.gd',control/'tests'/'benchmark_visuals.gd')
env = os.environ.copy()
env['APPDATA'] = str(Path(tempfile.gettempdir())/'patogen_visual_runtime')
engine = r'C:\Users\feliv\OneDrive\Desktop\Patogen\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
with (artifacts/'control-navigation.log').open('w',encoding='utf-8') as stream:
    result = subprocess.run([engine,'--path',str(control),'--headless','--fixed-fps','60','--script','res://tests/test_npc_navigation.gd'],env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=300)
print('BASELINE_CONTROL navigation exit', result.returncode,flush=True)
with (artifacts/'control-fps.log').open('w',encoding='utf-8') as stream:
    result = subprocess.run([engine,'--path',str(control),'--audio-driver','Dummy','--disable-vsync','--max-fps','0','--script','res://tests/benchmark_visuals.gd','--','Laboratorio','control_baseline'],env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=90)
print('BASELINE_CONTROL benchmark exit',result.returncode,flush=True)
