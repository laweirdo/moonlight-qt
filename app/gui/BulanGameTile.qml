import QtQuick 2.9
import QtQuick.Effects

import Bulan 1.0

Item {
    id: root

    property string gameName: ""
    property int appId: 0
    property url boxart: ""
    property bool running: false
    property bool selected: false
    property bool appCollectorGame: false
    property real tileWidth: Bulan.gameTileWidth
    property real tileHeight: Bulan.gameTileHeight

    width: tileWidth
    height: tileHeight + Bulan.gameRecentLabelGap + Bulan.lineHeightLabel

    Behavior on tileWidth {
        NumberAnimation {
            duration: Bulan.motionFocusMs
            easing.type: Easing.OutBack
            easing.overshoot: Bulan.motionOvershoot
        }
    }

    Behavior on tileHeight {
        NumberAnimation {
            duration: Bulan.motionFocusMs
            easing.type: Easing.OutBack
            easing.overshoot: Bulan.motionOvershoot
        }
    }

    Rectangle {
        id: artworkFrame
        objectName: "artwork"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.tileWidth
        height: root.tileHeight
        radius: Bulan.radiusMd
        color: Bulan.bgSurface
        border.width: root.selected ? Bulan.space2xs : Bulan.space2xs / 4
        border.color: root.selected ? Bulan.accentGlow : Bulan.hairline
        layer.enabled: root.selected
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Bulan.accentGlow
            shadowOpacity: Bulan.focusBloomOpacity
            shadowBlur: Bulan.buttonGlowBlur
        }

        Behavior on border.color {
            ColorAnimation { duration: Bulan.motionFocusMs }
        }

        Rectangle {
            id: artworkMask
            anchors.fill: parent
            anchors.margins: Bulan.space2xs
            radius: Bulan.radiusMd
            visible: false
            layer.enabled: true
        }

        Image {
            id: artwork
            objectName: "boxArtImage"
            anchors.fill: artworkMask
            source: root.boxart
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            readonly property bool isPlaceholder:
                !root.appCollectorGame && status === Image.Ready
                && ((sourceSize.width === 130 && sourceSize.height === 180)
                    || (sourceSize.width === 628 && sourceSize.height === 888)
                    || (sourceSize.width === 200 && sourceSize.height === 266))
            readonly property bool showArt: status === Image.Ready && !isPlaceholder
            opacity: showArt ? 1 : 0
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artworkMask
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Bulan.motionFocusMs
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Text {
        id: title
        objectName: "gameTitle"
        anchors.top: artworkFrame.bottom
        anchors.topMargin: Bulan.gameRecentLabelGap
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.tileWidth
        height: Bulan.lineHeightLabel
        text: root.gameName
        color: root.selected ? Bulan.textPrimary : Bulan.textSecondary
        font.family: Bulan.familyUi
        font.weight: Bulan.weightBody
        font.pixelSize: Bulan.sizeLabel
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
