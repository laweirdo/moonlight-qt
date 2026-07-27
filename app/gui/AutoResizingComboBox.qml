import QtQuick 2.9
import QtQuick.Controls 2.2

import SdlGamepadKeyNavigation 1.0
import SystemProperties 1.0

// https://stackoverflow.com/questions/45029968/how-do-i-set-the-combobox-width-to-fit-the-largest-item
ComboBox {
    property int textWidth
    property int desiredWidth : leftPadding + textWidth + indicator.width + rightPadding
    property int maximumWidth : parent.width

    implicitWidth: desiredWidth < maximumWidth ? desiredWidth : maximumWidth

    TextMetrics {
        id: popupMetrics
    }

    TextMetrics {
        id: textMetrics
    }

    function recalculateWidth() {
        textMetrics.font = font
        popupMetrics.font = popup.font
        textWidth = 0
        for (var i = 0; i < count; i++){
            textMetrics.text = textAt(i)
            popupMetrics.text = textAt(i)
            textWidth = Math.max(textMetrics.width, textWidth)
            textWidth = Math.max(popupMetrics.width, textWidth)
        }
    }

    // We call this every time the options change (and init)
    // so we can adjust the combo box width here too
    onActivated: recalculateWidth()

    popup.onAboutToShow: {
        // Suspend the page's tab chain so the popup gets plain arrow keys.
        // Suspending rather than setting the mode outright: this popup knows it
        // is open, but not what the navigation style should be once it closes.
        SdlGamepadKeyNavigation.setNavModeSuspended(true)

        // Override the popup color to improve contrast with the overridden
        // Material 2 background color set in main.qml.
        if (SystemProperties.usesMaterial3Theme) {
            popup.background.color = "#424242"
        }
    }

    popup.onAboutToHide: {
        // Lift the suspension only. This also fires when the combo box is torn
        // down along with its page, which is after that page has already reset
        // the mode -- asserting a value here instead would strand the tab chain
        // on the next screen and silently kill its A button. See defect 1.
        SdlGamepadKeyNavigation.setNavModeSuspended(false)
    }

    Keys.onLeftPressed: {
        decrementCurrentIndex()
    }

    Keys.onRightPressed: {
        incrementCurrentIndex()
    }
}
