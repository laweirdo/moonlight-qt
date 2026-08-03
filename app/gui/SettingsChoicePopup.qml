import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// The "Choose a Resolution" popup pattern (client mockup 3): a glass panel over
// the blurred settings screen, one column of rounded option rows, an optional
// pinned "Add X +" row first, a "Recommended" annotation on any row that
// carries it, and the focused row in the established amber outline.
//
// Deliberately generic -- SettingsShell.qml opens this same component for
// resolution, frame rate, audio configuration, display mode, video codec, and
// every other "pick one of a short list" row in the settings description list,
// following HostSettingsOverlay.qml's own precedent of one custom FocusScope
// owning its whole navigation rather than a stock Popup/Menu (forbidden here).
//
// Options are supplied fully resolved by the caller as
//   { label: string, value: var, note: string (optional),
//     recommended: bool (optional), current: bool (optional) }
// so this component never has to know what a resolution or a codec is -- it
// only ever compares by the caller-supplied `current` flag, never by identity
// or equality on `value`, because several rows (resolution, frame rate) hand
// back freshly-built option objects every time the popup opens.
//
// The optional "Add" row is a second, inline page of the same FocusScope
// (mirroring HostSettingsOverlay's page: "menu"/"confirm"/... shape) rather
// than a second popup, so Back always has exactly one place to return to.
// -----------------------------------------------------------------------------

FocusScope {
    id: popup

    property string title: ""
    property var options: []
    property bool addEnabled: false
    property string addLabel: qsTr("Add")
    property string addPromptTitle: qsTr("Add a value")
    property string addPromptBody: ""
    property string addPromptPlaceholder: ""

    signal selected(var value)
    signal addSubmitted(string text)
    signal dismissed()

    // `opened` is the intent, `visible` trails it: the panel stays on screen
    // until PopupMotion's exit animation has finished, which is what lets a
    // popup animate out instead of vanishing on the frame it was closed.
    // `enabled` follows the intent, not the presence, so a closing popup stops
    // taking input immediately.
    property bool opened: false
    visible: opened || popupMotion.progress > 0.001
    enabled: opened
    z: 200

    // "list" or "add". Not "confirm"/"feedback" like HostSettingsOverlay --
    // this popup never needs those, and inventing state it does not use would
    // just be surface area for a stray transition.
    property string page: "list"
    property int selectedIndex: 0

    readonly property int rowCount: (addEnabled ? 1 : 0) + options.length
    function isAddRow(i) { return addEnabled && i === 0 }
    function optionAt(i) { return options[addEnabled ? i - 1 : i] }

    function open(opts) {
        title = opts.title || ""
        options = opts.options || []
        addEnabled = opts.addEnabled === true
        addLabel = opts.addLabel || qsTr("Add")
        addPromptTitle = opts.addPromptTitle || qsTr("Add a value")
        addPromptBody = opts.addPromptBody || ""
        addPromptPlaceholder = opts.addPromptPlaceholder || ""

        selectedIndex = addEnabled ? 1 : 0
        for (var i = 0; i < options.length; i++) {
            if (options[i].current === true) {
                selectedIndex = (addEnabled ? 1 : 0) + i
                break
            }
        }

        page = "list"
        opened = true
        forceActiveFocus()
        // Scroll the already-selected row into view. Without this the list
        // always opens at the top while the selection sits wherever the
        // current value happens to be -- for a resolution list that is the
        // LAST row, so the one row the player needs to see opened half cut
        // off by the panel's bottom edge. Deferred because the Flickable has
        // no height yet during open(): ensureVisible() measured against a
        // zero-height viewport computes a meaningless contentY, which is the
        // same trap AppView.ensureLibraryFocusVisible() guards against.
        Qt.callLater(function() {
            listFlick.ensureVisible(popup.selectedIndex)
        })
    }

    function close() {
        focus = false
        opened = false
        addField.text = ""
        dismissed()
    }

    function activateCurrent() {
        if (page === "add") {
            if (addField.text.length > 0) {
                addSubmitted(addField.text)
            }
            return
        }
        if (rowCount === 0) {
            return
        }
        if (isAddRow(selectedIndex)) {
            page = "add"
            addField.forceActiveFocus()
            return
        }
        var option = optionAt(selectedIndex)
        if (option) {
            selected(option.value)
        }
    }

    function goBack() {
        if (page === "add") {
            page = "list"
            addField.text = ""
            popup.forceActiveFocus()
            return
        }
        close()
    }

    function moveSelection(step) {
        if (rowCount === 0) {
            return
        }
        selectedIndex = Math.max(0, Math.min(rowCount - 1, selectedIndex + step))
        listFlick.ensureVisible(selectedIndex)
    }

    // The shared popup entrance -- see PopupMotion.qml. Every Bulan popup uses
    // this one object rather than its own copy of the animation.
    PopupMotion {
        id: popupMotion
        open: popup.opened
    }

    Rectangle {
        anchors.fill: parent
        color: Bulan.popupScrim
        opacity: popupMotion.scrimOpacity

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: popup.goBack()
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

        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2, Bulan.hostTileSize * 2.6)
        // A fixed row budget, NOT listArea.height -- listArea's own height is
        // derived from content, which anchors.fill's this Rectangle, so
        // sizing this from listArea would be a binding loop (surface depends
        // on listArea depends on content depends on surface) that resolves
        // to a collapsed panel instead of an error. 5.5 rows is enough to
        // always show the "Add" row plus a partial next one as a scroll
        // affordance, capped by the screen's own available height.
        height: Math.min(parent.height - Bulan.space3xl * 2,
                          header.implicitHeight + Bulan.spaceLg
                          + (Bulan.targetRowHeight + Bulan.space2xs) * 5.5
                          + Bulan.spaceXl * 2)

        radius: Bulan.radiusXl
        color: Bulan.popupGlassSurface
        border.width: Bulan.space2xs / 4
        border.color: Bulan.popupGlassBorder

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: Bulan.spaceXl
            spacing: Bulan.spaceLg

            Text {
                id: header
                width: parent.width
                text: popup.title
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitle
                font.letterSpacing: Bulan.trackingTitle
                wrapMode: Text.Wrap
            }

            Item {
                id: listArea
                width: parent.width
                height: parent.height - header.implicitHeight - Bulan.spaceLg
                visible: popup.page === "list"

                Flickable {
                    id: listFlick
                    anchors.fill: parent
                    anchors.rightMargin: Bulan.spaceMd
                    clip: true
                    contentWidth: width
                    contentHeight: listColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    function ensureVisible(index) {
                        var rowH = Bulan.targetRowHeight + Bulan.space2xs
                        var top = index * rowH
                        var bottom = top + rowH
                        if (top < contentY) {
                            contentY = top
                        } else if (bottom > contentY + height) {
                            contentY = bottom - height
                        }
                    }

                    Column {
                        id: listColumn
                        width: listFlick.width
                        spacing: Bulan.space2xs

                        Repeater {
                            model: popup.addEnabled ? 1 : 0
                            delegate: Rectangle {
                                width: listColumn.width
                                height: Bulan.targetRowHeight
                                radius: Bulan.radiusMd
                                color: popup.selectedIndex === 0 ? Bulan.surfaceHover : Bulan.transparent
                                // See the option rows below: every row is
                                // outlined, the focused one in amber.
                                border.width: popup.selectedIndex === 0
                                              ? Bulan.space2xs / 2 : Bulan.space2xs / 4
                                border.color: popup.selectedIndex === 0
                                              ? Bulan.accentPrimary : Bulan.hairline

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Bulan.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: popup.addLabel
                                    color: Bulan.textPrimary
                                    font.family: Bulan.familyUi
                                    font.pixelSize: Bulan.sizeBody
                                    font.weight: Bulan.weightBody
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Bulan.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "+"
                                    color: popup.selectedIndex === 0 ? Bulan.accentPrimary : Bulan.textSecondary
                                    font.family: Bulan.familyUi
                                    font.pixelSize: Bulan.sizeTitle
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: popup.selectedIndex = 0
                                    onClicked: {
                                        popup.selectedIndex = 0
                                        popup.activateCurrent()
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: popup.options

                            delegate: Rectangle {
                                id: optionRow
                                readonly property int rowIndex: index + (popup.addEnabled ? 1 : 0)
                                readonly property bool isSelected: popup.selectedIndex === rowIndex

                                width: listColumn.width
                                height: Bulan.targetRowHeight
                                radius: Bulan.radiusMd
                                color: isSelected ? Bulan.surfaceHover : Bulan.transparent
                                // Every row carries an outline, per the
                                // mockup -- the focused one in amber, the
                                // rest as the quiet hairline. Drawing the
                                // unfocused rows with no border at all left
                                // them reading as loose text rather than as
                                // the list of choices they are.
                                border.width: isSelected ? Bulan.space2xs / 2
                                                         : Bulan.space2xs / 4
                                border.color: isSelected ? Bulan.accentPrimary
                                                         : Bulan.hairline

                                Rectangle {
                                    visible: isSelected
                                    anchors.left: parent.left
                                    anchors.leftMargin: Bulan.spaceSm
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Bulan.space2xs
                                    height: parent.height - Bulan.spaceMd * 2
                                    radius: width / 2
                                    color: Bulan.accentPrimary
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Bulan.spaceLg + Bulan.spaceXs
                                    anchors.right: noteLabel.left
                                    anchors.rightMargin: Bulan.spaceMd
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label !== undefined ? modelData.label : ""
                                    color: isSelected ? Bulan.accentPrimary : Bulan.textPrimary
                                    font.family: Bulan.familyUi
                                    font.pixelSize: Bulan.sizeBody
                                    font.weight: Bulan.weightBody
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: noteLabel
                                    anchors.right: parent.right
                                    anchors.rightMargin: Bulan.spaceLg
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.recommended === true
                                          ? qsTr("Recommended")
                                          : (modelData.note !== undefined ? modelData.note : "")
                                    visible: text !== ""
                                    color: Bulan.textSecondary
                                    font.family: Bulan.familyUi
                                    font.pixelSize: Bulan.sizeLabel
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: popup.selectedIndex = rowIndex
                                    onClicked: {
                                        popup.selectedIndex = rowIndex
                                        popup.activateCurrent()
                                    }
                                }
                            }
                        }
                    }
                }

                // Slim scroll indicator, per the mockup -- a bare Rectangle
                // sized and positioned off the Flickable's own visibleArea,
                // matching HostSettingsOverlay.detailsFlick's identical
                // indicator. No ScrollBar/ScrollView anywhere in this file.
                Rectangle {
                    anchors.right: parent.right
                    width: Bulan.space2xs
                    radius: width / 2
                    color: Bulan.secondary
                    visible: listFlick.contentHeight > listFlick.height
                    height: visible
                            ? Math.max(Bulan.spaceLg,
                                       parent.height * parent.height / listFlick.contentHeight)
                            : 0
                    y: visible
                       ? (parent.height - height) * listFlick.visibleArea.yPosition /
                         Math.max(Bulan.space2xs, 1 - listFlick.visibleArea.heightRatio)
                       : 0
                }
            }

            Column {
                width: parent.width
                spacing: Bulan.spaceLg
                visible: popup.page === "add"

                Text {
                    width: parent.width
                    text: popup.addPromptTitle
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: popup.addPromptBody
                    color: Bulan.textSecondary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBody
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    width: parent.width
                    height: Bulan.targetMin
                    radius: Bulan.radiusMd
                    color: Bulan.surfacePressed
                    border.width: addField.activeFocus ? 2 : 1
                    border.color: addField.activeFocus ? Bulan.accentPrimary : Bulan.hairline

                    TextInput {
                        id: addField
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

                        Keys.onReturnPressed: popup.activateCurrent()
                        Keys.onEnterPressed: popup.activateCurrent()
                    }
                }

                Text {
                    width: parent.width
                    visible: popup.addPromptPlaceholder !== "" && addField.text === ""
                    text: popup.addPromptPlaceholder
                    color: Bulan.secondary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeCaption
                }
            }
        }
    }

    Keys.onUpPressed: function(event) {
        if (page === "list") {
            moveSelection(-1)
        }
        event.accepted = true
    }
    Keys.onDownPressed: function(event) {
        if (page === "list") {
            moveSelection(1)
        }
        event.accepted = true
    }
    Keys.onLeftPressed: function(event) { event.accepted = true }
    Keys.onRightPressed: function(event) { event.accepted = true }

    Keys.onReturnPressed: function(event) {
        activateCurrent()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        activateCurrent()
        event.accepted = true
    }
    Keys.onEscapePressed: function(event) {
        goBack()
        event.accepted = true
    }
    Keys.onBackPressed: function(event) {
        goBack()
        event.accepted = true
    }
}
