#include "sdlgamepadkeynavigation.h"

#include <QKeyEvent>
#include <QGuiApplication>
#include <QWindow>

#include "settings/mappingmanager.h"

#define AXIS_NAVIGATION_REPEAT_DELAY 150

// -----------------------------------------------------------------------------
// Controller glyph family detection
//
// The UI draws button glyphs matching whatever controller is physically in the
// user's hands. This resolves the attached hardware to an asset-name prefix; see
// app/res/glyphs/ and gui/ControllerGlyph.qml.
//
// IMPORTANT: this only ever changes which picture is drawn. SDL normalises every
// controller to an Xbox-style layout by physical position, so the bottom face
// button is SDL_CONTROLLER_BUTTON_A on every device regardless of what letter is
// printed on it. Bindings are therefore identical across families and must not
// be varied here -- a Nintendo pad shows a "B" glyph on the bottom button while
// still reporting, and acting as, the confirm button.
// -----------------------------------------------------------------------------

// Valve. The Steam Deck's built-in controls have no SDL_GameControllerType of
// their own (the enum in SDL 2.32 runs Xbox/PlayStation/Switch/Luna/Stadia/
// Shield/Virtual and stops), so Valve hardware is identified by vendor ID
// instead. SDL3 underneath does carry a Steam Deck HIDAPI driver and reports the
// name "Steam Deck", but exposes no distinct type for it through the SDL2 API.
#define USB_VENDOR_VALVE 0x28DE

// Families with no art bundled yet resolve to one that has. Dropping real
// deck_*.svg files into app/res/glyphs/ and deleting the "deck" line here is the
// whole of what a future glyph delivery needs.
static QString resolveGlyphFamily(const QString& family)
{
    if (family == QLatin1String("deck") || family == QLatin1String("fallback")) {
        return QLatin1String("xinput");
    }
    return family;
}

static QString familyForController(SDL_GameController* gc)
{
    if (SDL_GameControllerGetVendor(gc) == USB_VENDOR_VALVE) {
        return QLatin1String("deck");
    }

    switch (SDL_GameControllerGetType(gc)) {
    case SDL_CONTROLLER_TYPE_XBOX360:
    case SDL_CONTROLLER_TYPE_XBOXONE:
        return QLatin1String("xinput");

    case SDL_CONTROLLER_TYPE_PS3:
    case SDL_CONTROLLER_TYPE_PS4:
    case SDL_CONTROLLER_TYPE_PS5:
        return QLatin1String("ds");

    case SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_PRO:
    case SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_JOYCON_LEFT:
    case SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_JOYCON_RIGHT:
    case SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_JOYCON_PAIR:
        return QLatin1String("switch");

    default:
        // Includes UNKNOWN and the streaming-box types (Luna, Stadia, Shield)
        // plus VIRTUAL, which is what Steam Input presents. None of them have
        // their own art, and all of them use Xbox lettering in practice.
        return QLatin1String("fallback");
    }
}

SdlGamepadKeyNavigation::SdlGamepadKeyNavigation(StreamingPreferences* prefs)
    : m_Prefs(prefs),
      m_Enabled(false),
      m_UiNavMode(false),
      m_NavModeSuspended(false),
      m_FirstPoll(false),
      m_HasFocus(false),
      m_LastAxisNavigationEventTime(0),
      // Nothing attached yet. Xbox lettering is the neutral default, and is what
      // "fallback" resolves to anyway.
      m_GlyphFamily(QLatin1String("xinput"))
{
    m_PollingTimer = new QTimer(this);
    connect(m_PollingTimer, &QTimer::timeout, this, &SdlGamepadKeyNavigation::onPollingTimerFired);
}

SdlGamepadKeyNavigation::~SdlGamepadKeyNavigation()
{
    disable();
}

void SdlGamepadKeyNavigation::enable()
{
    if (m_Enabled) {
        return;
    }

    // We have to initialize and uninitialize this in enable()/disable()
    // because we need to get out of the way of the Session class. If it
    // doesn't get to reinitialize the GC subsystem, it won't get initial
    // arrival events. Additionally, there's a race condition between
    // our QML objects being destroyed and SDL being deinitialized that
    // this solves too.
    if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
                     "SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) failed: %s",
                     SDL_GetError());
        return;
    }

    MappingManager mappingManager;
    mappingManager.applyMappings();

    // Drop all pending gamepad add events. SDL will generate these for us
    // on first init of the GC subsystem. We can't depend on them due to
    // overlapping lifetimes of SdlGamepadKeyNavigation instances, so we
    // will attach ourselves.
    //
    // NB: We use SDL_JoystickUpdate() instead of SDL_PumpEvents() because
    // the latter can do a bit more work that we want (like handling video
    // events that we intentionally do not want to process yet).
    SDL_JoystickUpdate();
    SDL_FlushEvent(SDL_CONTROLLERDEVICEADDED);

    // Open all currently attached game controllers
    int numJoysticks = SDL_NumJoysticks();
    for (int i = 0; i < numJoysticks; i++) {
        if (SDL_IsGameController(i)) {
            SDL_GameController* gc = SDL_GameControllerOpen(i);
            if (gc != nullptr) {
                m_Gamepads.append(gc);
            }
        }
    }

    m_Enabled = true;

    // Pick up whatever was already attached before we opened. Without this the
    // glyphs would stay on the default family until the first hotplug event.
    refreshGlyphFamily();

    // Start the polling timer if the window is focused
    updateTimerState();
}

void SdlGamepadKeyNavigation::refreshGlyphFamily()
{
    QString family;

    if (m_Gamepads.isEmpty()) {
        family = QLatin1String("fallback");
    }
    else {
        // Most recently attached controller wins. If someone has a pad plugged in
        // and then picks up a different one, the one they just connected is the
        // one they are about to use.
        family = familyForController(m_Gamepads.last());
    }

    QString resolved = resolveGlyphFamily(family);
    if (resolved != m_GlyphFamily) {
        SDL_LogInfo(SDL_LOG_CATEGORY_APPLICATION,
                    "Controller glyphs: %s -> %s",
                    family.toUtf8().constData(),
                    resolved.toUtf8().constData());
        m_GlyphFamily = resolved;
        emit glyphFamilyChanged();
    }
}

void SdlGamepadKeyNavigation::disable()
{
    if (!m_Enabled) {
        return;
    }

    m_Enabled = false;
    updateTimerState();
    Q_ASSERT(!m_PollingTimer->isActive());

    while (!m_Gamepads.isEmpty()) {
        SDL_GameControllerClose(m_Gamepads[0]);
        m_Gamepads.removeAt(0);
    }

    SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
}

void SdlGamepadKeyNavigation::notifyWindowFocus(bool hasFocus)
{
    m_HasFocus = hasFocus;
    updateTimerState();
}

void SdlGamepadKeyNavigation::onPollingTimerFired()
{
    SDL_Event event;

    // Update joystick state without pumping other events (see enable() comment)
    SDL_JoystickUpdate();

    // Discard any pending button events on the first poll to avoid picking up
    // stale input data from the stream session (like the quit combo).
    if (m_FirstPoll) {
        SDL_FlushEvent(SDL_CONTROLLERBUTTONDOWN);
        SDL_FlushEvent(SDL_CONTROLLERBUTTONUP);
        m_FirstPoll = false;
    }

    // Peep events rather than polling to avoid calling SDL_PumpEvents()
    while (SDL_PeepEvents(&event, 1, SDL_GETEVENT, SDL_FIRSTEVENT, SDL_LASTEVENT) == 1) {
        switch (event.type) {
        case SDL_QUIT:
            // SDL may send us a quit event since we initialize
            // the video subsystem on startup. If we get one,
            // forward it on for Qt to take care of.
            QCoreApplication::instance()->quit();
            break;
        case SDL_CONTROLLERBUTTONDOWN:
        case SDL_CONTROLLERBUTTONUP:
        {
            QEvent::Type type =
                    event.type == SDL_CONTROLLERBUTTONDOWN ?
                        QEvent::Type::KeyPress : QEvent::Type::KeyRelease;

            // Swap face buttons if needed
            if (m_Prefs->swapFaceButtons) {
                switch (event.cbutton.button) {
                case SDL_CONTROLLER_BUTTON_A:
                    event.cbutton.button = SDL_CONTROLLER_BUTTON_B;
                    break;
                case SDL_CONTROLLER_BUTTON_B:
                    event.cbutton.button = SDL_CONTROLLER_BUTTON_A;
                    break;
                case SDL_CONTROLLER_BUTTON_X:
                    event.cbutton.button = SDL_CONTROLLER_BUTTON_Y;
                    break;
                case SDL_CONTROLLER_BUTTON_Y:
                    event.cbutton.button = SDL_CONTROLLER_BUTTON_X;
                    break;
                }
            }

            switch (event.cbutton.button) {
            case SDL_CONTROLLER_BUTTON_DPAD_UP:
                if (uiNavActive()) {
                    // Back-tab
                    sendKey(type, Qt::Key_Tab, Qt::ShiftModifier);
                }
                else {
                    sendKey(type, Qt::Key_Up);
                }
                break;
            case SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                if (uiNavActive()) {
                    sendKey(type, Qt::Key_Tab);
                }
                else {
                    sendKey(type, Qt::Key_Down);
                }
                break;
            case SDL_CONTROLLER_BUTTON_DPAD_LEFT:
                sendKey(type, Qt::Key_Left);
                break;
            case SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
                sendKey(type, Qt::Key_Right);
                break;
            case SDL_CONTROLLER_BUTTON_A:
                if (uiNavActive()) {
                    sendKey(type, Qt::Key_Space);
                }
                else {
                    sendKey(type, Qt::Key_Return);
                }
                break;
            case SDL_CONTROLLER_BUTTON_B:
                sendKey(type, Qt::Key_Escape);
                break;
            case SDL_CONTROLLER_BUTTON_X:
                sendKey(type, Qt::Key_Menu);
                break;
            case SDL_CONTROLLER_BUTTON_START:
                // HACK: We use this keycode to inform main.qml
                // to show the settings when Key_Menu is handled
                // by the control in focus.
                sendKey(type, Qt::Key_Hangup);
                break;
            case SDL_CONTROLLER_BUTTON_Y:
                // Y used to share Key_Hangup with Start, which made the two
                // buttons indistinguishable to QML. The host carousel needs them
                // apart -- Y wakes a host, Start opens client settings -- so Y now
                // has a keycode of its own.
                //
                // Key_Call is chosen for the same reason Key_Hangup was: it is a
                // reserved telephony key with no text meaning, so it cannot
                // collide with typing in a focused text field. QML surfaces it as
                // Keys.onCallPressed.
                //
                // main.qml still treats it as "show settings" at the StackView
                // level, so Y keeps its old behaviour on every screen that does
                // not consume it first.
                sendKey(type, Qt::Key_Call);
                break;
            case SDL_CONTROLLER_BUTTON_BACK:
                // Select/Back/View was not mapped to anything at all before.
                // Key_Context1 is a reserved soft key, surfaced in QML as
                // Keys.onContext1Pressed.
                sendKey(type, Qt::Key_Context1);
                break;
            default:
                break;
            }
            break;
        }
        case SDL_CONTROLLERDEVICEADDED:
        {
            SDL_GameController* gc = SDL_GameControllerOpen(event.cdevice.which);
            if (gc != nullptr) {
                // SDL_CONTROLLERDEVICEADDED can be reported multiple times for the same
                // gamepad in rare cases, because SDL doesn't fixup the device index in
                // the SDL_CONTROLLERDEVICEADDED event if an unopened gamepad disappears
                // before we've processed the add event.
                if (!m_Gamepads.contains(gc)) {
                    m_Gamepads.append(gc);
                }
                else {
                    // We already have this game controller open
                    SDL_GameControllerClose(gc);
                }

                // Swapping pads mid-session has to change the glyphs live.
                refreshGlyphFamily();
            }
            break;
        }
        case SDL_CONTROLLERDEVICEREMOVED:
        {
            // For removal events 'which' is the instance ID, not a device index.
            //
            // Nothing handled this case before. The consequence was mild while
            // m_Gamepads was only used for axis polling -- a closed controller
            // reads as zero -- but it leaked the handle, and it would have left
            // the glyphs showing a controller that had already been unplugged.
            SDL_GameController* gc = SDL_GameControllerFromInstanceID(event.cdevice.which);
            if (gc != nullptr) {
                int idx = m_Gamepads.indexOf(gc);
                if (idx >= 0) {
                    m_Gamepads.removeAt(idx);
                    SDL_GameControllerClose(gc);
                    refreshGlyphFamily();
                }
            }
            break;
        }
        }
    }

    // Handle analog sticks by polling
    for (auto gc : std::as_const(m_Gamepads)) {
        short leftX = SDL_GameControllerGetAxis(gc, SDL_CONTROLLER_AXIS_LEFTX);
        short leftY = SDL_GameControllerGetAxis(gc, SDL_CONTROLLER_AXIS_LEFTY);
        if (SDL_GetTicks() - m_LastAxisNavigationEventTime < AXIS_NAVIGATION_REPEAT_DELAY) {
            // Do nothing
        }
        else if (leftY < -30000) {
            if (uiNavActive()) {
                // Back-tab
                sendKey(QEvent::Type::KeyPress, Qt::Key_Tab, Qt::ShiftModifier);
                sendKey(QEvent::Type::KeyRelease, Qt::Key_Tab, Qt::ShiftModifier);
            }
            else {
                sendKey(QEvent::Type::KeyPress, Qt::Key_Up);
                sendKey(QEvent::Type::KeyRelease, Qt::Key_Up);
            }

            m_LastAxisNavigationEventTime = SDL_GetTicks();
        }
        else if (leftY > 30000) {
            if (uiNavActive()) {
                sendKey(QEvent::Type::KeyPress, Qt::Key_Tab);
                sendKey(QEvent::Type::KeyRelease, Qt::Key_Tab);
            }
            else {
                sendKey(QEvent::Type::KeyPress, Qt::Key_Down);
                sendKey(QEvent::Type::KeyRelease, Qt::Key_Down);
            }

            m_LastAxisNavigationEventTime = SDL_GetTicks();
        }
        else if (leftX < -30000) {
            sendKey(QEvent::Type::KeyPress, Qt::Key_Left);
            sendKey(QEvent::Type::KeyRelease, Qt::Key_Left);
            m_LastAxisNavigationEventTime = SDL_GetTicks();
        }
        else if (leftX > 30000) {
            sendKey(QEvent::Type::KeyPress, Qt::Key_Right);
            sendKey(QEvent::Type::KeyRelease, Qt::Key_Right);
            m_LastAxisNavigationEventTime = SDL_GetTicks();
        }
    }
}

void SdlGamepadKeyNavigation::sendKey(QEvent::Type type, Qt::Key key, Qt::KeyboardModifiers modifiers)
{
    QGuiApplication* app = static_cast<QGuiApplication*>(QGuiApplication::instance());
    QWindow* focusWindow = app->focusWindow();
    if (focusWindow != nullptr) {
        QKeyEvent keyPressEvent(type, key, modifiers);
        app->sendEvent(focusWindow, &keyPressEvent);
    }
}

void SdlGamepadKeyNavigation::updateTimerState()
{
    if (m_PollingTimer->isActive() && (!m_HasFocus || !m_Enabled)) {
        m_PollingTimer->stop();
    }
    else if (!m_PollingTimer->isActive() && m_HasFocus && m_Enabled) {
        // Flush events on the first poll
        m_FirstPoll = true;

        // Poll every 50 ms for a new joystick event
        m_PollingTimer->start(50);
    }
}

void SdlGamepadKeyNavigation::setUiNavMode(bool uiNavMode)
{
    m_UiNavMode = uiNavMode;
}

void SdlGamepadKeyNavigation::setNavModeSuspended(bool suspended)
{
    m_NavModeSuspended = suspended;
}

int SdlGamepadKeyNavigation::getConnectedGamepads()
{
    Q_ASSERT(m_Enabled);

    int count = 0;
    int numJoysticks = SDL_NumJoysticks();
    for (int i = 0; i < numJoysticks; i++) {
        if (SDL_IsGameController(i)) {
            count++;
        }
    }

    return count;
}
