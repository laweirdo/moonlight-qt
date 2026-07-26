#!/usr/bin/env python3
"""
Generates the two static textures used by gui/Atmosphere.qml.

Both textures encode *shape only* — the alpha channel carries the pattern and the
RGB is a flat colour. Strength is applied at runtime by the opacity tokens in
Bulan.qml, so the design system stays the single source of truth for intensity
and these files never need regenerating to retune the look.

Run from the repo root:

    python3 scripts/gen-atmosphere-textures.py

Outputs app/res/atmosphere-grain.png and app/res/atmosphere-vignette.png.
Uses only the standard library so it runs on any machine with python3, without
Pillow or ImageMagick installed.
"""

import os
import random
import struct
import zlib

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "app", "res")

# Grain tile. 128 is large enough that the repeat is not detectable by eye at
# 1280x800 (10 x 6.25 repeats) and small enough to stay a trivial texture upload.
GRAIN_SIZE = 128

# Vignette is stretched to fill the window, so it only needs enough resolution to
# stay smooth under bilinear filtering. 16:10 matches the Deck panel so the
# falloff is not distorted by non-uniform scaling.
VIGNETTE_W, VIGNETTE_H = 512, 320

# Deterministic output: regenerating must not produce a spurious diff.
GRAIN_SEED = 20260726


def write_png(path, width, height, rgba_rows):
    """Minimal RGBA8 PNG writer."""
    raw = bytearray()
    for row in rgba_rows:
        raw.append(0)  # filter type 0 (None)
        raw.extend(row)

    def chunk(tag, data):
        out = struct.pack(">I", len(data)) + tag + data
        return out + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)  # 8-bit RGBA
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as f:
        f.write(png)
    return len(png)


def gen_grain():
    """White speckle with uniform random alpha.

    One-sided (lightening only) rather than symmetric, because QML Image has no
    blend modes and a mid-grey texture composited normally would just wash the
    ground out. At the 3% token strength the peak lift on #0D1024 is about
    7/255 per channel -- invisible as a colour shift, but enough per-pixel
    jitter to break the gradient banding the brief warns about.
    """
    rng = random.Random(GRAIN_SEED)
    rows = []
    for _ in range(GRAIN_SIZE):
        row = bytearray()
        for _ in range(GRAIN_SIZE):
            row += bytes((255, 255, 255, rng.randrange(256)))
        rows.append(row)
    return rows


def gen_vignette():
    """Black, alpha ramping from centre to corners on an elliptical falloff.

    Alpha reaches full 255 at the corners; the 8% token is what makes it the
    "barely-there" edge darkening the brief asks for. The exponent biases the
    darkening outward so the centre two-thirds of the panel stays untouched --
    a linear ramp reads as an obvious dark cloud over the middle.
    """
    cx, cy = (VIGNETTE_W - 1) / 2.0, (VIGNETTE_H - 1) / 2.0
    rows = []
    for y in range(VIGNETTE_H):
        row = bytearray()
        ny = (y - cy) / cy
        for x in range(VIGNETTE_W):
            nx = (x - cx) / cx
            r = min(1.0, (nx * nx + ny * ny) ** 0.5 / (2.0 ** 0.5))
            a = int(round(255.0 * (r ** 2.5)))
            row += bytes((0, 0, 0, max(0, min(255, a))))
        rows.append(row)
    return rows


def main():
    out = os.path.normpath(OUT_DIR)
    os.makedirs(out, exist_ok=True)

    grain_path = os.path.join(out, "atmosphere-grain.png")
    n = write_png(grain_path, GRAIN_SIZE, GRAIN_SIZE, gen_grain())
    print("wrote %s (%dx%d, %d bytes)" % (grain_path, GRAIN_SIZE, GRAIN_SIZE, n))

    vig_path = os.path.join(out, "atmosphere-vignette.png")
    n = write_png(vig_path, VIGNETTE_W, VIGNETTE_H, gen_vignette())
    print("wrote %s (%dx%d, %d bytes)" % (vig_path, VIGNETTE_W, VIGNETTE_H, n))


if __name__ == "__main__":
    main()
