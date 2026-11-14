# Usage: python tools/paint_scene_fixes.py textures/work <outdir>   (repaints the pieces from docs/quick-specs/scene-parts-match-2026-11-13.md; reads the current art as the base)
# Repaints the work-scene pieces that didn't match the real parts (docs/quick-specs/scene-parts-match-2026-11-13.md).
# Painted look like the existing scenes: soft gradients, a work-lamp highlight from the upper left, cast shadow, no ink outline.
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SRC, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
SS = 4  # supersample


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def down(im, w, h):
    return im.resize((w, h), Image.LANCZOS)


def mask_from(fn, w, h):
    m = Image.new("L", (w * SS, h * SS), 0)
    fn(ImageDraw.Draw(m))
    return m


def shade(mask, base, light=(0.35, 0.35), spread=0.55, spec=0.5, noise=6, seed=1):
    """Fill a mask with a lit color: brighter toward the light point, a soft specular, a little grain."""
    W, H = mask.size
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    lx, ly = light[0] * W, light[1] * H
    d = np.sqrt((xx - lx) ** 2 + (yy - ly) ** 2) / max(W, H)
    k = np.clip(1.25 - d / spread, 0.55, 1.25)
    rng = np.random.default_rng(seed)
    g = rng.normal(0, noise, (H, W)).astype(np.float32)
    rgb = np.zeros((H, W, 3), np.float32)
    for i in range(3):
        rgb[..., i] = base[i] * k + g
    s = np.exp(-((d - 0.08) ** 2) / 0.004) * 255 * spec
    rgb += s[..., None]
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    im = Image.fromarray(rgb, "RGB").convert("RGBA")
    im.putalpha(mask)
    return im


def edge(mask, color, width, alpha=200):  # soft dark rim so the piece sits on the scene
    e = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(width * 2 + 1)))
    layer = Image.new("RGBA", mask.size, color + (0,))
    layer.putalpha(e.point(lambda v: v * alpha // 255))
    return layer


def hole_mask(mask, pts, r):
    d = ImageDraw.Draw(mask)
    for (x, y) in pts:
        d.ellipse([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS], fill=0)


def lobed(cx, cy, a, b, lobe, n=6, steps=240, phase=0.0):
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        r = 1.0
        for k in range(n):
            lt = phase + 2 * math.pi * k / n
            dd = abs((t - lt + math.pi) % (2 * math.pi) - math.pi)
            r += lobe * max(0.0, 1 - dd / 0.38) ** 1.5
        pts.append(((cx + a * r * math.cos(t)) * SS, (cy + b * r * math.sin(t)) * SS))
    return pts


# ---------------- rocker cover (oil_leak) ----------------
RX, RY, RW, RH = 260, 110, 320, 190          # ROCKER_RECT in work.gd
LC = (RW / 2, RH / 2)                         # center inside the piece
SCREWS = [(LC[0] + 140 * math.cos(math.radians(60 * i)), LC[1] + 80 * math.sin(math.radians(60 * i))) for i in range(6)]


def flange_poly(scale=1.0):
    return lobed(LC[0], LC[1], 128 * scale, 70 * scale, 0.20)


def flange_mask(W, H, ox=0, oy=0, grow=0.0):
    """The C-85 rocker-box flange: an oval with a round ear at each screw, the joins filleted."""
    m = Image.new("L", (W * SS, H * SS), 0)
    d = ImageDraw.Draw(m)
    a, b, r = 118 + grow, 62 + grow, 19 + grow
    cx, cy = (LC[0] + ox) * SS, (LC[1] + oy) * SS
    d.ellipse([cx - a * SS, cy - b * SS, cx + a * SS, cy + b * SS], fill=255)
    for (x, y) in SCREWS:
        X, Y = (x + ox) * SS, (y + oy) * SS
        d.ellipse([X - r * SS, Y - r * SS, X + r * SS, Y + r * SS], fill=255)
    # fillet the inside corners: grow, then shrink back (a morphological close done with blur)
    m = m.filter(ImageFilter.GaussianBlur(9 * SS)).point(lambda v: 255 if v > 70 else 0)
    return m.filter(ImageFilter.GaussianBlur(0.6 * SS))


def oval_mask(W, H, a, b, ox=0, oy=0):
    m = Image.new("L", (W * SS, H * SS), 0)
    cx, cy = (LC[0] + ox) * SS, (LC[1] + oy) * SS
    ImageDraw.Draw(m).ellipse([cx - a * SS, cy - b * SS, cx + a * SS, cy + b * SS], fill=255)
    return m


def rocker_cover():
    W, H = RW, RH
    out = canvas(W, H)
    m = flange_mask(W, H)
    sh = m.filter(ImageFilter.GaussianBlur(6 * SS)).point(lambda v: v * 120 // 255)
    shadow = Image.new("RGBA", m.size, (10, 8, 6, 0)); shadow.putalpha(sh)
    out.alpha_composite(shadow, (5 * SS, 7 * SS))
    out.alpha_composite(shade(m, (140, 144, 148), light=(0.3, 0.25), spread=0.7, spec=0.12, seed=3))
    dome = mask_from(lambda d: d.ellipse([(LC[0] - 100) * SS, (LC[1] - 50) * SS, (LC[0] + 100) * SS, (LC[1] + 50) * SS], fill=255), W, H)
    out.alpha_composite(shade(dome, (168, 172, 176), light=(0.38, 0.3), spread=0.55, spec=0.22, seed=4))
    out.alpha_composite(edge(dome, (40, 40, 44), 2 * SS, 160))
    for (x, y) in SCREWS:  # cast boss under each screw
        b = mask_from(lambda d: d.ellipse([(x - 13) * SS, (y - 13) * SS, (x + 13) * SS, (y + 13) * SS], fill=255), W, H)
        out.alpha_composite(shade(b, (130, 134, 138), light=(0.3, 0.3), spec=0.15, seed=5))
        out.alpha_composite(edge(b, (30, 30, 34), 1 * SS, 140))
    d = ImageDraw.Draw(out)
    for (x, y) in SCREWS:
        d.ellipse([(x - 5) * SS, (y - 5) * SS, (x + 5) * SS, (y + 5) * SS], fill=(28, 26, 24, 255))
    out.alpha_composite(edge(m, (24, 22, 20), 2 * SS, 220))
    down(out, W, H).save(os.path.join(OUT, "oil_leak_rocker.png"))


def rocker_gasket(old):
    W, H = RW, RH
    out = canvas(W, H)
    m = flange_mask(W, H)
    inner = oval_mask(W, H, 100, 46)
    m = ImageChops.subtract(m, inner)
    hole_mask(m, SCREWS, 6)
    if old:  # oil-soaked, cracked through at one side
        d = ImageDraw.Draw(m)
        d.polygon([((LC[0] + 60) * SS, (LC[1] + 40) * SS), ((LC[0] + 90) * SS, (LC[1] + 40) * SS), ((LC[0] + 80) * SS, (LC[1] + 100) * SS), ((LC[0] + 55) * SS, (LC[1] + 100) * SS)], fill=0)
    col = (92, 58, 30) if old else (191, 98, 44)
    out.alpha_composite(shade(m, col, light=(0.3, 0.3), spread=0.8, spec=0.08 if old else 0.15, noise=14 if old else 8, seed=7))
    out.alpha_composite(edge(m, (40, 22, 10), 1 * SS, 200))
    down(out, W, H).save(os.path.join(OUT, "oil_leak_gasket_old.png" if old else "oil_leak_gasket_new.png"))


def oil_leak_bg():
    bg = Image.open(os.path.join(SRC, "oil_leak_bg.png")).convert("RGBA")
    a = np.array(bg)
    # 1) paint the old rectangular rocker flange out with the head's own fins (they run up and down,
    #    so copying a clean strip across keeps the pattern)
    # each fin column is the same top to bottom, so rebuild the covered span column by column from a
    # clean stretch past the rounded end (x 140-193), matching the 9 px fin pitch
    src0 = 140
    for x in range(196, 646):
        a[90:300, x] = a[90:300, src0 + (x - src0) % 54]
    bg = Image.fromarray(a)
    # 2) the lobed rocker-box flange, the open box and its rocker arms, in the new place
    W, H = 1000, 560
    fl = canvas(W, H)
    m = flange_mask(W, H, RX, RY, grow=4)
    fl.alpha_composite(shade(m, (162, 165, 168), light=(0.33, 0.22), spread=0.5, spec=0.1, seed=9))
    fl.alpha_composite(edge(m, (30, 30, 32), 2 * SS, 200))
    im_ = oval_mask(W, H, 96, 44, RX, RY)
    fl.alpha_composite(shade(im_, (44, 36, 28), light=(0.42, 0.3), spread=0.3, spec=0.0, noise=4, seed=10))
    d = ImageDraw.Draw(fl)
    for (x, y) in SCREWS:  # tapped holes for the cover screws
        X, Y = (x + RX) * SS, (y + RY) * SS
        d.ellipse([X - 6 * SS, Y - 6 * SS, X + 6 * SS, Y + 6 * SS], fill=(26, 24, 22, 255))
    fl = down(fl, W, H)
    # rocker arms and valve springs, taken from the old painting and set into the new box
    old = Image.open(os.path.join(SRC, "oil_leak_bg.png")).convert("RGBA")
    arms = old.crop((262, 165, 576, 245)).resize((190, 62), Image.LANCZOS)
    box = Image.new("L", (W, H), 0)
    ImageDraw.Draw(box).ellipse([RX + LC[0] - 92, RY + LC[1] - 40, RX + LC[0] + 92, RY + LC[1] + 40], fill=255)
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0)); lay.alpha_composite(arms, (RX + int(LC[0]) - 95, RY + int(LC[1]) - 31))
    lay.putalpha(ImageChops.multiply(lay.split()[3], box))
    bg.alpha_composite(fl)
    bg.alpha_composite(lay)
    bg.save(os.path.join(OUT, "oil_leak_bg.png"))


# ---------------- tail brace wires ----------------
UP = ((630 - 74, 175 - 89), (148, 178))       # rect origin, size (work.gd _c(630,175,148,178))
LO = ((590 - 114, 295 - 39), (228, 78))
A_FIN, A_STAB, A_FUS = (566, 96), (694, 256), (486, 328)   # attach points on the airframe


def rod(rect, p0, p1, old, name):
    (ox, oy), (w, h) = rect
    out = canvas(w, h)
    d = ImageDraw.Draw(out)
    a = ((p0[0] - ox) * SS, (p0[1] - oy) * SS); b = ((p1[0] - ox) * SS, (p1[1] - oy) * SS)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    ux, uy = math.cos(ang), math.sin(ang)
    sag = 6 * SS if old else 0
    mid = ((a[0] + b[0]) / 2 - uy * sag, (a[1] + b[1]) / 2 + ux * sag)
    body = [(a[0] + ux * 22 * SS, a[1] + uy * 22 * SS), mid, (b[0] - ux * 22 * SS, b[1] - uy * 22 * SS)]
    col = (150, 92, 60) if old else (172, 178, 184)
    d.line(body, fill=(30, 28, 26, 255), width=7 * SS, joint="curve")          # shadowed edge
    d.line(body, fill=col + (255,), width=5 * SS, joint="curve")
    d.line([(p[0] - uy * 1.2 * SS, p[1] + ux * 1.2 * SS) for p in body], fill=(235, 238, 240, 200) if not old else (190, 130, 90, 200), width=1 * SS)
    for (p, s) in ((a, 1), (b, -1)):  # threaded fork (clevis) end: body, two prongs, the pin through them
        cx, cy = p[0] + ux * s * 14 * SS, p[1] + uy * s * 14 * SS
        d.line([(cx, cy), (cx + ux * s * 10 * SS, cy + uy * s * 10 * SS)], fill=(30, 28, 26, 255), width=11 * SS)
        d.line([(cx, cy), (cx + ux * s * 10 * SS, cy + uy * s * 10 * SS)], fill=col + (255,), width=9 * SS)
        for side in (-1, 1):
            q0 = (cx - uy * side * 5 * SS, cy + ux * side * 5 * SS)
            q1 = (q0[0] - ux * s * 16 * SS, q0[1] - uy * s * 16 * SS)
            d.line([q0, q1], fill=(30, 28, 26, 255), width=5 * SS)
            d.line([q0, q1], fill=col + (255,), width=3 * SS)
        d.ellipse([p[0] - 4 * SS, p[1] - 4 * SS, p[0] + 4 * SS, p[1] + 4 * SS], fill=(90, 92, 96, 255), outline=(25, 25, 25, 255), width=SS)
    down(out, w, h).save(os.path.join(OUT, name))


def brace_bg():
    bg = Image.open(os.path.join(SRC, "brace_wires_bg.png")).convert("RGBA")
    W, H = bg.size
    lay = canvas(W, H)
    d = ImageDraw.Draw(lay)
    for (x, y), ang in ((A_FIN, 225), (A_STAB, 0), (A_FUS, 160)):
        X, Y = x * SS, y * SS
        r = 11 * SS
        pts = [(X + r * math.cos(math.radians(ang + t)), Y + r * math.sin(math.radians(ang + t))) for t in range(-110, 111, 10)]
        pts += [(X + 18 * SS * math.cos(math.radians(ang + 180 + 35)), Y + 18 * SS * math.sin(math.radians(ang + 180 + 35))),
                (X + 18 * SS * math.cos(math.radians(ang + 180 - 35)), Y + 18 * SS * math.sin(math.radians(ang + 180 - 35)))]
        d.polygon(pts, fill=(150, 154, 160, 255), outline=(30, 30, 32, 255))
        d.ellipse([X - 4 * SS, Y - 4 * SS, X + 4 * SS, Y + 4 * SS], fill=(24, 22, 20, 255))
    bg.alpha_composite(down(lay, W, H))
    bg.save(os.path.join(OUT, "brace_wires_bg.png"))


# ---------------- starter pad and gasket ----------------
FAST = [(150, 220), (150, 255), (150, 290), (200, 208), (200, 302)]   # 3 studs + 2 through bolts (work.gd)
BORE = (178, 255)
GR = (125, 195, 100, 120)   # gasket task rect


def pad_shape(d, ox, oy, grow=0):
    d.rounded_rectangle([(122 - grow - ox) * SS, (192 - grow - oy) * SS, (230 + grow - ox) * SS, (318 + grow - oy) * SS], radius=26 * SS, fill=255)


def starter_bg():
    bg = Image.open(os.path.join(SRC, "starter_bg.png")).convert("RGBA")
    a = np.array(bg)
    # cover the old round pad with the plain accessory-case metal beside it
    # (tone-matched to the metal around the hole, and feathered in so it leaves no edge)
    patch = np.array(Image.fromarray(a[180:340, 250:380]).resize((164, 172))).astype(float)
    ring = np.concatenate([a[154:162, 78:242, :3].reshape(-1, 3), a[170:330, 244:252, :3].reshape(-1, 3)]).astype(float)
    patch[:, :, :3] += ring.mean(0) - patch[:, :, :3].reshape(-1, 3).mean(0)
    fm = Image.new("L", (164, 172), 0); ImageDraw.Draw(fm).rectangle([5, 12, 151, 180], fill=255)
    fm = np.array(fm.filter(ImageFilter.GaussianBlur(4))).astype(float)[:, :, None] / 255
    reg = a[162:334, 78:242].astype(float)
    reg[:, :, :3] = reg[:, :, :3] * (1 - fm) + patch[:, :, :3] * fm
    a[162:334, 78:242] = np.clip(reg, 0, 255).astype(np.uint8)
    bg = Image.fromarray(a)
    W, H = bg.size
    m = Image.new("L", (W * SS, H * SS), 0); pad_shape(ImageDraw.Draw(m), 0, 0)
    lay = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    sh = m.filter(ImageFilter.GaussianBlur(5 * SS)).point(lambda v: v * 110 // 255)
    s_ = Image.new("RGBA", m.size, (10, 8, 6, 0)); s_.putalpha(sh); lay.alpha_composite(s_, (4 * SS, 6 * SS))
    lay.alpha_composite(shade(m, (190, 193, 197), light=(0.15, 0.36), spread=0.15, spec=0.3, seed=11))
    lay.alpha_composite(edge(m, (28, 28, 30), 2 * SS, 210))
    d = ImageDraw.Draw(lay)
    bx, by = BORE[0] * SS, BORE[1] * SS
    d.ellipse([bx - 20 * SS, by - 20 * SS, bx + 20 * SS, by + 20 * SS], fill=(24, 20, 18, 255), outline=(60, 60, 62, 255), width=2 * SS)
    for (x, y) in FAST:
        d.ellipse([(x - 6) * SS, (y - 6) * SS, (x + 6) * SS, (y + 6) * SS], fill=(28, 26, 24, 255))
        d.ellipse([(x - 3) * SS, (y - 3) * SS, (x + 3) * SS, (y + 3) * SS], fill=(150, 152, 156, 255))  # stud end
    bg.alpha_composite(down(lay, W, H))
    bg.save(os.path.join(OUT, "starter_bg.png"))


def starter_gasket():
    gx, gy, gw, gh = GR
    out = canvas(gw, gh)
    m = Image.new("L", (gw * SS, gh * SS), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([(128 - gx) * SS, (198 - gy) * SS, (224 - gx) * SS, (312 - gy) * SS], radius=22 * SS, fill=255)
    d.ellipse([(BORE[0] - 21 - gx) * SS, (BORE[1] - 21 - gy) * SS, (BORE[0] + 21 - gx) * SS, (BORE[1] + 21 - gy) * SS], fill=0)
    for (x, y) in FAST:
        d.ellipse([(x - 6 - gx) * SS, (y - 6 - gy) * SS, (x + 6 - gx) * SS, (y + 6 - gy) * SS], fill=0)
    out.alpha_composite(shade(m, (196, 128, 70), light=(0.3, 0.3), spread=0.9, spec=0.1, noise=10, seed=12))
    out.alpha_composite(edge(m, (60, 32, 14), 1 * SS, 200))
    down(out, gw, gh).save(os.path.join(OUT, "starter_gasket.png"))


# ---------------- magneto flange gasket ----------------
def magneto_gasket():
    W, H = 80, 60
    out = canvas(W, H)
    m = Image.new("L", (W * SS, H * SS), 0)
    d = ImageDraw.Draw(m)
    d.ellipse([18 * SS, 4 * SS, 62 * SS, 56 * SS], fill=255)                 # round flange
    for x in (4, 58):                                                        # two ears for the mounting studs
        d.rounded_rectangle([x * SS, 22 * SS, (x + 18) * SS, 38 * SS], radius=8 * SS, fill=255)
    d.ellipse([27 * SS, 14 * SS, 53 * SS, 46 * SS], fill=0)                 # drive opening
    for x in (11, 69):
        d.ellipse([(x - 4) * SS, 26 * SS, (x + 4) * SS, 34 * SS], fill=0)
    out.alpha_composite(shade(m, (204, 142, 86), light=(0.3, 0.3), spread=0.9, spec=0.1, noise=8, seed=13))
    out.alpha_composite(edge(m, (60, 32, 14), 1 * SS, 200))
    down(out, W, H).save(os.path.join(OUT, "magneto_gasket.png"))


# ---------------- spark plug leads ----------------
def lead(i):
    W, H = 80, 50
    out = canvas(W, H)
    d = ImageDraw.Draw(out)
    path = [(40 * SS, 0), (40 * SS, 14 * SS), (44 * SS, 24 * SS), (40 * SS, 30 * SS)]
    d.line(path, fill=(30, 30, 30, 255), width=12 * SS, joint="curve")
    d.line(path, fill=(176, 180, 184, 255), width=9 * SS, joint="curve")
    for y in range(2, 26, 3):  # braid crosshatch
        d.line([(36 * SS, y * SS), (44 * SS, (y + 3) * SS)], fill=(110, 112, 116, 255), width=SS)
        d.line([(44 * SS, y * SS), (36 * SS, (y + 3) * SS)], fill=(120, 122, 126, 255), width=SS)
    # elbow and coupling nut on the plug
    d.rounded_rectangle([30 * SS, 26 * SS, 50 * SS, 38 * SS], radius=3 * SS, fill=(150, 154, 158, 255), outline=(30, 30, 30, 255), width=SS)
    hx = [(40 + 13 * math.cos(math.radians(60 * k)) , 43 + 6 * math.sin(math.radians(60 * k))) for k in range(6)]
    d.polygon([(x * SS, y * SS) for x, y in hx], fill=(196, 160, 72, 255), outline=(40, 32, 14, 255))
    d.line([(31 * SS, 43 * SS), (49 * SS, 43 * SS)], fill=(140, 110, 50, 255), width=SS)
    down(out, W, H).save(os.path.join(OUT, "spark_plugs_lead%d.png" % i))


if __name__ == "__main__":
    rocker_cover(); rocker_gasket(False); rocker_gasket(True); oil_leak_bg()
    rod(UP, A_FIN, A_STAB, False, "brace_wires_upper_new.png"); rod(UP, A_FIN, A_STAB, True, "brace_wires_upper_old.png")
    rod(LO, A_STAB, A_FUS, False, "brace_wires_lower_new.png"); rod(LO, A_STAB, A_FUS, True, "brace_wires_lower_old.png")
    brace_bg()
    starter_bg(); starter_gasket()
    magneto_gasket()
    for i in range(4):
        lead(i)
    print(sorted(os.listdir(OUT)))
