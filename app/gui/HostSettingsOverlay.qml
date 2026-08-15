import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// Contextual host actions over the live carousel.
//
// This is a custom FocusScope rather than a stock Popup or Menu. It owns one
// visible selection, handles every controller path itself, and releases focus
// before disappearing so a closing overlay cannot strand navigation on an
// invisible child.
//
// Host identity is a UUID snapshot, never the carousel row captured at open
// time. The caller resolves that UUID immediately before each real action,
// because discovery can reorder the model while this overlay is open.
// -----------------------------------------------------------------------------

FocusScope {
    id: overlay

    property string hostUuid: ""
    property string hostName: ""
    property string hostAddress: ""
    property string hostDetails: ""
    property bool hostOnline: false
    property bool hostPaired: false
    property bool hostWakeable: false
    property bool hostStatusUnknown: false
    property bool reviewMode: false
    // Set by the caller from its own busy state (HostCarousel.wakingHostUuid
    // naming this host), not derived here -- the overlay has no idea what a wake
    // or a connection is, only what the carousel tells it about this host. Wake PC
    // is withheld while this is true, for the same reason the carousel's own hint
    // bar withholds its Wake hint while busy: the wake is already running, so
    // offering the action again would promise a second wake that pressing it
    // would not actually start.
    property bool wakePending: false

    // Action IDs to leave out of the menu this call builds, even where they
    // would otherwise qualify -- e.g. AppView.qml withholds "apps" when the
    // grid open behind this overlay is already the all-apps list, so the
    // menu is not offering to open the exact list already on screen. Read
    // once per showForHost() call, not bound continuously: the caller sets
    // it immediately before calling showForHost(), matching how every other
    // snapshot field here is a one-shot value rather than a live binding.
    // Empty by default, so HostCarousel.qml's own call site is unaffected.
    property var suppressActionIds: []

    property string page: "menu"
    property var menuActions: []
    property int selectedAction: 0
    property int confirmIndex: 0
    property string feedbackTitle: ""
    property string feedbackBody: ""
    property bool networkTestPending: false

    signal actionRequested(string actionId, string hostUuid, string hostName)
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

    function showForHost(snapshot) {
        hostUuid = snapshot.uuid
        hostName = snapshot.name
        hostAddress = snapshot.address
        hostDetails = snapshot.details
        hostOnline = snapshot.online
        hostPaired = snapshot.paired
        hostWakeable = snapshot.wakeable
        hostStatusUnknown = snapshot.statusUnknown
        reviewMode = snapshot.reviewMode
        wakePending = snapshot.wakePending

        var actions = []
        if (hostOnline && hostPaired && overlay.suppressActionIds.indexOf("apps") < 0) {
            actions.push({
                actionId: "apps",
                label: qsTr("View all apps"),
                note: qsTr("Includes hidden"),
                destructive: false
            })
        }
        if (!hostOnline && hostWakeable && !wakePending) {
            actions.push({
                actionId: "wake",
                label: qsTr("Wake PC"),
                note: "",
                destructive: false
            })
        }
        actions.push({
            actionId: "testNetwork",
            label: qsTr("Test Network"),
            note: qsTr("Takes a few seconds"),
            destructive: false
        })
        actions.push({
            actionId: "details",
            label: qsTr("Host Details"),
            note: "",
            destructive: false
        })
        // Ported from PcView.qml, the inherited screen this overlay replaced --
        // it was the last host action that existed only there, and only through
        // a stock dialog no player could reach. The caller opens the rename
        // panel; this overlay only reports which action was chosen.
        actions.push({
            actionId: "rename",
            label: qsTr("Rename PC"),
            note: "",
            destructive: false
        })
        actions.push({
            actionId: "forget",
            label: qsTr("Forget PC"),
            note: "",
            destructive: true
        })

        menuActions = actions
        selectedAction = 0
        confirmIndex = 0
        networkTestPending = false
        page = "menu"
        opened = true
        forceActiveFocus()
    }

    function close() {
        networkTestPending = false
        focus = false
        opened = false
        dismissed()
    }

    function showFeedback(title, body) {
        networkTestPending = false
        feedbackTitle = title
        feedbackBody = body
        page = "feedback"
        forceActiveFocus()
    }

    function showNetworkTestPending() {
        networkTestPending = true
        feedbackTitle = qsTr("Testing your network")
        feedbackBody = qsTr("Moonlight is checking whether this network blocks required streaming ports. This may take a few seconds…")
        page = "feedback"
        forceActiveFocus()
    }

    function showDetails() {
        detailsFlick.contentY = 0
        page = "details"
        forceActiveFocus()
    }

    function showForgetConfirmation() {
        confirmIndex = 0
        page = "confirm"
        forceActiveFocus()
    }

    function goBack() {
        if (page === "menu") {
            close()
        } else {
            networkTestPending = false
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
            if (action.actionId === "details") {
                showDetails()
            } else if (action.actionId === "forget") {
                showForgetConfirmation()
            } else {
                actionRequested(action.actionId, hostUuid, hostName)
            }
        } else if (page === "confirm") {
            if (confirmIndex === 0) {
                page = "menu"
            } else {
                actionRequested("forget", hostUuid, hostName)
            }
        }
    }

    function activateActionForReview(actionId) {
        for (var i = 0; i < menuActions.length; i++) {
            if (menuActions[i].actionId === actionId) {
                selectedAction = i
                activateCurrent()
                return
            }
        }
    }

    function moveDetails(amount) {
        var maximum = Math.max(0, detailsFlick.contentHeight - detailsFlick.height)
        detailsFlick.contentY = Math.max(0, Math.min(maximum,
                                                    detailsFlick.contentY + amount))
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
        height: Math.min(parent.height - hintBar.height - Bulan.space3xl,
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

            Item {
                id: header
                width: parent.width
                height: Bulan.targetRowHeight

                Rectangle {
                    id: hostMark
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Bulan.targetMin
                    height: Bulan.targetMin
                    radius: width / 2
                    color: Bulan.surfacePressed
                    border.width: Bulan.hairlineWidth
                    border.color: Bulan.popupGlassBorder

                    Text {
                        anchors.centerIn: parent
                        text: overlay.hostName.length > 0
                              ? overlay.hostName.charAt(0).toUpperCase() : "?"
                        color: Bulan.textSecondary
                        font.family: Bulan.familyDisplay
                        font.pixelSize: Bulan.sizeTitle
                    }
                }

                Column {
                    anchors.left: hostMark.right
                    anchors.leftMargin: Bulan.spaceLg
                    anchors.right: statusColumn.left
                    anchors.rightMargin: Bulan.spaceMd
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Bulan.space2xs

                    Text {
                        width: parent.width
                        text: qsTr("HOST SETTINGS")
                        color: Bulan.secondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeCaption
                        font.bold: true
                        font.letterSpacing: Bulan.trackingCaption
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: overlay.hostName
                        color: Bulan.textPrimary
                        font.family: Bulan.familyDisplay
                        font.pixelSize: Bulan.sizeTitle
                        font.letterSpacing: Bulan.trackingTitle
                        elide: Text.ElideRight
                    }
                }

                Column {
                    id: statusColumn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Bulan.space2xs

                    Text {
                        anchors.right: parent.right
                        text: overlay.hostStatusUnknown ? qsTr("Looking\u2026")
                              : (overlay.hostOnline ? qsTr("Online") : qsTr("Offline"))
                        color: overlay.hostOnline ? Bulan.statusSuccess : Bulan.secondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
                    }

                    Text {
                        anchors.right: parent.right
                        text: overlay.hostAddress
                        color: Bulan.secondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeCaption
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Bulan.hairlineWidth
                color: Bulan.hairline
            }

            Text {
                width: parent.width
                visible: overlay.reviewMode && overlay.page === "menu"
                text: qsTr("Review mode \u2014 actions cannot affect a real PC.")
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
                                color: index === overlay.selectedAction
                                       ? Bulan.accentPrimary : Bulan.textSecondary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeLabel
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
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

            Item {
                width: parent.width
                height: Bulan.targetRowHeight * 4
                visible: overlay.page === "details"

                Flickable {
                    id: detailsFlick
                    anchors.fill: parent
                    anchors.rightMargin: Bulan.spaceMd
                    clip: true
                    contentWidth: width
                    contentHeight: detailsText.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        id: detailsText
                        width: detailsFlick.width
                        text: overlay.hostDetails
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                        wrapMode: Text.Wrap
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: Bulan.space2xs
                    radius: width / 2
                    color: Bulan.secondary
                    visible: detailsFlick.contentHeight > detailsFlick.height
                    height: visible
                            ? Math.max(Bulan.spaceLg,
                                       parent.height * parent.height /
                                       detailsFlick.contentHeight)
                            : 0
                    y: visible
                       ? (parent.height - height) * detailsFlick.visibleArea.yPosition /
                         Math.max(Bulan.space2xs, 1 - detailsFlick.visibleArea.heightRatio)
                       : 0
                }
            }

            Column {
                width: parent.width
                spacing: Bulan.spaceLg
                visible: overlay.page === "confirm"

                Text {
                    width: parent.width
                    text: qsTr("Forget %1?").arg(overlay.hostName)
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    text: qsTr("This removes the stored relationship with this PC. You will need to pair it again.")
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
                            { label: qsTr("Keep PC"), destructive: false },
                            { label: qsTr("Forget PC"), destructive: true }
                        ]

                        delegate: Rectangle {
                            width: (content.width - Bulan.spaceMd) / 2
                            height: Bulan.targetRowHeight
                            radius: Bulan.radiusMd
                            color: index === overlay.confirmIndex
                                   ? Bulan.surfaceHover : Bulan.surfacePressed
                            border.width: index === overlay.confirmIndex
                                          ? Bulan.focusRingWidth : 0
                            border.color: Bulan.accentPrimary

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: modelData.destructive
                                       ? Bulan.statusError : Bulan.textPrimary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeBody
                                font.weight: Bulan.weightBody
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: overlay.confirmIndex = index
                                onClicked: {
                                    overlay.confirmIndex = index
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

    // Declared, not drawn -- see GameOptionsOverlay.qml for why.
    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints:
        overlay.page === "menu" || overlay.page === "confirm"
        ? [{ action: "confirm", label: qsTr("Select"), emphasis: true }]
        : []
    readonly property var hintRightHints: [{
            action: "back",
            label: overlay.page === "menu" ? qsTr("Close") : qsTr("Back")
        }]

    Keys.onUpPressed: {
        if (page === "menu") {
            selectedAction = Math.max(0, selectedAction - 1)
        } else if (page === "details") {
            moveDetails(-Bulan.targetMin)
        }
        event.accepted = true
    }

    Keys.onDownPressed: {
        if (page === "menu") {
            selectedAction = Math.min(menuActions.length - 1, selectedAction + 1)
        } else if (page === "details") {
            moveDetails(Bulan.targetMin)
        }
        event.accepted = true
    }

    Keys.onLeftPressed: {
        if (page === "confirm") {
            confirmIndex = Math.max(0, confirmIndex - 1)
        }
        event.accepted = true
    }

    Keys.onRightPressed: {
        if (page === "confirm") {
            confirmIndex = Math.min(1, confirmIndex + 1)
        }
        event.accepted = true
    }

    Keys.onReturnPressed: {
        activateCurrent()
        event.accepted = true
    }
    Keys.onEnterPressed: {
        activateCurrent()
        event.accepted = true
    }
    Keys.onSpacePressed: {
        activateCurrent()
        event.accepted = true
    }
    Keys.onEscapePressed: {
        goBack()
        event.accepted = true
    }
    Keys.onBackPressed: {
        goBack()
        event.accepted = true
    }
}
