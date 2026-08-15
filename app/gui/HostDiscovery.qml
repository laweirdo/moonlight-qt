import QtQuick 2.9
// Imported for the StackView attached properties only -- no stock control
// from this module is instantiated anywhere on this screen.
import QtQuick.Controls 2.2
import QtQuick.Effects

import ComputerModel 1.0
import ComputerManager 1.0
import SdlGamepadKeyNavigation 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// S2: the discovered-hosts list during first run. A simplified, vertical
// cousin of HostCarousel -- one column of full-width rows instead of a
// carousel of circular tiles, because there is no "current host" yet for a
// carousel's centred-focus geometry to mean anything about. Rows are
// positioned by a plain Repeater in a Column, following HostCarousel's own
// precedent of owning layout directly rather than reaching for a view
// component for a handful of items.
//
// A on a row that is not yet paired starts pairing and pushes PairView.qml.
// A on a row that is already paired and online goes straight to
// HostCarousel.qml instead -- the mockup never shows this case (first run
// implies nothing is paired yet), but it is a real reachable state (a host
// paired by a different install, or re-discovered after being forgotten and
// re-paired elsewhere) and silently doing nothing would be the "dead A"
// defect this project has already chased three times on HostCarousel.
//
// B (Escape) is not handled here on purpose, matching FirstRun.qml: at
// stack depth 2 main.qml's central Keys.onEscapePressed already pops back
// to FirstRun with no per-screen code needed.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Bulan")
    focus: true

    property ComputerModel computerModel: createModel()

    // Debug hook, reused verbatim from HostCarousel.qml rather than invented
    // fresh: MOONLIGHT_FAKE_HOSTS=none|one|two|offline|mixed|many substitutes
    // the same fixed host list here, so the same environment variable value
    // shows the same hosts on both screens.
    readonly property bool useFakeHosts:
        typeof fakeHosts !== "undefined" && fakeHosts !== "" && fakeHosts !== "off"
    property var hostModel: useFakeHosts ? fakeModel : computerModel

    ListModel {
        id: fakeModel
        Component.onCompleted: {
            if (!root.useFakeHosts) {
                return
            }
            // Copy of HostCarousel.fakeModel's own host() helper and preset
            // set -- see that file's comments for why each preset exists.
            // Duplicated rather than shared: each Bulan screen owns its own
            // model, the same way HostCarousel and AppView each keep their
            // own fakeModel.
            function host(n, on, paired, addr, unknown, canWake) {
                return {
                    name: n, online: on, paired: paired, statusUnknown: unknown === true,
                    wakeable: canWake === undefined ? !on : canWake,
                    serverSupported: true,
                    address: addr,
                    details: "Name: " + n + "\nStatus: " + (on ? "Online" : "Offline"),
                    uuid: "review:" + n
                }
            }
            if (fakeHosts === "none") {
                return
            }
            if (fakeHosts === "one") {
                append(host("Desktop-PC", true, false, "192.168.1.24"))
                return
            }
            if (fakeHosts === "two") {
                append(host("Desktop-PC", true, false, "192.168.1.24"))
                append(host("Living-Room", true, false, "192.168.1.31"))
                return
            }
            if (fakeHosts === "offline") {
                append(host("Living-Room", false, true, "192.168.1.31", false, false))
                append(host("Desktop-PC", false, true, "192.168.1.24"))
                append(host("Studio-Tower", false, true, "192.168.1.44"))
                return
            }
            if (fakeHosts === "many") {
                append(host("Living-Room", false, true, "192.168.1.31"))
                append(host("Desktop-PC", true, false, "192.168.1.24"))
                append(host("Studio-Tower", false, true, "192.168.1.44"))
                append(host("Bedroom-Mini", true, false, "192.168.1.58"))
                append(host("Garage-Rig", true, false, "192.168.1.62"))
                return
            }
            // "mixed": the S2 mockup's own arrangement -- Desktop-PC focused
            // first, Living-Room beneath it.
            append(host("Desktop-PC", true, false, "192.168.1.24"))
            append(host("Living-Room", true, false, "192.168.1.31"))
        }
    }

    function createModel() {
        var model = Qt.createQmlObject('import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        return model
    }

    // --- selection -------------------------------------------------------
    // Same shape as HostCarousel's currentIndex/host/moveBy/selectIndex/
    // clampIndex, minus the carousel geometry -- this is a plain vertical
    // list, so a row's position is its rank, not a function of distance from
    // a centred selection.
    property int currentIndex: 0
    property var host: null

    function refreshHost() {
        var item = (currentIndex >= 0 && currentIndex < hostRepeater.count)
                ? hostRepeater.itemAt(currentIndex)
                : null
        host = item ? item : null
    }
    onCurrentIndexChanged: refreshHost()
    Component.onCompleted: refreshHost()

    function moveBy(step) {
        root.settleEntrance()
        var next = currentIndex + step
        if (next < 0 || next > hostRepeater.count - 1) {
            return
        }
        currentIndex = next
    }
    function selectIndex(index) {
        if (index < 0 || index > hostRepeater.count - 1) {
            return
        }
        currentIndex = index
    }
    function clampIndex() {
        if (hostRepeater.count === 0) {
            currentIndex = 0
        } else if (currentIndex > hostRepeater.count - 1) {
            currentIndex = hostRepeater.count - 1
        } else if (currentIndex < 0) {
            currentIndex = 0
        }
    }

    function actAddress() {
        root.settleEntrance()
        addressPanel.opened = true
    }

    // --- select ------------------------------------------------------------
    function actSelect() {
        root.settleEntrance()
        if (root.host === null) {
            return
        }

        if (root.useFakeHosts) {
            if (root.host.paired) {
                // No fake preset actually reaches this today (every preset's
                // rows are unpaired, matching the first-run premise), but a
                // future preset could, and a silent A here would be the same
                // dead-A defect HostCarousel's own review guard exists to
                // avoid.
                messagePanel.show(qsTr("Review mode"),
                                  qsTr("%1 isn't a real PC, so there's nothing to open.")
                                      .arg(root.host.hostName))
                return
            }
            // Review hook: MOONLIGHT_FAKE_PAIR_PIN=<pin>. A fake row's index
            // names a real machine at the same position -- see
            // HostCarousel.actConfirm()'s own guard comment for the crash
            // that rule prevents -- so pairComputer() is never called here.
            // PairView is pushed with a PIN and nothing behind it ever
            // resolves, which is exactly S3's static mockup.
            var fakePin = (typeof fakePairPin !== "undefined" && fakePairPin !== "")
                    ? fakePairPin : root.computerModel.generatePinString()
            stackView.push("PairView.qml", {
                "computerModel": root.computerModel,
                "hostUuid": root.host.uuid,
                "hostName": root.host.hostName,
                "pin": fakePin
            })
            return
        }

        if (root.host.paired) {
            if (root.host.online) {
                // Not the reachable case the mockup illustrates, but a real
                // one -- see this file's header comment. clear()+push(), not
                // replace(null, ...) -- see PairView.qml's own success path
                // for why.
                stackView.clear(StackView.Immediate)
                stackView.push("HostCarousel.qml")
            } else {
                messagePanel.show(qsTr("Can't reach %1 yet").arg(root.host.hostName),
                                  qsTr("Give it a moment and try again."))
            }
            return
        }

        var pin = root.computerModel.generatePinString()
        root.computerModel.pairComputer(root.currentIndex, pin)
        stackView.push("PairView.qml", {
            "computerModel": root.computerModel,
            "hostUuid": root.host.uuid,
            "hostName": root.host.hostName,
            "pin": pin
        })
    }

    StackView.onActivated: {
        toolBar.visible = false
        SdlGamepadKeyNavigation.setUiNavMode(false)
        root.forceActiveFocus()
        root.clampIndex()
        root.refreshHost()
        // Active means the screen has stopped travelling. See FirstRun.qml.
        root.entranceStarted = true
    }

    readonly property bool bulanScreen: true

    // --- post-transition entrance ---
    //
    // Mark, headline, the results list, then the address escape hatch. See
    // EntranceMotion.qml.
    //
    // The list arrives as one unit rather than per row: rows appear whenever
    // discovery finds them, so a per-row entrance would fire at arbitrary times
    // long after the screen settled, and would replay every time a host dropped
    // and came back. HostCarousel's zero-host state moves its Column as a single
    // unit for the same reason.
    //
    // Started by the transition, not by a timer set to its duration. See
    // FirstRun.qml.
    property bool entranceStarted: false

    EntranceMotion { id: markMotion;    order: 0; started: root.entranceStarted }
    EntranceMotion { id: titleMotion;   order: 1; started: root.entranceStarted }
    EntranceMotion { id: listMotion;    order: 2; started: root.entranceStarted }
    EntranceMotion { id: addressMotion; order: 3; started: root.entranceStarted }

    function settleEntrance() {
        markMotion.settle()
        titleMotion.settle()
        listMotion.settle()
        addressMotion.settle()
    }

    onActiveFocusChanged: {
        if (!activeFocus && StackView.status === StackView.Active) {
            Qt.callLater(reclaimFocus)
        }
    }
    function reclaimFocus() {
        if (root.StackView.status !== StackView.Active) {
            return
        }
        if (messagePanel.visible || addressPanel.visible) {
            return
        }
        root.forceActiveFocus()
    }

    Item {
        anchors.fill: parent

        Atmosphere {
            anchors.fill: parent
        }

        Column {
            id: content
            anchors.centerIn: parent
            spacing: Bulan.spaceLg
            width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                             Bulan.hostTileSize * 3)

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/res/bulan_logomark.svg"
                width: Bulan.onboardingMarkSize
                height: width
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width * 2
                sourceSize.height: width * 2
                smooth: true
                opacity: markMotion.fadeOpacity
                transform: Translate { y: markMotion.riseOffset }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Looking for your PC…")
                color: Bulan.textPrimary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeDisplay
                opacity: titleMotion.fadeOpacity
                transform: Translate { y: titleMotion.riseOffset }
            }

            Column {
                width: parent.width
                spacing: Bulan.spaceMd
                opacity: listMotion.fadeOpacity
                transform: Translate { y: listMotion.riseOffset }

                Repeater {
                    id: hostRepeater
                    model: root.hostModel

                    onItemAdded: {
                        root.clampIndex()
                        root.refreshHost()
                    }
                    onItemRemoved: {
                        root.clampIndex()
                        root.refreshHost()
                    }

                    delegate: Rectangle {
                        id: row
                        width: content.width
                        height: Bulan.targetRowHeight
                        radius: Bulan.radiusLg
                        color: Bulan.bgSurface
                        border.width: isCurrent ? 2 : 0
                        border.color: Bulan.accentPrimary

                        readonly property bool isCurrent: index === root.currentIndex
                        readonly property string hostName: model.name
                        readonly property string address: model.address
                        readonly property bool online: model.online
                        readonly property bool paired: model.paired
                        readonly property string uuid: model.uuid

                        layer.enabled: isCurrent
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Bulan.accentGlow
                            shadowBlur: Bulan.buttonGlowBlur
                            shadowOpacity: Bulan.buttonGlowOpacity
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }

                        Behavior on border.width {
                            NumberAnimation { duration: Bulan.motionFocusMs }
                        }

                        // The focused row's identity mark from the mockup: a
                        // short amber bar inset at the left edge. Unfocused
                        // rows carry no border and no bar, per the mockup.
                        Rectangle {
                            visible: row.isCurrent
                            anchors.left: parent.left
                            anchors.leftMargin: Bulan.spaceMd
                            anchors.verticalCenter: parent.verticalCenter
                            width: Bulan.space2xs
                            height: parent.height - Bulan.spaceMd * 2
                            radius: width / 2
                            color: Bulan.accentPrimary
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Bulan.layoutScreenMarginX
                            anchors.right: addressLabel.left
                            anchors.rightMargin: Bulan.spaceMd
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.hostName
                            color: Bulan.textPrimary
                            font.family: Bulan.familyDisplay
                            font.pixelSize: Bulan.sizeTitle
                            elide: Text.ElideRight
                        }

                        Text {
                            id: addressLabel
                            anchors.right: parent.right
                            anchors.rightMargin: Bulan.layoutScreenMarginX
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.address
                            color: Bulan.textSecondary
                            font.family: Bulan.familyUi
                            font.pixelSize: Bulan.sizeBody
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectIndex(index)
                                root.actSelect()
                            }
                        }
                    }
                }
            }

            Text {
                id: addressLink
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Enter an address instead")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeLabel
                opacity: addressMotion.fadeOpacity
                transform: Translate { y: addressMotion.riseOffset }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Bulan.spaceSm
                    onClicked: root.actAddress()
                }
            }
        }
    }

    // --- hint bar --------------------------------------------------------
    // "Enter address" is the same controller-first addition FirstRun.qml
    // makes to its own hint bar, and for the same reason -- see that
    // screen's comment.
    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints: [
        { action: "confirm", label: qsTr("Select"), emphasis: true, visible: root.host !== null },
        { action: "options", label: qsTr("Enter address") }
    ]
    readonly property var hintRightHints: [
        { action: "back", label: qsTr("Back") }
    ]

    // --- input -------------------------------------------------------------
    // Any key ends the entrance early. Deliberately does not set
    // event.accepted -- it only stops an animation, and swallowing the press
    // would eat the navigation and actions below. moveBy() and the act*
    // functions settle as well, because Qt delivers the specific key signals
    // independently of this handler.
    Keys.onPressed: function(event) {
        root.settleEntrance()
    }

    Keys.onUpPressed: moveBy(-1)
    Keys.onDownPressed: moveBy(1)
    // Inert, and swallowed -- HostCarousel's own reasoning: without accepting
    // them they bubble to the StackView and drag focus into chrome this
    // screen does not have.
    Keys.onLeftPressed: function(event) { event.accepted = true }
    Keys.onRightPressed: function(event) { event.accepted = true }

    Keys.onReturnPressed: actSelect()
    Keys.onEnterPressed: actSelect()
    Keys.onSpacePressed: function(event) {
        actSelect()
        event.accepted = true
    }

    Keys.onMenuPressed: function(event) {
        actAddress()
        event.accepted = true
    }

    HostPanel {
        id: messagePanel
        anchors.fill: parent
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
    }

    HostPanel {
        id: addressPanel
        anchors.fill: parent
        title: qsTr("Add a PC")
        body: qsTr("Type its address.")
        editable: true
        // Steam on-screen keyboard: UNVALIDATED on this branch. See
        // FirstRun.qml's identical addressPanel for the reasoning -- this is
        // the same shared HostPanel, unmodified.
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
        onSubmitted: {
            if (text) {
                ComputerManager.addNewHostManually(text.trim())
            }
        }
    }
}
