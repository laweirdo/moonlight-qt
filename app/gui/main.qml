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
            window.width = 1280
            window.height = 800
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

        StackView {
            id: stackView
            anchors.fill: parent
        focus: true
        enabled: !quitConfirmationDialog.visible
        // One layer, one effect, claimed by whichever of the two blur
        // callers is actually active -- they never overlap in practice
        // (the quit dialog opens over a settled screen, never mid
        // transition), and this OR keeps them from being able to fight
        // over the layer even if that ever changed. `busy` is StackView's
        // own signal that a push/pop transition is currently animating, so
        // this leaves nothing enabled -- no layer, no effect, no cost --
        // the instant a screen settles (client override, 2 August 2026
        // review: real blur during the transition, on top of the existing
        // opacity falloff, accepting the Deck performance cost).
        layer.enabled: quitConfirmationDialog.visible || stackView.busy
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: quitConfirmationDialog.visible
                  ? Bulan.popupBackdropBlurStrength
                  : Bulan.motionTransitionBlurStrength
            blurMax: quitConfirmationDialog.visible
                     ? Bulan.popupBackdropBlurRadius
                     : Bulan.motionTransitionBlurRadius
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

        // The shared atmosphere layer — gradient, vignette and grain — behind
        // every page. See Atmosphere.qml; each effect is individually
        // switchable there.
        background: Atmosphere {}

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
            anchors.fill: parent

            onProxyReady: if (owner) owner.launchTransitionProxyReady()
            onFinished: if (owner) owner.launchTransitionFinished()
            onFailed: if (owner) owner.launchTransitionFailed()
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
        HintBar {
            id: sharedHintBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            // Whoever owns the input owns the hints. Three things could be that
            // owner and they are resolved in the order they stack: the quit
            // confirmation, which is parented to the window and sits above
            // everything; whichever popup the current screen reports as open;
            // and otherwise the screen itself.
            //
            // Popups used to draw hint bars of their own, so a second bar
            // appeared over the first and every screen had to remember to
            // suppress its own -- "A Select" printing over "A Connect". Some
            // screens remembered and some did not. Now there is one bar, and a
            // popup that wants no hints (HostPanel, which carries its own in
            // its card) simply says so.
            readonly property var owner: {
                if (quitConfirmationDialog.visible) {
                    return quitConfirmationDialog
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

    ErrorMessageDialog {
        id: noHwDecoderDialog
        text: qsTr("No functioning hardware accelerated video decoder was detected by Moonlight. " +
                   "Your streaming performance may be severely degraded in this configuration.")
        helpText: qsTr("Click the Help button for more information on solving this problem.")
        helpUrl: "https://github.com/moonlight-stream/moonlight-docs/wiki/Fixing-Hardware-Decoding-Problems"
    }

    ErrorMessageDialog {
        id: xWaylandDialog
        text: qsTr("Hardware acceleration doesn't work on XWayland. Continuing on XWayland may result in poor streaming performance. " +
                   "Try running with QT_QPA_PLATFORM=wayland or switch to X11.")
        helpText: qsTr("Click the Help button for more information.")
        helpUrl: "https://github.com/moonlight-stream/moonlight-docs/wiki/Fixing-Hardware-Decoding-Problems"
    }

    NavigableMessageDialog {
        id: wow64Dialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        text: qsTr("This version of Moonlight isn't optimized for your PC. Please download the '%1' version of Moonlight for the best streaming performance.").arg(SystemProperties.friendlyNativeArchName)
        onAccepted: {
            Qt.openUrlExternally("https://github.com/moonlight-stream/moonlight-qt/releases");
        }
    }

    ErrorMessageDialog {
        id: unmappedGamepadDialog
        property string unmappedGamepads : ""
        text: qsTr("Moonlight detected gamepads without a mapping:") + "\n" + unmappedGamepads
        helpTextSeparator: "\n\n"
        helpText: qsTr("Click the Help button for information on how to map your gamepads.")
        helpUrl: "https://github.com/moonlight-stream/moonlight-docs/wiki/Gamepad-Mapping"
    }

    // This dialog appears when quitting via keyboard or gamepad button
    BulanQuitConfirmation {
        id: quitConfirmationDialog
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
