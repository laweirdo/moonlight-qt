import QtQuick 2.9

import Bulan 1.0

FocusScope {
    id: root

    property string flowState: "idle"
    property var target: null
    property bool returning: false
    property bool confirmationVisible: false
    property string runningAppName: ""
    property real artworkProgress: 0
    property bool returnReported: false
    property bool motionReady: false

    readonly property rect sourceRect: target && target.sourceRect
                                       ? target.sourceRect : Qt.rect(0, 0, 0, 0)
    readonly property real destinationX: Bulan.launchDestinationCenterX
                                         - Bulan.launchDestinationWidth / 2
    readonly property real destinationY: Bulan.launchDestinationCenterY
                                         - Bulan.launchDestinationHeight / 2
    readonly property real artworkX: sourceRect.x
                                     + (destinationX - sourceRect.x)
                                       * artworkProgress
    readonly property real artworkY: sourceRect.y
                                     + (destinationY - sourceRect.y)
                                       * artworkProgress
    readonly property real artworkWidth: sourceRect.width
                                         + (Bulan.launchDestinationWidth
                                            - sourceRect.width) * artworkProgress
    readonly property real artworkHeight: sourceRect.height
                                          + (Bulan.launchDestinationHeight
                                             - sourceRect.height) * artworkProgress
    readonly property bool active: confirmationVisible || flowState !== "idle"
    readonly property bool canCancel: flowState === "initializing"
                                      || flowState === "warning"
                                      || flowState === "connecting"

    signal cancelRequested()
    signal retryRequested()
    signal dismissFailureRequested()
    signal confirmSwitchRequested()
    signal dismissConfirmationRequested()
    signal returnCompleted()

    visible: active
    enabled: active
    focus: active

    function phaseText() {
        if (confirmationVisible) return qsTr("Ready to switch?")
        if (flowState === "initializing") return qsTr("Getting ready…")
        if (flowState === "warning") return qsTr("Checking your setup…")
        if (flowState === "connecting") return qsTr("Connecting…")
        if (flowState === "stopping" || flowState === "stoppingPrevious") {
            return qsTr("Stopping…")
        }
        if (flowState === "failed") return qsTr("Couldn’t connect")
        return qsTr("Welcome back")
    }

    function detailText() {
        if (confirmationVisible) {
            return qsTr("Stop %1 and start %2?")
                    .arg(runningAppName).arg(target ? target.name : "")
        }
        if (flowState === "failed") {
            return qsTr("Try again, or return to your library.")
        }
        if (target && target.hostName) return target.hostName
        return ""
    }

    function triggerPrimary() {
        if (confirmationVisible) confirmSwitchRequested()
        else if (flowState === "failed") retryRequested()
        else if (canCancel) cancelRequested()
    }

    function triggerSecondary() {
        if (confirmationVisible) dismissConfirmationRequested()
        else if (flowState === "failed") dismissFailureRequested()
        else if (canCancel) cancelRequested()
    }

    function beginMotion() {
        if (!motionReady || !active || !target) return
        returnReported = false
        if (returning) {
            Qt.callLater(function() {
                root.artworkProgress = 0
                returnTimer.restart()
            })
        } else {
            returnTimer.stop()
            Qt.callLater(function() { root.artworkProgress = 1 })
        }
    }

    onActiveChanged: beginMotion()
    onTargetChanged: beginMotion()
    onReturningChanged: beginMotion()
    Component.onCompleted: {
        if (returning && target) artworkProgress = 1
        motionReady = true
        beginMotion()
    }

    Behavior on artworkProgress {
        enabled: root.motionReady
        NumberAnimation {
            duration: Bulan.motionTransitionMs
            easing.type: Easing.InOutCubic
        }
    }

    Timer {
        id: returnTimer
        interval: Bulan.motionTransitionMs
        onTriggered: {
            if (root.returning && !root.returnReported) {
                root.returnReported = true
                root.returnCompleted()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Bulan.popupScrim
    }

    Rectangle {
        id: artworkFrame
        x: root.artworkX
        y: root.artworkY
        width: root.artworkWidth
        height: root.artworkHeight
        radius: Bulan.radiusMd
        color: Bulan.bgSurface
        border.width: Bulan.space2xs / 2
        border.color: Bulan.accentGlow
        clip: true

        Image {
            anchors.fill: parent
            source: root.target ? root.target.artworkUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: root.target && !root.target.artworkFallback
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: artworkFrame.bottom
        anchors.topMargin: Bulan.spaceLg
        width: parent.width - Bulan.layoutScreenMarginX * 2
        spacing: Bulan.spaceXs

        Text {
            width: parent.width
            text: root.phaseText()
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.weight: Bulan.weightDisplay
            font.pixelSize: Bulan.sizeTitle
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: root.detailText()
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.weight: Bulan.weightBody
            font.pixelSize: Bulan.sizeLabel
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    HintBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.confirmationVisible || root.canCancel
                 || root.flowState === "failed"
        leftHints: root.confirmationVisible
                   ? [{ action: "confirm", label: qsTr("Switch") }]
                   : root.flowState === "failed"
                     ? [{ action: "confirm", label: qsTr("Retry") }]
                     : []
        rightHints: root.confirmationVisible
                    ? [{ action: "back", label: qsTr("Keep playing") }]
                    : root.flowState === "failed"
                      ? [{ action: "back", label: qsTr("Back") }]
                      : [{ action: "back", label: qsTr("Cancel") }]
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.triggerPrimary()
        } else {
            event.accepted = true
        }
    }
    Keys.onEscapePressed: function(event) {
        root.triggerSecondary()
        event.accepted = true
    }
    Keys.onBackPressed: function(event) {
        root.triggerSecondary()
        event.accepted = true
    }
}
