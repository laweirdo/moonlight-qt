#!/usr/bin/env python3
"""Build the Windows .ico and the PNG sizes from Bulan's app-icon master.

Run from the repository root:

    python scripts/gen-app-icon.py <pixels.json>

The master is `app/res/bulan_app_icon.svg`. Its inner-shadow filter uses SVG
features Qt's own SVG renderer does not implement, so rasterising has to happen
in something that renders the full spec -- a browser -- rather than in this
script. That step produces a JSON array of

    [{"size": 32, "rgba": "<base64 of raw RGBA, row-major, top-down>"}, ...]

and this script turns that into the icon files the build actually consumes. The
split is deliberate: rasterising is the part that needs a real renderer, and
packing is the part that must be reproducible, so only the packing lives here.

Only the standard library is used, matching every other asset script in this
directory. See gen-atmosphere-textures.py, which writes PNG the same way.

Outputs:
    app/moonlight.ico    -- Windows, embedded in the exe via RC_ICONS
    app/moonlight_wix.png -- the installer's logo
"""

from __future__ import annotations

import base64
import json
import struct
import sys
import zlib
from pathlib import Path

# Windows shows these at 16 for the title bar, 32 for the taskbar and alt-tab,
# and 256 for large Explorer views. The rest are the intermediate scales it
# picks at fractional DPI; leaving them out makes it downscale 256 badly.
ICO_SIZES = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]

# Above this, ICO entries carry a PNG rather than a DIB. Windows Vista and
# later read both; the PNG form exists because a 256x256 BGRA bitmap plus its
# mask is a megabyte on its own.
PNG_THRESHOLD = 64


def write_png(rgba: bytes, size: int) -> bytes:
    """Minimal RGBA PNG. Same approach as gen-atmosphere-textures.py."""

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + tag
            + payload
            + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    raw = bytearray()
    stride = size * 4
    for y in range(size):
        raw.append(0)  # filter type 0, none
        raw += rgba[y * stride:(y + 1) * stride]

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )


def write_dib(rgba: bytes, size: int) -> bytes:
    """A BITMAPINFOHEADER DIB: BGRA bottom-up, then the 1bpp AND mask.

    The header claims double the real height because an icon DIB is defined as
    the colour image stacked on top of its mask. The mask is redundant for a
    32-bit icon -- the alpha channel already carries transparency -- but it is
    not optional, and some older shell paths still consult it, so it is written
    honestly from alpha rather than zeroed.
    """
    header = struct.pack(
        "<IiiHHIIiiII",
        40,          # header size
        size,        # width
        size * 2,    # height: colour plus mask
        1,           # planes
        32,          # bits per pixel
        0,           # BI_RGB, uncompressed
        0, 0, 0, 0, 0,
    )

    stride = size * 4
    colour = bytearray()
    for y in range(size - 1, -1, -1):  # bottom-up
        row = rgba[y * stride:(y + 1) * stride]
        for x in range(0, stride, 4):
            r, g, b, a = row[x], row[x + 1], row[x + 2], row[x + 3]
            colour += bytes((b, g, r, a))

    # AND mask: one bit per pixel, set where the pixel is fully transparent.
    # Rows pad to a 4-byte boundary.
    mask_stride = ((size + 31) // 32) * 4
    mask = bytearray()
    for y in range(size - 1, -1, -1):
        bits = bytearray(mask_stride)
        for x in range(size):
            if rgba[y * stride + x * 4 + 3] == 0:
                bits[x // 8] |= 0x80 >> (x % 8)
        mask += bits

    return header + bytes(colour) + bytes(mask)


def build_ico(images: dict[int, bytes]) -> bytes:
    entries = []
    payloads = []
    for size in sorted(images):
        rgba = images[size]
        if size >= PNG_THRESHOLD:
            payloads.append(write_png(rgba, size))
        else:
            payloads.append(write_dib(rgba, size))

    offset = 6 + 16 * len(payloads)
    for size, payload in zip(sorted(images), payloads):
        entries.append(
            struct.pack(
                "<BBBBHHII",
                0 if size >= 256 else size,  # 0 means 256
                0 if size >= 256 else size,
                0,   # no colour palette
                0,   # reserved
                1,   # planes
                32,  # bits per pixel
                len(payload),
                offset,
            )
        )
        offset += len(payload)

    return (
        struct.pack("<HHH", 0, 1, len(payloads))
        + b"".join(entries)
        + b"".join(payloads)
    )


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2

    root = Path.cwd()
    if not (root / "AGENTS.md").exists():
        print("error: run this from the repository root", file=sys.stderr)
        return 2

    data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    images: dict[int, bytes] = {}
    for entry in data:
        size = int(entry["size"])
        rgba = base64.b64decode(entry["rgba"])
        expected = size * size * 4
        if len(rgba) != expected:
            print(
                f"error: size {size} carried {len(rgba)} bytes, expected {expected}",
                file=sys.stderr,
            )
            return 1
        images[size] = rgba

    missing = [s for s in ICO_SIZES if s not in images]
    if missing:
        print(f"error: missing sizes {missing}", file=sys.stderr)
        return 1

    ico_path = root / "app" / "moonlight.ico"
    ico_path.write_bytes(build_ico({s: images[s] for s in ICO_SIZES}))
    print(f"wrote {ico_path.relative_to(root)} ({ico_path.stat().st_size} bytes)")

    wix_path = root / "app" / "moonlight_wix.png"
    wix_path.write_bytes(write_png(images[64], 64))
    print(f"wrote {wix_path.relative_to(root)} ({wix_path.stat().st_size} bytes)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
