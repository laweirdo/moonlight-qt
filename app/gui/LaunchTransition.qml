import QtQuick 2.9

import Bulan 1.0

// One frozen launch proxy above the StackView. Geometry and crop are assigned
// once before motion; the animation touches transforms and opacity only.
Item {
    id: transition

    signal proxyReady()
    signal finished()
    signal failed()

    property var owner: null
    property rect sourceRect: Qt.rect(0, 0, 0, 0)
    property rect sourceCrop: Qt.rect(0, 0, 0, 0)
    property rect destinationRect: Qt.rect(0, 0, 0, 0)
    property real sourceOpacity: 1
    property bool useFallback: false
    property string fallbackTitle: ""
    property bool running: false

    visible: proxy.visible
    enabled: running

    function prepare(captureUrl, contract) {
        motion.stop()
        proxy.visible = false
        frozenImage.source = ""
        sourceRect = contract.visibleRect
        sourceCrop = contract.sourceCrop
        destinationRect = contract.destinationCropRect
        sourceOpacity = contract.opacity
        useFallback = contract.fallback === true
        fallbackTitle = contract.gameName
        proxyTranslate.x = 0
        proxyTranslate.y = 0
        proxyScale.xScale = 1
        proxyScale.yScale = 1
        proxy.opacity = sourceOpacity
        running = true
        if (useFallback) {
            Qt.callLater(function() {
                if (transition.running && transition.useFallback) {
                    transition.proxyReady()
                }
            })
        } else {
            frozenImage.source = captureUrl
        }
    }

    function start() {
        proxy.visible = true
        forceActiveFocus()
        motion.start()
    }

    function completeImmediately() {
        if (!running || !proxy.visible) {
            return
        }
        motion.stop()
        proxyTranslate.x = destinationRect.x - sourceRect.x
        proxyTranslate.y = destinationRect.y - sourceRect.y
        proxyScale.xScale = sourceRect.width > 0
                ? destinationRect.width / sourceRect.width : 1
        proxyScale.yScale = sourceRect.height > 0
                ? destinationRect.height / sourceRect.height : 1
        proxy.opacity = 1
        transition.finished()
    }

    function clear() {
        motion.stop()
        running = false
        owner = null
        proxy.visible = false
        frozenImage.source = ""
    }

    Item {
        id: proxy
        x: transition.sourceRect.x
        y: transition.sourceRect.y
        width: transition.sourceRect.width
        height: transition.sourceRect.height
        visible: false
        transform: Translate {
            id: proxyTranslate
        }

        Item {
            id: visualProxy
            anchors.fill: parent
            transform: Scale {
                id: proxyScale
                origin.x: 0
                origin.y: 0
            }

            Image {
                id: frozenImage
                anchors.fill: parent
                visible: !transition.useFallback
                asynchronous: false
                cache: false
                fillMode: Image.Stretch
                sourceClipRect: transition.sourceCrop

                onStatusChanged: {
                    if (transition.running && status === Image.Ready) {
                        transition.proxyReady()
                    } else if (transition.running && status === Image.Error) {
                        transition.failed()
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: transition.useFallback
                radius: Bulan.radiusMd
                color: Bulan.bgSurface

                Text {
                    anchors.fill: parent
                    anchors.margins: Bulan.spaceMd
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 4
                    text: transition.fallbackTitle
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeBody
                }
            }
        }
    }

    SequentialAnimation {
        id: motion

        ParallelAnimation {
            NumberAnimation {
                target: proxyTranslate
                property: "x"
                from: 0
                to: transition.destinationRect.x - transition.sourceRect.x
                duration: Bulan.motionTransitionMs
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: proxyTranslate
                property: "y"
                from: 0
                to: transition.destinationRect.y - transition.sourceRect.y
                duration: Bulan.motionTransitionMs
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: proxyScale
                property: "xScale"
                from: 1
                to: transition.sourceRect.width > 0
                    ? transition.destinationRect.width / transition.sourceRect.width : 1
                duration: Bulan.motionTransitionMs
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: proxyScale
                property: "yScale"
                from: 1
                to: transition.sourceRect.height > 0
                    ? transition.destinationRect.height / transition.sourceRect.height : 1
                duration: Bulan.motionTransitionMs
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: proxy
                property: "opacity"
                from: transition.sourceOpacity
                to: 1
                duration: Bulan.motionTransitionMs
                easing.type: Easing.InOutQuad
            }
        }

        ScriptAction { script: transition.finished() }
    }

    Keys.onPressed: function(event) {
        if (transition.running && proxy.visible) {
            transition.completeImmediately()
            event.accepted = true
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: transition.running && proxy.visible
        onPressed: transition.completeImmediately()
    }
}
