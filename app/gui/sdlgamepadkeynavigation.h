#pragma once

#include <QTimer>
#include <QEvent>
#include <QHash>

#include "SDL_compat.h"

#include "navigationrepeat.h"
#include "settings/streamingpreferences.h"

class SdlGamepadKeyNavigation : public QObject
{
    Q_OBJECT

    // Which set of button glyphs the UI should draw, as an asset-name prefix:
    // "xinput", "ds", "switch". Always a family that actually has art bundled --
    // see resolveGlyphFamily(). Changes live as controllers come and go, so QML
    // bindings on it update without any explicit refresh.
    Q_PROPERTY(QString glyphFamily READ glyphFamily NOTIFY glyphFamilyChanged)

public:
    SdlGamepadKeyNavigation(StreamingPreferences* prefs);

    ~SdlGamepadKeyNavigation();

    Q_INVOKABLE void enable();

    Q_INVOKABLE void disable();

    Q_INVOKABLE void notifyWindowFocus(bool hasFocus);

    // The active SCREEN's navigation style: true means the settings page's tab
    // chain, false means arrow keys. Owned by whichever screen is current --
    // each one asserts its own on activation.
    Q_INVOKABLE void setUiNavMode(bool settingsMode);

    // A transient suspension of the above, for a popup that needs plain arrow
    // keys while it is open. Deliberately SEPARATE from setUiNavMode(): a popup
    // states only that it is open, never what the mode should be afterwards.
    //
    // This is what defect 1 was. The combo box used to restore the mode by
    // asserting it true on close, and a combo box torn down along with the
    // settings page fires that after the page has already reset the mode --
    // leaving the tab chain armed on a screen that does not use it, where A
    // sends Space and reaches nothing. Clearing a suspension cannot resurrect a
    // stale value, so the ordering stops mattering.
    Q_INVOKABLE void setNavModeSuspended(bool suspended);

    Q_INVOKABLE int getConnectedGamepads();

    QString glyphFamily() const { return m_GlyphFamily; }

signals:
    void glyphFamilyChanged();

private:
    // The mode actually in force: the screen's style, unless a popup is holding
    // it suspended. Every input decision reads this, never m_UiNavMode directly.
    bool uiNavActive() const { return m_UiNavMode && !m_NavModeSuspended; }

    void sendKey(QEvent::Type type, Qt::Key key,
                 Qt::KeyboardModifiers modifiers = Qt::NoModifier,
                 bool autoRepeat = false);

    // The ONE place a navigation direction becomes a keystroke. Both the mode
    // translation (the settings tab chain versus plain arrows) and the
    // auto-repeat flag live here, so a press, a repeat and a release of the
    // same direction can never disagree about which key they are.
    void sendDirectionKey(NavigationDirection direction, QEvent::Type type, bool autoRepeat);

    // --- held-direction bookkeeping ---
    //
    // A logical direction is held while ANY attached controller source holds
    // it. Sources are tracked per instance ID rather than merged, because the
    // Deck's built-in sticks and a plugged-in DualSense are both live at once:
    // letting go on one pad must not cancel a direction the other is still
    // pushing, and unplugging one must not leave the key stuck down.
    bool anySourceHolds(NavigationDirection direction) const;

    // Recomputes one direction from its sources and emits the press or release
    // edge if that moved. Every path that changes a source calls this.
    void refreshLogicalDirection(NavigationDirection direction);

    void refreshAllDirections();

    // Releases everything currently held, resets the repeat clocks, and refuses
    // further directional input until the sticks and d-pads return to neutral.
    //
    // That last part is the point. Without it, holding the stick while a
    // dialog opens would hand the new screen a direction that is already down
    // and start it navigating on arrival -- the player never asked the new
    // screen to move, they were still talking to the old one.
    void cancelHeldNavigation();

    // Lifts the suppression above once every physical source reads neutral.
    void updateDirectionalSuppression();

    void updateTimerState();

    // Recomputes m_GlyphFamily from the currently attached controllers and
    // emits glyphFamilyChanged() if it moved.
    void refreshGlyphFamily();

    // The controller the glyphs should follow: most recently used, falling back
    // to most recently attached. Null when none are open.
    SDL_GameController* glyphSourceController() const;

    // Records that a controller sent input, and refreshes the glyphs if that
    // changes which pad is in the user's hands.
    void noteGamepadUsed(SDL_JoystickID which);

    // Writes what was detected to the log unconditionally. Called once at
    // startup so a Deck session can read the answer instead of forcing it out
    // with the controller-disconnect trick.
    void logGlyphDetection();

private slots:
    void onPollingTimerFired();

private:
    StreamingPreferences* m_Prefs;
    QTimer* m_PollingTimer;
    QList<SDL_GameController*> m_Gamepads;
    bool m_Enabled;
    bool m_UiNavMode;
    bool m_NavModeSuspended;
    bool m_FirstPoll;
    bool m_HasFocus;
    // Which d-pad directions each controller currently holds, as a bit per
    // NavigationDirection. Kept rather than derived because SDL reports d-pad
    // buttons as events, not as pollable state.
    QHash<SDL_JoystickID, quint8> m_DpadHeldMasks;
    // The direction each controller's left stick is currently pushed to.
    // Absent means neutral; one direction at most, so a diagonal resolves the
    // same way it always has.
    QHash<SDL_JoystickID, NavigationDirection> m_AnalogDirections;
    NavigationRepeatState m_NavigationRepeat;
    // True between a context change and the moment every physical source reads
    // neutral again. See cancelHeldNavigation().
    bool m_DirectionalInputSuppressed;
    QString m_GlyphFamily;
    // What detection actually returned, before art availability collapses it
    // into m_GlyphFamily. "deck" and "fallback" both draw the Xbox set, so this
    // is the only place the difference survives.
    QString m_DetectedFamily;
    // Instance ID of the controller that most recently sent input, or -1.
    SDL_JoystickID m_ActiveGamepadId;
};
