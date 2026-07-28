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
// PathView, not a ListView with transforms. PathView is the primitive for exactly
// this shape: scale and opacity are attributes interpolated along its path, so
// neighbour dimming is declarative instead of a computed transform per delegate,
// and StrictlyEnforceRange keeps the focused item centred with no positioning
// arithmetic at all.
//
// Two of its defaults are deliberately overridden:
//
//   interactive: false   Kills drag and flick. Mouse support here is hover-to-
//                        focus plus click, so dragging would be a second,
//                        competing way to change the selection.
//   wrapping             PathView wraps around its path by design. The spec wants
//                        clamping, so index movement is done in the key handlers
//                        and never wraps.
//
// Model access goes through the delegate's own properties (pathView.currentItem)
// rather than computerModel.data() with role numbers. Role numbers are an offset
// from Qt::UserRole and would break silently if anyone reordered the enum in
// computermodel.h; role names do not.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Computers")
    focus: true

    property ComputerModel computerModel: createModel()

    // Debug hook. MOONLIGHT_FAKE_HOSTS=none|one|offline|mixed substitutes a fixed
    // host list so every state below can be reviewed without pairing or unpairing
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
            function host(n, on, paired, addr, unknown) {
                return {
                    name: n, online: on, paired: paired, statusUnknown: unknown === true,
                    wakeable: !on, serverSupported: true,
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
            if (fakeHosts === "offline") {
                append(host("Living-Room", false, true, "192.168.1.31"))
                append(host("Desktop-PC", false, true, "192.168.1.24"))
                append(host("Studio-Tower", false, true, "192.168.1.44"))
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

    readonly property int hostCount: pathView.count
    readonly property bool hasHosts: hostCount > 0

    // The focused host, or null. Everything below reads through this.
    readonly property var host: pathView.currentItem
    readonly property bool hostOnline: host !== null && host.online

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
        if (!host.paired) {
            if (root.useFakeHosts) {
                return
            }
            var pin = computerModel.generatePinString()
            computerModel.pairComputer(pathView.currentIndex, pin)
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

        connectingIndex = pathView.currentIndex
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
                                              "computerIndex": pathView.currentIndex,
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
            computerModel.wakeComputer(pathView.currentIndex)
        }
        messagePanel.show(qsTr("Waking %1").arg(host.hostName),
                          qsTr("Give it a moment to come back."))
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
        if (pathView.count > 0) {
            for (var i = 0; i < counter.count; i++) {
                var it = counter.itemAt(i)
                if (it && it.isOnline && it.isPaired) {
                    pathView.currentIndex = i
                    break
                }
            }
        }
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
        x: pathView.x + pathView.width / 2 - width / 2
        y: pathView.y + pathView.focusY - height / 2
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
    PathView {
        id: pathView

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: wordmark.bottom
        anchors.topMargin: Bulan.space3xl
        width: parent.width
        height: Bulan.hostTileSize * 1.6

        // Where the focused tile's centre sits inside the band. The band is taller
        // than the tile so the neighbours' name labels have somewhere to go.
        readonly property real focusY: Bulan.hostTileSize * 0.52

        // PathView spaces items 1/count apart along the path while count is below
        // pathItemCount, and 1/pathItemCount once it is above. So a neighbour sits
        // at path fraction 0.0 when there are two hosts, but at 1/6 when there are
        // three or more -- the same geometry would put it in two different places.
        //
        // Solving x(fraction) = centre - spread for both cases gives a single
        // factor on the path's extent: 1.5 when the fraction is 1/6, 1.0 when it
        // is 0.0. Without this the neighbours drift inward and collide with the
        // focused tile as soon as a third host appears.
        readonly property real pathStretch: count >= 3 ? 1.5 : 1.0

        visible: root.hasHosts
        model: root.hostModel

        // The focused tile plus one neighbour each side.
        pathItemCount: 3
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

        // Selection comes from buttons and hover, never from dragging.
        interactive: false

        // Matches the tile's focus duration, so moving between hosts is one
        // motion rather than a tile animation racing a view animation.
        highlightMoveDuration: Bulan.motionFocusMs

        // A shallow arc: neighbours are inset from the edges and sit lower, so the
        // focused tile reads as the near one rather than the middle one.
        path: Path {
            startX: pathView.width / 2 - Bulan.hostTileSpread * pathView.pathStretch
            startY: pathView.focusY + Bulan.hostTileNeighbourDrop * pathView.pathStretch

            PathAttribute { name: "itemScale"; value: Bulan.hostTileNeighbourScale }
            PathAttribute { name: "itemOpacity"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 0 }

            PathLine { x: pathView.width / 2; y: pathView.focusY }

            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 2 }

            PathLine {
                x: pathView.width / 2 + Bulan.hostTileSpread * pathView.pathStretch
                y: pathView.focusY + Bulan.hostTileNeighbourDrop * pathView.pathStretch
            }

            PathAttribute { name: "itemScale"; value: Bulan.hostTileNeighbourScale }
            PathAttribute { name: "itemOpacity"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 0 }
        }

        delegate: HostTile {
            hostName: model.name
            online: model.online
            paired: model.paired
            statusUnknown: model.statusUnknown
            wakeable: model.wakeable
            serverSupported: model.serverSupported
            address: model.address
            details: model.details

            // Navigation clamps at both ends, but PathView still instantiates a
            // wrapped neighbour: focused on the first host, it draws the LAST one
            // to the left, which silently promises a host that pressing left will
            // never reach. Only genuinely adjacent indices are shown.
            visible: Math.abs(index - pathView.currentIndex) <= 1

            isCurrent: PathView.isCurrentItem
            pathScale: PathView.itemScale === undefined ? 1.0 : PathView.itemScale
            z: PathView.itemZ === undefined ? 0 : PathView.itemZ
            opacity: PathView.itemOpacity === undefined ? 1.0 : PathView.itemOpacity

            // Hover moves focus, so there is only ever one highlight and the
            // pointer and the D-pad always agree about what is selected.
            onHoverEntered: pathView.currentIndex = index
            onActivated: {
                pathView.currentIndex = index
                root.actConfirm()
            }
        }
    }

    // --- focused host detail -------------------------------------------------
    // Anchored up from the hint bar rather than down from the carousel: the
    // neighbours' labels overhang the band by a variable amount, so chaining off
    // pathView.bottom would let this block drift.
    Column {
        anchors.bottom: hintBar.top
        anchors.bottomMargin: Bulan.spaceXl
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Bulan.layoutScreenMarginX * 2
        spacing: Bulan.space2xs
        visible: root.hasHosts

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.host !== null ? root.host.hostName : ""
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeTitleLg
            elide: Text.ElideRight
        }

        // Status carries its own colour rather than a separate indicator: the
        // dot said the same thing the line already said, so it was two marks for
        // one fact. Reachability is the fact, and the status swatches are what
        // the design system has for it.
        Text {
            id: statusText
            anchors.horizontalCenter: parent.horizontalCenter
            // Copy is brief §8 verbatim wherever it specifies a line.
            text: {
                if (root.host === null) {
                    return ""
                }
                if (root.connectingIndex === pathView.currentIndex) {
                    // MINIMAL / NOT YET DESIGNED -- flagged in the spec.
                    return qsTr("Connecting…")
                }
                if (root.host.statusUnknown) {
                    return qsTr("Looking for your PC…")
                }
                if (!root.host.online) {
                    return qsTr("Couldn't reach %1").arg(root.host.hostName)
                }
                if (!root.host.paired) {
                    return qsTr("Not paired yet.")
                }
                return qsTr("Ready when you are.")
            }
            // Red and green state only what is settled: unreachable, or ready.
            // In-between states -- still looking, connecting, not yet paired --
            // are not a verdict, so they stay on the neutral text colour rather
            // than claiming a success or a failure that has not happened.
            color: {
                if (root.host === null || root.connectingIndex === pathView.currentIndex
                        || root.host.statusUnknown) {
                    return Bulan.textSecondary
                }
                if (!root.host.online) {
                    return Bulan.statusError
                }
                if (!root.host.paired) {
                    return Bulan.textSecondary
                }
                return Bulan.statusSuccess
            }
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeBodyLg
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.host !== null ? (root.host.address || "") : ""
            color: Bulan.secondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeBody
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
                  // Wake only where waking means something. actWake() returns
                  // immediately on a host that is already awake, so advertising
                  // it there offered a button that did nothing -- defect 2.
                  { action: "alternate", label: qsTr("Wake"),
                    visible: !root.hostOnline },
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
    // of through PathView's own increment/decrement -- those wrap by design.
    Keys.onLeftPressed: {
        if (pathView.currentIndex > 0) {
            pathView.currentIndex--
        }
    }
    Keys.onRightPressed: {
        if (pathView.currentIndex < pathView.count - 1) {
            pathView.currentIndex++
        }
    }

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
