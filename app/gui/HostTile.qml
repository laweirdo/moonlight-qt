import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// One host in the carousel: a circular tile with its own name, status and
// address directly beneath it. The whole thing travels as one object.
//
// The text used to be drawn twice -- a small name and status under the unfocused
// tiles here, and the focused host's name, status and address separately by the
// carousel, larger and near the bottom of the screen. Client's call, 28 July
// 2026: the text belongs to the tile. So there is now one text per host which
// GROWS and BRIGHTENS as its tile takes focus, and travels with it.
//
// It sits a fixed gap below the circle's *drawn* edge rather than at a fixed
// screen position, which is what the client asked for -- the old focused block
// sat low and disconnected from the host it described.
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
    property string uuid: ""

    property bool isCurrent: false

    // What this host is currently waiting on: "" | "connecting" | "waking" |
    // "wakeFailed". Owned by the carousel, which is what knows about connections
    // and wake attempts; the tile only draws it.
    //
    // It was a bool called `connecting` until the wake state needed the same
    // treatment. One property rather than two flags, because the states are
    // mutually exclusive by nature -- a host cannot be connecting and waking at
    // once -- and two bools would let that be expressed.
    property string busyKind: ""
    readonly property bool busy: tile.busyKind === "connecting"
                                 || tile.busyKind === "waking"

    // Set by the carousel: 1.0 for the focused tile, the neighbour scale for the
    // rest. The carousel animates it, so this is a plain value here -- see the
    // note on `interactionScale` below for why it is not eased twice.
    property real tileScale: 1.0

    // 0 while a neighbour, 1 while focused, animated by the carousel on the same
    // clock as the travel. Everything about the text that differs between the two
    // states is interpolated on this, so the label grows into focus rather than
    // switching size on arrival.
    property real focusAmount: 0

    // Linear blend between two colours. QML interpolates colours in animations
    // but gives no expression for it, and the label needs to follow focusAmount
    // rather than run an animation of its own -- two clocks on one transition is
    // the "animating an animation" fault that already cost this screen once.
    function mix(a, b, f) {
        return Qt.rgba(a.r + (b.r - a.r) * f,
                       a.g + (b.g - a.g) * f,
                       a.b + (b.b - a.b) * f,
                       a.a + (b.a - a.a) * f)
    }

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
        // tileScale is already being animated by the carousel, on the same clock
        // as the tile's travel. Running it through a Behavior here as well would
        // animate an animation: the tile would chase a value that was itself
        // still moving, so the grow would arrive after the tile had finished
        // travelling and read as a transform applied on arrival rather than as
        // the tile responding to the press. That was a real fault once.
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

        scale: tile.tileScale * interactionScale

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

        // --- waiting ---------------------------------------------------------
        // Both of these are children of the circle deliberately, so they inherit
        // its scale and the tile keeps reading as one object while it travels.
        // Client's call, 31 July 2026: the dots shrink with the tile rather than
        // holding a fixed size, so nothing changes size as you scroll past.

        // Dims the disc, inset by the border so the amber focus ring is NOT
        // dimmed. Focus has to read identically in every state or it stops being
        // a reliable signal -- a waiting host is still the host you are on.
        Rectangle {
            anchors.fill: parent
            anchors.margins: circle.border.width
            radius: width / 2
            color: Bulan.bgBaseOled
            visible: opacity > 0
            opacity: tile.busy ? Bulan.hostTileBusyDimOpacity : 0
            Behavior on opacity {
                NumberAnimation { duration: Bulan.motionFocusMs }
            }
        }

        // Three bouncing dots on one shared clock.
        //
        // One looping NumberAnimation drives a phase, and each dot reads its
        // height off that phase with an offset. No SequentialAnimation, which
        // keeps SPEC-host-carousel.md's statement about this screen true, and no
        // second clock -- the "animating an animation" fault noted above.
        Item {
            id: busyDots
            anchors.centerIn: parent
            visible: tile.busy
            width: Bulan.hostTileBusyDotSize * 3 + Bulan.hostTileBusyDotGap * 2
            height: Bulan.hostTileBusyDotSize + Bulan.motionBusyBounceHeight

            // No initializer: a declared real already defaults to 0, and giving
            // it one here as well as the animation's own `from: 0` combines an
            // initial-value binding with a value source on the same property,
            // which qmllint flags as [duplicate-property-binding].
            property real phase
            NumberAnimation on phase {
                running: busyDots.visible
                from: 0
                to: 1
                duration: Bulan.motionBusyBounceMs
                loops: Animation.Infinite
                // Linear: the arch below does the easing. A curve here would ease
                // the clock as well and the three dots would drift apart.
                easing.type: Easing.Linear
            }

            Repeater {
                model: 3
                Rectangle {
                    width: Bulan.hostTileBusyDotSize
                    height: width
                    radius: width / 2
                    color: Bulan.accentPrimary

                    x: index * (Bulan.hostTileBusyDotSize + Bulan.hostTileBusyDotGap)
                    y: busyDots.height - height - lift

                    // sin over half a turn is one clean arch per period: up,
                    // over, down, with the slow part at the top where a bounce
                    // wants it. The stagger is subtracted from the shared phase
                    // and wrapped, so each dot is the same motion started later.
                    property real lift: {
                        var p = busyDots.phase
                                - index * (Bulan.motionBusyStaggerMs / Bulan.motionBusyBounceMs)
                        p -= Math.floor(p)
                        return Math.sin(p * Math.PI) * Bulan.motionBusyBounceHeight
                    }
                }
            }
        }
    }

    // --- the host's own text -------------------------------------------------
    // Name, status and address, belonging to this tile and travelling with it.
    // Everything that differs between neighbour and focused is interpolated on
    // focusAmount, so this grows and brightens rather than switching.
    Column {
        id: labelBlock
        width: parent.width * 1.4
        anchors.horizontalCenter: parent.horizontalCenter

        // Anchored to the circle's DRAWN edge, not the tile's box. circle.scale
        // already carries the neighbour scale, the focus scale and the press
        // dip, so the gap below the artwork stays constant through all three
        // instead of the text drifting when any of them changes.
        anchors.top: parent.verticalCenter
        anchors.topMargin: (tile.height / 2) * circle.scale + Bulan.hostTileLabelGap
        spacing: Bulan.space2xs

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.hostName
            color: tile.mix(Bulan.textSecondary, Bulan.textPrimary, tile.focusAmount)
            // The display face throughout. The focused name already used it and
            // the neighbours did not; one text that grows into the other cannot
            // change typeface on the way, so the branded face wins.
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeBodyLg
                            + (Bulan.sizeTitleLg - Bulan.sizeBodyLg) * tile.focusAmount
            elide: Text.ElideRight
        }

        // Two status lines, cross-faded rather than one line that swaps text.
        //
        // The focused copy is brief §8 verbatim and is the app's voice -- "Ready
        // when you are." A neighbour cannot carry it: at neighbour size
        // "Couldn't reach Living-Room. Still on the same network?" wraps to two
        // lines and shouts louder than the host that IS selected. So the short
        // form is the neighbour's and the full form is the focused one, and they
        // trade places on the same clock as everything else.
        Item {
            width: parent.width
            height: Math.max(shortStatus.implicitHeight, fullStatus.implicitHeight)

            Text {
                id: shortStatus
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: tile.busyKind === "connecting" ? qsTr("Connecting…")
                    : tile.busyKind === "waking"     ? qsTr("Waking…")
                    : tile.busyKind === "wakeFailed" ? qsTr("Couldn't wake")
                    : tile.statusUnknown  ? qsTr("Checking…")
                    : !tile.online        ? qsTr("Offline")
                    : !tile.paired        ? qsTr("Not paired")
                                          : qsTr("Ready")
                color: Bulan.secondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
                opacity: 1.0 - tile.focusAmount
            }

            Text {
                id: fullStatus
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                // Brief §8 verbatim wherever it specifies a line.
                text: tile.busyKind === "connecting" ? qsTr("Connecting…")
                    : tile.busyKind === "waking"     ? qsTr("Waking %1. Give it a moment.").arg(tile.hostName)
                    : tile.busyKind === "wakeFailed" ? qsTr("Couldn't wake %1. It may still be asleep.").arg(tile.hostName)
                    : tile.statusUnknown  ? qsTr("Looking for your PC…")
                    : !tile.online        ? qsTr("Couldn't reach %1").arg(tile.hostName)
                    : !tile.paired        ? qsTr("Not paired yet.")
                                          : qsTr("Ready when you are.")
                // Red and green state only what is settled: unreachable, or
                // ready. The in-between states -- still looking, connecting,
                // waking, not yet paired -- are not a verdict, so they stay
                // neutral rather than claiming a success or a failure that has
                // not happened. A wake that gave up IS a verdict, so it is red.
                color: tile.busy || tile.statusUnknown  ? Bulan.textSecondary
                     : tile.busyKind === "wakeFailed"   ? Bulan.statusError
                     : !tile.online                     ? Bulan.statusError
                     : !tile.paired                     ? Bulan.textSecondary
                                                        : Bulan.statusSuccess
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBodyLg
                opacity: tile.focusAmount
            }
        }

        // The address is the focused host's alone -- it is detail, and repeating
        // it under every tile would compete with the names.
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.address
            color: Bulan.secondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeBody
            opacity: tile.focusAmount
            elide: Text.ElideRight
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
