import QtQuick 2.0
import QtQuick.Controls 2.2

import ComputerManager 1.0
import Session 1.0

import Bulan 1.0

Item {
    id: root

    property string appName
    property var quitRunningAppFn
    property Session nextSession : null
    property string nextAppName : ""

    // Deterministic QML-only quit review. AppView supplies an outcome and the
    // context a failure would return to; no ComputerManager signal or real quit
    // operation is involved while reviewMode is true.
    property bool reviewMode: false
    property string reviewOutcome: "success"
    property string reviewReturnTarget: "grid"
    property var reviewNextAppId: null
    property int reviewNextSourceIndex: -1
    property string reviewNextOrigin: "recent"
    property bool reviewNextSourceAvailable: true

    property string stageText : qsTr("Quitting %1...").arg(appName)

    function quitAppCompleted(error)
    {
        // Display a failed dialog if we got an error
        if (error !== undefined) {
            errorDialog.text = error
            errorDialog.open()
            console.error(error)
        }

        // If we're supposed to launch another game after this, do so now
        if (error === undefined && nextSession !== null) {
            var component = Qt.createComponent("StreamSegue.qml")
            var segue = component.createObject(stackView, {"appName": nextAppName, "session": nextSession})
            stackView.replace(segue)
        }
        else {
            // Exit this view
            stackView.pop()
        }
    }

    StackView.onActivated: {
        // Hide the toolbar before we start loading
        toolBar.visible = false

        if (reviewMode) {
            return
        }

        // Connect the quit completion signal
        ComputerManager.quitAppCompleted.connect(quitAppCompleted)

        // Start the quit operation if requested
        if (quitRunningAppFn) {
            quitRunningAppFn()
        }
    }

    StackView.onDeactivating: {
        // Show the toolbar again
        toolBar.visible = true

        if (!reviewMode) {
            // Disconnect the signal
            ComputerManager.quitAppCompleted.disconnect(quitAppCompleted)
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
            text: stageText
            font.pixelSize: Bulan.sizeBodyLg
            verticalAlignment: Text.AlignVCenter

            wrapMode: Text.Wrap
        }
    }

    ErrorMessageDialog {
        id: errorDialog
    }
}
