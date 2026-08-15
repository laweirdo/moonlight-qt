import QtQuick 2.9

import Bulan 1.0

// Controller-first quit confirmation for the Bulan root carousel.
// Safe Cancel is selected on every open; B/Escape closes and restores focus.
FocusScope {
    id: overlay

    property int selectedChoice: 0

    signal quitRequested()
    signal dismissed()

    // `opened` is the intent, `visible` trails it: the panel stays on screen
    // until PopupMotion's exit animation has finished, which is what lets a
    // popup animate out instead of vanishing on the frame it was closed.
    // `enabled` follows the intent, not the presence, so a closing popup stops
    // taking input immediately.
    property bool opened: false
    visible: opened || popupMotion.progress > 0.001
    enabled: opened
    z: 300

    function open() {
        selectedChoice = 0
        opened = true
        forceActiveFocus()
        Qt.callLater(forceActiveFocus)
    }

    function close() {
        focus = false
        opened = false
        dismissed()
    }

    function moveLeft() {
        selectedChoice = Math.max(0, selectedChoice - 1)
    }

    function moveRight() {
        selectedChoice = Math.min(1, selectedChoice + 1)
    }

    function activateCurrent() {
        if (selectedChoice === 0) {
            close()
        } else {
            quitRequested()
        }
    }

    // The shared popup entrance -- see PopupMotion.qml. Every Bulan popup uses
    // this one object rather than its own copy of the animation.
    PopupMotion {
        id: popupMotion
        open: overlay.opened
    }

    Rectangle {
        anchors.fill: parent
        color: Bulan.popupScrim
        opacity: popupMotion.scrimOpacity

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: overlay.close()
        }
    }

    Rectangle {
        id: surface

        // Grows from motionPopupEnterScale past its resting size and settles
        // back once. Opacity is clamped in PopupMotion so only the scale
        // carries the overshoot.
        scale: popupMotion.surfaceScale
        opacity: popupMotion.surfaceOpacity

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Bulan.spaceLg
        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                        Bulan.hostTileSize * 2)
        height: content.implicitHeight + Bulan.spaceXl * 2
        radius: Bulan.radiusXl
        color: Bulan.popupGlassSurface
        border.width: Bulan.hairlineWidth
        border.color: Bulan.popupGlassBorder

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            anchors.centerIn: parent
            width: parent.width - Bulan.spaceXl * 2
            spacing: Bulan.spaceLg

            Text {
                width: parent.width
                text: qsTr("Quit Bulan?")
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitle
                font.letterSpacing: Bulan.trackingTitle
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                text: qsTr("Your streams and host list will be here next time.")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
                wrapMode: Text.Wrap
            }

            Row {
                width: parent.width
                spacing: Bulan.spaceMd

                Repeater {
                    model: [
                        { label: qsTr("Cancel"), destructive: false },
                        { label: qsTr("Quit"), destructive: true }
                    ]

                    delegate: Rectangle {
                        id: choiceButton

                        required property int index
                        required property var modelData

                        width: (content.width - Bulan.spaceMd) / 2
                        height: Bulan.targetRowHeight
                        radius: Bulan.radiusMd
                        color: choiceButton.index === overlay.selectedChoice
                               ? Bulan.surfaceHover : Bulan.surfacePressed
                        border.width: choiceButton.index === overlay.selectedChoice
                                      ? Bulan.focusRingWidth : 0
                        border.color: Bulan.accentPrimary

                        Text {
                            anchors.centerIn: parent
                            text: choiceButton.modelData.label
                            color: choiceButton.modelData.destructive
                                   ? Bulan.statusError : Bulan.textPrimary
                            font.family: Bulan.familyUi
                            font.pixelSize: Bulan.sizeBody
                            font.weight: Bulan.weightBody
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: overlay.selectedChoice = choiceButton.index
                            onClicked: {
                                overlay.selectedChoice = choiceButton.index
                                overlay.activateCurrent()
                            }
                        }
                    }
                }
            }
        }
    }

    // Declared, not drawn -- see GameOptionsOverlay.qml. This one is parented to
    // the window rather than to a screen, so main.qml reads it directly.
    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints: [
        { action: "confirm", label: qsTr("Select"), emphasis: true }
    ]
    readonly property var hintRightHints: [
        { action: "back", label: qsTr("Cancel") }
    ]

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Left"
        onActivated: overlay.moveLeft()
    }

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Right"
        onActivated: overlay.moveRight()
    }

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Return"
        onActivated: overlay.activateCurrent()
    }

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Enter"
        onActivated: overlay.activateCurrent()
    }

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Space"
        onActivated: overlay.activateCurrent()
    }

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Escape"
        onActivated: overlay.close()
    }

    Shortcut {
        enabled: overlay.visible
        context: Qt.ApplicationShortcut
        sequence: "Back"
        onActivated: overlay.close()
    }

    Keys.onLeftPressed: function(event) {
        moveLeft()
        event.accepted = true
    }

    Keys.onRightPressed: function(event) {
        moveRight()
        event.accepted = true
    }

    Keys.onReturnPressed: function(event) {
        activateCurrent()
        event.accepted = true
    }

    Keys.onEnterPressed: function(event) {
        activateCurrent()
        event.accepted = true
    }

    Keys.onSpacePressed: function(event) {
        activateCurrent()
        event.accepted = true
    }

    Keys.onEscapePressed: function(event) {
        close()
        event.accepted = true
    }

    Keys.onBackPressed: function(event) {
        close()
        event.accepted = true
    }
}
