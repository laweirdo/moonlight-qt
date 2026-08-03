import QtQuick 2.9
import QtQuick.Effects
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
                    address: addr,
                    details: "Name: " + n + "\nStatus: " + (on ? "Online" : "Offline"),
                    uuid: "review:" + n
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
            //
            // Steambox is discovered but NOT paired, which is the exact state the
            // client was looking at when they reported the count reading "1 of 1
            // ready" beside two visible machines. Without an unpaired host in
            // some preset that rule cannot be reviewed at all.
            if (fakeHosts === "two") {
                append(host("Shoebox", true, true, "192.168.1.24"))
                append(host("Steambox", true, false, "192.168.1.31"))
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

    // Which host is connecting, which is waking, and which one's wake just
    // failed -- three independent slots rather than one shared "busy" pair.
    //
    // Keyed on UUID rather than carousel index, unlike the provisional
    // `connectingIndex` this replaces. A connection lived for one JS tick, so an
    // index was safe for it -- nothing could reorder the list in that window. A
    // wake is held open for up to 30 seconds (hostTileWakeTimeoutMs), and in that
    // span discovery can insert, remove or reorder rows -- that is exactly why
    // hostRepeater.onItemAdded/onItemRemoved below already re-resolve the
    // selection -- and the player is free to navigate to a different host while
    // the wake they started is still running. An index recorded at the moment
    // the wake began would silently point at whatever host now happens to sit
    // there. HostSettingsOverlay hit this same identity problem first: it stores
    // hostUuid and has the caller re-resolve it via computerIndexForUuid()
    // immediately before acting, rather than trusting a row captured when the
    // menu opened. This is the same fix applied to the tile's busy state.
    //
    // Separate from the UUID question is why there are three properties instead
    // of one pair. A single busyHostUuid/busyKind used to hold both connecting
    // and waking, on the assumption that only one host is ever busy at a time.
    // That assumption breaks the moment the player wakes host A, then -- with
    // A's 30-second clock still running -- selects a different, already-online
    // host B and presses A: setBusy(B.uuid, "connecting") would overwrite A's
    // entry outright, stop A's timeout timer, and leave A's wake dangling with
    // nothing left to ever resolve it. Connecting and waking are genuinely
    // independent in time -- one lasts a JS tick, the other up to 30 seconds and
    // survives navigating away -- so they need independent storage. Only one
    // wake is tracked at a time even so: waking a second host while the first is
    // still waking is not supported, and there is no fake-host preset or client
    // decision asking for it.
    property string connectingHostUuid: ""
    property string wakingHostUuid: ""
    property string wakeResultUuid: ""   // set on failure; "" once the hold ends
    property bool reviewMenuOpened: false
    property bool reviewWakeStarted: false
    property bool reviewAppsOpened: false

    // Starts (or restarts) a connection wait. One tick long in practice, but not
    // timed -- it ends when openAppView() either pushes AppView or hits one of
    // its own error returns, not on a clock.
    function beginConnecting(uuid) {
        connectingHostUuid = uuid
    }

    // Ends the connection wait, on success (AppView pushed) or failure alike.
    function clearConnecting() {
        connectingHostUuid = ""
    }

    // Starts (or restarts) a wake. Restarting matters: a second wake on a
    // different host, begun after the first settled or was abandoned, needs the
    // 30-second clock to run fresh rather than inherit whatever the timer was
    // doing before.
    function beginWake(uuid) {
        wakingHostUuid = uuid
        wakeResultUuid = ""
        busyResultHoldTimer.stop()
        wakeTimeoutTimer.restart()
    }

    // Resolves the wake for the given host. Takes the UUID, rather than acting
    // on "whatever is currently waking", and is ignored outright if it does not
    // match wakingHostUuid -- that is what makes a stray call safe: the timeout
    // firing just after the host happens to come online, or (per the fix this
    // replaces) a second host's wake finishing while this one still holds
    // wakeResultUuid from an earlier failure.
    //
    // Success clears the waking slot outright: the tile has nothing to hold on
    // screen once the host is back, so it reads its normal "Ready when you are."
    // copy on the very next frame. Failure is a verdict rather than a
    // transition, so it moves into wakeResultUuid and starts the hold timer --
    // brief §8's "Couldn't wake" needs to be legible for a moment rather than
    // vanishing the instant the 30 seconds expire -- and clearing wakeResultUuid
    // at the end of that hold reverts the tile to its normal offline copy with
    // nothing left for the player to dismiss, per the acceptance criteria.
    function resolveWake(uuid, success) {
        if (uuid !== wakingHostUuid) {
            return
        }
        wakeTimeoutTimer.stop()
        wakingHostUuid = ""
        if (success) {
            wakeResultUuid = ""
        } else {
            wakeResultUuid = uuid
            busyResultHoldTimer.restart()
        }
    }

    // True while the FOCUSED host -- the one actConfirm()/actWake() would act on
    // right now -- is connecting or waking. wakeFailed is deliberately excluded:
    // that is a settled verdict, not a wait, so it must not block a fresh press
    // the way an in-flight action does (see actConfirm()/actWake()'s no-op guard
    // below, and the Wake hint's visibility).
    readonly property bool hostIsBusy: host !== null &&
                                        (host.uuid === connectingHostUuid || host.uuid === wakingHostUuid)

    // Gives up on a wake that has run for hostTileWakeTimeoutMs (30s, the
    // client's figure) without the host coming back.
    Timer {
        id: wakeTimeoutTimer
        interval: Bulan.hostTileWakeTimeoutMs
        onTriggered: root.resolveWake(root.wakingHostUuid, false)
    }

    // Holds "wakeFailed" on screen long enough to read as a verdict before the
    // tile reverts to its ordinary offline copy on its own.
    Timer {
        id: busyResultHoldTimer
        interval: Bulan.hostTileBusyResultHoldMs
        onTriggered: root.wakeResultUuid = ""
    }

    // Review hook: MOONLIGHT_FAKE_WAKE_OUTCOME=success. A fake host's `online`
    // in fakeModel is a static false -- nothing in review mode ever flips it --
    // so without this a fake wake could only ever be reviewed failing: it runs
    // the full 30-second wakeTimeoutTimer and gives up every time. actWake()
    // starts this alongside beginWake() when the outcome is "success", and on
    // firing it calls fakeModel.setProperty(row, "online", true) rather than
    // resolveWake() directly. That distinction is the whole point of the hook:
    // setProperty() changes the delegate's own `online`, which drives the
    // delegate's existing onOnlineChanged below to call resolveWake() itself --
    // the same path a real host's poll-thread update takes. Calling
    // resolveWake() from here instead would make the hook review its own call
    // rather than the real resolution path. 3 seconds reads as a genuine wait
    // without making a reviewer sit through anything close to the 30-second
    // failure case. "timeout" or unset leaves this timer never started, so
    // fake wakes give up exactly as before.
    Timer {
        id: fakeWakeSuccessTimer
        interval: 3000
        onTriggered: {
            var uuid = root.wakingHostUuid
            for (var i = 0; i < fakeModel.count; i++) {
                if (fakeModel.get(i).uuid === uuid) {
                    fakeModel.setProperty(i, "online", true)
                    break
                }
            }
        }
    }

    // Review hook: MOONLIGHT_FAKE_CONNECT_HOLD_MS. actConfirm()'s useFakeHosts
    // branch (below) stops before openAppView() on purpose -- see that guard's
    // own comment for the crash a fake row's index caused there -- which also
    // means the connecting dots have never had anything to be reviewed on.
    // This does not move or weaken that guard: it only runs beginConnecting()/
    // clearConnecting(), the same pair a real connection's one JS tick would,
    // held open for a chosen number of milliseconds instead. It never calls
    // openAppView(), never reads computerIndex, and never resolves a real host.
    Timer {
        id: fakeConnectHoldTimer
        interval: typeof fakeConnectHoldMs !== "undefined" ? fakeConnectHoldMs : 0
        onTriggered: root.clearConnecting()
    }

    // Review hook: MOONLIGHT_OPEN_APPS_FOR_HOST=<name>. Opens the game grid for
    // a real, paired host so box art can actually be looked at -- the one thing
    // no fake preset can stand in for, because BoxArtManager only has files for
    // machines the app has really talked to.
    //
    // It polls rather than acting once, because a saved host starts OFFLINE:
    // ComputerManager loads it from settings immediately but does not know it is
    // reachable until the discovery poll answers, which is roughly 3 seconds
    // after launch on this network. Acting on the first frame would find the
    // host, find it offline, and route the press to a WAKE instead of the game
    // grid -- the hook would silently review the wrong thing.
    //
    // Matched on name rather than row: discovery decides the row order and it is
    // not stable between runs, which is the same identity problem the busy
    // state's UUID keying exists to solve.
    //
    // Gives up after openAppsReviewTimer's own budget rather than polling
    // forever, so a typo in the name says so in the log instead of hanging.
    property int reviewAppsAttempts: 0

    Timer {
        id: openAppsReviewTimer
        interval: 250
        repeat: true
        onTriggered: {
            root.reviewAppsAttempts++
            for (var i = 0; i < hostRepeater.count; i++) {
                var tile = hostRepeater.itemAt(i)
                if (!tile || tile.hostName !== openAppsForHost) {
                    continue
                }
                if (!tile.online || !tile.paired) {
                    // Found, but not usable yet. Keep waiting -- this is the
                    // ordinary state for the first few seconds after launch.
                    break
                }
                stop()
                root.reviewAppsOpened = true
                root.selectIndex(i)
                root.openAppView(i, tile.uuid, tile.hostName, false)
                return
            }
            // 80 tries at 250ms is 20 seconds, comfortably past the discovery
            // poll's own cadence.
            if (root.reviewAppsAttempts >= 80) {
                stop()
                console.warn("MOONLIGHT_OPEN_APPS_FOR_HOST: no reachable paired host named",
                             openAppsForHost, "after", root.reviewAppsAttempts, "tries")
            }
        }
    }

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
    Component.onCompleted: {
        refreshHost()
        if (!root.hasHosts) {
            zeroHostsEntranceDelay.restart()
        }
    }

    // --- zero-hosts entrance ---------------------------------------------
    // Motion rule: the zero-hosts state (below) waits out the screen
    // transition before it moves, exactly like AppView's own
    // gridEntranceStarted -- motionTransitionMs is the same "screen has
    // settled" duration, reused rather than a second raw value.
    //
    // Reset on every true->false edge of hasHosts, not just once at
    // Component.onCompleted: the carousel is a persistent object (only
    // AppView is destroyed and recreated per visit -- see the file banner),
    // so losing the last known host while this screen is already open --
    // Forget PC on the final remaining host, or discovery losing it -- is a
    // real way to arrive here without the object ever being recreated.
    property real zeroHostsEntranceProgress: 0
    onHasHostsChanged: {
        if (!hasHosts) {
            zeroHostsEntranceProgress = 0
            zeroHostsEntranceDelay.restart()
        }
    }
    Timer {
        id: zeroHostsEntranceDelay
        interval: Bulan.motionTransitionMs
        onTriggered: zeroHostsEntranceAnimation.start()
    }
    SequentialAnimation {
        id: zeroHostsEntranceAnimation
        NumberAnimation {
            target: root
            property: "zeroHostsEntranceProgress"
            to: 1
            duration: Bulan.motionGridEntranceRiseMs
            // One restrained overshoot, one bounce -- brief §6 rule 1 --
            // rather than motionOvershoot's stronger press-release curve.
            easing.type: Easing.OutBack
            easing.overshoot: Bulan.motionEntranceOvershoot
        }
    }

    readonly property bool hostOnline: host !== null && host.online

    // Whether waking this host could actually do anything. The app can only wake
    // a machine whose hardware address it has learned, and it learns that from
    // the host's own reply -- Sunshine does not always give one.
    readonly property bool hostWakeable: host !== null && host.wakeable

    function createModel() {
        var model = Qt.createQmlObject('import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        model.pairingCompleted.connect(pairingComplete)
        model.connectionTestCompleted.connect(connectionTestComplete)
        return model
    }

    function pairingComplete(error) {
        pinPanel.visible = false
        if (error !== undefined) {
            messagePanel.show(qsTr("Couldn't pair"), error)
        }
        recount()
    }

    function connectionTestComplete(result, blockedPorts) {
        // Leaving the progress page abandons only its presentation; the
        // upstream connectivity task is allowed to finish in the background.
        if (!hostSettingsMenu.visible || !hostSettingsMenu.networkTestPending) {
            return
        }

        if (result === -1) {
            hostSettingsMenu.showFeedback(
                        qsTr("Test unavailable"),
                        qsTr("Moonlight couldn't reach its connection-testing servers. Check this device's internet connection and try again."))
        } else if (result === 0) {
            hostSettingsMenu.showFeedback(
                        qsTr("Network looks ready"),
                        qsTr("Moonlight did not detect any blocked streaming ports on this network."))
        } else {
            hostSettingsMenu.showFeedback(
                        qsTr("Streaming ports are blocked"),
                        qsTr("This network may prevent streaming over the internet.")
                            + "\n\n" + qsTr("Blocked ports:")
                            + "\n" + blockedPorts)
        }
    }

    // --- ready count ---------------------------------------------------------
    // "hosts you can use, out of hosts you have".
    //
    // The denominator counts EVERY machine in the carousel, including ones
    // discovered but not yet paired. It used to count only paired ones, on the
    // reasoning that a machine is not yours to count until you have paired it.
    //
    // Seen in use that reads as a fault rather than a principle: with Steambox
    // unpaired and Shoebox online the line said "1 of 1 ready" while two
    // machines were plainly on screen, so the count contradicted the carousel
    // beside it. Client's call, 28 July 2026 -- the denominator is machines you
    // have, not machines you have finished setting up.
    //
    // The numerator is unchanged and still means "ready to stream": online AND
    // paired. An unpaired host is visible and selectable but cannot be
    // connected to, so counting it as ready would promise something the A
    // button will not deliver.
    property int totalCount: 0
    property int readyCount: 0

    function recount() {
        var total = 0, ready = 0
        for (var i = 0; i < counter.count; i++) {
            var it = counter.itemAt(i)
            if (it) {
                total++
                if (it.isPaired && it.isOnline) {
                    ready++
                }
            }
        }
        totalCount = total
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

    // A fresh AppView is created on every entry (see the createObject() call
    // below) and destroys itself on the way out (AppView.qml's
    // StackView.onRemoved) rather than being retained the way the launch and
    // quit surfaces retain it -- see BUGS.md's "forgets itself" defect. This
    // is where the app remembers what a discarded instance was showing, so
    // the next fresh instance for the SAME host can look like it never left.
    //
    // Keyed by host UUID rather than carousel index or row, for the same
    // reason busyHostUuid/wakingHostUuid are: discovery can reorder the
    // carousel while a grid is open elsewhere. In memory only, for this app
    // session only -- nothing here is written to disk, and a different host's
    // entry is never read or touched by this one.
    property var appViewContextByHostUuid: ({})

    // Connected to every AppView this screen creates. AppView calls this on
    // itself right before destroy() -- see contextSaved's declaration -- so
    // the dependency runs the same direction optionsRequested and
    // switchGameRequested already do: AppView names what happened, this
    // screen decides what to do with it.
    function rememberAppViewContext(hostUuid, context) {
        root.appViewContextByHostUuid[hostUuid] = context
    }

    function openAppView(computerIndex, hostUuid, hostName, showHiddenGames) {
        beginConnecting(hostUuid)
        var component = Qt.createComponent("AppView.qml")
        // Without these checks a failure to build the game grid is completely
        // silent: createObject() returns null, push(null) does nothing, and A
        // looks dead with no clue on screen.
        if (component.status !== Component.Ready) {
            console.error("AppView.qml failed to load:", component.errorString())
            clearConnecting()
            messagePanel.show(qsTr("Can't open %1").arg(hostName),
                              qsTr("Something went wrong loading the game list."))
            return
        }

        var savedContext = root.appViewContextByHostUuid[hostUuid]
        var properties = {
            "computerIndex": computerIndex,
            "objectName": hostName,
            "hostUuid": hostUuid,
            "restoreContext": savedContext !== undefined ? savedContext : null
        }
        if (showHiddenGames) {
            properties.showHiddenGames = true
        }

        var view = component.createObject(stackView, properties)
        if (view === null) {
            console.error("AppView.qml loaded but could not be created")
            clearConnecting()
            messagePanel.show(qsTr("Can't open %1").arg(hostName),
                              qsTr("Something went wrong loading the game list."))
            return
        }
        view.contextSaved.connect(root.rememberAppViewContext)
        stackView.push(view)
    }

    function actConfirm() {
        if (host === null) {
            return
        }
        // A repeated press on a host that is already connecting or waking does
        // nothing, rather than restarting the connection or the wake. This is
        // checked before flashPress() deliberately: flashPress() is the visual
        // acknowledgement that a press landed and did something, and a no-op
        // press did not, so giving press feedback here would tell the player
        // their input mattered when it was thrown away.
        if (root.hostIsBusy) {
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
            // Review hook: MOONLIGHT_FAKE_CONNECT_HOLD_MS. When set, rehearse
            // the connecting dots instead of showing the message below --
            // beginConnecting()/clearConnecting() are the exact pair a real
            // connection's one JS tick runs, just held open on a timer. The
            // "Review mode" message is withheld while this hold is running,
            // not shown alongside it: that message is a full-screen HostPanel
            // and would sit on top of the very tile the hold exists to make
            // visible, hiding the thing under review. This still never calls
            // openAppView() and never touches computerIndex -- see the guard
            // comment a few lines below for the crash that rule prevents;
            // this hook does not move or weaken it.
            if (typeof fakeConnectHoldMs !== "undefined" && fakeConnectHoldMs > 0) {
                beginConnecting(host.uuid)
                fakeConnectHoldTimer.restart()
                return
            }
            // Review hook: MOONLIGHT_FAKE_HOSTS together with MOONLIGHT_FAKE_GAMES.
            // Lets Stage 1's destroy-on-leave and per-host restore (BUGS.md's two
            // carousel-round-trip defects) be exercised repeatedly with no real
            // paired host attached -- Confirm opens, B leaves, Confirm again on
            // the same fake host proves both the old instance was destroyed and
            // the new one restored this host's tab/selection/scroll.
            //
            // This does not weaken the guard above: that guard exists because
            // openAppView() otherwise leads to code that indexes the REAL host
            // list at this fake row's position (pairComputer(), the branches
            // below). AppView with fakeGames active never does anything of the
            // kind -- createModel() returns null without touching
            // ComputerManager and gameModel becomes the fake ListModel instead
            // (see AppView.qml) -- so computerIndex reaches AppView here but is
            // never read. Both variables must be set together on purpose; this
            // is inert with either one alone.
            if (typeof fakeGames !== "undefined" && fakeGames !== "" && fakeGames !== "off") {
                openAppView(root.currentIndex, host.uuid, host.hostName, false)
                return
            }
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

        openAppView(root.currentIndex, host.uuid, host.hostName, false)
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
        // Repeating Wake (or Confirm, which redirects here for an offline host)
        // on a host that is already waking must do nothing -- the packet was
        // already sent and there is nothing a second press can add to it.
        if (root.hostIsBusy) {
            return
        }
        if (!root.useFakeHosts) {
            computerModel.wakeComputer(root.currentIndex)
        } else if (typeof fakeWakeOutcome !== "undefined" && fakeWakeOutcome === "success") {
            // See fakeWakeSuccessTimer above for why this starts a timer
            // rather than resolving the wake itself.
            fakeWakeSuccessTimer.restart()
        }
        // No popup here any more. The client rejected the HostPanel "Waking…"
        // message on 28 July 2026 review -- this task folds that decision in --
        // and the tile now carries the wait itself via busyKind === "waking".
        beginWake(host.uuid)
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

    // Adding a PC opens the onboarding screen, not a popup (client review,
    // 3 August 2026). This used to raise addPcPanel -- a bare "type an
    // address" box, which is upstream's Add PC dialog with Bulan paint on it
    // and skips the discovery step entirely. FLOW.md has always drawn this
    // edge as "Your PCs --> Add another --> find your PC"; it is the same
    // destination actLookAgain() uses, because adding a PC and looking again
    // are the same act from the player's side.
    //
    // The manual-address escape hatch is not lost: HostDiscovery.qml carries
    // "Enter an address instead", which is where a typed address belongs --
    // after looking has failed, not instead of looking.
    function actAddPc() {
        stackView.push("HostDiscovery.qml")
    }

    // The zero-hosts state's primary action -- the same re-scan FirstRun.qml's
    // "Look" button starts, reached from the other direction. Pushes straight
    // to the discovered-hosts list rather than back through FirstRun's own
    // splash copy, since this screen already implies "look again", not "look
    // for the first time".
    function actLookAgain() {
        stackView.push("HostDiscovery.qml")
    }

    function actClientSettings() {
        navigateTo("qrc:/gui/SettingsShell.qml", SettingsShell)
    }

    function actHostSettings() {
        if (host === null) {
            return
        }
        hostSettingsMenu.showForHost({
            uuid: host.uuid,
            name: host.hostName,
            address: host.address,
            details: host.details,
            online: host.online,
            paired: host.paired,
            wakeable: host.wakeable,
            statusUnknown: host.statusUnknown,
            reviewMode: root.useFakeHosts,
            wakePending: host.uuid === root.wakingHostUuid
        })
    }

    function handleHostMenuAction(actionId, hostUuid, hostName) {
        // A fake row number can name a real machine at the same position. Block
        // the entire real-action path before resolving or dispatching anything.
        if (root.useFakeHosts) {
            hostSettingsMenu.showFeedback(
                        qsTr("Review mode"),
                        qsTr("%1 isn't a real PC, so nothing was changed.")
                            .arg(hostName))
            return
        }

        // Resolve the stable identity at activation time. Discovery may have
        // inserted, removed or reordered rows since the overlay opened.
        var computerIndex = computerModel.computerIndexForUuid(hostUuid)
        if (computerIndex < 0) {
            hostSettingsMenu.showFeedback(
                        qsTr("PC no longer available"),
                        qsTr("%1 changed while this menu was open. Close it and try again.")
                            .arg(hostName))
            return
        }

        if (actionId === "apps") {
            hostSettingsMenu.close()
            openAppView(computerIndex, hostUuid, hostName, true)
        } else if (actionId === "wake") {
            // Closed before waking, not after: the busy tile this produces is
            // drawn on the carousel behind the overlay, and leaving the overlay
            // open would hide the very feedback the action just produced. No
            // showFeedback() call either, for the same reason the popup is gone
            // from actWake() -- the tile now carries the wait.
            hostSettingsMenu.close()
            computerModel.wakeComputer(computerIndex)
            beginWake(hostUuid)
        } else if (actionId === "testNetwork") {
            hostSettingsMenu.showNetworkTestPending()
            computerModel.testConnectionForComputer(computerIndex)
        } else if (actionId === "forget") {
            hostSettingsMenu.close()
            computerModel.deleteComputer(computerIndex)
        }
    }

    // --- lifecycle -----------------------------------------------------------
    StackView.onActivated: {
        // No toolbar here: the wordmark and the hint bar are this screen's chrome.
        toolBar.visible = false

        // Arrow-key navigation, not the settings page's tab chain.
        SdlGamepadKeyNavigation.setUiNavMode(false)

        // Only the connecting slot. Arriving on this screen at all means the
        // AppView a connection was waiting on either never opened or has since
        // been left, so whatever it was waiting for is moot either way.
        //
        // A wake is untouched here, and that is the point of the two slots being
        // separate. Pushing and popping another host's AppView deactivates and
        // reactivates this carousel without destroying it, so a wake that was
        // running before the push is still genuinely running now -- the packet
        // was sent, the machine is still booting, and its timeout is still
        // counting. Clearing it here would drop it on the floor with no success
        // and no failure to show for it.
        clearConnecting()
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
        if (root.useFakeHosts &&
                typeof hostSettingsReviewIndex !== "undefined" &&
                hostSettingsReviewIndex >= 0 &&
                hostSettingsReviewIndex < hostRepeater.count) {
            root.currentIndex = hostSettingsReviewIndex
        }
        refreshHost()
        root.forceActiveFocus()

        if (root.useFakeHosts && !reviewMenuOpened &&
                typeof openHostSettingsForReview !== "undefined" &&
                openHostSettingsForReview) {
            reviewMenuOpened = true
            Qt.callLater(function() {
                root.actHostSettings()
                if (typeof hostSettingsReviewAction !== "undefined" &&
                        hostSettingsReviewAction !== "") {
                    Qt.callLater(function() {
                        hostSettingsMenu.activateActionForReview(
                                    hostSettingsReviewAction)
                    })
                }
            })
        }

        // Review hook: MOONLIGHT_FAKE_WAKE_ON_START. Presses Wake for the
        // screenshot hook, which grabs the window on a timer and cannot press a
        // button itself. Without this the busy state could only ever be argued
        // for, never looked at, on a machine with no host it can put to sleep.
        //
        // It calls actWake() rather than beginWake() directly, so the review
        // goes through the same refusals and guards a real press does -- an
        // unwakeable host still gets "Can't wake this one" here, exactly as it
        // should, rather than the hook forcing dots onto a tile that would
        // never show them in use.
        // Review hook: MOONLIGHT_OPEN_APPS_FOR_HOST. Real hosts only -- a fake
        // row's index names a real machine at the same position, which is the
        // crash actConfirm()'s review guard exists to prevent, and openAppView()
        // is exactly the call that guard blocks. Runs once per app launch, not
        // once per return to this screen: reopening the grid every time the
        // player backs out of it would make B useless.
        if (!root.useFakeHosts && !reviewAppsOpened &&
                typeof openAppsForHost !== "undefined" && openAppsForHost !== "") {
            reviewAppsAttempts = 0
            openAppsReviewTimer.restart()
        }

        if (root.useFakeHosts && !reviewWakeStarted &&
                typeof fakeWakeOnStart !== "undefined" && fakeWakeOnStart) {
            reviewWakeStarted = true
            Qt.callLater(function() {
                root.actWake()
            })
        }
    }

    // Deliberately does NOT restore the toolbar.
    //
    // It used to, and that is what made upstream's toolbar flash across the
    // screen every time you opened a host's games: this screen set it visible
    // on the way out, the game grid set it hidden on the way in, and the frames
    // between the two handlers drew it. Both screens are Bulan screens and
    // neither ever wants it, so handing it back and forth was always a fiction.
    //
    // Every screen that genuinely wants the toolbar turns it on in its own
    // onActivated -- SettingsView and PcView both do. main.qml carries the
    // backstop for the reverse case, where an upstream screen hands the toolbar
    // back to a Bulan screen that never asked for it; see `bulanScreen` there.
    readonly property bool bulanScreen: true

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
        if (messagePanel.visible || pinPanel.visible || addPcPanel.visible ||
                hostSettingsMenu.visible) {
            return
        }
        root.forceActiveFocus()
    }

    Item {
        id: screenContent
        anchors.fill: parent
        // Blurred behind ANY panel, not just the host menu (client review,
        // 3 August 2026). The pairing PIN, the message panel and the
        // add-a-PC panel all sat on an unblurred screen, so the same glass
        // treatment appeared or did not depending on which panel you opened.
        layer.enabled: hostSettingsMenu.visible || messagePanel.visible
                       || pinPanel.visible || addPcPanel.visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: Bulan.popupBackdropBlurStrength
            blurMax: Bulan.popupBackdropBlurRadius
        }

        Atmosphere {
            anchors.fill: parent
        }

        // --- header ----------------------------------------------------------
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
        y: wordmark.y + wordmark.height / 2 - height / 2
        spacing: Bulan.spaceXs
        visible: root.totalCount > 0

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Bulan.space2xs
            height: Bulan.space2xs
            radius: width / 2
            color: root.readyCount > 0 ? Bulan.statusSuccess : Bulan.secondary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 of %2 ready").arg(root.readyCount).arg(root.totalCount)
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
        y: wordmark.y + wordmark.height + Bulan.space3xl
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
                uuid: model.uuid

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

                // The tile draws the busy state; the carousel knows about it.
                //
                // Waking wins over connecting if the two ever named the same
                // host -- they should not in practice, since a host that is
                // already waking is by definition offline and actConfirm() would
                // have routed a press on it to actWake() rather than
                // openAppView(), but a wake is the longer-lived truth of the two
                // and the one worth trusting if that assumption is ever wrong.
                //
                // A NEIGHBOUR tile can legitimately be the one showing dots
                // here: if the player navigates away from a host that is still
                // waking, the wake keeps running (it is a magic packet already
                // sent, not something tied to being on screen) and the dots
                // travel with the host's own tile rather than staying pinned to
                // whatever index used to be selected. That following-the-host
                // behaviour is the entire reason this is keyed on UUID instead
                // of the old connectingIndex.
                busyKind: root.wakingHostUuid === uuid ? "waking"
                        : root.wakeResultUuid === uuid ? "wakeFailed"
                        : root.connectingHostUuid === uuid ? "connecting"
                        : ""

                // Resolves a wake the instant this host's model row reports
                // online, with no C++ change needed: ComputerModel::
                // handleComputerStateChanged already emits a per-row dataChanged
                // whenever ComputerManager's monitor thread sees a state flip, so
                // model.online is already live -- it is the same signal that
                // drives this tile's ordinary offline copy. The poll cycle bounds
                // how quickly that arrives to roughly 3 seconds after the machine
                // actually answers.
                onOnlineChanged: {
                    if (online && uuid === root.wakingHostUuid) {
                        root.resolveWake(uuid, true)
                    }
                }

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
    // Reached whenever hostCount is 0: nothing has ever answered, every known
    // host was forgotten, or discovery lost the last one while this screen
    // stayed open. This is the same moment as FirstRun.qml's S1 -- "no host
    // known yet" -- seen from the other direction, so it borrows that
    // screen's composition (crescent, display headline, secondary supporting
    // line, one amber primary action) rather than inventing a second
    // language for an empty carousel. The copy is deliberately NOT FirstRun's
    // own "Let's find your PC.": the player has been here before, so brief
    // §8's warm-second-person register is followed with different words for
    // a different moment.
        Column {
        id: zeroHostsContent
        anchors.centerIn: parent
        // Motion rule: rises into place after the screen itself has settled
        // (see zeroHostsEntranceDelay below), reusing motionGridEntranceRise
        // rather than a raw per-screen distance.
        anchors.verticalCenterOffset: -Bulan.space2xl
                + (1 - root.zeroHostsEntranceProgress) * Bulan.motionGridEntranceRise
        spacing: Bulan.spaceLg
        width: Math.min(parent.width - Bulan.layoutScreenMarginX * 2,
                         Bulan.hostTileSize * 2.4)
        visible: !root.hasHosts
        opacity: Math.min(1, root.zeroHostsEntranceProgress)

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/res/bulan_logomark.svg"
            width: Bulan.onboardingMarkSize
            height: width
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width * 2
            sourceSize.height: width * 2
            smooth: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("No PC to play on right now.")
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeDisplay
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: qsTr("Make sure it's awake and on the same network.")
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeBody
        }

        // --- primary button: FirstRun.qml's own "Look" treatment ------------
        Item {
            id: lookAgainButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(Bulan.hostTileSize * 0.7,
                             lookAgainLabel.implicitWidth + Bulan.space2xl * 2)
            height: Math.max(Bulan.targetMin,
                              lookAgainLabel.implicitHeight + Bulan.spaceLg * 2)

            // Press feedback for controller input, which has no release event
            // to hang a state off -- HostTile.flashPress()'s own pattern.
            property bool pressed: lookAgainMouse.pressed || lookAgainPressFlash.running
            function flashPress() { lookAgainPressFlash.restart() }
            Timer { id: lookAgainPressFlash; interval: Bulan.motionPressMs }

            scale: lookAgainButton.pressed ? Bulan.motionPressScale : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: lookAgainButton.pressed ? Bulan.motionPressMs : Bulan.motionFocusMs
                    easing.type: lookAgainButton.pressed ? Easing.OutCubic : Easing.OutBack
                    easing.overshoot: Bulan.motionOvershoot
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Bulan.radiusLg
                color: Bulan.accentPrimary

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Bulan.accentGlow
                    shadowBlur: Bulan.buttonGlowBlur
                    shadowOpacity: Bulan.buttonGlowOpacity
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }

                Text {
                    id: lookAgainLabel
                    anchors.centerIn: parent
                    text: qsTr("Look again")
                    // Dark text on the amber fill, matching FirstRun.qml's
                    // "Look" -- the only place on this screen text sits on a
                    // light ground rather than the dark atmosphere.
                    color: Bulan.bgBaseOled
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeBodyLg
                    font.bold: true
                }
            }

            MouseArea {
                id: lookAgainMouse
                anchors.fill: parent
                onClicked: {
                    lookAgainButton.flashPress()
                    root.actLookAgain()
                }
            }
        }

        Text {
            id: enterAddressLink
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Enter an address instead")
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeLabel

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Bulan.spaceSm
                onClicked: root.actAddPc()
            }
        }
    }
    } // screenContent

    // --- hint bar ------------------------------------------------------------
    // Lifted out of this screen and into main.qml as a sibling of stackView
    // (client decision, 2 August 2026 review): nothing about this bar
    // changes between the carousel and the grid except its labels, so
    // animating it along with the rest of the screen read as unrefined. A
    // child cannot opt out of its parent's stack-transition opacity, so the
    // single window-level HintBar reads these three properties off
    // whichever screen is current instead of this screen drawing its own.
    // Hidden while any overlay owns the input, because the overlay draws its
    // own hints and the two bars would otherwise print on top of each other --
    // "A Select" over "A Connect", "B Close" over "Host Settings". AppView.qml
    // already guards its bar the same way; this screen was missed.
    readonly property bool hintBarVisible: !hostSettingsMenu.visible
                                           && !messagePanel.visible
                                           && !pinPanel.visible
                                           && !addPcPanel.visible

    readonly property var hintLeftHints: root.hasHosts
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
              //
              //   The wake is already running. Advertising Wake while
              //   hostIsBusy would offer a third button that does nothing --
              //   actWake() no-ops on a host that is already connecting or
              //   waking, per the guard added there -- so it is withheld for
              //   exactly the same reason as the two cases above.
              { action: "alternate", label: qsTr("Wake"),
                visible: !root.hostOnline && root.hostWakeable && !root.hostIsBusy },
              { action: "options",   label: qsTr("Add a PC") }
          ]
        : [
              { action: "confirm", label: qsTr("Look again"), emphasis: true },
              { action: "options", label: qsTr("Enter an address instead") }
          ]

    readonly property var hintRightHints: root.hasHosts
        ? [
              { action: "start",  label: qsTr("Client Settings") },
              { action: "select", label: qsTr("Host Settings") }
          ]
        : [
              { action: "start", label: qsTr("Client Settings") }
          ]

    // --- input ---------------------------------------------------------------
    // Movement clamps rather than wrapping, which is why it is done here instead
    // of anywhere else: moveBy() is the only thing that writes the selection.
    Keys.onLeftPressed: moveBy(-1)
    Keys.onRightPressed: moveBy(1)

    // Inert, and swallowed. Without accepting them they bubble to the StackView
    // and drag focus into chrome this screen does not have.
    Keys.onUpPressed: function(event) { event.accepted = true }
    Keys.onDownPressed: function(event) { event.accepted = true }

    // A. Three keycodes for one button: Return and Enter are the same press on
    // different keyboards, and Space is what A becomes while the settings page's
    // tab chain is armed. This screen never wants that chain, but accepting
    // Space anyway means a mode that leaks in from elsewhere can no longer make
    // A do nothing at all -- which is the failure defect 1 produced, and the
    // reason it read as a pairing problem rather than a navigation one.
    //
    // With zero hosts there is no host for actConfirm() to act on -- it
    // returns immediately on a null host -- so A instead does what the
    // zero-hosts state's own primary button does: look again.
    Keys.onReturnPressed: function(event) {
        if (root.hasHosts) {
            actConfirm()
        } else {
            actLookAgain()
        }
    }
    Keys.onEnterPressed: function(event) {
        if (root.hasHosts) {
            actConfirm()
        } else {
            actLookAgain()
        }
    }
    Keys.onSpacePressed: function(event) {
        if (root.hasHosts) {
            actConfirm()
        } else {
            actLookAgain()
        }
        event.accepted = true
    }

    // X. Menu is also what the toolbar used for settings upstream; consumed here.
    Keys.onMenuPressed: function(event) {
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

    HostSettingsOverlay {
        id: hostSettingsMenu
        anchors.fill: parent
        onActionRequested: function(actionId, hostUuid, hostName) {
            root.handleHostMenuAction(actionId, hostUuid, hostName)
        }
        onVisibleChanged: if (!visible) Qt.callLater(root.reclaimFocus)
    }
}
