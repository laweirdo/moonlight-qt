import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Effects

import Bulan 1.0
import ComputerManager 1.0
import AutoUpdateChecker 1.0
import StreamingPreferences 1.0
import SystemProperties 1.0
import SdlGamepadKeyNavigation 1.0

ApplicationWindow {
    property bool pollingActive: false

    // Set by SettingsShell before a retranslate, to force the back operation to
    // pop every page except the initial view -- AppView does not survive one.
    // Inherited from upstream's SettingsView, which is gone; the shell copied
    // the workaround and is now its only writer.
    property bool clearOnBack: false

    id: window
    width: 1280
    height: 800

    // --- Bulan design system ------------------------------------------------
    // Faces are bundled static instances (see resources.qrc). Loading them here
    // makes them available to every view in the app.
    FontLoader { source: "qrc:/fonts/Inter-Regular.ttf" }
    FontLoader { source: "qrc:/fonts/Inter-Medium.ttf" }
    FontLoader { source: "qrc:/fonts/Inter-SemiBold.ttf" }
    FontLoader { source: "qrc:/fonts/Fraunces-Regular.ttf" }

    // Inherited by every child control unless overridden.
    font.family: Bulan.familyUi
    font.pixelSize: Bulan.sizeLabel
    // Medium is the body weight everywhere -- see Bulan.weightBody. Inherited
    // by every control unless it overrides, so a Text that says nothing about
    // weight is already right.
    font.weight: Bulan.weightBody

    // Drive the Material style from the tokens so stock controls (buttons,
    // combo boxes, switches, dialogs, scrollbars) come out in Bulan colours
    // without restyling each one by hand.
    Material.theme: Material.Dark
    Material.background: Bulan.bgBase
    Material.foreground: Bulan.textPrimary
    Material.accent: Bulan.accentPrimary
    Material.primary: Bulan.bgSurface

    color: Bulan.gradientBaseTop

    // --- window-level modals -------------------------------------------------
    // The one place the app asks "is a window modal up". Two unrelated things
    // need the answer -- the scene's popup blur and the shared hint bar -- and
    // they used to keep two copies of the same list of dialogs, which is two
    // places to forget a sixth one. The hint bar needs the dialog itself, not
    // just a yes or no, so the owner is what is resolved and the boolean is
    // derived from it.
    //
    // Resolved in the order they stack; the quit confirmation is above
    // everything.
    readonly property var windowModalOwner: {
        if (quitConfirmationDialog.visible) return quitConfirmationDialog
        if (noHwDecoderDialog.visible) return noHwDecoderDialog
        if (xWaylandDialog.visible) return xWaylandDialog
        if (wow64Dialog.visible) return wow64Dialog
        if (unmappedGamepadDialog.visible) return unmappedGamepadDialog
        return null
    }
    readonly property bool windowModalOpen: windowModalOwner !== null

    // This function runs prior to creation of the initial StackView item
    function doEarlyInit() {
        // Override the background color to Material 2 colors for Qt 6.5+
        // in order to improve contrast between GFE's placeholder box art
        // and the background of the app grid.
        // Upstream forces a grey here for Material 3; Bulan sets its own
        // ground above, so leave it alone.

        SdlGamepadKeyNavigation.enable()
    }

    Component.onCompleted: {
        // Show the window according to the user's preferences
        if (SystemProperties.hasDesktopEnvironment) {
            if (StreamingPreferences.uiDisplayMode == StreamingPreferences.UI_MAXIMIZED) {
                window.showMaximized()
            }
            else if (StreamingPreferences.uiDisplayMode == StreamingPreferences.UI_FULLSCREEN) {
                window.showFullScreen()
            }
            else {
                window.show()
            }
        } else {
            window.showFullScreen()
        }

        // Display any modal dialogs for configuration warnings
        if (runConfigChecks) {
            if (SystemProperties.isWow64) {
                wow64Dialog.open()
            }

            // Hardware acceleration and unmapped gamepads are checked asynchronously
            SystemProperties.hasHardwareAccelerationChanged.connect(hasHardwareAccelerationChanged)
            SystemProperties.unmappedGamepadsChanged.connect(hasUnmappedGamepadsChanged)
            SystemProperties.startAsyncLoad()
        }
    }

    function hasHardwareAccelerationChanged() {
        if (!SystemProperties.hasHardwareAcceleration && StreamingPreferences.videoDecoderSelection !== StreamingPreferences.VDS_FORCE_SOFTWARE) {
            if (SystemProperties.isRunningXWayland) {
                xWaylandDialog.open()
            }
            else {
                noHwDecoderDialog.open()
            }
        }
    }

    function hasUnmappedGamepadsChanged() {
        if (SystemProperties.unmappedGamepads) {
            unmappedGamepadDialog.unmappedGamepads = SystemProperties.unmappedGamepads
            unmappedGamepadDialog.open()
        }
    }

    // It would be better to use TextMetrics here, but it always lays out
    // the text slightly more compactly than real Text does in ToolTip,
    // causing unexpected line breaks to be inserted
    Text {
        id: tooltipTextLayoutHelper
        visible: false
        font: ToolTip.toolTip.font
        text: ToolTip.toolTip.text
    }

    // This configures the maximum width of the singleton attached QML ToolTip. If left unconstrained,
    // it will never insert a line break and just extend on forever.
    ToolTip.toolTip.contentWidth: Math.min(tooltipTextLayoutHelper.width, 400)

    function goBack() {
        if (clearOnBack) {
            // Pop all items except the first one
            stackView.pop(null)
            clearOnBack = false
        }
        else {
            stackView.pop()
        }
    }

    // Debug hook: MOONLIGHT_SCREENSHOT=<path> grabs the window once the UI has
    // settled and exits. Lets the design be checked without Screen Recording
    // permission. Inert unless the variable is set.
    Timer {
        // Phase 1: pin the window to the Deck's panel size, so the grab is laid
        // out at the size the design targets rather than whatever the offscreen
        // platform happened to pick.
        //
        // MOONLIGHT_SCREENSHOT_DELAY_MS extends the wait. 2500 plus shotTimer's
        // 1500 is four seconds, which is enough for any screen that draws from
        // state the app already has. It is not enough for one that has to wait
        // on the network: a saved host is loaded OFFLINE and only reports itself
        // reachable when the discovery poll answers, so a grab of the game grid
        // for a real host lands on the carousel instead. Zero unless set, so
        // every existing review recipe times exactly as before.
        interval: 2500 + screenshotDelayMs
        running: screenshotPath !== ""
        onTriggered: {
            window.showNormal()
            // MOONLIGHT_SCREENSHOT_WIDTH/_HEIGHT review the same composition at
            // another viewport. Both default to the design frame, so every
            // recipe written before the app could be scaled grabs exactly what
            // it always did.
            window.width = screenshotWidth > 0 ? screenshotWidth : Bulan.designWidth
            window.height = screenshotHeight > 0 ? screenshotHeight : Bulan.designHeight
            shotTimer.start()
        }
    }

    Timer {
        id: shotTimer
        interval: 1500
        onTriggered: {
            // The window root is a QQuickRootItem with no QML engine, so it
            // cannot be grabbed. Capture the content item instead. This used to
            // take a second image of the toolbar, which no longer exists.
            var ok = contentCapture.grabToImage(function(res) {
                res.saveToFile(screenshotPath)
                Qt.quit()
            })
            // grabToImage returns false if the item cannot be rendered; quit
            // regardless so a failed grab never hangs the run.
            if (!ok) {
                console.log("screenshot: grabToImage refused")
                Qt.quit()
            }
        }
    }

    // Screenshot surface includes the retained navigation stack and the
    // top-level launch proxy. The toolbar remains a separate capture because
    // ApplicationWindow lays its header outside the content item.
    Item {
        id: contentCapture
        anchors.fill: parent

        // --- the scene ---------------------------------------------------------
        // The whole composed world: the persistent atmosphere and every screen
        // drawn over it. It exists to be one blur target. A modal blurs the
        // scene it interrupts, and that scene is the background as much as the
        // screen -- so the effect belongs here, above both, rather than on the
        // StackView, which is only the screens.
        //
        // The window modals themselves are NOT in here. They are in
        // overlayFrame below, for the obvious reason that a panel cannot blur
        // the picture it is sitting on if it is part of that picture.
        //
        // Gated on visibility, so a settled screen with nothing open carries no
        // layer and no effect at all. Strength and radius are the same popup
        // backdrop tokens this blur has always used.
        Item {
            id: sceneRoot
            z: 0
            anchors.fill: parent

            layer.enabled: window.windowModalOpen
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: Bulan.popupBackdropBlurStrength
                blurMax: Bulan.popupBackdropBlurRadius
            }

            // --- the world ------------------------------------------------
            // The one atmosphere in the application. Every screen used to draw
            // its own copy inside the StackView, which meant the background
            // travelled, faded and blurred with whatever screen was moving:
            // the whole picture slid, rather than the screens sliding over a
            // world that stays put (client decision, 20 August 2026). Routes
            // are transparent now and this is what is underneath all of them,
            // so a transition can never expose a bare stack.
            //
            // It is also what fills the band down each side of a window wider
            // than 16:10, which no screen reaches. The frame below is always
            // full height -- its scale is limited by whichever axis is tighter
            // and 16:10 is the widest composition -- so nothing can leave a
            // seam across this.
            //
            // A future ambient gradient movement animates this item and only
            // this item. Nothing here implements one.
            Atmosphere {
                anchors.fill: parent
            }

            // --- the design frame ---------------------------------------------
            // Every Bulan screen is drawn against Bulan.designWidth x
            // designHeight and nothing inside this item ever asks how large the
            // window is. This lays that composition out at its true size and
            // scales it to fit, so a 4K window gets the same picture as the
            // Deck, larger -- never more grid columns, never a re-flow (client
            // decision, 16 August 2026).
            //
            // A scale on the frame rather than a scale factor threaded through
            // every measurement: the scene graph applies it to the whole
            // subtree, so text and shapes re-render at the window's real
            // resolution rather than being magnified, and input coordinates map
            // back through it for free. The one thing it does NOT re-render is
            // an item that rasterises itself into a texture (layer.enabled) --
            // those hold their own resolution and are magnified, which is why
            // the artwork layer in GameTile.qml sizes its texture against this
            // scale.
            //
            // Its children are declared below rather than nested inside it,
            // each naming this item as its `parent`. They were already siblings
            // of one another for reasons their own comments give -- the hint
            // bar and the launch proxy must not inherit the StackView's
            // transition opacity -- and re-nesting three hundred lines to move
            // them one level down would have buried that reasoning in an
            // indentation change.
            // Every child names its own `z`. Declaration order is what normally
            // stacks siblings, and it stops meaning anything once the children
            // arrive by reassigning `parent` -- Qt adds them in whatever order
            // those bindings happen to be evaluated, which put the hint bar
            // underneath an opaque screen and made it disappear. Stated
            // outright, in the order they paint: screens, mark, launch proxy,
            // hint bar. The window's own panels are above all of it and above
            // this whole scene, in overlayFrame.
            Item {
                id: designFrame
                anchors.centerIn: parent
                width: Bulan.designWidth
                height: Bulan.designHeight
                transformOrigin: Item.Center
                scale: Math.min(parent.width / width, parent.height / height)
            }
        }

        // The design frame again, above the scene rather than inside it, for
        // the window modals alone. They are laid out in design coordinates like
        // everything else and must scale with the composition, but they must
        // not be part of what they blur. Same geometry, same scale, taken
        // straight off designFrame so the two can never drift apart.
        //
        // Nothing else belongs up here. The onboarding mark, the launch proxy
        // and the hint bar are all foreground content, and a modal is meant to
        // blur the complete composed scene -- background, screens and all three
        // of those.
        Item {
            id: overlayFrame
            z: 1
            anchors.centerIn: parent
            width: designFrame.width
            height: designFrame.height
            transformOrigin: Item.Center
            scale: designFrame.scale
        }

        StackView {
            id: stackView
            parent: designFrame
            z: 0
            anchors.fill: parent
        focus: true
        enabled: !quitConfirmationDialog.visible
        // Navigation blur, and only navigation blur. This layer covers the
        // screens; it does not cover the world they move over, which is the
        // whole point of the split (client decision, 20 August 2026). The other
        // scope -- a modal blurring the complete scene, background included --
        // belongs to sceneRoot above.
        //
        // `busy` is StackView's own signal that a push/pop transition is
        // currently animating, so this leaves nothing enabled -- no layer, no
        // effect, no cost -- the instant a screen settles (client override,
        // 2 August 2026 review: real blur during the transition, on top of the
        // existing opacity falloff, accepting the Deck performance cost).
        //
        // Stood down while a modal is up. The two scopes are nested -- this
        // layer is inside sceneRoot's -- so leaving both on would blur the
        // screens twice, at two different strengths, for the one case where a
        // dialog happens to open mid transition. The modal wins; when it
        // closes, this returns to following `busy` on its own.
        layer.enabled: stackView.busy && !window.windowModalOpen
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: Bulan.motionTransitionBlurStrength
            blurMax: Bulan.motionTransitionBlurRadius
        }

        // Ordinary screen navigation, brief §6 "Screen transition": content
        // surfaces vertically over Bulan.motionTransitionMs, ease-out with no
        // overshoot (Easing.OutCubic; motionOvershoot belongs to focus motion,
        // not this). The opacity falloff below was originally the whole of
        // the "slight motion blur" reading; the layer.enabled/layer.effect
        // pair above now adds genuine blur on top of it, gated to the
        // transition's own `busy` window (client override, 2 August 2026).
        // Push and pop are exact mirrors of each other so forward and back
        // read as one reversible movement. Declared once here per the
        // accepted decision that no per-screen route may attach its own
        // animation.
        // replaceEnter/replaceExit are deliberately left at their implicit
        // immediate default so StreamSegue.qml's existing replace is
        // unaffected.
        //
        // Only y and opacity are animated, and every enter transition drives
        // both to their resting values (0 and 1) with an explicit `from`, so
        // it never inherits whatever mid-flight value the item happened to
        // hold. StackView finishes an in-flight transition immediately when a
        // new operation arrives rather than abandoning it part-way, which is
        // what keeps rapid B/A input from stranding a screen at an
        // in-between offset or a partial opacity.
        //
        // The two do not share a duration: the fade runs at
        // motionTransitionFadeMs and finishes first, so the tail of the
        // movement is pure travel at full opacity. See that token in Bulan.qml
        // for why the fade is shortened rather than removed.
        pushEnter: Transition {
            NumberAnimation {
                property: "y"
                from: Bulan.motionTransitionRise
                to: 0
                duration: Bulan.motionTransitionMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Bulan.motionTransitionFadeMs
                easing.type: Easing.OutCubic
            }
        }

        pushExit: Transition {
            NumberAnimation {
                property: "y"
                from: 0
                to: -Bulan.motionTransitionRise
                duration: Bulan.motionTransitionMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Bulan.motionTransitionFadeMs
                easing.type: Easing.OutCubic
            }
        }

        popEnter: Transition {
            NumberAnimation {
                property: "y"
                from: -Bulan.motionTransitionRise
                to: 0
                duration: Bulan.motionTransitionMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Bulan.motionTransitionFadeMs
                easing.type: Easing.OutCubic
            }
        }

        popExit: Transition {
            NumberAnimation {
                property: "y"
                from: 0
                to: Bulan.motionTransitionRise
                duration: Bulan.motionTransitionMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Bulan.motionTransitionFadeMs
                easing.type: Easing.OutCubic
            }
        }

        // No background. There used to be a gradient here, covering the band of
        // bare stack that shows during a vertical transition while one screen
        // has risen and the next has not yet landed. The persistent atmosphere
        // in sceneRoot is behind every screen now, at every moment, so there is
        // nothing left for a second ground to cover.
        //
        // What the screens' own copies also did was hide the outgoing screen
        // during that travel. Transparent routes do not, so for the length of
        // motionTransitionFadeMs both screens' content is faintly visible at
        // once. That is the accepted shape of the approved design -- foreground
        // content keeps the opacity behaviour it always had, over a world that
        // no longer moves with it -- not an oversight.

        Component.onCompleted: {
            // Perform our early initialization before constructing
            // the initial view and pushing it to the StackView
            doEarlyInit()
            // There is nothing on screen to transition from yet, so this
            // first push must not animate (accepted decision 8).
            push(initialView, StackView.Immediate)
        }

        onCurrentItemChanged: {
            // Ensure focus travels to the next view when going back
            if (currentItem) {
                currentItem.forceActiveFocus()
            }
        }

        Keys.onEscapePressed: {
            if (depth > 1) {
                goBack()
            }
            else {
                quitConfirmationDialog.open()
            }
        }

        Keys.onBackPressed: {
            if (depth > 1) {
                goBack()
            }
            else {
                quitConfirmationDialog.open()
            }
        }

        // These three used to press an invisible toolbar button to get here.
        // The toolbar is gone, so they navigate directly.
        Keys.onMenuPressed: {
            navigateTo("qrc:/gui/SettingsShell.qml", SettingsShell)
        }

        // This is a keypress we've reserved for letting the
        // SdlGamepadKeyNavigation object tell us to show settings
        // when Menu is consumed by a focused control. Start sends it.
        Keys.onHangupPressed: {
            navigateTo("qrc:/gui/SettingsShell.qml", SettingsShell)
        }

        // Y, which used to share Key_Hangup with Start. Handled here too so Y
        // still opens settings on every screen that does not claim it first --
        // the host carousel claims it for Wake.
        Keys.onCallPressed: {
            navigateTo("qrc:/gui/SettingsShell.qml", SettingsShell)
        }
        }

        // Frozen selected-game artwork above the retained AppView and every
        // pushed segue. It is a sibling of StackView so source mapping includes
        // all nested transforms while the proxy itself inherits none of them.
        LaunchTransition {
            id: launchTransition
            parent: designFrame
            z: 2
            anchors.fill: parent

            onProxyReady: if (owner) owner.launchTransitionProxyReady()
            onFinished: if (owner) owner.launchTransitionFinished()
            onFailed: if (owner) owner.launchTransitionFailed()
        }

        // --- the onboarding mark ------------------------------------------
        // The crescent on the first-run and discovery screens. One Image, at
        // the window, rather than one per screen.
        //
        // Both screens draw it centred, and the client's requirement is that
        // crossing between them moves that one mark rather than dissolving one
        // and raising another, while everything else takes the ordinary screen
        // blur and fade. A StackView child cannot opt out of its parent's
        // transition -- the blur in particular is applied to the whole stack --
        // so the only thing that stays sharp is something that was never in
        // the stack. That is the same reasoning the launch proxy above and the
        // hint bar below already follow.
        //
        // Because it never leaves, there is no handoff to get wrong: no proxy
        // to strand visible, no screen left with its own mark hidden, nothing
        // to cancel if a transition is interrupted. It simply moves to wherever
        // the current screen says its mark belongs.
        //
        // A screen joins in by declaring onboardingMarkY. One that does not --
        // every other screen in the app -- gets no mark, exactly as it gets no
        // hint bar by not declaring hintBarVisible.
        Image {
            id: onboardingMark
            parent: designFrame
            z: 1
            source: "qrc:/res/bulan_logomark.svg"
            width: Bulan.onboardingMarkSize
            height: width
            fillMode: Image.PreserveAspectFit
            sourceSize.width: width * 2
            sourceSize.height: width * 2
            smooth: true

            x: (parent.width - width) / 2

            readonly property var markScreen: {
                var screen = stackView.currentItem
                return screen && screen.onboardingMarkY !== undefined ? screen : null
            }

            // NaN while no screen wants a mark, which is what makes the
            // assignment below hold the last real position instead of dropping
            // the mark to the top of the frame as it fades out.
            readonly property real slotY:
                markScreen ? markScreen.onboardingMarkY : NaN
            onSlotYChanged: if (!isNaN(slotY)) y = slotY

            // The screen transition's own clock and curve, so the mark crosses
            // in step with the screens moving underneath it. Off while the
            // mark cannot be seen, so its first placement is a position rather
            // than a journey from the top of the frame.
            Behavior on y {
                enabled: onboardingMark.visible
                NumberAnimation {
                    duration: Bulan.motionTransitionMs
                    easing.type: Easing.OutCubic
                }
            }

            // 0 before the mark belongs anywhere, 1 while it does. One value
            // carries both the fade and the rise, the same shape and the same
            // tokens EntranceMotion gives a screen's own content -- written
            // out here rather than instantiated because this element's arrival
            // is driven by the stack rather than by one screen's settle, and
            // EntranceMotion starts on an edge it would never see.
            opacity: present
            visible: opacity > 0.01
            transform: Translate {
                y: (1 - onboardingMark.present) * Bulan.motionGridEntranceRise
            }

            property real present: 0
            Behavior on present {
                NumberAnimation {
                    duration: Bulan.motionGridEntranceRiseMs
                    easing.type: Easing.OutBack
                    easing.overshoot: Bulan.motionEntranceOvershoot
                }
            }

            // Rises in once the screen it belongs to has stopped travelling --
            // arriving under a moving screen is the one thing every entrance
            // in this app avoids. Crucially it does NOT drop back while the
            // stack is busy: crossing from one onboarding screen to the other
            // leaves this at 1 throughout, which is what makes the mark one
            // continuous object rather than a fade out and a fade in.
            function updatePresent() {
                if (!markScreen) {
                    present = 0
                } else if (present > 0 || !stackView.busy) {
                    present = 1
                }
            }
            onMarkScreenChanged: updatePresent()
            Component.onCompleted: updatePresent()
            Connections {
                target: stackView
                function onBusyChanged() { onboardingMark.updatePresent() }
            }
        }

        // Window-level hint bar, sibling of stackView for exactly the reason
        // LaunchTransition above is: a child cannot opt out of its parent's
        // stack-transition opacity, and nothing about this bar should move
        // or fade with the screen (client decision, 2 August 2026 review --
        // "nothing about it changes between the carousel and the grid except
        // its labels"). HostCarousel.qml and AppView.qml no longer draw
        // their own; they expose hintBarVisible/hintLeftHints/hintRightHints
        // instead, and this single bar reads whichever one is current.
        //
        // Screens that never had a hint bar -- settings, the segues, CLI
        // routes, the token/glyph proofs -- simply don't define these
        // properties, so `currentItem.hintBarVisible === true` is false
        // (undefined) for all of them and this bar stays hidden there,
        // exactly as before.
        // Shared scene furniture, under designFrame with the screens, the mark
        // and the launch proxy. It is part of the composed picture, so a modal
        // blurs it along with everything else it interrupts (client decision,
        // 20 August 2026); only the window-modal panels themselves stand
        // outside that picture, in overlayFrame.
        HintBar {
            id: sharedHintBar
            parent: designFrame
            z: 3
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            // Whoever owns the input owns the hints. Three things could be that
            // owner and they are resolved in the order they stack: a window
            // modal, which is parented above everything; whichever popup the
            // current screen reports as open; and otherwise the screen itself.
            //
            // The window modals -- the quit confirmation and the startup
            // configuration warnings -- are not in any screen's hintOwner
            // chain, so they have to be asked about separately. Each carries
            // its hints inside its own card, so naming one as the owner is what
            // takes the screen's bar off the screen beneath it. That list lives
            // once, on the window, as windowModalOwner.
            //
            // Popups used to draw hint bars of their own, so a second bar
            // appeared over the first and every screen had to remember to
            // suppress its own -- "A Select" printing over "A Connect". Some
            // screens remembered and some did not. Now there is one bar, and a
            // popup that wants no hints (HostPanel, which carries its own in
            // its card) simply says so.
            readonly property var owner: {
                if (window.windowModalOwner) {
                    return window.windowModalOwner
                }
                var screen = stackView.currentItem
                if (!screen) {
                    return null
                }
                return screen.hintOwner ? screen.hintOwner : screen
            }

            visible: owner !== null && owner !== undefined
                     && owner.hintBarVisible === true

            leftHints: visible ? owner.hintLeftHints : []
            rightHints: visible ? owner.hintRightHints : []
        }
    }

    // This timer keeps us polling for 5 minutes of inactivity
    // to allow the user to work with Moonlight on a second display
    // while dealing with configuration issues. This will ensure
    // machines come online even if the input focus isn't on Moonlight.
    Timer {
        id: inactivityTimer
        interval: 5 * 60000
        onTriggered: {
            if (!active && pollingActive) {
                ComputerManager.stopPollingAsync()
                pollingActive = false
            }
        }
    }

    onVisibleChanged: {
        // When we become invisible while streaming is going on,
        // stop polling immediately.
        if (!visible) {
            inactivityTimer.stop()

            if (pollingActive) {
                ComputerManager.stopPollingAsync()
                pollingActive = false
            }
        }
        else if (active) {
            // When we become visible and active again, start polling
            inactivityTimer.stop()

            // Restart polling if it was stopped
            if (!pollingActive) {
                ComputerManager.startPolling()
                pollingActive = true
            }
        }

        // Poll for gamepad input only when the window is in focus
        SdlGamepadKeyNavigation.notifyWindowFocus(visible && active)
    }

    onActiveChanged: {
        if (active) {
            // Stop the inactivity timer
            inactivityTimer.stop()

            // Restart polling if it was stopped
            if (!pollingActive) {
                ComputerManager.startPolling()
                pollingActive = true
            }
        }
        else {
            // Start the inactivity timer to stop polling
            // if focus does not return within a few minutes.
            inactivityTimer.restart()
        }

        // Poll for gamepad input only when the window is in focus
        SdlGamepadKeyNavigation.notifyWindowFocus(visible && active)
    }

    function navigateTo(url, objectType)
    {
        var existingItem = stackView.find(function(item, index) {
            return item instanceof objectType
        })

        if (existingItem !== null) {
            // Pop to the existing item
            stackView.pop(existingItem)
        }
        else {
            // Create a new item
            stackView.push(url)
        }
    }

    // The inherited toolbar is gone. It was upstream's chrome, kept intact
    // through the fork so a rebase stayed easy, and hidden by every Bulan
    // screen in turn -- nineteen imperative `toolBar.visible` writes plus a
    // Qt.callLater backstop to correct the ones that got it wrong. The two
    // screens that actually wanted it, SettingsView and PcView, are gone with
    // it. Bulan screens carry their own header and the window carries one hint
    // bar, which is what this replaced it with in the first place.
    //
    // What went with it: the version label and the Discord community link,
    // both of which only ever appeared on upstream's settings screen. The
    // version is on the About page; the Discord link pointed at Moonlight's
    // community, and Bulan credits its upstream in About instead (client
    // decision, 15 August 2026). The Help and Gamepad Mapper buttons were an
    // upstream wiki link and a permanently hidden stub.
    // The update check is deliberately not started, and the button it would
    // have revealed went with the toolbar. It compared this build's version
    // against Moonlight's own release feed, and Bulan's version is its own
    // (0.0.1), not a point on that feed's timeline -- so the check would have
    // reported an "update" to Moonlight 6.1.0 forever, and clicking through
    // would have sent the player to a different application's download page.
    // The receiver survives because main.cpp still connects to it.
    QtObject {
        id: updateButton

        function updateAvailable(version, url)
        {
        }
    }

    // --- configuration warnings ----------------------------------------------
    // Raised once at startup when the machine cannot do something Bulan expects.
    // Bulan panels rather than the stock Dialogs these replaced: a stock Dialog
    // lives in Qt's own overlay layer, which is a second stacking system this
    // application does not otherwise use -- it painted over the hint bar and
    // brought Material buttons with it.
    //
    // The Help buttons are gone with them. They opened a moonlight-docs wiki
    // page in a browser, and the target device has no browser to open (client
    // decision, 15 August 2026).
    //
    // **The copy below is upstream's, unchanged, and is the client's to
    // rewrite.** It names XWayland, a display protocol and a decoder API on a
    // front-facing screen, which the creative brief forbids. It is left exactly
    // as upstream wrote it rather than replaced with a placeholder, because a
    // placeholder is a thing that ships by accident. Tracked in TASK-BRIEF.md.

    HostPanel {
        id: noHwDecoderDialog
        // overlayFrame, not designFrame: the same composition and the same
        // scale, but above the scene these panels blur rather than inside it.
        parent: overlayFrame
        z: 4
        anchors.fill: parent
        // Deferred, not direct. HostPanel.close() emits dismissed() and THEN
        // calls parent.forceActiveFocus() itself -- which is right for a panel
        // parented to a screen, and wrong for these four, whose parent is the
        // window's design frame and runs no key handlers. A synchronous handler
        // here is overwritten by that trailing call and the gamepad is left
        // navigating nothing. callLater runs on the next pass, after it.
        onDismissed: Qt.callLater(function() { stackView.forceActiveFocus() })
        function open() {
            show("", qsTr("No functioning hardware accelerated video decoder was detected by Moonlight. " +
                          "Your streaming performance may be severely degraded in this configuration."))
        }
    }

    HostPanel {
        id: xWaylandDialog
        parent: overlayFrame
        z: 4
        anchors.fill: parent
        // Deferred, not direct. HostPanel.close() emits dismissed() and THEN
        // calls parent.forceActiveFocus() itself -- which is right for a panel
        // parented to a screen, and wrong for these four, whose parent is the
        // window's design frame and runs no key handlers. A synchronous handler
        // here is overwritten by that trailing call and the gamepad is left
        // navigating nothing. callLater runs on the next pass, after it.
        onDismissed: Qt.callLater(function() { stackView.forceActiveFocus() })
        function open() {
            show("", qsTr("Hardware acceleration doesn't work on XWayland. Continuing on XWayland may result in poor streaming performance. " +
                          "Try running with QT_QPA_PLATFORM=wayland or switch to X11."))
        }
    }

    HostPanel {
        id: wow64Dialog
        parent: overlayFrame
        z: 4
        anchors.fill: parent
        // The one config warning with something to agree to, so it is the one
        // that offers a confirm rather than only a way out. The confirm's
        // wording is the client's, like the message itself; until then it keeps
        // the panel's default.
        confirmable: true
        // Deferred, not direct. HostPanel.close() emits dismissed() and THEN
        // calls parent.forceActiveFocus() itself -- which is right for a panel
        // parented to a screen, and wrong for these four, whose parent is the
        // window's design frame and runs no key handlers. A synchronous handler
        // here is overwritten by that trailing call and the gamepad is left
        // navigating nothing. callLater runs on the next pass, after it.
        onDismissed: Qt.callLater(function() { stackView.forceActiveFocus() })
        onAccepted: Qt.openUrlExternally("https://github.com/moonlight-stream/moonlight-qt/releases")
        function open() {
            show("", qsTr("This version of Moonlight isn't optimized for your PC. Please download the '%1' version of Moonlight for the best streaming performance.")
                         .arg(SystemProperties.friendlyNativeArchName))
        }
    }

    HostPanel {
        id: unmappedGamepadDialog
        parent: overlayFrame
        z: 4
        anchors.fill: parent
        property string unmappedGamepads: ""
        // Deferred, not direct. HostPanel.close() emits dismissed() and THEN
        // calls parent.forceActiveFocus() itself -- which is right for a panel
        // parented to a screen, and wrong for these four, whose parent is the
        // window's design frame and runs no key handlers. A synchronous handler
        // here is overwritten by that trailing call and the gamepad is left
        // navigating nothing. callLater runs on the next pass, after it.
        onDismissed: Qt.callLater(function() { stackView.forceActiveFocus() })
        function open() {
            show("", qsTr("Moonlight detected gamepads without a mapping:") + "\n\n" + unmappedGamepads)
        }
    }

    // This dialog appears when quitting via keyboard or gamepad button
    BulanQuitConfirmation {
        id: quitConfirmationDialog
        parent: overlayFrame
        z: 4
        anchors.fill: parent
        onDismissed: {
            if (stackView.currentItem) {
                stackView.currentItem.forceActiveFocus()
            } else {
                stackView.forceActiveFocus()
            }
        }
        onQuitRequested: Qt.quit()
    }

    // The Add PC dialog went with the toolbar button that was its only opener.
    // Adding a PC by hand lives on the Bulan screens: HostDiscovery's "Enter an
    // address instead", and the carousel's Add a PC, both of which raise
    // HostPanel and call the same ComputerManager.addNewHostManually().
}
