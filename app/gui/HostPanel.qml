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

    // When true, the panel offers a confirm action without a text field --
    // the "are you sure" shape, as opposed to the "here is something you need
    // to know" shape, which takes Close alone. An editable panel is always
    // confirmable, because submitting the field is the confirmation.
    property bool confirmable: false
    readonly property bool showsConfirm: panel.editable || panel.confirmable

    // Whether the panel that just closed was confirmed or only dismissed.
    // accept() always closes, so dismissed() fires on both routes; a caller
    // that has to act on "no" specifically -- a CLI route with nothing to
    // return to -- reads this rather than inferring it.
    property bool confirmed: false

    // What the field starts with. Empty for "enter an address", where there is
    // nothing to start from; the current name for a rename, where retyping a
    // name you are only editing would be busywork. Applied by show(), not bound,
    // so a caller changing it later cannot overwrite what is being typed.
    property string initialText: ""

    // The confirm hint's wording. "Add" is right for the address panel and wrong
    // for anything else, and this panel is now used for more than one thing.
    property string confirmLabel: qsTr("Add")

    // The dismiss hint's wording. "Close" everywhere unless a caller says
    // otherwise -- deliberately NOT switched to "Cancel" on confirmable panels,
    // which would have quietly reworded the address panel the client has
    // already reviewed. Copy is the client's, including this word.
    property string dismissLabel: qsTr("Close")

    signal submitted(string text)

    // Confirmed rather than dismissed. Separate from submitted() because a
    // panel with no field has nothing to submit, and separate from dismissed()
    // because "yes" and "go away" must never be the same event -- that is the
    // distinction a stock Dialog gets from Ok/Cancel and the reason this panel
    // could not replace one until now.
    signal accepted()

    signal dismissed()

    // `opened` is the intent, `visible` trails it, so this panel animates out
    // instead of vanishing -- see PopupMotion.qml. This is the panel the
    // onboarding screens raise for "Enter an address instead", which had no
    // motion at all (client review, 3 August 2026).
    property bool opened: false
    visible: opened || popupMotion.progress > 0.001
    // 200, the same as every other Bulan popup. This was 100, from before there
    // was a second popup to stack against.
    z: 200

    // The shared popup entrance. Every Bulan popup uses this one object rather
    // than its own copy of the animation.
    PopupMotion {
        id: popupMotion
        open: panel.opened
    }

    // This panel carries its hints inside its own card, below the field, where
    // they belong to the card rather than to the window. So it owns the hint
    // bar while it is open and asks for nothing to be drawn -- which is what
    // takes the screen's own bar off the screen underneath. Before this, the
    // onboarding screens kept printing their hints under an open panel.
    readonly property bool hintBarVisible: false
    readonly property var hintLeftHints: []
    readonly property var hintRightHints: []

    // A hidden panel must not be able to hold focus. Qt will not give active
    // focus to a disabled item, and relinquishes it if an item holding focus
    // becomes disabled -- so this is what stops focus being trapped on a panel
    // that has closed, which leaves the screen underneath listening to nothing.
    enabled: opened

    function show(t, b) {
        title = t
        body = b
        confirmed = false
        field.text = panel.initialText
        // Selected, not just placed: the whole point of starting from the
        // current name is that typing replaces it, while a deliberate press
        // still lets it be edited.
        field.selectAll()
        opened = true
        panel.forceActiveFocus()
    }

    function takeInput() {
        panel.forceActiveFocus()
        if (editable) {
            field.forceActiveFocus()
            // forceActiveFocus() alone does not invoke a platform on-screen
            // keyboard: Qt Quick only opens one itself in response to a real
            // mouse/touch press on the TextInput, which gamepad navigation
            // never generates (SdlGamepadKeyNavigation delivers synthetic key
            // events, not pointer events). Asking explicitly is what a real
            // touch tap would have triggered implicitly.
            Qt.inputMethod.show()
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

        if (editable) {
            Qt.inputMethod.hide()
        }

        opened = false
        field.text = ""
        dismissed()
        // Hand focus back to the screen beneath, or the D-pad stops working.
        if (parent) {
            parent.forceActiveFocus()
        }
    }

    function accept() {
        // A panel that offers neither a field nor a confirm action has nothing
        // to accept, so Return is inert on it rather than closing it by a route
        // its own hints never advertised.
        if (!panel.showsConfirm) {
            return
        }
        panel.confirmed = true
        if (editable) {
            submitted(field.text)
        }
        accepted()
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
        // The shared popup scrim, not a raw 0.72 over the OLED base. This panel
        // predates the glass treatment the client accepted on 3 August 2026 and
        // was the only popup still painting its own darkness, so it sat a shade
        // heavier than every other modal in the app.
        color: Bulan.popupScrim
        opacity: popupMotion.scrimOpacity
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: panel.close()
        }
    }

    // --- surface -------------------------------------------------------------
    Rectangle {
        id: surface

        // Grows from motionPopupEnterScale past its resting size and settles
        // back once. Opacity is clamped in PopupMotion so only the scale
        // carries the overshoot.
        scale: popupMotion.surfaceScale
        opacity: popupMotion.surfaceOpacity

        anchors.centerIn: parent
        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2, 640)
        height: content.implicitHeight + Bulan.spaceXl * 2
        // The glass surface, radius and border every other popup uses.
        radius: Bulan.radiusXl
        color: Bulan.popupGlassSurface
        border.width: Bulan.hairlineWidth
        border.color: Bulan.popupGlassBorder

        // Clicks on the panel itself must not fall through to the scrim.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - Bulan.spaceXl * 2
            spacing: Bulan.spaceMd

            // Guarded the same way the body below is: a panel raised with no
            // title must not reserve a line's worth of empty space above its
            // text. The configuration warnings in main.qml are exactly that --
            // a message with no headline, until the client writes one.
            Text {
                width: parent.width
                text: panel.title
                visible: text !== ""
                height: visible ? implicitHeight : 0
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
                border.width: field.activeFocus ? Bulan.focusRingWidth
                                                : Bulan.hairlineWidth
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
                    visible: panel.showsConfirm
                    ControllerGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        action: "confirm"
                        tone: "focus"
                        glyphSize: Bulan.sizeBodyLg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: panel.confirmLabel
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
                        text: panel.dismissLabel
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
