import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// The one entrance every Bulan popup uses.
//
// Client review, 3 August 2026: popups appeared instantly, with no motion at
// all — the host menu, the settings pickers, the confirmations. Everything else
// in the app moves when it arrives, so a panel simply existing read as a
// dropped frame rather than as a deliberate choice.
//
// Declared once here rather than copied into each popup, per the motion rule in
// TASK-BRIEF.md: "centralise cadence, duration, travel distance and overshoot;
// no raw per-screen values, and no second near-identical copy of the same
// animation." Six popups share this file.
//
// Usage — bind `open` to the popup's own visibility, then read the outputs:
//
//     PopupMotion { id: motion; open: myPopup.visible }
//     Rectangle { ... opacity: motion.scrimOpacity }        // the scrim
//     Rectangle { ... scale: motion.surfaceScale
//                     opacity: motion.surfaceOpacity }      // the panel
//
// The panel grows from motionPopupEnterScale past its resting size and settles
// back, once, on Easing.OutBack — the same curve and the same overshoot token
// the game grid's tile entrance uses, so a popup arriving and a tile arriving
// feel like the same app.
//
// Closing does NOT bounce. An overshoot on the way out would push the panel
// briefly larger while the player is trying to leave, which reads as the popup
// resisting. Out is a plain ease, and faster than in.
// -----------------------------------------------------------------------------

QtObject {
    id: motion

    // Bind this to the popup's `visible`.
    property bool open: false

    // 0 while closed, 1 once settled. Passes above 1 mid-flight on the way in,
    // which is where the overshoot comes from.
    property real progress: 0

    // Scale for the panel itself. Inherits the overshoot, so this crosses 1.0
    // once and comes back.
    readonly property real surfaceScale:
        Bulan.motionPopupEnterScale
        + (1 - Bulan.motionPopupEnterScale) * progress

    // Clamped, so only the scale carries the overshoot. Without this a panel
    // would flash brighter than its settled opacity as it landed — the same
    // correction the grid's tile entrance needed.
    readonly property real surfaceOpacity: Math.min(1, progress)

    // The scrim fades with the panel but never overshoots, because a scrim
    // darker than its settled value would show as a flicker across the whole
    // screen rather than as motion on the panel.
    readonly property real scrimOpacity: Math.min(1, progress)

    // Not a Behavior on `progress`: a Behavior retargets from wherever the
    // value currently sits, so reopening a popup mid-close would start its
    // entrance from a half-faded panel. These two run to a fixed target from
    // whatever the state actually is, which is what makes a fast
    // open/close/open sequence land correctly every time.
    readonly property NumberAnimation enterAnimation: NumberAnimation {
        target: motion
        property: "progress"
        to: 1
        duration: Bulan.motionPopupEnterMs
        easing.type: Easing.OutBack
        easing.overshoot: Bulan.motionEntranceOvershoot
    }

    readonly property NumberAnimation exitAnimation: NumberAnimation {
        target: motion
        property: "progress"
        to: 0
        duration: Bulan.motionPopupEnterMs / 2
        easing.type: Easing.OutCubic
    }

    onOpenChanged: {
        enterAnimation.stop()
        exitAnimation.stop()
        if (open) {
            enterAnimation.start()
        } else {
            exitAnimation.start()
        }
    }
}
