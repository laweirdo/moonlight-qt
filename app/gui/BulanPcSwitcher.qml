import QtQuick 2.9

import Bulan 1.0

BulanReflectionTray {
    id: tray

    title: qsTr("Choose a PC")
    leftHints: [{ action: "confirm", label: qsTr("Select"), emphasis: true }]

    property var hosts: []
    property string activeHostUuid: ""
    property string selectedHostUuid: ""
    property int selectedHostIndex: -1
    property int selectedActionIndex: 0
    property bool actionFocus: false
    property var actions: []

    signal actionRequested(string actionId, string hostUuid, string address)

    function hostIndexForUuid(uuid) {
        for (var i = 0; i < hosts.length; i++) {
            if (hosts[i].uuid === uuid) return i
        }
        return -1
    }

    function selectedHost() {
        var index = hostIndexForUuid(selectedHostUuid)
        return index >= 0 ? hosts[index] : null
    }

    function syncSelection() {
        var index = hostIndexForUuid(selectedHostUuid)
        if (index < 0) index = hostIndexForUuid(activeHostUuid)
        if (index < 0 && hosts.length > 0) index = 0
        selectedHostIndex = index
        selectedHostUuid = index >= 0 ? hosts[index].uuid : ""
        hostList.currentIndex = index
        rebuildActions()
    }

    function rebuildActions() {
        var host = selectedHost()
        var next = []
        if (host) {
            next.push({ actionId: "choose", label: qsTr("Choose") })
            if (!host.online && host.wakeable) {
                next.push({ actionId: "wake", label: qsTr("Wake") })
            }
            if (!host.online) {
                next.push({ actionId: "retry", label: qsTr("Retry") })
            }
        }
        next.push({ actionId: "add", label: qsTr("Add PC") })
        if (host) {
            next.push({ actionId: "details", label: qsTr("Details") })
        }
        actions = next
        selectedActionIndex = Math.min(selectedActionIndex,
                                       Math.max(0, actions.length - 1))
    }

    function selectHost(index) {
        if (index < 0 || index >= hosts.length) return
        selectedHostIndex = index
        selectedHostUuid = hosts[index].uuid
        hostList.currentIndex = index
        rebuildActions()
    }

    function requestAction(actionId) {
        if (actionId === "add") {
            actionRequested(actionId, "", "")
            return
        }
        var host = selectedHost()
        if (!host) return
        actionRequested(actionId, host.uuid, host.address || "")
    }

    function activateCurrent() {
        if (actionFocus) {
            if (selectedActionIndex >= 0 && selectedActionIndex < actions.length) {
                requestAction(actions[selectedActionIndex].actionId)
            }
        } else if (selectedHostUuid !== "") {
            requestAction("choose")
        }
    }

    onHostsChanged: syncSelection()
    onActiveHostUuidChanged: if (opened) syncSelection()
    onOpenedChanged: if (opened) {
        actionFocus = hosts.length === 0
        selectedActionIndex = 0
        selectedHostUuid = activeHostUuid
        syncSelection()
    }

    Item {
        width: parent.width
        height: Bulan.targetRowHeight * 2

        ListView {
            id: hostList
            anchors.fill: parent
            orientation: ListView.Horizontal
            clip: true
            spacing: Bulan.spaceMd
            model: tray.hosts
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - Bulan.targetRowHeight
            preferredHighlightEnd: width / 2 + Bulan.targetRowHeight
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property int index
                required property var modelData

                width: Bulan.targetRowHeight * 2
                height: hostList.height
                radius: Bulan.radiusLg
                color: index === tray.selectedHostIndex
                       ? Bulan.surfaceHover : Bulan.surfacePressed
                border.width: index === tray.selectedHostIndex
                              ? Bulan.space2xs / 2 : Bulan.space2xs / 4
                border.color: index === tray.selectedHostIndex
                              ? Bulan.accentPrimary : Bulan.popupGlassBorder

                Column {
                    anchors.centerIn: parent
                    width: parent.width - Bulan.spaceLg * 2
                    spacing: Bulan.spaceXs

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Bulan.targetMin
                        height: Bulan.targetMin
                        radius: width / 2
                        color: Bulan.bgSurface
                        border.width: Bulan.space2xs / 4
                        border.color: Bulan.popupGlassBorder

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name.length > 0
                                  ? modelData.name.charAt(0).toUpperCase() : "?"
                            color: Bulan.textSecondary
                            font.family: Bulan.familyDisplay
                            font.weight: Bulan.weightDisplay
                            font.pixelSize: Bulan.sizeTitle
                        }
                    }

                    Text {
                        width: parent.width
                        text: modelData.name
                        color: Bulan.textPrimary
                        font.family: Bulan.familyUi
                        font.weight: Bulan.weightBody
                        font.pixelSize: Bulan.sizeBody
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.statusUnknown ? qsTr("Looking…")
                              : modelData.online ? qsTr("Ready") : qsTr("Offline")
                        color: modelData.online ? Bulan.statusSuccess : Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: tray.selectHost(index)
                    onClicked: {
                        if (tray.selectedHostIndex === index) tray.requestAction("choose")
                        else tray.selectHost(index)
                    }
                }
            }
        }
    }

    Row {
        id: actionRow
        width: parent.width
        height: Bulan.targetMin
        spacing: Bulan.spaceXs

        Repeater {
            model: tray.actions

            delegate: Rectangle {
                required property int index
                required property var modelData

                width: (actionRow.width - actionRow.spacing * (tray.actions.length - 1))
                       / Math.max(1, tray.actions.length)
                height: Bulan.targetMin
                radius: Bulan.radiusMd
                color: tray.actionFocus && index === tray.selectedActionIndex
                       ? Bulan.surfaceHover : Bulan.surfacePressed
                border.width: tray.actionFocus && index === tray.selectedActionIndex
                              ? Bulan.space2xs / 2 : 0
                border.color: Bulan.accentPrimary

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: tray.actionFocus && index === tray.selectedActionIndex
                           ? Bulan.accentPrimary : Bulan.textPrimary
                    font.family: Bulan.familyUi
                    font.weight: Bulan.weightBody
                    font.pixelSize: Bulan.sizeLabel
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        tray.actionFocus = true
                        tray.selectedActionIndex = index
                    }
                    onClicked: {
                        tray.selectedActionIndex = index
                        tray.requestAction(modelData.actionId)
                    }
                }
            }
        }
    }

    Keys.onLeftPressed: function(event) {
        if (actionFocus) {
            selectedActionIndex = Math.max(0, selectedActionIndex - 1)
        } else {
            selectHost(selectedHostIndex - 1)
        }
        event.accepted = true
    }
    Keys.onRightPressed: function(event) {
        if (actionFocus) {
            selectedActionIndex = Math.min(actions.length - 1,
                                           selectedActionIndex + 1)
        } else {
            selectHost(selectedHostIndex + 1)
        }
        event.accepted = true
    }
    Keys.onUpPressed: function(event) {
        if (hosts.length > 0) actionFocus = false
        event.accepted = true
    }
    Keys.onDownPressed: function(event) {
        actionFocus = true
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
