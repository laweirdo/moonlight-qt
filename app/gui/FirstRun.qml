import QtQuick 2.9
// Imported for the StackView attached properties only -- no stock control
// from this module is instantiated anywhere on this screen.
import QtQuick.Controls 2.2
import QtQuick.Effects

import ComputerManager 1.0
import SdlGamepadKeyNavigation 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// S1: first run, before any host has ever been found. "Look" pushes
// HostDiscovery.qml. The quiet link underneath is the escape hatch for a
// host on a different subnet, or one whose mDNS reply never arrives -- the
// same manual-address path HostCarousel's addPcPanel already uses, not a
// second implementation of it.
//
// B (Escape) is not handled here on purpose. This screen sits at stack
// depth 1, the same place HostCarousel sits once onboarding is behind you,
// and main.qml's central Keys.onEscapePressed already opens the quit
// dialog at that depth with no per-screen code needed -- exactly the
// behaviour this screen wants.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Bulan")
    focus: true

    function actLook() {
        root.settleEntrance()
        stackView.push("HostDiscovery.qml")
    }

    function actAddress() {
        root.settleEntrance()
        addressPanel.opened = true
    }

    StackView.onActivated: {
        SdlGamepadKeyNavigation.setUiNavMode(false)
        root.forceActiveFocus()
        // The transition is over: StackView sets Active once the screen has
        // stopped travelling, which is the moment the entrance is waiting for.
        root.entranceStarted = true
    }

    readonly property bool bulanScreen: true

    // --- post-transition entrance ---
    //
    // Mark, headline, supporting line, button, then the address escape hatch:
    // the order the player reads them in. See EntranceMotion.qml.
    //
    // Started by the transition itself rather than by a timer set to the
    // transition's duration. The timer only matched the transition when the push
    // was punctual; a slow one -- a first frame, an asset load -- left the
    // entrance playing underneath a screen that was still moving, which is
    // exactly what EntranceMotion.qml says must never happen.
    property bool entranceStarted: false

    EntranceMotion { id: markMotion;    order: 0; started: root.entranceStarted }
    EntranceMotion { id: titleMotion;   order: 1; started: root.entranceStarted }
    EntranceMotion { id: bodyMotion;    order: 2; started: root.entranceStarted }
    EntranceMotion { id: buttonMotion;  order: 3; started: root.entranceStarted }
    EntranceMotion { id: addressMotion; order: 4; started: root.entranceStarted }

    function settleEntrance() {
        markMotion.settle()
        titleMotion.settle()
        bodyMotion.settle()
        buttonMotion.settle()
        addressMotion.settle()
    }

    // Focus recovery, HostCarousel.qml's own pattern: the manual-address
    // panel is the only overlay this screen ever opens, and closing it must
    // not leave A dead the way defect 1 did there.
    onActiveFocusChanged: {
        if (!activeFocus && StackView.status === StackView.Active) {
            Qt.callLater(reclaimFocus)
        }
    }
    function reclaimFocus() {
        if (root.StackView.status !== StackView.Active) {
            return
        }
        if (addressPanel.visible) {
            return
        }
        root.forceActiveFocus()
    }

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

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/res/bulan_logomark.svg"
                width: Bulan.onboardingMarkSize
                height: width
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width * 2
                sourceSize.height: width * 2
                smooth: true
                opacity: markMotion.fadeOpacity
                transform: Translate { y: markMotion.riseOffset }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Let's find your PC.")
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeDisplay
                horizontalAlignment: Text.AlignHCenter
                opacity: titleMotion.fadeOpacity
                transform: Translate { y: titleMotion.riseOffset }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: qsTr("Make sure it's awake and on the same network.")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
                opacity: bodyMotion.fadeOpacity
                transform: Translate { y: bodyMotion.riseOffset }
            }

            // --- primary button ---------------------------------------------
            Item {
                id: lookButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(Bulan.hostTileSize * 0.7,
                                 lookLabel.implicitWidth + Bulan.space2xl * 2)
                height: Math.max(Bulan.targetMin,
                                  lookLabel.implicitHeight + Bulan.spaceLg * 2)

                // Press feedback for controller input, which has no release
                // event to hang a state off -- HostTile.flashPress()'s own
                // pattern.
                property bool pressed: lookMouse.pressed || pressFlash.running
                function flashPress() {
                    pressFlash.restart()
                }
                Timer {
                    id: pressFlash
                    interval: Bulan.motionPressMs
                }

                // Entrance rise rides alongside the press scale rather than
                // fighting it: `scale` and the transform list compose, so a
                // press landing mid-entrance still squashes the button while it
                // is still rising.
                opacity: buttonMotion.fadeOpacity
                transform: Translate { y: buttonMotion.riseOffset }

                scale: lookButton.pressed ? Bulan.motionPressScale : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: lookButton.pressed ? Bulan.motionPressMs : Bulan.motionFocusMs
                        easing.type: lookButton.pressed ? Easing.OutCubic : Easing.OutBack
                        easing.overshoot: Bulan.motionOvershoot
                    }
                }

                Rectangle {
                    id: lookSurface
                    anchors.fill: parent
                    radius: Bulan.radiusLg
                    color: Bulan.accentPrimary

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Bulan.accentGlow
                        shadowBlur: Bulan.buttonGlowBlur
                        shadowOpacity: Bulan.buttonGlowOpacity
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }

                    Text {
                        id: lookLabel
                        anchors.centerIn: parent
                        text: qsTr("Look")
                        // Dark text on the amber fill, per the mockup -- the
                        // only place on this screen where text sits on a
                        // light ground rather than the dark atmosphere.
                        color: Bulan.bgBaseOled
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBodyLg
                        font.bold: true
                    }
                }

                MouseArea {
                    id: lookMouse
                    anchors.fill: parent
                    onClicked: {
                        lookButton.flashPress()
                        root.actLook()
                    }
                }
            }

            Text {
                id: addressLink
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Enter an address instead")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeLabel
                opacity: addressMotion.fadeOpacity
                transform: Translate { y: addressMotion.riseOffset }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Bulan.spaceSm
                    onClicked: root.actAddress()
                }
            }
        }
    }

    // --- hint bar --------------------------------------------------------
    // "Enter address" has no visible glyph in the mockup, which only shows
    // this screen's single state. It is still bound to X and surfaced here
    // regardless -- AGENTS.md's controller-first invariant is permanent and
    // outranks a mockup that shows one screenshot, not every binding, and a
    // real binding missing from the hint bar is the exact failure HintBar
    // exists to prevent. HostCarousel's own "Add a PC" is the same shape.
    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints: [
        { action: "confirm", label: qsTr("Continue"), emphasis: true },
        { action: "options", label: qsTr("Enter address") }
    ]
    readonly property var hintRightHints: []

    // Any key ends the entrance early. Deliberately does not set
    // event.accepted -- it only stops an animation, and swallowing the press
    // would eat A, X, and the Escape main.qml pops on. The two act* functions
    // settle as well, because Qt delivers the specific key signals below
    // independently of this handler.
    Keys.onPressed: function(event) {
        root.settleEntrance()
    }

    // A. Three keycodes for one button, matching HostCarousel.actConfirm()'s
    // own reasoning: Return and Enter are the same press on different
    // keyboards, and Space is what A becomes while the settings page's tab
    // chain is armed.
    Keys.onReturnPressed: actLook()
    Keys.onEnterPressed: actLook()
    Keys.onSpacePressed: function(event) {
        actLook()
        event.accepted = true
    }

    // X, matching HostCarousel's own use of Menu for "Add a PC".
    Keys.onMenuPressed: function(event) {
        actAddress()
        event.accepted = true
    }

    HostPanel {
        id: addressPanel
        anchors.fill: parent
        title: qsTr("Add a PC")
        body: qsTr("Type its address.")
        editable: true
        // Steam on-screen keyboard: UNVALIDATED on this branch. This reuses
        // HostPanel exactly as HostCarousel.addPcPanel does, unmodified --
        // HostPanel is shared, not owned by this task. Its own
        // onVisibleChanged already forceActiveFocus()es the field the instant
        // it opens (HostPanel.takeInput()), which is the one thing already in
        // place to help the Game Mode OSK appear; there is no Deck or
        // physical controller here to confirm that it actually does.
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
        onSubmitted: {
            if (text) {
                ComputerManager.addNewHostManually(text.trim())
            }
        }
    }
}
