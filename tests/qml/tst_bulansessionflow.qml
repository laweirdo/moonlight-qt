import QtQuick 2.9
import QtTest 1.2

TestCase {
    id: testCase
    name: "BulanSessionFlow"
    when: windowShown

    property int runningAppId: 0
    property string runningAppName: ""
    property int quitCalls: 0
    property var sessions: []

    Component {
        id: sessionComponent

        QtObject {
            property var launchWarnings: []
            property int interruptCalls: 0
            property int initializeCalls: 0
            property bool startedBeforeInitialize: false

            signal stageStarting(string stage)
            signal stageFailed(string stage, int errorCode, string failingPorts)
            signal connectionStarted()
            signal displayLaunchError(string text)
            signal quitStarting()
            signal sessionFinished(int portTestResult)
            signal readyForDeletion()

            function initialize(windowTarget) {
                initializeCalls++
                return true
            }
            function start() { startedBeforeInitialize = initializeCalls === 0 }
            function interrupt() { interruptCalls++ }
        }
    }

    QtObject {
        id: appModel

        function getRunningAppId() { return testCase.runningAppId }
        function getRunningAppName() { return testCase.runningAppName }
        function appIndexForId(appId) { return appId === 42 ? 0 : -1 }
        function createSessionForApp(index) {
            var session = sessionComponent.createObject(testCase)
            testCase.sessions.push(session)
            return session
        }
        function quitRunningApp() { testCase.quitCalls++ }
    }

    function init() {
        runningAppId = 0
        runningAppName = ""
        quitCalls = 0
        sessions = []
    }

    function cleanup() {
        for (var i = 0; i < sessions.length; i++) sessions[i].destroy()
    }

    function createFlow() {
        var component = Qt.createComponent(
                    Qt.resolvedUrl("../../app/gui/BulanSessionFlow.qml"))
        compare(component.status, Component.Ready, component.errorString())
        var flow = createTemporaryObject(component, this, {
            appModel: appModel,
            windowTarget: null
        })
        verify(flow !== null)
        return flow
    }

    function targetSnapshot() {
        return {
            appId: 42,
            name: "Hades II",
            hostName: "Desktop-PC",
            artworkUrl: "",
            artworkFallback: true,
            sourceRect: Qt.rect(400, 300, 200, 300)
        }
    }

    function test_cancelWaitsForCleanupAndReturnMotion() {
        var flow = createFlow()
        flow.requestPlay(targetSnapshot())
        tryCompare(flow, "state", "connecting")
        compare(sessions.length, 1)

        flow.cancel()
        compare(flow.state, "stopping")
        sessions[0].sessionFinished(0)
        compare(flow.state, "cleanup")

        sessions[0].readyForDeletion()
        compare(flow.state, "cleanup")
        compare(flow.returning, true)

        flow.completeReturn()
        compare(flow.state, "idle")
        compare(flow.session, null)
    }

    function test_cancelDuringInitializationInitializesBeforeStopping() {
        var flow = createFlow()
        flow.requestPlay(targetSnapshot())
        compare(flow.state, "initializing")

        flow.cancel()
        compare(flow.state, "stopping")
        tryCompare(sessions[0], "interruptCalls", 1)
        compare(sessions[0].initializeCalls, 1)
        compare(sessions[0].startedBeforeInitialize, false)
    }

    function test_switchWaitsForQuitBeforeCreatingSession() {
        runningAppId = 7
        runningAppName = "Control"
        var flow = createFlow()

        flow.requestPlay(targetSnapshot())
        compare(flow.confirmationVisible, true)
        compare(sessions.length, 0)

        flow.confirmSwitch()
        compare(flow.state, "stoppingPrevious")
        compare(quitCalls, 1)
        compare(sessions.length, 0)

        flow.quitCompleted(undefined)
        tryCompare(flow, "state", "connecting")
        compare(sessions.length, 1)
    }

    function test_dismissedSwitchReturnsArtworkBeforeResettingTarget() {
        runningAppId = 7
        runningAppName = "Control"
        var flow = createFlow()

        flow.requestPlay(targetSnapshot())
        flow.dismissConfirmation()

        compare(flow.state, "cleanup")
        compare(flow.returning, true)
        verify(flow.target !== null)
        flow.completeReturn()
        compare(flow.state, "idle")
        compare(flow.target, null)
    }

    function test_retryAfterQuitFailureRetriesQuit() {
        runningAppId = 7
        runningAppName = "Control"
        var flow = createFlow()

        flow.requestPlay(targetSnapshot())
        flow.confirmSwitch()
        flow.quitCompleted("host did not stop")
        compare(flow.state, "failed")

        flow.retry()
        compare(flow.state, "stoppingPrevious")
        compare(quitCalls, 2)
        compare(sessions.length, 0)
    }

    function test_hostLossAfterQuitBecomesRecoverableFailure() {
        runningAppId = 7
        runningAppName = "Control"
        var flow = createFlow()

        flow.requestPlay(targetSnapshot())
        flow.confirmSwitch()
        flow.appModel = null
        flow.quitCompleted(undefined)

        compare(flow.state, "failed")
        compare(flow.failureStage, "launch")
        compare(sessions.length, 0)
    }

    function test_retryCreatesFreshSessionOnlyAfterCleanup() {
        var flow = createFlow()
        flow.requestPlay(targetSnapshot())
        tryCompare(flow, "state", "connecting")

        sessions[0].displayLaunchError("technical detail")
        sessions[0].sessionFinished(0)
        compare(flow.state, "failed")

        flow.retry()
        compare(flow.state, "cleanup")
        compare(sessions.length, 1)

        sessions[0].readyForDeletion()
        tryCompare(flow, "state", "connecting")
        compare(sessions.length, 2)
    }
}
