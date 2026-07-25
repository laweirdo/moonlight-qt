import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Bulan 1.0

ToolButton {
    id: control
    property string iconSource

    activeFocusOnTab: true

    // Stock ToolButton gives no visible keyboard-focus affordance, which makes
    // the toolbar unusable with a D-pad. Give it the same amber focus language
    // as the grid cards.
    background: Rectangle {
        implicitWidth: Bulan.targetMin
        implicitHeight: Bulan.targetMin
        radius: Bulan.radiusSm
        color: control.pressed ? Bulan.surfacePressed
             : (control.visualFocus || control.hovered) ? Bulan.surfaceHover
             : "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Bulan.accentPrimary
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    icon.color: control.visualFocus ? Bulan.accentPrimary : Bulan.textSecondary

    icon.source: iconSource
    icon.width: Bulan.spaceXl
    icon.height: Bulan.spaceXl

    // This determines the size of the Material highlight. We increase it
    // from the default because we use larger than normal icons for TV readability.
    Layout.preferredHeight: parent.height

    Keys.onReturnPressed: {
        clicked()
    }

    Keys.onEnterPressed: {
        clicked()
    }

    Keys.onRightPressed: {
        nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocus)
    }

    Keys.onLeftPressed: {
        nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocus)
    }
}
