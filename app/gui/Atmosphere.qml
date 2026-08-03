import QtQuick 2.9

import Bulan 1.0
import StreamingPreferences 1.0

// -----------------------------------------------------------------------------
// The shared ground every Bulan screen sits on.
//
// Creative brief §4, "Depth, Not Darkness": the dark theme is built from
// gradation and texture rather than from black, so that it reads as dusk instead
// of a void. This consolidates that treatment into one place — previously the
// gradient was inline in main.qml's StackView.background and nothing else
// existed.
//
// Layer order is deliberate, bottom to top:
//
//   1. gradient  — sky into water, the reflection concept as a vertical fade
//   2. vignette  — draws the eye inward on a small panel
//   3. grain     — last, so it dithers the gradient *and* the vignette; this is
//                  what stops either showing colour banding on a dark ground
//
// The focused-element bloom is deliberately NOT here. The brief scopes that glow
// to "behind the focused element", which means it belongs to whichever component
// currently has focus and has to move with it — NavigableItemDelegate already
// draws its own. A screen-level bloom would be a second, unrelated glow.
//
// Purely decorative: declares no input handlers, so it never competes with the
// content above it for clicks or focus.
// -----------------------------------------------------------------------------

Item {
    id: root

    // Each effect is independently switchable, per the brief's non-negotiable.
    // Defaults come from the real, persisted preference (Settings > UI), added
    // in private v1 finalisation stage 5. Bulan.qml's own atmosphere*Enabled
    // tokens now only describe StreamingPreferences' own out-of-the-box
    // default and are read by nothing at runtime; override per instance as
    // needed -- main.qml's toolbar instance still forces gradient/vignette off
    // regardless of the user's preference.
    property bool gradientEnabled: StreamingPreferences.atmosphereGradientEnabled
    property bool vignetteEnabled: StreamingPreferences.atmosphereVignetteEnabled
    property bool grainEnabled:    StreamingPreferences.atmosphereGrainEnabled

    // --- 1. Vertical base gradient -------------------------------------------
    Rectangle {
        anchors.fill: parent
        visible: root.gradientEnabled
        gradient: Gradient {
            GradientStop { position: 0.0; color: Bulan.gradientBaseTop }
            GradientStop { position: 1.0; color: Bulan.gradientBaseBottom }
        }
    }

    // Turning the gradient off must not punch a transparent hole through the
    // window, so fall back to the flat base colour.
    Rectangle {
        anchors.fill: parent
        visible: !root.gradientEnabled
        color: Bulan.bgBase
    }

    // --- 2. Vignette ---------------------------------------------------------
    Image {
        anchors.fill: parent
        visible: root.vignetteEnabled
        opacity: Bulan.atmosphereVignetteOpacity

        source: "qrc:/res/atmosphere-vignette.png"

        // Stretched from 512x320 to the window, so it must filter smoothly —
        // the whole point is that no edge is visible anywhere.
        fillMode: Image.Stretch
        smooth: true
        cache: true
    }

    // --- 3. Film grain -------------------------------------------------------
    Image {
        anchors.fill: parent
        visible: root.grainEnabled
        opacity: Bulan.atmosphereGrainOpacity

        source: "qrc:/res/atmosphere-grain.png"

        // Tiled, never regenerated. Per-frame noise reads as video artifacting
        // and costs battery on a handheld; this is one static texture upload
        // that the GPU repeats.
        fillMode: Image.Tile

        // Never filter the noise. Bilinear sampling of a texture whose features
        // are one pixel wide turns grain into grey mush.
        smooth: false
        cache: true
    }
}
