import QtQuick 2.9
import QtTest 1.2
import "../../app/gui" as Gui

TestCase {
    name: "BulanGameTile"
    when: windowShown

    Component {
        id: subject

        Gui.BulanGameTile {
            gameName: "A Very Long Game Title That Must Not Clip"
            tileWidth: 244
            tileHeight: 304
            selected: true
        }
    }

    function test_titleHasReservedSpaceBelowArtwork() {
        var tile = createTemporaryObject(subject, this)
        verify(tile !== null)
        var artwork = findChild(tile, "artwork")
        var title = findChild(tile, "gameTitle")
        verify(artwork !== null)
        verify(title !== null)
        verify(title.y >= artwork.y + artwork.height)
        verify(title.y + title.height <= tile.height)
    }

    function test_stockPlaceholderIsNotPresentedAsGameArtwork() {
        var tile = createTemporaryObject(subject, this, {
            "boxart": Qt.resolvedUrl("../../app/res/no_app_image.png")
        })
        verify(tile !== null)
        var artwork = findChild(tile, "boxArtImage")
        verify(artwork !== null)
        tryCompare(artwork, "status", Image.Ready)
        compare(artwork.opacity, 0)
    }
}
