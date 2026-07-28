import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// A modal overlay panel: scrim, surface, title, body, optionally one text field.
//
// Drawn from scratch rather than using Dialog from Qt Quick Controls, per the
// brief's "custom components only". The text field is a bare QtQuick TextInput,
// which is a primitive rather than a styled stock control.
//
// While open it holds active focus, which is what stops the screen underneath
// acting on the same buttons: the carousel's Keys handlers only fire when the
// carousel itself has focus. On close, focus is handed back explicitly -- without
// that, gamepad navigation dies after the first dialog, which is a bug upstream
// went to some trouble to work around in NavigableDialog.
// -----------------------------------------------------------------------------

FocusScope {
    id: panel

    property string title: ""
    property string body: ""

    // When true, shows a text field and emits submitted() with its contents.
    property bool editable: false

    signal submitted(string text)
    signal dismissed()

    visible: false
    z: 100

    // A hidden panel must not be able to hold focus. Qt will not give active
    // focus to a disabled item, and relinquishes it if an item holding focus
    // becomes disabled -- so this is what stops focus being trapped on a panel
    // that has closed, which leaves the screen underneath listening to nothing.
    enabled: visible

    function show(t, b) {
        title = t
        body = b
        visible = true
        panel.forceActiveFocus()
    }

    function takeInput() {
        panel.forceActiveFocus()
        if (editable) {
            field.forceActiveFocus()
        }
    }

    function close() {
        // Release this scope's focus BEFORE handing it back. A FocusScope gives
        // active focus to whichever child last held it, so leaving this set means
        // the parent hands focus straight back into a panel that is now invisible.
        // An invisible panel runs no key handlers, and neither does the screen
        // underneath, so every button the screen owns goes dead.
        field.focus = false
        panel.focus = false

        visible = false
        field.text = ""
        dismissed()
        // Hand focus back to the screen beneath, or the D-pad stops working.
        if (parent) {
            parent.forceActiveFocus()
        }
    }

    function accept() {
        if (editable) {
            submitted(field.text)
        }
        close()
    }

    onVisibleChanged: {
        if (visible) {
            takeInput()
        }
    }

    // --- scrim ---------------------------------------------------------------
    // Swallows clicks so the carousel underneath cannot be hovered or activated
    // through the overlay.
    Rectangle {
        anchors.fill: parent
        color: Bulan.bgBaseOled
        opacity: 0.72
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: panel.close()
        }
    }

    // --- surface -------------------------------------------------------------
    Rectangle {
        id: surface
        anchors.centerIn: parent
        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2, 640)
        height: content.implicitHeight + Bulan.spaceXl * 2
        radius: Bulan.radiusLg
        color: Bulan.bgSurface
        border.width: 1
        border.color: Bulan.hairline

        // Clicks on the panel itself must not fall through to the scrim.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - Bulan.spaceXl * 2
            spacing: Bulan.spaceMd

            Text {
                width: parent.width
                text: panel.title
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitle
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                text: panel.body
                visible: text !== ""
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
                wrapMode: Text.Wrap
            }

            // --- text field ---------------------------------------------------
            Rectangle {
                width: parent.width
                height: Bulan.targetMin
                visible: panel.editable
                radius: Bulan.radiusMd
                color: Bulan.surfacePressed
                border.width: field.activeFocus ? 2 : 1
                border.color: field.activeFocus ? Bulan.accentPrimary : Bulan.hairline

                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: Bulan.spaceMd
                    anchors.rightMargin: Bulan.spaceMd
                    verticalAlignment: TextInput.AlignVCenter
                    color: Bulan.textPrimary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBody
                    selectByMouse: true
                    selectionColor: Bulan.accentGlow
                    clip: true

                    Keys.onReturnPressed: panel.accept()
                    Keys.onEnterPressed: panel.accept()
                    Keys.onEscapePressed: panel.close()
                }
            }

            // --- hints --------------------------------------------------------
            Row {
                spacing: Bulan.spaceXl

                Row {
                    spacing: Bulan.spaceXs
                    visible: panel.editable
                    ControllerGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        action: "confirm"
                        tone: "focus"
                        glyphSize: Bulan.sizeBodyLg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Add")
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
                    }
                }

                Row {
                    spacing: Bulan.spaceXs
                    ControllerGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        action: "back"
                        glyphSize: Bulan.sizeBodyLg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Close")
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
                    }
                }
            }
        }
    }

    // Non-editable panels take the keys themselves; editable ones let the
    // TextInput have them so typing works.
    Keys.onEscapePressed: close()
    Keys.onReturnPressed: accept()
    Keys.onEnterPressed: accept()
}
