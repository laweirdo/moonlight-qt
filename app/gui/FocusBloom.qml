import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// The warm halo behind whatever is focused.
//
// Written out four times before this: once on the host carousel, twice in the
// game grid (Recent and Library), and once on the stock delegate that has since
// been deleted. Every copy carried the same five gradient stops, the same
// multipliers and the same scale-draw-unscale trick for a portrait tile, and
// every copy painted `Qt.rgba(1, 0.85, 0.63, ...)` -- an approximation of
// accentPrimary written by hand rather than the token itself.
//
// One instance per screen, not one per delegate. The focused item is the only
// thing that carries a halo, so the halo moves to it; it never has to be
// repainted, only positioned, which is why the callers animate x and y rather
// than asking this to redraw.
//
// A Canvas rather than a MultiEffect glow: this is a soft radial fill with a
// deliberately eased rolloff, and it is painted once into a texture and then
// left alone, where an effect would run a pass every frame.
// -----------------------------------------------------------------------------

Canvas {
    id: bloom

    // The bloom's colour. accentPrimary by default -- the moonglow amber the
    // whole focus language is built from.
    property color tint: Bulan.accentPrimary

    // Peak alpha at the centre. The stop multipliers below are relative to it,
    // so this one number controls the whole falloff.
    property real strength: Bulan.focusBloomOpacity

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onTintChanged: requestPaint()
    onStrengthChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var rx = width / 2
        var ry = height / 2

        // Drawn as a circle inside a scaled context rather than as an ellipse,
        // so a portrait tile gets a halo of its own proportions and a circular
        // host tile gets a circle, from the same code.
        ctx.save()
        ctx.translate(rx, ry)
        ctx.scale(1, ry / rx)

        var g = ctx.createRadialGradient(0, 0, 0, 0, 0, rx)
        var a = bloom.strength
        var c = bloom.tint

        // Eased rolloff. A linear alpha fade still reads as a visible disc edge
        // against a ground this dark.
        function stop(at, scale) {
            g.addColorStop(at, Qt.rgba(c.r, c.g, c.b, a * scale))
        }
        stop(0.00, 1.0)
        stop(0.30, 0.45)
        stop(0.55, 0.16)
        stop(0.78, 0.04)
        stop(1.00, 0.0)

        ctx.fillStyle = g
        ctx.beginPath()
        ctx.arc(0, 0, rx, 0, Math.PI * 2)
        ctx.fill()
        ctx.restore()
    }
}
