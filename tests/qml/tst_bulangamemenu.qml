import QtQuick 2.9
import QtTest 1.2

TestCase {
    name: "BulanGameMenu"
    when: windowShown

    SignalSpy {
        id: actionSpy
        signalName: "actionRequested"
    }

    function test_actionKeepsAppIdSnapshot() {
        var component = Qt.createComponent(
                    Qt.resolvedUrl("../../app/gui/BulanGameMenu.qml"))
        compare(component.status, Component.Ready, component.errorString())
        var menu = createTemporaryObject(component, this)
        verify(menu !== null)
        actionSpy.target = menu

        menu.showForGame({
            appId: 42,
            name: "Hades II",
            running: false,
            hidden: false,
            directLaunch: false
        })
        menu.requestAction("toggleHidden")

        compare(actionSpy.count, 1)
        compare(actionSpy.signalArguments[0][0], "toggleHidden")
        compare(actionSpy.signalArguments[0][1], 42)
    }
}
