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

    property AppModel appModel: createModel()

    // Emitted instead of building the popup. X on a tile means "show its
    // options"; this file only names which game, not what the popup contains.
    signal optionsRequested(int sourceIndex)

    // Emitted instead of building the confirmation. A on a game while a
    // DIFFERENT one is running must not launch -- see actConfirmOn() below.
    signal switchGameRequested(int sourceIndex, string runningName, string nextName)

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
                onIsRunningChanged: root.recomputeRunning()
                onLastPlayedValueChanged: root.recomputeRecentOrder()
            }
            onItemAdded: {
                root.recomputeRunning()
                root.recomputeRecentOrder()
                root.clampLibraryIndex()
                root.clampRecentIndex()
                root.ensureLibraryFocusVisible()
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

    // --- launching -------------------------------------------------------------
    // Reproduces upstream's launchOrResumeSelectedApp()/createSessionForApp()
    // path (git show 6712ac83:app/gui/AppView.qml), through the unmodified
    // StreamSegue.qml, with two differences: quitting-and-switching is not
    // built here (it is emitted as a signal instead, see switchGameRequested
    // above), and the whole path is guarded off in review mode.
    function launchOrResumeApp(srcIndex, gameName, isResume) {
        var component = Qt.createComponent("StreamSegue.qml")
        if (component.status !== Component.Ready) {
            console.error("StreamSegue.qml failed to load:", component.errorString())
            return
        }
        var segue = component.createObject(stackView, {
            "appName": gameName,
            "session": appModel.createSessionForApp(srcIndex),
            "isResume": isResume
        })
        if (segue === null) {
            console.error("StreamSegue.qml loaded but could not be created")
            return
        }
        stackView.push(segue)
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
    function actConfirmOn(srcIndex) {
        if (root.useFakeGames) {
            console.log("Review mode: launching does nothing on a fake game row.")
            return
        }
        if (srcIndex < 0 || srcIndex >= root.gameCount) {
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
            root.switchGameRequested(srcIndex, root.runningGameName, it.gameName)
            return
        }
        root.launchOrResumeApp(srcIndex, it.gameName, it.isRunning)
    }

    function actConfirm() {
        root.actConfirmOn(root.currentSourceIndex())
    }

    // True once this screen has tried the upstream direct-launch behaviour, so
    // it is attempted exactly once per activation of this screen rather than
    // looping every time StackView.onActivated fires again (e.g. on return
    // from a stream). Follows upstream's own `showGames` guard, renamed for
    // what it actually tracks here.
    property bool directLaunchAttempted: false

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
        Qt.callLater(function() {
            root.actConfirmOn(directIndex)
        })
    }

    // --- lifecycle -----------------------------------------------------------
    StackView.onActivated: {
        // This is a Bulan screen now; the stock toolbar upstream's AppView kept
        // is gone, replaced by this screen's own header and hint bar.
        toolBar.visible = false

        // Null in review mode -- see createModel().
        if (appModel !== null) {
            appModel.computerLost.connect(computerLost)
        }

        root.forceActiveFocus()
        root.attemptDirectLaunch()

        // Review hook: MOONLIGHT_GAME_REVIEW=options|switch. Fake games only,
        // and once per launch rather than on every return to this screen --
        // reopening the popup each time the player backs out of it would make
        // B useless, the same rule MOONLIGHT_OPEN_APPS_FOR_HOST follows.
        if (root.useFakeGames && !root.gameReviewOpened &&
                typeof gameReviewAction !== "undefined" &&
                (gameReviewAction === "options" || gameReviewAction === "switch")) {
            root.gameReviewOpened = true
            Qt.callLater(function() {
                var srcIndex = root.currentSourceIndex()
                if (srcIndex < 0) {
                    return
                }
                if (gameReviewAction === "switch") {
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
                            root.openSwitchConfirmation(i)
                            return
                        }
                    }
                    return
                }
                root.openGameOptions(srcIndex)
            })
        }
    }

    property bool gameReviewOpened: false

    StackView.onDeactivating: {
        toolBar.visible = true
        if (appModel !== null) {
            appModel.computerLost.disconnect(computerLost)
        }
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
        if (!activeFocus && StackView.status === StackView.Active) {
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
    property int optionsSourceIndex: -1

    function openGameOptions(srcIndex) {
        var snap = root.gameSnapshot(srcIndex)
        if (snap === null) {
            return
        }
        root.optionsSourceIndex = srcIndex
        gameOptions.showForGame(snap)
    }

    function openSwitchConfirmation(srcIndex) {
        var snap = root.gameSnapshot(srcIndex)
        if (snap === null) {
            return
        }
        root.optionsSourceIndex = srcIndex
        gameOptions.showSwitchConfirmation(snap)
    }

    function gameSnapshot(srcIndex) {
        if (srcIndex < 0 || srcIndex >= root.gameCount) {
            return null
        }
        var it = modelMirror.itemAt(srcIndex)
        if (!it) {
            return null
        }
        return {
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
        var srcIndex = root.optionsSourceIndex
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
            // Closed before launching, not after: the stream segue is pushed on
            // top of this screen and leaving the popup open would leave it
            // drawn over whatever comes back when the stream ends.
            gameOptions.close()
            root.launchOrResumeApp(srcIndex, it.gameName, it.isRunning)
        } else if (actionId === "quitGame") {
            gameOptions.close()
            root.quitRunningGame(null, "")
        } else if (actionId === "quitAndSwitch") {
            gameOptions.close()
            root.quitRunningGame(srcIndex, it.gameName)
        }
    }

    // Quits the running game, optionally streaming a different one once it has
    // gone. Reuses upstream's QuitSegue exactly as the old AppView did -- that
    // component owns the wait and the failure, and rebuilding it is not in this
    // task.
    function quitRunningGame(nextSrcIndex, nextName) {
        if (root.appModel === null) {
            return
        }
        var component = Qt.createComponent("QuitSegue.qml")
        if (component.status !== Component.Ready) {
            console.error("QuitSegue.qml failed to load:", component.errorString())
            return
        }
        var params = {
            "appName": root.runningGameName,
            "quitRunningAppFn": function() { root.appModel.quitRunningApp() }
        }
        if (nextSrcIndex !== null && nextSrcIndex >= 0) {
            params.nextAppName = nextName
            params.nextSession = root.appModel.createSessionForApp(nextSrcIndex)
        } else {
            params.nextAppName = null
            params.nextSession = null
        }
        var segue = component.createObject(stackView, params)
        if (segue === null) {
            console.error("QuitSegue.qml loaded but could not be created")
            return
        }
        stackView.push(segue)
    }

    onOptionsRequested: function(sourceIndex) {
        root.openGameOptions(sourceIndex)
    }

    onSwitchGameRequested: function(sourceIndex, runningName, nextName) {
        root.openSwitchConfirmation(sourceIndex)
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
        anchors.bottom: hintBar.top
        visible: root.activeTab === "recent" && root.gameCount > 0

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

        Repeater {
            model: root.gameModel

            delegate: Item {
                id: recentSlot

                readonly property int rank:
                    root.recentRankBySourceIndex[index] !== undefined
                        ? root.recentRankBySourceIndex[index] : index
                // Clamped to two slots either side, exactly like
                // HostTile's `slot` in HostCarousel.qml -- distance 2 is
                // off-screen and invisible, which is what gives a departing
                // tile somewhere to go rather than being cut.
                readonly property int slot: {
                    var d = rank - root.recentFocusedIndex
                    return d < -2 ? -2 : (d > 2 ? 2 : d)
                }
                readonly property int distance: slot < 0 ? -slot : slot
                readonly property bool isFocused: rank === root.recentFocusedIndex
                readonly property real tileScale:
                    distance === 0 ? 1.0 : Bulan.gameRecentNeighbourScale

                width: Bulan.gameRecentTileWidth
                height: Bulan.gameRecentTileHeight

                x: recentView.width / 2 - width / 2 + slot * Bulan.gameRecentSpread
                y: recentView.focusCenterY - height / 2

                z: distance === 0 ? 2 : 0
                opacity: distance === 0 ? 1.0 : (distance === 1 ? 0.5 : 0.0)
                visible: opacity > 0.01

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
                        x: Bulan.spaceXs
                        y: Bulan.spaceXs
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

                    Row {
                        visible: recentSlot.isFocused
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Bulan.spaceXs

                        Text {
                            text: model.name
                            color: Bulan.textPrimary
                            font.family: Bulan.familyDisplay
                            font.pixelSize: Bulan.sizeTitleLg
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: model.running
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
                        visible: !recentSlot.isFocused
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Bulan.gameRecentTileWidth * Bulan.gameRecentNeighbourScale
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: model.name
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
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
    function ensureLibraryFocusVisible() {
        if (root.gameCount === 0) {
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
        libraryFlickable.contentY = Math.max(0, Math.min(newY, maxY))
    }
    onLibraryFocusedIndexChanged: ensureLibraryFocusVisible()

    Flickable {
        id: libraryFlickable
        anchors.left: parent.left
        anchors.leftMargin: Bulan.layoutScreenMarginX - root.libraryFocusInset
        anchors.top: tabStrip.bottom
        anchors.topMargin: Bulan.spaceLg - root.libraryFocusInset
        anchors.bottom: hintBar.top
        width: Bulan.gameGridColumns * Bulan.gameTileWidth
               + (Bulan.gameGridColumns - 1) * Bulan.gameGridGap
               + 2 * root.libraryFocusInset
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: root.libraryRowCount * root.libraryCellHeight
                       + 2 * root.libraryFocusInset
        visible: root.activeTab === "library" && root.gameCount > 0

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

                x: root.libraryFocusInset + column * root.libraryCellWidth
                y: root.libraryFocusInset + row * root.libraryCellHeight

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
    // Withholds Play/Options entirely when the library is empty (nothing to
    // act on, and X would open options on nothing), reads Resume instead of
    // Play for the running game, and withholds two of the mockup's promised
    // right-hand hints because they cannot currently do anything -- see the
    // stage 3 report:
    //
    //   Switch tab (L1/R1): no keycode reaches this file at all right now.
    //   Host Settings (SELECT): this screen has no host-settings overlay.
    //
    // HintBar.qml's own comment is explicit that a hint promising an action
    // that does nothing is worse than showing fewer hints.
    HintBar {
        id: hintBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // Hidden while the options popup is up, because the popup brings its
        // own bar and the two land in exactly the same place. The scrim is
        // translucent by design, so this screen's bar was reading straight
        // through it and the two sets of hints drew over each other -- "Select"
        // on top of "Play", "Close" on top of "Client Settings". Two bars also
        // contradict each other: only one of them describes what the buttons
        // do while a popup owns the input.
        visible: !gameOptions.visible

        leftHints: root.gameCount > 0
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
        // and building a second one is not in this task. Advertising it would
        // be exactly the failure HintBar.qml exists to prevent. Recorded as a
        // gap in TASK-BRIEF.md rather than papered over with a dead hint.
        rightHints: [
            { action: "l1",    label: qsTr("Switch tab") },
            { action: "start", label: qsTr("Client Settings") }
        ]
    }

    // --- input ---------------------------------------------------------------
    // Following SPEC-host-carousel.md's table and HostCarousel.qml's handlers.
    //
    // Left/Right: Library moves through the flat index (see moveLibraryStep's
    // own comment for the row-wrap judgement call); Recent moves by rank,
    // clamping at both ends.
    Keys.onLeftPressed: {
        if (root.activeTab === "recent") {
            root.moveRecentBy(-1)
        } else {
            root.moveLibraryStep(-1)
        }
    }
    Keys.onRightPressed: {
        if (root.activeTab === "recent") {
            root.moveRecentBy(1)
        } else {
            root.moveLibraryStep(1)
        }
    }

    // Up/Down: Library moves by row, clamping. Recent is inert and swallowed,
    // exactly as on the carousel -- accepted so it does not bubble to the
    // StackView and drag focus into chrome this screen hides.
    Keys.onUpPressed: {
        if (root.activeTab === "library") {
            root.moveLibraryRow(-1)
        }
        event.accepted = true
    }
    Keys.onDownPressed: {
        if (root.activeTab === "library") {
            root.moveLibraryRow(1)
        }
        event.accepted = true
    }

    // A. Three keycodes for one button, following HostCarousel's own comment:
    // Return and Enter are the same press on different keyboards, and Space is
    // what A becomes while the settings page's tab chain is armed elsewhere in
    // the app.
    Keys.onReturnPressed: root.actConfirm()
    Keys.onEnterPressed: root.actConfirm()
    Keys.onSpacePressed: {
        root.actConfirm()
        event.accepted = true
    }

    // X. Names the focused game's options; the popup itself is built and
    // wired up elsewhere.
    Keys.onMenuPressed: {
        var srcIndex = root.currentSourceIndex()
        if (srcIndex >= 0) {
            root.optionsRequested(srcIndex)
        }
        event.accepted = true
    }

    // B (Key_Escape) is deliberately NOT handled here. main.qml's StackView
    // owns Keys.onEscapePressed at the root: with stackView.depth > 1 it pops
    // back to the host carousel; this file leaves the event unaccepted so it
    // bubbles there. Confirmed by reading main.qml -- see the stage 3 report.

    // START.
    Keys.onHangupPressed: {
        navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
        event.accepted = true
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
    Keys.onContext2Pressed: {
        root.switchTab("recent")
        event.accepted = true
    }
    Keys.onContext3Pressed: {
        root.switchTab("library")
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
}
