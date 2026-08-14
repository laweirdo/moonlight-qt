import QtQuick 2.9
import QtTest 1.2
import "../../app/gui" as Gui

TestCase {
    name: "BulanStartup"

    Component {
        id: subject

        Gui.BulanStartup {
            startupDuration: 20
        }
    }

    function test_timeoutCompletesOnce() {
        var startup = createTemporaryObject(subject, this)
        verify(startup !== null)

        var completions = 0
        startup.completed.connect(function() { completions++ })

        tryCompare(startup, "active", false, 100)
        compare(completions, 1)
    }

    function test_skipCompletesOnce() {
        var startup = createTemporaryObject(subject, this,
                                            { startupDuration: 1000 })
        verify(startup !== null)

        var completions = 0
        startup.completed.connect(function() { completions++ })

        startup.skip()
        startup.skip()

        compare(startup.active, false)
        compare(completions, 1)
    }

    function test_keyPressSkipsStartup() {
        var startup = createTemporaryObject(subject, this,
                                            { startupDuration: 1000 })
        verify(startup !== null)
        startup.forceActiveFocus()

        keyClick(Qt.Key_A)

        compare(startup.active, false)
    }
}
