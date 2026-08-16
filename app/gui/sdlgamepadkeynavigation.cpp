#include "sdlgamepadkeynavigation.h"

#include <QKeyEvent>
#include <QGuiApplication>
#include <QWindow>

#include "settings/mappingmanager.h"

// The left stick's navigation thresholds, with hysteresis.
//
// ENTER is the long-standing value and is unchanged: it takes a deliberate
// shove, well clear of the resting drift of a controller sitting on a desk.
// RELEASE is lower so that a stick held near the edge stays HELD instead of
// flickering in and out of the threshold -- each flicker used to be a fresh
// press, which restarted the initial delay and made a steady hold produce a
// stutter of single moves rather than a repeat.
constexpr qint16 AXIS_NAV_ENTER = 30000;
constexpr qint16 AXIS_NAV_RELEASE = 24000;

static constexpr quint8 directionBit(NavigationDirection direction)
{
    return static_cast<quint8>(1u << static_cast<int>(direction));
}

static const NavigationDirection ALL_NAVIGATION_DIRECTIONS[NAVIGATION_DIRECTION_COUNT] = {
    NavigationDirection::Up,
    NavigationDirection::Down,
    NavigationDirection::Left,
    NavigationDirection::Right
};

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
      m_NavigationRepeat(NAV_REPEAT_INITIAL_DELAY_MS, NAV_REPEAT_INTERVAL_MS),
      m_DirectionalInputSuppressed(false),
      // Nothing attached yet. Xbox lettering is the neutral default, and is what
      // "fallback" resolves to anyway.
      m_GlyphFamily(QLatin1String("xinput")),
      // Deliberately not "fallback": detection has not run, which is a different
      // state from having run and found nothing, and the startup log says so.
      m_DetectedFamily(QLatin1String("none")),
      m_ActiveGamepadId(-1)
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
    logGlyphDetection();

    // Start the polling timer if the window is focused
    updateTimerState();
}

// The controller whose glyphs should be drawn: the one most recently used, or
// the most recently attached if nothing has been used yet. Null with none open.
SDL_GameController* SdlGamepadKeyNavigation::glyphSourceController() const
{
    if (m_Gamepads.isEmpty()) {
        return nullptr;
    }

    if (m_ActiveGamepadId >= 0) {
        SDL_GameController* active = SDL_GameControllerFromInstanceID(m_ActiveGamepadId);
        if (active != nullptr && m_Gamepads.contains(active)) {
            return active;
        }
    }

    return m_Gamepads.last();
}

// Defect 4. Called whenever a controller actually sends input. The glyphs follow
// the pad in the user's hands, not the one plugged in most recently: with a
// DualSense connected and the Deck's own sticks still live, picking the Deck
// back up used to leave PlayStation shapes on screen until the DualSense was
// unplugged.
//
// Attaching a pad also marks it active, so hot-swap still switches the glyphs
// the instant something is plugged in rather than waiting for the first press.
// Plugging a controller in is itself a statement of intent to use it.
void SdlGamepadKeyNavigation::noteGamepadUsed(SDL_JoystickID which)
{
    if (m_ActiveGamepadId == which) {
        return;
    }

    m_ActiveGamepadId = which;
    refreshGlyphFamily();
}

void SdlGamepadKeyNavigation::refreshGlyphFamily()
{
    SDL_GameController* source = glyphSourceController();
    QString family = (source == nullptr) ? QLatin1String("fallback")
                                         : familyForController(source);

    // Log on any change in what was DETECTED, not just in what gets drawn.
    // Several families resolve to the same art -- "deck" and "fallback" both
    // draw the Xbox set -- so keying the log off the drawn family made it
    // silent in exactly the case worth knowing about: whether a Steam Deck's
    // built-in controls were recognised at all.
    if (family != m_DetectedFamily) {
        m_DetectedFamily = family;
        SDL_LogInfo(SDL_LOG_CATEGORY_APPLICATION,
                    "Controller glyphs: %s -> %s",
                    family.toUtf8().constData(),
                    resolveGlyphFamily(family).toUtf8().constData());
    }

    QString resolved = resolveGlyphFamily(family);
    if (resolved != m_GlyphFamily) {
        m_GlyphFamily = resolved;
        emit glyphFamilyChanged();
    }
}

// An unconditional report of what was found, written once at startup.
//
// The change-triggered line above cannot be relied on here: at startup the
// detected family goes from nothing to something, so it does fire -- but the
// only way anyone could previously observe glyph detection on a Steam Deck was
// to connect a DualSense and then unplug it, purely to force a change. That
// cost every Deck session real time. This states the answer outright, including
// the vendor ID, which is the thing that actually decides whether Valve
// hardware is recognised.
void SdlGamepadKeyNavigation::logGlyphDetection()
{
    SDL_LogInfo(SDL_LOG_CATEGORY_APPLICATION,
                "Controller glyphs: %d controller(s) attached",
                (int)m_Gamepads.count());

    for (auto gc : std::as_const(m_Gamepads)) {
        const char* name = SDL_GameControllerName(gc);
        SDL_LogInfo(SDL_LOG_CATEGORY_APPLICATION,
                    "Controller glyphs:   \"%s\" vendor=%04x product=%04x type=%d -> %s",
                    name != nullptr ? name : "(unnamed)",
                    SDL_GameControllerGetVendor(gc),
                    SDL_GameControllerGetProduct(gc),
                    (int)SDL_GameControllerGetType(gc),
                    familyForController(gc).toUtf8().constData());
    }

    SDL_LogInfo(SDL_LOG_CATEGORY_APPLICATION,
                "Controller glyphs: detected %s, drawing %s",
                m_DetectedFamily.toUtf8().constData(),
                m_GlyphFamily.toUtf8().constData());
}

void SdlGamepadKeyNavigation::disable()
{
    if (!m_Enabled) {
        return;
    }

    m_Enabled = false;
    updateTimerState();
    Q_ASSERT(!m_PollingTimer->isActive());

    // Let go of anything still held before the controllers go away. A stream
    // session starting while a direction is down would otherwise inherit a key
    // that nothing left alive can ever release.
    cancelHeldNavigation();
    m_DpadHeldMasks.clear();
    m_AnalogDirections.clear();

    while (!m_Gamepads.isEmpty()) {
        SDL_GameControllerClose(m_Gamepads[0]);
        m_Gamepads.removeAt(0);
    }

    SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
}

void SdlGamepadKeyNavigation::notifyWindowFocus(bool hasFocus)
{
    // Losing focus stops the poll, so nothing would ever release a direction
    // that was down at the time -- and nothing would notice it had been let go
    // while the window was in the background either.
    if (!hasFocus) {
        cancelHeldNavigation();
    }

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

            // A press is the clearest possible statement of which pad is in
            // the user's hands.
            noteGamepadUsed(event.cbutton.which);

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
            case SDL_CONTROLLER_BUTTON_DPAD_DOWN:
            case SDL_CONTROLLER_BUTTON_DPAD_LEFT:
            case SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
            {
                // The d-pad no longer sends keystrokes of its own. It records
                // which directions this pad is holding; the shared repeat clock
                // below decides what that means. This is the whole reason a
                // held d-pad now behaves like a held arrow key instead of
                // moving exactly once and stopping -- SDL generates no
                // auto-repeat for controller buttons, and nothing here ever
                // supplied one.
                NavigationDirection direction;
                switch (event.cbutton.button) {
                case SDL_CONTROLLER_BUTTON_DPAD_UP:
                    direction = NavigationDirection::Up;
                    break;
                case SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                    direction = NavigationDirection::Down;
                    break;
                case SDL_CONTROLLER_BUTTON_DPAD_LEFT:
                    direction = NavigationDirection::Left;
                    break;
                default:
                    direction = NavigationDirection::Right;
                    break;
                }

                quint8& mask = m_DpadHeldMasks[event.cbutton.which];
                if (type == QEvent::Type::KeyPress) {
                    mask = static_cast<quint8>(mask | directionBit(direction));
                }
                else {
                    mask = static_cast<quint8>(mask & ~directionBit(direction));
                }

                // Refreshed here rather than once at the end of the poll: a tap
                // short enough that its press and release arrive in the same
                // batch would otherwise cancel itself out and be lost.
                refreshLogicalDirection(direction);
                break;
            }
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
            case SDL_CONTROLLER_BUTTON_LEFTSHOULDER:
            case SDL_CONTROLLER_BUTTON_RIGHTSHOULDER:
                // The shoulder buttons were not mapped to anything at all,
                // which is why the game grid's Recent/Library tabs could not be
                // bound to them without coming here first. Same reasoning as
                // Key_Context1 for Select above: Key_Context2 and Key_Context3
                // are reserved soft keys with no text meaning, so they cannot
                // collide with typing in a focused field, and QML surfaces them
                // as Keys.onContext2Pressed and Keys.onContext3Pressed.
                //
                // Deliberately NOT switched by the swap-face-buttons
                // preference. That preference rewrites the four FACE buttons
                // (see the swap block above); shoulders are not face buttons
                // and a player who swaps A/B does not expect their bumpers to
                // trade places. ControllerGlyph makes the same distinction --
                // its _swappedFaceToken map covers b1..b4 only.
                sendKey(type,
                        event.cbutton.button == SDL_CONTROLLER_BUTTON_LEFTSHOULDER
                            ? Qt::Key_Context2 : Qt::Key_Context3);
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
                // Plugging one in counts as picking it up.
                noteGamepadUsed(SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(gc)));
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
            // Whatever this pad was holding, it is holding nothing now. Dropped
            // before the handle is closed so the refresh below can release any
            // direction that has just lost its last source -- an unplugged pad
            // must not leave an arrow key stuck down. A direction another
            // controller is still pushing survives, because the refresh asks
            // every remaining source rather than assuming this one spoke for
            // all of them.
            m_DpadHeldMasks.remove(event.cdevice.which);
            m_AnalogDirections.remove(event.cdevice.which);
            refreshAllDirections();

            SDL_GameController* gc = SDL_GameControllerFromInstanceID(event.cdevice.which);
            if (gc != nullptr) {
                int idx = m_Gamepads.indexOf(gc);
                if (idx >= 0) {
                    m_Gamepads.removeAt(idx);
                    SDL_GameControllerClose(gc);
                    // If the pad that just left was the one the glyphs were
                    // following, fall back to whatever is still attached.
                    if (m_ActiveGamepadId == event.cdevice.which) {
                        m_ActiveGamepadId = -1;
                    }
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

        // A stick pushed past the navigation threshold counts as using this
        // pad. The threshold matters: it is a deliberate shove, well clear of
        // the resting drift that would otherwise let an idle controller on the
        // desk keep stealing the glyphs back.
        if (leftX < -AXIS_NAV_ENTER || leftX > AXIS_NAV_ENTER ||
                leftY < -AXIS_NAV_ENTER || leftY > AXIS_NAV_ENTER) {
            noteGamepadUsed(SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(gc)));
        }

        // Resolve this stick to at most one direction, then let the shared
        // repeat clock time it. The stick no longer emits keystrokes itself:
        // it used to send a press and a release every 150 ms for as long as it
        // was pushed, which is neither a tap nor a hold and matched neither the
        // d-pad nor the keyboard.
        const SDL_JoystickID id = SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(gc));
        auto existing = m_AnalogDirections.constFind(id);
        const bool hadDirection = (existing != m_AnalogDirections.constEnd());

        // An established direction survives on the lower release threshold, so
        // a stick held near the edge stays held rather than chattering.
        bool keepExisting = false;
        if (hadDirection) {
            switch (existing.value()) {
            case NavigationDirection::Up:
                keepExisting = leftY <= -AXIS_NAV_RELEASE;
                break;
            case NavigationDirection::Down:
                keepExisting = leftY >= AXIS_NAV_RELEASE;
                break;
            case NavigationDirection::Left:
                keepExisting = leftX <= -AXIS_NAV_RELEASE;
                break;
            case NavigationDirection::Right:
                keepExisting = leftX >= AXIS_NAV_RELEASE;
                break;
            }
        }

        bool haveDirection = false;
        NavigationDirection direction = NavigationDirection::Up;
        if (keepExisting) {
            haveDirection = true;
            direction = existing.value();
        }
        // Acquiring a NEW direction takes the full entry threshold, and Y still
        // beats X so a diagonal resolves vertically -- unchanged from the
        // original ordering.
        else if (leftY < -AXIS_NAV_ENTER) {
            haveDirection = true;
            direction = NavigationDirection::Up;
        }
        else if (leftY > AXIS_NAV_ENTER) {
            haveDirection = true;
            direction = NavigationDirection::Down;
        }
        else if (leftX < -AXIS_NAV_ENTER) {
            haveDirection = true;
            direction = NavigationDirection::Left;
        }
        else if (leftX > AXIS_NAV_ENTER) {
            haveDirection = true;
            direction = NavigationDirection::Right;
        }

        const NavigationDirection previous = hadDirection ? existing.value() : direction;
        if (hadDirection != haveDirection || previous != direction) {
            if (haveDirection) {
                m_AnalogDirections.insert(id, direction);
            }
            else {
                m_AnalogDirections.remove(id);
            }

            // Both ends of the move: the direction being left may have lost its
            // last source, and the one being entered may have gained its first.
            if (hadDirection) {
                refreshLogicalDirection(previous);
            }
            if (haveDirection) {
                refreshLogicalDirection(direction);
            }
        }
    }

    // Everything physical has been read. Lift any suppression the sticks and
    // d-pads have now cleared, then pay out whatever repeats are due.
    updateDirectionalSuppression();

    const quint32 nowMs = SDL_GetTicks();
    for (NavigationDirection direction : ALL_NAVIGATION_DIRECTIONS) {
        if (m_NavigationRepeat.repeatDue(direction, nowMs)) {
            sendDirectionKey(direction, QEvent::Type::KeyPress, true);
        }
    }
}

bool SdlGamepadKeyNavigation::anySourceHolds(NavigationDirection direction) const
{
    const quint8 bit = directionBit(direction);

    for (auto it = m_DpadHeldMasks.constBegin(); it != m_DpadHeldMasks.constEnd(); ++it) {
        if (it.value() & bit) {
            return true;
        }
    }

    for (auto it = m_AnalogDirections.constBegin(); it != m_AnalogDirections.constEnd(); ++it) {
        if (it.value() == direction) {
            return true;
        }
    }

    return false;
}

void SdlGamepadKeyNavigation::refreshLogicalDirection(NavigationDirection direction)
{
    // A source moving is also evidence about whether everything has gone
    // neutral, which is what ends a suppression.
    updateDirectionalSuppression();

    const bool held = !m_DirectionalInputSuppressed && anySourceHolds(direction);

    switch (m_NavigationRepeat.setHeld(direction, held, SDL_GetTicks())) {
    case NavigationRepeatState::Edge::Press:
        sendDirectionKey(direction, QEvent::Type::KeyPress, false);
        break;
    case NavigationRepeatState::Edge::Release:
        sendDirectionKey(direction, QEvent::Type::KeyRelease, false);
        break;
    case NavigationRepeatState::Edge::None:
        break;
    }
}

void SdlGamepadKeyNavigation::refreshAllDirections()
{
    for (NavigationDirection direction : ALL_NAVIGATION_DIRECTIONS) {
        refreshLogicalDirection(direction);
    }
}

void SdlGamepadKeyNavigation::cancelHeldNavigation()
{
    for (NavigationDirection direction : ALL_NAVIGATION_DIRECTIONS) {
        if (m_NavigationRepeat.held(direction)) {
            // Released through the mapping still in force. Callers change the
            // navigation mode AFTER this returns for exactly that reason: a
            // release that translated differently from its own press would
            // leave the first key down forever.
            sendDirectionKey(direction, QEvent::Type::KeyRelease, false);
        }
    }

    m_NavigationRepeat.reset();

    // Refuse the next directional input until the hardware says the player has
    // let go and started again. updateDirectionalSuppression() lifts this
    // immediately when nothing is actually being held.
    m_DirectionalInputSuppressed = true;
    updateDirectionalSuppression();
}

void SdlGamepadKeyNavigation::updateDirectionalSuppression()
{
    if (!m_DirectionalInputSuppressed) {
        return;
    }

    for (auto it = m_DpadHeldMasks.constBegin(); it != m_DpadHeldMasks.constEnd(); ++it) {
        if (it.value() != 0) {
            return;
        }
    }

    if (!m_AnalogDirections.isEmpty()) {
        return;
    }

    m_DirectionalInputSuppressed = false;
}

void SdlGamepadKeyNavigation::sendKey(QEvent::Type type, Qt::Key key,
                                      Qt::KeyboardModifiers modifiers, bool autoRepeat)
{
    QGuiApplication* app = static_cast<QGuiApplication*>(QGuiApplication::instance());
    QWindow* focusWindow = app->focusWindow();
    if (focusWindow != nullptr) {
        // The auto-repeat flag is what tells anything downstream that this is a
        // key being HELD rather than pressed afresh. A synthesized repeat that
        // claimed to be a new press would be indistinguishable from the player
        // tapping very fast, which is a different intention.
        QKeyEvent keyPressEvent(type, key, modifiers, QString(), autoRepeat);
        app->sendEvent(focusWindow, &keyPressEvent);
    }
}

// Every navigation keystroke leaves through here, so a press, its repeats and
// its release cannot disagree about which key they are.
void SdlGamepadKeyNavigation::sendDirectionKey(NavigationDirection direction,
                                               QEvent::Type type, bool autoRepeat)
{
    switch (direction) {
    case NavigationDirection::Up:
        if (uiNavActive()) {
            // Back-tab
            sendKey(type, Qt::Key_Tab, Qt::ShiftModifier, autoRepeat);
        }
        else {
            sendKey(type, Qt::Key_Up, Qt::NoModifier, autoRepeat);
        }
        break;
    case NavigationDirection::Down:
        if (uiNavActive()) {
            sendKey(type, Qt::Key_Tab, Qt::NoModifier, autoRepeat);
        }
        else {
            sendKey(type, Qt::Key_Down, Qt::NoModifier, autoRepeat);
        }
        break;
    case NavigationDirection::Left:
        sendKey(type, Qt::Key_Left, Qt::NoModifier, autoRepeat);
        break;
    case NavigationDirection::Right:
        sendKey(type, Qt::Key_Right, Qt::NoModifier, autoRepeat);
        break;
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

// Both of these cancel BEFORE the mode moves, and only when it actually moves.
//
// Two reasons. The release has to translate the same way its own press did, and
// after this point it would not -- Down means Tab on the settings page and
// Key_Down everywhere else. And a screen change must not arrive holding a
// direction the player was aiming at the screen they just left: opening
// Settings with the stick still pushed used to be the surest way to watch a
// list scroll on its own.
void SdlGamepadKeyNavigation::setUiNavMode(bool uiNavMode)
{
    if (m_UiNavMode == uiNavMode) {
        return;
    }

    cancelHeldNavigation();
    m_UiNavMode = uiNavMode;
}

void SdlGamepadKeyNavigation::setNavModeSuspended(bool suspended)
{
    if (m_NavModeSuspended == suspended) {
        return;
    }

    cancelHeldNavigation();
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
