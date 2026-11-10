"""Build a first-person mesh from the installed Rover model, retaining all animation frames."""
from pathlib import Path
import struct
import sys

source, destination = map(Path, sys.argv[1:])
data = bytearray(source.read_bytes())
magic, version = struct.unpack_from("<4si", data)
skins, width, height, vertices, triangles = struct.unpack_from("<5i", data, 48)
if (magic, version, skins) != (b"IDPO", 6, 1) or struct.unpack_from("<i", data, 84)[0]:
    raise ValueError("Expected the single-skin QBJ3 Rover MDL")
triangle_offset = 88 + width * height + 12 * vertices
frames = triangle_offset + 16 * triangles
pose = frames + 28
# Weld UV seams in the reference pose. The first vertex belongs to the
# connected torso, arms and boots. Head, hair and equipment are separate.
points = [bytes(data[pose + 4*i:pose + 4*i + 3]) for i in range(vertices)]
neighbors = {}
mesh = []
for offset in range(triangle_offset, frames, 16):
    indices = struct.unpack_from("<3i", data, offset + 4)
    corners = [points[i] for i in indices]
    mesh.append((offset, corners[0]))
    for point in corners:
        neighbors.setdefault(point, set()).update(corners)
body = {points[0]}
pending = list(body)
while pending:
    adjacent = neighbors[pending.pop()] - body
    body.update(adjacent)
    pending.extend(adjacent)
faces = [data[offset:offset + 16] for offset, point in mesh if point in body]
if not 0 < len(faces) < triangles:
    raise ValueError("Unexpected Rover mesh proportions")
# Place the neckline behind the headset while leaving the collision hull and
# the model seen by other players at their authored origins.
forward_origin, = struct.unpack_from("<f", data, 20)
struct.pack_into("<f", data, 20, forward_origin - 7)
struct.pack_into("<i", data, 64, len(faces))
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_bytes(data[:triangle_offset] + b"".join(faces) + data[frames:])

