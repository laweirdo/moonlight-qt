import QtQuick 2.9
import QtTest 1.2
import "../../app/gui" as Gui

TestCase {
    name: "BulanHome"

    ListModel {
        id: games
    }

    Component {
        id: subject

        Gui.BulanHome {
            width: 1280
            height: 800
            gameModel: games
            hostName: "Desktop-PC"
            hostOnline: true
        }
    }

    SignalSpy {
        id: playSpy
        signalName: "playRequested"
    }

    SignalSpy {
        id: optionsSpy
        signalName: "gameOptionsRequested"
    }

    function init() {
        games.clear()
        playSpy.clear()
        optionsSpy.clear()
    }

    function addGame(name, appId, lastPlayed, running, hidden, directLaunch) {
        games.append({
            "name": name,
            "appid": appId,
            "boxart": "",
            "running": running === true,
            "hidden": hidden === true,
            "directLaunch": directLaunch === true,
            "appCollectorGame": false,
            "lastPlayed": lastPlayed || new Date(0)
        })
    }

    function test_entrySnapshotCarriesStableMenuState() {
        addGame("Hades II", 42, null, true, false, true)

        var home = createTemporaryObject(subject, this)
        verify(home !== null)
        tryCompare(home, "gameCount", 1)
        tryVerify(function() { return home.entryForAppId(42) !== null })
        var entry = home.entryForAppId(42)

        compare(entry.appId, 42)
        compare(entry.running, true)
        compare(entry.hidden, false)
        compare(entry.directLaunch, true)
    }

    function test_withoutHistoryShowsFirstFiveAlphabetically() {
        addGame("Zelda", 6)
        addGame("Control", 3)
        addGame("Balatro", 2)
        addGame("Hades II", 4)
        addGame("Forza Horizon 5", 1)
        addGame("Outer Wilds", 5)

        var home = createTemporaryObject(subject, this)
        verify(home !== null)

        tryCompare(home, "gameCount", 6)
        tryVerify(function() { return home.shelfAppIds.length === 5 })
        compare(home.sectionTitle, "Your games")
        compare(home.shelfAppIds, [2, 3, 1, 4, 5])
        compare(home.selectedAppId, 2)
    }

    function test_continueUsesFiveNewestPlayedGames() {
        addGame("Never played", 9)
        addGame("Fifth", 5, new Date("2026-08-10T12:00:00Z"))
        addGame("Newest", 1, new Date("2026-08-14T12:00:00Z"))
        addGame("Third", 3, new Date("2026-08-12T12:00:00Z"))
        addGame("Sixth", 6, new Date("2026-08-09T12:00:00Z"))
        addGame("Second", 2, new Date("2026-08-13T12:00:00Z"))
        addGame("Fourth", 4, new Date("2026-08-11T12:00:00Z"))

        var home = createTemporaryObject(subject, this)
        verify(home !== null)

        tryVerify(function() { return home.shelfAppIds.length === 5 })
        compare(home.sectionTitle, "Pick up where you left off")
        compare(home.shelfAppIds, [1, 2, 3, 4, 5])
        compare(home.selectedAppId, 1)
        compare(home.shelfOffsetForAppId(home.selectedAppId), 0)
        compare(home.shelfOffsetForAppId(2), -2)
        compare(home.shelfOffsetForAppId(3), -1)
        compare(home.shelfOffsetForAppId(4), 1)
        compare(home.shelfOffsetForAppId(5), 2)
    }

    function test_downOpensAlphabeticalLibraryWithoutLosingSelection() {
        addGame("Zelda", 6, new Date("2026-08-13T12:00:00Z"))
        addGame("Control", 3)
        addGame("Balatro", 2)
        addGame("Hades II", 4, new Date("2026-08-14T12:00:00Z"))
        addGame("Forza Horizon 5", 1)
        addGame("Outer Wilds", 5)

        var home = createTemporaryObject(subject, this)
        verify(home !== null)
        tryCompare(home, "selectedAppId", 4)
        home.forceActiveFocus()

        keyClick(Qt.Key_Down)

        compare(home.mode, "library")
        compare(home.selectedAppId, 4)
        compare(home.displayAppIds, [2, 3, 1, 4, 5, 6])

        keyClick(Qt.Key_Right)
        compare(home.selectedAppId, 5)
    }

    function test_modelReorderKeepsSelectionByAppId() {
        addGame("Balatro", 2)
        addGame("Control", 3)
        addGame("Hades II", 4)

        var home = createTemporaryObject(subject, this)
        verify(home !== null)
        tryCompare(home, "selectedAppId", 2)
        home.forceActiveFocus()
        keyClick(Qt.Key_Right)
        compare(home.selectedAppId, 3)

        games.move(2, 0, 1)

        tryCompare(home, "selectedAppId", 3)
    }

    function test_confirmAndSelectEmitStableAppIdIntentions() {
        addGame("Balatro", 2)
        addGame("Control", 3)

        var home = createTemporaryObject(subject, this)
        verify(home !== null)
        tryCompare(home, "selectedAppId", 2)
        home.forceActiveFocus()
        playSpy.target = home
        optionsSpy.target = home

        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Return)
        home.openGameOptions()

        compare(playSpy.count, 1)
        compare(playSpy.signalArguments[0][0], 3)
        compare(optionsSpy.count, 1)
        compare(optionsSpy.signalArguments[0][0], 3)
    }
}
