"""Build body-relative Monolith weapon models from the unscaled source assets."""
import argparse
import struct
from pathlib import Path

# Relative to each authored model. Shared reload parts use the same factor.
GROUPS = (
    (0.38, ("v_pistol", "pistol_mag")),
    (0.65, ("v_mvrnail", "mvr_nailmag", "v_plasmatrench")),
    (0.70, ("v_spiker", "spikermag", "v_trenchgun", "v_mvrflak", "mvr_flakshell")),
    (0.55, ("v_mvrrebar", "mvr_rebarbundle", "v_quadlauncher")),
    (0.60, ("v_mvrmmml", "mvr_mmmlrack", "v_mvrgren", "mvr_canister")),
    (0.62, ("v_mvrwrench",)),
    (0.80, ("v_trenchmace", "v_greatsword", "v_mvrinvoker")),
)


def floats(data, offset, count, factor):
    fmt = f"<{count}f"
    values = struct.unpack_from(fmt, data, offset)
    struct.pack_into(fmt, data, offset, *(v * factor for v in values))


def scaled_model(path, factor):
    data = bytearray(path.read_bytes())
    if data[:4] == b"IDPO":
        # Vertex decoding scale, origin, radius and eye position, for every frame.
        floats(data, 8, 10, factor)
        return data
    if data[:4] != b"IDP3":
        raise ValueError(f"Unknown model format in {path}")
    frames, tags, surfaces = struct.unpack_from("<3i", data, 76)
    frame, tag, surface = struct.unpack_from("<3i", data, 92)
    for i in range(frames):
        floats(data, frame + 56*i, 10, factor)
    for i in range(frames*tags):
        floats(data, tag + 112*i + 64, 3, factor)
    for _ in range(surfaces):
        count, _, vertices = struct.unpack_from("<3i", data, surface + 72)
        xyz, end = struct.unpack_from("<2i", data, surface + 100)
        for i in range(count*vertices):
            pos = surface + xyz + i*8
            point = struct.unpack_from("<3h", data, pos)
            struct.pack_into("<3h", data, pos, *(round(v*factor) for v in point))
        surface += end
    return data


def tracked_pistol(data):
    """Retain the animated gun and magazine, removing the two legacy arm meshes."""
    skins, width, height, count, triangles, frames = struct.unpack_from("<6i", data, 48)
    uv = 84 + skins * (4 + width * height)
    tri = uv + count * 12
    start = tri + triangles * 16
    faces = list(struct.iter_unpack("<4i", data[tri:start]))
    pose = start + 28
    points = [bytes(data[pose + i*4:pose + i*4 + 3]) for i in range(count)]
    neighbors = {}
    for _, a, b, c in faces:
        vertices = [points[i] for i in (a, b, c)]
        for v in vertices:
            neighbors.setdefault(v, set()).update(vertices)
    scale = struct.unpack_from("<3f", data, 8)
    origin = struct.unpack_from("<3f", data, 20)
    arms = set()
    while neighbors:
        component = {next(iter(neighbors))}
        todo = list(component)
        for v in todo:
            new = neighbors.pop(v) - component
            component.update(new)
            todo.extend(new)
        # Only the arms extend behind the rear of the slide, including the wrist.
        if min(p[0] * scale[0] + origin[0] for p in component) < 0:
            arms.update(component)
    kept = [i for i in range(count) if points[i] not in arms]
    remap = {v: i for i, v in enumerate(kept)}
    faces = [(f, remap[a], remap[b], remap[c]) for f,a,b,c in faces if a in remap]
    if len(kept) == count or not faces:
        raise ValueError("Could not isolate the pistol from its glove meshes")
    out = bytearray(data[:uv])
    struct.pack_into("<2i", out, 60, len(kept), len(faces))
    struct.pack_into("<3f", out, 20, *(o-p for o,p in zip(origin,(10,-3.4,-7))))
    for i in kept:
        out.extend(data[uv+12*i:uv+12*i+12])
    for face in faces:
        out.extend(struct.pack("<4i", *face))
    for frame in range(frames):
        pos = start + frame * (28+count*4)
        if struct.unpack_from("<i",data,pos)[0]:
            raise ValueError("Grouped pistol frame")
        out.extend(data[pos:pos+28])
        for i in kept:
            out.extend(data[pos+28+i*4:pos+32+i*4])
    return out



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    dest = parser.parse_args().destination
    repo = Path(__file__).resolve().parents[1]
    for factor, names in GROUPS:
        for name in names:
            for ext in (".mdl", ".md3"):
                filename = name + ext
                source = repo / "mvr/progs" / filename
                if not source.exists():
                    source = repo.parent / "monolith_devkit/progs" / filename
                if source.exists():
                    (dest / filename).write_bytes(scaled_model(source, factor))
                elif ext == ".mdl":
                    raise FileNotFoundError(filename)


    # The jointed-hand solver reads Quake alias triangles for contact.
    for original, tracked in (("v_trenchmace","v_mvrmace"), ("v_greatsword","v_mvrsword")):
        (dest / (tracked+".mdl")).write_bytes((dest / (original+".mdl")).read_bytes())
    (dest / "v_mvrpistol.mdl").write_bytes(tracked_pistol((dest / "v_pistol.mdl").read_bytes()))


if __name__ == "__main__":
    main()
