"""Convert a FlightGear AC3D model (.ac) to a game-ready .glb.

blender -b -P tools/ac3d_to_glb.py -- <in.ac> <out.glb> [skip_name ...]

Each AC object becomes its own named node, so the game can find parts like tyre_l.
Textures are looked up next to the .ac file and shrunk to 2048 px. Objects whose
names are listed after the paths (exact, or prefix ending in *) are left out.
"""
import bpy, sys, os

args = sys.argv[sys.argv.index("--") + 1:]
src, out, skip = args[0], args[1], args[2:]
folder = os.path.dirname(os.path.abspath(src))
MAX_TEX = 2048


def skipped(name):
    return any(name == s or (s.endswith("*") and name.startswith(s[:-1])) for s in skip)


lines = open(src, encoding="latin-1").read().splitlines()
pos = 0


def nxt():
    global pos
    pos += 1
    return lines[pos - 1].strip()


bpy.ops.wm.read_factory_settings(use_empty=True)
ac_mats = []
images = {}
mat_cache = {}


def material(mi, tex):
    key = (mi, tex)
    if key in mat_cache:
        return mat_cache[key]
    name, rgb, trans = ac_mats[mi]
    m = bpy.data.materials.new(f"{name}_{tex or 'flat'}")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.7
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    glass = "glass" in (tex or "") or "glass" in name or name == "window"
    if tex and not glass:
        if tex not in images:
            img = bpy.data.images.load(os.path.join(folder, tex))
            if img.size[0] > MAX_TEX:
                img.scale(MAX_TEX, int(MAX_TEX * img.size[1] / img.size[0]))
            img.pack()
            images[tex] = img
        node = m.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = images[tex]
        m.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    if glass or trans > 0:
        bsdf.inputs["Base Color"].default_value = (0.55, 0.62, 0.62, 1)
        bsdf.inputs["Alpha"].default_value = 0.3
        bsdf.inputs["Roughness"].default_value = 0.05
        m.surface_render_method = "BLENDED"
    mat_cache[key] = m
    return m


def read_object(parent_off):
    """Reads one OBJECT block (header already consumed) and its kids."""
    name, tex, loc = "", None, (0.0, 0.0, 0.0)
    verts, faces = [], []
    while True:
        line = nxt()
        tok = line.split()
        if not tok:
            continue
        k = tok[0]
        if k == "name":
            name = line.split('"')[1]
        elif k == "data":
            nxt()
        elif k == "texture":
            tex = line.split('"')[1]
        elif k == "loc":
            loc = tuple(map(float, tok[1:4]))
        elif k == "numvert":
            for _ in range(int(tok[1])):
                verts.append(tuple(map(float, nxt().split()[:3])))
        elif k == "numsurf":
            for _ in range(int(tok[1])):
                flags = int(nxt().split()[1], 16)
                mi = int(nxt().split()[1])
                refs = [nxt().split() for _ in range(int(nxt().split()[1]))]
                if flags & 0xF == 0 and len(refs) >= 3:  # polygons only, no lines
                    faces.append((mi, [(int(r[0]), float(r[1]), float(r[2])) for r in refs], flags & 0x20))
        elif k == "kids":
            off = tuple(a + b for a, b in zip(parent_off, loc))
            if faces and not skipped(name):
                build(name, verts, faces, tex, off)
            for _ in range(int(tok[1])):
                nxt()  # OBJECT line
                read_object(off)
            return


def build(name, verts, faces, tex, off):
    me = bpy.data.meshes.new(name)
    # AC is Y-up (x, y, z); Blender is Z-up, the glTF exporter turns it back.
    me.from_pydata([(v[0] + off[0], -(v[2] + off[2]), v[1] + off[1]) for v in verts], [],
                   [[r[0] for r in f[1]] for f in faces])
    uv = me.uv_layers.new()
    i = 0
    for f in faces:
        for r in f[1]:
            uv.data[i].uv = (r[1], r[2])
            i += 1
    slots = {}
    for f in faces:
        key = (f[0], tex)
        if key not in slots:
            slots[key] = len(slots)
            me.materials.append(material(f[0], tex))
    for p, f in zip(me.polygons, faces):
        p.material_index = slots[(f[0], tex)]
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)


while pos < len(lines):
    line = nxt()
    if line.startswith("MATERIAL"):
        name = line.split('"')[1]
        t = line.split('"')[2].split()
        ac_mats.append((name, tuple(map(float, t[t.index("rgb") + 1:t.index("rgb") + 4])), float(t[t.index("trans") + 1])))
    elif line.startswith("OBJECT"):
        read_object((0.0, 0.0, 0.0))

for ob in bpy.context.scene.objects:  # smooth shading, sharp past 40 degrees like the AC crease
    for p in ob.data.polygons:
        p.use_smooth = True
    ob.data.set_sharp_from_angle(angle=0.70)
tris = sum(len(p.vertices) - 2 for ob in bpy.context.scene.objects for p in ob.data.polygons)
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85)
print(f"AC3D {len(bpy.context.scene.objects)} objects, {tris:,} tris -> {out} ({os.path.getsize(out) / 1e6:.1f} MB)")
