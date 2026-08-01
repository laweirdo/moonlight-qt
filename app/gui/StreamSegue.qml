import QtQuick 2.9
// Imported only for StackView attached lifecycle/status and StackView.Immediate.
// No stock Qt Quick Control is instantiated on this Bulan screen.
import QtQuick.Controls 2.2
import QtQuick.Window 2.2

import SdlGamepadKeyNavigation 1.0
import Session 1.0
import SystemProperties 1.0

import Bulan 1.0

// The selected game's launch route. The frozen artwork handed over by
// AppView remains the visual anchor while the existing Session lifecycle runs.
FocusScope {
    id: root
    focus: true

    property Session session
    property string appName: ""
    property bool isResume: false
    property bool quitAfter: false
    // AppView owns the QQuickItemGrabResult for the lifetime of this route so
    // its memory URL stays valid. CLI launches have no captured source and use
    // the same honest title-card fallback as Stage 2's no-source path.
    property url launchArtworkUrl: ""
    property bool launchArtworkFallback: true
    property string launchArtworkTitle: appName

    // "progress", "warning", or "failure". Raw Session warning/error strings
    // are logged for diagnosis but never become front-facing copy.
    property string surfaceState: "progress"
    property bool launchContentVisible: true
    property bool launchFailed: false
    property bool connectionBegan: false
    property bool sessionSignalsConnected: false
    property bool guiGamepadDisabled: false

    // Deterministic QML-only launch review. Production leaves reviewMode false
    // and follows initialize/start/finish exactly as before.
    property bool reviewMode: false
    property string reviewOutcome: "start"
    property var reviewAppId: null
    property int reviewSourceIndex: -1
    property string reviewOrigin: "recent"
    property bool reviewSourceAvailable: true
    property bool reviewRepeat: false
    property int reviewCycle: 0

    readonly property bool showingProgress: surfaceState === "progress"
    readonly property bool showingWarning: surfaceState === "warning"
    readonly property bool showingFailure: surfaceState === "failure"
    readonly property bool bulanScreen: true

    signal reviewCycleRequested(int cycle)

    function requestReviewCycle()
    {
        reviewCycle++
        reviewCycleRequested(reviewCycle)
    }

    function stageStarting(stage)
    {
        // Stage names are useful in the log, but they are transport detail and
        // do not replace the human Starting/Resuming title.
        console.log("Launch stage:", stage)
        surfaceState = "progress"
    }

    function stageFailed(stage, errorCode, failingPorts)
    {
        console.error("Launch stage failed:", stage,
                      "error", errorCode, "ports", failingPorts)
        launchFailed = true
    }

    function connectionStarted()
    {
        // Preserve the established window handoff once streaming begins.
        connectionBegan = true
        launchContentVisible = false
        window.visible = false
    }

    function displayLaunchError(text)
    {
        console.error("Launch failed:", text)
        launchFailed = true
    }

    function quitStarting()
    {
        // Preserve the immediate replacement used when Session turns a launch
        // into a quit operation.
        var component = Qt.createComponent("QuitSegue.qml")
        var segue = component.createObject(stackView, {"appName": appName})
        stackView.replace(stackView.currentItem, segue, StackView.Immediate)
        window.visible = true
    }

    function showFailure()
    {
        warningContinueTimer.stop()
        surfaceState = "failure"
        launchContentVisible = true
        window.visible = true
        forceActiveFocus()
        Qt.callLater(forceActiveFocus)
    }

    function sessionFinished(portTestResult)
    {
        warningContinueTimer.stop()
        if (portTestResult !== 0 && portTestResult !== -1 && launchFailed) {
            console.error("Launch port test result:", portTestResult)
        }

        // Preserve GUI gamepad restoration on every Session exit.
        SdlGamepadKeyNavigation.enable()
        guiGamepadDisabled = false

        if (launchFailed) {
            // Unlike the inherited global dialog path, failure stays on this
            // route until A or B returns to the retained AppView.
            showFailure()
            return
        }

        if (quitAfter) {
            Qt.quit()
            return
        }

        stackView.pop()
        window.visible = true
    }

    function sessionReadyForDeletion()
    {
        // Preserve the heavyweight Session cleanup contract.
        session = null
        gc()
    }

    function returnFromFailure()
    {
        if (!showingFailure) {
            return
        }
        if (quitAfter) {
            Qt.quit()
        } else {
            stackView.pop()
        }
    }

    function beginSession()
    {
        if (reviewMode || session === null || launchFailed) {
            return
        }
        surfaceState = "progress"
        gc()
        session.start()
    }

    function initializeSession()
    {
        if (reviewMode || session === null) {
            return
        }

        SdlGamepadKeyNavigation.disable()
        guiGamepadDisabled = true

        if (!session.initialize(window)) {
            if (!launchFailed) {
                console.error("Session initialization failed without detail")
                launchFailed = true
            }
            sessionFinished(0)
            sessionReadyForDeletion()
            return
        }

        var warnings = session.launchWarnings
        if (warnings && warnings.length > 0) {
            for (var i = 0; i < warnings.length; i++) {
                console.warn("Launch warning:", warnings[i])
            }
            surfaceState = "warning"
            warningContinueTimer.restart()
        } else {
            Qt.callLater(beginSession)
        }
    }

    StackView.onDeactivating: {
        warningContinueTimer.stop()
        reviewCycleTimer.stop()

        // Preserve the inherited toolbar/gamepad cleanup. main.qml's Bulan
        // backstop hides the toolbar again when the retained AppView returns.
        toolBar.visible = true
        if (!reviewMode && guiGamepadDisabled) {
            SdlGamepadKeyNavigation.enable()
            guiGamepadDisabled = false
        }
    }

    StackView.onActivated: {
        toolBar.visible = false
        launchContentVisible = true
        forceActiveFocus()
        Qt.callLater(forceActiveFocus)

        if (reviewMode) {
            if (reviewOutcome === "failure") {
                surfaceState = "failure"
            } else if (reviewOutcome === "warning") {
                // Review holds this state; production alone continues after the
                // approved warning duration.
                surfaceState = "warning"
            } else {
                surfaceState = "progress"
            }
            Qt.callLater(requestReviewCycle)
            return
        }

        if (!sessionSignalsConnected) {
            sessionSignalsConnected = true
            session.stageStarting.connect(stageStarting)
            session.stageFailed.connect(stageFailed)
            session.connectionStarted.connect(connectionStarted)
            session.displayLaunchError.connect(displayLaunchError)
            session.quitStarting.connect(quitStarting)
            session.sessionFinished.connect(sessionFinished)
            session.readyForDeletion.connect(sessionReadyForDeletion)
        }

        SystemProperties.waitForAsyncLoad()
        streamLoader.active = true
    }

    Timer {
        id: warningContinueTimer
        interval: Bulan.launchWarningDurationMs
        onTriggered: root.beginSession()
    }

    Timer {
        id: reviewCycleTimer
        interval: Bulan.launchReviewCycleMs
        repeat: true
        running: root.reviewMode && root.reviewRepeat
        onTriggered: root.requestReviewCycle()
    }

    Loader {
        id: streamLoader
        active: false
        asynchronous: true
        onLoaded: root.initializeSession()
        sourceComponent: Item {}
    }

    Atmosphere {
        anchors.fill: parent
    }

    Item {
        id: launchContent
        anchors.fill: parent
        visible: root.launchContentVisible

        Item {
            id: artworkFrame
            x: Bulan.launchDestinationCenterX - width / 2
            y: Bulan.launchDestinationCenterY - height / 2
            width: Bulan.launchDestinationWidth
            height: Bulan.launchDestinationHeight

            Rectangle {
                anchors.fill: parent
                visible: !capturedArtwork.visible
                radius: Bulan.radiusMd
                color: Bulan.bgSurface

                Text {
                    anchors.fill: parent
                    anchors.margins: Bulan.spaceMd
                    text: root.launchArtworkTitle || root.appName
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeBody
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 4
                }
            }

            Image {
                id: capturedArtwork
                anchors.fill: parent
                source: root.launchArtworkUrl
                visible: !root.launchArtworkFallback
                         && source !== "" && status === Image.Ready
                asynchronous: false
                cache: false
                fillMode: Image.Stretch
            }
        }

        Item {
            id: progressContent
            visible: root.showingProgress
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: artworkFrame.bottom
            anchors.topMargin: Bulan.spaceXl
            height: busyDots.height + Bulan.spaceXl + progressTitle.height

            Item {
                id: busyDots
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: Bulan.spaceSm * 3 + Bulan.space2xs * 2
                height: Bulan.spaceSm + Bulan.motionBusyBounceHeight

                property real phase
                NumberAnimation on phase {
                    running: progressContent.visible
                    from: 0
                    to: 1
                    duration: Bulan.motionBusyBounceMs
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }

                Repeater {
                    model: 3
                    Rectangle {
                        width: Bulan.spaceSm
                        height: width
                        radius: width / 2
                        color: Bulan.accentPrimary
                        x: index * (Bulan.spaceSm + Bulan.space2xs)
                        y: busyDots.height - height - lift

                        property real lift: {
                            var p = busyDots.phase
                                    - index * (Bulan.motionBusyStaggerMs
                                               / Bulan.motionBusyBounceMs)
                            p -= Math.floor(p)
                            return Math.sin(p * Math.PI)
                                    * Bulan.motionBusyBounceHeight
                        }
                    }
                }
            }

            Text {
                id: progressTitle
                anchors.top: busyDots.bottom
                anchors.topMargin: Bulan.spaceXl
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Bulan.layoutScreenMarginX
                anchors.rightMargin: Bulan.layoutScreenMarginX
                height: Bulan.lineHeightTitleLg
                text: root.isResume
                      ? qsTr("Resuming %1").arg(root.appName)
                      : qsTr("Starting %1").arg(root.appName)
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitleLg
                font.letterSpacing: Bulan.trackingTitle
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Column {
            id: messageContent
            visible: root.showingWarning || root.showingFailure
            anchors.top: artworkFrame.bottom
            anchors.topMargin: Bulan.spaceXl
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                            Bulan.hostTileSize * 2)
            spacing: Bulan.spaceMd

            Text {
                width: parent.width
                height: Bulan.lineHeightTitleLg
                text: root.showingFailure
                      ? (root.connectionBegan
                         ? qsTr("Couldn't continue %1").arg(root.appName)
                         : qsTr("Couldn't start %1").arg(root.appName))
                      : qsTr("Just a moment")
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
                      ? (root.connectionBegan
                         ? qsTr("Your session ended. You're back where you started.")
                         : qsTr("You're still right where you were. Try again from your games."))
                      : qsTr("Your PC shared a quick heads-up. We'll keep going.")
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
                    text: root.quitAfter ? qsTr("Close") : qsTr("Back to games")
                    color: Bulan.textPrimary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBody
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
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
                  : (root.showingWarning
                     ? qsTr("We'll continue automatically.")
                     : (root.isResume
                        ? qsTr("Picking up where you left off.")
                        : qsTr("Getting things ready.")))
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeCaption
            font.letterSpacing: Bulan.trackingCaption
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Progress and warning are deliberately non-cancellable. Failure is the
    // only interactive state; its single target is visibly focused and both A
    // and B return through the same safe route.
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
