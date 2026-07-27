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
//             { action: "alternate", label: qsTr("Wake"), visible: !host.online }
//         ]
//         rightHints: [
//             { action: "start", label: qsTr("Client Settings") }
//         ]
//     }
//
// A hint may set `visible: <expression>` to appear only in the states where its
// button actually does something. Bindings whose keycode is live but whose
// action is a no-op right now are the failure this exists for: the bar promised
// Wake on a host that was already awake, so pressing it did nothing and read as
// a broken button. A hint bar that shows an action you cannot take is worse
// than one that shows less.
//
// The filtering lives here rather than in each screen so that "which hints does
// this state show" is one mechanism rather than a per-screen habit.
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

    // Each entry:
    //   { action: string, label: string,
    //     emphasis: bool (optional), visible: bool (optional, default true) }
    //
    // emphasis marks the screen's primary action and draws it in moonglow amber
    // while everything else stays in the quiet tone. Per-item rather than a rule
    // like "confirm is always emphasised", because which action leads is the
    // screen's decision, not this component's.
    property var leftHints: []
    property var rightHints: []

    // Entries whose `visible` is not false, in declared order. A hint with no
    // `visible` key is shown -- conditional is opt-in, so an unconditional hint
    // stays a one-liner.
    //
    // These recompute whenever the source list rebinds, which is what makes the
    // bar track state: a screen writing `visible: !host.online` rebuilds its
    // array when the host changes, and the filter follows.
    readonly property var visibleLeftHints: applicable(leftHints)
    readonly property var visibleRightHints: applicable(rightHints)

    function applicable(hints) {
        var out = []
        if (hints === undefined || hints === null) {
            return out
        }
        for (var i = 0; i < hints.length; i++) {
            var hint = hints[i]
            if (hint === undefined || hint === null) {
                continue
            }
            if (hint.visible === false) {
                continue
            }
            out.push(hint)
        }
        return out
    }

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
            model: root.visibleLeftHints
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
            model: root.visibleRightHints
            delegate: hintDelegate
        }
    }
}
