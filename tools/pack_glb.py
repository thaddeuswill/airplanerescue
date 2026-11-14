# Usage: python tools/pack_glb.py <source .glb or .gltf> <models/name.glb>
#
# Makes one self-contained .glb out of a downloaded model, so it can be dropped into models/
# under the name the game asks for (barrel_a, crate_a, tree_broadleaf_b, ...).
#
# Why: Kenney's GLB files point at an outside texture (Textures/colormap.png), and every kit has
# its own colormap.png with the same name, so copying a few into models/ breaks their colors.
# Quaternius and other packs often ship .gltf + .bin + loose textures. This tool reads the
# model, pulls in the .bin and every image it points at, and writes a single .glb with all of
# it inside. Nothing else changes: same meshes, materials and scale.
#
# Example (Kenney Survival Kit, unzipped into _downloads/kenney_survival):
#   python tools/pack_glb.py "_downloads/kenney_survival/Models/GLB format/barrel.glb" models/barrel_a.glb
# No extra packages needed (standard Python 3 only).
import json, os, struct, sys, mimetypes


def read_model(path):
    data = open(path, "rb").read()
    if data[:4] == b"glTF":  # binary: header, JSON chunk, optional BIN chunk
        off, j, bin_ = 12, None, b""
        while off < len(data):
            n, kind = struct.unpack("<II", data[off:off + 8])
            chunk = data[off + 8:off + 8 + n]
            if kind == 0x4E4F534A:
                j = json.loads(chunk)
            elif kind == 0x004E4942:
                bin_ = chunk
            off += 8 + n
        return j, bin_
    return json.loads(data), None  # .gltf text


def pad(b, fill=b"\x00"):
    return b + fill * ((4 - len(b) % 4) % 4)


def main(src, dst):
    base = os.path.dirname(os.path.abspath(src))
    j, glb_bin = read_model(src)
    blob = bytearray()
    views_of_buffer = {}  # old buffer index -> offset of its bytes inside the new blob
    for i, buf in enumerate(j.get("buffers", [])):
        if "uri" in buf:
            raw = open(os.path.join(base, buf["uri"]), "rb").read()
        else:
            raw = glb_bin or b""
        views_of_buffer[i] = len(blob)
        blob += pad(raw)
    for v in j.get("bufferViews", []):
        v["byteOffset"] = v.get("byteOffset", 0) + views_of_buffer[v["buffer"]]
        v["buffer"] = 0
    for img in j.get("images", []):
        if "uri" not in img:
            continue
        p = os.path.join(base, img.pop("uri"))
        if not os.path.exists(p):
            sys.exit("missing texture: %s (keep the kit's folders as they came out of the zip)" % p)
        raw = open(p, "rb").read()
        j.setdefault("bufferViews", []).append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(raw)})
        img["bufferView"] = len(j["bufferViews"]) - 1
        img["mimeType"] = mimetypes.guess_type(p)[0] or "image/png"
        blob += pad(raw)
    j["buffers"] = [{"byteLength": len(blob)}]
    js = pad(json.dumps(j, separators=(",", ":")).encode(), b" ")
    out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob))
    out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(blob), 0x004E4942) + bytes(blob)
    os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
    open(dst, "wb").write(out)
    print("wrote", dst, len(out) // 1024, "KB")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__ if __doc__ else "usage: pack_glb.py <src .glb/.gltf> <dst .glb>")
    main(sys.argv[1], sys.argv[2])
