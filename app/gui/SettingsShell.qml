import QtQuick 2.9
// Imported for the StackView attached properties only -- no stock control
// from this module is instantiated anywhere on this screen.
import QtQuick.Controls 2.2
import QtQuick.Effects

import Bulan 1.0
import StreamingPreferences 1.0
import SystemProperties 1.0
import ComputerManager 1.0
import ComputerModel 1.0
import SdlGamepadKeyNavigation 1.0

// -----------------------------------------------------------------------------
// The Bulan settings shell (private v1 finalisation, stage 5), replacing
// SettingsView.qml on every route. Two panes per the client's mockups:
//
//   left  -- "Settings" in the display face, then a vertical category rail
//   right -- full-width rounded rows for whichever category is selected
//
// Left/Right move focus between the rail and the rows pane; Up/Down move
// within whichever pane currently holds it -- the "spatial D-pad navigation
// matching the visible layout" the work order asks for. A on a row opens the
// matching popup (SettingsChoicePopup for `choice`, SettingsSliderPopup for
// `slider`) or flips a `toggle` row in place with no popup at all.
//
// DATA-DRIVEN, per the work order: `categories` below is one description
// list, built once in buildCategories(). Every row is
//   { id, type: "toggle"|"choice"|"slider"|"host"|"info",
//     label, visible(), enabled(), ... type-specific accessors }
// and the generic delegate at the bottom renders whichever shape a row
// declares. Adding one more StreamingPreferences control from here on is one
// list entry, not a bespoke block of QML -- this is what lets the shell cover
// every setting SettingsView.qml exposed without 60 copies of the same rows.
//
// House style follows HostDiscovery.qml (the newest Bulan screen) and
// HostSettingsOverlay.qml (the accepted popup/glass pattern): a plain
// FocusScope owning its own input, `bulanScreen`, hint-bar properties instead
// of a bar drawn here, and comments that explain a choice once rather than
// re-arguing it at every call site.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Settings")
    focus: true

    readonly property bool bulanScreen: true

    // --- host-info row -------------------------------------------------------
    // The mockup's Host category leads with a row naming the current PC
    // (mockups 2 and 4). StreamingPreferences has no per-host storage --
    // every setting here is global, not scoped to a PC -- so building a real
    // per-host selector would be the settings re-architecture ROADMAP.md
    // explicitly rules out of this task. This row is informational only: the
    // first paired PC ComputerManager knows about, or a placeholder when none
    // is paired yet. Built the same way HostDiscovery.qml reads a host's
    // fields -- through a live Repeater delegate, which is the only place
    // ComputerModel's roles (model.name, model.address) are reachable -- not
    // through a plain JS accessor.
    property ComputerModel hostInfoModel: createHostInfoModel()
    function createHostInfoModel() {
        var model = Qt.createQmlObject('import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        return model
    }

    // --- description list ------------------------------------------------
    property var categories: buildCategories()
    property int categoryIndex: 0
    property int rowIndex: 0
    // "rail" or "rows".
    property string activePane: "rail"

    readonly property var currentCategory:
        (categoryIndex >= 0 && categoryIndex < categories.length) ? categories[categoryIndex] : null

    function visibleRows(category) {
        if (!category || !category.rows) {
            return []
        }
        var out = []
        for (var i = 0; i < category.rows.length; i++) {
            var row = category.rows[i]
            if (!row.visible || row.visible()) {
                out.push(row)
            }
        }
        return out
    }

    readonly property var currentRows: visibleRows(currentCategory)
    readonly property var currentRow:
        (rowIndex >= 0 && currentRows && rowIndex < currentRows.length) ? currentRows[rowIndex] : null

    function rowEnabled(row) {
        return row.enabled ? row.enabled() : true
    }

    function moveCategory(step) {
        var next = categoryIndex + step
        if (next < 0 || next >= categories.length) {
            return
        }
        categoryIndex = next
        rowIndex = 0
    }

    function moveRow(step) {
        var rows = currentRows
        if (rows.length === 0) {
            return
        }
        rowIndex = Math.max(0, Math.min(rows.length - 1, rowIndex + step))
        rowsFlickable.ensureRowVisible(rowIndex)
    }

    // The row that opened whichever popup is currently open, so the popups'
    // generic onSelected/onChanged handlers know which accessor to call back
    // into without the popup itself knowing what a resolution or a bitrate is.
    property var activePopupRow: null

    function activateCurrent() {
        if (activePane === "rail") {
            activePane = "rows"
            return
        }
        var row = currentRow
        if (!row || !rowEnabled(row)) {
            return
        }
        if (row.type === "toggle") {
            row.toggle()
        } else if (row.type === "choice") {
            openChoicePopup(row)
        } else if (row.type === "slider") {
            openSliderPopup(row)
        } else if (row.type === "action" && row.activate) {
            row.activate()
        }
        // "host"/"info" rows carry nothing to activate -- they display data,
        // not an action, so A is silently inert rather than a dead promise.
    }

    function openChoicePopup(row) {
        activePopupRow = row
        choicePopup.open({
            title: row.popupTitle || row.label,
            options: row.buildOptions(),
            addEnabled: row.addEnabled === true,
            addLabel: row.addLabel,
            addPromptTitle: row.addPromptTitle,
            addPromptBody: row.addPromptBody,
            addPromptPlaceholder: row.addPromptPlaceholder
                ? (typeof row.addPromptPlaceholder === "function" ? row.addPromptPlaceholder() : row.addPromptPlaceholder)
                : ""
        })
    }

    function openSliderPopup(row) {
        activePopupRow = row
        sliderPopup.open({
            title: row.popupTitle || row.label,
            min: row.min(),
            max: row.max(),
            step: row.step,
            value: row.value(),
            formattedValue: row.valueLabel(),
            resetTo: row.resetTo ? row.resetTo() : null
        })
    }

    function reclaimFocus() {
        if (root.StackView.status !== StackView.Active) {
            return
        }
        root.forceActiveFocus()
    }

    StackView.onActivated: {
        SdlGamepadKeyNavigation.setUiNavMode(false)
        root.forceActiveFocus()

        // Review hooks: MOONLIGHT_SETTINGS_REVIEW_CATEGORY selects a rail
        // category by id, and MOONLIGHT_SETTINGS_REVIEW_ROW additionally opens
        // that row's popup, the same screenshot-cannot-press-A reasoning as
        // MOONLIGHT_OPEN_HOST_SETTINGS. Both inert when unset.
        if (typeof settingsReviewCategory !== "undefined" && settingsReviewCategory !== "") {
            for (var i = 0; i < categories.length; i++) {
                if (categories[i].id === settingsReviewCategory) {
                    categoryIndex = i
                    rowIndex = 0
                    activePane = "rows"
                    break
                }
            }
        }
        if (typeof settingsReviewRow !== "undefined" && settingsReviewRow !== "") {
            var rows = currentRows
            for (var j = 0; j < rows.length; j++) {
                if (rows[j].id === settingsReviewRow) {
                    rowIndex = j
                    Qt.callLater(function() { root.activateCurrent() })
                    break
                }
            }
        }
    }

    StackView.onDeactivating: {
        // Save the prefs so the Session can observe the changes -- mirrors
        // SettingsView.qml's own onDeactivating exactly.
        StreamingPreferences.save()
    }

    Component.onDestruction: {
        // Also save on destruction, since we won't get a deactivating callback
        // if the user just closes Moonlight -- same reasoning as
        // SettingsView.qml's matching handler.
        StreamingPreferences.save()
    }

    onActiveFocusChanged: {
        if (!activeFocus && StackView.status === StackView.Active
                && !choicePopup.visible && !sliderPopup.visible) {
            Qt.callLater(reclaimFocus)
        }
    }

    // --- entrance motion ---------------------------------------------------
    // Brief §6/TASK-BRIEF.md motion rule: the stack transition settles first,
    // then this screen's principal elements rise and fade in on a slight
    // stagger, each with one restrained overshoot. Three elements, ordered by
    // reading order (title, then rail, then the rows pane) -- following
    // AppView.qml's Recent/Library tile entrance exactly, just with three
    // steps instead of per-tile, since a settings shell has three principal
    // regions rather than a grid of many identical ones.
    property bool entranceStarted: false
    Timer {
        interval: Bulan.motionGridEntranceDelayMs
        running: true
        onTriggered: root.entranceStarted = true
    }

    Item {
        id: screenContent
        anchors.fill: parent

        // Blurred behind either popup, the same glass treatment the host
        // carousel gives its own panels (client review, 3 August 2026: popups
        // should blur what is behind them). Safe to blur this whole item
        // because both popups are declared as SIBLINGS of it further down, not
        // children -- blurring a popup's own parent would blur the popup too.
        //
        // Gated on visibility, so a settled screen with nothing open carries
        // no layer and no effect at all.
        layer.enabled: choicePopup.visible || sliderPopup.visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: Bulan.popupBackdropBlurStrength
            blurMax: Bulan.popupBackdropBlurRadius
        }

        Atmosphere {
            anchors.fill: parent
        }

        // --- title -----------------------------------------------------------
        Text {
            id: titleLabel
            anchors.left: parent.left
            anchors.leftMargin: Bulan.layoutScreenMarginX
            anchors.top: parent.top
            anchors.topMargin: Bulan.layoutScreenMarginY
                               + (1 - titleEntrance.entranceProgress) * Bulan.motionGridEntranceRise
            opacity: Math.min(1, titleEntrance.entranceProgress)
            text: qsTr("Settings")
            color: Bulan.textPrimary
            font.family: Bulan.familyDisplay
            font.pixelSize: Bulan.sizeDisplay
            font.letterSpacing: Bulan.trackingDisplay

            QtObject {
                id: titleEntrance
                property real entranceProgress: 0
                property bool entranceSettled: false
            }
            SequentialAnimation {
                running: root.entranceStarted && !titleEntrance.entranceSettled
                onStopped: titleEntrance.entranceSettled = true
                PauseAnimation { duration: 0 }
                NumberAnimation {
                    target: titleEntrance
                    property: "entranceProgress"
                    to: 1
                    duration: Bulan.motionGridEntranceRiseMs
                    easing.type: Easing.OutBack
                    easing.overshoot: Bulan.motionEntranceOvershoot
                }
            }
        }

        // --- rail --------------------------------------------------------
        Item {
            id: railPane
            anchors.left: parent.left
            anchors.leftMargin: Bulan.layoutScreenMarginX
            anchors.top: titleLabel.bottom
            anchors.topMargin: Bulan.spaceXl
                               + (1 - railEntrance.entranceProgress) * Bulan.motionGridEntranceRise
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Bulan.targetRowHeight + Bulan.spaceLg
            width: Bulan.settingsRailWidth
            opacity: Math.min(1, railEntrance.entranceProgress)

            QtObject {
                id: railEntrance
                property real entranceProgress: 0
                property bool entranceSettled: false
            }
            SequentialAnimation {
                running: root.entranceStarted && !railEntrance.entranceSettled
                onStopped: railEntrance.entranceSettled = true
                PauseAnimation { duration: Bulan.motionGridEntranceStaggerMs }
                NumberAnimation {
                    target: railEntrance
                    property: "entranceProgress"
                    to: 1
                    duration: Bulan.motionGridEntranceRiseMs
                    easing.type: Easing.OutBack
                    easing.overshoot: Bulan.motionEntranceOvershoot
                }
            }

            Column {
                id: railColumn
                width: parent.width
                spacing: Bulan.space2xs

                // Every category has to be visible at once. The rail is this
                // screen's map, and a map you have to scroll to reach the end
                // of is not doing its job -- About in particular would be
                // navigable by feel and invisible to the eye.
                //
                // Eight categories at targetRowHeight overflowed this pane by
                // about a row and a half at 1280x800: About fell off the
                // bottom entirely and Advanced collided with the hint bar.
                // Rows divide the height the pane actually has instead,
                // floored at targetMin so a row can never fall below the 64px
                // focus target AGENTS.md requires.
                readonly property int rowHeight:
                    Math.max(Bulan.targetMin,
                             (railPane.height - spacing * (root.categories.length - 1))
                             / root.categories.length)

                Repeater {
                    model: root.categories

                    delegate: Item {
                        id: railRow
                        width: parent.width
                        height: railColumn.rowHeight

                        readonly property bool isActiveCategory: index === root.categoryIndex
                        readonly property bool isFocusedPane:
                            isActiveCategory && root.activePane === "rail"

                        // The pill only appears while the rail itself holds
                        // focus (mockup 1); once focus moves to the rows pane
                        // the category keeps its amber text and left bar but
                        // loses the pill (mockup 2).
                        //
                        // ONE size for every category, not one sized to each
                        // label (client review, 3 August 2026). Fitting the
                        // pill to the text made the focus ring change shape as
                        // it moved -- wide on "Advanced", narrow on "UI" --
                        // which read as the control resizing rather than the
                        // selection moving. Focus has to be the same object
                        // wherever it lands, exactly as the game grid's ring is
                        // the same ring on every tile.
                        Rectangle {
                            id: pill
                            visible: railRow.isFocusedPane
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            width: parent.width
                            height: Bulan.targetMin
                            radius: Bulan.radiusFull
                            color: Bulan.transparent
                            border.width: Bulan.space2xs / 2
                            border.color: Bulan.accentPrimary

                            layer.enabled: railRow.isFocusedPane
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Bulan.accentGlow
                                shadowBlur: Bulan.buttonGlowBlur
                                shadowOpacity: Bulan.buttonGlowOpacity
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }
                        }

                        Rectangle {
                            id: bar
                            visible: railRow.isActiveCategory
                            anchors.left: parent.left
                            anchors.leftMargin: Bulan.spaceLg
                            anchors.verticalCenter: parent.verticalCenter
                            width: Bulan.space2xs
                            height: Bulan.spaceLg
                            radius: width / 2
                            color: Bulan.accentPrimary
                        }

                        Item {
                            id: labelSpacing
                            anchors.left: bar.visible ? bar.right : parent.left
                            anchors.leftMargin: bar.visible ? Bulan.spaceMd : Bulan.spaceLg + Bulan.space2xs
                            width: Bulan.spaceXs
                            height: 1
                        }

                        Text {
                            id: label
                            anchors.left: labelSpacing.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: railRow.isActiveCategory ? Bulan.accentPrimary : Bulan.textSecondary
                            font.family: Bulan.familyUi
                            font.pixelSize: Bulan.sizeBodyLg
                            font.bold: railRow.isActiveCategory
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.categoryIndex = index
                                root.rowIndex = 0
                                root.activePane = "rail"
                            }
                            onDoubleClicked: root.activePane = "rows"
                        }
                    }
                }
            }
        }

        // --- rows pane -----------------------------------------------------
        Item {
            id: rowsPane
            anchors.left: railPane.right
            anchors.leftMargin: Bulan.spaceXl
            anchors.right: parent.right
            anchors.rightMargin: Bulan.layoutScreenMarginX
            anchors.top: titleLabel.bottom
            anchors.topMargin: Bulan.spaceXl
                               + (1 - rowsEntrance.entranceProgress) * Bulan.motionGridEntranceRise
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Bulan.targetRowHeight + Bulan.spaceLg
            opacity: Math.min(1, rowsEntrance.entranceProgress)

            QtObject {
                id: rowsEntrance
                property real entranceProgress: 0
                property bool entranceSettled: false
            }
            SequentialAnimation {
                running: root.entranceStarted && !rowsEntrance.entranceSettled
                onStopped: rowsEntrance.entranceSettled = true
                PauseAnimation { duration: Bulan.motionGridEntranceStaggerMs * 2 }
                NumberAnimation {
                    target: rowsEntrance
                    property: "entranceProgress"
                    to: 1
                    duration: Bulan.motionGridEntranceRiseMs
                    easing.type: Easing.OutBack
                    easing.overshoot: Bulan.motionEntranceOvershoot
                }
            }

            // --- About: a fixed content page, not a row list -----------------
            Flickable {
                id: aboutFlick
                anchors.fill: parent
                visible: root.currentCategory !== null && root.currentCategory.id === "about"
                clip: true
                contentWidth: width
                contentHeight: aboutColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: aboutColumn
                    width: aboutFlick.width - Bulan.spaceMd
                    spacing: Bulan.spaceLg

                    Image {
                        source: "qrc:/res/bulan_logomark.svg"
                        width: Bulan.onboardingMarkSize
                        height: width
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: width * 2
                        sourceSize.height: width * 2
                        smooth: true
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Bulan")
                        color: Bulan.textPrimary
                        font.family: Bulan.familyDisplay
                        font.pixelSize: Bulan.sizeTitleLg
                        font.letterSpacing: Bulan.trackingTitle
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Version %1").arg(SystemProperties.versionString)
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                    }

                    Rectangle {
                        width: parent.width
                        height: Bulan.space2xs / 4
                        color: Bulan.hairline
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Built on Moonlight")
                        color: Bulan.accentPrimary
                        font.family: Bulan.familyDisplay
                        font.pixelSize: Bulan.sizeTitle
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("Bulan is a fork of moonlight-qt, the open-source Moonlight game streaming client. Everything about how a stream actually reaches your PC and comes back to this screen is Moonlight's engineering, not ours -- we built the front door.")
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("Moonlight is licensed under the GNU General Public License v3.0. This fork carries that same license, and its source is available on request.")
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                    }

                    Rectangle {
                        width: parent.width
                        height: Bulan.space2xs / 4
                        color: Bulan.hairline
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Typefaces")
                        color: Bulan.accentPrimary
                        font.family: Bulan.familyDisplay
                        font.pixelSize: Bulan.sizeTitle
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("Inter and Fraunces, the two faces used throughout this app, are each licensed under the SIL Open Font License 1.1. Their full license texts ship inside the application (OFL-Inter.txt and OFL-Fraunces.txt).")
                        color: Bulan.textSecondary
                        font.family: Bulan.familyUi
                        font.pixelSize: Bulan.sizeBody
                    }
                }
            }

            Flickable {
                id: rowsFlickable
                anchors.fill: parent
                anchors.rightMargin: Bulan.spaceMd
                visible: root.currentCategory !== null && root.currentCategory.id !== "about"
                clip: true
                contentWidth: width
                contentHeight: rowsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                function ensureRowVisible(index) {
                    var rowH = Bulan.targetRowHeight + Bulan.spaceMd
                    var top = index * rowH
                    var bottom = top + rowH
                    var newY = contentY
                    if (top < contentY) {
                        newY = top
                    } else if (bottom > contentY + height) {
                        newY = bottom - height
                    }
                    var maxY = Math.max(0, contentHeight - height)
                    newY = Math.max(0, Math.min(newY, maxY))
                    rowsScrollAnimation.to = newY
                    rowsScrollAnimation.restart()
                }

                NumberAnimation {
                    id: rowsScrollAnimation
                    target: rowsFlickable
                    property: "contentY"
                    duration: Bulan.motionFocusMs
                    easing.type: Easing.OutCubic
                }

                onDraggingChanged: {
                    if (dragging) {
                        rowsScrollAnimation.stop()
                    }
                }

                Column {
                    id: rowsColumn
                    width: rowsFlickable.width
                    spacing: Bulan.spaceMd

                    Repeater {
                        model: root.currentRows

                        delegate: Rectangle {
                            id: rowSurface
                            width: rowsColumn.width
                            height: Bulan.targetRowHeight
                            radius: Bulan.radiusLg
                            readonly property bool isFocusedRow:
                                index === root.rowIndex && root.activePane === "rows"
                            readonly property bool rowIsEnabled: root.rowEnabled(modelData)

                            color: isFocusedRow ? Bulan.surfaceHover : Bulan.bgSurface
                            border.width: isFocusedRow ? Bulan.space2xs / 2 : 0
                            border.color: Bulan.accentPrimary
                            opacity: rowIsEnabled ? 1.0 : Bulan.disabledOpacity

                            layer.enabled: isFocusedRow
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Bulan.accentGlow
                                shadowBlur: Bulan.buttonGlowBlur
                                shadowOpacity: Bulan.buttonGlowOpacity
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }

                            Rectangle {
                                visible: rowSurface.isFocusedRow
                                anchors.left: parent.left
                                anchors.leftMargin: Bulan.spaceMd
                                anchors.verticalCenter: parent.verticalCenter
                                width: Bulan.space2xs
                                height: parent.height - Bulan.spaceMd * 2
                                radius: width / 2
                                color: Bulan.accentPrimary
                            }

                            // --- "host" row: informational only, see the
                            // hostInfoModel comment above. Text is used
                            // directly as the Repeater delegate -- its
                            // implicitWidth/Height become its actual size
                            // with nothing else set, so Row can lay it out
                            // like any other child with no wrapper Item
                            // needed.
                            Row {
                                visible: modelData.type === "host"
                                anchors.left: parent.left
                                anchors.leftMargin: Bulan.layoutScreenMarginX
                                anchors.verticalCenter: parent.verticalCenter

                                // QAbstractListModel exposes no real `count`
                                // property of its own to plain JS -- that
                                // only exists as a delegate-context role
                                // inside a view. Reading Repeater.count below
                                // (a genuine QQuickRepeater property) is the
                                // one reliable way to know whether a host
                                // exists at all outside a delegate.
                                Repeater {
                                    id: hostNameRepeater
                                    model: modelData.type === "host" ? root.hostInfoModel : 0
                                    delegate: Text {
                                        visible: index === 0
                                        text: model.name
                                        color: Bulan.textPrimary
                                        font.family: Bulan.familyDisplay
                                        font.pixelSize: Bulan.sizeTitle
                                    }
                                }

                                Text {
                                    visible: modelData.type === "host" && hostNameRepeater.count === 0
                                    text: qsTr("No PC paired yet")
                                    color: Bulan.textPrimary
                                    font.family: Bulan.familyDisplay
                                    font.pixelSize: Bulan.sizeTitle
                                }
                            }

                            // Address, right-aligned, only when a host exists.
                            Repeater {
                                model: (modelData.type === "host" && hostNameRepeater.count > 0) ? root.hostInfoModel : 0
                                delegate: Text {
                                    visible: index === 0
                                    anchors.right: parent.right
                                    anchors.rightMargin: Bulan.layoutScreenMarginX
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: model.address
                                    color: Bulan.textSecondary
                                    font.family: Bulan.familyUi
                                    font.pixelSize: Bulan.sizeBody
                                }
                            }

                            // --- ordinary row: label left, value or switch right
                            Text {
                                visible: modelData.type !== "host"
                                anchors.left: parent.left
                                anchors.leftMargin: Bulan.layoutScreenMarginX
                                anchors.right: (modelData.type === "toggle") ? toggleTrack.left : valueLabel.left
                                anchors.rightMargin: Bulan.spaceMd
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label !== undefined ? modelData.label : ""
                                color: Bulan.textPrimary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeBody
                                elide: Text.ElideRight
                            }

                            Text {
                                id: valueLabel
                                visible: modelData.type !== "host" && modelData.type !== "toggle"
                                anchors.right: parent.right
                                anchors.rightMargin: Bulan.layoutScreenMarginX
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.valueLabel ? modelData.valueLabel() : ""
                                color: Bulan.textSecondary
                                font.family: Bulan.familyUi
                                font.pixelSize: Bulan.sizeBody
                            }

                            Rectangle {
                                id: toggleTrack
                                visible: modelData.type === "toggle"
                                anchors.right: parent.right
                                anchors.rightMargin: Bulan.layoutScreenMarginX
                                anchors.verticalCenter: parent.verticalCenter
                                width: Bulan.targetMin * 1.15
                                height: Bulan.spaceXl
                                radius: height / 2
                                readonly property bool on: modelData.type === "toggle" && modelData.checked()
                                color: on ? Bulan.accentPrimary : Bulan.surfacePressed
                                border.width: 1
                                border.color: on ? Bulan.accentPrimary : Bulan.hairline

                                Rectangle {
                                    width: Bulan.spaceLg
                                    height: Bulan.spaceLg
                                    radius: width / 2
                                    color: Bulan.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: toggleTrack.on ? parent.width - width - 3 : 3
                                    Behavior on x {
                                        NumberAnimation { duration: Bulan.motionFocusMs; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: rowSurface.rowIsEnabled
                                onEntered: {
                                    root.activePane = "rows"
                                    root.rowIndex = index
                                }
                                onClicked: {
                                    root.activePane = "rows"
                                    root.rowIndex = index
                                    root.activateCurrent()
                                }
                            }
                        }
                    }
                }
            }

            // Slim scroll indicator, matching HostSettingsOverlay's and
            // SettingsChoicePopup's identical treatment. No ScrollBar.
            Rectangle {
                anchors.right: parent.right
                width: Bulan.space2xs
                radius: width / 2
                color: Bulan.secondary
                visible: rowsFlickable.visible && rowsFlickable.contentHeight > rowsFlickable.height
                height: visible
                        ? Math.max(Bulan.spaceLg,
                                   rowsFlickable.height * rowsFlickable.height / rowsFlickable.contentHeight)
                        : 0
                y: visible
                   ? (rowsFlickable.height - height) * rowsFlickable.visibleArea.yPosition /
                     Math.max(Bulan.space2xs, 1 - rowsFlickable.visibleArea.heightRatio)
                   : 0
            }
        }
    }

    SettingsChoicePopup {
        id: choicePopup
        anchors.fill: parent

        onSelected: function(value) {
            if (root.activePopupRow && root.activePopupRow.onSelect) {
                root.activePopupRow.onSelect(value)
            }
            choicePopup.close()
        }
        onAddSubmitted: function(text) {
            if (root.activePopupRow && root.activePopupRow.onAdd) {
                root.activePopupRow.onAdd(text)
            }
            choicePopup.close()
        }
        onDismissed: root.reclaimFocus()
    }

    SettingsSliderPopup {
        id: sliderPopup
        anchors.fill: parent

        onChanged: function(value, isReset) {
            if (root.activePopupRow && root.activePopupRow.onChange) {
                root.activePopupRow.onChange(value, isReset)
            }
        }
        onDismissed: root.reclaimFocus()
    }

    // --- hint bar ----------------------------------------------------------
    readonly property bool hintBarVisible: true
    readonly property var hintLeftHints: [
        {
            action: "confirm",
            label: root.activePane === "rail"
                   ? qsTr("Open")
                   : (root.currentRow && root.currentRow.type === "toggle" ? qsTr("Toggle") : qsTr("Select")),
            emphasis: true,
            visible: root.currentRow !== null || root.activePane === "rail"
        }
    ]
    readonly property var hintRightHints: [
        { action: "back", label: qsTr("Back") }
    ]

    // --- input ---------------------------------------------------------------
    // B is deliberately unhandled here, matching HostDiscovery.qml's own
    // reasoning: main.qml's central Keys.onEscapePressed/onBackPressed already
    // pops the stack when this screen holds focus and does not accept the
    // event -- and it never reaches there while a popup has focus, because the
    // popup's own handler accepts it first.
    Keys.onLeftPressed: function(event) {
        if (root.activePane === "rows") {
            root.activePane = "rail"
        }
        event.accepted = true
    }
    Keys.onRightPressed: function(event) {
        if (root.activePane === "rail") {
            root.activePane = "rows"
        }
        event.accepted = true
    }
    Keys.onUpPressed: function(event) {
        if (root.activePane === "rail") {
            root.moveCategory(-1)
        } else {
            root.moveRow(-1)
        }
        event.accepted = true
    }
    Keys.onDownPressed: function(event) {
        if (root.activePane === "rail") {
            root.moveCategory(1)
        } else {
            root.moveRow(1)
        }
        event.accepted = true
    }
    Keys.onReturnPressed: function(event) {
        root.activateCurrent()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        root.activateCurrent()
        event.accepted = true
    }
    Keys.onSpacePressed: function(event) {
        root.activateCurrent()
        event.accepted = true
    }

    // ==========================================================================
    // Description list. Every StreamingPreferences property SettingsView.qml
    // exposed is represented here -- see TASK-BRIEF.md's completeness
    // requirement -- except `packetSize`, which SettingsView.qml never
    // exposed either (no control anywhere bound it); that omission is
    // pre-existing, not introduced by this screen.
    // ==========================================================================
    function buildCategories() {
        function formatMbps(kbps) {
            return qsTr("%1 Mbps").arg((kbps / 1000.0).toFixed(kbps % 1000 === 0 ? 0 : 1))
        }

        function applyResolution(w, h) {
            if (StreamingPreferences.width === w && StreamingPreferences.height === h) {
                return
            }
            StreamingPreferences.width = w
            StreamingPreferences.height = h
            if (StreamingPreferences.autoAdjustBitrate) {
                StreamingPreferences.bitrateKbps = StreamingPreferences.getDefaultBitrate(
                            w, h, StreamingPreferences.fps, StreamingPreferences.enableYUV444)
            }
        }

        function applyFps(fps) {
            if (StreamingPreferences.fps === fps) {
                return
            }
            StreamingPreferences.fps = fps
            if (StreamingPreferences.autoAdjustBitrate) {
                StreamingPreferences.bitrateKbps = StreamingPreferences.getDefaultBitrate(
                            StreamingPreferences.width, StreamingPreferences.height,
                            fps, StreamingPreferences.enableYUV444)
            }
        }

        function buildResolutionOptions() {
            var opts = [
                { label: "720p", w: 1280, h: 720 },
                { label: "1080p", w: 1920, h: 1080 },
                { label: "1440p", w: 2560, h: 1440 },
                { label: "4K", w: 3840, h: 2160 }
            ]

            function insertDetected(prefix, rect, recommended) {
                if (rect.width === 0) {
                    return
                }
                var idx = 0
                for (var j = 0; j < opts.length; j++) {
                    if (rect.width === opts[j].w && rect.height === opts[j].h) {
                        return
                    } else if (rect.width * rect.height > opts[j].w * opts[j].h) {
                        idx = j + 1
                    }
                }
                opts.splice(idx, 0, {
                    label: prefix + " (" + rect.width + "×" + rect.height + ")",
                    w: rect.width, h: rect.height, recommended: recommended === true
                })
            }

            SystemProperties.refreshDisplays()
            for (var displayIndex = 0; ; displayIndex++) {
                var screenRect = SystemProperties.getNativeResolution(displayIndex)
                if (screenRect.width === 0) {
                    break
                }
                var safeRect = SystemProperties.getSafeAreaResolution(displayIndex)
                insertDetected(qsTr("Native"), screenRect, true)
                insertDetected(qsTr("Native (Excluding Notch)"), safeRect, false)
            }

            var maxPixels = SystemProperties.maximumResolution.width * SystemProperties.maximumResolution.height
            if (maxPixels > 0) {
                opts = opts.filter(function(o) { return o.w * o.h <= maxPixels })
            }

            for (var i = 0; i < opts.length; i++) {
                if (opts[i].label.indexOf("(") === -1) {
                    opts[i].label = opts[i].label + " (" + opts[i].w + "×" + opts[i].h + ")"
                }
                opts[i].value = { w: opts[i].w, h: opts[i].h }
                opts[i].current = (opts[i].w === StreamingPreferences.width && opts[i].h === StreamingPreferences.height)
            }

            if (!opts.some(function(o) { return o.current })) {
                opts.push({
                    label: qsTr("Custom") + " (" + StreamingPreferences.width + "×" + StreamingPreferences.height + ")",
                    value: { w: StreamingPreferences.width, h: StreamingPreferences.height },
                    current: true
                })
            }

            return opts
        }

        function buildFpsOptions() {
            var opts = [
                { fps: 30, label: qsTr("30 FPS") },
                { fps: 60, label: qsTr("60 FPS") }
            ]

            function insertRate(rate) {
                if (rate === 0) {
                    return
                }
                for (var j = 0; j < opts.length; j++) {
                    if (opts[j].fps === rate) {
                        return
                    }
                }
                var idx = opts.length
                for (var k = 0; k < opts.length; k++) {
                    if (rate > opts[k].fps) {
                        idx = k
                        break
                    }
                }
                opts.splice(idx, 0, { fps: rate, label: qsTr("%1 FPS").arg(rate) })
            }

            for (var displayIndex = 0; ; displayIndex++) {
                var rate = SystemProperties.getRefreshRate(displayIndex)
                if (rate === 0) {
                    break
                }
                insertRate(rate)
            }

            var opts2 = []
            for (var i = 0; i < opts.length; i++) {
                opts2.push({
                    label: opts[i].label,
                    value: opts[i].fps,
                    current: opts[i].fps === StreamingPreferences.fps
                })
            }
            if (!opts2.some(function(o) { return o.current })) {
                opts2.push({
                    label: qsTr("Custom (%1 FPS)").arg(StreamingPreferences.fps),
                    value: StreamingPreferences.fps,
                    current: true
                })
            }
            return opts2
        }

        function enumOptions(pairs, currentValue) {
            var out = []
            for (var i = 0; i < pairs.length; i++) {
                out.push({
                    label: pairs[i][0],
                    value: pairs[i][1],
                    current: pairs[i][1] === currentValue
                })
            }
            return out
        }

        function windowModeLabel(mode) {
            var suffix = (mode === StreamingPreferences.recommendedFullScreenMode)
                    ? " " + qsTr("(Recommended)") : ""
            if (mode === StreamingPreferences.WM_FULLSCREEN) return qsTr("Fullscreen") + suffix
            if (mode === StreamingPreferences.WM_FULLSCREEN_DESKTOP) return qsTr("Borderless windowed") + suffix
            return qsTr("Windowed") + suffix
        }

        // -------------------------------------------------------------- Basic
        var basicRows = [
            {
                id: "resolution", type: "choice",
                label: qsTr("Resolution"),
                popupTitle: qsTr("Choose a Resolution"),
                valueLabel: function() { return StreamingPreferences.width + "×" + StreamingPreferences.height },
                buildOptions: buildResolutionOptions,
                addEnabled: true,
                addLabel: qsTr("Add Resolution"),
                addPromptTitle: qsTr("Add a custom resolution"),
                addPromptBody: qsTr("Enter it as width x height, for example 1920x1080."),
                addPromptPlaceholder: function() { return StreamingPreferences.width + "x" + StreamingPreferences.height },
                onSelect: function(value) { applyResolution(value.w, value.h) },
                onAdd: function(text) {
                    var m = /^\s*(\d{3,5})\s*[x×]\s*(\d{3,5})\s*$/.exec(text)
                    if (m) {
                        applyResolution(parseInt(m[1], 10), parseInt(m[2], 10))
                    }
                }
            },
            {
                id: "fps", type: "choice",
                label: qsTr("Frame Rate"),
                popupTitle: qsTr("Choose a Frame Rate"),
                valueLabel: function() { return StreamingPreferences.fps },
                buildOptions: buildFpsOptions,
                addEnabled: true,
                addLabel: qsTr("Add Frame Rate"),
                addPromptTitle: qsTr("Add a custom frame rate"),
                addPromptBody: qsTr("Enter it in frames per second, for example 120."),
                addPromptPlaceholder: function() { return "" + StreamingPreferences.fps },
                onSelect: function(value) { applyFps(value) },
                onAdd: function(text) {
                    var fps = parseInt(text, 10)
                    if (!isNaN(fps) && fps >= 10 && fps <= 9999) {
                        applyFps(fps)
                    }
                }
            },
            {
                id: "bitrate", type: "slider",
                label: qsTr("Video Bitrate"),
                popupTitle: qsTr("Bitrate"),
                valueLabel: function() { return formatMbps(StreamingPreferences.bitrateKbps) },
                min: function() { return 500 },
                max: function() { return StreamingPreferences.unlockBitrate ? 500000 : 150000 },
                step: 500,
                value: function() { return StreamingPreferences.bitrateKbps },
                onChange: function(v, isReset) {
                    StreamingPreferences.bitrateKbps = v
                    StreamingPreferences.autoAdjustBitrate = isReset === true
                },
                resetTo: function() {
                    var d = StreamingPreferences.getDefaultBitrate(
                                StreamingPreferences.width, StreamingPreferences.height,
                                StreamingPreferences.fps, StreamingPreferences.enableYUV444)
                    if (d === StreamingPreferences.bitrateKbps) {
                        return null
                    }
                    return { label: qsTr("Use default (%1 Mbps)").arg((d / 1000.0).toFixed(0)), value: d }
                }
            },
            {
                id: "windowMode", type: "choice",
                label: qsTr("Display Mode"),
                popupTitle: qsTr("Choose a Display Mode"),
                visible: function() { return SystemProperties.hasDesktopEnvironment },
                enabled: function() { return !SystemProperties.rendererAlwaysFullScreen },
                valueLabel: function() { return windowModeLabel(StreamingPreferences.windowMode) },
                buildOptions: function() {
                    var modes = [StreamingPreferences.WM_FULLSCREEN,
                                 StreamingPreferences.WM_FULLSCREEN_DESKTOP,
                                 StreamingPreferences.WM_WINDOWED]
                    var out = []
                    for (var i = 0; i < modes.length; i++) {
                        out.push({
                            label: windowModeLabel(modes[i]),
                            value: modes[i],
                            recommended: modes[i] === StreamingPreferences.recommendedFullScreenMode,
                            current: modes[i] === StreamingPreferences.windowMode
                        })
                    }
                    return out
                },
                onSelect: function(value) { StreamingPreferences.windowMode = value }
            },
            {
                id: "vsync", type: "toggle",
                label: qsTr("V-Sync"),
                checked: function() { return StreamingPreferences.enableVsync },
                toggle: function() { StreamingPreferences.enableVsync = !StreamingPreferences.enableVsync }
            },
            {
                id: "framePacing", type: "toggle",
                label: qsTr("Frame Pacing"),
                enabled: function() { return StreamingPreferences.enableVsync },
                checked: function() { return StreamingPreferences.enableVsync && StreamingPreferences.framePacing },
                toggle: function() { StreamingPreferences.framePacing = !StreamingPreferences.framePacing }
            },
            {
                id: "hdr", type: "toggle",
                label: qsTr("Enable HDR"),
                enabled: function() { return SystemProperties.supportsHdr },
                checked: function() { return SystemProperties.supportsHdr && StreamingPreferences.enableHdr },
                toggle: function() { StreamingPreferences.enableHdr = !StreamingPreferences.enableHdr }
            }
        ]

        // -------------------------------------------------------------- Audio
        var audioRows = [
            {
                id: "audioConfig", type: "choice",
                label: qsTr("Audio Configuration"),
                popupTitle: qsTr("Choose an Audio Configuration"),
                valueLabel: function() {
                    var c = StreamingPreferences.audioConfig
                    if (c === StreamingPreferences.AC_51_SURROUND) return qsTr("5.1 surround sound")
                    if (c === StreamingPreferences.AC_71_SURROUND) return qsTr("7.1 surround sound")
                    return qsTr("Stereo")
                },
                buildOptions: function() {
                    return enumOptions([
                        [qsTr("Stereo"), StreamingPreferences.AC_STEREO],
                        [qsTr("5.1 surround sound"), StreamingPreferences.AC_51_SURROUND],
                        [qsTr("7.1 surround sound"), StreamingPreferences.AC_71_SURROUND]
                    ], StreamingPreferences.audioConfig)
                },
                onSelect: function(value) { StreamingPreferences.audioConfig = value }
            },
            {
                id: "muteHost", type: "toggle",
                label: qsTr("Mute host PC speakers while streaming"),
                checked: function() { return !StreamingPreferences.playAudioOnHost },
                toggle: function() { StreamingPreferences.playAudioOnHost = !StreamingPreferences.playAudioOnHost }
            },
            {
                id: "muteOnFocusLoss", type: "toggle",
                label: qsTr("Mute audio when Moonlight is not active"),
                visible: function() { return SystemProperties.hasDesktopEnvironment },
                checked: function() { return StreamingPreferences.muteOnFocusLoss },
                toggle: function() { StreamingPreferences.muteOnFocusLoss = !StreamingPreferences.muteOnFocusLoss }
            }
        ]

        // --------------------------------------------------------------- Host
        var hostRows = [
            { id: "hostinfo", type: "host" },
            {
                id: "gameOptimizations", type: "toggle",
                label: qsTr("Optimize game settings for streaming"),
                checked: function() { return StreamingPreferences.gameOptimizations },
                toggle: function() { StreamingPreferences.gameOptimizations = !StreamingPreferences.gameOptimizations }
            },
            {
                id: "quitAppAfter", type: "toggle",
                label: qsTr("Quit app on host after ending stream"),
                checked: function() { return StreamingPreferences.quitAppAfter },
                toggle: function() { StreamingPreferences.quitAppAfter = !StreamingPreferences.quitAppAfter }
            }
        ]

        // ----------------------------------------------------------------- UI
        // Full language list, verbatim from SettingsView.qml's languageListModel
        // -- see TASK-BRIEF.md's completeness requirement.
        var languagePairs = [
            [qsTr("Automatic"), StreamingPreferences.LANG_AUTO],
            ["Deutsch", StreamingPreferences.LANG_DE],
            ["English", StreamingPreferences.LANG_EN],
            ["Français", StreamingPreferences.LANG_FR],
            ["简体中文", StreamingPreferences.LANG_ZH_CN],
            ["Norwegian Bokmål", StreamingPreferences.LANG_NB_NO],
            ["русский", StreamingPreferences.LANG_RU],
            ["Español", StreamingPreferences.LANG_ES],
            ["日本語", StreamingPreferences.LANG_JA],
            ["Tiếng Việt", StreamingPreferences.LANG_VI],
            ["ภาษาไทย", StreamingPreferences.LANG_TH],
            ["한국어", StreamingPreferences.LANG_KO],
            ["Magyar", StreamingPreferences.LANG_HU],
            ["Nederlands", StreamingPreferences.LANG_NL],
            ["Svenska", StreamingPreferences.LANG_SV],
            ["Türkçe", StreamingPreferences.LANG_TR],
            ["繁體中文", StreamingPreferences.LANG_ZH_TW],
            ["Português", StreamingPreferences.LANG_PT],
            ["Português do Brasil", StreamingPreferences.LANG_PT_BR],
            ["Ελληνικά", StreamingPreferences.LANG_EL],
            ["Italiano", StreamingPreferences.LANG_IT],
            ["Język polski", StreamingPreferences.LANG_PL],
            ["Čeština", StreamingPreferences.LANG_CS],
            ["Български", StreamingPreferences.LANG_BG],
            ["தமிழ்", StreamingPreferences.LANG_TA]
        ]

        var uiRows = [
            {
                id: "language", type: "choice",
                label: qsTr("Language"),
                popupTitle: qsTr("Choose a Language"),
                valueLabel: function() {
                    for (var i = 0; i < languagePairs.length; i++) {
                        if (languagePairs[i][1] === StreamingPreferences.language) {
                            return languagePairs[i][0]
                        }
                    }
                    return qsTr("Automatic")
                },
                buildOptions: function() { return enumOptions(languagePairs, StreamingPreferences.language) },
                onSelect: function(value) {
                    if (StreamingPreferences.language === value) {
                        return
                    }
                    StreamingPreferences.language = value
                    if (!StreamingPreferences.retranslate()) {
                        // No dynamic retranslation available on this Qt
                        // version -- the same silent limitation
                        // SettingsView.qml's ToolTip used to surface. There is
                        // no toast component in Bulan yet, so this is recorded
                        // here rather than invented on the spot; the language
                        // still takes effect on next launch.
                    } else {
                        // Retranslating breaks AppView's retained instance,
                        // same as SettingsView.qml's own workaround -- see
                        // main.qml's goBack().
                        window.clearOnBack = true
                    }
                }
            },
            {
                id: "uiDisplayMode", type: "choice",
                label: qsTr("GUI Display Mode"),
                popupTitle: qsTr("Choose a GUI Display Mode"),
                visible: function() { return SystemProperties.hasDesktopEnvironment },
                valueLabel: function() {
                    var m = StreamingPreferences.uiDisplayMode
                    if (m === StreamingPreferences.UI_MAXIMIZED) return qsTr("Maximized")
                    if (m === StreamingPreferences.UI_FULLSCREEN) return qsTr("Fullscreen")
                    return qsTr("Windowed")
                },
                buildOptions: function() {
                    return enumOptions([
                        [qsTr("Windowed"), StreamingPreferences.UI_WINDOWED],
                        [qsTr("Maximized"), StreamingPreferences.UI_MAXIMIZED],
                        [qsTr("Fullscreen"), StreamingPreferences.UI_FULLSCREEN]
                    ], StreamingPreferences.uiDisplayMode)
                },
                onSelect: function(value) { StreamingPreferences.uiDisplayMode = value }
            },
            {
                id: "connectionWarnings", type: "toggle",
                label: qsTr("Show connection quality warnings"),
                checked: function() { return StreamingPreferences.connectionWarnings },
                toggle: function() { StreamingPreferences.connectionWarnings = !StreamingPreferences.connectionWarnings }
            },
            {
                id: "configurationWarnings", type: "toggle",
                label: qsTr("Show configuration warnings"),
                checked: function() { return StreamingPreferences.configurationWarnings },
                toggle: function() { StreamingPreferences.configurationWarnings = !StreamingPreferences.configurationWarnings }
            },
            {
                id: "richPresence", type: "toggle",
                label: qsTr("Discord Rich Presence"),
                visible: function() { return SystemProperties.hasDiscordIntegration },
                checked: function() { return StreamingPreferences.richPresence },
                toggle: function() { StreamingPreferences.richPresence = !StreamingPreferences.richPresence }
            },
            {
                id: "keepAwake", type: "toggle",
                label: qsTr("Keep the display awake while streaming"),
                checked: function() { return StreamingPreferences.keepAwake },
                toggle: function() { StreamingPreferences.keepAwake = !StreamingPreferences.keepAwake }
            },
            {
                id: "atmosphereGradient", type: "toggle",
                label: qsTr("Background gradient"),
                checked: function() { return StreamingPreferences.atmosphereGradientEnabled },
                toggle: function() { StreamingPreferences.atmosphereGradientEnabled = !StreamingPreferences.atmosphereGradientEnabled }
            },
            {
                id: "atmosphereVignette", type: "toggle",
                label: qsTr("Background vignette"),
                checked: function() { return StreamingPreferences.atmosphereVignetteEnabled },
                toggle: function() { StreamingPreferences.atmosphereVignetteEnabled = !StreamingPreferences.atmosphereVignetteEnabled }
            },
            {
                id: "atmosphereGrain", type: "toggle",
                label: qsTr("Background film grain"),
                checked: function() { return StreamingPreferences.atmosphereGrainEnabled },
                toggle: function() { StreamingPreferences.atmosphereGrainEnabled = !StreamingPreferences.atmosphereGrainEnabled }
            }
        ]

        // -------------------------------------------------------------- Input
        var inputRows = [
            {
                id: "absoluteMouseMode", type: "toggle",
                label: qsTr("Optimize mouse for remote desktop"),
                checked: function() { return StreamingPreferences.absoluteMouseMode },
                toggle: function() { StreamingPreferences.absoluteMouseMode = !StreamingPreferences.absoluteMouseMode }
            },
            {
                id: "captureSysKeys", type: "choice",
                label: qsTr("Capture system keyboard shortcuts"),
                popupTitle: qsTr("Capture System Keyboard Shortcuts"),
                // Desktop-only, matching SettingsView.qml's `enabled` gate --
                // there is no system-wide Alt+Tab to capture on a platform
                // with no desktop environment, so the whole row is hidden
                // there rather than shown disabled with nothing to explain
                // why.
                visible: function() { return SystemProperties.hasDesktopEnvironment },
                valueLabel: function() {
                    var m = StreamingPreferences.captureSysKeysMode
                    if (m === StreamingPreferences.CSK_FULLSCREEN) return qsTr("In fullscreen")
                    if (m === StreamingPreferences.CSK_ALWAYS) return qsTr("Always")
                    return qsTr("Off")
                },
                buildOptions: function() {
                    return enumOptions([
                        [qsTr("Off"), StreamingPreferences.CSK_OFF],
                        [qsTr("In fullscreen"), StreamingPreferences.CSK_FULLSCREEN],
                        [qsTr("Always"), StreamingPreferences.CSK_ALWAYS]
                    ], StreamingPreferences.captureSysKeysMode)
                },
                onSelect: function(value) { StreamingPreferences.captureSysKeysMode = value }
            },
            {
                id: "absoluteTouchMode", type: "toggle",
                label: qsTr("Use touchscreen as a virtual trackpad"),
                checked: function() { return !StreamingPreferences.absoluteTouchMode },
                toggle: function() { StreamingPreferences.absoluteTouchMode = !StreamingPreferences.absoluteTouchMode }
            },
            {
                id: "swapMouseButtons", type: "toggle",
                label: qsTr("Swap left and right mouse buttons"),
                checked: function() { return StreamingPreferences.swapMouseButtons },
                toggle: function() { StreamingPreferences.swapMouseButtons = !StreamingPreferences.swapMouseButtons }
            },
            {
                id: "reverseScrollDirection", type: "toggle",
                label: qsTr("Reverse mouse scrolling direction"),
                checked: function() { return StreamingPreferences.reverseScrollDirection },
                toggle: function() { StreamingPreferences.reverseScrollDirection = !StreamingPreferences.reverseScrollDirection }
            }
        ]

        // ------------------------------------------------------------ Gamepad
        var gamepadRows = [
            {
                id: "swapFaceButtons", type: "toggle",
                label: qsTr("Swap A/B and X/Y gamepad buttons"),
                checked: function() { return StreamingPreferences.swapFaceButtons },
                toggle: function() { StreamingPreferences.swapFaceButtons = !StreamingPreferences.swapFaceButtons }
            },
            {
                id: "multiController", type: "toggle",
                label: qsTr("Force gamepad #1 always connected"),
                checked: function() { return !StreamingPreferences.multiController },
                toggle: function() { StreamingPreferences.multiController = !StreamingPreferences.multiController }
            },
            {
                id: "gamepadMouse", type: "toggle",
                label: qsTr("Hold Start for mouse control"),
                checked: function() { return StreamingPreferences.gamepadMouse },
                toggle: function() { StreamingPreferences.gamepadMouse = !StreamingPreferences.gamepadMouse }
            },
            {
                id: "backgroundGamepad", type: "toggle",
                label: qsTr("Process gamepad input in the background"),
                visible: function() { return SystemProperties.hasDesktopEnvironment },
                checked: function() { return StreamingPreferences.backgroundGamepad },
                toggle: function() { StreamingPreferences.backgroundGamepad = !StreamingPreferences.backgroundGamepad }
            }
        ]

        // ------------------------------------------------------------ Advanced
        var advancedRows = [
            {
                id: "videoDecoder", type: "choice",
                label: qsTr("Video Decoder"),
                popupTitle: qsTr("Choose a Video Decoder"),
                valueLabel: function() {
                    var v = StreamingPreferences.videoDecoderSelection
                    if (v === StreamingPreferences.VDS_FORCE_SOFTWARE) return qsTr("Force software")
                    if (v === StreamingPreferences.VDS_FORCE_HARDWARE) return qsTr("Force hardware")
                    return qsTr("Automatic")
                },
                buildOptions: function() {
                    return enumOptions([
                        [qsTr("Automatic (Recommended)"), StreamingPreferences.VDS_AUTO],
                        [qsTr("Force software decoding"), StreamingPreferences.VDS_FORCE_SOFTWARE],
                        [qsTr("Force hardware decoding"), StreamingPreferences.VDS_FORCE_HARDWARE]
                    ], StreamingPreferences.videoDecoderSelection)
                },
                onSelect: function(value) { StreamingPreferences.videoDecoderSelection = value }
            },
            {
                id: "videoCodec", type: "choice",
                label: qsTr("Video Codec"),
                popupTitle: qsTr("Choose a Video Codec"),
                valueLabel: function() {
                    var v = StreamingPreferences.videoCodecConfig
                    if (v === StreamingPreferences.VCC_FORCE_H264) return "H.264"
                    if (v === StreamingPreferences.VCC_FORCE_HEVC) return qsTr("HEVC (H.265)")
                    if (v === StreamingPreferences.VCC_FORCE_AV1) return "AV1"
                    return qsTr("Automatic")
                },
                buildOptions: function() {
                    return enumOptions([
                        [qsTr("Automatic (Recommended)"), StreamingPreferences.VCC_AUTO],
                        ["H.264", StreamingPreferences.VCC_FORCE_H264],
                        [qsTr("HEVC (H.265)"), StreamingPreferences.VCC_FORCE_HEVC],
                        ["AV1", StreamingPreferences.VCC_FORCE_AV1]
                    ], StreamingPreferences.videoCodecConfig)
                },
                onSelect: function(value) { StreamingPreferences.videoCodecConfig = value }
            },
            {
                id: "renderer", type: "choice",
                label: qsTr("Renderer"),
                popupTitle: qsTr("Choose a Renderer"),
                visible: function() { return SystemProperties.isDarwin },
                valueLabel: function() {
                    var v = StreamingPreferences.rendererSelection
                    if (v === StreamingPreferences.RS_VULKAN) return "Vulkan"
                    if (v === StreamingPreferences.RS_METAL) return "Metal"
                    if (v === StreamingPreferences.RS_AVSBDL) return "AVSampleBufferDisplayLayer"
                    return qsTr("Automatic")
                },
                buildOptions: function() {
                    return enumOptions([
                        [qsTr("Automatic (Recommended)"), StreamingPreferences.RS_AUTO],
                        ["Vulkan", StreamingPreferences.RS_VULKAN],
                        ["Metal", StreamingPreferences.RS_METAL],
                        ["AVSampleBufferDisplayLayer", StreamingPreferences.RS_AVSBDL]
                    ], StreamingPreferences.rendererSelection)
                },
                onSelect: function(value) { StreamingPreferences.rendererSelection = value }
            },
            {
                id: "yuv444", type: "toggle",
                label: qsTr("Enable YUV 4:4:4"),
                checked: function() { return StreamingPreferences.enableYUV444 },
                toggle: function() {
                    StreamingPreferences.enableYUV444 = !StreamingPreferences.enableYUV444
                    if (StreamingPreferences.autoAdjustBitrate) {
                        StreamingPreferences.bitrateKbps = StreamingPreferences.getDefaultBitrate(
                                    StreamingPreferences.width, StreamingPreferences.height,
                                    StreamingPreferences.fps, StreamingPreferences.enableYUV444)
                    }
                }
            },
            {
                id: "unlockBitrate", type: "toggle",
                label: qsTr("Unlock bitrate limit (Experimental)"),
                checked: function() { return StreamingPreferences.unlockBitrate },
                toggle: function() {
                    StreamingPreferences.unlockBitrate = !StreamingPreferences.unlockBitrate
                    var maxKbps = StreamingPreferences.unlockBitrate ? 500000 : 150000
                    StreamingPreferences.bitrateKbps = Math.min(StreamingPreferences.bitrateKbps, maxKbps)
                }
            },
            {
                id: "enableMdns", type: "toggle",
                label: qsTr("Automatically find PCs on the network (Recommended)"),
                checked: function() { return StreamingPreferences.enableMdns },
                toggle: function() {
                    StreamingPreferences.enableMdns = !StreamingPreferences.enableMdns
                    if (window.pollingActive) {
                        ComputerManager.stopPollingAsync()
                        ComputerManager.startPolling()
                    }
                }
            },
            {
                id: "detectNetworkBlocking", type: "toggle",
                label: qsTr("Automatically detect blocked connections (Recommended)"),
                checked: function() { return StreamingPreferences.detectNetworkBlocking },
                toggle: function() { StreamingPreferences.detectNetworkBlocking = !StreamingPreferences.detectNetworkBlocking }
            },
            {
                id: "showPerformanceOverlay", type: "toggle",
                label: qsTr("Show performance stats while streaming"),
                checked: function() { return StreamingPreferences.showPerformanceOverlay },
                toggle: function() { StreamingPreferences.showPerformanceOverlay = !StreamingPreferences.showPerformanceOverlay }
            }
        ]

        return [
            { id: "basic", label: qsTr("Basic"), rows: basicRows },
            { id: "audio", label: qsTr("Audio"), rows: audioRows },
            { id: "host", label: qsTr("Host"), rows: hostRows },
            { id: "ui", label: qsTr("UI"), rows: uiRows },
            { id: "input", label: qsTr("Input"), rows: inputRows },
            { id: "gamepad", label: qsTr("Gamepad"), rows: gamepadRows },
            { id: "advanced", label: qsTr("Advanced"), rows: advancedRows },
            { id: "about", label: qsTr("About"), rows: [] }
        ]
    }
}
