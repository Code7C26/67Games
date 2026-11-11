"""Pose definitions for the approved Garfio art; raster output is authored in Aseprite MCP."""
import json
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCE = ROOT / 'work' / 'garfio-concepto'
PALETTE = {'K':'#2E2938','S':'#456965','M':'#638881','L':'#89A099','H':'#AFB7B4','C':'#C6BC99','I':'#DED9CD','T':'#814953','P':'#9E6C7B','N':'#303A47','D':'#485764','E':'#E8D78A','Z':'#00000000'}
REVERSE = {tuple(bytes.fromhex(v[1:]))+(255,): k for k,v in PALETTE.items() if k != 'Z'}

def read(name):
    im = Image.open(SOURCE / ('garfio_' + name + '.png')).convert('RGBA')
    return [[REVERSE.get(im.getpixel((x,y)), 'Z') for x in range(32)] for y in range(32)]

def clone(p): return [r[:] for r in p]

def breathe(p, dx=0):
    q=clone(p)
    for y in range(31):
        for x in range(32):
            if y <= 22 or (y <= 28 and (x <= 9 or x >= 22)): q[y][x]='Z'
    for y in range(29):
        for x in range(32):
            if (y <= 22 or x <= 9 or x >= 22) and p[y][x]!='Z' and 0 <= x+dx < 32: q[y+1][x+dx]=p[y][x]
    return q

def stamp(p, x, y, rows):
    for yy,row in enumerate(rows):
        for xx,ch in enumerate(row):
            if 0 <= x+xx < 32 and 0 <= y+yy < 32 and ch != '.': p[y+yy][x+xx]=ch

def walk(p, phase, facing):
    q = clone(p) if phase % 2 == 0 else breathe(p)
    # Explicit contact / passing key poses: each leg is redrawn, not a translated cel.
    poses = [
        ['.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','KDDK..KNNK.','KDDK...KNNK','KDDK...KCCK','KCCK...KKKK','KKKK.......'],
        ['.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KCCK.KNNK.','.KKKK.KCCK.','......KKKK.'],
        ['.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KDDK..KNNK','KDDK...KNNK','KCCK...KNNK','KKKK...KCCK','.......KKKK'],
        ['.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KNNK.','.KDDK.KCCK.','.KCCK.KKKK.','.KKKK......']]
    for yy in range(23,31):
        for xx in range(11,22): q[yy][xx]='Z'
    rows=poses[phase]
    if facing == 'izquierda': rows=[r[::-1] for r in rows]
    stamp(q,11,23,[r.replace('.','Z') for r in rows])
    return q

def extended(p, low=False):
    q=breathe(p,1)
    for y in range(10,30):
        for x in range(22,32): q[y][x]='Z'
    if low:
        rows=['..KKKK.....','.KLLMTSK...','KLLMTPTSK..','KMMTPTCCKK.','.KSTTCCICIK','..KKKKCCIK.','......KKK..']
    else:
        rows=['..KKKK.....','.KLLMTSKKKK','KLLMTPTCCIK','KMMTPTCCICK','.KSTTTKKKK.','..KKKK.....']
    stamp(q,20,10,rows)
    return q

def main():
    frames=[]; animations=[]
    for name in ['abajo','arriba','derecha','izquierda']:
        p=read(name)
        first=len(frames)
        frames.extend([p,breathe(p)])
        animations.append({'name':'idle_'+name,'start':first,'count':2,'speed':3.5,'loop':True})
        first=len(frames)
        frames.extend([walk(p,i,name) for i in range(4)])
        animations.append({'name':'caminar_'+name,'start':first,'count':4,'speed':7.5,'loop':True})
    base=read('abajo'); prep=read('preparacion')
    for name, poses, speed, loop in [
        ('preparacion',[prep,breathe(prep)],8.0,False),
        ('enganche',[extended(base),extended(base,True)],12.0,False),
        ('tension',[extended(base,True),extended(base)],5.0,True),
        ('recuperacion',[prep,base],8.0,False)]:
        first=len(frames); frames.extend(poses)
        animations.append({'name':name,'start':first,'count':len(poses),'speed':speed,'loop':loop})
    data={'legend':PALETTE,'frames':[[''.join(r) for r in f] for f in frames],'animations':animations}
    (HERE / 'poses.json').write_text(json.dumps(data),encoding='utf-8')
    print(json.dumps(data))

if __name__ == '__main__': main()
