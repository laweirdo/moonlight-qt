#pragma once

#include <QtGlobal>

// -----------------------------------------------------------------------------
// Hold-to-repeat timing for controller navigation
//
// A keyboard arrow key held down moves once, pauses, then repeats steadily.
// That cadence is the whole reason a held key feels deliberate rather than
// twitchy, and the gamepad path used to have nothing like it: the d-pad emitted
// exactly one move per press and the analogue stick fired a fresh press/release
// pair every 150 ms from the instant it crossed the threshold -- no pause, no
// distinction between a tap and a hold.
//
// This class owns that cadence and nothing else. It knows no SDL, no Qt events
// and no screens, which is the point: hold timing is the one part of the gamepad
// route that can be proved correct without a controller in someone's hands.
// See tests/navigationrepeat/.
//
// Time is passed in rather than read, and every comparison is on ELAPSED
// unsigned ticks rather than an absolute deadline. SDL_GetTicks() wraps roughly
// every 49 days; unsigned subtraction rides through the wrap, while a stored
// "repeat at T" would leave a held direction dead until the clock caught up.
// -----------------------------------------------------------------------------

// Starting values, tuned against how a held keyboard arrow feels on this
// project's screens. Deliberately NOT design-system tokens: these describe the
// cadence of a hardware input, not the duration of anything drawn, and
// DESIGN-SYSTEM.md owns only the latter.
constexpr quint32 NAV_REPEAT_INITIAL_DELAY_MS = 350;
constexpr quint32 NAV_REPEAT_INTERVAL_MS = 100;

enum class NavigationDirection {
    Up,
    Down,
    Left,
    Right
};

constexpr int NAVIGATION_DIRECTION_COUNT = 4;

class NavigationRepeatState
{
public:
    // What a call to setHeld() actually changed. Edge::None means the caller
    // restated something already true -- a second controller pushing a
    // direction the first one is already holding -- and must send no event.
    enum class Edge {
        None,
        Press,
        Release
    };

    NavigationRepeatState(quint32 initialDelayMs,
                          quint32 repeatIntervalMs)
        : m_InitialDelayMs(initialDelayMs),
          m_RepeatIntervalMs(repeatIntervalMs)
    {
        reset();
    }

    // Reports whether a logical direction is currently held at all. The caller
    // decides what "held" means across several physical sources; this only
    // records the answer and times it.
    Edge setHeld(NavigationDirection direction, bool held, quint32 nowMs)
    {
        Entry& e = entry(direction);

        if (held == e.held) {
            return Edge::None;
        }

        e.held = held;

        if (held) {
            e.sinceMs = nowMs;
            e.repeated = false;
            return Edge::Press;
        }

        return Edge::Release;
    }

    // Asks whether a held direction has earned another move. Answering true
    // consumes the repeat, so this is called once per poll per direction.
    //
    // The clock restarts from the poll that was SERVED, not from when the
    // repeat theoretically became due. A poll arriving late -- a stalled frame,
    // a blocked event loop -- therefore pays out one move rather than the whole
    // backlog it slept through, which is the difference between a hold and a
    // sudden jump to the end of a row.
    bool repeatDue(NavigationDirection direction, quint32 nowMs)
    {
        Entry& e = entry(direction);

        if (!e.held) {
            return false;
        }

        const quint32 threshold = e.repeated ? m_RepeatIntervalMs
                                             : m_InitialDelayMs;
        if (nowMs - e.sinceMs < threshold) {
            return false;
        }

        e.sinceMs = nowMs;
        e.repeated = true;
        return true;
    }

    bool held(NavigationDirection direction) const
    {
        return entry(direction).held;
    }

    // Drops every direction without reporting a release. The caller owns
    // telling anyone that the keys went up -- see
    // SdlGamepadKeyNavigation::cancelHeldNavigation().
    void reset()
    {
        for (int i = 0; i < NAVIGATION_DIRECTION_COUNT; i++) {
            m_Entries[i] = Entry();
        }
    }

private:
    struct Entry {
        bool held = false;
        // True once this hold has produced at least one repeat, which is what
        // selects the short interval over the initial delay.
        bool repeated = false;
        // When the current wait started: the press, or the last repeat served.
        quint32 sinceMs = 0;
    };

    Entry& entry(NavigationDirection direction)
    {
        return m_Entries[static_cast<int>(direction)];
    }

    const Entry& entry(NavigationDirection direction) const
    {
        return m_Entries[static_cast<int>(direction)];
    }

    quint32 m_InitialDelayMs;
    quint32 m_RepeatIntervalMs;
    Entry m_Entries[NAVIGATION_DIRECTION_COUNT];
};
