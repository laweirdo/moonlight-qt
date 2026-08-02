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

    // Set by SettingsView to force the back operation to pop all
    // pages except the initial view. This is required when doing
    // a retranslate() because AppView breaks for some reason.
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
            // cannot be grabbed. Capture the content and the toolbar as two
            // images instead.
            var ok = contentCapture.grabToImage(function(res) {
                res.saveToFile(screenshotPath)
                toolBar.grabToImage(function(res2) {
                    res2.saveToFile(screenshotPath.replace(".png", "-toolbar.png"))
                    Qt.quit()
                })
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
        layer.enabled: quitConfirmationDialog.visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: Bulan.popupBackdropBlurStrength
            blurMax: Bulan.popupBackdropBlurRadius
        }

        // Ordinary screen navigation, brief §6 "Screen transition": content
        // surfaces vertically over Bulan.motionTransitionMs, ease-out with no
        // overshoot (Easing.OutCubic; motionOvershoot belongs to focus motion,
        // not this), and the "slight motion blur" note is read as opacity
        // falling off during travel rather than an actual blur effect. Push
        // and pop are exact mirrors of each other so forward and back read as
        // one reversible movement. Declared once here per the accepted
        // decision that no per-screen route may attach its own animation.
        // replaceEnter/replaceExit are deliberately left at their implicit
        // immediate default so StreamSegue.qml's existing replace is
        // unaffected.
        //
        // Only y and opacity are animated, and both always animate to their
        // resting values (0 and 1) on enter and away from them on exit. Qt
        // queues an operation that arrives while a transition is already
        // running rather than interrupting it in place, so a settled item
        // reached via any number of queued pushes/pops always lands back on
        // this same resting state -- there is no in-between value for rapid
        // input to strand a screen at.
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
                duration: Bulan.motionTransitionMs
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
                duration: Bulan.motionTransitionMs
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
                duration: Bulan.motionTransitionMs
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
                duration: Bulan.motionTransitionMs
                easing.type: Easing.OutCubic
            }
        }

        // The shared atmosphere layer — gradient, vignette and grain — behind
        // every page. See Atmosphere.qml; each effect is individually
        // switchable there.
        background: Atmosphere {}

        // Backstop for upstream's toolbar appearing on a Bulan screen.
        //
        // Toolbar visibility is imperative all over this application: each
        // screen writes toolBar.visible in its own onActivated or
        // onDeactivating. That works while every screen agrees, and it stopped
        // working when Bulan screens arrived, because upstream screens hand the
        // toolbar back on the way out on the assumption that whatever is
        // underneath wants it. StreamSegue and QuitSegue both do exactly that,
        // and both of them sit on top of the game grid, which never wants it.
        //
        // Rather than rewrite every upstream screen's toolbar handling -- which
        // would reach well past this task -- a Bulan screen declares itself with
        // `bulanScreen`, and this runs after the push or pop has settled and
        // takes the toolbar back off. callLater is what makes it deterministic:
        // it runs at the end of the current pass, after both the outgoing
        // screen's onDeactivating and the incoming screen's onActivated,
        // whichever order those two happen to fire in. Reasoning about that
        // order is exactly what made the flash intermittent to describe.
        function hideToolBarOnBulanScreen() {
            if (stackView.currentItem &&
                    stackView.currentItem.bulanScreen === true) {
                toolBar.visible = false
            }
        }

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
            Qt.callLater(hideToolBarOnBulanScreen)
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

        Keys.onMenuPressed: {
            settingsButton.clicked()
        }

        // This is a keypress we've reserved for letting the
        // SdlGamepadKeyNavigation object tell us to show settings
        // when Menu is consumed by a focused control. Start sends it.
        Keys.onHangupPressed: {
            settingsButton.clicked()
        }

        // Y, which used to share Key_Hangup with Start. Handled here too so Y
        // still opens settings on every screen that does not claim it first --
        // the host carousel claims it for Wake.
        Keys.onCallPressed: {
            settingsButton.clicked()
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

    header: ToolBar {
        id: toolBar
        // Bulan screens claim the inherited toolbar explicitly. Starting
        // hidden prevents upstream chrome from painting before the first view
        // has activated and decided which surface owns it.
        visible: false
        height: Bulan.targetRowHeight
        anchors.topMargin: 0
        anchors.bottomMargin: 0

        // Transparent so the base gradient runs unbroken behind the chrome,
        // with a single hairline to divide it from the content.
        background: Rectangle {
            // Match the top stop of the content gradient so the chrome and the
            // content read as one continuous ground.
            color: Bulan.gradientBaseTop

            // The atmosphere layer lives in StackView.background, which sits
            // below this bar rather than behind it — so without this the grain
            // would stop dead at the bar's lower edge and leave a visible
            // untextured strip. Only the grain is repeated: the gradient's top
            // stop is already the fill above, and the vignette is positioned
            // against the full window rather than this 88px slice.
            Atmosphere {
                anchors.fill: parent
                gradientEnabled: false
                vignetteEnabled: false
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Bulan.hairline
            }
        }

        Label {
            id: titleLabel
            visible: toolBar.width > 700
            anchors.fill: parent
            text: stackView.currentItem.objectName
            // The screen name is the one piece of display typography in the
            // chrome, so it carries the Fraunces face.
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeTitle
            font.letterSpacing: Bulan.trackingTitle
            color: Bulan.textPrimary
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
        }

        RowLayout {
            spacing: Bulan.spaceSm
            anchors.leftMargin: Bulan.spaceLg
            anchors.rightMargin: Bulan.spaceLg
            anchors.fill: parent

            NavigableToolButton {
                // Only make the button visible if the user has navigated somewhere.
                visible: stackView.depth > 1

                iconSource: "qrc:/res/arrow_left.svg"

                onClicked: goBack()

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            // This label will appear when the window gets too small and
            // we need to ensure the toolbar controls don't collide
            Label {
                id: titleRowLabel
                font.family: Bulan.familyDisplay
                font.pixelSize: Bulan.sizeTitle
                font.letterSpacing: Bulan.trackingTitle
                color: Bulan.textPrimary
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true

                // We need this label to always be visible so it can occupy
                // the remaining space in the RowLayout. To "hide" it, we
                // just set the text to empty string.
                text: !titleLabel.visible ? stackView.currentItem.objectName : ""
            }

            Label {
                id: versionLabel
                visible: stackView.currentItem instanceof SettingsView
                text: qsTr("Version %1").arg(SystemProperties.versionString)
                font.pixelSize: Bulan.sizeCaption
                color: Bulan.textSecondary
                horizontalAlignment: Qt.AlignRight
                verticalAlignment: Qt.AlignVCenter
            }

            NavigableToolButton {
                id: discordButton
                visible: SystemProperties.hasBrowser &&
                         stackView.currentItem instanceof SettingsView

                iconSource: "qrc:/res/discord.svg"

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Join our community on Discord")

                // TODO need to make sure browser is brought to foreground.
                onClicked: Qt.openUrlExternally("https://moonlight-stream.org/discord");

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            NavigableToolButton {
                id: addPcButton
                visible: stackView.currentItem instanceof PcView

                iconSource:  "qrc:/res/ic_add_to_queue_white_48px.svg"

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Add PC manually") + (newPcShortcut.nativeText ? (" ("+newPcShortcut.nativeText+")") : "")

                Shortcut {
                    id: newPcShortcut
                    sequence: StandardKey.New
                    onActivated: addPcButton.clicked()
                }

                onClicked: {
                    addPcDialog.open()
                }

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            NavigableToolButton {
                property string browserUrl: ""

                id: updateButton

                iconSource: "qrc:/res/update.svg"

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered || visible

                // Invisible until we get a callback notifying us that
                // an update is available
                visible: false

                onClicked: {
                    if (SystemProperties.hasBrowser) {
                        Qt.openUrlExternally(browserUrl);
                    }
                }

                function updateAvailable(version, url)
                {
                    ToolTip.text = qsTr("Update available for Moonlight: Version %1").arg(version)
                    updateButton.browserUrl = url
                    updateButton.visible = true
                }

                Component.onCompleted: {
                    AutoUpdateChecker.onUpdateAvailable.connect(updateAvailable)
                    AutoUpdateChecker.start()
                }

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            NavigableToolButton {
                id: helpButton
                visible: SystemProperties.hasBrowser

                iconSource: "qrc:/res/question_mark.svg"

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Help") + (helpShortcut.nativeText ? (" ("+helpShortcut.nativeText+")") : "")

                Shortcut {
                    id: helpShortcut
                    sequence: StandardKey.HelpContents
                    onActivated: helpButton.clicked()
                }

                // TODO need to make sure browser is brought to foreground.
                onClicked: Qt.openUrlExternally("https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide");

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            NavigableToolButton {
                // TODO: Implement gamepad mapping then unhide this button
                visible: false

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Gamepad Mapper")

                iconSource: "qrc:/res/ic_videogame_asset_white_48px.svg"

                onClicked: navigateTo("qrc:/gui/GamepadMapper.qml", GamepadMapper)

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            NavigableToolButton {
                id: settingsButton

                iconSource:  "qrc:/res/settings.svg"

                onClicked: navigateTo("qrc:/gui/SettingsView.qml", SettingsView)

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }

                Shortcut {
                    id: settingsShortcut
                    sequence: StandardKey.Preferences
                    onActivated: settingsButton.clicked()
                }

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Settings") + (settingsShortcut.nativeText ? (" ("+settingsShortcut.nativeText+")") : "")
            }
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

    NavigableDialog {
        id: addPcDialog
        property string label: qsTr("Enter the IP address of your host PC:")

        standardButtons: Dialog.Ok | Dialog.Cancel

        onOpened: {
            // Force keyboard focus on the textbox so keyboard navigation works
            editText.forceActiveFocus()
        }

        onClosed: {
            editText.clear()
        }

        onAccepted: {
            if (editText.text) {
                ComputerManager.addNewHostManually(editText.text.trim())
            }
        }

        ColumnLayout {
            Label {
                text: addPcDialog.label
                font.bold: true
            }

            TextField {
                id: editText
                Layout.fillWidth: true
                focus: true

                Keys.onReturnPressed: {
                    addPcDialog.accept()
                }

                Keys.onEnterPressed: {
                    addPcDialog.accept()
                }
            }
        }
    }
}
