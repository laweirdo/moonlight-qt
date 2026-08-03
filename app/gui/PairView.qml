import QtQuick 2.9
// Imported for the StackView attached properties only -- no stock control
// from this module is instantiated anywhere on this screen.
import QtQuick.Controls 2.2

import SdlGamepadKeyNavigation 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// S3: pairing. Pushed by HostDiscovery.qml immediately after pairComputer()
// is called on the SAME ComputerModel instance that started it -- passed in
// as `computerModel` -- so this screen only ever listens for the one
// pairing it was created to watch, never a stray one belonging to a
// different host or a different visit to this screen.
//
// Fake-host review (MOONLIGHT_FAKE_HOSTS): no real pairComputer() call was
// ever made for a fake row -- see HostDiscovery.actSelect()'s guard, which
// follows HostCarousel.actConfirm()'s own -- so pairingCompleted never fires
// here and the screen simply holds on "Waiting for you to confirm…"
// indefinitely, which is exactly S3's static mockup.
//
// B (Escape) is not handled here on purpose, matching FirstRun.qml and
// HostDiscovery.qml: at stack depth 3 main.qml's central
// Keys.onEscapePressed already pops back to HostDiscovery -- "cancel" is
// simply leaving; the pairing attempt already sent is not recalled, the
// same way dismissing HostCarousel's pinPanel does not recall one either.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Bulan")
    focus: true

    property var computerModel: null
    property string hostUuid: ""
    property string hostName: ""
    property string pin: ""

    // "waiting" | "failed". Success never lingers in a state here at all --
    // it replaces the whole stack with HostCarousel immediately, the moment
    // HostCarousel's own pairingComplete() would have hidden its pinPanel.
    property string pairState: "waiting"

    function onPairingCompleted(error) {
        if (error !== undefined) {
            root.pairState = "failed"
            return
        }
        // Not left behind for B to return to: the whole onboarding chain
        // (FirstRun, HostDiscovery, this screen) is gone the instant pairing
        // succeeds, and HostCarousel is the only thing left on the stack.
        //
        // clear() then push(), not replace() in any form -- see
        // Splash.qml's proceed() for what actual key-delivery testing found
        // wrong with replace(null, ...) and its self-replace equivalent.
        // The push runs a normal forward transition since this is a real
        // screen change the player should see happen, not a boot-time swap.
        stackView.clear(StackView.Immediate)
        stackView.push("HostCarousel.qml")
    }

    function retry() {
        if (root.computerModel === null) {
            return
        }
        // Resolved by UUID rather than trusted from when this screen opened
        // -- discovery can reorder or drop rows in the meantime, the same
        // reason HostSettingsOverlay's actions re-resolve computerIndex
        // immediately before acting.
        var idx = root.computerModel.computerIndexForUuid(root.hostUuid)
        if (idx < 0) {
            // The host went away while this screen was up. Nothing left to
            // retry against.
            stackView.pop()
            return
        }
        var freshPin = root.computerModel.generatePinString()
        root.computerModel.pairComputer(idx, freshPin)
        root.pin = freshPin
        root.pairState = "waiting"
    }

    Component.onCompleted: {
        if (root.computerModel !== null) {
            root.computerModel.pairingCompleted.connect(root.onPairingCompleted)
        }
    }

    StackView.onActivated: {
        toolBar.visible = false
        SdlGamepadKeyNavigation.setUiNavMode(false)
        root.forceActiveFocus()
    }

    readonly property bool bulanScreen: true

    Item {
        anchors.fill: parent

        Atmosphere {
            anchors.fill: parent
        }

        Column {
            anchors.centerIn: parent
            spacing: Bulan.spaceLg
            width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                             Bulan.hostTileSize * 2.4)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.pairState === "failed" ? qsTr("Couldn't pair.") : qsTr("Almost there.")
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeDisplay
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                // Warm and brief either way, per AGENTS.md -- no technical
                // detail from whatever error string the backend produced.
                text: root.pairState === "failed"
                      ? qsTr("Check the PIN on %1 and try again.").arg(root.hostName)
                      : qsTr("Type this on %1:").arg(root.hostName)
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Bulan.spaceLg
                visible: root.pairState !== "failed"

                Repeater {
                    model: 4
                    Rectangle {
                        width: Bulan.pairPinTileWidth
                        height: Bulan.pairPinTileHeight
                        radius: Bulan.radiusMd
                        color: Bulan.bgSurface
                        border.width: 1
                        border.color: Bulan.hairline

                        Text {
                            anchors.centerIn: parent
                            text: index < root.pin.length ? root.pin.charAt(index) : ""
                            color: Bulan.accentPrimary
                            font.family: Bulan.familyDisplay
                            font.pixelSize: Bulan.sizeDisplay
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.pairState !== "failed"
                text: qsTr("Waiting for you to confirm…")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
            }
        }
    }

    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints: root.pairState === "failed"
        ? [ { action: "confirm", label: qsTr("Try again"), emphasis: true } ]
        : []
    readonly property var hintRightHints: [
        { action: "back", label: qsTr("Cancel") }
    ]

    Keys.onReturnPressed: if (root.pairState === "failed") root.retry()
    Keys.onEnterPressed: if (root.pairState === "failed") root.retry()
    Keys.onSpacePressed: function(event) {
        if (root.pairState === "failed") {
            root.retry()
        }
        event.accepted = true
    }
}
