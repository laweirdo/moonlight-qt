import QtQuick 2.9
// Imported for the StackView attached properties only -- no stock control
// from this module is instantiated anywhere on this screen.
import QtQuick.Controls 2.2
import ComputerModel 1.0
import ComputerManager 1.0
import SdlGamepadKeyNavigation 1.0

import Bulan 1.0

// -----------------------------------------------------------------------------
// S0: the vertical lockup, alone, on the atmosphere. Nothing else.
//
// This is the app's very first screen, pushed by main.qml's initial
// push(initialView, StackView.Immediate) -- so, like that push, it must not
// animate on arrival. It holds for onboardingSplashHoldMs, skippable by any
// key, then decides where the app actually starts: the host carousel if a
// host is already known and paired, first run otherwise.
//
// It REPLACES itself (clear() then push(); see proceed() below) rather than
// pushing on top, so it is never left on the stack for the next screen's B
// to return to, and it is gone before that screen's own Escape/B handling
// could ever matter.
//
// A "press lost after the splash hands off" defect was reported against this
// screen during implementation and investigated: it does not exist. The
// measurement behind it sent a single press at a moment when this screen was
// still up -- the hold does not begin until QML has loaded, about a second
// after launch, so a press at t=2s arrives here, not at FirstRun -- and this
// screen consumed it exactly as the skip behaviour below is meant to. The
// press that "vanished" was the skip working.
//
// Retested deliberately: two presses 400ms apart, the first skipping the
// hold and the second landing 400ms after the stack swap. The second was
// acted on by the newly pushed screen. There is no gap, and nothing here
// needs to compensate for one.
// -----------------------------------------------------------------------------

FocusScope {
    id: root
    objectName: qsTr("Bulan")
    focus: true

    // Debug hook: MOONLIGHT_FORCE_FIRST_RUN=1 always continues to FirstRun
    // even when a host is already paired. Without this, first run could only
    // ever be reached once per review station -- the very first paired host
    // would close the door on looking at S1-S3 again.
    readonly property bool forceFirstRun:
        typeof forceFirstRunReview !== "undefined" && forceFirstRunReview

    // A throwaway model, exactly like HostCarousel.createModel() -- it exists
    // only to answer "is anything paired yet", not to be shown.
    property ComputerModel computerModel: createModel()
    function createModel() {
        var model = Qt.createQmlObject('import ComputerModel 1.0; ComputerModel {}', root, '')
        model.initialize(ComputerManager)
        return model
    }

    // True once any known host reports itself paired. ComputerModel's data()
    // is a plain override, not Q_INVOKABLE, so a role can only be read
    // through a delegate's own `model.paired` -- the same reason
    // HostCarousel's hidden `counter` Repeater exists, copied here for the
    // same reason at a smaller scale.
    property bool anyPairedHost: false
    function recomputePaired() {
        for (var i = 0; i < pairedCounter.count; i++) {
            var it = pairedCounter.itemAt(i)
            if (it && it.isPaired) {
                anyPairedHost = true
                return
            }
        }
        anyPairedHost = false
    }

    Item {
        visible: false
        Repeater {
            id: pairedCounter
            model: root.computerModel
            delegate: Item {
                readonly property bool isPaired: model.paired
                onIsPairedChanged: root.recomputePaired()
            }
            onItemAdded: root.recomputePaired()
            onItemRemoved: root.recomputePaired()
        }
    }

    property bool proceeded: false
    function proceed() {
        if (proceeded) {
            return
        }
        proceeded = true
        holdTimer.stop()
        // Stop reacting to the live ComputerModel before leaving. This
        // screen's own StackView removal is not guaranteed to run within the
        // same tick, and while it is still technically alive it would
        // otherwise keep processing real discovery events (a host coming
        // online, going away) through pairedCounter's delegates for however
        // long that takes.
        pairedCounter.model = null
        var target = (root.anyPairedHost && !root.forceFirstRun)
                ? "HostCarousel.qml" : "FirstRun.qml"
        // clear() then push(), not replace() in any form. Both
        // replace(null, ...) and the self-replace
        // stackView.replace(stackView.currentItem, target, ...) are the old
        // StackView 1.x idiom carrying real ambiguity about what a null or
        // self target means; clear()+push() is two separately well-defined
        // operations instead. Immediate, matching the app's very first push
        // in main.qml -- there is nothing on screen yet to move from.
        stackView.clear(StackView.Immediate)
        stackView.push(target, StackView.Immediate)
    }

    Timer {
        id: holdTimer
        interval: Bulan.onboardingSplashHoldMs
        running: true
        onTriggered: root.proceed()
    }

    // Skippable by any button press. This screen carries no interaction of
    // its own for a press to conflict with, so nothing here needs to
    // distinguish one key from another.
    //
    // Guarded on `proceeded` rather than accepting unconditionally: this
    // item's removal from the stack (clear()/push() in proceed() above) is
    // not guaranteed to destroy it within the same tick, and a QML item
    // that is visually gone but not yet destroyed can still sit in the
    // key-event delivery chain for the next event or two. An unconditional
    // `event.accepted = true` here would silently swallow a press meant for
    // whatever screen replaced this one, with proceed()'s own re-entry
    // guard making the swallow invisible from this function's own behaviour
    // (the second call does nothing observable either way). Once already
    // proceeded, this stale instance must let a press fall through
    // untouched rather than consume it. Defensive rather than observed: no
    // swallowed press was ever measured here, but an already-departed screen
    // holding onto input is the kind of thing that only shows up as an
    // occasional dead button much later.
    Keys.onPressed: function(event) {
        if (root.proceeded) {
            return
        }
        root.proceed()
        event.accepted = true
    }

    StackView.onActivated: {
        root.forceActiveFocus()
        root.recomputePaired()
    }

    // Deliberately does NOT wire up HostCarousel's reclaimFocus() dance: no
    // overlay ever opens on this screen, so there is nothing that could
    // strand focus the way a torn-down panel does there.
    readonly property bool bulanScreen: true

    Item {
        anchors.fill: parent

        Atmosphere {
            anchors.fill: parent
        }

        Image {
            anchors.centerIn: parent
            source: "qrc:/res/bulan_logo_vert.svg"
            // Mirrors HostCarousel's wordmark: bind height to a token
            // multiple of sizeDisplay rather than a fresh raw number, and
            // rasterize at twice that so the SVG stays crisp scaled up.
            height: Bulan.sizeDisplay * 3
            fillMode: Image.PreserveAspectFit
            sourceSize.height: height * 2
            smooth: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.proceed()
        }
    }
}
