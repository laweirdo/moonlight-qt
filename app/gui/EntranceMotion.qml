import QtQuick 2.9

import Bulan 1.0

// -----------------------------------------------------------------------------
// The one post-transition entrance every Bulan screen uses for its own content.
//
// The screen transition in main.qml moves the whole screen into place. That is
// travel, not arrival: once it settles, the content is simply already there.
// AppView's game tiles and HostCarousel's zero-host state each answered that by
// rising and fading in after the travel finished, and the onboarding screens --
// FirstRun, HostDiscovery, PairView -- had no equivalent, so walking the route
// alternated between screens whose content arrived and screens whose content
// was just present.
//
// Declared once here rather than copied per screen, the same reason
// PopupMotion.qml exists: cadence, delay, travel distance and overshoot live in
// one file, and no screen carries a raw motion value of its own.
//
// Usage -- one instance per element that should arrive, `order` counting up in
// reading order, all of them gated on the same `started` flag:
//
//     Timer { id: gate; interval: Bulan.motionGridEntranceDelayMs
//             running: true; onTriggered: root.entranceStarted = true }
//
//     EntranceMotion { id: titleMotion;    order: 0; started: root.entranceStarted }
//     EntranceMotion { id: subtitleMotion; order: 1; started: root.entranceStarted }
//
//     Text { opacity: titleMotion.fadeOpacity
//            transform: Translate { y: titleMotion.riseOffset } }
//
// Translate rather than `y`, because these elements are Column children and the
// Column owns their y. A transform offsets what is drawn without moving what the
// layout thinks is there, so the entrance cannot reflow the screen.
//
// The delay is motionGridEntranceDelayMs, which is the transition duration --
// the rise begins as the screen stops moving, never during it, so the two
// motions never compete for the eye.
//
// Nothing here gates input. `started` only drives what the element looks like;
// key handlers and focus are live from the moment the screen is pushed. When
// input does arrive mid-flight, call settle() and the entrance ends at its
// resting value immediately rather than being left half-played.
// -----------------------------------------------------------------------------

QtObject {
    id: motion

    // Stagger step. Capped so a long column cannot push its last element into
    // arriving noticeably after the player has already started moving -- the
    // same cap the game grid's tile entrance uses.
    property int order: 0

    // Flip once, when the screen transition has settled.
    property bool started: false

    // 0 before the entrance, 1 once settled. Passes above 1 mid-flight, which
    // is where the overshoot comes from.
    property real progress: 0

    readonly property int step:
        Math.min(order, Bulan.motionGridEntranceMaxSteps)

    // Travel remaining, in pixels. Bind to a Translate's y: full offset at rest,
    // zero once settled. Inherits the overshoot, so this crosses zero once and
    // comes back -- the element rises slightly past its resting place and drops
    // onto it.
    readonly property real riseOffset:
        (1 - progress) * Bulan.motionGridEntranceRise

    // Clamped, so only the travel carries the overshoot. Without this an
    // element would flash brighter than its settled opacity as it landed -- the
    // same correction the grid's tile entrance and PopupMotion both needed.
    readonly property real fadeOpacity: Math.min(1, progress)

    readonly property SequentialAnimation enterAnimation: SequentialAnimation {
        PauseAnimation {
            duration: motion.step * Bulan.motionGridEntranceStaggerMs
        }
        NumberAnimation {
            target: motion
            property: "progress"
            to: 1
            duration: Bulan.motionGridEntranceRiseMs
            easing.type: Easing.OutBack
            easing.overshoot: Bulan.motionEntranceOvershoot
        }
    }

    // Ends the entrance where it would have ended anyway. Called when the
    // player acts before the screen has finished arriving: the alternative is
    // either freezing them out until it does, or leaving an element stranded
    // part-risen when its animation is cut.
    function settle() {
        enterAnimation.stop()
        progress = 1
    }

    onStartedChanged: {
        if (started && progress < 1) {
            enterAnimation.start()
        }
    }
}
