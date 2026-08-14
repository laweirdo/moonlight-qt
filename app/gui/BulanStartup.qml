import QtQuick 2.9

FocusScope {
    id: root

    required property int startupDuration
    property bool active: true

    signal completed()

    function skip() {
        if (!active) {
            return
        }

        active = false
        completed()
    }

    Timer {
        interval: root.startupDuration
        running: root.active
        onTriggered: root.skip()
    }

    Keys.onPressed: function(event) {
        if (!root.active) {
            return
        }

        root.skip()
        event.accepted = true
    }

}
