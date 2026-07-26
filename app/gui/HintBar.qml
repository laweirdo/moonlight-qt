import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// The persistent bottom bar telling the user what the buttons do on this screen.
//
// This is the answer to the single largest gap in upstream Moonlight: it has
// exactly one on-screen button hint in the whole application, on the streaming
// screen, and everything else is discoverable only by hovering a mouse over it.
// On a handheld that means undiscoverable.
//
// Contents are declarative, so each screen states its own:
//
//     HintBar {
//         leftHints: [
//             { action: "confirm",   label: qsTr("Connect"), emphasis: true },
//             { action: "alternate", label: qsTr("Wake") }
//         ]
//         rightHints: [
//             { action: "start", label: qsTr("Client Settings") }
//         ]
//     }
//
// Two lists rather than one with a side flag, because left and right are
// genuinely separate groups: the left is what you do to the thing in front of
// you, the right is where you go from here.
//
// Hints name a SEMANTIC ACTION, never a letter -- "confirm", not "A". See
// ControllerGlyph: the glyph redraws itself for whatever controller is attached,
// and the letter shown is never the caller's concern.
//
// DISPLAY ONLY. It declares no input handlers and nothing inside it is focusable,
// so it never appears in the focus chain and cannot be navigated into. It reports
// the bindings; it is not one of them.
// -----------------------------------------------------------------------------

Item {
    id: root

    // Each entry: { action: string, label: string, emphasis: bool (optional) }
    //
    // emphasis marks the screen's primary action and draws it in moonglow amber
    // while everything else stays in the quiet tone. Per-item rather than a rule
    // like "confirm is always emphasised", because which action leads is the
    // screen's decision, not this component's.
    property var leftHints: []
    property var rightHints: []

    implicitHeight: Bulan.targetRowHeight

    // A single hairline is the whole of the division. No filled band: the
    // atmosphere gradient is already at its darkest here, so the bar reads as
    // separate without a second surface competing with it.
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Bulan.hairline
    }

    // One hint: glyph, then label, tied together.
    Component {
        id: hintDelegate

        Row {
            spacing: Bulan.spaceXs

            // Guard against a malformed entry rather than rendering a broken
            // image and an empty label.
            readonly property bool _valid: modelData !== undefined
                                           && modelData.action !== undefined
            readonly property string _tone: (modelData && modelData.emphasis)
                                            ? "focus" : "unfocused"

            ControllerGlyph {
                anchors.verticalCenter: parent.verticalCenter
                visible: parent._valid
                action: parent._valid ? modelData.action : "confirm"
                tone: parent._tone
                glyphSize: Bulan.sizeBodyLg
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (modelData && modelData.label !== undefined) ? modelData.label : ""
                // Always the quiet tone, including on the emphasised hint: only
                // the glyph carries the amber. The label is the same kind of
                // information on every hint, so colouring it too would make the
                // primary action shout rather than lead.
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeLabel
            }
        }
    }

    Row {
        id: leftGroup
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Bulan.spaceXl

        Repeater {
            model: root.leftHints
            delegate: hintDelegate
        }
    }

    Row {
        id: rightGroup
        anchors.right: parent.right
        anchors.rightMargin: Bulan.layoutScreenMarginX
        anchors.verticalCenter: parent.verticalCenter
        spacing: Bulan.spaceXl

        Repeater {
            model: root.rightHints
            delegate: hintDelegate
        }
    }
}
