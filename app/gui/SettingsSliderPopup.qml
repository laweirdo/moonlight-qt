import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// The "Bitrate" popup pattern (client mockup 4): a small glass panel, the
// setting's display-face title with the live value beside it, and an amber
// track with a cream knob. Left/Right nudge the value by one step; there is no
// separate confirm, because the value it edits (bitrate) has always applied
// live while dragging on the upstream slider this replaces -- see
// SettingsView.qml's old `slider.onValueChanged` writing straight to
// StreamingPreferences on every tick. B or A both simply close the popup.
//
// Generic over any single ranged value, the same way SettingsChoicePopup is
// generic over any option list: SettingsShell.qml supplies min/max/step/value/
// format/onChanged and this component never has to know it is bitrate.
// -----------------------------------------------------------------------------

FocusScope {
    id: popup

    property string title: ""
    property real minValue: 0
    property real maxValue: 100
    property real stepValue: 1
    property real currentValue: 0
    property string formattedValue: ""
    // Optional: { label: string, value: real }. Hidden when null.
    property var resetTo: null

    // isReset distinguishes an explicit "reset to default" activation from an
    // ordinary nudge/drag, so the caller can restore its own "auto-adjust"
    // semantics (see SettingsShell.qml's bitrate row) only on the former --
    // exactly mirroring SettingsView.qml's old resetBitrateButton, which set
    // autoAdjustBitrate back to true while an ordinary slider drag turned it
    // off.
    signal changed(real value, bool isReset)
    signal dismissed()

    visible: false
    enabled: visible
    z: 200

    function open(opts) {
        title = opts.title || ""
        minValue = opts.min
        maxValue = opts.max
        stepValue = opts.step || 1
        currentValue = opts.value
        formattedValue = opts.formattedValue || ""
        resetTo = opts.resetTo || null
        visible = true
        forceActiveFocus()
    }

    function close() {
        focus = false
        visible = false
        dismissed()
    }

    function clamp(v) {
        return Math.max(minValue, Math.min(maxValue, v))
    }

    function nudge(direction) {
        var next = clamp(currentValue + direction * stepValue)
        if (next !== currentValue) {
            currentValue = next
            changed(currentValue, false)
        }
    }

    function applyReset() {
        if (resetTo === null) {
            return
        }
        currentValue = clamp(resetTo.value)
        changed(currentValue, true)
    }

    // The shared popup entrance -- see PopupMotion.qml. Every Bulan popup uses
    // this one object rather than its own copy of the animation.
    PopupMotion {
        id: popupMotion
        open: popup.visible
    }

    Rectangle {
        anchors.fill: parent
        color: Bulan.popupScrim
        opacity: popupMotion.scrimOpacity

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: popup.close()
        }
    }

    Rectangle {
        id: surface

        // Grows from motionPopupEnterScale past its resting size and settles
        // back once. Opacity is clamped in PopupMotion so only the scale
        // carries the overshoot.
        scale: popupMotion.surfaceScale
        opacity: popupMotion.surfaceOpacity

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2, Bulan.hostTileSize * 2.2)
        height: content.implicitHeight + Bulan.spaceXl * 2

        radius: Bulan.radiusXl
        color: Bulan.popupGlassSurface
        border.width: Bulan.space2xs / 4
        border.color: Bulan.popupGlassBorder

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - Bulan.spaceXl * 2
            spacing: Bulan.spaceLg

            Item {
                width: parent.width
                height: titleLabel.implicitHeight

                Text {
                    id: titleLabel
                    anchors.left: parent.left
                    text: popup.title
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                    font.letterSpacing: Bulan.trackingTitle
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: titleLabel.verticalCenter
                    text: popup.formattedValue
                    color: Bulan.secondary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBody
                }
            }

            // --- track -----------------------------------------------------
            // A bare Rectangle pair plus a knob, not Slider -- forbidden here.
            // Left/Right are the only input; there is no drag handle to grab
            // with a mouse, matching the controller-first requirement, though
            // a MouseArea below still lets a click-and-drag reviewer move it.
            Item {
                id: track
                width: parent.width
                height: Bulan.targetMin

                readonly property real fraction:
                    popup.maxValue > popup.minValue
                        ? (popup.currentValue - popup.minValue) / (popup.maxValue - popup.minValue)
                        : 0

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Bulan.space2xs
                    radius: height / 2
                    color: Bulan.hairline
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent.width * track.fraction
                    height: Bulan.space2xs
                    radius: height / 2
                    color: Bulan.accentPrimary

                    Behavior on width {
                        NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    id: knob
                    width: Bulan.spaceLg
                    height: Bulan.spaceLg
                    radius: width / 2
                    color: Bulan.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width,
                                             parent.width * track.fraction - width / 2))

                    Behavior on x {
                        NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: {
                        if (pressed) {
                            drag(mouseX)
                        }
                    }
                    onPressed: drag(mouseX)

                    function drag(mouseX) {
                        var fraction = Math.max(0, Math.min(1, mouseX / track.width))
                        var raw = popup.minValue + fraction * (popup.maxValue - popup.minValue)
                        var stepped = Math.round(raw / popup.stepValue) * popup.stepValue
                        var next = popup.clamp(stepped)
                        if (next !== popup.currentValue) {
                            popup.currentValue = next
                            popup.changed(next, false)
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: popup.resetTo !== null
                text: popup.resetTo !== null ? popup.resetTo.label : ""
                color: Bulan.accentPrimary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeLabel

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Bulan.spaceXs
                    onClicked: popup.applyReset()
                }
            }
        }
    }

    Keys.onLeftPressed: function(event) {
        nudge(-1)
        event.accepted = true
    }
    Keys.onRightPressed: function(event) {
        nudge(1)
        event.accepted = true
    }
    Keys.onUpPressed: function(event) { event.accepted = true }
    Keys.onDownPressed: function(event) { event.accepted = true }

    Keys.onReturnPressed: function(event) {
        close()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        close()
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
