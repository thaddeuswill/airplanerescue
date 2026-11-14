# Usage: python tools/draw_catalog_icons.py <outdir>   (then copy icon_* to textures/, the rest to textures/catalog/)
# Redraws the 54 parts-book icons (textures/catalog/<id>.png) to the icon audit rules:
# one distinct drawing per part (shapes checked against photos of the real parts),
# flat mid-tone fills, 4 px ink outline at 256 (16 at the 1024 working size), 2 px inner lines,
# ~80% of the tile, one red accent at most, one hard shadow down-right.
import math, sys, os
from PIL import Image, ImageDraw, ImageFont

S = 1024                      # working size, downscaled 4x at the end
OUT_W, IN_W = 16, 8           # outline / inner line width at 1024
INK = (30, 27, 23, 255)
C = {
    "steel": (150, 157, 163, 255), "steel_d": (104, 111, 118, 255), "alu": (196, 201, 204, 255),
    "copper": (184, 115, 58, 255), "copper_l": (214, 150, 92, 255), "cork": (201, 160, 107, 255),
    "rubber": (52, 50, 48, 255), "rubber_l": (92, 88, 84, 255), "red": (168, 38, 31, 255),
    "mustard": (217, 166, 46, 255), "brass": (201, 162, 63, 255), "cream": (238, 230, 207, 255),
    "black": (46, 43, 40, 255), "paper": (172, 166, 150, 255), "orange": (214, 92, 46, 255),
    "green": (46, 83, 57, 255), "yellow": (232, 190, 60, 255), "cad": (205, 190, 120, 255),
    "can": (176, 182, 186, 255), "fiber": (150, 40, 32, 255),
}
FONT = os.path.join(os.path.dirname(__file__), "..", "fonts", "BigShouldersDisplay.ttf")


def font(px, weight=800):
    f = ImageFont.truetype(FONT, px)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


class Pen:
    def __init__(self):
        self.im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    # --- primitives (fill, then ink outline) ---
    def poly(self, pts, fill, w=OUT_W):
        self.d.polygon(pts, fill=fill)
        self.d.line(list(pts) + [pts[0]], fill=INK, width=w, joint="curve")

    def rect(self, x0, y0, x1, y1, fill, r=0, w=OUT_W):
        self.d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=fill, outline=INK, width=w)

    def ell(self, cx, cy, rx, ry, fill, w=OUT_W):
        self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill, outline=INK, width=w)

    def hole(self, cx, cy, rx, ry, w=IN_W):  # punched through: transparent, inked edge
        self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(0, 0, 0, 0))
        self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=INK, width=w)

    def ring(self, cx, cy, rx, ry, t, fill, w=OUT_W):  # flat ring seen at an angle
        self.ell(cx, cy, rx, ry, fill, w)
        self.hole(cx, cy, rx - t, ry - t * ry / rx, w)

    def line(self, pts, w=IN_W, fill=INK):
        self.d.line(pts, fill=fill, width=w, joint="curve")

    def cyl(self, cx, top, bot, rx, ry, fill, top_fill=None):  # upright cylinder, 3/4 view
        self.d.rectangle([cx - rx, top, cx + rx, bot], fill=fill)
        self.d.ellipse([cx - rx, bot - ry, cx + rx, bot + ry], fill=fill)
        self.d.arc([cx - rx, bot - ry, cx + rx, bot + ry], 0, 180, fill=INK, width=OUT_W)
        self.d.line([(cx - rx, top), (cx - rx, bot)], fill=INK, width=OUT_W)
        self.d.line([(cx + rx, top), (cx + rx, bot)], fill=INK, width=OUT_W)
        self.ell(cx, top, rx, ry, top_fill or fill)

    def hex(self, cx, cy, r, fill, squash=1.0, rot=0):
        pts = [(cx + r * math.cos(math.radians(rot + 60 * i)), cy + r * squash * math.sin(math.radians(rot + 60 * i))) for i in range(6)]
        self.poly(pts, fill)
        return pts

    def thread(self, x0, y0, x1, y1, n, w=IN_W):  # thread lines across a bar
        for i in range(1, n):
            t = i / n
            self.line([(x0 + (x1 - x0) * t - 10, y0), (x0 + (x1 - x0) * t + 10, y1)], w)

    def tag(self, cx, cy, text, fill=None, size=92):  # a stamped size tag, like a parts-bin label
        f = font(size, 800)
        tw = self.d.textlength(text, font=f)
        self.rect(cx - tw / 2 - 26, cy - size * 0.62, cx + tw / 2 + 26, cy + size * 0.62, fill or C["cream"], r=14, w=12)
        self.d.text((cx, cy + 4), text, font=f, fill=INK, anchor="mm")

    def finish(self, path):
        im = self.im
        a = im.split()[3]
        bb = a.getbbox()
        k = max(0.9, min(1.3, 0.80 * S / max(bb[2] - bb[0], bb[3] - bb[1])))
        if abs(k - 1) > 0.02:  # bring the longest side to ~80% (clamped so line widths stay close)
            im = im.resize((int(S * k), int(S * k)), Image.LANCZOS)
            a = im.split()[3]; bb = a.getbbox()
            tmp = Image.new("RGBA", (max(S, im.width), max(S, im.height)), (0, 0, 0, 0)); tmp.alpha_composite(im); im = tmp
        # center the drawing
        dx = (S - (bb[2] - bb[0])) // 2 - bb[0]
        dy = (S - (bb[3] - bb[1])) // 2 - bb[1]
        moved = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        moved.alpha_composite(im.crop(bb), (bb[0] + dx, bb[1] + dy))
        # one hard shadow down-right, 20% ink
        sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        mask = moved.split()[3].point(lambda v: 51 if v > 128 else 0)
        sh.paste((30, 27, 23, 255), (22, 22), mask)
        out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        out.alpha_composite(sh)
        out.alpha_composite(moved)
        out.resize((256, 256), Image.LANCZOS).save(path)


# ---------------- the parts ----------------
D = {}
def part(fn):
    D[fn.__name__] = fn
    return fn


def flat_gasket(p, outline_pts, holes, fill, bore=None):
    p.poly(outline_pts, fill)
    for (x, y, r) in holes:
        p.hole(x, y, r, r * 0.6)
    if bore:
        p.d.polygon(bore, fill=(0, 0, 0, 0))
        p.d.line(bore + [bore[0]], fill=INK, width=IN_W, joint="curve")


def iso(pts, cx=512, cy=512, sq=0.55, sk=0.35):  # flat plan shape laid back on the bench
    return [(cx + x + y * sk, cy + y * sq) for x, y in pts]


def oval_pts(rx, ry, n=48, lobes=None):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        r = 1.0
        if lobes:
            for lt in lobes:
                d = abs((t - lt + math.pi) % (2 * math.pi) - math.pi)
                r += 0.16 * max(0, 1 - d / 0.32)
        pts.append((rx * r * math.cos(t), ry * r * math.sin(t)))
    return pts


@part
def mag_gasket(p):  # magneto flange gasket: a ring with an ear at each mounting stud (same as the scene art)
    for sx in (-1, 1):
        p.ell(512 + sx * 300, 512, 110, 96, C["cork"])
    p.ring(512, 512, 270, 250, 78, C["cork"])
    for sx in (-1, 1):
        p.d.ellipse([512 + sx * 300 - 104, 512 - 90, 512 + sx * 300 + 104, 512 + 90], fill=C["cork"])  # hide the ring's ink across the ear
        p.hole(512 + sx * 318, 512, 40, 36)
    p.hole(512, 512, 192, 172)


@part
def points(p):  # breaker point set: base plate, spring arm, contacts
    p.poly([(120, 660), (680, 500), (780, 640), (220, 800)], C["steel"])
    p.hole(240, 700, 40, 24); p.hole(640, 590, 40, 24)
    p.poly([(400, 560), (880, 240), (920, 300), (450, 630)], C["brass"])   # spring arm
    p.rect(840, 180, 950, 290, C["steel_d"], r=12)                       # rubbing block
    p.ell(450, 540, 70, 44, C["alu"]); p.ell(450, 490, 70, 44, C["red"])  # contact, red


@part
def condenser(p):  # flat can with mounting tab and lead (Bendix style)
    p.rect(170, 300, 770, 760, C["steel"], r=40)
    p.line([(170, 410), (770, 410)])
    p.poly([(770, 640), (940, 640), (940, 760), (770, 760)], C["steel_d"])
    p.hole(870, 700, 32, 26)
    p.line([(330, 330), (300, 220), (200, 170)], 14, fill=C["red"])         # lead, red
    p.line([(330, 330), (300, 220), (200, 170)], 4)
    p.ell(195, 168, 30, 24, C["brass"])


def lead(p, length_label):
    # shielded, braided ignition lead: coupling nut at the harness end, spark plug terminal at the other
    pts = [(200, 300), (330, 250), (480, 330), (520, 480), (640, 560), (790, 520)]
    p.line(pts, 104, fill=INK); p.line(pts, 78, fill=C["alu"])
    for i in range(len(pts) - 1):  # braid ticks
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        for k in range(1, 4):
            t = k / 4; x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            p.line([(x - 14, y - 14), (x + 14, y + 14)], 6)
    p.hex(165, 310, 95, C["brass"], 0.8)                     # coupling nut (brass)
    p.rect(770, 450, 910, 590, C["steel"], r=14)             # terminal sleeve
    p.rect(890, 485, 980, 555, C["red"], r=12)               # insulator tip, red
    p.tag(560, 760, length_label)


@part
def lead_36(p): lead(p, "36 IN")


@part
def lead_42(p): lead(p, "42 IN")


@part
def plug_gasket(p):  # small solid copper ring, plus a second one behind (set of 8)
    p.ring(600, 470, 210, 120, 70, C["copper"])
    p.ring(420, 590, 210, 120, 70, C["copper_l"])
    p.tag(512, 820, "SET OF 8")


@part
def cyl_assy(p):  # finned barrel under a finned head, rocker box on top, intake port
    for i in range(9):  # barrel fins
        y = 520 + i * 38
        p.ell(470, y, 230 - i * 2, 40, C["steel"], w=10)
    p.rect(330, 520, 610, 860, C["steel_d"], w=OUT_W)
    for i in range(9):
        y = 535 + i * 38
        p.line([(330, y), (610, y)], 8)
    p.rect(250, 290, 700, 520, C["alu"], r=40)                 # head
    for i in range(5):
        y = 320 + i * 40
        p.line([(250, y), (700, y)], 8)
    p.rect(330, 190, 640, 300, C["steel"], r=30)               # rocker box cover
    p.rect(700, 360, 830, 440, C["alu"], r=10)                  # intake port
    p.hole(760, 400, 30, 22)
    p.hex(420, 300, 22, C["red"])                               # spark plug boss, red


@part
def base_packing(p):  # thin rubber O-ring that seals the cylinder base
    p.ring(512, 512, 420, 240, 34, C["rubber"])
    p.tag(512, 512, "O-RING", C["cream"], 80)


@part
def nut_38(p): flanged_nut(p, '3/8"')


@part
def nut_716(p): flanged_nut(p, '7/16"')


def flanged_nut(p, label):
    p.ell(512, 560, 300, 150, C["steel_d"])                     # flange
    pts = p.hex(512, 470, 220, C["steel"], 0.55)               # hex body top face
    p.d.polygon([pts[0], pts[1], pts[2], pts[3], (pts[3][0], pts[3][1] + 90), (pts[2][0], pts[2][1] + 90), (pts[1][0], pts[1][1] + 90), (pts[0][0], pts[0][1] + 90)], fill=C["steel"])
    for q in (pts[0], pts[1], pts[2], pts[3]):
        p.line([q, (q[0], q[1] + 90)], OUT_W)
    p.line([(pts[0][0], pts[0][1] + 90), (pts[1][0], pts[1][1] + 90), (pts[2][0], pts[2][1] + 90), (pts[3][0], pts[3][1] + 90)], OUT_W)
    p.hex(512, 470, 220, C["steel"], 0.55)
    p.hole(512, 470, 95, 55)
    p.tag(512, 830, label)


@part
def piston(p):  # dome, ring lands with grooves, pin boss
    p.cyl(512, 300, 760, 260, 90, C["alu"])
    for y in (380, 430, 480):
        p.d.arc([252, y - 90, 772, y + 90], 0, 180, fill=INK, width=IN_W)
    p.ell(512, 610, 70, 70, C["steel"])                         # pin boss
    p.hole(512, 610, 34, 34)
    p.d.arc([300, 200, 724, 360], 180, 360, fill=INK, width=IN_W)  # dome hint
    p.d.arc([252, 380 - 90, 772, 380 + 90], 0, 180, fill=C["red"], width=12)  # top ring groove, red


@part
def ring_top(p):  # cast-iron compression ring with its gap
    p.ell(512, 512, 410, 230, C["steel_d"])
    p.hole(512, 512, 360, 190)
    p.d.polygon([(880, 470), (940, 470), (940, 560), (880, 560)], fill=(0, 0, 0, 0))  # the gap
    p.line([(905, 455), (905, 500)], IN_W); p.line([(905, 525), (905, 570)], IN_W)
    p.tag(512, 512, "TOP", C["cream"], 90)


@part
def rocker_gasket(p):  # cork gasket in the rocker cover outline: lobed oval, 6 screw holes
    lobes = [0, math.pi / 3, 2 * math.pi / 3, math.pi, 4 * math.pi / 3, 5 * math.pi / 3]
    out = iso(oval_pts(380, 220, 72, lobes), sq=0.62, sk=0.2)
    inn = iso(oval_pts(300, 160, 72), sq=0.62, sk=0.2)
    p.poly(out, C["cork"])
    p.d.polygon(inn, fill=(0, 0, 0, 0)); p.d.line(inn + [inn[0]], fill=INK, width=IN_W)
    for t in lobes:
        x, y = 380 * 1.1 * math.cos(t), 220 * 1.1 * math.sin(t)
        q = iso([(x, y)], sq=0.62, sk=0.2)[0]
        p.hole(q[0], q[1], 18, 12)


@part
def lifter(p):  # hydraulic tappet: polished body, oil hole, cup socket
    p.cyl(512, 220, 780, 120, 44, C["alu"])
    p.line([(392, 470), (632, 470)])
    p.hole(470, 560, 16, 16)                                    # oil hole
    p.ell(512, 220, 80, 28, C["steel_d"])                       # pushrod socket
    p.d.arc([392, 780 - 44, 632, 780 + 44], 0, 180, fill=C["red"], width=12)  # face, red


@part
def pushrod_seal(p):  # small orange rubber packing (thick, short)
    p.cyl(512, 420, 620, 330, 170, C["orange"])
    p.hole(512, 420, 170, 88)


@part
def sump_gasket(p):  # paper gasket for the cast sump flange: long pear-shaped band, bolt holes all round
    def pear(sc):
        pts = []
        for i in range(60):
            t = 2 * math.pi * i / 60
            r = 1 + 0.18 * math.cos(t)          # wider at one end, like the sump
            pts.append((sc * 440 * r * math.cos(t), sc * 230 * r * math.sin(t)))
        return iso(pts, sq=0.7, sk=0.15)
    p.poly(pear(1.0), C["paper"])
    inner = pear(0.8)
    p.d.polygon(inner, fill=(0, 0, 0, 0)); p.d.line(inner + [inner[0]], fill=INK, width=IN_W)
    for i in range(12):
        t = 2 * math.pi * i / 12
        r = 1 + 0.18 * math.cos(t)
        q = iso([(0.9 * 440 * r * math.cos(t), 0.9 * 230 * r * math.sin(t))], sq=0.7, sk=0.15)[0]
        p.hole(q[0], q[1], 16, 11)


@part
def sump_nut(p):  # elastic stop nut: hex with red fiber collar
    pts = p.hex(512, 560, 230, C["steel"], 0.55)
    p.d.polygon([pts[0], pts[1], pts[2], pts[3], (pts[3][0], pts[3][1] + 100), (pts[2][0], pts[2][1] + 100), (pts[1][0], pts[1][1] + 100), (pts[0][0], pts[0][1] + 100)], fill=C["steel"])
    for q in pts[:4]:
        p.line([q, (q[0], q[1] + 100)], OUT_W)
    p.line([(q[0], q[1] + 100) for q in pts[:4]], OUT_W)
    p.cyl(512, 370, 520, 170, 80, C["fiber"])                   # collar, red
    p.hex(512, 560, 230, C["steel"], 0.55)
    p.ell(512, 370, 170, 80, C["fiber"]); p.hole(512, 370, 80, 40)


@part
def washer(p):  # plain flat washer, edge shown
    p.cyl(512, 470, 520, 360, 200, C["steel"])
    p.hole(512, 470, 130, 72)


@part
def drain_gasket(p):  # AN900 copper-asbestos: copper shell, fiber showing at the seam
    p.ring(512, 512, 380, 215, 120, C["copper"])
    p.d.arc([512 - 320, 512 - 182, 512 + 320, 512 + 182], 200, 340, fill=C["cream"], width=18)
    p.tag(512, 512, "AN900", C["cream"], 80)


@part
def screen_gasket(p):  # larger, thinner copper ring for the suction screen plug
    p.ring(512, 512, 430, 245, 60, C["copper_l"])
    p.ring(512, 512, 330, 185, 26, C["copper"])


@part
def dipstick(p):  # cap with a grip on a long marked blade
    p.line([(300, 330), (840, 870)], 80, fill=INK); p.line([(300, 330), (840, 870)], 54, fill=C["steel"])
    for k, t in enumerate((0.62, 0.72, 0.82)):
        x, y = 300 + 500 * t, 330 + 500 * t
        p.line([(x - 28, y + 28), (x + 28, y - 28)], 8)
    p.ell(280, 300, 170, 110, C["black"])                        # cap
    p.rect(200, 250, 360, 300, C["black"], r=14)                 # grip
    p.d.text((690, 640), "F", font=font(80), fill=C["red"], anchor="mm")


@part
def crank_seal(p):  # black lip seal: rubber ring with a metal case edge and garter spring
    p.cyl(512, 450, 540, 400, 230, C["steel_d"])                # metal case
    p.ell(512, 450, 330, 190, C["rubber"])                      # rubber lip
    p.hole(512, 450, 200, 115)
    p.d.ellipse([512 - 245, 450 - 141, 512 + 245, 450 + 141], outline=C["red"], width=12)  # garter spring, red


@part
def case_cover_gasket(p):  # accessory case cover gasket: a thin band following the cover's D-shaped edge
    def d_shape(sc):
        pts = []
        for i in range(40):
            t = math.pi * i / 39                  # rounded top half
            pts.append((sc * 440 * math.cos(t), -sc * 300 * math.sin(t) + 60))
        pts += [(-sc * 440, sc * 200), (sc * 440, sc * 200)]
        return iso(list(reversed(pts[:40])) + [pts[41], pts[40]], sq=0.62, sk=0.2)
    p.poly(d_shape(1.0), C["paper"])
    inner = d_shape(0.86)
    p.d.polygon(inner, fill=(0, 0, 0, 0)); p.d.line(inner + [inner[0]], fill=INK, width=IN_W)
    for i in range(9):
        t = math.pi * (i + 0.5) / 9
        q = iso([(0.93 * 440 * math.cos(t), -0.93 * 300 * math.sin(t) + 60)], sq=0.62, sk=0.2)[0]
        p.hole(q[0], q[1], 14, 9)
    for x in (-0.93 * 440, 0.93 * 440, 0):
        q = iso([(x, 0.93 * 200)], sq=0.62, sk=0.2)[0]; p.hole(q[0], q[1], 14, 9)


@part
def carb(p):  # MA-3: cast throttle body over a float bowl, throttle and mixture arms
    p.rect(300, 440, 720, 820, C["cad"], r=40)                  # float bowl
    p.line([(300, 560), (720, 560)])
    p.rect(330, 220, 690, 450, C["cad"], r=20)                  # throttle body
    p.ell(510, 220, 180, 50, C["alu"]); p.hole(510, 220, 120, 30)  # mounting flange bore
    p.rect(690, 300, 760, 360, C["steel_d"], r=8)
    p.poly([(760, 300), (900, 230), (920, 260), (760, 360)], C["red"])   # throttle arm, red
    p.poly([(330, 330), (200, 300), (190, 340), (330, 380)], C["steel"])  # mixture arm
    p.hex(510, 870, 50, C["brass"], 0.6)                         # bowl drain plug


@part
def carb_gasket(p):  # square flange gasket: 4 bolt holes and the throat
    out = iso([(-300, -300), (300, -300), (300, 300), (-300, 300)], sq=0.6, sk=0.3)
    p.poly(out, C["paper"])
    for (x, y) in [(-230, -230), (230, -230), (230, 230), (-230, 230)]:
        q = iso([(x, y)], sq=0.6, sk=0.3)[0]; p.hole(q[0], q[1], 26, 16)
    q = iso([(0, 0)], sq=0.6, sk=0.3)[0]; p.hole(q[0], q[1], 165, 100)


@part
def air_box(p):  # sheet-metal intake box with the carb heat flapper lever and inlet duct
    p.poly([(240, 330), (700, 330), (800, 430), (800, 780), (240, 780)], C["black"])
    p.line([(700, 330), (700, 430), (800, 430)])
    p.line([(240, 430), (700, 430)])
    p.cyl(420, 220, 330, 110, 40, C["steel"])                    # inlet duct
    p.poly([(800, 560), (920, 500), (940, 535), (800, 610)], C["red"])   # heat valve lever, red
    p.ell(560, 640, 90, 90, C["steel_d"])                        # outlet to the carb
    p.hole(560, 640, 60, 60)


@part
def air_box_gasket(p):  # rectangular flange gasket with rounded ends, 4 holes
    out = iso(oval_pts(380, 240, 48), sq=0.6, sk=0.3)
    p.poly(out, C["cork"])
    q = iso([(0, 0)], sq=0.6, sk=0.3)[0]; p.hole(q[0], q[1], 230, 90)
    for (x, y) in [(-330, 0), (330, 0), (0, -210), (0, 210)]:
        q = iso([(x, y)], sq=0.6, sk=0.3)[0]; p.hole(q[0], q[1], 18, 11)


@part
def intake_pipe(p):  # bent steel intake tube with a two-hole flange at the cylinder end
    pts = [(250, 760), (420, 700), (560, 560), (640, 380), (660, 260)]
    p.line(pts, 130, fill=INK); p.line(pts, 98, fill=C["steel"])
    p.ell(660, 230, 130, 60, C["steel_d"])                       # flange
    p.hole(570, 230, 16, 10); p.hole(750, 230, 16, 10)
    p.hole(660, 230, 50, 24)
    p.ell(250, 760, 52, 60, C["steel"]); p.hole(250, 760, 30, 38)
    p.line([(330, 735), (360, 720)], 12, fill=C["red"])          # paint band, red


def hose(p, label):  # short black rubber hose connector
    p.cyl(512, 330, 640, 230, 110, C["rubber"])
    p.hole(512, 330, 170, 80)
    p.line([(282, 420), (282, 600)], 6, fill=C["rubber_l"])
    p.tag(512, 830, label)


@part
def hose_15(p): hose(p, '1-1/2"')


@part
def hose_175(p): hose(p, '1-3/4"')


@part
def hose_clamp(p):  # worm-gear clamp
    p.ring(512, 512, 380, 260, 80, C["alu"])
    p.rect(700, 330, 860, 470, C["steel"], r=16)                  # housing
    p.ell(780, 330, 60, 26, C["steel_d"])                         # screw head
    p.line([(750, 330), (810, 330)], 10)
    for i in range(6):
        x = 300 + i * 50
        p.line([(x, 760), (x + 10, 730)], 6)                        # band slots


@part
def primer_jet(p):  # small brass jet: hex, threaded body, drilled nozzle tip
    p.rect(380, 360, 640, 490, C["brass"], r=12)                  # thread body
    p.thread(380, 360, 640, 490, 8, 7)
    p.hex(290, 425, 150, C["brass"], 1.0, 30)
    p.poly([(640, 380), (860, 405), (860, 445), (640, 470)], C["brass"])
    p.hole(845, 425, 14, 14)
    p.line([(880, 425), (970, 385)], 14, fill=C["red"]); p.line([(880, 425), (970, 465)], 14, fill=C["red"])  # spray, red


@part
def gasc_gasket(p):  # cork gasket for the fuel strainer bowl: plain thick round ring
    p.cyl(512, 470, 530, 370, 210, C["cork"])
    p.hole(512, 470, 270, 150)
    for (x, y) in [(330, 420), (690, 520), (520, 330)]:
        p.d.point((x, y), fill=INK)


@part
def exh_gasket(p):  # embossed steel exhaust gasket: oval port and two bolt ears
    out = [(140, 512), (260, 400), (400, 330), (624, 330), (764, 400), (884, 512), (764, 624), (624, 694), (400, 694), (260, 624)]
    p.poly(out, C["steel"])
    p.hole(512, 512, 170, 150)
    p.d.ellipse([512 - 210, 512 - 190, 512 + 210, 512 + 190], outline=INK, width=IN_W)  # embossed bead
    p.hole(220, 512, 40, 40); p.hole(804, 512, 40, 40)


@part
def generator(p):  # black can with end frames, pulley and terminal posts
    p.rect(220, 360, 760, 700, C["black"], r=50)
    p.rect(160, 380, 240, 680, C["steel_d"], r=20)               # drive end frame
    p.rect(740, 390, 830, 670, C["steel_d"], r=20)               # commutator end frame
    p.ell(110, 530, 40, 150, C["steel"])                         # drive pulley/gear
    p.rect(420, 300, 520, 360, C["steel"], r=8)                  # terminal block
    p.ell(450, 300, 18, 10, C["red"]); p.ell(495, 300, 18, 10, C["brass"])
    p.line([(220, 470), (760, 470)], 8, fill=C["rubber_l"])


@part
def regulator(p):  # black box on a base plate with feet, three terminal screws
    p.poly([(180, 700), (840, 700), (880, 790), (140, 790)], C["steel_d"])  # base plate
    p.hole(190, 750, 22, 14); p.hole(830, 750, 22, 14)
    p.rect(240, 330, 780, 710, C["black"], r=40)
    p.line([(240, 420), (780, 420)], 8, fill=C["rubber_l"])
    for i, x in enumerate((360, 510, 660)):
        p.hex(x, 760, 34, C["red"] if i == 0 else C["brass"], 0.6)


@part
def splice_kit(p):  # strip of insulated butt splices plus heat-shrink
    for i, col in enumerate((C["red"], C["steel"], C["steel"])):
        y = 290 + i * 220
        p.rect(240, y - 80, 780, y + 80, col, r=80)
        p.line([(510, y - 55), (510, y + 55)])
        p.line([(180, y), (260, y)], 14)
        p.line([(760, y), (840, y)], 14)


@part
def cushion_clamp(p):  # Adel clamp: steel loop, black cushion (as in the wire_chafe scene), tab with bolt hole
    p.ring(470, 470, 300, 300, 34, C["alu"])
    p.ring(470, 470, 266, 266, 80, C["rubber"])
    p.poly([(520, 720), (860, 720), (860, 810), (480, 810)], C["alu"])
    p.poly([(500, 690), (860, 690), (860, 740), (500, 740)], C["alu"])
    p.hole(780, 765, 32, 26)


@part
def expander_tube(p):  # Goodyear brake expander tube: flat rubber ring with a brass inlet
    p.ring(512, 520, 400, 230, 85, C["rubber"])
    p.d.arc([512 - 360, 520 - 207, 512 + 360, 520 + 207], 200, 340, fill=C["rubber_l"], width=10)
    p.rect(470, 260, 554, 340, C["brass"], r=8)                  # inlet nipple
    p.hex(512, 250, 40, C["brass"], 0.6)


@part
def turnbuckle(p):  # brass barrel, threaded terminals, safety-wire holes
    p.rect(360, 400, 660, 624, C["brass"], r=90)
    p.hole(510, 512, 16, 16)
    p.rect(190, 462, 370, 562, C["steel"], r=12); p.thread(190, 462, 370, 562, 6, 6)
    p.rect(650, 462, 830, 562, C["steel"], r=12); p.thread(650, 462, 830, 562, 6, 6)
    p.ell(130, 512, 90, 90, C["steel"]); p.hole(130, 512, 42, 42)      # eye end
    p.poly([(830, 440), (940, 410), (940, 614), (830, 584)], C["steel"])  # fork end
    p.hole(895, 512, 24, 24)
    p.line([(470, 440), (450, 400)], 8, fill=C["red"])                  # wrap of safety wire, red


@part
def trim_cable(p):  # coil of 7x19 cable with a thimble eye at one end
    for k in range(3):
        p.d.ellipse([140 + k * 40, 180 + k * 40, 760 - k * 40, 760 - k * 40], outline=INK, width=44)
        p.d.ellipse([140 + k * 40, 180 + k * 40, 760 - k * 40, 760 - k * 40], outline=C["alu"], width=24)
    p.line([(690, 680), (860, 820)], 44); p.line([(690, 680), (860, 820)], 24, fill=C["alu"])
    p.ell(890, 850, 80, 62, C["steel"]); p.hole(890, 850, 40, 30)
    p.rect(770, 720, 840, 780, C["red"], r=8)                            # swaged sleeve, red


def tie_rod(p, length, label):  # J-3 tail brace wire: rod with a fork end each side
    x0, x1 = 512 - length / 2, 512 + length / 2
    y0, y1 = 700, 300
    p.line([(x0 + 60, y0 - 30), (x1 - 60, y1 + 30)], 72, fill=INK)
    p.line([(x0 + 60, y0 - 30), (x1 - 60, y1 + 30)], 48, fill=C["steel"])
    for (x, y, s) in [(x0, y0, -1), (x1, y1, 1)]:
        p.poly([(x - 80 * s, y - 50), (x + 100 * s, y - 80), (x + 100 * s, y + 80), (x - 80 * s, y + 50)], C["steel_d"])
        p.hole(x + 50 * s, y, 22, 22)
    p.tag(512, 830, label)


@part
def brace_wires(p): tie_rod(p, 760, 'UPPER  41-3/4"')


@part
def tie_rod_lower(p): tie_rod(p, 600, 'LOWER  35"')


@part
def prop_bolts(p):  # six drilled-head bolts in a row with a coil of safety wire
    for i in range(6):
        x = 230 + i * 100
        p.rect(x - 22, 380, x + 22, 760, C["steel"], r=8)
        p.thread(x - 22, 620, x + 22, 760, 5, 5)
        p.hex(x, 360, 46, C["steel_d"], 0.6)
        p.hole(x, 360, 8, 6)
    p.d.ellipse([640, 700, 880, 860], outline=INK, width=18)
    p.d.ellipse([640, 700, 880, 860], outline=C["red"], width=8)        # safety wire, red


def can(p, label, label_col, w=230, h=420, cap="lid"):
    top, bot = 512 - h / 2, 512 + h / 2
    p.cyl(512, top, bot, w, w * 0.4, C["can"])
    p.d.rectangle([512 - w + 8, top + h * 0.3, 512 + w - 8, top + h * 0.75], fill=label_col)
    p.line([(512 - w, top + h * 0.3), (512 + w, top + h * 0.3)]); p.line([(512 - w, top + h * 0.75), (512 + w, top + h * 0.75)])
    f = font(int(w * 0.42), 900)
    p.d.text((512, top + h * 0.525), label, font=f, fill=INK if label_col != C["red"] else C["cream"], anchor="mm")
    if cap == "lid":
        p.ell(512, top, w * 0.55, w * 0.22, C["steel_d"])
    elif cap == "spout":
        p.cyl(512 + w * 0.45, top - 80, top, 40, 16, C["steel_d"])


@part
def dope(p): can(p, "DOPE", C["yellow"], 260, 360, "lid")   # pint can, Cub yellow label


@part
def preservative(p): can(p, "PRESERV.", C["green"], 230, 480, "spout")


@part
def grease(p):  # a tube, not a can: crimped end, cap
    p.poly([(220, 400), (720, 330), (740, 690), (220, 620)], C["red"])
    p.line([(220, 400), (220, 620)], OUT_W)
    p.poly([(160, 390), (240, 395), (240, 625), (160, 630)], C["steel"])   # crimp
    for y in range(410, 620, 40):
        p.line([(165, y), (235, y)], 6)
    p.rect(720, 440, 820, 580, C["black"], r=14)                            # cap
    p.d.text((470, 505), "GREASE", font=font(90, 900), fill=C["cream"], anchor="mm")


@part
def fuel_tank(p):  # J-3 nose tank: low rounded box, filler neck and float gauge wire
    p.poly([(160, 520), (300, 400), (860, 400), (880, 640), (740, 760), (180, 760)], C["alu"])
    p.line([(300, 400), (300, 520), (160, 520)]); p.line([(300, 520), (880, 520)])
    p.line([(740, 520), (740, 760)])
    p.cyl(520, 300, 400, 80, 30, C["steel"], C["red"])                      # filler cap, red
    p.line([(520, 300), (520, 160)], 10)                                    # float gauge wire
    p.ell(520, 150, 22, 22, C["cork"])


@part
def bleeder(p):  # brass bleeder screw: hex, thread, tip with side port
    p.hex(300, 512, 170, C["brass"], 1.0, 30)
    p.rect(450, 430, 720, 594, C["brass"], r=14)
    p.thread(450, 430, 720, 594, 7, 7)
    p.poly([(720, 450), (880, 480), (880, 544), (720, 574)], C["brass"])
    p.ell(300, 512, 60, 60, C["steel_d"]); p.hole(300, 512, 28, 28)       # drilled center
    p.hole(800, 512, 20, 16)
    p.rect(880, 470, 960, 554, C["red"], r=10)                              # rubber dust cap, red


@part
def tube_tire(p):  # inner tube: fat soft ring with the valve stem
    p.ring(512, 520, 420, 250, 140, C["rubber"])
    p.d.arc([512 - 350, 520 - 205, 512 + 350, 520 + 205], 200, 340, fill=C["rubber_l"], width=14)
    p.rect(495, 770, 530, 880, C["steel"], r=6)                             # valve stem
    p.ell(512, 890, 30, 14, C["red"])                                       # valve cap, red


@part
def stab_screw(p):  # stabilizer adjustment jack screw: long threaded shaft, nut block, end fitting
    p.rect(180, 450, 860, 574, C["steel"], r=16)
    p.thread(180, 450, 860, 574, 18, 7)
    p.rect(450, 330, 620, 694, C["steel_d"], r=20)                          # travelling nut block
    p.hole(535, 400, 26, 26)
    p.ell(140, 512, 100, 100, C["steel_d"]); p.hole(140, 512, 40, 40)
    p.hex(890, 512, 90, C["red"], 1.0, 30)                                  # drive end, red


@part
def baffle_seal(p):  # flexible seal strip: rubber strip with a row of rivet holes, curled edge
    p.poly([(140, 600), (880, 420), (900, 500), (160, 680)], C["orange"])
    p.poly([(160, 680), (900, 500), (880, 560), (190, 740)], C["red"])     # curled lip, red
    for i in range(7):
        x = 210 + i * 100; y = 620 - i * 24
        p.hole(x, y, 14, 10)


@part
def castle_cotter(p):  # castellated nut with a cotter pin through the slots
    pts = p.hex(512, 560, 230, C["steel"], 0.55)
    p.d.polygon([pts[0], pts[1], pts[2], pts[3], (pts[3][0], pts[3][1] + 90), (pts[2][0], pts[2][1] + 90), (pts[1][0], pts[1][1] + 90), (pts[0][0], pts[0][1] + 90)], fill=C["steel"])
    for q in pts[:4]:
        p.line([q, (q[0], q[1] + 90)], OUT_W)
    p.line([(q[0], q[1] + 90) for q in pts[:4]], OUT_W)
    p.cyl(512, 360, 560, 175, 82, C["steel"])                              # castellated crown
    for x in (440, 584):
        p.d.rectangle([x - 22, 360, x + 22, 470], fill=(0, 0, 0, 0))
        p.line([(x - 22, 380), (x - 22, 470), (x + 22, 470), (x + 22, 380)], IN_W)
    p.ell(512, 360, 175, 82, C["steel"]); p.hole(512, 360, 85, 40)
    p.line([(250, 430), (780, 430)], 40, fill=INK); p.line([(250, 430), (780, 430)], 22, fill=C["red"])  # cotter, red
    p.ell(225, 430, 40, 34, None, w=OUT_W)
    p.line([(780, 430), (860, 520)], 22, fill=C["red"]); p.line([(780, 430), (860, 340)], 22, fill=C["red"])


@part
def safety_wire(p):  # spool of .032 stainless safety wire with a twisted pigtail
    p.cyl(470, 360, 640, 250, 110, C["alu"], C["steel_d"])
    p.ell(470, 360, 250, 110, C["steel_d"]); p.hole(470, 360, 60, 26)
    for y in range(400, 640, 30):
        p.d.arc([220, y - 110, 720, y + 110], 0, 180, fill=C["steel"], width=6)
    pts = [(700, 500)] + [(740 + i * 30, 520 + (16 if i % 2 else -16)) for i in range(6)]
    p.line(pts, 14, fill=INK); p.line(pts, 6, fill=C["alu"])
    p.tag(470, 820, ".032")


@part
def icon_tire(p):  # 8.00 x 4 tire on its rim: smooth sidewall, a few tread ribs, hub
    p.ell(512, 512, 430, 400, C["rubber"])
    for r in (395, 360):
        p.d.ellipse([512 - r, 512 - r * 0.93, 512 + r, 512 + r * 0.93], outline=C["rubber_l"], width=8)
    p.ell(512, 512, 230, 214, C["rubber_l"])                    # sidewall
    p.ell(512, 512, 170, 158, C["alu"])                         # rim
    for i in range(6):
        t = 2 * math.pi * i / 6
        p.hole(512 + 115 * math.cos(t), 512 + 107 * math.sin(t), 16, 16)
    p.ell(512, 512, 62, 58, C["red"])                           # hub cap, red


@part
def icon_brakes(p):  # Goodyear expander-tube brake: torque flange, ring of lining blocks, tube inlet
    p.ell(512, 512, 420, 420, C["steel_d"])                     # torque flange
    n = 12
    for i in range(n):  # lining blocks around the rim
        a0 = 2 * math.pi * i / n + 0.06; a1 = 2 * math.pi * (i + 1) / n - 0.06
        pts = []
        for a in (a0, a1):
            pts.append((512 + 410 * math.cos(a), 512 + 410 * math.sin(a)))
        for a in (a1, a0):
            pts.append((512 + 320 * math.cos(a), 512 + 320 * math.sin(a)))
        p.poly(pts, C["cork"], w=IN_W)
    p.ring(512, 512, 320, 320, 50, C["rubber"])                # expander tube under the blocks
    p.ell(512, 512, 270, 270, C["steel"])
    p.hole(512, 512, 120, 120)                                 # axle hole
    for i in range(4):
        t = 2 * math.pi * i / 4 + math.pi / 4
        p.hole(512 + 195 * math.cos(t), 512 + 195 * math.sin(t), 22, 22)
    p.rect(470, 30, 554, 110, C["brass"], r=8)                 # tube inlet fitting
    p.hex(512, 120, 40, C["red"], 0.7)                          # inlet nut, red


def main(outdir):
    os.makedirs(outdir, exist_ok=True)
    for name, fn in D.items():
        p = Pen()
        fn(p)
        p.finish(os.path.join(outdir, name + ".png"))
    print(len(D), "icons")


if __name__ == "__main__":
    main(sys.argv[1])
