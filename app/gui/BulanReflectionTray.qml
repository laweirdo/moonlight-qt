import QtQuick 2.9

import Bulan 1.0

FocusScope {
    id: tray

    default property alias trayContent: content.data
    property string title: ""
    property var leftHints: []
    property var rightHints: [{ action: "back", label: qsTr("Close") }]
    property bool opened: false

    signal dismissed()

    visible: tray.opened || motion.progress > 0
    enabled: tray.opened
    z: 100

    function show() {
        opened = true
        forceActiveFocus()
    }

    function close() {
        if (!opened) return
        focus = false
        opened = false
        dismissed()
    }

    PopupMotion {
        id: motion
        open: tray.opened
    }

    Rectangle {
        anchors.fill: parent
        color: Bulan.popupScrim
        opacity: motion.scrimOpacity

        MouseArea {
            anchors.fill: parent
            onClicked: tray.close()
        }
    }

    Rectangle {
        id: surface
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Bulan.spaceLg
        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                        Bulan.hostTileSize * 2)
        height: Math.min(parent.height - hintBar.height - Bulan.space3xl,
                         content.implicitHeight + Bulan.spaceXl * 2)
        radius: Bulan.radiusXl
        color: Bulan.popupGlassSurface
        border.width: Bulan.space2xs / 4
        border.color: Bulan.popupGlassBorder
        scale: motion.surfaceScale
        opacity: motion.surfaceOpacity

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - Bulan.spaceXl * 2
            spacing: Bulan.spaceMd

            Text {
                width: parent.width
                text: tray.title
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.weight: Bulan.weightDisplay
                font.pixelSize: Bulan.sizeTitle
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: Bulan.space2xs / 4
                color: Bulan.hairline
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: Bulan.spaceMd
            width: Bulan.targetMin * 2
            height: Bulan.space2xs / 2
            radius: height / 2
            color: Bulan.secondary
            opacity: Bulan.disabledOpacity
        }
    }

    Rectangle {
        anchors.fill: hintBar
        visible: hintBar.visible
        color: Bulan.bgBaseOled
    }

    HintBar {
        id: hintBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: tray.opened || motion.progress > 0
        leftHints: tray.leftHints
        rightHints: tray.rightHints
    }

    Keys.onEscapePressed: function(event) {
        tray.close()
        event.accepted = true
    }
    Keys.onBackPressed: function(event) {
        tray.close()
        event.accepted = true
    }
}
