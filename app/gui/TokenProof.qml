import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

// -----------------------------------------------------------------------------
// Bulan token proof sheet. NOT wired into normal navigation.
//
// Launch with:   MOONLIGHT_TOKEN_PROOF=1 moonlight
// On Steam Deck: set the game's Launch Options to
//                MOONLIGHT_TOKEN_PROOF=1 %command%
//
// Laid out for a 1280x800 panel. Content taller than 800 scrolls (D-pad
// up/down, mouse wheel). B / Escape quits.
//
// All values come from BulanTokens.qml. See that file for provenance.
// -----------------------------------------------------------------------------

Item {
    id: root
    objectName: "Bulan token proof"

    focus: true

    BulanTokens { id: tok }

    // Type scale for this sheet's OWN chrome (labels, headings). Deliberately
    // NOT drawn from the token file — the sheet's furniture must stay legible
    // and visually distinct from the specimens it is displaying.
    readonly property int chromeLabel: 11
    readonly property color chromeInk: "#A8AECB"
    readonly property color chromeDim: "#6F779B"
    readonly property color chromeRule: "#2A3050"
    readonly property color warn: "#E08B7D"

    // --- Fonts ---------------------------------------------------------------
    // Both faces are bundled in resources.qrc (SIL OFL 1.1) rather than relying
    // on the host having them — the Deck won't.
    //
    // These are STATIC instances baked out of Google Fonts' variable TTFs with
    // fontTools, not the variable fonts themselves. Fraunces ships four axes
    // (opsz 9-144, wght, SOFT, WONK) and its defaults are wght=900 / WONK=1;
    // opsz in particular swings it from a sturdy text cut to a hairline display
    // cut, which is what made the headings hard to read. Baking removes fvar
    // entirely, so no rasteriser can pick an axis value for us and the Deck
    // (FreeType) and Mac (CoreText) cannot diverge. Verified: advance widths are
    // identical to 3dp under both the offscreen and cocoa platform plugins.
    //
    // Pinned at: Fraunces opsz=14 SOFT=100 WONK=0 wght=400 (sturdy, soft
    // terminals per the brief, conventional letterforms); Inter opsz=18.
    // Inter needs two files because weight is baked in, not selected.
    FontLoader { id: interFace;    source: "qrc:/fonts/Inter-Regular.ttf" }
    FontLoader { id: interMedium;  source: "qrc:/fonts/Inter-Medium.ttf" }
    FontLoader { id: frauncesFace; source: "qrc:/fonts/Fraunces-Regular.ttf" }

    // Qt silently substitutes a fallback for a missing family, which on a proof
    // sheet is the worst possible failure: it looks right and is wrong. Keep the
    // check even though the fonts are bundled — it catches a broken resource
    // path or a family-name change on re-export. Depends on the loader statuses
    // so it re-evaluates once loading completes.
    property var availableFamilies: {
        var _ = interFace.status + interMedium.status + frauncesFace.status
        return Qt.fontFamilies()
    }
    function haveFamily(f) { return availableFamilies.indexOf(f) !== -1 }

    readonly property bool haveDisplayFace: haveFamily(tok.familyDisplay)
    readonly property bool haveUiFace: haveFamily(tok.familyUi)
    readonly property bool fontsOk: haveDisplayFace && haveUiFace

    StackView.onActivated: {
        window.width = 1280
        window.height = 800
    }

    // --- Background: the real vertical base gradient -------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#151A38" }
            GradientStop { position: 1.0; color: "#080A18" }
        }
    }

    Keys.onEscapePressed: Qt.quit()
    Keys.onBackPressed: Qt.quit()
    Keys.onUpPressed: flick.flick(0, 900)
    Keys.onDownPressed: flick.flick(0, -900)

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 48
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: content
            x: 24
            width: parent.width - 48
            spacing: 18

            Text {
                Layout.topMargin: 18
                text: "BULAN — TOKEN PROOF SHEET · 1280×800"
                color: "#F4EDE2"
                font.pixelSize: 20
                font.letterSpacing: 2
            }

            // === Font substitution warning ===================================
            // Only appears when a specified family is genuinely missing.
            Rectangle {
                Layout.fillWidth: true
                visible: !root.fontsOk
                implicitHeight: fontWarn.implicitHeight + 22
                color: "#2A1A1E"
                border.color: root.warn
                border.width: 1
                radius: 6

                ColumnLayout {
                    id: fontWarn
                    x: 14
                    y: 11
                    width: parent.width - 28
                    spacing: 3

                    Text {
                        text: "BUNDLED FONT FAILED TO LOAD — TYPE SPECIMENS ARE A FALLBACK FACE"
                        color: root.warn
                        font.pixelSize: root.chromeLabel
                        font.bold: true
                        font.letterSpacing: 1.1
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#F4EDE2"
                        font.pixelSize: root.chromeLabel
                        text: {
                            var missing = []
                            if (!root.haveDisplayFace) missing.push(tok.familyDisplay + " (display/titleLg/title)")
                            if (!root.haveUiFace) missing.push(tok.familyUi + " (bodyLg/body/label/caption)")
                            return "Missing: " + missing.join(" · ") +
                                   ". Qt has substituted a system face, so the letterforms you are " +
                                   "looking at are NOT Bulan's. Sizes, line heights, tracking, colour and " +
                                   "layout are still accurate. Check the qrc:/fonts/ paths in " +
                                   "resources.qrc, and that the family name in BulanTokens.qml still " +
                                   "matches what the TTF registers itself as."
                        }
                    }
                }
            }

            // === Two-column body =============================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 28

                // ---------- LEFT COLUMN ----------
                ColumnLayout {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 16

                    // --- Type ramp -------------------------------------------
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Type ramp"
                        source: tok.typeSource
                        trusted: tok.typeTrusted
                    }

                    Repeater {
                        model: tok.typeRamp

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.preferredWidth: 120
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 4
                                spacing: 1

                                Text {
                                    text: modelData.name
                                    color: "#F4EDE2"
                                    font.pixelSize: root.chromeLabel
                                }
                                Text {
                                    text: modelData.size + "/" + modelData.lineHeight +
                                          "  " + (modelData.tracking > 0 ? "+" : "") + modelData.tracking
                                    color: root.chromeInk
                                    font.pixelSize: root.chromeLabel - 1
                                    font.family: "Menlo"
                                }
                                Text {
                                    // Name the face per step, and mark it when
                                    // what you're seeing isn't actually it.
                                    text: modelData.family +
                                          (root.haveFamily(modelData.family) ? "" : " — SUBSTITUTED")
                                    color: root.haveFamily(modelData.family) ? root.chromeDim : root.warn
                                    font.pixelSize: root.chromeLabel - 2
                                }
                            }

                            // Faint band showing the token's line height box, so
                            // leading is measurable and not just implied.
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: modelData.lineHeight
                                color: "#12162E"
                                radius: 2

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: parent.height
                                    text: modelData.sample
                                    color: "#F4EDE2"
                                    font.family: modelData.family
                                    font.pixelSize: modelData.size
                                    font.weight: modelData.weight
                                    font.letterSpacing: modelData.tracking
                                    lineHeight: modelData.lineHeight
                                    lineHeightMode: Text.FixedHeight
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 4 }

                    // --- Spacing scale ---------------------------------------
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Spacing scale"
                        source: tok.spacingSource
                        trusted: tok.spacingTrusted
                    }

                    Repeater {
                        model: tok.spacingScale

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                Layout.preferredWidth: 120
                                text: modelData.name + " · " + modelData.value
                                color: root.chromeInk
                                font.pixelSize: root.chromeLabel
                            }

                            // Drawn at exactly its own value, so the scale is
                            // measurable against the panel by eye.
                            Rectangle {
                                width: modelData.value
                                height: 14
                                color: "#FFD9A0"
                                radius: 1
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }

                    Item { Layout.preferredHeight: 4 }

                    // --- Layout / target tokens ------------------------------
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Layout & targets"
                        source: "figma — spacing/base. targetMin is the one to check with a thumb."
                        trusted: true
                    }

                    Repeater {
                        model: tok.layoutScale

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                Layout.preferredWidth: 120
                                text: modelData.name
                                color: root.chromeInk
                                font.pixelSize: root.chromeLabel - 1
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: modelData.value
                                height: 14
                                color: "#8A93C2"
                                radius: 1
                            }

                            Text {
                                text: modelData.value + " · " + modelData.note
                                color: root.chromeDim
                                font.pixelSize: root.chromeLabel - 2
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // ---------- RIGHT COLUMN ----------
                ColumnLayout {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 16

                    // --- Palette ---------------------------------------------
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Palette"
                        source: tok.paletteSource
                        trusted: tok.paletteTrusted
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 8

                        Repeater {
                            model: tok.palette

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 4
                                    color: modelData.value
                                    border.color: "#2A3050"
                                    border.width: 1
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: modelData.name
                                        color: "#F4EDE2"
                                        font.pixelSize: root.chromeLabel
                                    }
                                    Text {
                                        text: modelData.value
                                        color: root.chromeInk
                                        font.pixelSize: root.chromeLabel - 1
                                        font.family: "Menlo"
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: modelData.note !== ""
                                        text: modelData.note
                                        color: root.chromeDim
                                        font.pixelSize: root.chromeLabel - 2
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 4 }

                    // --- Radius ----------------------------------------------
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Radius"
                        source: tok.radiusSource
                        trusted: tok.radiusTrusted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: tok.radiusScale

                            ColumnLayout {
                                spacing: 4

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 54
                                    height: 44
                                    color: "#171B33"
                                    border.color: "#FFD9A0"
                                    border.width: 1
                                    // radiusFull (999) is a sentinel meaning
                                    // "fully rounded" — clamp so it renders as
                                    // the pill it describes.
                                    radius: Math.min(modelData.value, height / 2)
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name.replace("radius", "")
                                    color: "#F4EDE2"
                                    font.pixelSize: root.chromeLabel - 1
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.value
                                    color: root.chromeDim
                                    font.pixelSize: root.chromeLabel - 2
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Item { Layout.preferredHeight: 4 }

                    // --- Gradients -------------------------------------------
                    SectionHeader {
                        Layout.fillWidth: true
                        title: "Gradients"
                        source: tok.gradientSource
                        trusted: true
                    }

                    Repeater {
                        model: tok.gradients

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Canvas {
                                Layout.fillWidth: true
                                implicitHeight: 52

                                // Repaint when the layout finally gives us a width
                                onWidthChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    // Radial swatches sit on the base colour so a
                                    // 3-6% bloom is actually visible.
                                    if (modelData.kind === "radial") {
                                        ctx.fillStyle = "#0D1024"
                                        ctx.fillRect(0, 0, width, height)
                                        var rg = ctx.createRadialGradient(
                                                    width / 2, height / 2, 1,
                                                    width / 2, height / 2, height * 1.4)
                                        rg.addColorStop(0.0, Qt.rgba(1, 0.85, 0.63, 0.06))
                                        rg.addColorStop(1.0, Qt.rgba(1, 0.85, 0.63, 0.0))
                                        ctx.fillStyle = rg
                                        ctx.fillRect(0, 0, width, height)
                                    } else {
                                        var lg = ctx.createLinearGradient(0, 0, 0, height)
                                        lg.addColorStop(0.0, modelData.from)
                                        lg.addColorStop(1.0, modelData.to)
                                        ctx.fillStyle = lg
                                        ctx.fillRect(0, 0, width, height)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: "#F4EDE2"
                                font.pixelSize: root.chromeLabel
                            }
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: modelData.spec
                                color: modelData.trusted ? root.chromeInk : root.warn
                                font.pixelSize: root.chromeLabel - 2
                            }
                        }
                    }
                }
            }

            // === States — full width ==========================================
            // Pulled out of the two-column body: at column width each tile was
            // only ~143px, which left the focus bloom no room to clear the
            // button horizontally. Full width gives ~300px per tile.
            // --- Interaction states ----------------------------------
            SectionHeader {
                Layout.fillWidth: true
                title: "States — one element, four states"
                source: tok.statesSource
                trusted: false
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        { state: "focus",    spec: "brief"    },
                        { state: "hover",    spec: "inferred" },
                        { state: "pressed",  spec: "inferred" },
                        { state: "disabled", spec: "inferred" }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        // Inset of the button inside its tile. This is the room
                        // the focus bloom has to clear the button and fall off
                        // to nothing — on every side, including left and right.
                        readonly property int bloomInset: 50

                        Item {
                            id: stateCell
                            Layout.fillWidth: true
                            // 64 (targetMin) + bloom headroom above and below.
                            implicitHeight: 64 + bloomInset * 2

                            // Focus bloom — the brief's warm amber halo.
                            // Drawn on Canvas so it works without
                            // QtGraphicalEffects (gone in Qt 6).
                            Canvas {
                                anchors.fill: parent
                                visible: modelData.state === "focus"
                                // Both dimensions must retrigger paint, or the
                                // gradient keeps stale radii.
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    // The falloff must reach zero BEFORE the canvas
                                    // edge on every axis, or it gets clipped flat and
                                    // reads as a square. A single circular radius
                                    // can't do that here: the button is far wider
                                    // than it is tall, so a circle sized to clear it
                                    // vertically stays hidden behind it horizontally.
                                    // Use an ellipse matching the button's proportions
                                    // instead — semi-axes are the button's half-extents
                                    // plus the same inset all round.
                                    var ax = (width - bloomInset * 2) / 2 + bloomInset
                                    var ay = 32 + bloomInset
                                    ax = Math.min(ax, width / 2)
                                    ay = Math.min(ay, height / 2)

                                    ctx.save()
                                    ctx.translate(width / 2, height / 2)
                                    // Draw a unit circle of radius ay, stretched on x
                                    // to ax. Scaling the context keeps the gradient
                                    // itself elliptical rather than just the clip.
                                    ctx.scale(ax / ay, 1)

                                    var g = ctx.createRadialGradient(0, 0, 0, 0, 0, ay)
                                    // Eased rolloff rather than a straight ramp — a
                                    // linear alpha fade still reads as a visible disc
                                    // edge on a dark ground.
                                    g.addColorStop(0.00, Qt.rgba(1, 0.85, 0.63, 0.30))
                                    g.addColorStop(0.25, Qt.rgba(1, 0.85, 0.63, 0.185))
                                    g.addColorStop(0.45, Qt.rgba(1, 0.85, 0.63, 0.105))
                                    g.addColorStop(0.65, Qt.rgba(1, 0.85, 0.63, 0.048))
                                    g.addColorStop(0.82, Qt.rgba(1, 0.85, 0.63, 0.016))
                                    g.addColorStop(1.00, Qt.rgba(1, 0.85, 0.63, 0.0))
                                    ctx.fillStyle = g
                                    // Fill only the ellipse. Filling the full rect
                                    // paints alpha-0 corners, which on some drivers
                                    // still band faintly.
                                    ctx.beginPath()
                                    ctx.arc(0, 0, ay, 0, Math.PI * 2)
                                    ctx.fill()
                                    ctx.restore()
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                // Inset on every side by the same amount, so the
                                // bloom has symmetric room to fall off.
                                width: parent.width - bloomInset * 2
                                height: 64          // targetMin
                                radius: 14          // radiusMd
                                opacity: modelData.state === "disabled" ? 0.38 : 1.0

                                color: modelData.state === "hover"   ? "#1E2440"
                                     : modelData.state === "pressed" ? "#10142A"
                                     : "#171B33"

                                border.width: modelData.state === "focus" ? 2 : 1
                                border.color: modelData.state === "focus" ? "#FFD9A0"
                                            : modelData.state === "hover" ? "#8A93C2"
                                            : "#2A3050"

                                // Pressed reads as a small inward settle
                                scale: modelData.state === "pressed" ? 0.97 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    text: "Resume"
                                    font.family: tok.familyUi
                                    font.pixelSize: 18      // sizeLabel
                                    font.weight: Font.Medium
                                    color: modelData.state === "disabled" ? "#A8AECB"
                                         : modelData.state === "focus"    ? "#FFD9A0"
                                         : "#F4EDE2"
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.state
                            color: "#F4EDE2"
                            font.pixelSize: root.chromeLabel
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.spec
                            color: modelData.spec === "brief" ? "#7FC7A8" : root.warn
                            font.pixelSize: root.chromeLabel - 2
                        }
                    }
                }
            }
        }
    }
}
