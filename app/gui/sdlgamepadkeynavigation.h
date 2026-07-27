#pragma once

#include <QTimer>
#include <QEvent>

#include "SDL_compat.h"

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

    void sendKey(QEvent::Type type, Qt::Key key, Qt::KeyboardModifiers modifiers = Qt::NoModifier);

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
    Uint32 m_LastAxisNavigationEventTime;
    QString m_GlyphFamily;
    // What detection actually returned, before art availability collapses it
    // into m_GlyphFamily. "deck" and "fallback" both draw the Xbox set, so this
    // is the only place the difference survives.
    QString m_DetectedFamily;
    // Instance ID of the controller that most recently sent input, or -1.
    SDL_JoystickID m_ActiveGamepadId;
};
