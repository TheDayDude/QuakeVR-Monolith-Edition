"""Fit the headless Rover mesh to QuakeVR's body rig. Run after rover_body.py."""
import ast
import math
from pathlib import Path
import re
import shutil
import struct
import sys

body, upstream, out = map(Path, sys.argv[1:])
rig = upstream / "quakevr/progs"
template = (rig / "vrbody.md5mesh").read_text()
header, mesh = template.split("mesh {", 1)
joints = []
for name, parent, xyz, rotation in re.findall(r'"(\w+)"\s+(-?\d+) \( ([^)]*) \) \( ([^)]*) \)', header):
    joints.append((name, tuple(map(float, xyz.split())), tuple(map(float, rotation.split()))))

verts, weights, tris = [], [], []
# Retain the VR arm topology, including the weighted twist rings at the wrists.
source_weights = re.findall(r'weight \d+ (\d+) ([\d.]+) \( ([^)]*) \)', mesh)
indices = {}
for index, uv, start, count in re.findall(r'vert (\d+) \( ([^)]*) \) (\d+) (\d+)', mesh):
    ws = source_weights[int(start):int(start) + int(count)]
    if not any(joints[int(j)][0].startswith(("upperarm", "fore", "wrist", "hand", "clavicle")) for j, _, _ in ws):
        continue
    u, v = map(float, uv.split())
    indices[int(index)] = len(verts)
    verts.append(((512 + u * 256) / 1024, v, len(weights), len(ws)))
    weights.extend((int(j), float(b), tuple(map(float, p.split()))) for j, b, p in ws)
for face in re.findall(r'tri \d+ (\d+) (\d+) (\d+)', mesh):
    if all(int(i) in indices for i in face):
        tris.append(tuple(indices[int(i)] for i in face))

d = body.read_bytes()
scale = struct.unpack_from("<3f", d, 8)
origin = struct.unpack_from("<3f", d, 20)
_, width, height, nv, nt = struct.unpack_from("<5i", d, 48)
assert (width, height) == (512, 256)
st = 88 + width * height
faces = st + 12 * nv
# Frame 12 is stand1. Undo the old camera offset and centre the staggered feet.
frame = faces + 16 * nt + 12 * (28 + 4 * nv) + 28

def cross(a, b):
    return tuple(a[(i+1)%3]*b[(i+2)%3] - a[(i+2)%3]*b[(i+1)%3] for i in range(3))

def rover_vertex(i, back):
    seam, s, t = struct.unpack_from("<3i", d, st + i * 12)
    x, y, z = [origin[k] + scale[k]*d[frame + 4*i+k] for k in range(3)]
    side = "l" if y > 0 else "r"
    leg = min(1, max(0, (3-z)/18))
    pos = ((x + 7 - leg*(5 if y > 0 else -7))*.85,
           y * (.80 - .18*leg), (z + 24)*.83)
    # Smoothly transfer influence between adjacent anatomical landmarks.
    chain = [(2, "foot_"+side), (7, "calf_"+side), (14, "calf_"+side),
             (19, "thigh_"+side), (22, "thigh_"+side), (25, "pelvis"),
             (28, "spine"), (34, "chest")]
    ws = [(chain[-1][1], 1)]
    for (lo, a), (hi, b) in zip(chain, chain[1:]):
        if pos[2] <= hi:
            f = max(0, (pos[2]-lo)/(hi-lo))
            ws = [(a, 1)] if a == b else [(a, 1-f), (b, f)]
            break
    start = len(weights)
    for name, bias in ws:
        if bias <= 0:
            continue
        j = next(k for k, joint in enumerate(joints) if joint[0] == name)
        _, center, q = joints[j]
        p = tuple(a-b for a,b in zip(pos, center))
        # Inverse MD5 bind rotation (MD5 stores the negative quaternion root).
        w = math.sqrt(max(0, 1-sum(a*a for a in q)))
        t1 = cross(q, p)
        t2 = cross(q, t1)
        weights.append((j, bias, tuple(a+2*(w*b+c) for a,b,c in zip(p,t1,t2))))
    verts.append(((s + (width//2 if seam and back else 0) + .5)/1024,
                  (t+.5)/height, start, len(weights)-start))
    return len(verts)-1

corners = {}
for face in range(nt):
    front, *ids = struct.unpack_from("<4i", d, faces+16*face)
    tri = []
    for i in ids:
        key = i, not front
        if key not in corners:
            corners[key] = rover_vertex(*key)
        tri.append(corners[key])
    tris.append(tri)

with (out/"vrbody.md5mesh").open("w", newline="\n") as f:
    f.write(header + 'mesh {\n shader "rover_vr"\n')
    f.write(f" numverts {len(verts)}\n")
    for i,(u,v,start,count) in enumerate(verts):
        f.write(f" vert {i} ( {u:.7f} {v:.7f} ) {start} {count}\n")
    f.write(f" numtris {len(tris)}\n")
    for i,(a,b,c) in enumerate(tris):
        f.write(f" tri {i} {a} {b} {c}\n")
    f.write(f" numweights {len(weights)}\n")
    for i,(j,b,(x,y,z)) in enumerate(weights):
        f.write(f" weight {i} {j} {b:.7f} ( {x:.6f} {y:.6f} {z:.6f} )\n")
    f.write("}\n")

palette_src = (upstream/"Misc/quakevr/mdlpolish.py").read_text()
palette = bytes.fromhex(ast.literal_eval(re.search(r'PALETTE_HEX = (\(.*?\))', palette_src, re.S)[1]))
bgra = [palette[i:i+3][::-1] + b'\xff' for i in range(0,768,3)]
arms = (rig/"vrbody_00_00.tga").read_bytes()
atlas = bytearray(arms[:18])
struct.pack_into("<HH", atlas, 12, 1024, height)
for row in range(height):
    start = 88 + (height-1-row)*width
    atlas.extend(b''.join(bgra[c] for c in d[start:start+width]))
    atlas.extend(arms[18+1024*row:18+1024*(row+1)])
    atlas.extend(bytes(1024))
(out/"rover_vr_00_00.tga").write_bytes(atlas)
for pattern in ("vrbody.mdl","vrbody.md5anim","hand.mdl","hand_base.mdl","finger_*.mdl","hand_rig*"):
    for asset in rig.glob(pattern):
        shutil.copyfile(asset, out/asset.name)
