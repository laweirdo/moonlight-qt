#!/usr/bin/env python3
"""
Imports the supplied controller glyph SVGs into app/res/glyphs/.

Run from the repo root, after dropping new art into the source directory:

    python3 scripts/import-controller-glyphs.py [SOURCE_DIR]

Default SOURCE_DIR is ~/Documents/Bulan/controller_glyphs.

FILENAME CONVENTION -- <family>_<token>.svg

  family  xinput | ds | switch | deck
  token   b1 b2 b3 b4 lb lt rb rt start select

The face buttons are numbered by PHYSICAL POSITION, never by letter:

    b1 = bottom    b2 = right    b3 = left    b4 = top

which is what makes the Nintendo swap correct for free -- xinput_b1 draws "A",
switch_b1 draws "B", ds_b1 draws a cross, and all three are the bottom button.
Nothing downstream ever needs to know which letter is printed on it.

Three normalisations are applied on the way in, each reversible by re-running
this script against corrected source art:

  1. Whitespace in filenames is stripped ("switch_ b4.svg" shipped with a space).
  2. Redundant <text> nodes are removed. switch_b2.svg carried both an outlined
     letter path AND a live <text> node for the same "A"; the live node depends
     on Avenir Next being installed and would render wrong or blank inside a
     Flatpak. The outline is already present, so dropping the text node is
     lossless.
  3. The artwork is recoloured. The source draws inconsistently -- most shapes
     are filled with no fill declared at all (so they default to black), while
     the PlayStation cross and the bumpers use a black stroke. Both fill and
     stroke are recoloured; a shape declaring fill:none keeps it, since giving an
     outline-only shape a fill turns it into a solid blob.

     The fill colour is READ OUT OF Bulan.qml rather than hardcoded here, so the
     design system remains the single source of truth: change the token, re-run
     this script, and the art follows.

     Baking the colour in rather than tinting at runtime is deliberate. The
     obvious alternative, a QtQuick MultiEffect colorization pass, needs a real
     shader pipeline -- it renders nothing under QT_QPA_PLATFORM=offscreen, which
     is exactly how this project's screenshot review workflow captures screens,
     and it adds a Qt module that then has to exist inside the Flatpak. The cost
     of baking is that a second colour (a dimmed or focused glyph, say) means
     generating a second variant.
"""

import os
import re
import sys

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT_DIR = os.path.normpath(os.path.join(REPO, "app", "res", "glyphs"))
DEFAULT_SRC = os.path.expanduser("~/Documents/Bulan/controller_glyphs")

# Families expected in the source art. "deck" is listed because the Deck's own
# glyphs are a future delivery; see resolveGlyphFamily() in
# gui/sdlgamepadkeynavigation.cpp for how it resolves until then. Absent families
# are reported, not fatal.
FAMILIES = ["xinput", "ds", "switch", "deck"]
TOKENS = ["b1", "b2", "b3", "b4", "lb", "lt", "rb", "rt", "start", "select"]

BULAN_QML = os.path.normpath(os.path.join(REPO, "app", "gui", "Bulan.qml"))

# Which design token the glyphs are drawn in.
FILL_TOKEN = "textPrimary"

# Elements that carry actual artwork.
#
# <path> only, deliberately. Every <rect> in this art set is either the canvas
# bounds (declared fill:none) or lives inside a <clipPath>, and filling the
# latter makes Qt's SVG renderer paint the clip rectangle itself -- a solid
# square covering the entire glyph. Verified across the set: no glyph draws any
# part of its shape with a rect.
ART_ELEMENTS = ("path",)


def read_token_colour(token):
    """Pull a colour token's value straight out of Bulan.qml."""
    src = open(BULAN_QML, encoding="utf-8").read()
    m = re.search(
        r"readonly\s+property\s+color\s+%s\s*:\s*[\"'](#[0-9A-Fa-f]{6})[\"']" % token, src
    )
    if not m:
        sys.exit("could not find colour token %r in %s" % (token, BULAN_QML))
    return m.group(1).upper()


def recolour(tag, colour):
    """Recolour one element tag, preserving self-closing syntax.

    The art set is not consistent about how it draws: most shapes are filled,
    but the PlayStation cross is 'fill:none; stroke:#000' and the bumper glyphs
    carry a thin black stroke on top of a fill. Both fill and stroke therefore
    have to be recoloured, and a shape declaring fill:none must keep it -- adding
    a fill to an outline-only shape turns it into a solid blob.
    """
    # Recolour an explicit stroke first. 'stroke-width' is not matched, because
    # the pattern requires the colon to follow 'stroke' directly.
    if re.search(r"stroke\s*:\s*(?!none)", tag):
        tag = re.sub(r"stroke\s*:\s*[^;\"']+", "stroke:" + colour, tag)
    if re.search(r'\bstroke\s*=\s*"(?!none)', tag):
        tag = re.sub(r'\bstroke\s*=\s*"[^"]*"', 'stroke="%s"' % colour, tag)

    # Outline-only shape: stroke is already handled, and it must not gain a fill.
    if re.search(r"fill\s*:\s*none", tag) or re.search(r'\bfill\s*=\s*"none"', tag):
        return tag

    # Already has a fill declaration: replace its value in place.
    if re.search(r"fill\s*:", tag):
        return re.sub(r"fill\s*:\s*[^;\"']+", "fill:" + colour, tag)
    if re.search(r'\bfill\s*=\s*"', tag):
        return re.sub(r'\bfill\s*=\s*"[^"]*"', 'fill="%s"' % colour, tag)

    # Has a style attribute but no fill: prepend into it.
    if 'style="' in tag:
        return tag.replace('style="', 'style="fill:%s;' % colour, 1)

    # No style at all. Insert a style attribute before the tag terminator,
    # keeping "/>" intact -- getting this wrong yields '<path ... / style=...>',
    # which parses as nothing and renders as nothing.
    if tag.endswith("/>"):
        return tag[:-2].rstrip() + ' style="fill:%s"/>' % colour
    return tag[:-1].rstrip() + ' style="fill:%s">' % colour


def normalise(svg, colour):
    """Strip redundant text nodes and recolour all artwork."""
    # 1. Drop <text>...</text> blocks (and any <tspan> inside them).
    svg = re.sub(r"<text\b.*?</text>", "", svg, flags=re.DOTALL)

    # 2. Recolour every artwork element.
    for el in ART_ELEMENTS:
        svg = re.sub(
            r"<%s\b[^>]*>" % el, lambda m: recolour(m.group(0), colour), svg
        )
    return svg


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SRC
    if not os.path.isdir(src):
        sys.exit("source directory not found: %s" % src)

    os.makedirs(OUT_DIR, exist_ok=True)

    fill = read_token_colour(FILL_TOKEN)
    print("fill colour: %s (Bulan.%s)" % (fill, FILL_TOKEN))

    # Index the source directory by (family, token), tolerating stray whitespace.
    found = {}
    for name in os.listdir(src):
        if not name.lower().endswith(".svg"):
            continue
        stem = os.path.splitext(name)[0]
        clean = re.sub(r"\s+", "", stem)
        if "_" not in clean:
            continue
        fam, _, tok = clean.partition("_")
        found[(fam, tok)] = name

    written, missing, renamed, textstripped, raster = 0, [], [], [], []
    for fam in FAMILIES:
        for tok in TOKENS:
            srcname = found.get((fam, tok))
            if srcname is None:
                missing.append("%s_%s" % (fam, tok))
                continue
            raw = open(os.path.join(src, srcname), encoding="utf-8").read()
            name = "%s_%s" % (fam, tok)
            if re.search(r"<text\b", raw):
                textstripped.append(name)
            # An <image> element means the "vector" is a wrapped bitmap: it will
            # not scale and cannot be recoloured. Flag it rather than silently
            # shipping a glyph that behaves unlike its neighbours.
            if re.search(r"<image\b", raw):
                raster.append(name)
            out = normalise(raw, fill)
            dest = os.path.join(OUT_DIR, "%s.svg" % name)
            open(dest, "w", encoding="utf-8").write(out)
            if re.sub(r"\s+", "", os.path.splitext(srcname)[0]) != os.path.splitext(srcname)[0]:
                renamed.append("%r -> %s.svg" % (srcname, name))
            written += 1

    print("wrote %d glyphs to %s" % (written, OUT_DIR))
    if renamed:
        print("  whitespace stripped from filename:")
        for r in renamed:
            print("    " + r)
    if textstripped:
        print("  redundant <text> node removed: " + ", ".join(textstripped))
    if raster:
        print("  *** EMBEDDED BITMAP, not vector: %s" % ", ".join(raster))
        print("      will not scale and ignores the fill colour -- needs re-export")
    if missing:
        print("  not supplied (%d): %s" % (len(missing), ", ".join(missing)))
        print("  -> resolved by resolveGlyphFamily() in gui/sdlgamepadkeynavigation.cpp")


if __name__ == "__main__":
    main()
