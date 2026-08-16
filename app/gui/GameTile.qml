import QtQuick 2.9
// MultiEffect only, for masking the artwork to the tile's rounded rectangle --
// same module HostCarousel.qml and main.qml already use for the popup blur.
// Not a Qt Quick Control; nothing here is a stock visual control.
import QtQuick.Effects
// For the Window attached property only -- see uiScale below. No window or
// stock control is instantiated here.
import QtQuick.Window 2.2

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
//
// Nothing is drawn under the artwork. The title and the "Running" label that
// used to sit there were removed on the client's instruction of 16 August 2026:
// box art names its own game, and a row of captions under a grid of posters is
// the app repeating what the picture already says. The name survives inside the
// artwork rectangle, where it is the fallback for a game whose art is missing --
// which is the only case where the picture cannot speak for itself.
// -----------------------------------------------------------------------------

Item {
    id: tile

    property string gameName: ""
    property var appId: null
    property url boxart: ""
    property bool running: false
    property bool isCurrent: false
    property bool launchSourceHidden: false
    property bool launchMotionFreezeRequested: false
    property bool launchMotionFrozen: false
    property real frozenLaunchInteractionScale: 1
    property real frozenLaunchBorderWidth: 1
    property color frozenLaunchBorderColor: Bulan.hairline
    property real frozenLaunchFallbackOpacity: 1
    property real frozenLaunchArtOpacity: 0

    function freezeLaunchMotion() {
        if (tile.launchMotionFrozen) {
            return
        }
        tile.frozenLaunchInteractionScale = artRect.interactionScale
        tile.frozenLaunchBorderWidth = artRect.border.width
        tile.frozenLaunchBorderColor = artRect.border.color
        tile.frozenLaunchFallbackOpacity = fallbackText.opacity
        tile.frozenLaunchArtOpacity = art.opacity
        tile.launchMotionFrozen = true
    }

    function releaseLaunchMotion() {
        tile.launchMotionFrozen = false
    }

    onLaunchMotionFreezeRequestedChanged: {
        if (launchMotionFreezeRequested) {
            freezeLaunchMotion()
        } else {
            releaseLaunchMotion()
        }
    }
    Component.onCompleted: {
        if (launchMotionFreezeRequested) {
            freezeLaunchMotion()
        }
    }

    // Stage 2 captures this exact rendered item once. It contains the focus
    // ring, rounded art/mask, and fallback, while excluding the Library/Recent
    // label treatments that do not travel into launch.
    property alias launchCaptureItem: artRect

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
    height: tile.tileHeight

    // How much larger than its design size the window is drawing this tile.
    // main.qml scales one 1280x800 frame to fit the window, and everything in
    // the subtree re-renders at the window's real resolution -- except an item
    // that rasterises itself into a texture first. The artwork below is one of
    // those, so without this its texture would be cut at design size and then
    // magnified, and a 4K library would show soft posters on a sharp screen.
    readonly property real uiScale: Math.min(Window.width / Bulan.designWidth,
                                             Window.height / Bulan.designHeight)

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
        opacity: tile.launchSourceHidden ? 0 : 1
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: tile.tileWidth
        height: tile.tileHeight
        radius: Bulan.radiusMd
        color: Bulan.bgSurface

        border.width: tile.launchMotionFrozen ? tile.frozenLaunchBorderWidth
                                              : (tile.isCurrent ? Bulan.focusRingWidth
                                                                : Bulan.hairlineWidth)
        border.color: tile.launchMotionFrozen ? tile.frozenLaunchBorderColor
                                              : (tile.isCurrent ? Bulan.accentPrimary
                                                                : Bulan.hairline)
        Behavior on border.color {
            enabled: !tile.launchMotionFrozen
            ColorAnimation { duration: Bulan.motionFocusMs }
        }

        transformOrigin: Item.Center

        // Same shape as HostTile.qml's interactionScale, and the same reason:
        // this is the only scale animated *here*. A caller driving travel (as
        // HostCarousel does for its tiles) would animate its own transform
        // separately rather than feed this Behavior a moving target.
        property real interactionScale:
            tile.launchMotionFrozen ? tile.frozenLaunchInteractionScale
                                    : (tile.pressed ? Bulan.motionPressScale
                                                    : (tile.isCurrent
                                                       ? Bulan.motionFocusScale : 1.0))
        Behavior on interactionScale {
            enabled: !tile.launchMotionFrozen
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

            opacity: tile.launchMotionFrozen ? tile.frozenLaunchFallbackOpacity
                                             : (art.showArt ? 0 : 1)
            Behavior on opacity {
                enabled: !tile.launchMotionFrozen
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
        // Only allocated while the artwork above is actually being masked. The
        // mask is a texture in its own right, so an always-on one costs a second
        // render target per tile for as long as the tile exists.
        Rectangle {
            id: artMask
            anchors.fill: parent
            anchors.margins: artRect.artInset
            radius: Bulan.radiusMd
            visible: false
            layer.enabled: art.showArt
            // Matched to the artwork's own texture below, so the corners the
            // mask rounds are cut at the resolution they are drawn at.
            layer.textureSize: Qt.size(Math.round(width * tile.uiScale),
                                       Math.round(height * tile.uiScale))
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

            opacity: tile.launchMotionFrozen ? tile.frozenLaunchArtOpacity
                                             : (showArt ? 1 : 0)
            Behavior on opacity {
                enabled: !tile.launchMotionFrozen
                NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
            }

            // Gated on there being artwork to mask. A tile whose art is missing,
            // still loading, or a known placeholder draws the fallback instead
            // and this Image is at zero opacity -- but an ungated layer still
            // allocates a render target and runs a masking pass every frame to
            // round the corners of something invisible. A library of mostly
            // artless games was paying full price for every one of them.
            layer.enabled: art.showArt
            layer.textureSize: Qt.size(Math.round(width * tile.uiScale),
                                       Math.round(height * tile.uiScale))
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }
        }
    }

}
