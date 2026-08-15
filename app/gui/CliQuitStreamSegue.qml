import QtQuick 2.0
import QtQuick.Controls 2.2

import ComputerManager 1.0
import Session 1.0

import Bulan 1.0

Item {
    function onSearchingComputer() {
        stageLabel.text = qsTr("Establishing connection to PC...")
    }

    function onQuittingApp() {
        stageLabel.text = qsTr("Quitting app...")
    }

    function onFailure(message) {
        // The launcher's own message, not this file's to rewrite.
        errorDialog.show("", message)
    }

    StackView.onActivated: {
        if (!launcher.isExecuted()) {
            launcher.searchingComputer.connect(onSearchingComputer)
            launcher.quittingApp.connect(onQuittingApp)
            launcher.failed.connect(onFailure)
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
            text: stageText
            font.pixelSize: Bulan.sizeBodyLg
            verticalAlignment: Text.AlignVCenter

            wrapMode: Text.Wrap
        }
    }

    // A Bulan panel, not the stock Dialog it replaced -- see main.qml's
    // configuration warnings for why.
    HostPanel {
        id: errorDialog
        anchors.fill: parent
        onDismissed: Qt.quit()
    }
}
