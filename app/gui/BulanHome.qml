import QtQuick 2.9

import Bulan 1.0

FocusScope {
    id: root

    property var gameModel: null
    property string hostName: ""
    property bool hostOnline: false
    property bool hostWakeable: false

    signal playRequested(int appId)
    signal gameOptionsRequested(int appId)
    signal switchPcRequested()
    signal wakeRequested()
    signal settingsRequested()

    readonly property int gameCount: modelMirror.count
    property string mode: "continue"
    property string sectionTitle: qsTr("Your games")
    property int selectedAppId: 0
    property int selectedIndex: 0
    property var shelfEntries: []
    property var alphabeticalEntries: []
    readonly property var displayedEntries: mode === "continue"
                                                  ? shelfEntries
                                                  : alphabeticalEntries
    readonly property var shelfAppIds: shelfEntries.map(function(entry) {
        return entry.appId
    })
    readonly property var displayAppIds: displayedEntries.map(function(entry) {
        return entry.appId
    })
    property alias contentY: libraryGrid.contentY

    function scheduleRebuild() {
        rebuildTimer.restart()
    }

    function shelfOffsetForAppId(appId) {
        var index = shelfAppIds.indexOf(appId)
        var selected = shelfAppIds.indexOf(selectedAppId)
        var count = shelfEntries.length
        if (index < 0 || selected < 0 || count === 0) return 0
        if (index === selected) return 0

        var rankAfterSelection = (index - selected + count) % count
        var leftCount = Math.floor(count / 2)
        return rankAfterSelection <= leftCount
                ? rankAfterSelection - leftCount - 1
                : rankAfterSelection - leftCount
    }

    function playedAt(value) {
        if (value === undefined || value === null) {
            return 0
        }
        var date = value instanceof Date ? value : new Date(value)
        var time = date.getTime()
        return isNaN(time) || time <= 0 ? 0 : time
    }

    function alphabetically(a, b) {
        var left = a.name.toLocaleLowerCase()
        var right = b.name.toLocaleLowerCase()
        if (left < right) return -1
        if (left > right) return 1
        return a.appId - b.appId
    }

    function rebuild() {
        var entries = []
        for (var i = 0; i < modelMirror.count; i++) {
            var item = modelMirror.itemAt(i)
            if (item) {
                entries.push({
                    appId: item.appId,
                    name: item.gameName,
                    playedAt: playedAt(item.lastPlayedValue),
                    boxart: item.boxartValue,
                    running: item.isRunning,
                    appCollectorGame: item.isAppCollectorGame
                })
            }
        }

        var alphabetical = entries.slice().sort(alphabetically)
        var recent = entries.filter(function(entry) {
            return entry.playedAt > 0
        }).sort(function(a, b) {
            return b.playedAt - a.playedAt || alphabetically(a, b)
        })

        sectionTitle = recent.length > 0
                ? qsTr("Pick up where you left off") : qsTr("Your games")
        alphabeticalEntries = alphabetical
        shelfEntries = (recent.length > 0 ? recent : alphabetical).slice(0, 5)

        var activeEntries = mode === "continue" ? shelfEntries : alphabeticalEntries
        var selectedStillExists = activeEntries.some(function(entry) {
            return entry.appId === selectedAppId
        })
        if (!selectedStillExists) {
            selectedIndex = Math.min(selectedIndex,
                                     Math.max(0, activeEntries.length - 1))
            selectedAppId = activeEntries.length > 0
                    ? activeEntries[selectedIndex].appId : 0
        } else {
            selectedIndex = displayAppIds.indexOf(selectedAppId)
        }
    }

    function selectIndex(index) {
        if (displayedEntries.length === 0) {
            selectedIndex = 0
            selectedAppId = 0
            return
        }
        selectedIndex = Math.max(0, Math.min(index, displayedEntries.length - 1))
        selectedAppId = displayedEntries[selectedIndex].appId
    }

    function enterLibrary() {
        if (mode === "library") return
        mode = "library"
        selectIndex(displayAppIds.indexOf(selectedAppId))
    }

    function leaveLibrary() {
        if (mode === "continue") return
        mode = "continue"
        var index = displayAppIds.indexOf(selectedAppId)
        selectIndex(index >= 0 ? index : 0)
    }

    function playSelected() {
        if (selectedAppId !== 0) playRequested(selectedAppId)
    }

    function openGameOptions() {
        if (selectedAppId !== 0) gameOptionsRequested(selectedAppId)
    }

    Keys.onPressed: function(event) {
        var handled = true
        if (event.key === Qt.Key_Left) {
            selectIndex(selectedIndex - 1)
        } else if (event.key === Qt.Key_Right) {
            selectIndex(selectedIndex + 1)
        } else if (event.key === Qt.Key_Down) {
            if (mode === "continue") enterLibrary()
            else selectIndex(selectedIndex + Bulan.gameGridColumns)
        } else if (event.key === Qt.Key_Up) {
            if (mode === "library" && selectedIndex < Bulan.gameGridColumns) leaveLibrary()
            else if (mode === "library") {
                selectIndex(selectedIndex - Bulan.gameGridColumns)
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            playSelected()
        } else if (event.key === Qt.Key_Context1) {
            openGameOptions()
        } else if (event.key === Qt.Key_Menu) {
            switchPcRequested()
        } else if (event.key === Qt.Key_Call && !hostOnline && hostWakeable) {
            wakeRequested()
        } else if (event.key === Qt.Key_Hangup) {
            settingsRequested()
        } else {
            handled = false
        }
        event.accepted = handled
    }

    Timer {
        id: rebuildTimer
        interval: 0
        onTriggered: root.rebuild()
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Bulan.targetRowHeight

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Bulan.layoutScreenMarginX
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("B U L A N")
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.weight: Bulan.weightBody
            font.pixelSize: Bulan.sizeCaption
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Bulan.layoutScreenMarginX
            anchors.verticalCenter: parent.verticalCenter
            spacing: Bulan.spaceSm
            visible: root.hostName !== ""

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Bulan.spaceMd
                height: width
                radius: width / 2
                color: root.hostOnline ? Bulan.accentGlow : Bulan.secondary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.hostName
                color: Bulan.textPrimary
                font.family: Bulan.familyUi
                font.weight: Bulan.weightBody
                font.pixelSize: Bulan.sizeLabel
            }
        }
    }

    Column {
        id: destination
        anchors.top: parent.top
        anchors.topMargin: Bulan.space3xl * 2
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Bulan.spaceSm
        visible: root.gameCount > 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.mode === "continue"
                  ? qsTr("READY WHEN YOU ARE") : qsTr("ALL YOUR GAMES")
            color: Bulan.accentGlow
            font.family: Bulan.familyUi
            font.weight: Bulan.weightBody
            font.pixelSize: Bulan.sizeCaption
            font.letterSpacing: Bulan.trackingCaption
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.mode === "continue" ? root.sectionTitle : qsTr("Your library")
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.weight: Bulan.weightDisplay
            font.pixelSize: Bulan.sizeDisplay
            font.letterSpacing: Bulan.trackingDisplay
        }
    }

    Item {
        id: shelf
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: actionBar.top
        anchors.bottomMargin: Bulan.space3xl
        height: Bulan.homeShelfFocusHeight
                + Bulan.gameRecentLabelGap + Bulan.lineHeightLabel
        visible: opacity > 0
        opacity: root.mode === "continue" ? 1 : 0
        scale: root.mode === "continue" ? 1 : Bulan.motionPopupEnterScale

        Behavior on opacity {
            NumberAnimation { duration: Bulan.motionFocusMs }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Bulan.motionFocusMs
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: root.shelfEntries

            delegate: Item {
                readonly property bool isSelected: modelData.appId === root.selectedAppId
                x: shelf.width / 2
                   + root.shelfOffsetForAppId(modelData.appId)
                     * Bulan.homeShelfSpread
                   - Bulan.homeShelfFocusWidth / 2
                width: Bulan.homeShelfFocusWidth
                height: shelf.height
                z: isSelected ? 1 : 0

                Behavior on x {
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.OutCubic
                    }
                }

                BulanGameTile {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    gameName: modelData.name
                    appId: modelData.appId
                    boxart: modelData.boxart
                    running: modelData.running
                    appCollectorGame: modelData.appCollectorGame
                    selected: parent.isSelected
                    tileWidth: selected ? Bulan.homeShelfFocusWidth
                                        : Bulan.homeShelfTileWidth
                    tileHeight: selected ? Bulan.homeShelfFocusHeight
                                         : Bulan.homeShelfTileHeight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var selectedBefore = root.selectedAppId
                            root.selectIndex(index)
                            if (selectedBefore === modelData.appId) root.playSelected()
                        }
                    }
                }
            }
        }
    }

    GridView {
        id: libraryGrid
        anchors.top: destination.bottom
        anchors.topMargin: Bulan.spaceXl
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX
        anchors.right: parent.right
        anchors.rightMargin: Bulan.layoutScreenMarginX
        anchors.bottom: actionBar.top
        anchors.bottomMargin: Bulan.spaceMd
        cellWidth: width / Bulan.gameGridColumns
        cellHeight: Bulan.gameTileHeight + Bulan.gameRecentLabelGap
                    + Bulan.lineHeightLabel + Bulan.spaceLg
        model: root.alphabeticalEntries
        currentIndex: root.mode === "library" ? root.selectedIndex : -1
        clip: true
        interactive: root.mode === "library"
        visible: opacity > 0
        opacity: root.mode === "library" ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Bulan.motionFocusMs }
        }

        delegate: Item {
            width: libraryGrid.cellWidth
            height: libraryGrid.cellHeight

            BulanGameTile {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                gameName: modelData.name
                appId: modelData.appId
                boxart: modelData.boxart
                running: modelData.running
                appCollectorGame: modelData.appCollectorGame
                selected: modelData.appId === root.selectedAppId

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var selectedBefore = root.selectedAppId
                        root.selectIndex(index)
                        if (selectedBefore === modelData.appId) root.playSelected()
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Bulan.spaceMd
        visible: root.gameCount === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hostName === "" ? qsTr("Choose a PC to begin")
                                       : qsTr("No games here yet")
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.weight: Bulan.weightDisplay
            font.pixelSize: Bulan.sizeTitleLg
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hostName === "" ? qsTr("Switch PC")
                  : (root.hostOnline ? qsTr("Retry or switch PC")
                                     : qsTr("Wake or switch PC"))
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.weight: Bulan.weightBody
            font.pixelSize: Bulan.sizeLabel
        }
    }

    HintBar {
        id: actionBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Bulan.targetRowHeight
        leftHints: [
            { action: "confirm", label: qsTr("Play"), emphasis: true,
              visible: root.selectedAppId !== 0 },
            { action: "select", label: qsTr("Options"),
              visible: root.selectedAppId !== 0 },
            { action: "options", label: qsTr("Switch PC") },
            { action: "alternate", label: qsTr("Wake"),
              visible: !root.hostOnline && root.hostWakeable }
        ]
        rightHints: [
            { action: "start", label: qsTr("Settings") }
        ]
    }

    Item {
        visible: false

        Repeater {
            id: modelMirror
            model: root.gameModel

            delegate: Item {
                readonly property string gameName: model.name
                readonly property int appId: model.appid
                readonly property var lastPlayedValue: model.lastPlayed
                readonly property url boxartValue: model.boxart
                readonly property bool isRunning: model.running
                readonly property bool isAppCollectorGame: model.appCollectorGame

                onGameNameChanged: root.scheduleRebuild()
                onAppIdChanged: root.scheduleRebuild()
                onLastPlayedValueChanged: root.scheduleRebuild()
                onBoxartValueChanged: root.scheduleRebuild()
                onIsRunningChanged: root.scheduleRebuild()
                onIsAppCollectorGameChanged: root.scheduleRebuild()
            }

            onItemAdded: root.scheduleRebuild()
            onItemRemoved: root.scheduleRebuild()
        }
    }
}
