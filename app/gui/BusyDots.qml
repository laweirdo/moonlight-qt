import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// Three dots bouncing on one shared clock -- the app's only waiting indicator.
//
// This was written three times: once on the host tile, and twice more, byte for
// byte, in StreamSegue and QuitSegue. The two copies were also wrong. Each dot
// carried both a `y` binding for its resting place and a `SequentialAnimation on
// y`, which is an initial-value binding and a value source competing for one
// property; QML keeps the animation and discards the binding silently, so the
// dots rested wherever the animation's `from` happened to say rather than where
// the layout put them. HostTile.qml carries a comment explaining that it
// deliberately avoided exactly this fault. Declared once here, the way
// PopupMotion and EntranceMotion are, so there is one clock, one arch and one
// place to retune them.
//
// One looping NumberAnimation drives a phase from 0 to 1. Each dot reads its
// height off that phase with its own offset subtracted and wrapped, so the three
// are the same motion started at different times rather than three animations
// that can drift apart. sin over half a turn is one clean arch per period -- up,
// over, down, with the slow part at the top where a bounce wants it.
//
// The clock is Linear on purpose. The arch below does the easing; a curve here
// would ease the clock as well and the dots would separate.
// -----------------------------------------------------------------------------

Item {
    id: dots

    // Dot geometry. Defaulted to the carousel's measurements, which is where
    // this motion was first drawn; the segues pass their own, because their
    // sizes were settled separately and this file is not the place to change
    // what the client has already seen.
    property int dotSize: Bulan.hostTileBusyDotSize
    property int dotGap: Bulan.hostTileBusyDotGap
    property color dotColor: Bulan.accentPrimary

    // Callers gate this on whatever makes their surface a waiting one, so the
    // clock stops when the dots are not on screen.
    property bool running: visible

    implicitWidth: dotSize * 3 + dotGap * 2
    implicitHeight: dotSize + Bulan.motionBusyBounceHeight
    width: implicitWidth
    height: implicitHeight

    // No initializer: a declared real already defaults to 0, and giving it one
    // here as well as the animation's own `from: 0` combines an initial-value
    // binding with a value source on the same property, which qmllint flags as
    // [duplicate-property-binding]. That is the fault this file exists to end.
    property real phase

    NumberAnimation on phase {
        running: dots.running
        from: 0
        to: 1
        duration: Bulan.motionBusyBounceMs
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    Repeater {
        model: 3

        Rectangle {
            width: dots.dotSize
            height: width
            radius: width / 2
            color: dots.dotColor

            x: index * (dots.dotSize + dots.dotGap)
            y: dots.height - height - lift

            property real lift: {
                var p = dots.phase
                        - index * (Bulan.motionBusyStaggerMs / Bulan.motionBusyBounceMs)
                p -= Math.floor(p)
                return Math.sin(p * Math.PI) * Bulan.motionBusyBounceHeight
            }
        }
    }
}
