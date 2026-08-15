import QtQuick 2.0
import QtQuick.Controls 2.2

import ComputerManager 1.0

import Bulan 1.0

Item {
    function onSearchingComputer() {
        stageLabel.text = qsTr("Establishing connection to PC...")
    }

    function onSearchingApp() {
        stageLabel.text = qsTr("Loading app list...")
    }

    function onSessionCreated(appName, session) {
        var component = Qt.createComponent("StreamSegue.qml")
        var segue = component.createObject(stackView, {
            "appName": appName,
            "session": session,
            "quitAfter": true
        })
        // CLI entry routes stay free of competing stack motion (brief
        // decision 7, out-of-scope table).
        stackView.push(segue, StackView.Immediate)
    }

    function onLaunchFailed(message) {
        // The message comes from the launcher and is not this file's to
        // rewrite; the log line stays, because a CLI route is the one place a
        // technical string genuinely belongs.
        errorDialog.show("", message)
        console.error(message)
    }

    function onAppQuitRequired(appName) {
        quitAppDialog.appName = appName
        quitAppDialog.show("", qsTr("Are you sure you want to quit %1? Any unsaved progress will be lost.")
                                   .arg(appName))
    }

    StackView.onActivated: {
        if (!launcher.isExecuted()) {

            launcher.searchingComputer.connect(onSearchingComputer)
            launcher.searchingApp.connect(onSearchingApp)
            launcher.sessionCreated.connect(onSessionCreated)
            launcher.failed.connect(onLaunchFailed)
            launcher.appQuitRequired.connect(onAppQuitRequired)
            launcher.execute(ComputerManager)
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 5

        BusyIndicator {
            id: stageSpinner
            running: visible
        }

        Label {
            id: stageLabel
            height: stageSpinner.height
            font.pixelSize: Bulan.sizeBodyLg
            verticalAlignment: Text.AlignVCenter

            wrapMode: Text.Wrap
        }
    }

    // Bulan panels, not the stock Dialogs these replaced. Same reasoning as
    // main.qml's configuration warnings: a stock Dialog lives in Qt's own
    // overlay layer and brings Material controls with it.
    HostPanel {
        id: errorDialog
        anchors.fill: parent
        onDismissed: Qt.quit()
    }

    HostPanel {
        id: quitAppDialog
        anchors.fill: parent
        property string appName: ""

        // Yes/No became confirm/dismiss: the panel has one confirm action and
        // one way out, which is what Yes and No were.
        confirmable: true

        onAccepted: {
            var component = Qt.createComponent("QuitSegue.qml")
            var params = {"appName": appName, "quitRunningAppFn": function() { launcher.quitRunningApp() }}
            // CLI entry routes stay free of competing stack motion (brief
            // decision 7, out-of-scope table).
            stackView.push(component.createObject(stackView, params), StackView.Immediate)
        }
        // Declining a quit on a CLI route leaves nothing to return to, exactly
        // as the stock dialog's onRejected did.
        onDismissed: {
            if (!quitAppDialog.confirmed) {
                Qt.quit()
            }
        }
    }
}
