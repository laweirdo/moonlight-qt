import QtQuick 2.0
import QtQuick.Controls 2.2

import ComputerManager 1.0

import Bulan 1.0

Item {
    function onSearchingComputer() {
        stageLabel.text = qsTr("Establishing connection to PC...")
    }

    function onPairing(pcName, pin) {
        stageLabel.text = qsTr("Pairing... Please enter '%1' on %2.").arg(pin).arg(pcName)
    }

    function onFailed(message) {
        stageIndicator.visible = false
        // The launcher's own message, not this file's to rewrite.
        errorDialog.show("", message)
    }

    function onSuccess(appName) {
        stageIndicator.visible = false
        pairCompleteDialog.show("", qsTr("Pairing completed successfully"))
    }

    // Allow user to back out of pairing
    Keys.onEscapePressed: {
        Qt.quit()
    }
    Keys.onBackPressed: {
        Qt.quit()
    }
    Keys.onCancelPressed: {
        Qt.quit()
    }

    StackView.onActivated: {
        if (!launcher.isExecuted()) {

            launcher.searchingComputer.connect(onSearchingComputer)
            launcher.pairing.connect(onPairing)
            launcher.failed.connect(onFailed)
            launcher.success.connect(onSuccess)
            launcher.execute(ComputerManager)
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 5
        id: stageIndicator

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

    // Bulan panels, not the stock Dialogs these replaced -- see main.qml's
    // configuration warnings for why.
    HostPanel {
        id: errorDialog
        anchors.fill: parent
        onDismissed: Qt.quit()
    }

    HostPanel {
        id: pairCompleteDialog
        anchors.fill: parent
        onDismissed: Qt.quit()
    }
}
