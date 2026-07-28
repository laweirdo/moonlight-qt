import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// One host in the carousel: a circular tile, with its name and status beneath it
// only when it is NOT the focused one.
//
// The focused host's name, status and address are drawn by the carousel's own
// detail block, lower down and larger. That split is why the label here hides
// itself when focused rather than growing: two sizes of the same information in
// two places would read as a duplicate rather than a promotion.
//
// Motion is brief §6. The scale is a single Behavior, deliberately: one animation
// that retargets when the value changes, so holding a direction tracks the input
// instead of queueing a settle per press, and nothing ever bounces twice.
// -----------------------------------------------------------------------------

Item {
    id: tile

    property string hostName: ""
    property bool online: false
    property bool paired: false
    property bool statusUnknown: false
    property bool wakeable: false
    property bool serverSupported: true
    property string address: ""
    property string details: ""

    property bool isCurrent: false

    // Interpolated along the PathView path, so neighbours are smaller.
    property real pathScale: 1.0

    signal activated()

    width: Bulan.hostTileSize
    height: Bulan.hostTileSize

    // Press feedback for controller input, which has no release event to hang a
    // state off. The mouse drives `pressed` directly; this is the button path.
    property bool pressed: mouse.pressed || pressFlash.running
    function flashPress() {
        pressFlash.restart()
    }
    Timer {
        id: pressFlash
        interval: Bulan.motionPressMs
    }

    // --- the tile ------------------------------------------------------------
    Rectangle {
        id: circle
        anchors.fill: parent
        radius: width / 2

        color: tile.online ? Bulan.bgSurface : Bulan.surfacePressed

        // The focus ring is always amber, online or not: focus has to read the
        // same everywhere or it stops being a reliable signal. Reachability is
        // carried by the status line and the halo instead.
        border.width: tile.isCurrent ? 2 : 1
        border.color: tile.isCurrent ? Bulan.accentPrimary : Bulan.hairline

        transformOrigin: Item.Center

        // Two scales multiplied, and only one of them is animated here.
        //
        // pathScale is already being interpolated by the PathView as the carousel
        // moves. Running it through a Behavior as well animated an animation: the
        // tile chased a value that was itself still moving, so the grow arrived
        // after the tile had finished travelling and read as a transform applied
        // on arrival rather than as the tile responding to the press.
        //
        // The interaction scale -- focus and press -- does change in one step, so
        // that is the part that wants easing.
        // NOT readonly: a Behavior has to write this to animate it, and marking it
        // readonly makes the whole tile fail to load -- which takes the carousel
        // with it and drops the app back to upstream's screen.
        property real interactionScale:
            tile.pressed ? Bulan.motionPressScale
                         : (tile.isCurrent ? Bulan.motionFocusScale : 1.0)

        Behavior on interactionScale {
            NumberAnimation {
                // Press is faster and flat; focus is slower with a hint of spring.
                duration: tile.pressed ? Bulan.motionPressMs : Bulan.motionFocusMs
                easing.type: tile.pressed ? Easing.OutCubic : Easing.OutBack
                easing.overshoot: Bulan.motionOvershoot
            }
        }

        scale: tile.pathScale * interactionScale

        Behavior on border.color {
            ColorAnimation { duration: Bulan.motionFocusMs }
        }

        // Placeholder for host artwork, which the model has no concept of yet.
        // The mockup marks this area "HOST ARTWORK"; a monogram fills it with
        // something meaningful in the meantime rather than a hatch pattern, and
        // needs no new asset. See SPEC-host-carousel.md.
        Text {
            anchors.centerIn: parent
            text: tile.hostName.length > 0 ? tile.hostName.charAt(0).toUpperCase() : "?"
            color: tile.online ? Bulan.textPrimary : Bulan.secondary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.hostTileSize * 0.42
            opacity: tile.online ? 0.85 : 0.5
        }
    }

    // --- neighbour label -----------------------------------------------------
    Column {
        id: labelBlock
        visible: !tile.isCurrent
        width: parent.width * 1.4
        anchors.horizontalCenter: parent.horizontalCenter
        // Sits below the circle's *scaled* edge, so it does not drift when the
        // neighbour scale changes.
        anchors.top: parent.verticalCenter
        anchors.topMargin: (tile.height / 2) * tile.pathScale + Bulan.spaceMd
        spacing: Bulan.space2xs

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.hostName
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeBodyLg
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.statusUnknown ? qsTr("Checking…")
                : !tile.online       ? qsTr("Offline")
                : !tile.paired       ? qsTr("Not paired")
                                     : qsTr("Ready")
            color: Bulan.secondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeBody
        }
    }

    // --- mouse ---------------------------------------------------------------
    // Click only. Hover deliberately does NOT move the selection -- client's
    // call, 28 July 2026, reversing the original design.
    //
    // The original reasoning was that hover should move focus so the pointer and
    // the D-pad could never disagree about what is selected. That assumed a still
    // carousel. These tiles move, and a moving view cannot tell the pointer
    // arriving at a tile apart from a tile arriving at the pointer: both raise
    // the same hover events at the same item. Acting on them turned one keypress
    // into a selection that walked away on its own.
    //
    // Two attempts were made to keep hover and filter the false events. The first
    // trusted `entered`; the second trusted `positionChanged` on the theory that
    // it only fires for real pointer movement. It does not -- the position it
    // reports is relative to the tile, so a tile sliding under a still cursor
    // changes it too. **There is no local signal that distinguishes them**, which
    // is the durable finding here: telling them apart needs the pointer tracked
    // in screen coordinates, above the level of any one item.
    //
    // Rather than build that on a controller-first screen, hover simply does not
    // steer any more. `hoverEnabled` stays off, so the false events are not even
    // generated.
    MouseArea {
        id: mouse
        anchors.fill: circle
        onClicked: tile.activated()
    }
}
