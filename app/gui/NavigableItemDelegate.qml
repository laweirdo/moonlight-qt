import QtQuick 2.0
import QtQuick.Controls 2.2

import Bulan 1.0

ItemDelegate {
    id: control
    property GridView grid

    highlighted: grid.activeFocus && grid.currentItem === this

    // --- Bulan card ---------------------------------------------------------
    // Replaces the stock Material ripple background. Focus is the important
    // state on a handheld: it is the only thing telling you where the D-pad
    // will act, so it gets the amber border plus the warm bloom from the brief.
    background: Item {

        // Focus bloom. Drawn on Canvas because QtGraphicalEffects is gone in
        // Qt 6. The falloff must reach zero before the canvas edge on every
        // axis or it clips into a visible square, so the ellipse is sized from
        // the card's own half-extents plus a fixed inset.
        Canvas {
            id: bloom
            anchors.fill: parent
            visible: control.highlighted
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var ax = width / 2
                var ay = height / 2

                ctx.save()
                ctx.translate(width / 2, height / 2)
                ctx.scale(ax / ay, 1)

                var g = ctx.createRadialGradient(0, 0, 0, 0, 0, ay)
                // Eased rolloff — a linear alpha fade still reads as a visible
                // disc edge against the dark ground.
                g.addColorStop(0.00, Qt.rgba(1, 0.85, 0.63, 0.22))
                g.addColorStop(0.25, Qt.rgba(1, 0.85, 0.63, 0.135))
                g.addColorStop(0.45, Qt.rgba(1, 0.85, 0.63, 0.075))
                g.addColorStop(0.65, Qt.rgba(1, 0.85, 0.63, 0.034))
                g.addColorStop(0.82, Qt.rgba(1, 0.85, 0.63, 0.011))
                g.addColorStop(1.00, Qt.rgba(1, 0.85, 0.63, 0.0))
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(0, 0, ay, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Bulan.spaceSm
            radius: Bulan.radiusLg

            color: control.pressed ? Bulan.surfacePressed
                 : (control.highlighted || control.hovered) ? Bulan.surfaceHover
                 : Bulan.bgSurface

            border.width: control.highlighted ? 2 : 1
            border.color: control.highlighted ? Bulan.accentPrimary
                        : control.hovered ? Bulan.secondary
                        : Bulan.hairline

            // Confident, not elaborate — the brief's motion note.
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            scale: control.pressed ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: 90 } }
        }
    }

    Keys.onLeftPressed: {
        grid.moveCurrentIndexLeft()
    }
    Keys.onRightPressed: {
        grid.moveCurrentIndexRight()
    }
    Keys.onDownPressed: {
        grid.moveCurrentIndexDown()
    }
    Keys.onUpPressed: {
        grid.moveCurrentIndexUp()

        // If we've reached the top of the grid, move focus to the toolbar
        if (grid.currentItem === this) {
            nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocus)
        }
    }
    Keys.onReturnPressed: {
        clicked()
    }
    Keys.onEnterPressed: {
        clicked()
    }
}
