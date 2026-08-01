import QtQuick 2.9
// MultiEffect only, for masking the artwork to the tile's rounded rectangle --
// same module HostCarousel.qml and main.qml already use for the popup blur.
// Not a Qt Quick Control; nothing here is a stock visual control.
import QtQuick.Effects

import Bulan 1.0

// -----------------------------------------------------------------------------
// One game: artwork cropped to a rounded rectangle, a placeholder fallback, a
// focus ring, and a title/running label beneath. The rectangular equivalent of
// HostTile.qml -- read that file's comments first; the focus/press scale and
// the label-follows-the-drawn-edge pattern are copied from it deliberately.
//
// Sized by the caller: tileWidth/tileHeight default to the Library dimensions
// but Recent (stage 3) passes its own larger pair. Nothing below hardcodes
// either size.
// -----------------------------------------------------------------------------

Item {
    id: tile

    property string gameName: ""
    property url boxart: ""
    property bool running: false
    property bool isCurrent: false

    // Not in the brief's property list, but required to preserve the upstream
    // placeholder check exactly (see `art.isPlaceholder` below): GFE's
    // placeholder art is told apart from real art by exact pixel dimensions,
    // except for the one known app-collector game (Overcooked) whose real art
    // happens to match one of those sizes. AppView.qml passes this straight
    // from the model's existing `appCollectorGame` role.
    property bool appCollectorGame: false

    property real tileWidth: Bulan.gameTileWidth
    property real tileHeight: Bulan.gameTileHeight

    // Stage 3 connects this. Nothing emits it yet -- stage 2 adds no input
    // handling, so there is deliberately no MouseArea here.
    signal activated()

    width: tile.tileWidth
    height: tile.tileHeight + Bulan.spaceMd + Bulan.lineHeightLabel

    // Press feedback, following HostTile.qml's mechanism exactly so stage 3 has
    // it ready to wire up. Nothing calls flashPress() yet -- with no MouseArea
    // in this stage, `pressed` can only ever be driven by the timer.
    property bool pressed: pressFlash.running
    function flashPress() {
        pressFlash.restart()
    }
    Timer {
        id: pressFlash
        interval: Bulan.motionPressMs
    }

    // --- the artwork rectangle -------------------------------------------------
    Rectangle {
        id: artRect
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: tile.tileWidth
        height: tile.tileHeight
        radius: Bulan.radiusMd
        color: Bulan.bgSurface

        border.width: tile.isCurrent ? 2 : 1
        border.color: tile.isCurrent ? Bulan.accentPrimary : Bulan.hairline
        Behavior on border.color {
            ColorAnimation { duration: Bulan.motionFocusMs }
        }

        transformOrigin: Item.Center

        // Same shape as HostTile.qml's interactionScale, and the same reason:
        // this is the only scale animated *here*. A caller driving travel (as
        // HostCarousel does for its tiles) would animate its own transform
        // separately rather than feed this Behavior a moving target.
        property real interactionScale:
            tile.pressed ? Bulan.motionPressScale
                         : (tile.isCurrent ? Bulan.motionFocusScale : 1.0)
        Behavior on interactionScale {
            NumberAnimation {
                duration: tile.pressed ? Bulan.motionPressMs : Bulan.motionFocusMs
                easing.type: tile.pressed ? Easing.OutCubic : Easing.OutBack
                easing.overshoot: Bulan.motionOvershoot
            }
        }
        scale: interactionScale

        // --- fallback: surface + title -----------------------------------------
        // Drawn first so it sits under the artwork and shows through while the
        // artwork is loading, missing, or detected as a GFE/Sunshine placeholder.
        // This is upstream's own fallback behaviour, drawn properly rather than
        // the mockup's diagonal-stripe annotation.
        Text {
            id: fallbackText
            anchors.fill: parent
            anchors.margins: Bulan.spaceMd
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 4
            text: tile.gameName
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeBody

            opacity: art.showArt ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
            }
        }

        // Mask shape for the artwork below: same rect, same radius, never drawn
        // itself -- MultiEffect samples it as a stencil.
        //
        // layer.enabled is what makes this work and its absence is silent. A
        // MultiEffect maskSource must be a TEXTURE PROVIDER, and a plain
        // Rectangle is not one; without the layer the effect samples nothing,
        // masks the artwork away entirely, and the tile draws empty -- with no
        // warning in the log and the fallback ALSO hidden, because as far as
        // the fallback is concerned the image loaded fine. That is exactly how
        // it failed the first time it was pointed at a real host: real names,
        // real art on disk, and twenty-five blank rectangles.
        Rectangle {
            id: artMask
            anchors.fill: parent
            anchors.margins: artRect.artInset
            radius: Bulan.radiusMd
            visible: false
            layer.enabled: true
        }

        // The artwork sits inside the border rather than under it. Box art
        // reaches its own edges -- almost all of it is a full-bleed poster --
        // so drawn edge to edge it paints straight over the focus ring and the
        // focused tile becomes indistinguishable from its neighbours. Which is
        // the one thing a focus ring cannot afford to be.
        //
        // A constant inset, not the live border width: tying it to the border
        // would shift and rescale every pixel of the artwork each time focus
        // arrived, which reads as the picture flinching.
        readonly property int artInset: 2

        Image {
            id: art
            anchors.fill: parent
            anchors.margins: artRect.artInset
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: tile.boxart

            // Deliberately NO explicit sourceSize. Binding one would make Qt
            // decode to (and report back) the requested size rather than the
            // source's true pixel dimensions -- and isPlaceholder below depends
            // on reading the image's real, undistorted size to preserve
            // upstream's exact-pixel-match check. Sunshine/GFE box art is not
            // large photography, so the memory cost of decoding at native size
            // is low; flagged in the stage-2 report as a deliberate deviation
            // from "set an appropriate sourceSize" rather than a silent skip.

            // Upstream's placeholder check (AppView.qml pre-rebuild, GFE 2.0 /
            // 3.0 placeholder images and this repo's own no_app_image.png),
            // preserved exactly: gated off for app-collector games, since the
            // one known exception (Overcooked) has real art at one of these
            // sizes.
            readonly property bool isPlaceholder:
                !tile.appCollectorGame && status === Image.Ready &&
                ((sourceSize.width === 130 && sourceSize.height === 180) ||
                 (sourceSize.width === 628 && sourceSize.height === 888) ||
                 (sourceSize.width === 200 && sourceSize.height === 266))

            readonly property bool showArt: status === Image.Ready && !isPlaceholder

            opacity: showArt ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }
        }
    }

    // --- the label block ---------------------------------------------------
    // Fixed to the tile's UNSCALED bottom edge, deliberately NOT to its drawn
    // edge the way HostTile.qml's label follows its circle.
    //
    // That difference is the difference between a carousel and a grid. On the
    // carousel a tile is alone on its own line, so a label that tracks the
    // drawn edge reads as belonging to it. Here five tiles sit side by side and
    // their labels form a visible row: letting the focused one drop by the few
    // pixels the 1.04 focus scale adds would break that row every time the
    // selection moved, and the eye reads a ragged baseline long before it reads
    // a tile being slightly larger.
    //
    // So the focus scale grows the artwork over the gap instead of pushing the
    // label down. Bulan.spaceMd is wider than the scale can consume.
    Row {
        id: labelRow
        anchors.top: artRect.bottom
        anchors.topMargin: Bulan.spaceMd
        anchors.horizontalCenter: parent.horizontalCenter
        width: tile.tileWidth
        spacing: Bulan.spaceXs

        // Gives way to "Running" rather than pushing it off the tile: its width
        // is capped to what's left after the running label when running is
        // true, so it elides instead of overflowing.
        Text {
            id: titleText
            elide: Text.ElideRight
            width: tile.running
                   ? (labelRow.width - runningText.width - labelRow.spacing)
                   : labelRow.width
            text: tile.gameName
            color: tile.isCurrent ? Bulan.textPrimary : Bulan.textSecondary
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeLabel
        }

        Text {
            id: runningText
            visible: tile.running
            text: qsTr("Running")
            color: Bulan.statusSuccess
            font.family: Bulan.familyUi
            font.pixelSize: Bulan.sizeLabel
        }
    }
}
