"""Shrink Meshy exports into game-ready models.

blender -b -P tools/optimize_models.py -- <raw_dir> <out_dir> [preview_dir] [only_name ...]

For each model name keeps the largest file (the textured one), makes a
decimated copy with fresh UVs, and bakes the high-poly color + surface detail
onto it (plain decimation scrambles Meshy's fragmented UVs). Exports
<out_dir>/<name>.glb and optionally renders a preview PNG.
"""
import bpy, sys, os, re, glob
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst = args[0], args[1]
preview = args[2] if len(args) > 2 else None
only = set(args[3:])
TRIS = {"plane_trainer": 10000}  # face budget after remesh; triangulating roughly doubles it
DEFAULT_TRIS = 2500
TEX = {"plane_trainer": 2048}    # everything else: DEFAULT_TEX
DEFAULT_TEX = 1024
LIGHT_TRIS = 25000  # at or under this, skip the remesh/bake (it would smear thin parts like needles)

files = {}
for f in glob.glob(os.path.join(src, "*.glb")):
    stem = os.path.splitext(os.path.basename(f))[0]
    name = re.match(r"(?:Meshy_AI_)?(.+?)(?:_\d{8,}.*|\s\(\d+\))?$", stem).group(1)
    if name not in files or os.path.getsize(f) > os.path.getsize(files[name]):
        files[name] = f


def ctx(active, selected):
    return bpy.context.temp_override(object=active, active_object=active, selected_objects=selected,
                                     selected_editable_objects=selected)


def bounds(objs):
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
    return lo, hi


os.makedirs(dst, exist_ok=True)
for name, f in sorted(files.items()):
    if only and name not in only:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if len(meshes) > 1:
        with ctx(meshes[0], meshes):
            bpy.ops.object.join()
    high = meshes[0]
    with ctx(high, [high]):
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    textured = len(bpy.data.images) > 0
    before = len(high.data.polygons)
    lo, hi = bounds([high])
    radius = (hi - lo).length / 2

    if before <= LIGHT_TRIS:  # already game-ready: keep the mesh as-is, only shrink textures
        size = TEX.get(name, DEFAULT_TEX)
        for img in bpy.data.images:
            if img.size[0] > size:
                img.scale(size, int(size * img.size[1] / img.size[0]))
                img.pack()
        out = os.path.join(dst, name + ".glb")
        bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="JPEG",
                                  export_jpeg_quality=85)
        print(f"OPT {name}: {before:,} tris kept, textures <= {size}px, "
              f"{os.path.getsize(f) / 1e6:.1f} MB -> {os.path.getsize(out) / 1e6:.1f} MB", flush=True)
        continue

    low = high.copy(); low.data = high.data.copy(); low.name = name
    bpy.context.scene.collection.objects.link(low)
    # Meshy meshes are triangle soup split at every UV seam, so decimating them directly
    # tears holes. Rebuild a clean watertight surface first (voxel remesh), then decimate.
    rm = low.modifiers.new("remesh", "REMESH")
    rm.mode = "VOXEL"
    rm.voxel_size = radius * 0.008
    with ctx(low, [low]):
        bpy.ops.object.modifier_apply(modifier="remesh")
    budget = TRIS.get(name, DEFAULT_TRIS)
    remeshed = len(low.data.polygons)
    if remeshed > budget:
        m = low.modifiers.new("dec", "DECIMATE"); m.ratio = budget / remeshed; m.use_collapse_triangulate = True
        with ctx(low, [low]):
            bpy.ops.object.modifier_apply(modifier="dec")
    after = len(low.data.polygons)

    if textured:
        while low.data.uv_layers:
            low.data.uv_layers.remove(low.data.uv_layers[0])
        low.data.uv_layers.new(name="UVMap")
        bpy.context.view_layer.objects.active = low
        for o in bpy.context.scene.objects:
            o.select_set(o == low)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.01)
        bpy.ops.object.mode_set(mode="OBJECT")

        size = TEX.get(name, DEFAULT_TEX)
        mat = bpy.data.materials.new("body" if name.startswith("plane") else name)
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 0.6
        col_img = bpy.data.images.new(name + "_col", size, size)
        nrm_img = bpy.data.images.new(name + "_nrm", size, size)
        nrm_img.colorspace_settings.name = "Non-Color"
        col = nt.nodes.new("ShaderNodeTexImage"); col.image = col_img
        nrm = nt.nodes.new("ShaderNodeTexImage"); nrm.image = nrm_img
        nmap = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
        nt.links.new(nrm.outputs["Color"], nmap.inputs["Color"])
        nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
        low.data.materials.clear(); low.data.materials.append(mat)

        sc = bpy.context.scene
        sc.render.engine = "CYCLES"
        sc.cycles.samples = 1
        sc.cycles.device = "CPU"
        sc.render.bake.margin = 4
        high.select_set(True); low.select_set(True)
        bpy.context.view_layer.objects.active = low
        extrusion = radius * 0.03
        for node, kind in ((col, "DIFFUSE"), (nrm, "NORMAL")):
            nt.nodes.active = node
            kw = {"pass_filter": {"COLOR"}} if kind == "DIFFUSE" else {}
            bpy.ops.object.bake(type=kind, use_selected_to_active=True, cage_extrusion=extrusion, **kw)
            node.image.pack()
        nt.nodes.active = col  # workbench previews show the active image node
    bpy.data.objects.remove(high)

    out = os.path.join(dst, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="JPEG",
                              export_jpeg_quality=85)
    print(f"OPT {name}: {before:,} -> {after:,} tris, baked={textured}, "
          f"{os.path.getsize(f) / 1e6:.1f} MB -> {os.path.getsize(out) / 1e6:.1f} MB", flush=True)

    if preview:
        sc = bpy.context.scene
        lo, hi = bounds([low])
        center, r = (lo + hi) / 2, (hi - lo).length / 2
        cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
        sc.collection.objects.link(cam)
        cam.location = center + Vector((1.0, -1.3, 0.8)).normalized() * r * 2.6
        cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.camera = cam
        sc.render.engine = "BLENDER_WORKBENCH"
        sc.display.shading.color_type = "TEXTURE"
        sc.display.shading.light = "STUDIO"
        sc.render.resolution_x = sc.render.resolution_y = 420
        sc.render.filepath = os.path.join(preview, name + ".png")
        bpy.ops.render.render(write_still=True)
