import QtQuick 2.9

import Bulan 1.0

BulanReflectionTray {
    id: tray

    title: gameName
    leftHints: [{ action: "confirm", label: qsTr("Select"), emphasis: true }]

    property int appId: 0
    property string gameName: ""
    property bool running: false
    property bool hidden: false
    property bool directLaunch: false
    property var actions: []
    property int selectedActionIndex: 0

    signal actionRequested(string actionId, int appId)

    function showForGame(snapshot) {
        appId = snapshot.appId
        gameName = snapshot.name
        running = snapshot.running
        hidden = snapshot.hidden
        directLaunch = snapshot.directLaunch
        rebuildActions()
        selectedActionIndex = firstSelectableAction()
        show()
    }

    function rebuildActions() {
        var next = [{
            actionId: running ? "resume" : "play",
            label: running ? qsTr("Resume") : qsTr("Play"),
            note: "",
            destructive: false,
            disabled: false
        }]
        if (running) {
            next.push({
                actionId: "quit",
                label: qsTr("Quit current game"),
                note: "",
                destructive: true,
                disabled: false
            })
        }
        var hideDisabled = !hidden && (running || directLaunch)
        next.push({
            actionId: "toggleHidden",
            label: hidden ? qsTr("Show") : qsTr("Hide"),
            note: hideDisabled
                  ? (running ? qsTr("Quit first") : qsTr("Clear direct launch first"))
                  : "",
            destructive: false,
            disabled: hideDisabled
        })
        next.push({
            actionId: "toggleDirectLaunch",
            label: directLaunch ? qsTr("Clear direct launch")
                                : qsTr("Set direct launch"),
            note: hidden ? qsTr("Show this game first") : "",
            destructive: false,
            disabled: hidden
        })
        actions = next
    }

    function firstSelectableAction() {
        for (var i = 0; i < actions.length; i++) {
            if (!actions[i].disabled) return i
        }
        return 0
    }

    function actionIndex(actionId) {
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].actionId === actionId) return i
        }
        return -1
    }

    function requestAction(actionId) {
        var index = actionIndex(actionId)
        if (index < 0 || actions[index].disabled) return
        actionRequested(actionId, appId)
    }

    function moveSelection(delta) {
        var index = selectedActionIndex
        while (true) {
            index += delta
            if (index < 0 || index >= actions.length) return
            if (!actions[index].disabled) {
                selectedActionIndex = index
                return
            }
        }
    }

    function activateCurrent() {
        if (selectedActionIndex < 0 || selectedActionIndex >= actions.length) return
        requestAction(actions[selectedActionIndex].actionId)
    }

    Column {
        id: actionColumn
        width: parent.width
        spacing: Bulan.spaceXs

        Repeater {
            model: tray.actions

            delegate: Rectangle {
                required property int index
                required property var modelData

                width: actionColumn.width
                height: Bulan.targetRowHeight
                radius: Bulan.radiusMd
                opacity: modelData.disabled ? Bulan.disabledOpacity : 1
                color: index === tray.selectedActionIndex
                       ? Bulan.surfaceHover : Bulan.surfacePressed
                border.width: index === tray.selectedActionIndex
                              ? Bulan.space2xs / 2 : 0
                border.color: Bulan.accentPrimary

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Bulan.spaceLg
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: modelData.destructive ? Bulan.statusError : Bulan.textPrimary
                    font.family: Bulan.familyUi
                    font.weight: Bulan.weightBody
                    font.pixelSize: Bulan.sizeBody
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Bulan.spaceLg
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.note
                    visible: text !== ""
                    color: Bulan.textSecondary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeLabel
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !modelData.disabled
                    hoverEnabled: true
                    onEntered: tray.selectedActionIndex = index
                    onClicked: {
                        tray.selectedActionIndex = index
                        tray.activateCurrent()
                    }
                }
            }
        }
    }

    Keys.onUpPressed: function(event) {
        moveSelection(-1)
        event.accepted = true
    }
    Keys.onDownPressed: function(event) {
        moveSelection(1)
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
}
