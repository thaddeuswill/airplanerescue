"""Cuts the downloaded CC0 packs into sounds/ (see CREDITS.md for sources) and renders the few
one clip no pack had (straw). Run with any Python that has numpy:
    python tools/prep_audio.py <folder holding the downloads and extracted x_* packs>
"""
import os
import shutil
import struct
import sys
import wave

import numpy as np

SRC = sys.argv[1]
OUT = os.path.join(os.path.dirname(__file__), "..", "sounds")
R = 44100
rng = np.random.default_rng(7)


def read(path):
    b = open(path, "rb").read()
    p = 12
    fmt = None
    while p < len(b) - 8:
        cid = b[p:p + 4]
        n = struct.unpack("<I", b[p + 4:p + 8])[0]
        if cid == b"fmt ":
            fmt = struct.unpack("<HHIIHH", b[p + 8:p + 24])
        if cid == b"data":
            d = b[p + 8:p + 8 + n]
            break
        p += 8 + n + (n & 1)
    kind, ch, rate, _, _, bits = fmt
    if kind == 3:
        a = np.frombuffer(d[:len(d) // (bits // 8) * (bits // 8)], dtype="<f4" if bits == 32 else "<f8").astype(np.float64)
    elif bits == 16:
        a = np.frombuffer(d[:len(d) // 2 * 2], dtype="<i2") / 32768.0
    elif bits == 24:
        u = np.frombuffer(d[:len(d) // 3 * 3], dtype=np.uint8).reshape(-1, 3).astype(np.int32)
        v = u[:, 0] | (u[:, 1] << 8) | (u[:, 2] << 16)
        a = np.where(v >= 1 << 23, v - (1 << 24), v) / float(1 << 23)
    else:
        raise ValueError(path)
    a = a.reshape(-1, ch).mean(1)
    if rate != R:
        a = np.interp(np.arange(0, len(a) * R / rate) * rate / R, np.arange(len(a)), a)
    return a


def write(name, a, loud=-20.0, trim=True, fade=0.04):
    """Saves a clip at a set loudness (dB of its loudest 100 ms), with peaks held under -3 dB."""
    if trim:  # start just before the first sound, stop once it has really died away
        e = np.abs(a)
        on = np.where(e > e.max() * 0.012)[0]
        a = a[max(0, on[0] - 200):min(len(a), on[-1] + int(R * 0.05))]
    n = int(R * 0.1)
    rms = max(np.sqrt((a[i:i + n] ** 2).mean()) for i in range(0, max(1, len(a) - n), n // 2))
    a = a * (10 ** (loud / 20) / max(1e-6, rms))
    a = a * min(1.0, 0.7 / max(1e-6, np.abs(a).max()))
    n = min(len(a), int(R * fade))
    a[-n:] *= np.linspace(1, 0, n)
    a[:64] *= np.linspace(0, 1, 64)
    p = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(R)
        w.writeframes((a * 32767).astype("<i2").tobytes())


def tone(a, pitch=1.0, cut=-10.0):
    """These were close-miked and tinny: drop the pitch for weight, and turn down the top end."""
    if pitch != 1.0:
        a = np.interp(np.arange(0, len(a) - 1, pitch), np.arange(len(a)), a)
    low = lowpass(a, 5000)
    a = low + (a - low) * 10 ** (cut / 20)
    return a - lowpass(a, 90)  # and take out rumble


def shop(n):
    return os.path.join(SRC, "x_workshop", "workshop", "workshop - %s.wav" % n)


def lowpass(a, hz):
    k = max(1, int(R / hz))
    return np.convolve(a, np.ones(k) / k, "same")


def band(n, lo, hi):
    a = rng.standard_normal(n)
    return lowpass(a, hi) - lowpass(a, lo)


# Recordings: name -> (source, loudness dB, pitch). Small sounds sit under big ones.
CUTS = {
    "ratchet": ("ratchet1", -24, 0.72), "torque_turn": ("ratchet2", -25, 0.8), "screw": ("quiet scrape", -28, 0.85),
    "scrape": ("scrapes", -25, 0.85), "wire": ("jingle3", -27, 0.8),
    "tray_1": ("clink1", -24, 0.8), "tray_2": ("clink2", -24, 0.8), "tray_3": ("clink3", -24, 0.8),
    "seat": ("dull ping", -26, 0.7), "snip": ("ping", -24, 0.9),
    "heavy_1": ("thuds", -14, 0.75), "heavy_2": ("wood on concrete", -14, 0.6), "part_1": ("metal clatter", -18, 0.8), "part_2": ("metal drop 3", -19, 0.65),
    "wood": ("wood clap", -18, 0.85), "tool": ("tool clatter", -26, 0.8),
}
for name, (src, loud, pitch) in CUTS.items():
    a = read(shop(src))
    if name == "heavy_2":
        a = a[:R]  # one knock, not the whole run of them
    write("sfx/%s.wav" % name, tone(a, pitch), loud)
for name, src, loud, pitch in [("thread_1", "lightclunk1", -25, 0.9), ("thread_2", "lightclunk2", -25, 0.9), ("breakfree", "squeakyclick1", -20, 0.8),
        ("latch", "squeakyclick2", -20, 0.85), ("click", "typewriter", -19, 0.7), ("crank", "mechanical1", -21, 0.7), ("jack", "clank1", -17, 0.8), ("deny", "lightclunk2", -29, 0.7)]:
    write("sfx/%s.wav" % name, tone(read(os.path.join(SRC, src + ".wav")), pitch, -4.0), loud)
for name, src in [("panel_1", "metal_sheet_01"), ("panel_2", "metal_sheet_02"), ("panel_3", "metal_sheet_03"), ("seat_panel_1", "metal_sheet_04"), ("seat_panel_2", "metal_sheet_05")]:
    shutil.copy(os.path.join(SRC, "x_100-CC0-wood-metal-SFX", src + ".ogg"), os.path.join(OUT, "sfx", name + ".ogg"))


def more(n):
    return read(os.path.join(SRC, "x_more", n + ".wav"))


# Real cloth, water and air (x_more holds wav copies of the clips from the two later packs).
gap = np.zeros(int(R * 0.12))
write("sfx/rag.wav", tone(np.concatenate([more("Cloth_01"), gap, more("Cloth_06"), gap, more("Cloth_02")]), 1.0, -3.0), -27, False)
write("sfx/sweep.wav", tone(np.concatenate([more("Cloth_03"), gap, more("Cloth_07")]), 1.25, -3.0), -29, False)
write("sfx/spray.wav", tone(more("sfx100v2_air_01"), 1.0, -5.0), -30, True, 0.1)
write("sfx/liquid.wav", more("sfx100v2_loop_water_02")[:R * 5], -26, False, 0.2)
puff = tone(more("sfx100v2_air_02"), 0.6, -6.0)[:int(R * 0.5)] * np.hanning(int(R * 0.5))  # one stroke of a hand pump
write("sfx/pump.wav", np.concatenate([np.concatenate([puff, np.zeros(int(R * 0.4))]) for _ in range(4)]), -24, False)

# Rendered here: no recording of straw in any pack.
N = R * 4
crackle = (rng.random(N) > 0.9985).astype(float)
write("sfx/rustle.wav", np.convolve(crackle * rng.standard_normal(N), np.exp(-np.arange(500) / 80), "same") + band(N, 800, 4000) * 0.15, -26, False)

# Hangar room tone: the fridge drone with its hum taken out, cross-faded end to start so it loops.
a = read(os.path.join(SRC, "x_legit_audio_-_the_shop_free_sfx_wav", "TheShopCollection_convenience_store_drinks_fridge_drone_2.wav"))
a = a - lowpass(a, 180)
n = R * 2
a = np.concatenate([a[n:-n], a[-n:] * np.linspace(1, 0, n) + a[:n] * np.linspace(0, 1, n)])
write("amb/room.wav", a, -30, False, 0.0001)

# Music, copied as it is; sound.gd evens out the track levels.
os.makedirs(os.path.join(OUT, "music"), exist_ok=True)
shutil.copy(os.path.join(SRC, "OneStepAtATIme.wav"), os.path.join(OUT, "music", "one_step_at_a_time.wav"))
shutil.copy(os.path.join(SRC, "LaDaDaGuitar_2.mp3"), os.path.join(OUT, "music", "la_da_da_guitar.mp3"))
shutil.copy(os.path.join(SRC, "apple_cider.ogg"), os.path.join(OUT, "music", "apple_cider.ogg"))
print("ok", sum(len(f) for _, _, f in os.walk(OUT)))
