import QtQuick 2.9
// Imported for the StackView attached properties (StackView.onActivated) only --
// this screen pushes and pops through the app's existing StackView. No stock
// control from this module is instantiated anywhere in the Bulan screens.
import QtQuick.Controls 2.2

import ComputerModel 1.0

import ComputerManager 1.0
import SdlGamepadKeyNavigation 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// The host screen: a centred carousel of hosts with dimmed neighbours either side.
//
// Replaces PcView's grid. This is a VIEW ONLY -- it drives the same ComputerModel
// and calls the same ComputerManager entry points, and touches no discovery or
// pairing logic.
//
// The tiles are positioned directly -- a Repeater and one animated position per
// tile -- rather than laid out by a view component.
//
// This screen used PathView for two sessions and the mismatch was the source of
// every carousel defect on the project. PathView exists to move items endlessly
// around a CLOSED LOOP; this carousel CLAMPS at both ends and never wraps. While
// the host count is at or below the number of tiles drawn, the items fill that
// loop exactly, so on every move one of them has to travel from one end of the
// path to the other -- leaving one edge of the screen and reappearing at the
// opposite one in a single frame. At two hosts the join is a RESTING position,
// so a tile could be drawn on the wrong side while standing still. Both
// workarounds attempted -- hiding the crossing tile, stating the direction --
// traded one artefact for another, and the second was rejected on sight.
//
// Owning the coordinates removes the loop, the join, the direction guessing and
// the per-host-count special-casing all at once:
//
//   * a tile's position is a pure function of how far its index sits from the
//     selection, so direction ALWAYS follows the index and a wrap is not
//     expressible;
//   * there is real off-screen space either side, so a tile leaving simply
//     travels further out and fades rather than being cut;
//   * `pathStretch` is gone. It existed only to compensate for PathView spacing
//     items differently above and below three hosts, and there is nothing left
//     for it to compensate for.
//
// The cost is that scale and opacity are written here rather than interpolated
// for free along a path, and the focused tile is centred by arithmetic rather
// than by StrictlyEnforceRange. More code in exchange for total control.
//
// Model access goes through the delegate's own properties (root.host)
// rather than computerModel.data() with role numbers. Role numbers are an offset
// from Qt::UserRole and would break silently if anyone reordered the enum in
// computermodel.h; role names do not.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Computers")
    focus: true

    property ComputerModel computerModel: createModel()

    // Debug hook. MOONLIGHT_FAKE_HOSTS=none|one|two|offline|mixed|many substitutes
    // a fixed host list so every state below can be reviewed without pairing or unpairing
    // real machines. Inert unless the variable is set, and the only reason the
    // model is injectable at all -- which is also what makes this screen testable.
    readonly property bool useFakeHosts:
        typeof fakeHosts !== "undefined" && fakeHosts !== "" && fakeHosts !== "off"
    property var hostModel: useFakeHosts ? fakeModel : computerModel

    ListModel {
        id: fakeModel
        Component.onCompleted: {
            if (!root.useFakeHosts) {
                return
            }
            // wakeable defaults to "offline hosts can be woken", which is the
            // common case. Pass it explicitly for the case that is easy to
            // forget exists: a host that is unreachable AND cannot be woken,
            // because it never told us its hardware address. Shoebox is one.
            function host(n, on, paired, addr, unknown, canWake) {
                return {
                    name: n, online: on, paired: paired, statusUnknown: unknown === true,
                    wakeable: canWake === undefined ? !on : canWake,
                    serverSupported: true,
                    address: addr, details: "Name: " + n + "\nStatus: " + (on ? "Online" : "Offline")
                }
            }
            if (fakeHosts === "none") {
                return
            }
            if (fakeHosts === "one") {
                append(host("Desktop-PC", true, true, "192.168.1.24"))
                return
            }
            // "two": the client's real configuration, and the count the old
            // carousel was worst at -- with two hosts the non-focused tile sat
            // exactly on the loop's join, so it could be drawn on the wrong side
            // even standing still. There was no preset for it, which is why the
            // case that matters most in daily use was the one hardest to look at.
            if (fakeHosts === "two") {
                append(host("Shoebox", true, true, "192.168.1.24"))
                append(host("Steambox", false, true, "192.168.1.31"))
                return
            }
            if (fakeHosts === "offline") {
                // First, so it is the one on screen when this preset opens:
                // unreachable AND not wakeable, which is the state that is easy
                // to forget exists. The hint bar should withhold Wake here and
                // offer it on the two after. Shoebox is this case permanently.
                append(host("Living-Room", false, true, "192.168.1.31", false, false))
                append(host("Desktop-PC", false, true, "192.168.1.24"))
                append(host("Studio-Tower", false, true, "192.168.1.44"))
                return
            }
            // "many": more hosts than the carousel draws at once. Exists because
            // the carousel's behaviour changes shape at exactly three -- below
            // that the tiles fill its loop exactly and one has to cross the
            // screen on every move; above it, the surplus tile is never built.
            // Three states cannot demonstrate that on their own.
            if (fakeHosts === "many") {
                append(host("Living-Room", false, true, "192.168.1.31"))
                append(host("Desktop-PC", true, true, "192.168.1.24"))
                append(host("Studio-Tower", false, true, "192.168.1.44"))
                append(host("Bedroom-Mini", true, true, "192.168.1.58"))
                append(host("Garage-Rig", true, true, "192.168.1.62"))
                return
            }
            // "mixed": the mockup's own arrangement -- one reachable, two not.
            append(host("Living-Room", false, true, "192.168.1.31"))
            append(host("Desktop-PC", true, true, "192.168.1.24"))
            append(host("Studio-Tower", false, true, "192.168.1.44"))
        }
    }

    // Index whose connection is in flight, or -1.
    property int connectingIndex: -1

    // The selection. This is the whole of the carousel's state: every tile's
    // position, scale and opacity is a function of the distance between its own
    // index and this one, so there is no view offset, no phase and no join.
    property int currentIndex: 0

    readonly property int hostCount: hostRepeater.count
    readonly property bool hasHosts: hostCount > 0

    // The focused host's tile, or null. Everything below reads through this.
    //
    // Assigned rather than bound: Repeater.itemAt() is a function call, so a
    // binding on it would not re-evaluate when hosts appear or disappear, only
    // when the index changes. Every path that can change either one calls this.
    property var host: null
    // Normalised to exactly null when there is nothing, never undefined: every
    // reader below tests `host !== null`, and undefined would pass that test and
    // then fail on the property access.
    function refreshHost() {
        var item = (currentIndex >= 0 && currentIndex < hostRepeater.count)
                ? hostRepeater.itemAt(currentIndex)
                : null
        host = item ? item : null
    }
    onCurrentIndexChanged: refreshHost()
    // Belt and braces. The Repeater's own signals cover every path that populates
    // the list, but a null `host` reads on screen as a completely dead screen --
    // the exact failure this project keeps meeting -- so it is worth one more call.
    Component.onCompleted: refreshHost()

    readonly property bool hostOnline: host !== null && host.online

    // Whether waking this host could actually do anything. The app can only wake
    // a machine whose hardware address it has learned, and it learns that from
    // the host's own reply -- Sunshine does not always give one.
    readonly property bool hostWakeable: host !== null && host.wakeable

    function createModel() {
        var model = Qt.createQmlObject('import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        model.pairingCompleted.connect(pairingComplete)
        return model
    }

    function pairingComplete(error) {
        pinPanel.visible = false
        if (error !== undefined) {
            messagePanel.show(qsTr("Couldn't pair"), error)
        }
        recount()
    }

    // --- ready count ---------------------------------------------------------
    // "available systems out of paired systems". Hosts that are discovered but not
    // yet paired sit outside both figures -- they are not yours to count until you
    // have paired them -- so they appear in the carousel without inflating this.
    property int pairedCount: 0
    property int readyCount: 0

    function recount() {
        var paired = 0, ready = 0
        for (var i = 0; i < counter.count; i++) {
            var it = counter.itemAt(i)
            if (it && it.isPaired) {
                paired++
                if (it.isOnline) {
                    ready++
                }
            }
        }
        pairedCount = paired
        readyCount = ready
    }

    // Invisible mirror of the model, purely to count by role name.
    Item {
        visible: false
        Repeater {
            id: counter
            model: root.hostModel
            delegate: Item {
                readonly property bool isPaired: model.paired
                readonly property bool isOnline: model.online
                onIsOnlineChanged: root.recount()
                onIsPairedChanged: root.recount()
            }
            onItemAdded: root.recount()
            onItemRemoved: root.recount()
        }
    }

    // --- actions -------------------------------------------------------------
    // One function per hint, so the buttons and the mouse share a single path and
    // cannot drift apart.

    function actConfirm() {
        if (host === null) {
            return
        }
        host.flashPress()

        if (!host.online) {
            // Spec: confirm on an offline host attempts to wake it.
            actWake()
            return
        }
        // Everything past this point acts on a real machine, addressed by its
        // position in the real host list. A fake host has no machine behind it
        // and its position means nothing in that list, so acting on one either
        // does something to the wrong host or reads past the end of the list
        // and takes the app down with it.
        //
        // That is why the crash was intermittent and looked unrelated to host
        // count: with two real hosts, pressing A on the second fake host opens
        // the second REAL host's games and looks like it worked. Pressing A on
        // the fifth reads off the end and segfaults. Same code, same press.
        //
        // One guard covering every branch below, rather than one per branch --
        // the previous shape guarded pairing and missed the game list, and
        // would have missed the next branch added too.
        if (root.useFakeHosts) {
            // Says so out loud rather than doing nothing. A silent A is
            // indistinguishable from the dead-A defect this project has now
            // chased three times, and this screen is where that was chased.
            messagePanel.show(qsTr("Review mode"),
                              qsTr("%1 isn't a real PC, so there's nothing to open.")
                                  .arg(host.hostName))
            return
        }

        if (!host.paired) {
            var pin = computerModel.generatePinString()
            computerModel.pairComputer(root.currentIndex, pin)
            pinPanel.pin = pin
            pinPanel.hostName = host.hostName
            pinPanel.visible = true
            return
        }
        if (!host.serverSupported) {
            messagePanel.show(qsTr("Can't connect"),
                              qsTr("%1 is running a version this build doesn't support.")
                                  .arg(host.hostName))
            return
        }

        connectingIndex = root.currentIndex
        var component = Qt.createComponent("AppView.qml")
        // Defect 3. Without these checks a failure to build the game grid is
        // completely silent: createObject() returns null, push(null) does
        // nothing, and A looks like a dead button with no clue on screen. Say
        // so instead -- an error the user can report beats a button that
        // appears broken.
        if (component.status !== Component.Ready) {
            console.error("AppView.qml failed to load:", component.errorString())
            connectingIndex = -1
            messagePanel.show(qsTr("Can't open %1").arg(host.hostName),
                              qsTr("Something went wrong loading the game list."))
            return
        }
        var view = component.createObject(stackView, {
                                              "computerIndex": root.currentIndex,
                                              "objectName": host.hostName
                                          })
        if (view === null) {
            console.error("AppView.qml loaded but could not be created")
            connectingIndex = -1
            messagePanel.show(qsTr("Can't open %1").arg(host.hostName),
                              qsTr("Something went wrong loading the game list."))
            return
        }
        stackView.push(view)
    }

    function actWake() {
        if (host === null || host.online) {
            return
        }
        if (!host.wakeable) {
            messagePanel.show(qsTr("Can't wake this one"),
                              qsTr("%1 didn't tell us how to wake it.").arg(host.hostName))
            return
        }
        if (!root.useFakeHosts) {
            computerModel.wakeComputer(root.currentIndex)
        }
        messagePanel.show(qsTr("Waking %1").arg(host.hostName),
                          qsTr("Give it a moment to come back."))
    }

    // Move the selection one host, clamping at both ends.
    //
    // There is no direction to state any more. A tile's position is derived from
    // its distance to the selection, so raising the index can only ever slide the
    // row left and lowering it can only ever slide it right -- travelling the
    // wrong way round is not something the geometry can express. The old
    // component chose its own route and chose wrong at exactly three hosts.
    function moveBy(step) {
        var next = currentIndex + step
        if (next < 0 || next > hostRepeater.count - 1) {
            return
        }
        currentIndex = next
    }

    // Select a host directly, for the mouse. Clamping does not apply -- a click
    // names its target rather than stepping towards it.
    function selectIndex(index) {
        if (index < 0 || index > hostRepeater.count - 1) {
            return
        }
        currentIndex = index
    }

    // Keep the selection inside the list when hosts appear or disappear.
    function clampIndex() {
        if (hostRepeater.count === 0) {
            currentIndex = 0
        } else if (currentIndex > hostRepeater.count - 1) {
            currentIndex = hostRepeater.count - 1
        } else if (currentIndex < 0) {
            currentIndex = 0
        }
    }

    function actAddPc() {
        addPcPanel.visible = true
    }

    function actClientSettings() {
        navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
    }

    function actHostSettings() {
        if (host === null) {
            return
        }
        // MINIMAL / NOT YET DESIGNED. The spec routes SELECT here, but no host
        // settings screen has been specified, so this shows what the old grid's
        // "View Details" showed and nothing more. Rename, delete and the network
        // test have no home in this view yet -- see SPEC-host-carousel.md.
        messagePanel.show(host.hostName, host.details)
    }

    // --- lifecycle -----------------------------------------------------------
    StackView.onActivated: {
        // No toolbar here: the wordmark and the hint bar are this screen's chrome.
        toolBar.visible = false

        // Arrow-key navigation, not the settings page's tab chain.
        SdlGamepadKeyNavigation.setUiNavMode(false)

        connectingIndex = -1
        recount()
        // Start on the first reachable host rather than whichever happens to be
        // first: opening on an offline machine would make the screen look broken.
        if (hostRepeater.count > 0) {
            for (var i = 0; i < counter.count; i++) {
                var it = counter.itemAt(i)
                if (it && it.isOnline && it.isPaired) {
                    root.currentIndex = i
                    break
                }
            }
        }
        refreshHost()
        root.forceActiveFocus()
    }

    StackView.onDeactivating: {
        toolBar.visible = true
    }

    // Focus recovery.
    //
    // A FocusScope reports activeFocus while anything inside it holds focus, so
    // this going false means focus left the screen entirely. That happens when a
    // popup elsewhere in the window is torn down and restores focus to a control
    // that no longer exists -- the settings page's Resolution dropdown does it on
    // the way back here. Nothing is then listening for A, and A is the only button
    // with no window-level shortcut standing behind it, so it alone goes dead and
    // stays dead until the app restarts.
    //
    // Deliberately reactive rather than ordered. Claiming focus once in
    // onActivated loses any race against a popup that tears down afterwards, and
    // reasoning about which handler runs last is what made defect 1 intermittent.
    // Reclaiming whenever focus is lost cannot be raced. callLater defers to the
    // end of the current pass so this does not fight something mid-teardown.
    onActiveFocusChanged: {
        if (!activeFocus && StackView.status === StackView.Active) {
            Qt.callLater(reclaimFocus)
        }
    }

    // Take focus back for this screen. Guarded on no overlay being open rather
    // than on activeFocus, because a panel is a CHILD of this scope: while focus
    // is stuck on a closed panel, root.activeFocus is still true and testing it
    // would decline to act in exactly the case that needs acting on.
    function reclaimFocus() {
        if (root.StackView.status !== StackView.Active) {
            return
        }
        if (messagePanel.visible || pinPanel.visible || addPcPanel.visible) {
            return
        }
        root.forceActiveFocus()
    }

    Atmosphere { anchors.fill: parent }

    // --- header --------------------------------------------------------------
    Image {
        id: wordmark
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX
        anchors.top: parent.top
        anchors.topMargin: Bulan.layoutScreenMarginY
        source: "qrc:/res/bulan_logo_horiz.svg"
        // The mark carries its own gradient fills, so it is drawn as supplied
        // rather than recoloured the way the controller glyphs are.
        height: Bulan.sizeTitle
        fillMode: Image.PreserveAspectFit
        sourceSize.height: Bulan.sizeTitle * 2
        smooth: true
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Bulan.layoutScreenMarginX
        anchors.verticalCenter: wordmark.verticalCenter
        spacing: Bulan.spaceXs
        visible: root.pairedCount > 0

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Bulan.space2xs
            height: Bulan.space2xs
            radius: width / 2
            color: root.readyCount > 0 ? Bulan.statusSuccess : Bulan.secondary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 of %2 ready").arg(root.readyCount).arg(root.pairedCount)
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeLabel
        }
    }

    // --- warm halo behind the focused tile -----------------------------------
    // One instance, centred, rather than one per delegate: the focused item is
    // always the centred one, so the halo never has to move or be repainted.
    Canvas {
        id: focusBloom
        width: Bulan.hostTileSize * 2.2
        height: width
        x: carousel.x + carousel.width / 2 - width / 2
        y: carousel.y + carousel.focusY - height / 2
        visible: root.hasHosts
        opacity: root.hostOnline ? 1.0 : 0.3

        Behavior on opacity {
            NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
        }

        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var r = width / 2
            var g = ctx.createRadialGradient(r, r, 0, r, r, r)
            var a = Bulan.focusBloomOpacity
            // Eased rolloff: a linear alpha fade still reads as a visible disc
            // edge against a ground this dark.
            g.addColorStop(0.00, Qt.rgba(1, 0.85, 0.63, a))
            g.addColorStop(0.30, Qt.rgba(1, 0.85, 0.63, a * 0.45))
            g.addColorStop(0.55, Qt.rgba(1, 0.85, 0.63, a * 0.16))
            g.addColorStop(0.78, Qt.rgba(1, 0.85, 0.63, a * 0.04))
            g.addColorStop(1.00, Qt.rgba(1, 0.85, 0.63, 0.0))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(r, r, r, 0, Math.PI * 2)
            ctx.fill()
        }
    }

    // --- carousel ------------------------------------------------------------
    // A band the tiles are positioned inside. Not a view: it lays nothing out and
    // scrolls nothing. Every tile's place is worked out from its own index.
    Item {
        id: carousel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: wordmark.bottom
        anchors.topMargin: Bulan.space3xl
        width: parent.width
        height: Bulan.hostTileSize * 1.6

        // Where the focused tile's centre sits inside the band. The band is taller
        // than the tile so the neighbours' name labels have somewhere to go.
        readonly property real focusY: Bulan.hostTileSize * 0.52

        visible: root.hasHosts

        Repeater {
            id: hostRepeater
            model: root.hostModel

            // Hosts appearing and disappearing has to keep the selection inside
            // the list and keep root.host pointing at the right tile. Counting
            // is left to the mirror above -- this one only owns the geometry.
            onItemAdded: {
                root.clampIndex()
                root.refreshHost()
            }
            onItemRemoved: {
                root.clampIndex()
                root.refreshHost()
            }

            delegate: HostTile {
                id: hostTile

                hostName: model.name
                online: model.online
                paired: model.paired
                statusUnknown: model.statusUnknown
                wakeable: model.wakeable
                serverSupported: model.serverSupported
                address: model.address
                details: model.details

                // How far this host sits from the selected one, clamped to two
                // slots either side.
                //
                // The clamp is what gives the carousel its off-screen space. One
                // slot out is a visible neighbour; two slots out is past the edge
                // of the screen and invisible. Everything beyond that parks at
                // two rather than flying off to arbitrary distances, so a tile
                // coming into view always travels exactly one slot to get there
                // however far down the list it started.
                readonly property int slot: {
                    var d = index - root.currentIndex
                    return d < -2 ? -2 : (d > 2 ? 2 : d)
                }
                readonly property int distance: slot < 0 ? -slot : slot

                // The tile's box is always hostTileSize; the circle inside it is
                // what scales. So the centre is placed here and the scale is
                // applied about that centre, which is what keeps the neighbour
                // labels sitting under a scaled edge rather than drifting.
                x: carousel.width / 2 - width / 2 + slot * Bulan.hostTileSpread
                y: carousel.focusY - height / 2 +
                   (distance === 0 ? 0 : Bulan.hostTileNeighbourDrop)

                tileScale: distance === 0 ? 1.0 : Bulan.hostTileNeighbourScale

                // 1.0 focused, 0.5 for the neighbours, nothing beyond them. A
                // tile leaving therefore travels out to the second slot while
                // fading -- it leaves the way something leaves, rather than
                // being cut because it had nowhere to go.
                opacity: distance === 0 ? 1.0 : (distance === 1 ? 0.5 : 0.0)

                // The focused tile draws above its neighbours.
                z: distance === 0 ? 2 : 0

                // Follows the animated opacity rather than the slot, so a tile on
                // its way out stays drawn for the whole of its exit and stops
                // being drawn -- and stops taking clicks -- once it is invisible.
                visible: opacity > 0.01

                isCurrent: index === root.currentIndex

                // Drives the tile's own text from neighbour size and dimness to
                // focused size and full strength. Animated below on the same
                // clock as the travel, so the label grows as the tile arrives
                // rather than snapping when it gets there.
                focusAmount: distance === 0 ? 1.0 : 0.0

                // The tile draws the connecting state; the carousel knows about it.
                connecting: root.connectingIndex === index

                // One clock for the whole move: position, drop, scale and fade
                // all run for motionFocusMs on the same curve, so a tile travels,
                // shrinks and dims as one object instead of four.
                //
                // The easing is the one thing here that had to be chosen rather
                // than copied -- the old component eased its own travel and did
                // not expose the curve. InOutQuad is the closest reproduction of
                // how it read. It is a judgement call and it is the client's to
                // confirm on screen.
                Behavior on x {
                    enabled: hostTile.settled
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on y {
                    enabled: hostTile.settled
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on tileScale {
                    enabled: hostTile.settled
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on opacity {
                    enabled: hostTile.settled
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on focusAmount {
                    enabled: hostTile.settled
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }

                // False until this tile has been placed once, so the first frame
                // is a position rather than a journey from the top-left corner.
                // Bindings are evaluated before Component.onCompleted runs, so by
                // the time this flips the tile is already where it belongs.
                property bool settled: false
                Component.onCompleted: settled = true

                // Click selects and acts. Hover does nothing -- see HostTile.
                onActivated: {
                    root.selectIndex(index)
                    root.actConfirm()
                }
            }
        }
    }


    // --- zero hosts ----------------------------------------------------------
    // Two stacked elements, per spec. The copy is deliberately off-register from
    // the rest of the app: this is a screen you see once, which makes it the one
    // place a joke costs nothing.
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Bulan.space2xl
        spacing: Bulan.spaceLg
        visible: !root.hasHosts

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("you have no pc's lol")
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeDisplay
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Bulan.spaceXs

            ControllerGlyph {
                anchors.verticalCenter: parent.verticalCenter
                action: "options"
                tone: "focus"
                glyphSize: Bulan.sizeBodyLg
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Press to pair a PC")
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeBodyLg
            }
        }
    }

    // --- hint bar ------------------------------------------------------------
    HintBar {
        id: hintBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        leftHints: root.hasHosts
            ? [
                  { action: "confirm",   label: qsTr("Connect"), emphasis: true },
                  // Wake only where waking means something. Two ways it can
                  // mean nothing, and both have now been seen:
                  //
                  //   The host is already awake. actWake() returns immediately,
                  //   so advertising it offered a button that did nothing.
                  //   That was defect 2 from the July hardware session.
                  //
                  //   The host cannot be woken at all, because it never told us
                  //   its hardware address. Pressing Wake there only ever
                  //   produces "it didn't tell us how to wake it", which is a
                  //   refusal the hint bar should not have promised. Shoebox is
                  //   this case permanently.
                  { action: "alternate", label: qsTr("Wake"),
                    visible: !root.hostOnline && root.hostWakeable },
                  { action: "options",   label: qsTr("Add a PC") }
              ]
            : [
                  { action: "options", label: qsTr("Add a PC"), emphasis: true }
              ]

        rightHints: root.hasHosts
            ? [
                  { action: "start",  label: qsTr("Client Settings") },
                  { action: "select", label: qsTr("Host Settings") }
              ]
            : [
                  { action: "start", label: qsTr("Client Settings") }
              ]
    }

    // --- input ---------------------------------------------------------------
    // Movement clamps rather than wrapping, which is why it is done here instead
    // of anywhere else: moveBy() is the only thing that writes the selection.
    Keys.onLeftPressed: moveBy(-1)
    Keys.onRightPressed: moveBy(1)

    // Inert, and swallowed. Without accepting them they bubble to the StackView
    // and drag focus into chrome this screen does not have.
    Keys.onUpPressed: event.accepted = true
    Keys.onDownPressed: event.accepted = true

    // A. Three keycodes for one button: Return and Enter are the same press on
    // different keyboards, and Space is what A becomes while the settings page's
    // tab chain is armed. This screen never wants that chain, but accepting
    // Space anyway means a mode that leaks in from elsewhere can no longer make
    // A do nothing at all -- which is the failure defect 1 produced, and the
    // reason it read as a pairing problem rather than a navigation one.
    Keys.onReturnPressed: actConfirm()
    Keys.onEnterPressed: actConfirm()
    Keys.onSpacePressed: {
        actConfirm()
        event.accepted = true
    }

    // X. Menu is also what the toolbar used for settings upstream; consumed here.
    Keys.onMenuPressed: {
        actAddPc()
        event.accepted = true
    }

    // Y, given its own keycode in sdlgamepadkeynavigation.cpp so it no longer
    // collides with Start. Consumed here, so it does not fall through to
    // main.qml's "show settings".
    Keys.onCallPressed: {
        actWake()
        event.accepted = true
    }

    // Start
    Keys.onHangupPressed: {
        actClientSettings()
        event.accepted = true
    }

    // Select, which had no mapping at all before.
    Keys.onContext1Pressed: {
        actHostSettings()
        event.accepted = true
    }

    // --- overlays ------------------------------------------------------------
    // Every panel hands focus back on the way out. Doing it here as well as in
    // HostPanel.close() covers the paths that hide a panel by setting visible
    // directly and so never run close() at all -- pairingComplete() is one.
    // callLater defers until the panel has finished going away.
    HostPanel {
        id: messagePanel
        anchors.fill: parent
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
    }

    HostPanel {
        id: pinPanel
        anchors.fill: parent
        property string pin: ""
        property string hostName: ""
        title: qsTr("Pair with %1").arg(hostName)
        body: qsTr("Enter %1 on your PC. This closes itself when pairing finishes.").arg(pin)
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
    }

    HostPanel {
        id: addPcPanel
        anchors.fill: parent
        title: qsTr("Add a PC")
        body: qsTr("Type its address.")
        editable: true
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
        onSubmitted: {
            if (text) {
                ComputerManager.addNewHostManually(text.trim())
            }
        }
    }
}
