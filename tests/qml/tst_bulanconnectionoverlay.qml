import QtQuick 2.9
import QtTest 1.2

import Bulan 1.0

TestCase {
    id: testCase
    name: "BulanConnectionOverlay"
    width: Bulan.referenceWidth
    height: Bulan.referenceHeight
    when: windowShown

    property int cancelRequests: 0
    property int retryRequests: 0
    property int returnCompletions: 0

    function createOverlay(properties) {
        var component = Qt.createComponent(
                    Qt.resolvedUrl("../../app/gui/BulanConnectionOverlay.qml"))
        compare(component.status, Component.Ready, component.errorString())
        var overlay = createTemporaryObject(component, this, properties || {})
        verify(overlay !== null)
        overlay.cancelRequested.connect(function() { cancelRequests++ })
        overlay.retryRequested.connect(function() { retryRequests++ })
        overlay.returnCompleted.connect(function() { returnCompletions++ })
        return overlay
    }

    function init() {
        cancelRequests = 0
        retryRequests = 0
        returnCompletions = 0
    }

    function snapshot() {
        return {
            appId: 42,
            name: "Hades II",
            hostName: "Desktop-PC",
            artworkUrl: "",
            artworkFallback: true,
            sourceRect: Qt.rect(400, 300, 200, 300)
        }
    }

    function test_connectingMovesArtworkToLaunchDestination() {
        var overlay = createOverlay({
            width: width,
            height: height,
            flowState: "connecting",
            target: snapshot()
        })
        tryCompare(overlay, "artworkX",
                   Bulan.launchDestinationCenterX
                   - Bulan.launchDestinationWidth / 2,
                   Bulan.motionTransitionMs * 3)
        compare(overlay.artworkY,
                Bulan.launchDestinationCenterY
                - Bulan.launchDestinationHeight / 2)
        compare(overlay.artworkWidth, Bulan.launchDestinationWidth)
        compare(overlay.artworkHeight, Bulan.launchDestinationHeight)
    }

    function test_actionsFollowLifecycleState() {
        var overlay = createOverlay({
            width: width,
            height: height,
            flowState: "connecting",
            target: snapshot()
        })
        overlay.triggerPrimary()
        compare(cancelRequests, 1)

        overlay.flowState = "failed"
        overlay.triggerPrimary()
        compare(retryRequests, 1)
    }

    function test_returnCompletesOnlyAfterReverseMotion() {
        var overlay = createOverlay({
            width: width,
            height: height,
            flowState: "cleanup",
            target: snapshot(),
            returning: true
        })
        compare(returnCompletions, 0)
        tryCompare(testCase, "returnCompletions", 1,
                   Bulan.motionTransitionMs * 3)
        compare(overlay.artworkX, snapshot().sourceRect.x)
        compare(overlay.artworkY, snapshot().sourceRect.y)
    }
}
