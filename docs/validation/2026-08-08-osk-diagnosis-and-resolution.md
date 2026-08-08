# Validation report — SteamOS on-screen keyboard, 8 August 2026

| Item | Value |
|---|---|
| Date | 8 August 2026 |
| Branch | `fix-deck-osk`, cut from `bulan` at `54f46db7` |
| Commit under test | `54f46db7` plus one uncommitted change to `app/gui/HostPanel.qml` at time of writing |
| Hardware | Steam Deck, this session's machine; panel type not recorded |
| Environment | Real Steam Game Mode, via a non-Steam-game Flatpak shortcut (`/home/deck/Documents/bulan-gamemode.sh`) |
| Who | Claude Code (diagnosis, build, log analysis), client (all physical Game Mode observations) |

**Evidence basis.** This session's own build, install, and log capture — not a
transcribed client report. Every Game Mode observation below (OSK appearance,
typing, focus behaviour) was performed and reported live by the client, since
this session has SSH/terminal access only, no physical controller, no direct
view of the Game Mode display.

## Repository state at session start

`/home/deck/Documents/Bulan` was found empty (no `.git`, no `AGENTS.md`/
`HANDOFF.md`/`BUGS.md`) — the prior checkout was gone, along with
`/home/deck/Documents/moonlight-qt` and `/home/deck/Documents/
moonlight-flatpak-recipe`, the paths `BUILDING-DECK.md` expects. Re-cloned
from `https://github.com/laweirdo/moonlight-qt.git`, branch `bulan`, with
submodules, per the client's direction. The Flatpak build recipe was
recreated from Flathub's current `com.moonlight_stream.Moonlight.json`,
reapplying `BUILDING-DECK.md`'s four documented changes (app ID, two/three
renames, local source path, patch removal) — five patches were stale rather
than three now (Flathub's recipe has grown since `BUILDING-DECK.md` was
written) and all five were confirmed already-fixed in source before removal.
One additional, pre-existing, unrelated inconsistency was found and fixed:
the recipe's `rename-icon` value (`moonlight`) no longer matched the app's
actual installed icon filename (`com.moonlight_stream.Moonlight.svg`, per
`app/app.pro:545`) — corrected to unblock the build. `BUILDING-DECK.md` has
been updated to record all of this so a future session does not repeat the
diagnosis.

## Diagnosis

**Root cause 1 (fixed in source).** `HostPanel.qml`'s text field — the one
shared component every manual-address entry point uses — gave its
`TextInput` focus only programmatically (`forceActiveFocus()`), and nowhere
called `Qt.inputMethod.show()`. Qt Quick's own automatic software-input-panel
invocation is tied to real mouse/touch press handling; Bulan's gamepad
navigation (`sdlgamepadkeynavigation.cpp`) delivers only synthetic key
events, so the input panel was never requested at all.

**Root cause 2 (platform limitation, not a Bulan defect).** Confirmed by
process inspection (`libqxcb.so` loaded, no Wayland library, `DISPLAY` set,
no `WAYLAND_DISPLAY`) that Bulan runs as an XWayland client in real Game
Mode. Gamescope's automatic OSK path is documented (Valve, gamescope issue
#668) to require a native Wayland client via `text-input-v3`; this gamescope
session was not started with `--expose-wayland` (confirmed from the running
`gamescope` command line), and that flag is explicitly beta/opt-in with
known app-compatibility breakage — not a safe or in-scope change for a
streaming app.

Two further avenues were tested and ruled out with direct evidence, not
speculation:

- Valve's own Qt input-context plugin (`/usr/lib/qt/plugins/
  platforminputcontexts/steam-qt-keyboard-plugin.so`, module key `"steam"`)
  is Qt5-only (`QT_DEBUG_PLUGINS=1` log: `"Plugin uses incompatible Qt
  library (5.15.0)"`) — categorically unusable by Bulan's Qt6 build.
- The standard Qt6 IBus input-context path (`QT_IM_MODULE=ibus`) **does**
  work end to end: it loads via the sandboxed `org.freedesktop.portal.IBus`
  portal (no extra filesystem permissions needed), connects to the host's
  `ibus-gamescope` engine, and exchanges real IBus protocol messages
  (`QIBusText::fromDBusArgument`, `preedit text: ""`) at the moment the field
  is focused — confirmed via `QT_LOGGING_RULES=qt.qpa.ibus*=true` in the
  captured Game Mode log. Genuine touch-press events (`XI2 mouse press`) were
  also confirmed reaching Qt at the same moment. Despite the protocol
  handshake completing correctly, gamescope never rendered the keyboard
  overlay — this matches a documented Valve limitation
  ([steam-for-linux#9117](https://github.com/ValveSoftware/steam-for-linux/issues/9117)):
  non-Steam-game windows receive different, less reliable on-screen-keyboard
  treatment in Game Mode than real Steam library titles.

## Client decision, 8 August 2026

Given the above, the client decided: **Steam+X remains the supported way to
bring up the keyboard for Bulan on Steam Deck.** Automatic invocation is a
SteamOS/gamescope platform characteristic for non-Steam-game windows, not a
Bulan defect to keep chasing. The `Qt.inputMethod.show()`/`hide()` fix was
kept — it is the technically correct way to request the input panel per
Qt's own API, is confirmed to reach gamescope's `ibus-gamescope` engine at
the protocol level, and is harmless regardless of whether the overlay
renders automatically.

## Validation performed (client-observed, this session)

| Check | Result |
|---|---|
| `Steam + X` opens the OSK with a Bulan field focused | Pass |
| OSK appears automatically (no Steam+X), pre-fix | Fail — confirmed the defect |
| OSK appears automatically, post-fix (`Qt.inputMethod.show()`) | Still does not appear — root cause 2 (platform) applies regardless of the source fix |
| Full manual-address entry via Steam+X: type and submit, controller-only | **Pass** |
| Second entry point, `HostCarousel.qml`'s "Add a PC" (same `HostPanel` component) via Steam+X | Pass |
| Controller focus/navigation after closing the panel (submit and cancel paths) | Pass — no dead focus, no stuck input |

## Skipped, and why

- LCD-specific appearance — hardware/panel type not recorded this session,
  unrelated to this defect.
- Blur cost, battery draw, waiting-state timings — out of scope for this
  task.

## Conclusion

The Phase F blocker is resolved: manual address entry can be completed
controller-only in Game Mode, via Steam+X. The `HostPanel.qml` fix is a
genuine correctness improvement and is retained. No further source change is
planned for automatic OSK invocation; it depends on SteamOS/gamescope
behaviour for non-Steam-game windows, outside this repository's control.
