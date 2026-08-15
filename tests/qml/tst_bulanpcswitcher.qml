import QtQuick 2.9
import QtTest 1.2

TestCase {
    name: "BulanPcSwitcher"
    when: windowShown

    SignalSpy {
        id: actionSpy
        signalName: "actionRequested"
    }

    function test_chooseKeepsHostUuidAfterReorder() {
        var component = Qt.createComponent(
                    Qt.resolvedUrl("../../app/gui/BulanPcSwitcher.qml"))
        compare(component.status, Component.Ready, component.errorString())
        var switcher = createTemporaryObject(component, this)
        verify(switcher !== null)
        actionSpy.target = switcher

        switcher.hosts = [
            { uuid: "host-a", name: "Alpha", online: true, paired: true,
              wakeable: false, statusUnknown: false, address: "10.0.0.1" },
            { uuid: "host-b", name: "Beta", online: false, paired: true,
              wakeable: true, statusUnknown: false, address: "10.0.0.2" }
        ]
        switcher.activeHostUuid = "host-b"
        switcher.show()
        compare(switcher.enabled, true)
        compare(switcher.selectedHostUuid, "host-b")

        switcher.hosts = [switcher.hosts[1], switcher.hosts[0]]
        compare(switcher.selectedHostUuid, "host-b")
        switcher.requestAction("choose")

        compare(actionSpy.count, 1)
        compare(actionSpy.signalArguments[0][0], "choose")
        compare(actionSpy.signalArguments[0][1], "host-b")

        switcher.close()
        compare(switcher.enabled, false)
    }
}
