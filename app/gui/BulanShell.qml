import QtQuick 2.9
import QtQuick.Window 2.2

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
    property bool directLaunchHandled: false

    signal legacySettingsRequested()
    signal legacyPcRequested()

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

    function hostSnapshots() {
        var hosts = []
        for (var i = 0; i < hostMirror.count; i++) {
            var item = hostMirror.itemAt(i)
            if (item) {
                hosts.push({
                    uuid: item.hostUuid,
                    name: item.hostName,
                    online: item.online,
                    paired: item.paired,
                    wakeable: item.wakeable,
                    statusUnknown: item.statusUnknown,
                    address: item.address,
                    details: item.details
                })
            }
        }
        return hosts
    }

    function hostForUuid(uuid) {
        var hosts = hostSnapshots()
        for (var i = 0; i < hosts.length; i++) {
            if (hosts[i].uuid === uuid) return hosts[i]
        }
        return null
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
        pcSwitcher.hosts = hostSnapshots()

        if (!host) {
            replaceAppModel(null, "")
            if (shellReady && !pcSwitcher.opened) pcSwitcher.show()
            return
        }
        if (appModel && appModelHostUuid === activeHostUuid) {
            Qt.callLater(attemptDirectLaunch)
            return
        }

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

    function openPcSwitcher() {
        pcSwitcher.hosts = hostSnapshots()
        pcSwitcher.activeHostUuid = activeHostUuid
        pcSwitcher.show()
    }

    function openGameMenu(appId) {
        var entry = home.entryForAppId(appId)
        if (!entry) return
        gameMenu.showForGame({
            appId: entry.appId,
            name: entry.name,
            running: entry.running,
            hidden: entry.hidden,
            directLaunch: entry.directLaunch
        })
    }

    function wakeHost(uuid) {
        var index = computerModel.computerIndexForUuid(uuid)
        if (index >= 0) computerModel.wakeComputer(index)
    }

    function handlePcAction(actionId, hostUuid, address) {
        var host = hostForUuid(hostUuid)
        if (actionId === "add") {
            pcSwitcher.close()
            legacyPcRequested()
        } else if (actionId === "details") {
            pcSwitcher.close()
            legacyPcRequested()
        } else if (actionId === "wake" && host) {
            wakeHost(host.uuid)
        } else if (actionId === "retry" && host && address !== "") {
            ComputerManager.addNewHostManually(address)
        } else if (actionId === "choose" && host) {
            if (!host.paired) {
                pcSwitcher.close()
                legacyPcRequested()
                return
            }
            saveHomeContext()
            StreamingPreferences.lastHostUuid = host.uuid
            activeHostUuid = host.uuid
            pcSwitcher.close()
        }
    }

    function rememberNearestApp(appId) {
        var ids = home.displayAppIds
        var index = ids.indexOf(appId)
        var nearestId = 0
        if (ids.length > 1 && index >= 0) {
            nearestId = index < ids.length - 1 ? ids[index + 1] : ids[index - 1]
        }
        var contexts = hostContexts
        var context = contexts[appModelHostUuid] || {
            hostUuid: appModelHostUuid,
            mode: home.mode,
            contentY: home.contentY
        }
        context.appId = nearestId
        contexts[appModelHostUuid] = context
        hostContexts = contexts
    }

    function reloadAppModel() {
        replaceAppModel(null, "")
        scheduleHostSync()
    }

    function requestPlayApp(appId, revealIfNeeded) {
        var snapshot = home.launchSnapshotForAppId(appId)
        if (!snapshot && revealIfNeeded !== false && home.revealApp(appId)) {
            Qt.callLater(function() { root.requestPlayApp(appId, false) })
            return
        }
        if (!snapshot) {
            console.error("Launch artwork source disappeared for app:", appId)
            return
        }
        saveHomeContext()
        sessionFlow.requestPlay(snapshot)
    }

    function requestQuitApp(appId) {
        var snapshot = home.launchSnapshotForAppId(appId)
        if (!snapshot) return
        saveHomeContext()
        sessionFlow.requestQuit(snapshot)
    }

    function attemptDirectLaunch() {
        if (directLaunchHandled || !shellReady || !activeHostOnline
                || !appModel || home.gameCount === 0) return
        directLaunchHandled = true
        var appId = appModel.getDirectLaunchAppId()
        if (appId !== 0) requestPlayApp(appId, true)
    }

    function handleGameAction(actionId, appId) {
        if (!appModel) return
        var index = appModel.appIndexForId(appId)
        if (index < 0) {
            gameMenu.close()
            return
        }
        var entry = home.entryForAppId(appId)
        if (!entry) {
            gameMenu.close()
            return
        }

        if (actionId === "toggleHidden") {
            rememberNearestApp(appId)
            appModel.setAppHidden(index, !entry.hidden)
            gameMenu.close()
            reloadAppModel()
        } else if (actionId === "toggleDirectLaunch") {
            appModel.setAppDirectLaunch(index, !entry.directLaunch)
            gameMenu.close()
            reloadAppModel()
        } else if (actionId === "play" || actionId === "resume") {
            gameMenu.close()
            requestPlayApp(appId, true)
        } else if (actionId === "quit") {
            gameMenu.close()
            requestQuitApp(appId)
        }
    }

    onActiveHostUuidChanged: scheduleHostSync()

    Timer {
        id: hostSync
        interval: 0
        onTriggered: {
            root.syncActiveHost()
            if (!pcSwitcher.opened && !gameMenu.opened) {
                home.forceActiveFocus()
            }
        }
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
            focus: visible && !sessionFlow.active
            enabled: visible && !sessionFlow.active
            gameModel: root.appModel
            hostName: root.activeHostName
            hostOnline: root.activeHostOnline
            hostWakeable: root.activeHostWakeable

            onModeChanged: root.saveHomeContext()
            onSelectedAppIdChanged: root.saveHomeContext()
            onContentYChanged: root.saveHomeContext()
            onGameCountChanged: Qt.callLater(function() {
                root.restoreHomeContext()
                root.attemptDirectLaunch()
            })
            onPlayRequested: root.requestPlayApp(appId, true)
            onGameOptionsRequested: root.openGameMenu(appId)
            onSwitchPcRequested: root.openPcSwitcher()
            onWakeRequested: root.wakeHost(root.activeHostUuid)
            onSettingsRequested: root.legacySettingsRequested()
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
                    readonly property bool paired: model.paired
                    readonly property bool wakeable: model.wakeable
                    readonly property bool statusUnknown: model.statusUnknown
                    readonly property string address: model.address
                    readonly property string details: model.details

                    onHostUuidChanged: root.scheduleHostSync()
                    onHostNameChanged: root.scheduleHostSync()
                    onOnlineChanged: root.scheduleHostSync()
                    onPairedChanged: root.scheduleHostSync()
                    onWakeableChanged: root.scheduleHostSync()
                    onStatusUnknownChanged: root.scheduleHostSync()
                    onAddressChanged: root.scheduleHostSync()
                    onDetailsChanged: root.scheduleHostSync()
                }

                onItemAdded: root.scheduleHostSync()
                onItemRemoved: root.scheduleHostSync()
            }
        }

        BulanPcSwitcher {
            id: pcSwitcher
            anchors.fill: parent
            activeHostUuid: root.activeHostUuid
            onActionRequested: root.handlePcAction(actionId, hostUuid, address)
            onDismissed: Qt.callLater(home.forceActiveFocus)
        }

        BulanGameMenu {
            id: gameMenu
            anchors.fill: parent
            onActionRequested: root.handleGameAction(actionId, appId)
            onDismissed: Qt.callLater(home.forceActiveFocus)
        }

        BulanSessionFlow {
            id: sessionFlow
            appModel: root.appModel
            windowTarget: root.Window.window
            onStateChanged: {
                if (state === "idle") Qt.callLater(home.forceActiveFocus)
            }
        }

        BulanConnectionOverlay {
            id: connectionOverlay
            anchors.fill: parent
            flowState: sessionFlow.state
            target: sessionFlow.target
            returning: sessionFlow.returning
            confirmationVisible: sessionFlow.confirmationVisible
            runningAppName: sessionFlow.runningAppName
            onCancelRequested: sessionFlow.cancel()
            onRetryRequested: sessionFlow.retry()
            onDismissFailureRequested: sessionFlow.dismissFailure()
            onConfirmSwitchRequested: sessionFlow.confirmSwitch()
            onDismissConfirmationRequested: sessionFlow.dismissConfirmation()
            onReturnCompleted: sessionFlow.completeReturn()
        }
    }

    BulanStartup {
        id: startup
        anchors.fill: parent
        focus: active
        startupDuration: Bulan.shellStartupMaxMs
        onCompleted: {
            root.shellReady = true
            root.scheduleHostSync()
            Qt.callLater(root.attemptDirectLaunch)
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: startup.active
        onClicked: startup.skip()
    }
}
