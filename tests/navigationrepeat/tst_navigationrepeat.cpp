// Unit tests for the controller navigation repeat clock.
//
// This helper exists to be testable: hold-to-repeat timing is the one part of
// the gamepad path that can be proved without a controller in someone's hands,
// and it is the part where a wrong number is invisible in review and maddening
// in use.

#include <QtTest>

#include "navigationrepeat.h"

class tst_NavigationRepeat : public QObject
{
    Q_OBJECT

private slots:
    void immediatePress();
    void noRepeatBeforeInitialDelay();
    void firstRepeatAtInitialDelay();
    void subsequentRepeatsUseShortInterval();
    void latePollingEmitsOnlyOneRepeat();
    void duplicatePressDoesNotRestartDelay();
    void releaseCancelsRepeat();
    void directionsTrackIndependently();
    void resetClearsEverything();
    void tickWrapDoesNotStallRepeat();
};

static NavigationRepeatState makeState()
{
    return NavigationRepeatState(NAV_REPEAT_INITIAL_DELAY_MS,
                                 NAV_REPEAT_INTERVAL_MS);
}

void tst_NavigationRepeat::immediatePress()
{
    NavigationRepeatState state = makeState();

    QVERIFY(!state.held(NavigationDirection::Right));
    QCOMPARE(state.setHeld(NavigationDirection::Right, true, 1000),
             NavigationRepeatState::Edge::Press);
    QVERIFY(state.held(NavigationDirection::Right));
}

void tst_NavigationRepeat::noRepeatBeforeInitialDelay()
{
    NavigationRepeatState state = makeState();

    state.setHeld(NavigationDirection::Right, true, 1000);

    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1000));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1200));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1349));
}

void tst_NavigationRepeat::firstRepeatAtInitialDelay()
{
    NavigationRepeatState state = makeState();

    QCOMPARE(state.setHeld(NavigationDirection::Right, true, 1000),
             NavigationRepeatState::Edge::Press);
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1349));
    QVERIFY(state.repeatDue(NavigationDirection::Right, 1350));
}

void tst_NavigationRepeat::subsequentRepeatsUseShortInterval()
{
    NavigationRepeatState state = makeState();

    state.setHeld(NavigationDirection::Right, true, 1000);
    QVERIFY(state.repeatDue(NavigationDirection::Right, 1350));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1449));
    QVERIFY(state.repeatDue(NavigationDirection::Right, 1450));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1549));
    QVERIFY(state.repeatDue(NavigationDirection::Right, 1550));
}

void tst_NavigationRepeat::latePollingEmitsOnlyOneRepeat()
{
    NavigationRepeatState state = makeState();

    state.setHeld(NavigationDirection::Right, true, 1000);
    QVERIFY(state.repeatDue(NavigationDirection::Right, 1350));

    // A poll that arrives far late -- a stalled frame, a blocked event loop --
    // must not pay out the repeats it slept through. Six queued moves arriving
    // in one frame is exactly the runaway this whole helper exists to stop.
    QVERIFY(state.repeatDue(NavigationDirection::Right, 2000));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 2000));

    // And the cadence restarts from the poll that was actually served.
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 2099));
    QVERIFY(state.repeatDue(NavigationDirection::Right, 2100));
}

void tst_NavigationRepeat::duplicatePressDoesNotRestartDelay()
{
    NavigationRepeatState state = makeState();

    QCOMPARE(state.setHeld(NavigationDirection::Right, true, 1000),
             NavigationRepeatState::Edge::Press);

    // A second source asserting the same direction -- the other pad's d-pad, or
    // an analogue stick joining a d-pad already held -- is not a new press and
    // must not push the first repeat further away.
    QCOMPARE(state.setHeld(NavigationDirection::Right, true, 1200),
             NavigationRepeatState::Edge::None);

    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1349));
    QVERIFY(state.repeatDue(NavigationDirection::Right, 1350));
}

void tst_NavigationRepeat::releaseCancelsRepeat()
{
    NavigationRepeatState state = makeState();

    state.setHeld(NavigationDirection::Right, true, 1000);
    QCOMPARE(state.setHeld(NavigationDirection::Right, false, 1100),
             NavigationRepeatState::Edge::Release);
    QVERIFY(!state.held(NavigationDirection::Right));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 2000));

    // Releasing something that was never held says nothing happened.
    QCOMPARE(state.setHeld(NavigationDirection::Right, false, 1200),
             NavigationRepeatState::Edge::None);

    // A fresh press starts a fresh initial delay, not a resumed one.
    QCOMPARE(state.setHeld(NavigationDirection::Right, true, 2000),
             NavigationRepeatState::Edge::Press);
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 2349));
    QVERIFY(state.repeatDue(NavigationDirection::Right, 2350));
}

void tst_NavigationRepeat::directionsTrackIndependently()
{
    NavigationRepeatState state = makeState();

    state.setHeld(NavigationDirection::Right, true, 1000);
    state.setHeld(NavigationDirection::Down, true, 1200);

    QVERIFY(state.repeatDue(NavigationDirection::Right, 1350));
    QVERIFY(!state.repeatDue(NavigationDirection::Down, 1350));
    QVERIFY(state.repeatDue(NavigationDirection::Down, 1550));

    QCOMPARE(state.setHeld(NavigationDirection::Right, false, 1600),
             NavigationRepeatState::Edge::Release);
    QVERIFY(state.held(NavigationDirection::Down));
    QVERIFY(!state.repeatDue(NavigationDirection::Right, 1700));
    QVERIFY(state.repeatDue(NavigationDirection::Down, 1650));
}

void tst_NavigationRepeat::resetClearsEverything()
{
    NavigationRepeatState state = makeState();

    state.setHeld(NavigationDirection::Left, true, 1000);
    state.setHeld(NavigationDirection::Up, true, 1000);
    state.reset();

    QVERIFY(!state.held(NavigationDirection::Left));
    QVERIFY(!state.held(NavigationDirection::Up));
    QVERIFY(!state.repeatDue(NavigationDirection::Left, 5000));
}

void tst_NavigationRepeat::tickWrapDoesNotStallRepeat()
{
    NavigationRepeatState state = makeState();

    // SDL_GetTicks() wraps roughly every 49 days. Elapsed unsigned arithmetic
    // rides through it; an absolute-deadline comparison would leave a held
    // direction dead for the next 49 days.
    const quint32 justBeforeWrap = 0xFFFFFF00u;

    state.setHeld(NavigationDirection::Left, true, justBeforeWrap);
    QVERIFY(!state.repeatDue(NavigationDirection::Left, justBeforeWrap + 349u));
    QVERIFY(state.repeatDue(NavigationDirection::Left, justBeforeWrap + 350u));
    QVERIFY(state.repeatDue(NavigationDirection::Left, justBeforeWrap + 450u));
}

QTEST_APPLESS_MAIN(tst_NavigationRepeat)

#include "tst_navigationrepeat.moc"
