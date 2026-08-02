import QtQuick 2.9
// Imported only for StackView attached lifecycle. No stock control is
// instantiated on this Bulan screen.
import QtQuick.Controls 2.2

import ComputerManager 1.0

import Bulan 1.0

// The quit route owns the real ComputerManager wait and nothing beyond it.
// AppView prepares any switch Session and frozen launch source before this
// screen is pushed, then supplies callbacks for the success/failure handoff.
FocusScope {
    id: root
    focus: true

    property string appName: ""
    property string nextAppName: ""
    property string returnTarget: "grid"
    property var quitRunningAppFn
    property var successFn
    property var failureReturnFn

    // Deterministic QML-only quit review. Production alone connects to
    // ComputerManager and invokes the real quit operation.
    property bool reviewMode: false
    property string reviewOutcome: "pending"

    property string surfaceState: "progress"
    property bool quitStarted: false
    property bool completionHandled: false
    property bool quitSignalConnected: false
    property bool failureReturnHandled: false

    readonly property bool switching: nextAppName !== ""
    readonly property bool showingProgress: surfaceState === "progress"
    readonly property bool showingFailure: surfaceState === "failure"
    readonly property bool bulanScreen: true

    function disconnectQuitSignal()
    {
        if (!quitSignalConnected) {
            return
        }
        ComputerManager.quitAppCompleted.disconnect(quitAppCompleted)
        quitSignalConnected = false
    }

    function showFailure()
    {
        surfaceState = "failure"
        forceActiveFocus()
        Qt.callLater(forceActiveFocus)
    }

    function quitAppCompleted(error)
    {
        if (completionHandled) {
            return
        }
        completionHandled = true
        disconnectQuitSignal()

        // The raw backend text stays in the log. Front-facing copy below is
        // deliberately stable, human, and free of transport detail.
        if (error !== undefined) {
            console.error("Quit failed:", error)
            showFailure()
            return
        }

        if (successFn) {
            successFn()
        }
        stackView.pop()
    }

    function returnFromFailure()
    {
        if (!showingFailure || failureReturnHandled) {
            return
        }
        failureReturnHandled = true
        if (failureReturnFn) {
            failureReturnFn()
        }
        stackView.pop()
    }

    StackView.onActivated: {
        toolBar.visible = false
        forceActiveFocus()
        Qt.callLater(forceActiveFocus)

        if (quitStarted) {
            return
        }
        quitStarted = true

        if (reviewMode) {
            if (reviewOutcome === "failure") {
                completionHandled = true
                showFailure()
            } else if (reviewOutcome === "success") {
                // Keep the same success callback/pop order as production while
                // guaranteeing that review never touches ComputerManager.
                Qt.callLater(function() { root.quitAppCompleted(undefined) })
            }
            return
        }

        ComputerManager.quitAppCompleted.connect(quitAppCompleted)
        quitSignalConnected = true

        if (quitRunningAppFn) {
            quitRunningAppFn()
        }
    }

    StackView.onDeactivating: {
        toolBar.visible = true
        disconnectQuitSignal()
    }

    // AppView and StreamSegue push this route as a pre-created Item, which
    // StackView does not own. Destroy it after pop/replace completes.
    StackView.onRemoved: destroy()

    Component.onDestruction: disconnectQuitSignal()

    Atmosphere {
        anchors.fill: parent
    }

    Item {
        anchors.fill: parent

        Column {
            id: messageContent
            anchors.centerIn: parent
            width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                            Bulan.hostTileSize * 2)
            spacing: Bulan.spaceLg

            Item {
                id: busyDots
                visible: root.showingProgress
                anchors.horizontalCenter: parent.horizontalCenter
                width: Bulan.spaceSm * 3 + Bulan.space2xs * 2
                height: Bulan.spaceSm + Bulan.motionBusyBounceHeight

                Repeater {
                    model: 3
                    Rectangle {
                        id: busyDot
                        width: Bulan.spaceSm
                        height: width
                        radius: width / 2
                        color: Bulan.accentPrimary
                        x: index * (Bulan.spaceSm + Bulan.space2xs)
                        y: busyDots.height - height

                        readonly property int travelMs:
                            (Bulan.motionBusyBounceMs
                             - Bulan.motionBusyStaggerMs * 2) / 2

                        SequentialAnimation on y {
                            running: busyDots.visible
                            loops: Animation.Infinite
                            PauseAnimation {
                                duration: index * Bulan.motionBusyStaggerMs
                            }
                            NumberAnimation {
                                from: busyDots.height - busyDot.height
                                to: busyDots.height - busyDot.height
                                    - Bulan.motionBusyBounceHeight
                                duration: busyDot.travelMs
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: busyDots.height - busyDot.height
                                    - Bulan.motionBusyBounceHeight
                                to: busyDots.height - busyDot.height
                                duration: busyDot.travelMs
                                easing.type: Easing.InOutQuad
                            }
                            PauseAnimation {
                                duration: (2 - index)
                                          * Bulan.motionBusyStaggerMs
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                height: Bulan.lineHeightTitleLg
                text: root.showingFailure
                      ? qsTr("Couldn't quit %1").arg(root.appName)
                      : (root.switching
                         ? qsTr("Making room for %1").arg(root.nextAppName)
                         : qsTr("Quitting %1").arg(root.appName))
                color: root.showingFailure ? Bulan.statusError
                                           : Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitleLg
                font.letterSpacing: Bulan.trackingTitle
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.showingFailure
                      ? qsTr("It's still running. You're right where you were.")
                      : (root.switching
                         ? qsTr("We'll start %1 as soon as %2 closes.")
                           .arg(root.nextAppName).arg(root.appName)
                         : qsTr("Closing things gently."))
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBody
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Rectangle {
                id: failureButton
                visible: root.showingFailure
                anchors.horizontalCenter: parent.horizontalCenter
                width: Bulan.hostTileSize
                height: Bulan.targetMin
                radius: Bulan.radiusMd
                color: Bulan.surfaceHover
                border.width: Bulan.space2xs / 2
                border.color: Bulan.accentPrimary

                Text {
                    anchors.centerIn: parent
                    text: root.returnTarget === "options"
                          ? qsTr("Back to options") : qsTr("Back to games")
                    color: Bulan.textPrimary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBody
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.showingFailure
                             && !root.failureReturnHandled
                    onClicked: root.returnFromFailure()
                }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Bulan.layoutScreenMarginX
            anchors.rightMargin: Bulan.layoutScreenMarginX
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Bulan.space2xl + Bulan.spaceXs
            text: root.showingFailure
                  ? qsTr("Press A or B when you're ready.")
                  : (root.switching
                     ? qsTr("Waiting for your PC to finish up.")
                     : qsTr("Just a moment."))
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeCaption
            font.letterSpacing: Bulan.trackingCaption
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Progress is deliberately non-cancellable. Failure is the only
    // interactive state, with one visible 64px target and A/B parity.
    Keys.onReturnPressed: function(event) {
        if (root.showingFailure) root.returnFromFailure()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        if (root.showingFailure) root.returnFromFailure()
        event.accepted = true
    }
    Keys.onSpacePressed: function(event) {
        if (root.showingFailure) root.returnFromFailure()
        event.accepted = true
    }
    Keys.onEscapePressed: function(event) {
        if (root.showingFailure) root.returnFromFailure()
        event.accepted = true
    }
    Keys.onBackPressed: function(event) {
        if (root.showingFailure) root.returnFromFailure()
        event.accepted = true
    }
    Keys.onLeftPressed: function(event) { event.accepted = true }
    Keys.onRightPressed: function(event) { event.accepted = true }
    Keys.onUpPressed: function(event) { event.accepted = true }
    Keys.onDownPressed: function(event) { event.accepted = true }
    Keys.onMenuPressed: function(event) { event.accepted = true }
    Keys.onHangupPressed: function(event) { event.accepted = true }
    Keys.onCallPressed: function(event) { event.accepted = true }
    Keys.onContext1Pressed: function(event) { event.accepted = true }
    Keys.onContext2Pressed: function(event) { event.accepted = true }
    Keys.onContext3Pressed: function(event) { event.accepted = true }
    Keys.onPressed: function(event) { event.accepted = true }
}
