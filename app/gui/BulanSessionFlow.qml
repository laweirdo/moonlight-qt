import QtQuick 2.9

import Bulan 1.0
import ComputerManager 1.0
import SdlGamepadKeyNavigation 1.0
import SystemProperties 1.0

QtObject {
    id: root

    property string state: "idle"
    property var appModel: null
    property var windowTarget: null
    property var session: null
    property var target: null
    property bool confirmationVisible: false
    property bool returning: false
    property bool isResume: false
    property bool quitOnly: false
    property bool launchFailed: false
    property bool connectionBegan: false
    property bool sessionStarted: false
    property bool cancelPending: false
    property bool retryPending: false
    property bool dismissPending: false
    property string cleanupReason: ""
    property string failureStage: ""
    property string runningAppName: ""

    readonly property bool active: state !== "idle" || confirmationVisible

    function requestPlay(snapshot) {
        if (state !== "idle" || confirmationVisible || !appModel || !snapshot) return

        target = snapshot
        quitOnly = false
        var runningId = appModel.getRunningAppId()
        isResume = runningId === snapshot.appId
        if (runningId !== 0 && !isResume) {
            runningAppName = appModel.getRunningAppName()
            confirmationVisible = true
            return
        }
        beginTarget()
    }

    function requestQuit(snapshot) {
        if (state !== "idle" || confirmationVisible || !appModel || !snapshot) return
        target = snapshot
        quitOnly = true
        runningAppName = snapshot.name
        beginQuit()
    }

    function dismissConfirmation() {
        if (!confirmationVisible) return
        confirmationVisible = false
        cleanupReason = "dismiss"
        returning = true
        state = "cleanup"
    }

    function confirmSwitch() {
        if (!confirmationVisible || state !== "idle") return
        confirmationVisible = false
        beginQuit()
    }

    function beginQuit() {
        state = "stoppingPrevious"
        quitTimeout.restart()
        appModel.quitRunningApp()
    }

    function quitCompleted(error) {
        if (state !== "stoppingPrevious") return
        quitTimeout.stop()
        if (error !== undefined) {
            console.error("Quit failed:", error)
            launchFailed = true
            failureStage = "quit"
            state = "failed"
            return
        }
        if (quitOnly) {
            cleanupReason = "quit"
            state = "cleanup"
            returning = true
            return
        }
        beginTarget()
    }

    function beginTarget() {
        if (!appModel || !target) {
            console.error("Launch context disappeared before session creation")
            launchFailed = true
            failureStage = "launch"
            state = "failed"
            return
        }
        var appIndex = appModel.appIndexForId(target.appId)
        if (appIndex < 0) {
            console.error("Target app disappeared before launch:", target.appId)
            launchFailed = true
            failureStage = "launch"
            state = "failed"
            return
        }

        launchFailed = false
        failureStage = ""
        connectionBegan = false
        sessionStarted = false
        cancelPending = false
        retryPending = false
        dismissPending = false
        cleanupReason = ""
        session = appModel.createSessionForApp(appIndex)
        if (!session) {
            console.error("Session creation failed for app:", target.appId)
            launchFailed = true
            failureStage = "launch"
            state = "failed"
            return
        }

        state = "initializing"
        SdlGamepadKeyNavigation.disable()
        SystemProperties.waitForAsyncLoad()
        initializeTimer.restart()
    }

    function initializeSession() {
        if ((state !== "initializing" && !cancelPending) || !session) return
        if (!session.initialize(windowTarget)) {
            console.error("Session initialization failed")
            SdlGamepadKeyNavigation.enable()
            session = null
            gc()
            if (cancelPending) {
                state = "cleanup"
                returning = true
            } else {
                launchFailed = true
                failureStage = "launch"
                state = "failed"
            }
            return
        }

        if (cancelPending) {
            startAndInterrupt()
            return
        }

        var warnings = session.launchWarnings
        if (warnings && warnings.length > 0) {
            for (var i = 0; i < warnings.length; i++) {
                console.warn("Launch warning:", warnings[i])
            }
            state = "warning"
            warningTimer.restart()
        } else {
            Qt.callLater(startSession)
        }
    }

    function startSession() {
        if ((state !== "initializing" && state !== "warning") || !session) return
        warningTimer.stop()
        state = "connecting"
        sessionStarted = true
        session.start()
    }

    function cancel() {
        if (state !== "initializing" && state !== "warning"
                && state !== "connecting") return
        warningTimer.stop()
        cleanupReason = "cancel"
        state = "stopping"
        if (!session) {
            state = "cleanup"
            returning = true
            return
        }
        if (initializeTimer.running) {
            cancelPending = true
            return
        }
        startAndInterrupt()
    }

    function startAndInterrupt() {
        if (!sessionStarted) {
            sessionStarted = true
            session.start()
        }
        Qt.callLater(function() {
            if (root.session) root.session.interrupt()
        })
    }

    function retry() {
        if (state !== "failed" || !target) return
        if (failureStage === "quit") {
            launchFailed = false
            beginQuit()
            return
        }
        retryPending = true
        returning = false
        if (session) {
            state = "cleanup"
        } else {
            beginTarget()
        }
    }

    function dismissFailure() {
        if (state !== "failed") return
        dismissPending = true
        if (session) {
            state = "cleanup"
        } else {
            returning = true
            state = "cleanup"
        }
    }

    function sessionFinished(portTestResult) {
        warningTimer.stop()
        SdlGamepadKeyNavigation.enable()
        if (windowTarget) windowTarget.visible = true

        if (cleanupReason === "cancel") {
            state = "cleanup"
        } else if (launchFailed) {
            state = "failed"
        } else {
            cleanupReason = "return"
            state = "cleanup"
        }
    }

    function sessionReadyForDeletion() {
        session = null
        sessionStarted = false
        cancelPending = false
        gc()
        if (retryPending) {
            beginTarget()
        } else if (dismissPending || cleanupReason === "cancel"
                   || cleanupReason === "return") {
            returning = true
            state = "cleanup"
        }
    }

    function completeReturn() {
        if (state !== "cleanup" || !returning) return
        returning = false
        state = "idle"
        target = null
        runningAppName = ""
        isResume = false
        quitOnly = false
        launchFailed = false
        failureStage = ""
        connectionBegan = false
        cancelPending = false
        retryPending = false
        dismissPending = false
        cleanupReason = ""
    }

    property Connections sessionSignals: Connections {
        target: root.session
        ignoreUnknownSignals: true

        function onStageStarting(stage) {
            console.log("Launch stage:", stage)
        }
        function onStageFailed(stage, errorCode, failingPorts) {
            console.error("Launch stage failed:", stage,
                          "error", errorCode, "ports", failingPorts)
            root.launchFailed = true
            root.failureStage = "launch"
        }
        function onConnectionStarted() {
            root.connectionBegan = true
            if (root.windowTarget) root.windowTarget.visible = false
        }
        function onDisplayLaunchError(text) {
            console.error("Launch failed:", text)
            root.launchFailed = true
            root.failureStage = "launch"
        }
        function onSessionFinished(portTestResult) {
            root.sessionFinished(portTestResult)
        }
        function onReadyForDeletion() {
            root.sessionReadyForDeletion()
        }
    }

    property Connections quitSignals: Connections {
        target: ComputerManager
        function onQuitAppCompleted(error) { root.quitCompleted(error) }
    }

    property Timer initializeTimer: Timer {
        interval: 0
        onTriggered: root.initializeSession()
    }

    property Timer warningTimer: Timer {
        interval: Bulan.launchWarningDurationMs
        onTriggered: root.startSession()
    }

    property Timer quitTimeout: Timer {
        interval: Bulan.sessionSwitchTimeoutMs
        onTriggered: root.quitCompleted(qsTr("Timed out"))
    }
}
