import QtQuick 2.9

import Bulan 1.0
import ComputerManager 1.0
import ComputerModel 1.0
import StreamingPreferences 1.0

FocusScope {
    id: root
    objectName: qsTr("Bulan")
    focus: true

    readonly property bool bulanScreen: true
    property bool shellReady: false
    property string activeHostUuid: StreamingPreferences.lastHostUuid
    property var appModel: null
    property var hostContexts: ({})
    property ComputerModel computerModel: createComputerModel()

    readonly property real compositionScale: Math.min(
            width / Bulan.referenceWidth,
            height / Bulan.referenceHeight)

    function createComputerModel() {
        var model = Qt.createQmlObject(
                    'import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        return model
    }

    Atmosphere {
        anchors.fill: parent
    }

    Item {
        id: composition
        anchors.centerIn: parent
        width: Bulan.referenceWidth
        height: Bulan.referenceHeight
        scale: root.compositionScale

        Image {
            anchors.centerIn: parent
            visible: startup.active
            source: "qrc:/res/bulan_logo_vert.svg"
            height: Bulan.shellWordmarkHeight
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    BulanStartup {
        id: startup
        anchors.fill: parent
        focus: active
        startupDuration: Bulan.shellStartupMaxMs
        onCompleted: root.shellReady = true
    }

    MouseArea {
        anchors.fill: parent
        enabled: startup.active
        onClicked: startup.skip()
    }
}
