import QtQuick 2.9

import Bulan 1.0
import SdlGamepadKeyNavigation 1.0
import StreamingPreferences 1.0

// -----------------------------------------------------------------------------
// One controller button glyph, drawn to match the controller in the user's hands.
//
// Takes a SEMANTIC ACTION, never a letter:
//
//     ControllerGlyph { action: "confirm" }
//
// so no screen ever hardcodes "A". The letter on the glyph is a function of the
// attached hardware and is resolved here; the meaning is a function of the screen
// and is all the caller has to know.
//
// --- The correctness rule ----------------------------------------------------
//
// SDL normalises every controller to an Xbox-style layout by PHYSICAL POSITION.
// The bottom face button is SDL_CONTROLLER_BUTTON_A on an Xbox pad, a DualSense
// and a Switch Pro Controller alike, even though it is lettered A, cross and B
// respectively. So:
//
//     the glyph changes; the binding does not.
//
// "confirm" is always the bottom button. On a Nintendo pad it draws a "B",
// because that is what is physically printed there -- and pressing it still
// confirms. Getting this backwards produces an interface that lies, which is why
// the mapping below is expressed in positions (b1..b4) and never in letters.
//
// --- One real exception ------------------------------------------------------
//
// Moonlight's "Swap A/B and X/Y gamepad buttons" preference rewrites the button
// in the SDL event before it is ever turned into a keypress
// (sdlgamepadkeynavigation.cpp). With it on, the physical bottom button really
// does stop being confirm -- confirm moves to the right-hand button. That is a
// genuine binding change rather than a relabelling, so the glyph has to follow
// it, or the hint bar would be telling the user to press the wrong button.
// -----------------------------------------------------------------------------

Item {
    id: root

    // Semantic action. Face buttons are the four positions; the rest are named
    // for what they are because their position is not in question.
    //
    //   confirm    bottom face button
    //   back       right face button
    //   options    left face button
    //   alternate  top face button
    //   start, select
    //   l1, r1     shoulder bumpers
    //   l2, r2     triggers
    property string action: "confirm"

    // Colour, chosen from the tone variants that exist on disk rather than set as
    // a colour. Valid values are the keys of VARIANTS in
    // scripts/import-controller-glyphs.py:
    //
    //   "unfocused"  Bulan.textSecondary  — the quiet default
    //   "focus"      Bulan.accentPrimary  — moonglow amber, for the one hint that
    //                                       is the screen's primary action
    //
    // It is a tone name and not a colour property because the art ships with the
    // fill already baked in, by a script that reads those tokens out of Bulan.qml
    // -- so the design system still owns the values, but they are fixed at import
    // time. Runtime tinting was tried and abandoned: a MultiEffect colorization
    // pass renders nothing under QT_QPA_PLATFORM=offscreen, which is how this
    // project screenshots screens for review, and it pulls in a Qt module that
    // would then have to exist inside the Flatpak. A third tone is a line in that
    // script plus a re-run.
    property string tone: "unfocused"

    property int glyphSize: Bulan.sizeBodyLg

    implicitWidth: glyphSize
    implicitHeight: glyphSize

    // --- action -> physical position -----------------------------------------
    readonly property var _actionToToken: ({
        "confirm":   "b1",
        "back":      "b2",
        "options":   "b3",
        "alternate": "b4",
        "start":     "start",
        "select":    "select",
        "l1":        "lb",
        "r1":        "rb",
        "l2":        "lt",
        "r2":        "rt"
    })

    // Face buttons under the swap preference. Only the four face positions move;
    // shoulders, triggers and start/select are untouched by it.
    readonly property var _swappedFaceToken: ({
        "b1": "b2",
        "b2": "b1",
        "b3": "b4",
        "b4": "b3"
    })

    readonly property string _token: {
        var t = _actionToToken[root.action]
        if (t === undefined) {
            // Unknown action name: fall through to the confirm glyph rather than
            // rendering a broken image, and say so once in the log.
            console.warn("ControllerGlyph: unknown action '" + root.action + "'")
            t = "b1"
        }
        if (StreamingPreferences.swapFaceButtons && _swappedFaceToken[t] !== undefined) {
            t = _swappedFaceToken[t]
        }
        return t
    }

    // Binding on glyphFamily, so hot-swapping a controller re-resolves the
    // source with no explicit refresh anywhere.
    readonly property string _source:
        "qrc:/res/glyphs/" + root.tone + "/"
        + SdlGamepadKeyNavigation.glyphFamily + "_" + _token + ".svg"

    Image {
        anchors.fill: parent
        source: root._source

        // Rasterise the SVG at the size it is actually drawn at, rather than
        // scaling a default-sized bitmap.
        sourceSize.width: root.glyphSize
        sourceSize.height: root.glyphSize
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
