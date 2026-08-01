import QtQuick 2.9
// Imported for the StackView attached properties (StackView.onActivated) only --
// this screen pushes and pops through the app's existing StackView. No stock
// control from this module is instantiated anywhere in this file.
import QtQuick.Controls 2.2

import AppModel 1.0
import ComputerManager 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// The game grid: a host-specific Library of one host's games.
//
// Stage 1 (this file, first pass) is STATIC -- the screen shell, the model, and
// a plain grid of placeholder tiles. No input handling, no focus treatment, no
// motion, no popups. See TASK-BRIEF.md's stage table: artwork/focus/motion is
// stage 2, navigation/tabs/popups is stage 3.
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
// -----------------------------------------------------------------------------

FocusScope {
    id: root

    property int computerIndex
    property bool showHiddenGames

    property AppModel appModel: createModel()

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
    // Stage 3's Recent ordering is built on this.
    function playedAt(value) {
        if (!value || typeof value.getTime !== "function") {
            return 0
        }
        var t = value.getTime()
        return isNaN(t) ? 0 : Math.max(t, 0)
    }

    function computerLost() {
        // Go back to the host carousel on PC loss, exactly as upstream did.
        stackView.pop()
    }

    // --- model mirror ----------------------------------------------------------
    // Invisible mirror of gameModel, the same pattern HostCarousel.qml's
    // `counter` Repeater uses. It does two jobs.
    //
    // First, it reads `running`/`name` by role NAME rather than by role number,
    // which is the reason that pattern exists at all -- role numbers are an
    // offset from Qt::UserRole and would break silently if anyone reordered the
    // enum in appmodel.h.
    //
    // Second, it is where the row count comes from. `gameModel.count` cannot be
    // used: AppModel is a QAbstractListModel and has no `count` property in QML,
    // so that expression is undefined against the real model and the grid would
    // draw nothing while reporting itself empty. Only the fake ListModel would
    // have answered. A Repeater over the same model counts both.
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

    Item {
        visible: false
        Repeater {
            id: modelMirror
            model: root.gameModel
            delegate: Item {
                readonly property bool isRunning: model.running
                readonly property string gameName: model.name
                onIsRunningChanged: root.recomputeRunning()
            }
            onItemAdded: root.recomputeRunning()
            onItemRemoved: root.recomputeRunning()
        }
    }
    Component.onCompleted: recomputeRunning()

    // The host's name. Normally objectName, which HostCarousel.openAppView()
    // already sets -- no second plumbing path for the same string. In review
    // mode nothing sets it, because MOONLIGHT_INITIAL_VIEW pushes this screen
    // with no properties at all, so the header would draw a blank name and a
    // "?" disc and every screenshot would be reviewing the wrong thing.
    readonly property string hostName:
        root.objectName.length > 0 ? root.objectName
                                   : (root.useFakeGames ? "Desktop-PC" : "")

    // --- tabs --------------------------------------------------------------
    // Stage 1 hardcodes "library" -- Recent and switching between the two are
    // stage 3. Declared now so both tab states are expressible and drawable.
    property string activeTab: "library"

    // Which tile is focused. Stage 3 replaces this with real controller
    // navigation; a plain property is what lets GameTile's focus ring, scale
    // and bloom be reviewed via MOONLIGHT_FAKE_GAMES before any input exists.
    property int focusedIndex: 0

    // --- lifecycle -----------------------------------------------------------
    StackView.onActivated: {
        // This is a Bulan screen now; the stock toolbar upstream's AppView kept
        // is gone, replaced by this screen's own header and hint bar.
        toolBar.visible = false

        // Null in review mode -- see createModel().
        if (appModel !== null) {
            appModel.computerLost.connect(computerLost)
        }

        // STAGE 3: upstream auto-launched a direct-launch app here
        // (model.getDirectLaunchAppIndex(), then launchOrResumeSelectedApp())
        // whenever the host was opened without showHiddenGames and no game was
        // already showing. That is real behaviour this rewrite removes for
        // now, not behaviour that stopped mattering -- it has to come back
        // when navigation and launching are rebuilt in stage 3, reading
        // model.getDirectLaunchAppIndex() the same way.
    }

    StackView.onDeactivating: {
        toolBar.visible = true
        if (appModel !== null) {
            appModel.computerLost.disconnect(computerLost)
        }
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
    // tab is stage 3; this only has to be able to DRAW either state.
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
        visible: root.gameCount > 0

        // No ScrollBar attached -- that is a stock QtQuick.Controls control and
        // forbidden here. Stage 1 has no input treatment at all yet, so there
        // is nothing to bind one to besides.

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
               + (root.focusedIndex % Bulan.gameGridColumns) * root.libraryCellWidth
               + Bulan.gameTileWidth / 2 - width / 2
            y: root.libraryFocusInset
               + Math.floor(root.focusedIndex / Bulan.gameGridColumns) * root.libraryCellHeight
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
                isCurrent: index === root.focusedIndex
            }
        }
    }

    // --- empty library ---------------------------------------------------------
    // Minimal placeholder only. TASK-BRIEF.md: the designed empty-library
    // treatment is Phase D and FLOW.md records it as unresolved flow design --
    // this is deliberately one line and nothing else.
    Text {
        anchors.centerIn: parent
        visible: root.gameCount === 0
        text: qsTr("No games here yet.")
        color: Bulan.textSecondary
        font.family: Bulan.familyUi
        font.pixelSize: Bulan.sizeBodyLg
    }

    // --- hint bar ------------------------------------------------------------
    // Display-only in stage 1: every binding below is what the button WILL do
    // once stage 3 wires up A/X/B/L1/R1/START/SELECT. None of it fires yet.
    HintBar {
        id: hintBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        leftHints: [
            { action: "confirm", label: qsTr("Play"), emphasis: true },
            { action: "options", label: qsTr("Options") },
            { action: "back",    label: qsTr("Back") }
        ]

        rightHints: [
            { action: "l1",     label: qsTr("Switch tab") },
            { action: "start",  label: qsTr("Client Settings") },
            { action: "select", label: qsTr("Host Settings") }
        ]
    }
}
