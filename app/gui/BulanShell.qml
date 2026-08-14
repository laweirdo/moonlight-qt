import QtQuick 2.9

import AppModel 1.0
import Bulan 1.0
import ComputerManager 1.0
import ComputerModel 1.0
import StreamingPreferences 1.0

FocusScope {
    id: root
    objectName: qsTr("Bulan")
    focus: true

    readonly property bool bulanScreen: true
    property bool shellReady: false
    property string activeHostUuid: StreamingPreferences.lastHostUuid
    property string activeHostName: ""
    property bool activeHostOnline: false
    property bool activeHostWakeable: false
    property var appModel: null
    property string appModelHostUuid: ""
    property var hostContexts: ({})
    property ComputerModel computerModel: createComputerModel()

    readonly property real compositionScale: Math.min(
            width / Bulan.referenceWidth,
            height / Bulan.referenceHeight)

    function createComputerModel() {
        var model = Qt.createQmlObject(
                    'import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        return model
    }

    function scheduleHostSync() {
        hostSync.restart()
    }

    function syncActiveHost() {
        var host = null
        for (var i = 0; i < hostMirror.count; i++) {
            var candidate = hostMirror.itemAt(i)
            if (candidate && candidate.hostUuid === activeHostUuid) {
                host = candidate
                break
            }
        }

        activeHostName = host ? host.hostName : ""
        activeHostOnline = host ? host.online : false
        activeHostWakeable = host ? host.wakeable : false

        if (!host) {
            replaceAppModel(null, "")
            return
        }
        if (appModel && appModelHostUuid === activeHostUuid) return

        var computerIndex = computerModel.computerIndexForUuid(activeHostUuid)
        if (computerIndex < 0) return

        var model = Qt.createQmlObject(
                    'import AppModel 1.0; AppModel {}', root, '')
        model.initialize(ComputerManager, computerIndex, false)
        replaceAppModel(model, activeHostUuid)
    }

    function replaceAppModel(model, hostUuid) {
        var previous = appModel
        appModel = model
        appModelHostUuid = hostUuid
        if (previous && previous !== model) previous.destroy()
    }

    function saveHomeContext() {
        if (appModelHostUuid === "" || !home) return
        var contexts = hostContexts
        contexts[appModelHostUuid] = {
            hostUuid: appModelHostUuid,
            mode: home.mode,
            appId: home.selectedAppId,
            contentY: home.contentY
        }
        hostContexts = contexts
    }

    function restoreHomeContext() {
        var context = hostContexts[appModelHostUuid]
        if (!context || home.gameCount === 0) return
        home.mode = context.mode === "library" ? "library" : "continue"
        var index = home.displayAppIds.indexOf(context.appId)
        home.selectIndex(index >= 0 ? index : 0)
        home.contentY = context.contentY
    }

    onActiveHostUuidChanged: scheduleHostSync()

    Timer {
        id: hostSync
        interval: 0
        onTriggered: root.syncActiveHost()
    }

    Atmosphere {
        anchors.fill: parent
    }

    Item {
        id: composition
        anchors.centerIn: parent
        width: Bulan.referenceWidth
        height: Bulan.referenceHeight
        scale: root.compositionScale

        Image {
            anchors.centerIn: parent
            visible: startup.active
            source: "qrc:/res/bulan_logo_vert.svg"
            height: Bulan.shellWordmarkHeight
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        BulanHome {
            id: home
            anchors.fill: parent
            visible: root.shellReady
            focus: visible
            gameModel: root.appModel
            hostName: root.activeHostName
            hostOnline: root.activeHostOnline
            hostWakeable: root.activeHostWakeable

            onModeChanged: root.saveHomeContext()
            onSelectedAppIdChanged: root.saveHomeContext()
            onContentYChanged: root.saveHomeContext()
            onGameCountChanged: Qt.callLater(root.restoreHomeContext)
        }

        Item {
            visible: false

            Repeater {
                id: hostMirror
                model: root.computerModel

                delegate: Item {
                    readonly property string hostUuid: model.uuid
                    readonly property string hostName: model.name
                    readonly property bool online: model.online
                    readonly property bool wakeable: model.wakeable

                    onHostUuidChanged: root.scheduleHostSync()
                    onHostNameChanged: root.scheduleHostSync()
                    onOnlineChanged: root.scheduleHostSync()
                    onWakeableChanged: root.scheduleHostSync()
                }

                onItemAdded: root.scheduleHostSync()
                onItemRemoved: root.scheduleHostSync()
            }
        }
    }

    BulanStartup {
        id: startup
        anchors.fill: parent
        focus: active
        startupDuration: Bulan.shellStartupMaxMs
        onCompleted: {
            root.shellReady = true
            Qt.callLater(home.forceActiveFocus)
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: startup.active
        onClicked: startup.skip()
    }
}
