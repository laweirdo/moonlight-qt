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

    Q_INVOKABLE void setUiNavMode(bool settingsMode);

    Q_INVOKABLE int getConnectedGamepads();

    QString glyphFamily() const { return m_GlyphFamily; }

signals:
    void glyphFamilyChanged();

private:
    void sendKey(QEvent::Type type, Qt::Key key, Qt::KeyboardModifiers modifiers = Qt::NoModifier);

    void updateTimerState();

    // Recomputes m_GlyphFamily from the currently attached controllers and
    // emits glyphFamilyChanged() if it moved.
    void refreshGlyphFamily();

private slots:
    void onPollingTimerFired();

private:
    StreamingPreferences* m_Prefs;
    QTimer* m_PollingTimer;
    QList<SDL_GameController*> m_Gamepads;
    bool m_Enabled;
    bool m_UiNavMode;
    bool m_FirstPoll;
    bool m_HasFocus;
    Uint32 m_LastAxisNavigationEventTime;
    QString m_GlyphFamily;
};
