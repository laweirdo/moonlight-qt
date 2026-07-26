import QtQuick 2.9

import Bulan 1.0
import SdlGamepadKeyNavigation 1.0
import StreamingPreferences 1.0

// -----------------------------------------------------------------------------
// Offline proof sheet for the controller glyph system.
//
//   MOONLIGHT_INITIAL_VIEW=qrc:/gui/GlyphProof.qml
//
// Exists for the same reason TokenProof.qml does: the glyphs have to be checkable
// without owning five controllers, and a future glyph delivery needs somewhere to
// be reviewed before it goes near a real screen.
//
// The upper grid draws every family's art unconditionally, bypassing detection.
// The panel at the bottom goes through ControllerGlyph, so it reflects what is
// actually plugged in and honours the swap preference.
// -----------------------------------------------------------------------------

Item {
    objectName: qsTr("Glyph Proof")

    // resolved: the family whose art is actually on disk. "deck" and "fallback"
    // have none yet and alias to xinput, matching resolveGlyphFamily() in
    // sdlgamepadkeynavigation.cpp.
    readonly property var families: [
        { label: "Xbox / XInput",              resolved: "xinput", note: "XBOX360, XBOXONE" },
        { label: "PlayStation DS4 / DualSense", resolved: "ds",     note: "PS3, PS4, PS5" },
        { label: "Nintendo Switch Pro",        resolved: "switch", note: "SWITCH_PRO, JOYCON_*" },
        { label: "Steam Deck",                 resolved: "xinput", note: "vendor 0x28DE — aliased, no art yet" },
        { label: "Unknown / fallback",         resolved: "xinput", note: "UNKNOWN, VIRTUAL, Luna, Stadia, Shield" }
    ]

    // Labelled by position, deliberately never by letter.
    readonly property var tokens: [
        { t: "b1",     pos: "bottom" },
        { t: "b2",     pos: "right" },
        { t: "b3",     pos: "left" },
        { t: "b4",     pos: "top" },
        { t: "lb",     pos: "L bump" },
        { t: "rb",     pos: "R bump" },
        { t: "lt",     pos: "L trig" },
        { t: "rt",     pos: "R trig" },
        { t: "start",  pos: "start" },
        { t: "select", pos: "select" }
    ]

    readonly property int labelColW: 250
    readonly property int cellW: 62
    readonly property int glyphPx: 32

    Atmosphere { anchors.fill: parent }

    // The real HintBar, in situ, with this screen's own hint set.
    HintBar {
        id: previewBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        leftHints: [
            { action: "confirm",   label: qsTr("Connect"),  emphasis: true },
            { action: "alternate", label: qsTr("Wake") },
            { action: "options",   label: qsTr("Add a PC") }
        ]
        rightHints: [
            { action: "start",  label: qsTr("Client Settings") },
            { action: "select", label: qsTr("Host Settings") }
        ]
    }

    Column {
        anchors.fill: parent
        anchors.margins: Bulan.layoutScreenMarginY
        spacing: Bulan.spaceSm

        Text {
            text: "Controller glyphs — b1…b4 are PHYSICAL POSITIONS, not letters"
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeTitle
        }

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: "The bottom button is always confirm. Xbox draws A there, Nintendo draws B, "
                  + "PlayStation draws ✕ — the glyph changes, the binding does not."
            color: Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeCaption
        }

        Item { width: 1; height: Bulan.spaceXs }

        // Column headers
        Row {
            spacing: Bulan.spaceXs
            Item { width: labelColW; height: 1 }
            Repeater {
                model: tokens
                Text {
                    width: cellW
                    text: modelData.pos
                    color: Bulan.secondary
                    font.family: Bulan.familyUi
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // One row per family
        Repeater {
            model: families

            Row {
                id: famRow
                // Captured here so the inner Repeater's modelData does not shadow it.
                readonly property string famResolved: modelData.resolved
                spacing: Bulan.spaceXs

                Column {
                    width: labelColW
                    Text {
                        text: modelData.label
                        color: Bulan.textPrimary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
                    }
                    Text {
                        width: labelColW
                        text: modelData.note
                        color: Bulan.secondary
                        font.family: Bulan.familyUi
                        font.pixelSize: 10
                        wrapMode: Text.Wrap
                    }
                }

                Repeater {
                    model: tokens

                    Item {
                        width: cellW
                        height: 46

                        Image {
                            anchors.centerIn: parent
                            width: glyphPx
                            height: glyphPx
                            source: "qrc:/res/glyphs/unfocused/" + famRow.famResolved + "_" + modelData.t + ".svg"
                            sourceSize.width: glyphPx
                            sourceSize.height: glyphPx
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }
                }
            }
        }

        Item { width: 1; height: Bulan.spaceMd }

        // --- Live detection ---------------------------------------------------
        Rectangle {
            width: parent.width
            height: 104
            radius: Bulan.radiusMd
            color: Bulan.bgSurface
            border.width: 1
            border.color: Bulan.hairline

            Row {
                anchors.centerIn: parent
                spacing: Bulan.spaceXl

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "Live — through ControllerGlyph"
                        color: Bulan.textPrimary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeLabel
                    }
                    Text {
                        text: "family: " + SdlGamepadKeyNavigation.glyphFamily
                              + "    swapFaceButtons: " + StreamingPreferences.swapFaceButtons
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeCaption
                    }
                }

                Repeater {
                    model: [ "confirm", "back", "options", "alternate", "start", "select" ]

                    Column {
                        spacing: 3
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4
                            ControllerGlyph {
                                action: modelData
                                tone: "unfocused"
                                glyphSize: glyphPx
                            }
                            ControllerGlyph {
                                action: modelData
                                tone: "focus"
                                glyphSize: glyphPx
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData
                            color: Bulan.textSecondary
                            font.family: Bulan.familyUi
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
