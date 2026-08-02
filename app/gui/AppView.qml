import QtQuick 2.9
// Imported for the StackView attached properties (StackView.onActivated) only --
// this screen pushes and pops through the app's existing StackView. No stock
// control from this module is instantiated anywhere in this file.
import QtQuick.Controls 2.2

import AppModel 1.0
import ComputerManager 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// The game grid: a host-specific Recent and Library view of one host's games.
//
// Stage 3 (this pass) adds: the Recent view and its ordering, tab switching,
// all controller navigation (A/X/B/L1/R1/START/SELECT), launching, and focus
// recovery. See TASK-BRIEF.md's stage table -- stage 1 built the static shell
// and model, stage 2 built GameTile.qml.
//
// Replaces stock upstream AppView.qml, which instantiated CenteredGridView,
// NavigableItemDelegate, RoundButton, ToolTip, NavigableMenu,
// NavigableMessageDialog and ScrollBar throughout -- all forbidden on a Bulan
// screen by AGENTS.md. This is a rebuild, not an edit, following the same
// principle HostCarousel.qml established: a delegate's position is a pure
// function of its own index, not something a view component works out for you.
//
// Reached from exactly two places in HostCarousel.qml (actConfirm() and
// handleHostMenuAction("apps")), both passing computerIndex and
// showHiddenGames and setting objectName to the host's name. That contract is
// preserved unchanged -- see createModel() and the header below, which reads
// the host name straight off objectName rather than adding a second path for
// the same string.
//
// The per-game options popup (X) and the quit-and-switch confirmation are
// NOT built here. This file emits optionsRequested()/switchGameRequested()
// and accepts the event; another agent owns the popup and confirmation and
// wires them to these signals separately.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    focus: true

    property int computerIndex
    property bool showHiddenGames

    // Set by HostCarousel.openAppView() alongside computerIndex/objectName --
    // see that function and BUGS.md's "forgets itself" defect. hostUuid names
    // whose context this instance publishes on the way out; restoreContext is
    // whatever that host last published, or null for a host with nothing
    // saved yet (including every fake-host/review path that never sets it).
    property string hostUuid: ""
    property var restoreContext: null

    // Emitted once, from StackView.onRemoved just before destroy() -- see
    // that handler below -- so HostCarousel can remember this host's tab,
    // selected game and Library scroll for the rest of the app session. Kept
    // one-directional, the same way optionsRequested/switchGameRequested are:
    // this file only reports what it was showing, never reaches up into
    // HostCarousel to store it itself.
    signal contextSaved(string hostUuid, var context)

    // Grid entrance: Recent and Library tiles rise from below in a short
    // stagger once this screen has visually arrived, replacing the old
    // horizontal slide-into-rank motion (client decision, 2 August 2026
    // review -- see the Recent/Library delegates below and the tokens in
    // Bulan.qml). False for exactly motionGridEntranceDelayMs after this
    // screen is created -- which is also exactly when it is pushed, so this
    // waits out the screen transition itself before any tile moves. A fresh
    // AppView instance is created on every push (HostCarousel.openAppView()),
    // so re-entering the grid always replays this from scratch.
    property bool gridEntranceStarted: false

    Timer {
        id: gridEntranceTimer
        interval: Bulan.motionGridEntranceDelayMs
        running: true
        onTriggered: root.gridEntranceStarted = true
    }

    // Belt-and-braces against a settled tile re-entering. Ordinary Recent
    // re-ranking (a launch updates lastPlayed, recomputeRecentOrder() below
    // reorders) never recreates a delegate -- rank/slot/x are plain
    // property bindings recomputed on the SAME Item, and Repeater only
    // destroys/creates delegates on an actual model row insert, remove, or
    // reset, none of which this screen's own code triggers for reordering.
    // These two sets exist for the cases that are less certain -- a host's
    // app list arriving in chunks after this screen is already open (see
    // libraryFlickable's "rows come in chunks" comment), or any future
    // change that does cause a delegate to be recreated for a game already
    // shown once. Recent and Library are tracked separately: the same game
    // legitimately gets its own first entrance in each grid.
    property var recentEntranceSeenAppIds: ({})
    property var libraryEntranceSeenAppIds: ({})

    // Returns true if this appId already played its entrance in this grid
    // during this screen instance, marking it seen as a side effect either
    // way -- so a delegate's own Component.onCompleted can call this once
    // and know, from the single return value, whether to animate in or
    // simply appear settled.
    function markRecentEntranceSeen(appId) {
        var key = String(appId)
        if (root.recentEntranceSeenAppIds[key] === true) {
            return true
        }
        root.recentEntranceSeenAppIds[key] = true
        return false
    }

    function markLibraryEntranceSeen(appId) {
        var key = String(appId)
        if (root.libraryEntranceSeenAppIds[key] === true) {
            return true
        }
        root.libraryEntranceSeenAppIds[key] = true
        return false
    }

    property AppModel appModel: createModel()

    // Emitted instead of building the popup. X on a tile means "show its
    // options"; this file only names which game, not what the popup contains.
    signal optionsRequested(var appId, string origin)

    // Emitted instead of building the confirmation. A on a game while a
    // DIFFERENT one is running must not launch -- see actConfirmOn() below.
    signal switchGameRequested(var appId, string origin,
                               string runningName, string nextName,
                               string returnTarget)

    // Stage 2 can bind its transient launch visual to this without introducing
    // another environment variable or a network-timed replay path.
    signal reviewLaunchCycleRequested(var reviewState, int cycle)

    // Debug hook. MOONLIGHT_FAKE_GAMES=none|one|partial|many|mixed substitutes a
    // fixed game list, following MOONLIGHT_FAKE_HOSTS's exact precedent in
    // HostCarousel.qml. Required, not optional: the review station has no
    // paired host with a game library, and a fake host cannot open a real game
    // list at all (HostCarousel.actConfirm() blocks that path outright -- a
    // fake row's index names a real machine at the same position, and reading
    // past the end of that list segfaulted the app once already). Without this
    // hook the screen could not be looked at before the client sees it.
    readonly property bool useFakeGames:
        typeof fakeGames !== "undefined" && fakeGames !== "" && fakeGames !== "off"
    property var gameModel: useFakeGames ? fakeModel : appModel

    ListModel {
        id: fakeModel
        Component.onCompleted: {
            if (!root.useFakeGames) {
                return
            }

            // MOONLIGHT_FAKE_GAMES_ART, exposed as fakeGamesArtDir: when set,
            // fake games get real box art (1.jpg, 2.jpg, ... in that directory)
            // instead of an empty string, so the client can drop real art into
            // a folder and see the actual image path rather than always the
            // fallback. Assigned in call order, one file per game appended
            // below, across every preset -- not per preset -- so "1.jpg" is
            // always the first game any given preset adds.
            var artDir = (typeof fakeGamesArtDir !== "undefined") ? fakeGamesArtDir : ""
            var artIndex = 0
            function art() {
                artIndex++
                return artDir !== "" ? ("file:///" + artDir + "/" + artIndex + ".jpg") : ""
            }

            function daysAgo(days) {
                var d = new Date()
                d.setDate(d.getDate() - days)
                return d
            }

            // appid is just the call order; nothing here reads it as anything
            // but an identifier.
            //
            // "Never played" is the epoch, not undefined. A ListModel infers
            // its roles from the objects appended to it and refuses an
            // undefined member outright -- "Adding an object with a undefined
            // member does not create a role for it" -- so the role would simply
            // not exist on those rows. It cannot be an empty string either: a
            // role's type is fixed by the first row that sets it, and mixing a
            // string with a Date in one role is asking to be coerced.
            //
            // The real model expresses the same state differently: NvApp's
            // lastPlayed is a default-constructed QDateTime, which arrives in
            // QML as an INVALID Date whose getTime() is NaN. Both are read
            // through playedAt() below, which flattens either to 0.
            function game(name, opts) {
                opts = opts || {}
                return {
                    name: name,
                    running: opts.running === true,
                    boxart: art(),
                    hidden: opts.hidden === true,
                    appid: artIndex,
                    directLaunch: opts.directLaunch === true,
                    appCollectorGame: opts.appCollectorGame === true,
                    lastPlayed: opts.lastPlayed !== undefined ? opts.lastPlayed
                                                              : new Date(0)
                }
            }

            if (fakeGames === "none") {
                // Proves the empty-library placeholder.
                return
            }
            if (fakeGames === "one") {
                // Proves a single-item grid -- no partial-row arithmetic to get
                // wrong, but still has to be legible on its own.
                append(game("Portal 2", { lastPlayed: daysAgo(2) }))
                return
            }
            if (fakeGames === "partial") {
                // 7 games: one full row of 5 plus a partial row of 2, proving
                // the last-row arithmetic lands where the mockup says it should.
                append(game("Portal 2", { lastPlayed: daysAgo(1) }))
                append(game("Half-Life: Alyx", { lastPlayed: daysAgo(2) }))
                append(game("Stardew Valley", { lastPlayed: daysAgo(3) }))
                append(game("Celeste"))
                append(game("Hades", { lastPlayed: daysAgo(4) }))
                append(game("Hollow Knight"))
                append(game("Outer Wilds", { lastPlayed: daysAgo(5) }))
                return
            }
            if (fakeGames === "many") {
                // 23 games: more than one screen of scrolling, with a partial
                // final row (23 = 4 full rows of 5 + a row of 3).
                var manyNames = [
                    "Portal 2", "Half-Life: Alyx", "Stardew Valley", "Celeste",
                    "Hades", "Hollow Knight", "Outer Wilds", "Disco Elysium",
                    "Return of the Obra Dinn", "Slay the Spire", "Inscryption",
                    "Baba Is You", "Katana Zero", "Dead Cells", "Subnautica",
                    "Cuphead", "Undertale", "Cave Story+", "Papers, Please",
                    "Spelunky 2", "Superliminal", "Risk of Rain 2", "Terraria"
                ]
                for (var i = 0; i < manyNames.length; i++) {
                    append(game(manyNames[i], { lastPlayed: (i % 3 === 0) ? daysAgo(i) : undefined }))
                }
                return
            }
            // "mixed" is the default for anything else, including a value that
            // doesn't match a known preset name. About 12 games covering, in
            // one list: a running game, a very long title, and a mix of
            // last-played dates and never-played games. Whether artwork shows
            // depends only on MOONLIGHT_FAKE_GAMES_ART (see art() above) -- with
            // it unset, this preset also covers "no artwork at all" for every
            // row, which is the common review case.
            append(game("Portal 2", { running: true, lastPlayed: daysAgo(0) }))
            append(game("Half-Life: Alyx", { lastPlayed: daysAgo(1) }))
            // At least 45 characters, to prove a long title does not break the
            // tile or the grid.
            append(game("The Witcher 3: Wild Hunt Complete Edition Extended Cut", { lastPlayed: daysAgo(3) }))
            append(game("Stardew Valley", { lastPlayed: daysAgo(7) }))
            append(game("Hades"))
            append(game("Celeste", { lastPlayed: daysAgo(14) }))
            append(game("Hollow Knight"))
            append(game("Outer Wilds", { lastPlayed: daysAgo(30) }))
            append(game("Disco Elysium"))
            append(game("Return of the Obra Dinn", { lastPlayed: daysAgo(60) }))
            append(game("Slay the Spire"))
            append(game("Inscryption", { lastPlayed: daysAgo(2) }))
        }
    }

    // Null in review mode, deliberately. AppModel::initialize() asserts that
    // computerIndex is inside the real computer list, and the only way to reach
    // this screen without a real paired host is MOONLIGHT_INITIAL_VIEW, which
    // leaves computerIndex at its default 0. On a machine with no paired hosts
    // that assert fires and takes the app down before the screen draws -- so the
    // review path could not review anything. Nothing else here touches appModel
    // without checking it first.
    function createModel() {
        if (useFakeGames) {
            return null
        }
        var model = Qt.createQmlObject('import AppModel 1.0; AppModel {}', parent, '')
        model.initialize(ComputerManager, computerIndex, showHiddenGames)
        return model
    }

    // When a game was last played, in milliseconds, or 0 for never.
    //
    // One reader for two representations of "never", because the screen is fed
    // by two different models: the real AppModel returns an invalid QDateTime,
    // which is a Date with a NaN time, and the review ListModel uses the epoch
    // (see fakeModel above for why it cannot use undefined). Both flatten to 0
    // here so nothing downstream has to know which model it is looking at.
    // The Recent ordering below is built on this.
    function playedAt(value) {
        if (!value || typeof value.getTime !== "function") {
            return 0
        }
        var t = value.getTime()
        return isNaN(t) ? 0 : Math.max(t, 0)
    }

    // A relative last-played line for a Recent neighbour tile, or "" for a
    // game that has never been played -- which must show no second line at
    // all, not invented copy (client decision, TASK-BRIEF.md #1).
    //
    // Qt.formatDate/Qt.locale() rather than hand-rolled day names, per the
    // brief. "Today" is not in the brief's own list (Yesterday / weekday /
    // short date) -- it only describes neighbour tiles, and the one game
    // played today is normally also the running game, which takes the
    // Running/tagline treatment instead of a date line. It is filled in here
    // as the only sane reading for a same-day, non-running play; a judgement
    // call, noted in the stage 3 report.
    function relativePlayed(value) {
        var t = root.playedAt(value)
        if (t === 0) {
            return ""
        }
        var played = new Date(t)
        var now = new Date()
        var startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        var startOfPlayed = new Date(played.getFullYear(), played.getMonth(), played.getDate())
        var diffDays = Math.round((startOfToday - startOfPlayed) / 86400000)
        if (diffDays <= 0) {
            return qsTr("Today")
        }
        if (diffDays === 1) {
            return qsTr("Yesterday")
        }
        if (diffDays < 7) {
            return Qt.locale().dayName(played.getDay(), Locale.LongFormat)
        }
        return Qt.formatDate(played, "d MMM")
    }

    function computerLost() {
        // Go back to the host carousel on PC loss, exactly as upstream did.
        stackView.pop()
    }

    // --- model mirror ----------------------------------------------------------
    // Invisible mirror of gameModel, the same pattern HostCarousel.qml's
    // `counter` Repeater uses. It does three jobs.
    //
    // First, it reads `running`/`name`/`lastPlayed` by role NAME rather than by
    // role number, which is the reason that pattern exists at all -- role
    // numbers are an offset from Qt::UserRole and would break silently if
    // anyone reordered the enum in appmodel.h.
    //
    // Second, it is where the row count comes from. `gameModel.count` cannot be
    // used: AppModel is a QAbstractListModel and has no `count` property in QML,
    // so that expression is undefined against the real model and the grid would
    // draw nothing while reporting itself empty. Only the fake ListModel would
    // have answered. A Repeater over the same model counts both.
    //
    // Third, it is where the Recent ordering is computed FROM -- see
    // recomputeRecentOrder() below. Ordering is deliberately done here in QML
    // against role names, not in C++ and not via a proxy model: the review hook
    // substitutes a plain ListModel, and a C++ ordering could not serve it.
    readonly property int gameCount: modelMirror.count

    property bool anyGameRunning: false
    property string runningGameName: ""

    function recomputeRunning() {
        for (var i = 0; i < modelMirror.count; i++) {
            var it = modelMirror.itemAt(i)
            if (it && it.isRunning) {
                root.anyGameRunning = true
                root.runningGameName = it.gameName
                return
            }
        }
        root.anyGameRunning = false
        root.runningGameName = ""
    }

    // Recent's ordering: most recently played first, then alphabetically.
    // Never-played games sort after every played game and alphabetically among
    // themselves -- both fall out of one comparator, since "never" flattens to
    // 0 via playedAt() and a descending sort on that puts every 0 last.
    //
    // recentOrder is the array of SOURCE indices in display order.
    // recentRankBySourceIndex is its reverse map, so a Repeater delegate that
    // knows only its own source row (as the Library grid's already does) can
    // find its own position in the Recent row without a second Repeater over a
    // plain JS array -- which would need its own way to read model data back
    // out, and AppModel has no invokable get() the way ListModel does.
    property var recentOrder: []
    property var recentRankBySourceIndex: ({})

    function recomputeRecentOrder() {
        var order = []
        for (var i = 0; i < modelMirror.count; i++) {
            order.push(i)
        }
        order.sort(function(a, b) {
            var ia = modelMirror.itemAt(a)
            var ib = modelMirror.itemAt(b)
            var pa = ia ? root.playedAt(ia.lastPlayedValue) : 0
            var pb = ib ? root.playedAt(ib.lastPlayedValue) : 0
            if (pa !== pb) {
                return pb - pa
            }
            var na = (ia ? ia.gameName : "").toLowerCase()
            var nb = (ib ? ib.gameName : "").toLowerCase()
            if (na < nb) return -1
            if (na > nb) return 1
            return 0
        })
        root.recentOrder = order
        var rank = {}
        for (var r = 0; r < order.length; r++) {
            rank[order[r]] = r
        }
        root.recentRankBySourceIndex = rank
        root.clampRecentIndex()
    }

    Item {
        visible: false
        Repeater {
            id: modelMirror
            model: root.gameModel
            delegate: Item {
                readonly property bool isRunning: model.running
                readonly property string gameName: model.name
                readonly property var lastPlayedValue: model.lastPlayed
                // Read here too, so the options popup's snapshot comes from the
                // same by-role-name mirror as everything else rather than a
                // second path into the model.
                readonly property bool isHidden: model.hidden
                readonly property bool isDirectLaunch: model.directLaunch
                readonly property var appId: model.appid
                onIsRunningChanged: root.recomputeRunning()
                onLastPlayedValueChanged: root.recomputeRecentOrder()
            }
            onItemAdded: {
                root.recomputeRunning()
                root.recomputeRecentOrder()
                root.clampLibraryIndex()
                root.clampRecentIndex()
                root.ensureLibraryFocusVisible()
                // See attemptContextRestore()'s own comment: a saved game may
                // arrive in a later chunk than this screen opened with.
                root.attemptContextRestore()
            }
            onItemRemoved: {
                root.recomputeRunning()
                root.recomputeRecentOrder()
                root.clampLibraryIndex()
                root.clampRecentIndex()
                root.ensureLibraryFocusVisible()
            }
        }
    }
    Component.onCompleted: {
        recomputeRunning()
        recomputeRecentOrder()
        ensureLibraryFocusVisible()
        // Covers the case where restoreContext's game is already present at
        // construction (the fake-games list, or a real host whose app list
        // had already arrived before this screen was opened). The chunked
        // case is covered by modelMirror's onItemAdded above instead.
        attemptContextRestore()
    }

    // The host's name. Normally objectName, which HostCarousel.openAppView()
    // already sets -- no second plumbing path for the same string. In review
    // mode nothing sets it, because MOONLIGHT_INITIAL_VIEW pushes this screen
    // with no properties at all, so the header would draw a blank name and a
    // "?" disc and every screenshot would be reviewing the wrong thing.
    readonly property string hostName:
        root.objectName.length > 0 ? root.objectName
                                   : (root.useFakeGames ? "Desktop-PC" : "")

    // --- tabs --------------------------------------------------------------
    // Recent is the landing tab: TASK-BRIEF.md's decision #2 is that Recent is
    // never empty unless the library itself is, and the app always lands on
    // Recent. Each view keeps its own selection index (below) so switching
    // tabs and back returns to where you were.
    property string activeTab: "recent"

    // Ready for L1/R1 once the C++ mapping exists (see the stage 3 report --
    // sdlgamepadkeynavigation.cpp delivers no keycode at all for either
    // shoulder button right now). Nothing currently calls this.
    function switchTab(tab) {
        if (tab !== "recent" && tab !== "library") {
            return
        }
        root.activeTab = tab
    }

    // Recompute the Library's scroll the moment it becomes the visible tab.
    // ensureLibraryFocusVisible() declines to run while another tab is showing
    // -- see its comment for the defect that caused -- so arriving here is the
    // first honest opportunity to place it.
    onActiveTabChanged: {
        if (root.activeTab === "library") {
            Qt.callLater(root.ensureLibraryFocusVisible)
        }
    }

    // Which tile is focused, one index per view so a tab change does not lose
    // the other view's place.
    //
    // libraryFocusedIndex is a SOURCE row index, exactly as stage 1/2 used it.
    // recentFocusedIndex is a RANK -- a position in recentOrder -- because the
    // Recent row is ordered independently of the source model; its source row
    // is recentOrder[recentFocusedIndex].
    property int libraryFocusedIndex: 0
    property int recentFocusedIndex: 0

    function clampLibraryIndex() {
        if (root.gameCount === 0) {
            root.libraryFocusedIndex = 0
            return
        }
        if (root.libraryFocusedIndex > root.gameCount - 1) {
            root.libraryFocusedIndex = root.gameCount - 1
        } else if (root.libraryFocusedIndex < 0) {
            root.libraryFocusedIndex = 0
        }
    }

    function clampRecentIndex() {
        if (root.recentOrder.length === 0) {
            root.recentFocusedIndex = 0
            return
        }
        if (root.recentFocusedIndex > root.recentOrder.length - 1) {
            root.recentFocusedIndex = root.recentOrder.length - 1
        } else if (root.recentFocusedIndex < 0) {
            root.recentFocusedIndex = 0
        }
    }

    // The SOURCE row index of whatever is focused right now, on whichever tab
    // is active, or -1 if there is nothing to focus. Everything that acts on
    // "the focused game" -- A, X, the hint bar's Play/Resume label -- reads
    // through this rather than knowing about ranks and tabs itself.
    function currentSourceIndex() {
        if (root.activeTab === "recent") {
            if (root.recentFocusedIndex >= 0 && root.recentFocusedIndex < root.recentOrder.length) {
                return root.recentOrder[root.recentFocusedIndex]
            }
            return -1
        }
        if (root.libraryFocusedIndex >= 0 && root.libraryFocusedIndex < root.gameCount) {
            return root.libraryFocusedIndex
        }
        return -1
    }

    readonly property int currentSrcIndex: currentSourceIndex()
    readonly property bool currentIsRunning: {
        var it = root.currentSrcIndex >= 0 ? modelMirror.itemAt(root.currentSrcIndex) : null
        return it ? it.isRunning : false
    }

    function sameAppId(first, second) {
        return first !== null && first !== undefined
                && second !== null && second !== undefined
                && String(first) === String(second)
    }

    function appIdAtSourceIndex(sourceIndex) {
        if (sourceIndex < 0 || sourceIndex >= root.gameCount) {
            return null
        }
        var item = modelMirror.itemAt(sourceIndex)
        return item ? item.appId : null
    }

    // Model rows and Recent ranks can both change between input and dispatch.
    // Every delayed action re-resolves the one durable identity instead.
    function sourceIndexForAppId(appId) {
        for (var i = 0; i < modelMirror.count; i++) {
            var item = modelMirror.itemAt(i)
            if (item && root.sameAppId(item.appId, appId)) {
                return i
            }
        }
        return -1
    }

    function selectAppById(appId, origin) {
        var sourceIndex = root.sourceIndexForAppId(appId)
        if (sourceIndex < 0) {
            return false
        }
        root.selectReviewSource(sourceIndex, origin)
        return true
    }

    // What contextSaved() reports when this instance is discarded: the tab
    // showing, the currently focused game by stable id (null if nothing is
    // focused -- an empty library, say), and the Library's own scroll. Read
    // back by attemptContextRestore() below on the NEXT instance opened for
    // this host.
    function contextSnapshot() {
        return {
            activeTab: root.activeTab,
            appId: root.appIdAtSourceIndex(root.currentSourceIndex()),
            contentY: libraryFlickable.contentY
        }
    }

    // Restores whatever contextSnapshot() captured for this host last time,
    // by stable app id rather than index -- restoreAfterLaunch() below is the
    // established precedent for exactly this reasoning: the Recent order and
    // even the row count can differ from what they were when the context was
    // saved.
    //
    // The host's app list arrives in chunks (see libraryFlickable's "rows come
    // in chunks" comment), so this is called again from modelMirror's
    // onItemAdded below on every row that arrives, until the player's first
    // input retires it -- see abandonContextRestore().
    //
    // It deliberately does NOT stop at the first success, and that is the
    // whole subtlety. recentFocusedIndex is a RANK in recentOrder, not a
    // source row, and every arriving row makes onItemAdded recompute
    // recentOrder -- so a rank that pointed at the restored game one chunk ago
    // points at a different game the next. Restoring once, early, and calling
    // it done is exactly the failure restoreAfterLaunch() warns about in its
    // own comment: it looks like it worked, and then the list finishes
    // arriving and quietly moves the selection somewhere else. Re-applying the
    // saved app id on every change is what makes the restore survive the rest
    // of the list showing up.
    //
    // Re-applying is idempotent -- it selects the same game by the same stable
    // id, and writes the same saved scroll -- so the cost of doing it on every
    // row is one lookup, and the screen simply keeps showing the game you left
    // on until you touch something. It also repairs itself: the scroll clamp
    // below is bound by the rows present, so a saved position deeper than the
    // partial list allows is clamped now and re-applied in full once the
    // remaining rows have arrived.
    //
    // If the saved game never arrives at all (uninstalled on the host), this
    // simply never matches, changes nothing, and is discarded with this
    // instance.
    function attemptContextRestore() {
        if (root.restoreContext === null) {
            return
        }
        var context = root.restoreContext
        root.activeTab = context.activeTab
        if (!root.selectAppById(context.appId, context.activeTab)) {
            return
        }
        if (context.activeTab !== "library") {
            return
        }
        // selectAppById() above wrote libraryFocusedIndex synchronously (see
        // selectReviewSource()), which ran ensureLibraryFocusVisible() once
        // via onLibraryFocusedIndexChanged and started libraryScrollAnimation
        // towards ITS OWN idea of where to land. That happened earlier in this
        // same call, before a frame was drawn, so stopping the animation and
        // writing contentY outright here replaces it with the saved position
        // before anything is visible.
        //
        // Two DEFERRED calls to the same function are still queued behind this
        // one, though -- selectReviewSource() and onActiveTabChanged each add a
        // Qt.callLater -- and they run after this function returns. They do not
        // undo this: ensureLibraryFocusVisible() only moves contentY when the
        // focused row falls outside the viewport, and at the position being
        // restored here that row is inside it by construction, because this is
        // the scroll that was saved while that same game was focused. The one
        // case where they do move it is the case where they should -- the
        // library changed shape since the save and the restored scroll no
        // longer shows the game.
        //
        // Clamped because the library may be shorter now than when this was
        // saved. contentHeight is a plain binding on the row count, so it is
        // already correct for the rows present; rows arriving in a LATER chunk
        // than the saved game can still leave this clamped tighter than the
        // save intended, which is the honest limit of restoring against a list
        // that is still arriving.
        var maxY = Math.max(0, libraryFlickable.contentHeight - libraryFlickable.height)
        libraryScrollAnimation.stop()
        libraryFlickable.contentY = Math.max(0, Math.min(context.contentY, maxY))
    }

    // A pending restore belongs to ARRIVING on this screen, not to living on
    // it. modelMirror's onItemAdded retries attemptContextRestore() on every
    // row the host ever inserts, and a real host keeps inserting them long
    // after the grid has settled -- so without this, a late chunk could still
    // pull the tab or the selection out from under someone who had already
    // started moving. Worse, a saved game that has since been uninstalled
    // never matches, which leaves the tab being re-applied on every future
    // insert forever.
    //
    // Input is authoritative (creative brief §6 rule 3): a restore that
    // arrives after the player's first press is not a restore, it is the
    // screen arguing with them. Called from Keys.onPressed, which Qt emits
    // before any of the specific key handlers below, so it covers every
    // button this screen reads -- and from the Library's own drag, which is
    // the one mouse gesture that moves the same scroll this would rewrite.
    function abandonContextRestore() {
        root.restoreContext = null
    }

    function sourceTileForAppId(appId, origin) {
        var sourceIndex = root.sourceIndexForAppId(appId)
        if (sourceIndex < 0) {
            return null
        }
        if (origin === "library") {
            return libraryRepeater.itemAt(sourceIndex)
        }
        var recentSlot = recentRepeater.itemAt(sourceIndex)
        return recentSlot ? recentSlot.gameTileItem : null
    }

    function sourceSlotForAppId(appId, origin) {
        var sourceIndex = root.sourceIndexForAppId(appId)
        if (sourceIndex < 0) {
            return null
        }
        return origin === "recent" ? recentRepeater.itemAt(sourceIndex) : null
    }

    function mappedItemRect(item, target) {
        var first = item.mapToItem(target, 0, 0)
        var second = item.mapToItem(target, item.width, 0)
        var third = item.mapToItem(target, 0, item.height)
        var fourth = item.mapToItem(target, item.width, item.height)
        var left = Math.min(first.x, second.x, third.x, fourth.x)
        var right = Math.max(first.x, second.x, third.x, fourth.x)
        var top = Math.min(first.y, second.y, third.y, fourth.y)
        var bottom = Math.max(first.y, second.y, third.y, fourth.y)
        return Qt.rect(left, top, right - left, bottom - top)
    }

    function intersectRects(first, second) {
        var left = Math.max(first.x, second.x)
        var top = Math.max(first.y, second.y)
        var right = Math.min(first.x + first.width, second.x + second.width)
        var bottom = Math.min(first.y + first.height, second.y + second.height)
        return Qt.rect(left, top, Math.max(0, right - left),
                       Math.max(0, bottom - top))
    }

    function effectiveItemOpacity(item) {
        var opacity = 1
        var node = item
        while (node) {
            if (node.visible === false) {
                return 0
            }
            if (node.opacity !== undefined) {
                opacity *= node.opacity
            }
            node = node.parent
        }
        return opacity
    }

    function launchDestinationRect() {
        return Qt.rect(Bulan.launchDestinationCenterX
                       - Bulan.launchDestinationWidth / 2,
                       Bulan.launchDestinationCenterY
                       - Bulan.launchDestinationHeight / 2,
                       Bulan.launchDestinationWidth,
                       Bulan.launchDestinationHeight)
    }

    function fallbackLaunchContract(gameName) {
        var destination = root.launchDestinationRect()
        return {
            fallback: true,
            gameName: gameName,
            visibleRect: destination,
            sourceCrop: Qt.rect(0, 0, destination.width, destination.height),
            destinationCropRect: destination,
            opacity: 0
        }
    }

    function sourceContractForApp(appId, origin, sourceAvailable, gameName) {
        if (!sourceAvailable) {
            return { item: null, contract: root.fallbackLaunchContract(gameName) }
        }

        var tile = root.sourceTileForAppId(appId, origin)
        var captureItem = tile ? tile.launchCaptureItem : null
        if (!captureItem || captureItem.width <= 0 || captureItem.height <= 0) {
            return { item: null, contract: root.fallbackLaunchContract(gameName) }
        }

        var fullRect = root.mappedItemRect(captureItem, launchTransition)
        if (fullRect.width <= 0 || fullRect.height <= 0) {
            return { item: null, contract: root.fallbackLaunchContract(gameName) }
        }

        var visibleRect = root.intersectRects(
                    fullRect, Qt.rect(0, 0,
                                      launchTransition.width,
                                      launchTransition.height))
        var node = captureItem.parent
        while (node && visibleRect.width > 0 && visibleRect.height > 0) {
            if (node.clip === true) {
                visibleRect = root.intersectRects(
                            visibleRect,
                            root.mappedItemRect(node, launchTransition))
            }
            node = node.parent
        }
        if (visibleRect.width <= 0 || visibleRect.height <= 0) {
            return { item: null, contract: root.fallbackLaunchContract(gameName) }
        }

        var crop = Qt.rect(
                    (visibleRect.x - fullRect.x) * captureItem.width / fullRect.width,
                    (visibleRect.y - fullRect.y) * captureItem.height / fullRect.height,
                    visibleRect.width * captureItem.width / fullRect.width,
                    visibleRect.height * captureItem.height / fullRect.height)
        var destination = root.launchDestinationRect()
        var destinationCrop = Qt.rect(
                    destination.x + crop.x * destination.width / captureItem.width,
                    destination.y + crop.y * destination.height / captureItem.height,
                    crop.width * destination.width / captureItem.width,
                    crop.height * destination.height / captureItem.height)
        return {
            item: captureItem,
            contract: {
                fallback: false,
                gameName: gameName,
                visibleRect: visibleRect,
                sourceCrop: crop,
                destinationCropRect: destinationCrop,
                opacity: root.effectiveItemOpacity(captureItem)
            }
        }
    }

    // Ends the grid entrance (Recent and Library both) immediately: every
    // tile still mid-rise snaps straight to its resting position and
    // opacity, same "finish it now rather than fight it" shape as
    // launchTransition.completeImmediately() below. Called the moment a
    // launch is committed to, so nothing is ever captured mid-flight and
    // nothing is left stranded part-risen if the launch later rolls back
    // and returns the player to this same screen.
    function completeGridEntrance() {
        var i, item
        for (i = 0; i < recentRepeater.count; i++) {
            item = recentRepeater.itemAt(i)
            if (item && !item.entranceSettled) {
                item.completeEntrance()
            }
        }
        for (i = 0; i < libraryRepeater.count; i++) {
            item = libraryRepeater.itemAt(i)
            if (item && !item.entranceSettled) {
                item.completeEntrance()
            }
        }
    }

    function freezeLaunchSourceMotion(appId, origin) {
        libraryScrollAnimation.stop()
        libraryFlickable.cancelFlick()
        // A launch pressed while the source tile is still mid-rise (grid
        // entrance) must never freeze and capture that in-flight geometry --
        // the frozen proxy would zoom from a position and opacity the
        // player never actually saw settle. Rather than withholding the
        // capture (which would silently degrade the accepted launch
        // experience for the whole entrance window), the entrance is simply
        // over now: finish it immediately, for every tile, then capture the
        // now-settled geometry exactly as if the entrance had already
        // finished on its own.
        root.completeGridEntrance()
        root.frozenLaunchAppId = appId
        var tile = root.sourceTileForAppId(appId, origin)
        var slot = root.sourceSlotForAppId(appId, origin)
        var valid = tile && root.sameAppId(tile.appId, appId)
                && tile.launchMotionFrozen
                && (origin !== "recent" || (slot && slot.launchMotionFrozen))
        if (!valid) {
            root.frozenLaunchAppId = null
        }
        return valid
    }

    function releaseLaunchSourceMotion() {
        root.frozenLaunchAppId = null
        if (root.pendingLaunch) {
            root.pendingLaunch.sourceMotionFrozen = false
        }
    }

    // Hiding is identity state, not an imperative mutation of one delegate.
    // Both Recent and Library delegates therefore inherit it if either view is
    // rebuilt while the launch segue owns the screen.
    function setLaunchSourceHidden(appId, origin, hidden) {
        if (!hidden) {
            if (root.sameAppId(root.hiddenLaunchAppId, appId)) {
                root.hiddenLaunchAppId = null
            }
            return true
        }
        root.hiddenLaunchAppId = appId
        var tile = root.sourceTileForAppId(appId, origin)
        var valid = tile && root.sameAppId(tile.appId, appId)
                && tile.launchSourceHidden
        if (!valid) {
            root.hiddenLaunchAppId = null
        }
        return valid
    }

    // Left/Right in the Library: one continuous index across the whole model,
    // clamped only at the first and last game overall. Crossing a row
    // boundary happens as a side effect of the index being contiguous, rather
    // than being special-cased -- that is the "wrap to the next/previous row"
    // reading of the brief's judgement call, chosen because it means Left/Right
    // held down never dead-ends at a row edge the way a same-row-only clamp
    // would.
    function moveLibraryStep(step) {
        var next = root.libraryFocusedIndex + step
        if (next < 0 || next > root.gameCount - 1) {
            return
        }
        root.libraryFocusedIndex = next
    }

    // Up/Down in the Library: previous/next row, clamping. A partially filled
    // final row clamps to its last REAL tile -- never to an empty cell -- by
    // falling back to gameCount - 1 whenever a full row-step would read past
    // the end of the model.
    function moveLibraryRow(step) {
        var candidate = root.libraryFocusedIndex + step * Bulan.gameGridColumns
        if (step < 0) {
            if (candidate < 0) {
                return
            }
            root.libraryFocusedIndex = candidate
        } else {
            if (candidate > root.gameCount - 1) {
                if (root.libraryFocusedIndex === root.gameCount - 1) {
                    return
                }
                root.libraryFocusedIndex = root.gameCount - 1
            } else {
                root.libraryFocusedIndex = candidate
            }
        }
    }

    // Left/Right in Recent: previous/next by RANK, clamping at both ends --
    // matching HostCarousel.moveBy() exactly. Up/Down are inert and swallowed
    // in Recent, same as the carousel; see the Keys handlers below.
    function moveRecentBy(step) {
        var next = root.recentFocusedIndex + step
        if (next < 0 || next > root.recentOrder.length - 1) {
            return
        }
        root.recentFocusedIndex = next
    }

    // --- deterministic launch/quit review -----------------------------------
    // MOONLIGHT_GAME_REVIEW remains a single string supplied by app/main.cpp.
    // New Stage 1 cases are parsed and dispatched here, against fake games
    // only, so none of them can address a real AppModel row by accident.
    readonly property string gameReviewCase:
        typeof gameReviewAction !== "undefined"
            ? String(gameReviewAction).trim().toLowerCase() : ""

    function stageOneReviewRoute(action) {
        var route = {
            kind: "launch",
            origin: "recent",
            lowerRow: false,
            resume: false,
            launchOutcome: "start",
            sourceAvailable: true,
            repeat: false,
            switching: false,
            quitOutcome: "pending",
            returnTarget: "grid"
        }

        if (action === "launch-recent" || action === "recent-start") {
            return route
        }
        if (action === "launch-library" || action === "library-start") {
            route.origin = "library"
            return route
        }
        if (action === "launch-library-scrolled" || action === "library-scroll-start") {
            route.origin = "library"
            route.lowerRow = true
            return route
        }
        if (action === "launch-resume" || action === "recent-resume") {
            route.resume = true
            return route
        }
        if (action === "launch-warning") {
            route.launchOutcome = "warning"
            return route
        }
        if (action === "launch-failure") {
            route.launchOutcome = "failure"
            return route
        }
        if (action === "launch-valid-source" || action === "valid-source") {
            return route
        }
        if (action === "launch-no-source" || action === "no-source") {
            route.sourceAvailable = false
            return route
        }
        if (action === "launch-cycle" || action === "cycle") {
            route.repeat = true
            return route
        }
        if (action === "quit") {
            route.kind = "quit"
            route.returnTarget = "options"
            return route
        }
        if (action === "quit-switch-success" || action === "switch-success") {
            route.kind = "quit"
            route.switching = true
            route.quitOutcome = "success"
            return route
        }
        if (action === "quit-switch-launch-failure-options") {
            route.kind = "quit"
            route.switching = true
            route.quitOutcome = "success"
            route.launchOutcome = "failure"
            route.returnTarget = "options"
            return route
        }
        if (action === "quit-failure") {
            route.kind = "quit"
            route.quitOutcome = "failure"
            route.returnTarget = "options"
            return route
        }
        if (action === "quit-switch-failure-grid" || action === "switch-failure-grid") {
            route.kind = "quit"
            route.switching = true
            route.quitOutcome = "failure"
            route.returnTarget = "grid"
            return route
        }
        if (action === "quit-switch-failure-options" || action === "switch-failure-options") {
            route.kind = "quit"
            route.switching = true
            route.quitOutcome = "failure"
            route.returnTarget = "options"
            return route
        }
        return null
    }

    function setFakeRunningIndex(runningIndex) {
        for (var i = 0; i < fakeModel.count; i++) {
            fakeModel.setProperty(i, "running", i === runningIndex)
        }
        root.recomputeRunning()
    }

    function selectReviewSource(sourceIndex, origin) {
        if (sourceIndex < 0 || sourceIndex >= root.gameCount) {
            return
        }
        root.switchTab(origin)
        if (origin === "library") {
            root.libraryFocusedIndex = sourceIndex
            Qt.callLater(root.ensureLibraryFocusVisible)
            return
        }
        for (var rank = 0; rank < root.recentOrder.length; rank++) {
            if (root.recentOrder[rank] === sourceIndex) {
                root.recentFocusedIndex = rank
                return
            }
        }
    }

    function sourceForReviewRoute(route) {
        if (root.gameCount === 0) {
            return -1
        }
        if (route.switching) {
            return root.gameCount > 1 ? 1 : 0
        }
        if (route.lowerRow) {
            return root.gameCount - 1
        }
        return 0
    }

    function ensureReviewGameCount(minimum) {
        while (fakeModel.count < minimum) {
            var number = fakeModel.count + 1
            fakeModel.append({
                name: qsTr("Review game %1").arg(number),
                running: false,
                boxart: "",
                hidden: false,
                appid: 900000 + number,
                directLaunch: false,
                appCollectorGame: false,
                lastPlayed: new Date(0)
            })
        }
    }

    function beginStageOneReview(route) {
        root.pendingGameReviewRoute = route
        root.gameReviewAttempts = 0

        var minimumGameCount = route.lowerRow
                ? Bulan.gameGridColumns + 1 : (route.switching ? 2 : 1)
        root.ensureReviewGameCount(minimumGameCount)
        Qt.callLater(root.tryStageOneReview)
    }

    function tryStageOneReview() {
        var route = root.pendingGameReviewRoute
        if (route === null) {
            return
        }
        if (root.gameCount < fakeModel.count && root.gameReviewAttempts < 80) {
            root.gameReviewAttempts++
            Qt.callLater(root.tryStageOneReview)
            return
        }

        var sourceIndex = root.sourceForReviewRoute(route)

        if (route.kind === "quit") {
            root.setFakeRunningIndex(0)
        } else {
            root.setFakeRunningIndex(route.resume ? sourceIndex : -1)
        }
        root.selectReviewSource(sourceIndex, route.origin)

        // Library tab opacity and focus-follow scrolling both use
        // motionFocusMs. Let both settle before exposing the route, otherwise
        // the lower-row case would be configured but already hidden behind the
        // segue before its source tile entered the viewport.
        if (route.origin === "library") {
            root.pendingGameReviewSourceIndex = sourceIndex
            gameReviewSettleTimer.restart()
            return
        }
        root.completeStageOneReview(route, sourceIndex)
    }

    function completeStageOneReview(route, sourceIndex) {
        root.pendingGameReviewRoute = null
        root.pendingGameReviewSourceIndex = -1
        if (route.kind === "quit") {
            root.pushReviewQuit(route, sourceIndex)
        } else {
            root.beginReviewLaunch(route, sourceIndex)
        }
    }

    Timer {
        id: gameReviewSettleTimer
        interval: Bulan.motionFocusMs * 2
        onTriggered: root.completeStageOneReview(
                         root.pendingGameReviewRoute,
                         root.pendingGameReviewSourceIndex)
    }

    function pushReviewLaunch(route, sourceIndex) {
        var game = sourceIndex >= 0 && sourceIndex < fakeModel.count
                ? fakeModel.get(sourceIndex) : null
        var reviewState = {
            appId: game ? game.appid : null,
            sourceIndex: sourceIndex,
            origin: route.origin,
            sourceAvailable: route.sourceAvailable && game !== null,
            outcome: route.launchOutcome,
            resume: route.resume
        }
        var component = Qt.createComponent("StreamSegue.qml")
        if (component.status !== Component.Ready) {
            console.error("Review StreamSegue.qml failed to load:", component.errorString())
            return false
        }
        var returnsToOptions = root.pendingLaunch
                && root.pendingLaunch.preparedByQuit === true
                && route.returnTarget === "options"
        var segue = component.createObject(stackView, {
            "appName": game ? game.name : qsTr("Review game"),
            "isResume": route.resume,
            "launchArtworkUrl": root.frozenLaunchResult
                                    ? root.frozenLaunchResult.url : "",
            "launchArtworkFallback": root.frozenLaunchContract
                                         ? root.frozenLaunchContract.fallback : true,
            "launchArtworkTitle": root.frozenLaunchContract
                                      ? root.frozenLaunchContract.gameName
                                      : (game ? game.name : qsTr("Review game")),
            "reviewMode": true,
            "reviewOutcome": route.launchOutcome,
            "reviewAppId": reviewState.appId,
            "reviewSourceIndex": sourceIndex,
            "reviewOrigin": route.origin,
            "reviewSourceAvailable": reviewState.sourceAvailable,
            "reviewRepeat": route.repeat,
            "failureReturnTarget": returnsToOptions ? "options" : "grid",
            "failureReturnFn": returnsToOptions ? function() {
                root.preparedLaunchFailureDismissed()
            } : null
        })
        if (segue === null) {
            console.error("Review StreamSegue.qml loaded but could not be created")
            return false
        }
        segue.reviewCycleRequested.connect(function(cycle) {
            root.reviewLaunchCycleRequested(reviewState, cycle)
        })
        return root.pushLaunchSegue(segue, "Review StreamSegue.qml")
    }

    function pushReviewQuit(route, sourceIndex) {
        var runningGame = fakeModel.count > 0 ? fakeModel.get(0) : null
        var nextGame = route.switching && sourceIndex >= 0
                && sourceIndex < fakeModel.count ? fakeModel.get(sourceIndex) : null
        if (!runningGame) {
            return
        }

        if (route.switching && nextGame) {
            root.beginQuitAndSwitch(nextGame.appid, route.origin,
                                    nextGame.name, route.returnTarget,
                                    true, route.quitOutcome, route)
        } else {
            root.beginQuitOnly(runningGame.appid, route.origin,
                               route.returnTarget, true,
                               route.quitOutcome, route)
        }
    }

    // --- launching -------------------------------------------------------------
    property bool launchBusy: false
    property var pendingLaunch: null
    property var frozenLaunchResult: null
    property var frozenLaunchContract: null
    property bool reviewReplayActive: false
    property var hiddenLaunchAppId: null
    property var frozenLaunchAppId: null
    property int launchCaptureGeneration: 0
    property int launchWatchdogGeneration: -1
    property bool launchSeguePushCommitted: false

    // Quit preparation is distinct from launch-busy: while the next game's
    // source is being frozen/grabbed, no launch proxy is visible and no Session
    // exists yet. Once the grab is accepted, the established early Session is
    // created and both are retained here while QuitSegue owns the real wait.
    property bool quitBusy: false
    property var pendingQuit: null
    property int quitCaptureGeneration: 0
    property int quitWatchdogGeneration: -1
    property bool quitSeguePushCommitted: false
    property string pendingQuitReturnTarget: ""
    property var pendingQuitReturnAppId: null
    property string pendingQuitReturnOrigin: "recent"

    Timer {
        id: quitCaptureWatchdog
        interval: Bulan.launchCaptureWatchdogMs
        onTriggered: {
            if (root.quitBusy && root.pendingQuit
                    && root.pendingQuit.captureGeneration
                       === root.quitWatchdogGeneration) {
                root.invalidateQuitCapture()
                root.abortQuitPreparation(
                            "The next game's artwork capture timed out.")
            }
        }
    }

    Timer {
        id: launchCaptureWatchdog
        interval: Bulan.launchCaptureWatchdogMs
        onTriggered: {
            if (root.launchBusy && root.pendingLaunch
                    && root.pendingLaunch.captureGeneration
                       === root.launchWatchdogGeneration) {
                root.invalidateLaunchCapture()
                root.rollbackLaunch("The selected artwork capture timed out.")
            }
        }
    }

    function invalidateLaunchCapture() {
        launchCaptureWatchdog.stop()
        root.launchWatchdogGeneration = -1
        root.launchCaptureGeneration++
    }

    function pushLaunchSegue(segue, label) {
        root.launchSeguePushCommitted = true
        var pushed = null
        try {
            // Launch keeps its own LaunchTransition proxy motion; the stack
            // operation underneath must not gain competing motion (brief
            // decision 7, precedent StreamSegue.qml:102).
            pushed = stackView.push(segue, StackView.Immediate)
        } catch (error) {
            console.error(label + " push failed:", error)
        }
        if (pushed === null || pushed === undefined) {
            root.launchSeguePushCommitted = false
            segue.destroy()
            return false
        }
        return true
    }

    function beginReviewLaunch(route, sourceIndex) {
        var game = sourceIndex >= 0 && sourceIndex < fakeModel.count
                ? fakeModel.get(sourceIndex) : null
        if (!game) {
            return
        }
        root.beginLaunchTransition({
            appId: game.appid,
            gameName: game.name,
            origin: route.origin,
            isResume: route.resume,
            sourceAvailable: route.sourceAvailable,
            review: true,
            reviewRoute: route,
            returnTarget: "grid",
            restoreOptions: false,
            sourceHidden: false
        })
    }

    function beginLaunchTransition(request) {
        if (root.launchBusy || root.quitBusy || request === null) {
            return
        }
        var sourceIndex = root.sourceIndexForAppId(request.appId)
        if (sourceIndex < 0) {
            root.reclaimFocus()
            return
        }

        root.launchBusy = true
        root.pendingLaunch = request
        root.pendingLaunch.sourceMotionFrozen = false
        root.pendingLaunch.captureGeneration = -1
        root.frozenLaunchResult = null
        root.frozenLaunchContract = null
        root.launchSeguePushCommitted = false
        libraryScrollAnimation.stop()

        if (request.sourceAvailable
                && root.freezeLaunchSourceMotion(request.appId, request.origin)) {
            root.pendingLaunch.sourceMotionFrozen = true
        }

        var source = root.sourceContractForApp(
                    request.appId, request.origin,
                    request.sourceAvailable
                    && root.pendingLaunch.sourceMotionFrozen,
                    request.gameName)
        var contract = source.contract
        if (contract.fallback) {
            root.prepareLaunchProxy("", contract)
            return
        }

        var expectedTile = root.sourceTileForAppId(request.appId, request.origin)
        var captureItem = source.item
        if (!expectedTile || captureItem !== expectedTile.launchCaptureItem
                || !root.sameAppId(expectedTile.appId, request.appId)) {
            root.prepareLaunchProxy("", root.fallbackLaunchContract(request.gameName))
            return
        }
        var generation = ++root.launchCaptureGeneration
        root.pendingLaunch.captureGeneration = generation
        root.launchWatchdogGeneration = generation
        var captureSize = Qt.size(Math.ceil(captureItem.width),
                                  Math.ceil(captureItem.height))
        launchCaptureWatchdog.restart()
        var accepted = captureItem.grabToImage(function(result) {
            root.acceptLaunchCapture(result, contract, generation,
                                     expectedTile, request.appId)
        }, captureSize)
        if (!accepted) {
            root.invalidateLaunchCapture()
            root.rollbackLaunch("The selected artwork could not be captured.")
            return
        }
    }

    function acceptLaunchCapture(result, contract, generation,
                                 expectedTile, expectedAppId) {
        if (!root.launchBusy || root.pendingLaunch === null
                || generation !== root.launchWatchdogGeneration
                || generation !== root.pendingLaunch.captureGeneration) {
            return
        }
        root.invalidateLaunchCapture()
        if (root.sourceIndexForAppId(root.pendingLaunch.appId) < 0) {
            root.rollbackLaunch("The selected game disappeared before launch.")
            return
        }
        var currentTile = root.sourceTileForAppId(root.pendingLaunch.appId,
                                                  root.pendingLaunch.origin)
        if (!expectedTile || currentTile !== expectedTile
                || !root.sameAppId(expectedTile.appId, expectedAppId)
                || !root.sameAppId(currentTile.appId, expectedAppId)
                || !result || !result.url) {
            // A reused delegate can deliver a valid image for the wrong app.
            // Reject that texture and continue with the honest no-source card.
            root.frozenLaunchResult = null
            root.prepareLaunchProxy(
                        "", root.fallbackLaunchContract(root.pendingLaunch.gameName))
            return
        }
        root.frozenLaunchResult = result
        root.prepareLaunchProxy(result.url, contract)
    }

    function prepareLaunchProxy(captureUrl, contract) {
        root.frozenLaunchContract = contract
        launchTransition.owner = root
        launchTransition.prepare(captureUrl, contract)
    }

    function resumeHeldLaunchAfterQuit() {
        if (!root.launchBusy || root.pendingLaunch === null
                || root.pendingLaunch.heldAfterQuit !== true) {
            return
        }

        // The prepared Session still names the intended game even if a poll
        // removed its visible row while quitting. Never resolve a replacement
        // row; use the honest title-card fallback if identity is no longer in
        // the retained model.
        if (root.sourceIndexForAppId(root.pendingLaunch.appId) < 0) {
            root.frozenLaunchResult = null
            root.frozenLaunchContract = root.fallbackLaunchContract(
                        root.pendingLaunch.gameName)
        }
        if (root.frozenLaunchContract === null) {
            root.rollbackLaunch("The prepared launch source was unavailable.")
            return
        }

        root.pendingLaunch.heldAfterQuit = false
        root.prepareLaunchProxy(root.pendingLaunch.preparedCaptureUrl || "",
                                root.frozenLaunchContract)
    }

    function launchTransitionProxyReady() {
        if (!root.launchBusy || root.pendingLaunch === null) {
            launchTransition.clear()
            return
        }
        if (root.sourceIndexForAppId(root.pendingLaunch.appId) < 0
                && root.pendingLaunch.preparedByQuit !== true) {
            root.rollbackLaunch("The selected game disappeared before launch.")
            return
        }

        if (!root.frozenLaunchContract.fallback) {
            root.pendingLaunch.sourceHidden = root.setLaunchSourceHidden(
                        root.pendingLaunch.appId,
                        root.pendingLaunch.origin, true)
            if (!root.pendingLaunch.sourceHidden) {
                root.rollbackLaunch("The selected launch source could not be hidden.")
                return
            }
        }
        // Source hiding and proxy reveal are assigned in this same event-loop
        // pass, so the scene graph never receives a frame containing both.
        launchTransition.start()
        root.releaseLaunchSourceMotion()
    }

    function launchTransitionFinished() {
        if (root.reviewReplayActive) {
            root.reviewReplayActive = false
            var replayIndex = root.sourceIndexForAppId(
                        root.pendingLaunch.appId)
            if (replayIndex < 0
                    || !root.pushReviewLaunch(
                        root.pendingLaunch.reviewRoute, replayIndex)) {
                root.rollbackLaunch(
                            "The review launch screen could not be replayed.")
                return
            }
            launchTransition.clear()
            return
        }
        if (!root.launchBusy || root.pendingLaunch === null) {
            launchTransition.clear()
            return
        }

        if (root.pendingLaunch.review) {
            var reviewIndex = root.sourceIndexForAppId(root.pendingLaunch.appId)
            if (reviewIndex < 0) {
                root.rollbackLaunch("The selected review game disappeared.")
                return
            }
            if (!root.pushReviewLaunch(root.pendingLaunch.reviewRoute, reviewIndex)) {
                root.rollbackLaunch("The review launch screen could not be pushed.")
                return
            }
            launchTransition.clear()
            return
        }
        root.completeProductionLaunch()
    }

    function launchTransitionFailed() {
        if (root.reviewReplayActive) {
            root.reviewReplayActive = false
            root.rollbackLaunch("The review launch replay could not be created.")
            return
        }
        root.rollbackLaunch("The launch artwork proxy could not be created.")
    }

    function completeProductionLaunch() {
        var request = root.pendingLaunch
        var sourceIndex = request ? root.sourceIndexForAppId(request.appId) : -1
        var preparedSession = request && request.preparedSession
                ? request.preparedSession : null
        if (!request || (preparedSession === null
                         && (sourceIndex < 0 || root.appModel === null))) {
            root.rollbackLaunch("The selected game is no longer available.")
            return
        }

        var component = Qt.createComponent("StreamSegue.qml")
        if (component.status !== Component.Ready) {
            console.error("StreamSegue.qml failed to load:", component.errorString())
            root.rollbackLaunch("The launch screen could not be loaded.")
            return
        }

        // Ordinary launches construct here, after their visual handoff.
        // Quit-and-switch instead supplies the one Session constructed after
        // source capture but before quitting began; never create a second one.
        var session = preparedSession !== null
                ? preparedSession : root.appModel.createSessionForApp(sourceIndex)
        if (session === null || session === undefined) {
            root.rollbackLaunch("The streaming session could not be created.")
            return
        }
        var segue = component.createObject(stackView, {
            "appName": request.gameName,
            "session": session,
            "isResume": request.isResume,
            "launchArtworkUrl": root.frozenLaunchResult
                                    ? root.frozenLaunchResult.url : "",
            "launchArtworkFallback": root.frozenLaunchContract
                                         ? root.frozenLaunchContract.fallback : true,
            "launchArtworkTitle": root.frozenLaunchContract
                                      ? root.frozenLaunchContract.gameName
                                      : request.gameName,
            "failureReturnTarget": request.preparedByQuit === true
                                   && request.returnTarget === "options"
                                   ? "options" : "grid",
            "failureReturnFn": request.preparedByQuit === true
                               && request.returnTarget === "options"
                               ? function() {
                                   root.preparedLaunchFailureDismissed()
                               } : null
        })
        if (segue === null) {
            console.error("StreamSegue.qml loaded but could not be created")
            root.rollbackLaunch("The launch screen could not be created.")
            return
        }
        if (!root.pushLaunchSegue(segue, "StreamSegue.qml")) {
            root.rollbackLaunch("The launch screen could not be pushed.")
            return
        }
        request.preparedSession = null
        launchTransition.clear()
        // Keep the grab result alive while StreamSegue displays its memory URL.
        // restoreAfterLaunch() releases it only after the retained AppView has
        // returned and the launch surface no longer references the image.
    }

    function rollbackLaunch(reason) {
        if (reason) {
            console.error(reason)
        }
        root.invalidateLaunchCapture()
        if (root.pendingLaunch) {
            root.selectAppById(root.pendingLaunch.appId,
                               root.pendingLaunch.origin)
        }
        if (root.pendingLaunch && root.pendingLaunch.sourceHidden) {
            root.setLaunchSourceHidden(root.pendingLaunch.appId,
                                       root.pendingLaunch.origin, false)
        }
        root.hiddenLaunchAppId = null
        root.releaseLaunchSourceMotion()
        launchTransition.clear()
        root.reviewReplayActive = false
        root.launchSeguePushCommitted = false
        if (root.pendingLaunch && root.pendingLaunch.preparedSession) {
            root.pendingLaunch.preparedSession = null
            gc()
        }
        root.launchBusy = false
        root.pendingLaunch = null
        root.frozenLaunchResult = null
        root.frozenLaunchContract = null
        Qt.callLater(root.reclaimFocus)
    }

    function restoreAfterLaunch() {
        root.invalidateLaunchCapture()
        if (root.pendingLaunch) {
            // createSessionForApp() updates lastPlayed and may move this game
            // to a different Recent rank while AppView is retained underneath
            // the segue. Restore by stable identity before clearing the launch
            // request so focus returns to the game that actually launched.
            root.selectAppById(root.pendingLaunch.appId,
                               root.pendingLaunch.origin)
        }
        if (root.pendingLaunch && root.pendingLaunch.sourceHidden) {
            root.setLaunchSourceHidden(root.pendingLaunch.appId,
                                       root.pendingLaunch.origin, false)
        }
        root.hiddenLaunchAppId = null
        root.releaseLaunchSourceMotion()
        launchTransition.clear()
        root.reviewReplayActive = false
        root.launchSeguePushCommitted = false
        if (root.pendingLaunch && root.pendingLaunch.preparedSession) {
            root.pendingLaunch.preparedSession = null
            gc()
        }
        root.launchBusy = false
        root.pendingLaunch = null
        root.frozenLaunchResult = null
        root.frozenLaunchContract = null
    }

    function preparedLaunchFailureDismissed() {
        if (!root.pendingLaunch
                || root.pendingLaunch.preparedByQuit !== true
                || root.pendingLaunch.returnTarget !== "options") {
            return
        }
        root.pendingQuitReturnTarget = "options"
        root.pendingQuitReturnAppId = root.pendingLaunch.appId
        root.pendingQuitReturnOrigin = root.pendingLaunch.origin
    }

    onReviewLaunchCycleRequested: function(reviewState, cycle) {
        // Cycle 1 is the transition already played before the review segue was
        // pushed. Later cycles reuse the same frozen texture and mapped contract
        // without touching the inactive delegate or waiting on network state.
        if (cycle <= 1 || !root.launchBusy || !root.pendingLaunch
                || !root.pendingLaunch.review || root.reviewReplayActive
                || launchTransition.running || root.frozenLaunchContract === null) {
            return
        }
        root.reviewReplayActive = true
        root.setLaunchSourceHidden(root.pendingLaunch.appId,
                                   root.pendingLaunch.origin, false)
        root.pendingLaunch.sourceHidden = false
        var reviewSegue = stackView.currentItem
        if (reviewSegue && reviewSegue.reviewMode === true) {
            reviewSegue.reviewRepeat = false
        }
        root.launchSeguePushCommitted = false
        // Review replay pop, out of scope for the stack transition (brief
        // out-of-scope table); keep it free of competing motion.
        var poppedSegue = stackView.pop(StackView.Immediate)
        if (poppedSegue === null || poppedSegue === undefined) {
            root.reviewReplayActive = false
            root.rollbackLaunch("The review launch screen could not be popped for replay.")
            return
        }
        Qt.callLater(function() {
            if (!root.reviewReplayActive || !root.launchBusy
                    || root.pendingLaunch === null) {
                return
            }
            launchTransition.owner = root
            launchTransition.prepare(root.frozenLaunchResult
                                     ? root.frozenLaunchResult.url : "",
                                     root.frozenLaunchContract)
        })
    }

    // The one real-action entry point for "launch or resume this SOURCE row",
    // shared by the A-press dispatch below and the direct-launch startup path,
    // so both go through the same review guard and the same quit-and-switch
    // redirect.
    //
    // Guarded exactly the way HostCarousel.actConfirm() guards its own
    // real-action path: a fake row's index names a real machine (there, a real
    // host; here, a real app) at the same position in the real list, and
    // reading past the end of that list segfaulted the app once already. This
    // never reaches createSessionForApp() in review mode.
    function actConfirmApp(appId, origin, returnTarget) {
        if (root.useFakeGames) {
            console.log("Review mode: launching does nothing on a fake game row.")
            return
        }
        if (root.launchBusy || root.quitBusy) {
            return
        }
        var srcIndex = root.sourceIndexForAppId(appId)
        if (srcIndex < 0) {
            return
        }
        var it = modelMirror.itemAt(srcIndex)
        if (!it) {
            return
        }
        if (root.anyGameRunning && !it.isRunning) {
            // A different game is running than the one focused. Do not launch
            // -- emit the signal the quit-and-switch confirmation is wired to
            // instead.
            root.switchGameRequested(appId, origin,
                                     root.runningGameName, it.gameName,
                                     returnTarget === "options" ? "options" : "grid")
            return
        }
        root.beginLaunchTransition({
            appId: appId,
            gameName: it.gameName,
            origin: origin,
            isResume: it.isRunning,
            sourceAvailable: true,
            review: false,
            reviewRoute: null,
            returnTarget: returnTarget === "options" ? "options" : "grid",
            restoreOptions: false,
            sourceHidden: false
        })
    }

    function actConfirmOn(srcIndex) {
        var appId = root.appIdAtSourceIndex(srcIndex)
        if (appId === null || appId === undefined) {
            return
        }
        root.selectAppById(appId, root.activeTab)
        root.actConfirmApp(appId, root.activeTab)
    }

    function actConfirm() {
        var sourceIndex = root.currentSourceIndex()
        var appId = root.appIdAtSourceIndex(sourceIndex)
        if (appId !== null && appId !== undefined) {
            root.actConfirmApp(appId, root.activeTab)
        }
    }

    // True once this screen has tried the upstream direct-launch behaviour, so
    // it is attempted exactly once per activation of this screen rather than
    // looping every time StackView.onActivated fires again (e.g. on return
    // from a stream). Follows upstream's own `showGames` guard, renamed for
    // what it actually tracks here.
    property bool directLaunchAttempted: false
    property var pendingDirectLaunchAppId: null
    property string pendingDirectLaunchOrigin: "recent"

    Timer {
        id: directLaunchSettleTimer
        interval: Bulan.motionFocusMs
        onTriggered: {
            var appId = root.pendingDirectLaunchAppId
            var origin = root.pendingDirectLaunchOrigin
            root.pendingDirectLaunchAppId = null
            if (root.sourceIndexForAppId(appId) < 0
                    || !root.selectAppById(appId, origin)) {
                return
            }
            root.actConfirmApp(appId, origin)
        }
    }

    function settleDirectLaunch(appId, origin) {
        if (root.sourceIndexForAppId(appId) < 0
                || !root.selectAppById(appId, origin)) {
            return
        }
        root.pendingDirectLaunchAppId = appId
        root.pendingDirectLaunchOrigin = origin
        directLaunchSettleTimer.restart()
    }

    // STAGE 3: restores the direct-launch behaviour removed in stage 1.
    // Upstream auto-launched a direct-launch app whenever the host was opened
    // without showHiddenGames and no game was already showing
    // (model.getDirectLaunchAppIndex(), then launchOrResumeSelectedApp()).
    // Reproduced here through actConfirmOn() -- the same dispatch a real A
    // press uses -- so a direct-launch app that is already running resumes
    // rather than relaunching, and a direct-launch app while a DIFFERENT game
    // is running correctly asks via switchGameRequested() instead of forcing
    // a launch.
    function attemptDirectLaunch() {
        if (root.useFakeGames || root.showHiddenGames || root.directLaunchAttempted) {
            return
        }
        root.directLaunchAttempted = true
        if (root.appModel === null) {
            return
        }
        var directIndex = root.appModel.getDirectLaunchAppIndex()
        if (directIndex < 0) {
            return
        }
        // The model row is consumed synchronously. Only durable identity and
        // origin cross the deferred selection/settle boundary.
        var directAppId = root.appIdAtSourceIndex(directIndex)
        var directOrigin = root.activeTab
        if (directAppId === null || directAppId === undefined) {
            return
        }
        Qt.callLater(function() {
            root.settleDirectLaunch(directAppId, directOrigin)
        })
    }

    // --- lifecycle -----------------------------------------------------------
    StackView.onActivated: {
        // This is a Bulan screen now; the stock toolbar upstream's AppView kept
        // is gone, replaced by this screen's own header and hint bar.
        toolBar.visible = false

        // A successful launch retains this AppView under the segue. Returning
        // restores the exact source tile, tab selections, and Library contentY
        // already owned by this instance; no view is recreated.
        if (root.launchBusy && root.pendingLaunch !== null
                && !root.reviewReplayActive) {
            if (root.pendingLaunch.heldAfterQuit === true) {
                Qt.callLater(root.resumeHeldLaunchAfterQuit)
            } else {
                root.restoreAfterLaunch()
            }
        }

        // Null in review mode -- see createModel().
        if (appModel !== null) {
            appModel.computerLost.connect(computerLost)
        }

        root.forceActiveFocus()
        root.attemptDirectLaunch()

        if (root.pendingQuitReturnTarget === "options") {
            Qt.callLater(root.restorePendingQuitReturn)
        } else {
            root.pendingQuitReturnTarget = ""
            root.pendingQuitReturnAppId = null
        }

        // Review hook: existing options/switch/library cases plus Stage 1's
        // deterministic launch and quit cases. Fake actions run once per launch
        // rather than on every return to this screen --
        // reopening the popup each time the player backs out of it would make
        // B useless, the same rule MOONLIGHT_OPEN_APPS_FOR_HOST follows.
        // "library" is the one review action that applies to a REAL host too:
        // it only changes which tab is showing, and switching tabs is not a
        // real action on a real machine. It exists because the screenshot hook
        // grabs on a timer and cannot press R1, so without it the Library tab
        // could never be photographed against real box art.
        if (root.gameReviewCase === "library") {
            root.switchTab("library")
        }

        var stageOneRoute = root.stageOneReviewRoute(root.gameReviewCase)
        if (root.useFakeGames && !root.gameReviewOpened && stageOneRoute !== null) {
            root.gameReviewOpened = true
            root.beginStageOneReview(stageOneRoute)
        }

        if (root.useFakeGames && !root.gameReviewOpened &&
                (root.gameReviewCase === "options" || root.gameReviewCase === "switch")) {
            root.gameReviewOpened = true
            Qt.callLater(function() {
                var srcIndex = root.currentSourceIndex()
                if (srcIndex < 0) {
                    return
                }
                if (root.gameReviewCase === "switch") {
                    // The switch confirmation only makes sense on a game that
                    // is NOT the running one -- actConfirmOn() will only ever
                    // raise it in that case. Pointing the hook at the focused
                    // game regardless produced "Quit Portal 2? Portal 2 is
                    // still running. Quitting it starts Portal 2", which is the
                    // hook reviewing a state the app cannot reach. Pick a game
                    // that makes the question real.
                    for (var i = 0; i < root.gameCount; i++) {
                        var it = modelMirror.itemAt(i)
                        if (it && !it.isRunning) {
                            root.openSwitchConfirmation(root.appIdAtSourceIndex(i),
                                                        root.activeTab)
                            return
                        }
                    }
                    return
                }
                root.openGameOptions(root.appIdAtSourceIndex(srcIndex), root.activeTab)
            })
        }
    }

    property bool gameReviewOpened: false
    property int gameReviewAttempts: 0
    property var pendingGameReviewRoute: null
    property int pendingGameReviewSourceIndex: -1

    // Deliberately does NOT restore the toolbar -- see the matching note in
    // HostCarousel.qml. Handing upstream's toolbar back on the way out is what
    // made it flash between the host carousel and this screen.
    readonly property bool bulanScreen: true

    StackView.onDeactivating: {
        directLaunchSettleTimer.stop()
        root.pendingDirectLaunchAppId = null
        if (root.launchBusy && !root.launchSeguePushCommitted) {
            root.rollbackLaunch("Launch was interrupted by external navigation.")
        }
        if (root.quitBusy && !root.quitSeguePushCommitted) {
            root.abortQuitPreparation("Quit preparation was interrupted by external navigation.")
        }
        if (gameReviewSettleTimer.running) {
            gameReviewSettleTimer.stop()
            root.pendingGameReviewRoute = null
            root.pendingGameReviewSourceIndex = -1
        }
        if (appModel !== null) {
            appModel.computerLost.disconnect(computerLost)
        }
    }

    // HostCarousel.openAppView() creates a fresh AppView on every entry and
    // never retains one of its own -- see the file banner and BUGS.md's
    // "grows every time" defect. Without this, every carousel round trip left
    // the discarded instance parented to the StackView forever.
    //
    // This does NOT fire during a launch or a quit: pushLaunchSegue() and
    // pushPreparedQuitSegue() both call stackView.push(segue, ...) to put
    // StreamSegue/QuitSegue on TOP of this screen without ever popping it, so
    // this screen stays in the stack -- just not the current item -- for
    // exactly as long as the retained-grid contract requires. StackView.onRemoved
    // only fires when THIS item itself leaves the stack, which is not what
    // pushing something above it does, so restoreAfterLaunch() and
    // resumeHeldLaunchAfterQuit() still find the same live instance they
    // always did.
    //
    // Publish this host's context before destroying, so the next fresh
    // instance opened for the same host can restore it -- see
    // contextSnapshot()/attemptContextRestore() above. Skipped only in review
    // mode with no host at all (hostUuid left at its default ""), where there
    // is nothing to key a saved context by.
    StackView.onRemoved: {
        if (root.hostUuid.length > 0) {
            root.contextSaved(root.hostUuid, root.contextSnapshot())
        }
        destroy()
    }

    // Focus recovery, copied from HostCarousel.qml's own pattern and reasoning.
    //
    // A FocusScope reports activeFocus while anything inside it holds focus, so
    // this going false means focus left the screen entirely -- which happens
    // when a popup elsewhere in the window is torn down and restores focus to
    // a control that no longer exists. Nothing is then listening for A, and A
    // is the only button with no window-level shortcut standing behind it, so
    // it alone goes dead and stays dead.
    //
    // Deliberately reactive rather than ordered, for the same reason
    // HostCarousel's version is: claiming focus once in onActivated loses any
    // race against a popup that tears down afterwards. callLater defers to the
    // end of the current pass so this does not fight something mid-teardown.
    //
    onActiveFocusChanged: {
        if (!root.launchBusy && !root.quitBusy && !activeFocus
                && StackView.status === StackView.Active) {
            Qt.callLater(reclaimFocus)
        }
    }

    // Guarded on the options popup being closed rather than on activeFocus,
    // for the reason HostCarousel's version spells out: the popup is a CHILD
    // of this scope, so while it holds focus root.activeFocus is still true and
    // testing that would decline to act in exactly the case that needs acting
    // on -- while snatching focus back off an open popup in the case that does
    // not.
    function reclaimFocus() {
        if (root.launchBusy || root.quitBusy) {
            return
        }
        if (root.StackView.status !== StackView.Active) {
            return
        }
        if (gameOptions.visible) {
            return
        }
        root.forceActiveFocus()
    }

    // --- game actions ----------------------------------------------------------
    // What an action MEANS lives here; GameOptionsOverlay only reports which one
    // the player picked. The source row is captured when the popup opens and is
    // re-read from the mirror at activation time rather than trusted -- the app
    // list can be replaced by a poll while a menu is open, which is the same
    // identity problem HostSettingsOverlay solved by re-resolving its host.
    property var optionsAppId: null
    property string optionsOrigin: "recent"
    property string optionsReturnTarget: "grid"

    function openGameOptions(appId, origin) {
        var snap = root.gameSnapshot(appId)
        if (snap === null) {
            return
        }
        root.optionsAppId = appId
        root.optionsOrigin = origin
        root.optionsReturnTarget = "options"
        gameOptions.showForGame(snap)
    }

    function openSwitchConfirmation(appId, origin, returnTarget) {
        var snap = root.gameSnapshot(appId)
        if (snap === null) {
            return
        }
        root.optionsAppId = appId
        root.optionsOrigin = origin
        root.optionsReturnTarget = returnTarget === "options" ? "options" : "grid"
        gameOptions.showSwitchConfirmation(snap)
    }

    function gameSnapshot(appId) {
        var srcIndex = root.sourceIndexForAppId(appId)
        if (srcIndex < 0 || srcIndex >= root.gameCount) {
            return null
        }
        var it = modelMirror.itemAt(srcIndex)
        if (!it) {
            return null
        }
        return {
            appId: it.appId,
            gameName: it.gameName,
            running: it.isRunning,
            hidden: it.isHidden,
            directLaunch: it.isDirectLaunch,
            anotherRunning: root.anyGameRunning && !it.isRunning,
            runningName: root.runningGameName,
            reviewMode: root.useFakeGames
        }
    }

    function handleGameAction(actionId) {
        var srcIndex = root.sourceIndexForAppId(root.optionsAppId)
        if (srcIndex < 0 || srcIndex >= root.gameCount) {
            gameOptions.close()
            return
        }
        var it = modelMirror.itemAt(srcIndex)
        if (!it) {
            gameOptions.close()
            return
        }

        // Everything below acts on a real app addressed by its position in the
        // real list. GameOptionsOverlay already refuses in review mode and
        // never emits this signal there; this is the second guard, kept for the
        // same reason HostCarousel keeps one guard covering every branch rather
        // than one per branch.
        if (root.useFakeGames || root.appModel === null) {
            gameOptions.close()
            return
        }

        if (actionId === "toggleHidden") {
            root.appModel.setAppHidden(srcIndex, !it.isHidden)
            gameOptions.close()
        } else if (actionId === "toggleDirectLaunch") {
            root.appModel.setAppDirectLaunch(srcIndex, !it.isDirectLaunch)
            gameOptions.close()
        } else if (actionId === "play" || actionId === "resume") {
            // Close before the shared transition takes focus, while retaining
            // stable identity and the tab that owns the rendered source. The
            // app is re-resolved again inside actConfirmApp(), so a model update
            // during the popup delay cannot redirect the launch.
            var launchAppId = root.optionsAppId
            var launchOrigin = root.optionsOrigin
            gameOptions.close()
            if (root.selectAppById(launchAppId, launchOrigin)) {
                Qt.callLater(function() {
                    root.actConfirmApp(launchAppId, launchOrigin, "options")
                })
            }
        } else if (actionId === "quitGame") {
            gameOptions.close()
            root.beginQuitOnly(root.optionsAppId, root.optionsOrigin,
                               "options", false, "pending", null)
        } else if (actionId === "quitAndSwitch") {
            var switchAppId = root.optionsAppId
            var switchOrigin = root.optionsOrigin
            var switchName = it.gameName
            var switchReturnTarget = root.optionsReturnTarget
            gameOptions.close()
            root.beginQuitAndSwitch(switchAppId, switchOrigin,
                                    switchName, switchReturnTarget,
                                    false, "pending", null)
        }
    }

    function invalidateQuitCapture() {
        quitCaptureWatchdog.stop()
        root.quitWatchdogGeneration = -1
        root.quitCaptureGeneration++
    }

    function rememberQuitReturn(request) {
        if (!request || request.returnTarget !== "options") {
            root.pendingQuitReturnTarget = ""
            root.pendingQuitReturnAppId = null
            return
        }
        root.pendingQuitReturnTarget = "options"
        root.pendingQuitReturnAppId = request.returnAppId
        root.pendingQuitReturnOrigin = request.returnOrigin
    }

    function restorePendingQuitReturn() {
        if (root.pendingQuitReturnTarget !== "options"
                || root.StackView.status !== StackView.Active) {
            return
        }
        var returnAppId = root.pendingQuitReturnAppId
        var returnOrigin = root.pendingQuitReturnOrigin
        root.pendingQuitReturnTarget = ""
        root.pendingQuitReturnAppId = null
        if (root.selectAppById(returnAppId, returnOrigin)) {
            root.openGameOptions(returnAppId, returnOrigin)
        }
    }

    function abortQuitPreparation(reason, restoreOrigin) {
        if (reason) {
            console.error(reason)
        }
        var request = root.pendingQuit
        root.invalidateQuitCapture()
        root.releaseLaunchSourceMotion()
        if (restoreOrigin !== false) {
            root.rememberQuitReturn(request)
        }
        if (request && request.preparedSession) {
            request.preparedSession = null
            gc()
        }
        root.pendingQuit = null
        root.quitSeguePushCommitted = false
        root.quitBusy = false
        Qt.callLater(function() {
            root.restorePendingQuitReturn()
            root.reclaimFocus()
        })
    }

    function beginQuitOnly(appId, origin, returnTarget,
                           review, reviewOutcome, reviewRoute) {
        if (root.launchBusy || root.quitBusy) {
            return
        }
        var snapshot = root.gameSnapshot(appId)
        if (snapshot === null || (!review && root.appModel === null)) {
            root.reclaimFocus()
            return
        }

        root.quitBusy = true
        root.quitSeguePushCommitted = false
        root.pendingQuit = {
            switching: false,
            appName: snapshot.gameName,
            returnTarget: returnTarget === "options" ? "options" : "grid",
            returnAppId: appId,
            returnOrigin: origin,
            review: review === true,
            reviewOutcome: reviewOutcome,
            reviewRoute: reviewRoute,
            preparedSession: null,
            captureGeneration: -1
        }
        root.pushPreparedQuitSegue()
    }

    function beginQuitAndSwitch(appId, origin, nextName, returnTarget,
                                review, reviewOutcome, reviewRoute) {
        if (root.launchBusy || root.quitBusy) {
            return
        }
        var sourceIndex = root.sourceIndexForAppId(appId)
        if (sourceIndex < 0 || (!review && root.appModel === null)) {
            root.reclaimFocus()
            return
        }
        var item = modelMirror.itemAt(sourceIndex)
        if (!item || !root.sameAppId(item.appId, appId)) {
            root.reclaimFocus()
            return
        }

        root.selectAppById(appId, origin)
        root.quitBusy = true
        root.quitSeguePushCommitted = false
        root.pendingQuit = {
            switching: true,
            appId: appId,
            gameName: nextName || item.gameName,
            appName: root.runningGameName,
            origin: origin,
            returnTarget: returnTarget === "options" ? "options" : "grid",
            returnAppId: appId,
            returnOrigin: origin,
            review: review === true,
            reviewOutcome: reviewOutcome,
            reviewRoute: reviewRoute,
            sourceAvailable: !reviewRoute || reviewRoute.sourceAvailable !== false,
            sourceIndexAtCapture: sourceIndex,
            sourceItemAtCapture: null,
            captureResult: null,
            captureUrl: "",
            captureContract: null,
            preparedSession: null,
            captureGeneration: -1
        }

        var sourceMotionFrozen = root.pendingQuit.sourceAvailable
                && root.freezeLaunchSourceMotion(appId, origin)
        var source = root.sourceContractForApp(
                    appId, origin, sourceMotionFrozen, root.pendingQuit.gameName)
        root.pendingQuit.captureContract = source.contract

        if (source.contract.fallback) {
            root.releaseLaunchSourceMotion()
            root.finishQuitSwitchCapture(null, source.contract)
            return
        }

        var expectedTile = root.sourceTileForAppId(appId, origin)
        var captureItem = source.item
        if (!expectedTile || captureItem !== expectedTile.launchCaptureItem
                || !root.sameAppId(expectedTile.appId, appId)) {
            root.releaseLaunchSourceMotion()
            root.finishQuitSwitchCapture(
                        null, root.fallbackLaunchContract(root.pendingQuit.gameName))
            return
        }

        root.pendingQuit.sourceItemAtCapture = captureItem
        var generation = ++root.quitCaptureGeneration
        root.pendingQuit.captureGeneration = generation
        root.quitWatchdogGeneration = generation
        var captureSize = Qt.size(Math.ceil(captureItem.width),
                                  Math.ceil(captureItem.height))
        quitCaptureWatchdog.restart()
        var accepted = captureItem.grabToImage(function(result) {
            root.acceptQuitSwitchCapture(result, source.contract, generation,
                                         expectedTile, appId)
        }, captureSize)
        if (!accepted) {
            root.invalidateQuitCapture()
            root.abortQuitPreparation(
                        "The next game's artwork could not be captured.")
        }
    }

    function acceptQuitSwitchCapture(result, contract, generation,
                                     expectedTile, expectedAppId) {
        if (!root.quitBusy || root.pendingQuit === null
                || generation !== root.quitWatchdogGeneration
                || generation !== root.pendingQuit.captureGeneration) {
            return
        }
        root.invalidateQuitCapture()

        // Re-resolve by app ID after the asynchronous grab. A delegate reused
        // for another row is never accepted as the intended game.
        var sourceIndex = root.sourceIndexForAppId(expectedAppId)
        if (sourceIndex < 0) {
            root.abortQuitPreparation(
                        "The next game disappeared before quit preparation completed.")
            return
        }
        var currentTile = root.sourceTileForAppId(expectedAppId,
                                                  root.pendingQuit.origin)
        if (!expectedTile || currentTile !== expectedTile
                || !root.sameAppId(expectedTile.appId, expectedAppId)
                || !root.sameAppId(currentTile.appId, expectedAppId)
                || !result || !result.url) {
            root.releaseLaunchSourceMotion()
            root.pendingQuit.sourceItemAtCapture = null
            root.finishQuitSwitchCapture(
                        null, root.fallbackLaunchContract(root.pendingQuit.gameName))
            return
        }

        root.releaseLaunchSourceMotion()
        root.pendingQuit.sourceItemAtCapture = null
        root.finishQuitSwitchCapture(result, contract)
    }

    function finishQuitSwitchCapture(result, contract) {
        if (!root.quitBusy || root.pendingQuit === null) {
            return
        }
        var request = root.pendingQuit
        var sourceIndex = root.sourceIndexForAppId(request.appId)
        if (sourceIndex < 0) {
            root.abortQuitPreparation(
                        "The next game is no longer available for quit-and-switch.")
            return
        }
        request.captureResult = result
        request.captureUrl = result && result.url ? String(result.url) : ""
        request.captureContract = contract

        // This construction intentionally remains early: capture is complete,
        // then createSessionForApp() stamps lastPlayed before the quit begins.
        // The Session is only stored; QuitSegue cannot start it.
        if (!request.review) {
            request.preparedSession = root.appModel.createSessionForApp(sourceIndex)
            if (request.preparedSession === null
                    || request.preparedSession === undefined) {
                root.abortQuitPreparation(
                            "The next streaming session could not be prepared.")
                return
            }
        }
        root.pushPreparedQuitSegue()
    }

    function pushPreparedQuitSegue() {
        var request = root.pendingQuit
        if (!root.quitBusy || request === null) {
            return
        }
        var component = Qt.createComponent("QuitSegue.qml")
        if (component.status !== Component.Ready) {
            console.error("QuitSegue.qml failed to load:", component.errorString())
            root.abortQuitPreparation("The quit screen could not be loaded.")
            return
        }
        var params = {
            "appName": request.appName,
            "nextAppName": request.switching ? request.gameName : "",
            "returnTarget": request.returnTarget,
            "reviewMode": request.review,
            "reviewOutcome": request.reviewOutcome,
            "quitRunningAppFn": request.review ? null : function() {
                if (root.appModel !== null) root.appModel.quitRunningApp()
            },
            "successFn": function() { root.quitCompletedSuccessfully() },
            "failureReturnFn": function() { root.quitFailureDismissed() }
        }
        var segue = component.createObject(stackView, params)
        if (segue === null) {
            console.error("QuitSegue.qml loaded but could not be created")
            root.abortQuitPreparation("The quit screen could not be created.")
            return
        }
        root.quitSeguePushCommitted = true
        var pushed = null
        try {
            // Quit keeps the accepted quit experience free of competing
            // stack motion (brief decision 7).
            pushed = stackView.push(segue, StackView.Immediate)
        } catch (error) {
            console.error("QuitSegue.qml push failed:", error)
        }
        if (pushed === null || pushed === undefined) {
            root.quitSeguePushCommitted = false
            segue.destroy()
            root.abortQuitPreparation("The quit screen could not be pushed.")
        }
    }

    function quitCompletedSuccessfully() {
        var request = root.pendingQuit
        if (!root.quitBusy || request === null) {
            return
        }
        root.invalidateQuitCapture()
        root.releaseLaunchSourceMotion()
        root.quitSeguePushCommitted = false
        root.quitBusy = false

        if (!request.switching) {
            root.pendingQuit = null
            return
        }

        if (request.review) {
            root.setFakeRunningIndex(-1)
        }
        root.launchBusy = true
        root.launchSeguePushCommitted = false
        root.pendingLaunch = {
            appId: request.appId,
            gameName: request.gameName,
            origin: request.origin,
            isResume: false,
            sourceAvailable: !request.captureContract.fallback,
            review: request.review,
            reviewRoute: request.reviewRoute,
            returnTarget: request.returnTarget,
            restoreOptions: false,
            sourceHidden: false,
            sourceMotionFrozen: false,
            captureGeneration: -1,
            preparedSession: request.preparedSession,
            preparedCaptureUrl: request.captureUrl,
            preparedByQuit: true,
            heldAfterQuit: true
        }
        root.frozenLaunchResult = request.captureResult
        root.frozenLaunchContract = request.captureContract
        request.preparedSession = null
        root.pendingQuit = null
    }

    function quitFailureDismissed() {
        var request = root.pendingQuit
        if (!root.quitBusy || request === null) {
            return
        }
        root.rememberQuitReturn(request)
        root.invalidateQuitCapture()
        root.releaseLaunchSourceMotion()
        if (request.preparedSession) {
            request.preparedSession = null
            gc()
        }
        root.pendingQuit = null
        root.quitSeguePushCommitted = false
        root.quitBusy = false
    }

    onOptionsRequested: function(appId, origin) {
        root.openGameOptions(appId, origin)
    }

    onSwitchGameRequested: function(appId, origin, runningName, nextName,
                                    returnTarget) {
        root.openSwitchConfirmation(appId, origin, returnTarget)
    }

    // --- screen --------------------------------------------------------------
    Atmosphere {
        anchors.fill: parent
    }

    // --- header ----------------------------------------------------------------
    Item {
        id: header
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX
        anchors.top: parent.top
        anchors.topMargin: Bulan.layoutScreenMarginY
        height: Math.max(Bulan.gameHeaderAvatarSize, hostTextBlock.height)
        width: parent.width - 2 * Bulan.layoutScreenMarginX

        Row {
            id: headerLeft
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Bulan.spaceMd

            // The client's mockup drew a B glyph and a divider ahead of the host
            // block. Removed on their instruction, 1 August 2026: the hint bar
            // already carries B/Back, and saying it twice on one screen makes
            // the bar look like it cannot be relied on to be complete.

            // The host disc. Not HostTile -- that component is a whole
            // carousel tile with busy states and motion that do not apply
            // here -- just the same monogram idea it uses as an artwork
            // placeholder, redrawn directly.
            Rectangle {
                id: hostDisc
                anchors.verticalCenter: parent.verticalCenter
                width: Bulan.gameHeaderAvatarSize
                height: Bulan.gameHeaderAvatarSize
                radius: width / 2
                color: Bulan.bgSurface
                border.width: 1
                border.color: Bulan.hairline

                Text {
                    anchors.centerIn: parent
                    text: root.hostName.length > 0 ? root.hostName.charAt(0).toUpperCase() : "?"
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.gameHeaderAvatarSize * 0.5
                }
            }

            Column {
                id: hostTextBlock
                anchors.verticalCenter: parent.verticalCenter
                spacing: Bulan.space2xs

                // The host name comes straight off objectName, which the
                // caller (HostCarousel.openAppView()) already sets to the
                // host's name. No second plumbing path for the same string.
                Text {
                    id: hostNameText
                    text: root.hostName
                    color: Bulan.textPrimary
                    font.family: Bulan.familyDisplay
                    font.pixelSize: Bulan.sizeTitle
                }

                Text {
                    text: qsTr("Connected")
                    color: Bulan.textSecondary
                    font.family: Bulan.familyUi
                    font.pixelSize: Bulan.sizeLabel
                }
            }
        }

        // Right side: "<game> is running", vertically centred against the
        // host NAME specifically rather than the whole header block, which is
        // taller because of the "Connected" line under it.
        //
        // A plain binding rather than an anchor: hostNameText is a grandchild
        // of this Row's parent, and Qt only anchors between a parent and its
        // siblings. Anchoring across that gap logs "Cannot anchor to an item
        // that isn't a parent or sibling" and then silently does nothing.
        Row {
            anchors.right: parent.right
            y: headerLeft.y + hostTextBlock.y + hostNameText.height / 2 - height / 2
            spacing: Bulan.spaceXs
            visible: root.anyGameRunning

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Bulan.space2xs
                height: Bulan.space2xs
                radius: width / 2
                color: Bulan.statusSuccess
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("%1 is running").arg(root.runningGameName)
                color: Bulan.textSecondary
                font.family: Bulan.familyUi
                font.pixelSize: Bulan.sizeLabel
            }
        }
    }

    // --- tab strip ---------------------------------------------------------
    // Indicator only, like HintBar: no input handlers, nothing here is
    // focusable, and it declares no Keys handlers. L1/R1 switching the active
    // tab cannot be bound at all right now -- see the stage 3 report -- so
    // this remains display-only until the C++ side is changed.
    Row {
        id: tabStrip
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX
        anchors.top: header.bottom
        anchors.topMargin: Bulan.spaceXl
        spacing: Bulan.spaceLg

        ControllerGlyph {
            anchors.verticalCenter: parent.verticalCenter
            action: "l1"
            tone: "unfocused"
            glyphSize: Bulan.sizeBodyLg
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Bulan.space2xs

            Text {
                text: qsTr("Recent")
                color: root.activeTab === "recent" ? Bulan.textPrimary : Bulan.secondary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitle
            }

            Rectangle {
                width: parent.width
                height: 2
                color: Bulan.accentPrimary
                visible: root.activeTab === "recent"
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Bulan.space2xs

            Text {
                text: qsTr("Library")
                color: root.activeTab === "library" ? Bulan.textPrimary : Bulan.secondary
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitle
            }

            Rectangle {
                width: parent.width
                height: 2
                color: Bulan.accentPrimary
                visible: root.activeTab === "library"
            }
        }

        ControllerGlyph {
            anchors.verticalCenter: parent.verticalCenter
            action: "r1"
            tone: "unfocused"
            glyphSize: Bulan.sizeBodyLg
        }
    }

    // --- Recent view -----------------------------------------------------------
    // A horizontal row, focused tile centred, dimmer smaller neighbours either
    // side -- the same composition as the host carousel, and built the same
    // way: each tile's position, scale and opacity is a pure function of its
    // own distance from the selection (here, distance in RANK, via
    // recentRankBySourceIndex), not a PathView or a ListView. See
    // HostCarousel.qml's header comment for why.
    Item {
        id: recentView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabStrip.bottom
        anchors.topMargin: Bulan.spaceXl
        // The hint bar itself now lives in main.qml (see the "hint bar"
        // section below), so it can no longer be referenced by id here.
        // Bulan.targetRowHeight is not a stand-in reproducing its height --
        // it is the literal same token HintBar.qml binds its own
        // implicitHeight to (HintBar.qml:90), so this margin cannot drift
        // out of sync with the bar's actual footprint; if that token ever
        // changes, both follow it together.
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Bulan.targetRowHeight

        // Cross-fades against the Library view on a tab switch, both on
        // motionFocusMs -- NOT motionTransitionMs, which Bulan.qml reserves
        // for a full screen transition (Phase B item 4); a tab is not a
        // screen. `enabled` is discrete on the tab so a faded-but-not-yet-
        // invisible view stops taking input immediately rather than at the
        // end of the fade -- see libraryFlickable's matching split for the
        // full reasoning. Recent has no Flickable to drag, but the same split
        // keeps both views' rules identical rather than special-casing the
        // one that currently has nothing to disable.
        enabled: root.activeTab === "recent" && root.gameCount > 0
        opacity: enabled ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.InOutQuad }
        }

        // Where the focused tile's centre sits. spaceLg matches the gap the
        // Library's own Flickable uses below the tab strip, so the two views'
        // art starts at a visually consistent height.
        // Where the focused tile's centre sits. Derived from the space actually
        // available rather than measured down from the top, so the title block
        // underneath cannot be pushed through the hint bar.
        //
        // It was a fixed offset, and the running game's extra "Pick up where
        // you left off." line overran the bar's hairline -- twice, at two
        // different tile heights. Reserving the block's height and centring the
        // tile in what is left means the composition corrects itself if the
        // tile size, the type ramp or the panel ever changes, instead of
        // needing another measured constant.
        readonly property int labelReserve: Bulan.gameRecentLabelGap
                                            + Bulan.lineHeightTitleLg
                                            + Bulan.lineHeightBodyLg
        readonly property real focusCenterY: Math.max(
            Bulan.gameRecentTileHeight * Bulan.motionFocusScale / 2,
            (height - labelReserve) / 2)

        // How many neighbour slots fit on each side of the focused tile,
        // worked out from the space actually on screen rather than the fixed
        // ±2 this was copied from. That clamp is right for HostCarousel.qml,
        // where three circular host tiles is the whole design; it is wrong
        // here -- the client's instruction is that Recent shows as many
        // games as the screen width and the spacing permit.
        //
        // One slot's worth of screen half-width divided by the spread
        // between slot centres gives how many whole steps fit from the
        // centre to the edge. Floors rather than rounds, so a slot only
        // counts as visible if it genuinely fits; clamped to a minimum of 1
        // so there is always at least one neighbour each side even on a
        // narrow window.
        // A slot counts as visible only if the WHOLE tile lands inside the
        // screen margin. Dividing the bare half-width by the spread counted a
        // slot whose centre fits but whose outer half hangs over the edge, and
        // the client saw exactly that: the last game on each side sliced in
        // half by the window. A tile cut by the screen edge reads as a bug
        // rather than as "there is more this way".
        //
        // So the half-width gives up the screen margin and half a neighbour
        // before the division, and floors -- a partial step is not a slot.
        readonly property int recentVisibleRadius:
            Math.max(1, Math.floor(
                (width / 2 - Bulan.layoutScreenMarginX
                 - (Bulan.gameRecentTileWidth * Bulan.gameRecentNeighbourScale) / 2)
                / Bulan.gameRecentSpread))

        // One extra slot beyond what is visible, kept as an off-screen
        // parking slot -- see HostCarousel.qml's own `slot` comment for why:
        // a tile leaving needs somewhere to travel to and fade, rather than
        // being cut because it had nowhere further to go.
        readonly property int recentParkSlot: recentVisibleRadius + 1

        Repeater {
            id: recentRepeater
            model: root.gameModel

            delegate: Item {
                id: recentSlot
                readonly property var gameTileItem: recentGameTile
                readonly property bool launchMotionFreezeRequested:
                    root.sameAppId(model.appid, root.frozenLaunchAppId)
                property bool launchMotionFrozen: false
                property real frozenLaunchX: 0
                property real frozenLaunchY: 0
                property real frozenLaunchScale: 1
                property real frozenLaunchOpacity: 1

                function freezeLaunchMotion() {
                    if (recentSlot.launchMotionFrozen) {
                        return
                    }
                    recentSlot.frozenLaunchX = recentSlot.x
                    recentSlot.frozenLaunchY = recentSlot.y
                    recentSlot.frozenLaunchScale = recentSlot.tileScale
                    recentSlot.frozenLaunchOpacity = recentSlot.opacity
                    recentSlot.launchMotionFrozen = true
                }

                function releaseLaunchMotion() {
                    recentSlot.launchMotionFrozen = false
                }

                onLaunchMotionFreezeRequestedChanged: {
                    if (launchMotionFreezeRequested) {
                        freezeLaunchMotion()
                    } else {
                        releaseLaunchMotion()
                    }
                }

                readonly property int rank:
                    root.recentRankBySourceIndex[index] !== undefined
                        ? root.recentRankBySourceIndex[index] : index
                // Clamped to recentView.recentParkSlot either side -- computed
                // from the screen width, not the fixed ±2 this was copied
                // from. See recentView.recentVisibleRadius/recentParkSlot
                // above for why and how many that is. Beyond the park slot is
                // off-screen and invisible, which is what gives a departing
                // tile somewhere to go rather than being cut.
                readonly property int slot: {
                    var d = rank - root.recentFocusedIndex
                    var park = recentView.recentParkSlot
                    return d < -park ? -park : (d > park ? park : d)
                }
                readonly property int distance: slot < 0 ? -slot : slot
                readonly property bool isFocused: rank === root.recentFocusedIndex

                // Grid entrance (Bulan.qml "Grid entrance" tokens). Ordered
                // outward from the focused tile -- distance 0 rises first --
                // so the cascade radiates from the centre of the row, capped
                // at motionGridEntranceMaxSteps so a wide row does not take
                // longer to arrive than a narrow one. 0 while below/hidden,
                // 1 once settled; y and opacity below read this directly, in
                // the same "no Behavior on the animated-on value" shape as
                // focusAmount above.
                readonly property int entranceOrder:
                    Math.min(distance, Bulan.motionGridEntranceMaxSteps)
                property real entranceProgress: 0
                // True once this tile's own rise has finished (either by
                // playing out, or by root.completeGridEntrance() below
                // ending it early for a launch). Gates the x/y/opacity
                // Behaviors below, so the entrance itself is never
                // double-animated.
                property bool entranceSettled: false

                // Snaps straight to the resting position/opacity and stops
                // the animation below, rather than fighting it. Called from
                // root.completeGridEntrance() -- see freezeLaunchSourceMotion()
                // -- the moment a launch on ANY tile is committed to, so a
                // capture never reads in-flight geometry and no tile is ever
                // left stranded part-risen.
                function completeEntrance() {
                    recentSlot.entranceProgress = 1
                    recentSlot.entranceSettled = true
                }

                SequentialAnimation {
                    id: recentEntranceAnimation
                    running: root.gridEntranceStarted && !recentSlot.entranceSettled
                    // Animation.finished() needs a newer QtQuick minor version
                    // than this file imports; onStopped is available since
                    // QtQuick 2.0 and, since nothing here ever sets
                    // `running` false except entranceSettled becoming true
                    // (naturally, or via completeEntrance() above), is
                    // equivalent for this animation's whole lifetime.
                    onStopped: recentSlot.entranceSettled = true

                    PauseAnimation {
                        duration: recentSlot.entranceOrder
                                  * Bulan.motionGridEntranceStaggerMs
                    }
                    NumberAnimation {
                        target: recentSlot
                        property: "entranceProgress"
                        to: 1
                        duration: Bulan.motionGridEntranceRiseMs
                        // Overshoots its resting place once and settles back,
                        // rather than easing flat into it -- see
                        // Bulan.motionEntranceOvershoot. OutBack crosses the
                        // target exactly once, so this is one bounce, never
                        // two. entranceProgress therefore passes slightly
                        // above 1 mid-flight, which is what lifts y a few
                        // pixels past its rest position; opacity clamps it
                        // below so only the travel bounces, not the fade.
                        easing.type: Easing.OutBack
                        easing.overshoot: Bulan.motionEntranceOvershoot
                    }
                }
                // NOT readonly, matching HostTile's tileScale exactly (see
                // HostCarousel.qml): a Behavior has to write this to animate
                // it, and readonly would make the whole tile fail to load.
                property real tileScale:
                    launchMotionFrozen ? frozenLaunchScale
                                       : (distance === 0 ? 1.0
                                                         : Bulan.gameRecentNeighbourScale)

                // 0 while a neighbour, 1 while focused, animated below on the
                // same clock as the tile's travel -- HostCarousel.qml's
                // HostTile.focusAmount exactly. Everything that differs
                // between the neighbour and focused title presentation
                // interpolates on this instead of the title element being
                // swapped for another one; see the label block below.
                property real focusAmount: distance === 0 ? 1.0 : 0.0

                // Linear blend between two colours, copied from
                // HostTile.qml's mix() -- QML interpolates colours in
                // animations but gives no expression for it, and the title
                // needs to follow focusAmount rather than run a colour
                // animation of its own.
                function mix(a, b, f) {
                    return Qt.rgba(a.r + (b.r - a.r) * f,
                                   a.g + (b.g - a.g) * f,
                                   a.b + (b.b - a.b) * f,
                                   a.a + (b.a - a.a) * f)
                }

                width: Bulan.gameRecentTileWidth
                height: Bulan.gameRecentTileHeight

                x: launchMotionFrozen ? frozenLaunchX
                                      : recentView.width / 2 - width / 2
                                        + slot * Bulan.gameRecentSpread
                // Rises from Bulan.motionGridEntranceRise px below its
                // resting position while entranceProgress travels 0 -> 1;
                // settled (entranceProgress === 1) this is exactly the old
                // expression. Frozen takes over entirely, same as x.
                y: launchMotionFrozen ? frozenLaunchY
                                      : recentView.focusCenterY - height / 2
                                        + (1 - entranceProgress)
                                          * Bulan.motionGridEntranceRise

                z: distance === 0 ? 2 : 0
                // Every non-focused VISIBLE tile stays at the same dimmed
                // opacity the design already used (0.5) -- no per-distance
                // gradient, which is a visual decision nobody has taken.
                // "Visible" now means "within recentVisibleRadius" rather
                // than the old fixed distance === 1. Multiplied by
                // entranceProgress so the tile fades in as it rises rather
                // than appearing at full/dimmed opacity mid-flight.
                // Clamped: entranceProgress overshoots above 1 on the way in
                // (see recentEntranceAnimation), and only the rise should
                // carry that -- a tile must not flash brighter than its
                // settled opacity on arrival.
                opacity: launchMotionFrozen ? frozenLaunchOpacity
                       : (distance === 0 ? 1.0
                       : (distance <= recentView.recentVisibleRadius ? 0.5 : 0.0))
                         * Math.min(1, entranceProgress)
                visible: opacity > 0.01

                // One clock for the whole move, copying HostCarousel.qml's
                // HostTile delegate block exactly in shape: position, scale
                // and fade all run for motionFocusMs on the same curve, so a
                // tile travels, shrinks and dims as one object rather than
                // three separately-timed ones. (GameTile's own interactionScale
                // -- focus/press -- is a different property on a different
                // item, artRect inside GameTile, not this tileScale; nothing
                // here chases that, so this is not the "animating an
                // animation" fault. See the stage 4 report.)
                //
                // x/y/opacity additionally wait on entranceSettled: while
                // the tile is still rising, entranceAnimation above is
                // already driving y and opacity on its own curve, and x's
                // rank-driven slide is the exact motion the client asked to
                // suppress on entry (brief item 3, "swiping in from the
                // side"). Both stay suppressed only until this tile's own
                // rise finishes; ordinary re-ranking afterwards is
                // unchanged.
                Behavior on x {
                    enabled: recentSlot.settled && recentSlot.entranceSettled
                             && !recentSlot.launchMotionFrozen
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on y {
                    enabled: recentSlot.settled && recentSlot.entranceSettled
                             && !recentSlot.launchMotionFrozen
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on tileScale {
                    enabled: recentSlot.settled && !recentSlot.launchMotionFrozen
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on opacity {
                    enabled: recentSlot.settled && recentSlot.entranceSettled
                             && !recentSlot.launchMotionFrozen
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }
                // The ONE place focusAmount is animated. The title's pixel
                // size and colour below read this value directly, with no
                // Behavior of their own -- giving them one would be
                // animating an animation, the fault HostTile.qml's
                // interactionScale comment describes.
                Behavior on focusAmount {
                    enabled: recentSlot.settled
                    NumberAnimation {
                        duration: Bulan.motionFocusMs
                        easing.type: Easing.InOutQuad
                    }
                }

                // False until this tile has been placed once, so the first
                // frame is a position rather than a journey from wherever the
                // bindings above would otherwise animate from. Bindings are
                // evaluated before Component.onCompleted runs, so by the time
                // this flips the tile is already where it belongs. Copied
                // from HostCarousel.qml's HostTile delegate.
                property bool settled: false
                Component.onCompleted: {
                    settled = true
                    // See root.markRecentEntranceSeen()'s comment: if this
                    // game's entrance already played once in Recent during
                    // this screen instance (only possible if a delegate got
                    // recreated for it, which ordinary re-ranking never
                    // does), skip straight to settled rather than rising
                    // again.
                    if (root.markRecentEntranceSeen(model.appid)) {
                        recentSlot.entranceProgress = 1
                        recentSlot.entranceSettled = true
                    }
                    if (launchMotionFreezeRequested) {
                        freezeLaunchMotion()
                    }
                }

                // Clips away GameTile's own built-in label row (title +
                // Running), which is not used for the Recent presentation --
                // the label block below draws the Recent-specific copy
                // instead. Inset by spaceXs, following the exact reasoning
                // Library's libraryFocusInset gives: the focused tile's own
                // small internal focus pulse must not be cut by this clip.
                Item {
                    id: artClip
                    anchors.centerIn: parent
                    width: Bulan.gameRecentTileWidth + 2 * Bulan.spaceXs
                    height: Bulan.gameRecentTileHeight + 2 * Bulan.spaceXs
                    clip: true
                    scale: recentSlot.tileScale
                    transformOrigin: Item.Center

                    GameTile {
                        id: recentGameTile
                        x: Bulan.spaceXs
                        y: Bulan.spaceXs
                        appId: model.appid
                        launchSourceHidden:
                            root.sameAppId(model.appid, root.hiddenLaunchAppId)
                        launchMotionFreezeRequested:
                            root.sameAppId(model.appid, root.frozenLaunchAppId)
                        gameName: model.name
                        boxart: model.boxart
                        running: false
                        appCollectorGame: model.appCollectorGame
                        isCurrent: recentSlot.isFocused
                        tileWidth: Bulan.gameRecentTileWidth
                        tileHeight: Bulan.gameRecentTileHeight
                    }
                }

                // The label block. Positioned from the tile's own VISUAL
                // (scaled) bottom edge, not its unscaled one -- artClip
                // scales about its own centre, so a neighbour's true bottom
                // sits higher than recentSlot.height would suggest.
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: recentSlot.height * (1 + recentSlot.tileScale) / 2
                       + (recentSlot.isFocused ? Bulan.gameRecentLabelGap : Bulan.spaceMd)
                    spacing: Bulan.space2xs

                    // ONE title element, always Bulan.familyDisplay, never
                    // swapped for a second one drawn in Bulan.familyUi --
                    // HostTile.qml's labelBlock solved exactly this jarring
                    // typeface-swap-on-scroll defect already, and its own
                    // comment gives the reason: a text that grows into
                    // another cannot change typeface on the way, so the
                    // branded face wins throughout. Pixel size, colour and
                    // the bound it elides against all interpolate on
                    // recentSlot.focusAmount instead.
                    //
                    // The width bound is itself interpolated: neighbourScale
                    // of the tile width at focusAmount 0, matching what the
                    // narrower neighbour tile used to bound its own separate
                    // title to, and the full gameRecentTileWidth (256, the
                    // tile's own accepted width) at focusAmount 1 -- which is
                    // also the bound the title needs while focused, so the
                    // pair with "Running" reads as centred under the tile
                    // per the mockup rather than drifting off it.
                    Item {
                        id: titleRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Bulan.gameRecentTileWidth
                               * (Bulan.gameRecentNeighbourScale
                                  + (1 - Bulan.gameRecentNeighbourScale) * recentSlot.focusAmount)
                        height: titleText.height

                        Text {
                            id: titleText
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: model.name
                            color: recentSlot.mix(Bulan.textSecondary, Bulan.textPrimary,
                                                   recentSlot.focusAmount)
                            font.family: Bulan.familyDisplay
                            font.pixelSize: Bulan.sizeLabel
                                            + (Bulan.sizeTitleLg - Bulan.sizeLabel) * recentSlot.focusAmount
                            elide: Text.ElideRight
                        }

                        // Baseline-aligned against the title -- a Row aligns
                        // its children's TOPS, which is why "Running" used to
                        // ride high above the title's own baseline at a
                        // smaller point size. This is a sibling anchored
                        // directly to titleText's baseline instead.
                        //
                        // Positioned off titleText's actual PAINTED width,
                        // not its bound width: the title elides/centres
                        // within a fixed-width box, so "Running" has to hang
                        // off the true right-hand edge of the glyphs, not the
                        // edge of the box. Centring the pair as a whole (the
                        // old Row) shifted the title left by half of this
                        // label's width; anchoring it as a sibling like this
                        // leaves the title itself centred on the tile.
                        Text {
                            id: runningLabel
                            visible: recentSlot.isFocused && model.running
                            anchors.baseline: titleText.baseline
                            x: titleText.x + titleText.width / 2
                               + titleText.paintedWidth / 2 + Bulan.spaceXs
                            text: qsTr("Running")
                            color: Bulan.statusSuccess
                            font.family: Bulan.familyUi
                            font.pixelSize: Bulan.sizeLabel
                        }
                    }

                    Text {
                        visible: recentSlot.isFocused && model.running
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Pick up where you left off.")
                        color: Bulan.accentPrimary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                    }

                    Text {
                        id: neighbourDateText
                        readonly property string dateLabel: root.relativePlayed(model.lastPlayed)
                        visible: !recentSlot.isFocused && dateLabel.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dateLabel
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeCaption
                    }
                }
            }
        }
    }

    // --- library grid --------------------------------------------------------
    // A cell is the tile plus its label plus the gap to the next row. Kept as
    // one number so the Flickable's contentHeight and each delegate's y are
    // computed from the same arithmetic rather than two similar-looking sums
    // drifting apart.
    readonly property int libraryCellWidth: Bulan.gameTileWidth + Bulan.gameGridGap
    readonly property int libraryCellHeight: Bulan.gameTileHeight + Bulan.spaceMd
                                              + Bulan.lineHeightLabel + Bulan.gameGridGap
    readonly property int libraryRowCount: Math.ceil(root.gameCount / Bulan.gameGridColumns)

    // Breathing room inside the Flickable's clip rectangle.
    //
    // The Flickable has to clip, or a scrolled row draws over the tab strip.
    // But the focused tile scales by motionFocusScale about its own centre, so
    // it grows about 6px past its cell on every side -- and the tiles on the
    // grid's edges have their cell flush against the clip. The focus ring on
    // the first tile was drawn with its top and left edges missing: not a
    // border bug, the clip cutting the growth off.
    //
    // So the content is inset and the clip rectangle grown by the same amount,
    // which leaves the grid sitting exactly where layoutScreenMarginX puts it
    // while giving the scale somewhere to go. spaceXs is comfortably more than
    // the 5.8px the tallest tile actually needs.
    readonly property int libraryFocusInset: Bulan.spaceXs

    // Keeps the focused tile (and the room its label and focus scale need)
    // fully inside the Flickable's viewport, clamped to the content bounds.
    // Writes contentY explicitly rather than relying on any implicit
    // scroll-into-view behaviour.
    //
    // TASK-BRIEF.md records a library grid seen scrolled a row on its own,
    // once, never reproduced or diagnosed. This may well remove that --
    // writing contentY outright on every focus change leaves less room for
    // whatever unexplained write was doing it before -- but that is not the
    // same thing as a diagnosis, and it is not claimed as a fix here.
    // Animates rather than jumps, but deliberately NOT via `Behavior on
    // contentY` -- a Behavior retargets on every write to contentY, including
    // the ones the Flickable itself makes while the player is dragging or
    // flicking the view with a mouse. That would fight the drag: every pixel
    // the user drags would kick off its own eased chase back, which reads as
    // the view fighting the hand on it rather than scrolling smoothly. An
    // explicit NumberAnimation, started only from here (a focus change), never
    // runs during a drag at all -- and libraryFlickable's own
    // onDraggingChanged stops it outright the instant a drag begins, so a
    // manual drag always wins over a focus-follow scroll still in flight.
    function ensureLibraryFocusVisible() {
        if (root.launchBusy || root.quitBusy || root.gameCount === 0) {
            return
        }
        // Only while the Library is the tab on screen.
        //
        // THIS IS THE DIAGNOSIS of the grid that was seen scrolled a row on its
        // own, recorded in TASK-BRIEF.md as unreproduced. It reproduces every
        // time on the real host: the app list arrives from the machine a few
        // rows at a time, each arrival fires the Repeater's onItemAdded, and
        // each of those called this function -- while the Library was not the
        // active tab, and while contentHeight was still growing row by row. The
        // "is the focused row below the viewport" test ran against a viewport
        // that did not have its final geometry yet, computed a contentY for a
        // grid that was a third of its eventual size, and scrolled there. By
        // the time the player switched to Library the number was long stale,
        // and nothing recomputed it, so the grid sat one row down with the
        // focused tile off screen above.
        //
        // It looked intermittent because it depended on how the host's app list
        // happened to be chunked on that particular run.
        if (root.activeTab !== "library") {
            return
        }
        // Geometry not settled yet -- a zero-height viewport makes the test
        // below meaningless. onHeightChanged calls this again once it is real.
        if (libraryFlickable.height <= 0) {
            return
        }
        var row = Math.floor(root.libraryFocusedIndex / Bulan.gameGridColumns)
        var top = row * root.libraryCellHeight
        var bottom = top + root.libraryCellHeight
        var newY = libraryFlickable.contentY
        if (top < libraryFlickable.contentY) {
            newY = top
        } else if (bottom > libraryFlickable.contentY + libraryFlickable.height) {
            newY = bottom - libraryFlickable.height
        }
        var maxY = Math.max(0, libraryFlickable.contentHeight - libraryFlickable.height)
        newY = Math.max(0, Math.min(newY, maxY))
        // restart() rather than a fresh start(): a second focus change
        // arriving while the first scroll is still travelling retargets from
        // wherever contentY currently sits, rather than queueing a second
        // settle behind the first -- the same "input always interrupts"
        // requirement the Behaviors elsewhere satisfy for free.
        libraryScrollAnimation.to = newY
        libraryScrollAnimation.restart()
    }
    onLibraryFocusedIndexChanged: ensureLibraryFocusVisible()

    NumberAnimation {
        id: libraryScrollAnimation
        target: libraryFlickable
        property: "contentY"
        duration: Bulan.motionFocusMs
        easing.type: Easing.OutCubic
    }

    Flickable {
        id: libraryFlickable
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX - root.libraryFocusInset
        anchors.top: tabStrip.bottom
        anchors.topMargin: Bulan.spaceLg - root.libraryFocusInset
        // See recentView's matching comment: the hint bar now lives in
        // main.qml, so it can no longer be referenced by id, and
        // Bulan.targetRowHeight is the same token driving its actual height
        // (HintBar.qml:90), not an independent number that happens to match.
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Bulan.targetRowHeight
        width: Bulan.gameGridColumns * Bulan.gameTileWidth
               + (Bulan.gameGridColumns - 1) * Bulan.gameGridGap
               + 2 * root.libraryFocusInset
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: root.libraryRowCount * root.libraryCellHeight
                       + 2 * root.libraryFocusInset

        // Both of these are still moving while a host's app list arrives -- the
        // rows come in chunks, so contentHeight grows several times, and the
        // viewport's own height is not final on the first frame. Any scroll
        // computed against a half-built grid is wrong, so it is recomputed each
        // time either changes rather than trusted from whenever it was last
        // worked out.
        onHeightChanged: Qt.callLater(root.ensureLibraryFocusVisible)
        onContentHeightChanged: Qt.callLater(root.ensureLibraryFocusVisible)

        // `enabled` gates input (dragging) on the discrete tab, so it cuts
        // the instant the tab changes rather than waiting for the cross-fade
        // below to finish -- rule 3, input always interrupts, applied to
        // "which view owns the mouse" rather than to a single animated value.
        // `opacity`/`visible` are the animated, continue-drawing-while-fading
        // half of the same split; see the tab cross-fade comment below.
        enabled: root.activeTab === "library" && root.gameCount > 0
        opacity: enabled ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.InOutQuad }
        }

        // A manual drag always wins over a focus-follow scroll still in
        // flight -- see ensureLibraryFocusVisible()'s own comment for why
        // that scroll is a NumberAnimation rather than a Behavior in the
        // first place.
        onDraggingChanged: {
            if (dragging) {
                libraryScrollAnimation.stop()
                // A hand on the view outranks a pending restore of where the
                // view used to be -- see abandonContextRestore().
                root.abandonContextRestore()
            }
        }

        // No ScrollBar attached -- that is a stock QtQuick.Controls control and
        // forbidden here.

        // --- warm halo behind the focused tile ---------------------------------
        // One instance, moved to the focused tile rather than one per delegate,
        // following HostCarousel.qml's focusBloom Canvas closely. Placed as a
        // plain child of the Flickable, ahead of the Repeater below, so it is
        // both behind every tile in paint order and scrolled by the Flickable's
        // own content offset exactly as the tiles are -- nothing here reads
        // contentX/contentY directly.
        Canvas {
            id: focusBloom
            width: Bulan.gameTileWidth * 2.2
            height: Bulan.gameTileHeight * 2.2
            x: root.libraryFocusInset
               + (root.libraryFocusedIndex % Bulan.gameGridColumns) * root.libraryCellWidth
               + Bulan.gameTileWidth / 2 - width / 2
            y: root.libraryFocusInset
               + Math.floor(root.libraryFocusedIndex / Bulan.gameGridColumns) * root.libraryCellHeight
               + Bulan.gameTileHeight / 2 - height / 2
            visible: root.gameCount > 0

            // The halo glides to the newly focused tile rather than jumping,
            // same clock and curve as every other focus-follow motion on this
            // screen. Nothing else writes focusBloom.x/y, so this is not
            // chasing an already-moving target.
            Behavior on x {
                NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.InOutQuad }
            }
            Behavior on y {
                NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.InOutQuad }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var rx = width / 2
                var ry = height / 2
                // The tile is portrait, not square, so the halo is stretched to
                // match rather than drawn as a circle: scale the canvas, draw a
                // circle, unscale. Same stops and colour as
                // HostCarousel.qml's focusBloom.
                ctx.save()
                ctx.translate(rx, ry)
                ctx.scale(1, ry / rx)
                var g = ctx.createRadialGradient(0, 0, 0, 0, 0, rx)
                var a = Bulan.focusBloomOpacity
                g.addColorStop(0.00, Qt.rgba(1, 0.85, 0.63, a))
                g.addColorStop(0.30, Qt.rgba(1, 0.85, 0.63, a * 0.45))
                g.addColorStop(0.55, Qt.rgba(1, 0.85, 0.63, a * 0.16))
                g.addColorStop(0.78, Qt.rgba(1, 0.85, 0.63, a * 0.04))
                g.addColorStop(1.00, Qt.rgba(1, 0.85, 0.63, 0.0))
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(0, 0, rx, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }
        }

        Repeater {
            id: libraryRepeater
            model: root.gameModel

            // GameTile.qml, stage 2: artwork, crop, fallback, loading
            // cross-fade, focus ring, title and running marker. A delegate's
            // position here is still a pure function of its own index,
            // following HostCarousel.qml's principle: nothing else should be
            // able to reorder or misplace a tile.
            delegate: GameTile {
                id: tile
                readonly property int column: index % Bulan.gameGridColumns
                readonly property int row: Math.floor(index / Bulan.gameGridColumns)

                // Grid entrance -- see the matching block on the Recent
                // delegate above for the full reasoning; this is the same
                // mechanism keyed on the Library's row-major index instead
                // of Recent's distance-from-focus, so the cascade reads
                // left-to-right, top-to-bottom.
                readonly property int entranceOrder:
                    Math.min(index, Bulan.motionGridEntranceMaxSteps)
                // GameTile.qml already declares its own Component.onCompleted
                // (freeze setup), so root.markLibraryEntranceSeen() cannot be
                // called from a second onCompleted here without silently
                // overriding that one -- QML does not merge two onCompleted
                // declarations for the same object. A one-shot property
                // binding runs exactly once instead: model.appid never
                // changes after creation, so this expression has nothing
                // left to react to once it has run.
                readonly property bool entranceAlreadySeen:
                    root.markLibraryEntranceSeen(model.appid)
                property real entranceProgress: entranceAlreadySeen ? 1 : 0
                property bool entranceSettled: entranceAlreadySeen

                // See recentSlot.completeEntrance()'s matching comment.
                function completeEntrance() {
                    tile.entranceProgress = 1
                    tile.entranceSettled = true
                }

                SequentialAnimation {
                    id: libraryEntranceAnimation
                    running: root.gridEntranceStarted && !tile.entranceSettled
                    // See recentEntranceAnimation's matching comment: onStopped
                    // instead of onFinished for QtQuick 2.9 compatibility.
                    onStopped: tile.entranceSettled = true

                    PauseAnimation {
                        duration: tile.entranceOrder
                                  * Bulan.motionGridEntranceStaggerMs
                    }
                    NumberAnimation {
                        target: tile
                        property: "entranceProgress"
                        to: 1
                        duration: Bulan.motionGridEntranceRiseMs
                        // See recentEntranceAnimation's matching comment.
                        easing.type: Easing.OutBack
                        easing.overshoot: Bulan.motionEntranceOvershoot
                    }
                }

                x: root.libraryFocusInset + column * root.libraryCellWidth
                y: root.libraryFocusInset + row * root.libraryCellHeight
                   + (1 - entranceProgress) * Bulan.motionGridEntranceRise
                opacity: Math.min(1, entranceProgress)

                appId: model.appid
                launchSourceHidden:
                    root.sameAppId(model.appid, root.hiddenLaunchAppId)
                launchMotionFreezeRequested:
                    root.sameAppId(model.appid, root.frozenLaunchAppId)
                gameName: model.name
                boxart: model.boxart
                running: model.running
                appCollectorGame: model.appCollectorGame
                isCurrent: index === root.libraryFocusedIndex
            }
        }
    }

    // --- empty library ---------------------------------------------------------
    // Minimal placeholder only. TASK-BRIEF.md: the designed empty-library
    // treatment is Phase D and FLOW.md records it as unresolved flow design --
    // this is deliberately one line and nothing else. Shown regardless of
    // which tab is active: with no games at all, Recent is empty too.
    Text {
        anchors.centerIn: parent
        visible: root.gameCount === 0
        text: qsTr("No games here yet.")
        color: Bulan.textSecondary
        font.family: Bulan.familyUi
        font.pixelSize: Bulan.sizeBodyLg
    }

    // --- hint bar ------------------------------------------------------------
    // Lifted out of this screen and into main.qml as a sibling of stackView
    // (client decision, 2 August 2026 review): nothing about this bar
    // changes between the carousel and the grid except its labels, so
    // animating it along with the rest of the screen read as unrefined. A
    // child cannot opt out of its parent's stack-transition opacity, so the
    // single window-level HintBar reads these three properties off
    // whichever screen is current instead of this screen drawing its own.
    //
    // Content unchanged from the previous local instance: withholds
    // Play/Options entirely when the library is empty (nothing to act on,
    // and X would open options on nothing), reads Resume instead of Play for
    // the running game, and withholds two of the mockup's promised
    // right-hand hints because they cannot currently do anything -- see the
    // stage 3 report:
    //
    //   Switch tab (L1/R1): no keycode reaches this file at all right now.
    //   Host Settings (SELECT): this screen has no host-settings overlay.
    //
    // HintBar.qml's own comment is explicit that a hint promising an action
    // that does nothing is worse than showing fewer hints.

    // Hidden while the options popup is up, because the popup brings its own
    // bar and the two land in exactly the same place. The scrim is
    // translucent by design, so this screen's bar was reading straight
    // through it and the two sets of hints drew over each other -- "Select"
    // on top of "Play", "Close" on top of "Client Settings". Two bars also
    // contradict each other: only one of them describes what the buttons do
    // while a popup owns the input.
    readonly property bool hintBarVisible: !gameOptions.visible

    readonly property var hintLeftHints: root.gameCount > 0
        ? [
              { action: "confirm", label: root.currentIsRunning ? qsTr("Resume") : qsTr("Play"), emphasis: true },
              { action: "options", label: qsTr("Options") },
              { action: "back",    label: qsTr("Back") }
          ]
        : [
              { action: "back", label: qsTr("Back") }
          ]

    // Switch tab is back: L1/R1 now carry a keycode (Key_Context2 /
    // Key_Context3, added to sdlgamepadkeynavigation.cpp in this task), so
    // the hint is no longer promising a button that does nothing.
    //
    // Host Settings is still absent, and deliberately. The client's mockup
    // shows it on this screen, but this screen has no host-settings surface
    // and building a second one is not in this task. Advertising it would be
    // exactly the failure HintBar.qml exists to prevent. Recorded as a gap
    // in TASK-BRIEF.md rather than papered over with a dead hint.
    readonly property var hintRightHints: [
        { action: "l1",    label: qsTr("Switch tab") },
        { action: "start", label: qsTr("Client Settings") }
    ]

    // --- input ---------------------------------------------------------------
    // Following SPEC-host-carousel.md's table and HostCarousel.qml's handlers.
    function consumeLaunchInput() {
        if (!root.launchBusy && !root.quitBusy) {
            return false
        }
        if (root.launchBusy && launchTransition.running
                && launchTransition.visible) {
            launchTransition.completeImmediately()
        }
        return true
    }

    // During capture this prevents a repeated confirm from starting another
    // launch. Once the proxy is visible, any input resolves the motion to its
    // destination instead of cancelling it.
    Keys.onPressed: function(event) {
        // Qt emits this for every key before the specific handlers below, so
        // this is the one place that sees the player's first press whatever it
        // was. See abandonContextRestore().
        root.abandonContextRestore()
        if (root.consumeLaunchInput()) {
            event.accepted = true
        }
    }

    //
    // Left/Right: Library moves through the flat index (see moveLibraryStep's
    // own comment for the row-wrap judgement call); Recent moves by rank,
    // clamping at both ends.
    Keys.onLeftPressed: function(event) {
        if (!root.consumeLaunchInput()) {
            if (root.activeTab === "recent") {
                root.moveRecentBy(-1)
            } else {
                root.moveLibraryStep(-1)
            }
        }
        event.accepted = true
    }
    Keys.onRightPressed: function(event) {
        if (!root.consumeLaunchInput()) {
            if (root.activeTab === "recent") {
                root.moveRecentBy(1)
            } else {
                root.moveLibraryStep(1)
            }
        }
        event.accepted = true
    }

    // Up/Down: Library moves by row, clamping. Recent is inert and swallowed,
    // exactly as on the carousel -- accepted so it does not bubble to the
    // StackView and drag focus into chrome this screen hides.
    Keys.onUpPressed: function(event) {
        if (!root.consumeLaunchInput() && root.activeTab === "library") {
            root.moveLibraryRow(-1)
        }
        event.accepted = true
    }
    Keys.onDownPressed: function(event) {
        if (!root.consumeLaunchInput() && root.activeTab === "library") {
            root.moveLibraryRow(1)
        }
        event.accepted = true
    }

    // A. Three keycodes for one button, following HostCarousel's own comment:
    // Return and Enter are the same press on different keyboards, and Space is
    // what A becomes while the settings page's tab chain is armed elsewhere in
    // the app.
    Keys.onReturnPressed: function(event) {
        if (!root.consumeLaunchInput()) {
            root.actConfirm()
        }
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        if (!root.consumeLaunchInput()) {
            root.actConfirm()
        }
        event.accepted = true
    }
    Keys.onSpacePressed: function(event) {
        if (!root.consumeLaunchInput()) {
            root.actConfirm()
        }
        event.accepted = true
    }

    // X. Names the focused game's options; the popup itself is built and
    // wired up elsewhere.
    Keys.onMenuPressed: function(event) {
        if (!root.consumeLaunchInput()) {
            var srcIndex = root.currentSourceIndex()
            if (srcIndex >= 0) {
                root.optionsRequested(root.appIdAtSourceIndex(srcIndex), root.activeTab)
            }
        }
        event.accepted = true
    }

    // B still bubbles to main.qml normally, but cannot pop this AppView out
    // from under an in-flight capture or proxy.
    Keys.onEscapePressed: function(event) {
        event.accepted = root.consumeLaunchInput()
    }
    Keys.onBackPressed: function(event) {
        event.accepted = root.consumeLaunchInput()
    }

    // START.
    Keys.onHangupPressed: function(event) {
        if (!root.consumeLaunchInput()) {
            navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
        }
        event.accepted = true
    }

    // Y and SELECT keep their existing window-level/unused behavior outside a
    // launch, while still obeying the launch interruption rule.
    Keys.onCallPressed: function(event) {
        event.accepted = root.consumeLaunchInput()
    }
    Keys.onContext1Pressed: function(event) {
        event.accepted = root.consumeLaunchInput()
    }

    // SELECT (Key_Context1) is deliberately NOT bound. This screen has no
    // host-settings overlay to open -- see the stage 3 report -- and binding
    // it to nothing would be exactly the failure HintBar.qml exists to
    // prevent: a live keycode whose action does nothing.

    // L1 / R1. Both shoulder buttons were unmapped in
    // sdlgamepadkeynavigation.cpp until this task -- they fell through to
    // `default: break` and no keycode reached QML for either, on any screen.
    // They now send Key_Context2 and Key_Context3, following the precedent set
    // when Y and Select had the same problem during the carousel work.
    //
    // Both are accepted whichever tab is showing, including when the press is a
    // no-op because that tab is already active. Letting an unaccepted shoulder
    // press bubble to the StackView is how a screen ends up with focus dragged
    // into chrome it does not have.
    Keys.onContext2Pressed: function(event) {
        if (!root.consumeLaunchInput()) {
            root.switchTab("recent")
        }
        event.accepted = true
    }
    Keys.onContext3Pressed: function(event) {
        if (!root.consumeLaunchInput()) {
            root.switchTab("library")
        }
        event.accepted = true
    }

    // --- the per-game options popup ------------------------------------------
    // Built as its own component, wired here. The screen owns what an action
    // MEANS; the overlay owns only which one the player picked.
    GameOptionsOverlay {
        id: gameOptions
        anchors.fill: parent

        onActionRequested: function(actionId) {
            root.handleGameAction(actionId)
        }
        onDismissed: Qt.callLater(root.reclaimFocus)
    }

    // Mouse/touch equivalent of the launch key barrier. The top-level proxy
    // receives presses during motion; this catches the brief capture interval.
    MouseArea {
        anchors.fill: parent
        enabled: root.launchBusy || root.quitBusy
        onPressed: root.consumeLaunchInput()
    }
}
