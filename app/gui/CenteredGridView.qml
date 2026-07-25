import QtQuick 2.9
import QtQuick.Controls 2.2

import Bulan 1.0

GridView {
    // Screen margin from the token file. Upstream used a flat 10px, which puts
    // cards hard against the panel edge on a handheld.
    property int minMargin: Bulan.layoutScreenMarginX
    property real availableWidth: (parent.width - 2 * minMargin)
    property int itemsPerRow: availableWidth / cellWidth
    property real horizontalMargin: itemsPerRow < count && availableWidth >= cellWidth ?
                                        (availableWidth % cellWidth) / 2 : minMargin

    function updateMargins() {
        leftMargin = horizontalMargin
        rightMargin = horizontalMargin
    }

    onHorizontalMarginChanged: {
        updateMargins()
    }

    Component.onCompleted: {
        updateMargins()
    }

    boundsBehavior: Flickable.OvershootBounds
}
