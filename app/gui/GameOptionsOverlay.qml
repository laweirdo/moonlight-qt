import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// Contextual game actions over the live grid, the per-game equivalent of
// HostSettingsOverlay.qml: a custom FocusScope rather than a stock Popup or
// Menu, owning one visible selection and every controller path itself,
// releasing focus before disappearing so a closing overlay cannot strand
// navigation on an invisible child.
//
// This replaces upstream's stock NavigableMenu + NavigableMessageDialog pair
// (see git show 6712ac83:app/gui/AppView.qml), which AGENTS.md forbids on a
// Bulan screen. Every enable/disable rule that pair enforced is reproduced
// here; see the comments on buildMenu() for exactly which and why.
//
// Game identity is a name snapshot handed in by the caller at open time, the
// same shape as HostSettingsOverlay's hostUuid/hostName snapshot. This
// component has no idea what a session, a launch or a quit is -- it only
// reports which action the player picked.
// -----------------------------------------------------------------------------

FocusScope {
    id: overlay

    property string gameName: ""
    // The artwork of the game this menu belongs to, so the card names what it
    // is acting on rather than opening as an anonymous list of verbs over a
    // blurred screen (client decision, 15 August 2026). Empty is normal --
    // plenty of games have no box art -- and the thumbnail simply does not
    // appear, exactly as a tile falls back to its name.
    property string boxart: ""
    property bool   running: false
    property bool   hidden: false
    property bool   directLaunch: false
    property bool   anotherRunning: false
    property string runningName: ""
    property bool   reviewMode: false

    property string page: "menu"
    property var    menuActions: []
    property int    selectedAction: 0
    property int    quitConfirmIndex: 0
    property int    switchConfirmIndex: 0
    property string feedbackTitle: ""
    property string feedbackBody: ""

    signal actionRequested(string actionId)
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

    // --- opening -------------------------------------------------------------

    function showForGame(snapshot) {
        applySnapshot(snapshot)
        buildMenu()
        selectedAction = firstSelectableAction()
        quitConfirmIndex = 0
        page = "menu"
        enteredAtConfirmation = false
        opened = true
        forceActiveFocus()
    }

    // Opens straight onto the switch confirmation, for the caller path where
    // Play was already chosen on a tile while another game is running -- the
    // menu page is skipped, not shown then immediately advanced past.
    function showSwitchConfirmation(snapshot) {
        applySnapshot(snapshot)
        buildMenu()
        selectedAction = firstSelectableAction()
        switchConfirmIndex = 0
        page = "switchConfirm"
        enteredAtConfirmation = true
        opened = true
        forceActiveFocus()
    }

    // True when the overlay opened straight onto a confirmation because the
    // player pressed A on a tile, rather than opening the menu and choosing
    // from it. Backing out of that confirmation has to close the overlay
    // outright: dropping the player into a menu they never asked for answers a
    // "no" with a screen they did not open, and the menu is not where B was
    // taking them from. HostSettingsOverlay always returns to its menu because
    // its confirmations can only ever be reached FROM that menu.
    property bool enteredAtConfirmation: false

    function applySnapshot(snapshot) {
        gameName = snapshot.gameName
        boxart = snapshot.boxart !== undefined ? snapshot.boxart : ""
        running = snapshot.running
        hidden = snapshot.hidden
        directLaunch = snapshot.directLaunch
        anotherRunning = snapshot.anotherRunning
        runningName = snapshot.runningName
        reviewMode = snapshot.reviewMode
    }

    function close() {
        focus = false
        opened = false
        dismissed()
    }

    // --- menu construction -----------------------------------------------------
    //
    // Rules reproduced from git show 6712ac83:app/gui/AppView.qml's
    // NavigableMenu, read directly off that file rather than trusted from
    // memory:
    //
    //   Launch/Resume:  text flips on model.running; always present.
    //   Quit Game:      visible: model.running -- omitted entirely otherwise.
    //   Direct Launch:  checkable; enabled: !model.hidden -- always shown here
    //                   per the brief, but blocked while hidden.
    //   Hide Game:      checkable; enabled: model.hidden ||
    //                   (!model.running && !model.directLaunch) -- i.e. you can
    //                   always un-hide an already-hidden game, but you can only
    //                   hide one that is neither running nor set to direct
    //                   launch.
    //
    // A blocked entry is never a dead row a player can land on and get
    // nothing from (HostSettingsOverlay avoids this by omitting the row
    // outright; Hide Game and Direct Launch cannot be omitted, since the brief
    // requires them always shown). Instead a disabled entry carries a note
    // explaining why, is dimmed to Bulan.disabledOpacity, and is skipped by
    // Up/Down and by mouse activation -- see moveSelection() and the
    // Repeater's MouseArea below.
    function buildMenu() {
        var actions = []

        if (running) {
            actions.push({
                actionId: "resume",
                label: qsTr("Resume"),
                note: "",
                destructive: false,
                disabled: false
            })
        } else {
            actions.push({
                actionId: "play",
                label: qsTr("Play"),
                note: "",
                destructive: false,
                disabled: false
            })
        }

        if (running) {
            actions.push({
                actionId: "quitGame",
                label: qsTr("Quit Game"),
                note: "",
                destructive: true,
                disabled: false
            })
        }

        // Hide Game / Show Game: always present. Blocked while running or
        // direct-launch, unless it is already hidden -- un-hiding always works.
        var hideBlockedByRunning = !hidden && running
        var hideBlockedByDirectLaunch = !hidden && directLaunch && !running
        var hideDisabled = hideBlockedByRunning || hideBlockedByDirectLaunch
        var hideNote = ""
        if (hideBlockedByRunning) {
            hideNote = qsTr("Quit the game first.")
        } else if (hideBlockedByDirectLaunch) {
            hideNote = qsTr("Turn off Direct Launch first.")
        }
        actions.push({
            actionId: "toggleHidden",
            label: hidden ? qsTr("Show Game") : qsTr("Hide Game"),
            note: hideNote,
            destructive: false,
            disabled: hideDisabled
        })

        // Direct Launch: always present. Blocked while hidden, in either
        // direction, matching upstream's enabled: !model.hidden.
        actions.push({
            actionId: "toggleDirectLaunch",
            label: qsTr("Direct Launch"),
            note: hidden ? qsTr("Show the game first.")
                         : (directLaunch ? qsTr("On") : qsTr("Off")),
            destructive: false,
            disabled: hidden
        })

        menuActions = actions
    }

    function firstSelectableAction() {
        for (var i = 0; i < menuActions.length; i++) {
            if (!menuActions[i].disabled) {
                return i
            }
        }
        return 0
    }

    // --- navigation ------------------------------------------------------------

    function moveSelection(delta) {
        if (menuActions.length === 0) {
            return
        }
        var idx = selectedAction
        while (true) {
            idx += delta
            if (idx < 0 || idx >= menuActions.length) {
                return
            }
            if (!menuActions[idx].disabled) {
                selectedAction = idx
                return
            }
        }
    }

    function goBack() {
        if (page === "menu" || enteredAtConfirmation) {
            close()
        } else {
            page = "menu"
            forceActiveFocus()
        }
    }

    function activateCurrent() {
        if (page === "menu") {
            if (selectedAction < 0 || selectedAction >= menuActions.length) {
                return
            }
            var action = menuActions[selectedAction]
            if (action.disabled) {
                return
            }
            if (action.actionId === "quitGame") {
                quitConfirmIndex = 0
                page = "quitConfirm"
                forceActiveFocus()
            } else if (action.actionId === "play" && anotherRunning) {
                switchConfirmIndex = 0
                page = "switchConfirm"
                forceActiveFocus()
            } else {
                dispatch(action.actionId)
            }
        } else if (page === "quitConfirm") {
            if (quitConfirmIndex === 0) {
                page = "menu"
                forceActiveFocus()
            } else {
                dispatch("quitGame")
            }
        } else if (page === "switchConfirm") {
            if (switchConfirmIndex === 0) {
                // Same rule as goBack(): Cancel on a confirmation the player
                // was taken straight to closes, rather than revealing a menu
                // they never opened.
                if (enteredAtConfirmation) {
                    close()
                    return
                }
                page = "menu"
                forceActiveFocus()
            } else {
                dispatch("quitAndSwitch")
            }
        }
        // "feedback" has no activation of its own, same as
        // HostSettingsOverlay's feedback page -- the hint bar offers no
        // "confirm" hint there, so nothing promised goes unanswered.
    }

    // Review mode never pretends an action worked and never lets one fall
    // through silently, per HostCarousel.handleHostMenuAction()'s review
    // branch: it says so plainly, on a feedback page, instead of emitting the
    // real signal.
    function dispatch(actionId) {
        if (reviewMode) {
            feedbackTitle = qsTr("Review mode")
            feedbackBody = qsTr("%1 isn't a real game, so nothing was changed.").arg(gameName)
            page = "feedback"
            forceActiveFocus()
            return
        }
        actionRequested(actionId)
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
            onClicked: overlay.goBack()
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
        anchors.verticalCenterOffset: -Bulan.spaceLg

        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                        Bulan.hostTileSize * 2)
        // Room left for the hint bar, which the window owns now -- always
        // targetRowHeight tall. See HostSettingsOverlay.qml.
        height: Math.min(parent.height - Bulan.targetRowHeight - Bulan.space3xl,
                         content.implicitHeight + Bulan.spaceXl * 2)

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
            spacing: Bulan.spaceMd

            // The card's head: the artwork, the name, and what the game is
            // actually doing. It used to be the name alone, which made every
            // menu look the same and left "Quit game" sitting under a title
            // with no indication of whether anything was running to quit.
            Row {
                width: parent.width
                height: Math.max(headThumb.height, headText.height)
                spacing: Bulan.spaceLg
                visible: overlay.page === "menu"

                Rectangle {
                    id: headThumb
                    width: Bulan.gameTileWidth / 2.25
                    height: Bulan.gameTileHeight / 2.25
                    radius: Bulan.radiusMd
                    color: Bulan.bgSurface
                    border.width: Bulan.hairlineWidth
                    border.color: Bulan.hairline
                    visible: headArt.status === Image.Ready
                    clip: true

                    Image {
                        id: headArt
                        anchors.fill: parent
                        anchors.margins: Bulan.hairlineWidth
                        source: overlay.boxart
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Column {
                    id: headText
                    width: parent.width - (headThumb.visible
                                           ? headThumb.width + Bulan.spaceLg
                                           : 0)
                    spacing: Bulan.space2xs
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: overlay.gameName
                        color: Bulan.textPrimary
                        font.family: Bulan.familyDisplay
                        font.pixelSize: Bulan.sizeTitle
                        font.letterSpacing: Bulan.trackingTitle
                        elide: Text.ElideRight
                    }

                    // The state the menu is acting on, in the app's own voice.
                    // "Another game is running" is the one worth saying plainly:
                    // it is the reason Play will ask before it launches.
                    Text {
                        width: parent.width
                        text: overlay.running
                              ? qsTr("Running now")
                              : (overlay.anotherRunning && overlay.runningName !== ""
                                 ? qsTr("%1 is running").arg(overlay.runningName)
                                 : qsTr("Not running"))
                        color: overlay.running ? Bulan.statusSuccess : Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Bulan.hairlineWidth
                color: Bulan.hairline
                visible: overlay.page === "menu"
            }

            Text {
                width: parent.width
                visible: overlay.reviewMode && overlay.page === "menu"
                text: qsTr("Review mode — actions cannot affect a real PC.")
                color: Bulan.accentPrimary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeCaption
                wrapMode: Text.Wrap
            }

            Column {
                id: actionColumn
                width: parent.width
                spacing: Bulan.space2xs
                visible: overlay.page === "menu"

                Repeater {
                    model: overlay.menuActions

                    delegate: Item {
                        width: actionColumn.width
                        height: modelData.destructive
                                ? Bulan.targetRowHeight + Bulan.spaceMd
                                : Bulan.targetRowHeight
                        opacity: modelData.disabled ? Bulan.disabledOpacity : 1.0

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: Bulan.hairlineWidth
                            visible: modelData.destructive
                            color: Bulan.hairline
                        }

                        Rectangle {
                            id: actionSurface
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: Bulan.targetRowHeight
                            radius: Bulan.radiusMd
                            color: index === overlay.selectedAction
                                   ? Bulan.surfaceHover : Bulan.transparent
                            border.width: index === overlay.selectedAction
                                          ? Bulan.focusRingWidth : 0
                            border.color: Bulan.accentPrimary

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Bulan.spaceLg
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: modelData.destructive
                                       ? Bulan.statusError : Bulan.textPrimary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeBody
                                font.weight: Bulan.weightBody
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Bulan.spaceLg
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.note
                                visible: text !== ""
                                color: modelData.disabled
                                       ? Bulan.textSecondary
                                       : (index === overlay.selectedAction
                                          ? Bulan.accentPrimary : Bulan.textSecondary)
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeLabel
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !modelData.disabled
                                onEntered: overlay.selectedAction = index
                                onClicked: {
                                    overlay.selectedAction = index
                                    overlay.activateCurrent()
                                }
                            }
                        }
                    }
                }
            }

            // Direct Launch has no tooltip to lean on here -- there is no mouse
            // hover on a controller. One short line in the app's voice, always
            // present on the menu page, does the job a tooltip did upstream.
            Text {
                width: parent.width
                visible: overlay.page === "menu"
                // "grid" and "host" are our words, not the player's. Brief §8:
                // warm, brief, second person, and technical language lives in
                // Advanced settings and nowhere else. The rest of the app says
                // "PC" -- "Add a PC", "Couldn't reach Desktop-PC" -- so this
                // does too.
                text: qsTr("With Direct Launch on, opening this PC starts this game straight away.")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeCaption
                wrapMode: Text.Wrap
            }

            Column {
                width: parent.width
                spacing: Bulan.spaceLg
                visible: overlay.page === "quitConfirm"

                Text {
                    width: parent.width
                    text: qsTr("Quit %1?").arg(overlay.gameName)
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                    font.letterSpacing: Bulan.trackingTitle
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    text: qsTr("Any unsaved progress in %1 will be lost.").arg(overlay.gameName)
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
                            { label: qsTr("Quit Game"), destructive: true }
                        ]

                        delegate: Rectangle {
                            id: quitChoiceButton

                            required property int index
                            required property var modelData

                            width: (content.width - Bulan.spaceMd) / 2
                            height: Bulan.targetRowHeight
                            radius: Bulan.radiusMd
                            color: quitChoiceButton.index === overlay.quitConfirmIndex
                                   ? Bulan.surfaceHover : Bulan.surfacePressed
                            border.width: quitChoiceButton.index === overlay.quitConfirmIndex
                                          ? Bulan.focusRingWidth : 0
                            border.color: Bulan.accentPrimary

                            Text {
                                anchors.centerIn: parent
                                text: quitChoiceButton.modelData.label
                                color: quitChoiceButton.modelData.destructive
                                       ? Bulan.statusError : Bulan.textPrimary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeBody
                                font.weight: Bulan.weightBody
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: overlay.quitConfirmIndex = quitChoiceButton.index
                                onClicked: {
                                    overlay.quitConfirmIndex = quitChoiceButton.index
                                    overlay.activateCurrent()
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Bulan.spaceLg
                visible: overlay.page === "switchConfirm"

                Text {
                    width: parent.width
                    text: qsTr("Quit %1?").arg(overlay.runningName)
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                    font.letterSpacing: Bulan.trackingTitle
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    text: qsTr("%1 is still running. Quitting it starts %2, and any unsaved progress in %1 will be lost.")
                          .arg(overlay.runningName).arg(overlay.gameName)
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
                            { label: qsTr("Quit and Play"), destructive: true }
                        ]

                        delegate: Rectangle {
                            id: switchChoiceButton

                            required property int index
                            required property var modelData

                            width: (content.width - Bulan.spaceMd) / 2
                            height: Bulan.targetRowHeight
                            radius: Bulan.radiusMd
                            color: switchChoiceButton.index === overlay.switchConfirmIndex
                                   ? Bulan.surfaceHover : Bulan.surfacePressed
                            border.width: switchChoiceButton.index === overlay.switchConfirmIndex
                                          ? Bulan.focusRingWidth : 0
                            border.color: Bulan.accentPrimary

                            Text {
                                anchors.centerIn: parent
                                text: switchChoiceButton.modelData.label
                                color: switchChoiceButton.modelData.destructive
                                       ? Bulan.statusError : Bulan.textPrimary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeBody
                                font.weight: Bulan.weightBody
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: overlay.switchConfirmIndex = switchChoiceButton.index
                                onClicked: {
                                    overlay.switchConfirmIndex = switchChoiceButton.index
                                    overlay.activateCurrent()
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Bulan.spaceLg
                visible: overlay.page === "feedback"

                Text {
                    width: parent.width
                    text: overlay.feedbackTitle
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    text: overlay.feedbackBody
                    color: Bulan.textSecondary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBody
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    // Declared, not drawn. There is one hint bar and the window owns it; a
    // popup that drew its own put a second bar on the screen and left every
    // screen underneath suppressing its own to stop the two printing over each
    // other. The screen hands these upward through its `hintOwner` instead.
    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints:
        (overlay.page === "menu" || overlay.page === "quitConfirm"
         || overlay.page === "switchConfirm")
        ? [{ action: "confirm", label: qsTr("Select"), emphasis: true }]
        : []
    readonly property var hintRightHints: [{
            action: "back",
            label: overlay.page === "menu" ? qsTr("Close") : qsTr("Back")
        }]

    Keys.onUpPressed: function(event) {
        if (page === "menu") {
            moveSelection(-1)
        }
        event.accepted = true
    }

    Keys.onDownPressed: function(event) {
        if (page === "menu") {
            moveSelection(1)
        }
        event.accepted = true
    }

    Keys.onLeftPressed: function(event) {
        if (page === "quitConfirm") {
            quitConfirmIndex = Math.max(0, quitConfirmIndex - 1)
        } else if (page === "switchConfirm") {
            switchConfirmIndex = Math.max(0, switchConfirmIndex - 1)
        }
        event.accepted = true
    }

    Keys.onRightPressed: function(event) {
        if (page === "quitConfirm") {
            quitConfirmIndex = Math.min(1, quitConfirmIndex + 1)
        } else if (page === "switchConfirm") {
            switchConfirmIndex = Math.min(1, switchConfirmIndex + 1)
        }
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
        goBack()
        event.accepted = true
    }
    Keys.onBackPressed: function(event) {
        goBack()
        event.accepted = true
    }
}
