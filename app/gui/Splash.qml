// 2.12, not the 2.9 the rest of the app inherited from upstream: Animation's
// `finished` signal arrived in that version, and it is the one signal that
// separates "the fade ran out" from "the fade was stopped" -- which is exactly
// the distinction the splash sequence below turns on. `stopped` fires for both
// and would have the fade-in start the hold on its way out.
import QtQuick 2.12
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
// push(initialView, StackView.Immediate) -- so, like that push, the SCREEN must
// not animate on arrival. The atmosphere behind it is the window's own and is
// already on screen before this exists.
//
// The logo does animate, and is the only thing here that does. It dissolves in
// over motionSplashFadeMs, holds for onboardingSplashHoldMs, dissolves out
// again, and only once it has actually reached nothing does the app decide
// where it really starts: the host carousel if a host is already known and
// paired, first run otherwise (client decision, 20 August 2026 -- the logo used
// to cut in and cut out).
//
// Four phases, in one `phase` property: fadingIn, holding, fadingOut,
// handedOff. Any input during the first two goes straight to fadingOut from
// wherever the logo currently is, at a duration scaled by that opacity so the
// dissolve keeps the same speed rather than jumping; reversing mid-fade-in is
// therefore continuous, not a cut. Input after that changes nothing.
//
// It REPLACES itself (clear() then push(); see handOff() below) rather than
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

    // --- the splash sequence -------------------------------------------------
    // "fadingIn" -> "holding" -> "fadingOut" -> "handedOff", in that order and
    // never backwards. Leaving early skips straight from one of the first two
    // to "fadingOut"; nothing skips the fade-out itself.
    property string phase: "fadingIn"

    // Asking to leave. Separate from actually leaving, which is the whole point
    // of the rework: a skip used to swap the stack out from under the logo, so
    // whatever the logo was doing at the time simply stopped existing. This
    // only ever starts the dissolve. handOff() below is what leaves, and it
    // runs when the dissolve is finished and not before.
    function requestExit() {
        // Only the two interruptible phases answer. During the fade-out the
        // request has already been made and is being carried out; after the
        // handoff there is nothing left to ask.
        if (phase !== "fadingIn" && phase !== "holding") {
            return
        }
        fadeIn.stop()
        holdTimer.stop()
        // Scaled by where the logo actually is, so opacity keeps roughly the
        // same speed through the reversal instead of the fade-out starting
        // slower than the fade-in it interrupted. A quarter of the way in is a
        // quarter of the time back out. No floor: at opacity 0 this is a 0ms
        // fade, which is exactly right -- there is nothing on screen to
        // dissolve.
        startFadeOut(Math.round(Bulan.motionSplashFadeMs * logo.opacity))
    }

    function startFadeOut(duration) {
        phase = "fadingOut"
        fadeOut.duration = duration
        fadeOut.start()
    }

    // Leaving. Guarded so it can only ever run once, as the old handoff guard
    // was.
    function handOff() {
        if (phase === "handedOff") {
            return
        }
        phase = "handedOff"
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
        // in main.qml -- and the logo has already reached nothing by the time
        // this runs, so there is no crossfade between the two screens and
        // nothing for a transition to do.
        stackView.clear(StackView.Immediate)
        stackView.push(target, StackView.Immediate)
    }

    // Both animations drive the logo's opacity and nothing else. Neither names
    // a `from`: each starts from wherever the logo currently is, which is what
    // makes an interrupted fade-in reverse continuously rather than jump.
    //
    // `finished` is emitted on natural completion only, not on stop(), so
    // interrupting the fade-in cannot also fire its completion. The phase
    // guard below is belt and braces.
    NumberAnimation {
        id: fadeIn
        target: logo
        property: "opacity"
        to: 1
        duration: Bulan.motionSplashFadeMs
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.phase === "fadingIn") {
                root.phase = "holding"
                holdTimer.start()
            }
        }
    }

    NumberAnimation {
        id: fadeOut
        target: logo
        property: "opacity"
        to: 0
        duration: Bulan.motionSplashFadeMs
        easing.type: Easing.OutCubic
        onFinished: root.handOff()
    }

    // Not `running: true`. The hold no longer begins at startup; it begins when
    // the logo has finished arriving.
    Timer {
        id: holdTimer
        interval: Bulan.onboardingSplashHoldMs
        onTriggered: root.startFadeOut(Bulan.motionSplashFadeMs)
    }

    // Skippable by any button press. This screen carries no interaction of
    // its own for a press to conflict with, so nothing here needs to
    // distinguish one key from another.
    //
    // Guarded on the phase rather than accepting unconditionally: this item's
    // removal from the stack (clear()/push() in handOff() above) is not
    // guaranteed to destroy it within the same tick, and a QML item that is
    // visually gone but not yet destroyed can still sit in the key-event
    // delivery chain for the next event or two. An unconditional
    // `event.accepted = true` here would silently swallow a press meant for
    // whatever screen replaced this one, with the re-entry guard making the
    // swallow invisible from the function's own behaviour (the second call does
    // nothing observable either way). Once handed off, this stale instance must
    // let a press fall through untouched rather than consume it. Defensive
    // rather than observed: no swallowed press was ever measured here, but an
    // already-departed screen holding onto input is the kind of thing that only
    // shows up as an occasional dead button much later.
    //
    // The fade-out is guarded the same way and for the same reason. Once the
    // dissolve has begun the request has been made and this screen has nothing
    // left to do with a press, so it declines it rather than consuming it --
    // exactly the two phases that can still act on input are the two that
    // accept it (client decision, 20 August 2026).
    Keys.onPressed: function(event) {
        if (root.phase !== "fadingIn" && root.phase !== "holding") {
            return
        }
        root.requestExit()
        event.accepted = true
    }

    // The sequence begins when this screen owns the display, not when the
    // component happens to be constructed: an item built off the stack, or
    // ahead of its push, must not spend its fade-in somewhere the player cannot
    // see it. Guarded rather than unconditional so a second activation can
    // neither restart a running fade nor rewind one already past.
    StackView.onActivated: {
        root.forceActiveFocus()
        root.recomputePaired()
        if (root.phase === "fadingIn" && !fadeIn.running && logo.opacity === 0) {
            fadeIn.start()
        }
    }

    // Deliberately does NOT wire up HostCarousel's reclaimFocus() dance: no
    // overlay ever opens on this screen, so there is nothing that could
    // strand focus the way a torn-down panel does there.
    readonly property bool bulanScreen: true

    // No Atmosphere here. The window owns the one persistent atmosphere and it
    // is already drawn, behind this and behind whatever replaces it, which is
    // what lets the logo dissolve away over a ground that does not move.
    Item {
        anchors.fill: parent

        Image {
            id: logo
            anchors.centerIn: parent
            // The only animated property on this screen. Starts at nothing;
            // fadeIn takes it up.
            opacity: 0
            source: "qrc:/res/bulan_logo_vert.svg"
            // Mirrors HostCarousel's wordmark: bind height to a token
            // multiple of sizeDisplay rather than a fresh raw number, and
            // rasterize at twice that so the SVG stays crisp scaled up.
            height: Bulan.sizeDisplay * 3
            fillMode: Image.PreserveAspectFit
            sourceSize.height: height * 2
            smooth: true
        }

        // The same request-exit path as a key or a controller button, so a
        // click dissolves the logo out rather than cutting it.
        MouseArea {
            anchors.fill: parent
            onClicked: root.requestExit()
        }
    }
}
