# Moonlight UI Audit

A plain-English inventory of Moonlight's interface, written for design work. Everything
here was read directly out of the 19 interface files in `app/gui/` plus the gamepad
input handler, at commit `17d5b1a8` (version 6.1.0).

File references like `PcView.qml:170` mean "the file PcView.qml, line 170" — you can hand
those to a developer to point them at the exact spot.

> **Historical baseline — read this first.**
>
> This audits upstream Moonlight's interface as it stood *before* the Bulan work
> began. It is preserved deliberately as the "before" picture: it is what the
> redesign is measured against, and several of its findings are the reasons
> particular decisions were later made.
>
> Superseded in the Bulan fork:
>
> - **Screen 1, "Computers"** — the card grid described below is no longer the host
>   screen. `HostCarousel.qml` replaced it; see
>   `docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md`. `PcView.qml`
>   is still in the tree but is no longer the initial view.
> - **Section 6, "Contextual button hints"** — the finding was that exactly one
>   on-screen hint existed in the entire app. `HintBar.qml` now exists, and the host
>   screen carries a full hint set.
> - **Section 3's D-pad map** — Y and START no longer share `Key_Hangup`, and SELECT
>   is now mapped at all. See the input table in
>   `docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md`.
>
> The remaining material is the upstream baseline and a catalogue of historical
> redesign findings. It is not an active Bulan defect list or a current-state
> tracker. Use `BUGS.md` for accepted open defects and `HANDOFF.md` for the live
> repository state.

**A note on vocabulary.** Moonlight's interface is built as a *stack of screens*, like a
deck of cards. Opening something pushes a new card on top; going back throws the top card
away. Only the top card is ever visible. This matters for design because there are no
tabs, no sidebar, and no persistent navigation — just a one-way stack and a Back arrow.

---

## Table of contents

1. [Every screen, in the order you meet it](#1-every-screen-in-the-order-you-meet-it)
2. [Every interactive element and what it does](#2-every-interactive-element-and-what-it-does)
3. [How focus moves with a D-pad](#3-how-focus-moves-with-a-d-pad)
4. [Reusable components](#4-reusable-components)
5. [Every user-visible text string](#5-every-user-visible-text-string)
6. [Contextual button hints](#6-contextual-button-hints)
7. [Layout at 1280×800](#7-layout-at-1280800)
8. [Observations for redesign](#8-observations-for-redesign)

---

## 1. Every screen, in the order you meet it

### The permanent frame

One thing is always present around the screens: a **60-pixel-tall toolbar** across the top
(`main.qml:236`). It holds the screen's name in the centre and a row of icon buttons on the
right. The buttons change depending on which screen you're on. Two screens hide the toolbar
entirely — noted below.

### Startup interruptions (before you see anything else)

On a normal launch, Moonlight runs three background checks and may throw a modal dialog at
you before you've done anything (`main.qml:54–63`). These are the very first thing some
users see:

| Order | Dialog | When it appears | Buttons |
|---|---|---|---|
| 1 | Wrong-architecture warning | Running a build that doesn't match the PC's processor | OK, Cancel |
| 2 | No hardware video decoder | No working hardware decoder found | OK, Help |
| 3 | XWayland warning | Linux only — running under XWayland | OK, Help |
| 4 | Unmapped gamepads | A connected gamepad has no button mapping | OK, Help |

Checks 2–4 are asynchronous, so they can appear a second or two *after* the first screen has
already drawn. All four can be switched off via "Show configuration warnings" in Settings.

### Screen 1 — Computers

**The home screen.** Every normal launch starts here (`main.cpp:996`).

A grid of large cards, one per host PC. Each card is a monitor icon with the PC's name
underneath in very large text (36pt). A small badge overlays the icon: a warning triangle
if the PC is offline, a padlock if it's online but not yet paired, or a spinner while the
status is still unknown.

If no PCs have been found yet, the grid is replaced by a centred spinner and the message
"Searching for compatible hosts on your local network…" — or, if automatic discovery is
turned off, "Automatic PC discovery is disabled. Add your PC manually."

Toolbar here: **Add PC**, **Help**, **Settings** (plus an **Update** button if a new version
was found).

### Screen 2 — App grid

Reached by clicking a paired, online PC. The toolbar title becomes **the PC's own name**
(`AppView.qml`, set at creation) — so this screen has no fixed title.

A grid of game box-art tiles. Games that are currently running get two large round buttons
laid over the art: a **play** button to resume and a **stop** button to quit. Games you've
hidden appear at 40% opacity — but only if you arrived here via "View All Apps".

If a game has no real box art, Moonlight detects the placeholder image and draws the game's
name over the tile instead (22pt, centred).

Empty state: "This computer doesn't seem to have any applications or some applications are
hidden."

Toolbar here: **Back**, **Help**, **Settings**.

### Screen 3 — Launching / streaming

**The toolbar is hidden on this screen** (`StreamSegue.qml:112`).

A centred spinner with a status line that updates as connection stages complete —
"Starting *game name*…", then "Starting *stage name*…". Near the bottom sits the one true
button hint in the whole app (see [section 6](#6-contextual-button-hints)).

When the stream actually begins, all of this is hidden and the whole Moonlight window
disappears — the stream takes over. When streaming ends the window returns.

### Screen 4 — Quitting a game

**Toolbar hidden.** A centred spinner reading "Quitting *game name*…". Appears when you
stop a running game, and also in the middle of switching games (quit the old one, then
straight into launching the new one).

### Screen 5 — Settings

Reached from the gear icon on any screen, or the Menu/Start button on a gamepad. A single
long, scrolling, **two-column** page — not tabs or sections you navigate between.

Seven titled panels, each with a sky-blue heading. Left column: **Basic Settings**, **Audio
Settings**, **Host Settings**, **UI Settings**. Right column: **Input Settings**, **Gamepad
Settings**, **Advanced Settings**.

Toolbar here gains two extras: the **version number** as text, and a **Discord** button.

### Screen 6 — Gamepad Mapping

**This screen exists but cannot be reached.** It's an empty placeholder, and the toolbar
button that would open it is permanently hidden with a "TODO: Implement gamepad mapping then
unhide this button" note (`main.qml:407–408`). Worth knowing it's a stub, not a feature.

### Command-line-only screens

Three screens replace the home screen entirely when Moonlight is launched from a terminal
with arguments (`main.cpp:1000–1021`). A normal user clicking the app icon will never see
them, but they exist and they're user-visible:

| Screen | Purpose | Messages shown |
|---|---|---|
| Pair | Pair with a PC | "Establishing connection to PC…", then "Pairing… Please enter '*PIN*' on *PC*.", then a "Pairing completed successfully" dialog |
| Start stream | Launch straight into a game | "Establishing connection to PC…", then "Loading app list…" |
| Quit stream | Quit a running game | "Establishing connection to PC…", then "Quitting app…" |

All three hide the toolbar, and all three quit the whole app when dismissed rather than
returning to a normal screen.

---

## 2. Every interactive element and what it does

### The toolbar (present on all screens except the two segue screens)

Buttons are laid out left to right in this fixed order. Which ones you actually see depends
on the screen.

| Button | Icon | Appears on | What it does |
|---|---|---|---|
| Back | Left arrow | Any screen deeper than the first | Goes back one screen |
| *(screen title)* | — | All | Not interactive |
| *(version number)* | — | Settings only | Not interactive |
| Discord | Discord logo | Settings only | Opens the Discord invite in your browser |
| Add PC | Monitor with a plus | Computers only | Opens "Enter the IP address of your host PC:" |
| Update | Update arrow | Any screen, only once an update is found | Opens the releases page in your browser |
| Help | Question mark | All (if a browser exists) | Opens the Setup Guide wiki page |
| Gamepad Mapper | Game controller | **Never — permanently hidden** | Would open the stub mapping screen |
| Settings | Gear | All | Opens Settings |

Keyboard shortcuts: **Add PC** is the system "New" shortcut (⌘N on macOS), **Help** is the
system Help shortcut, **Settings** is the system Preferences shortcut (⌘,). Each button's
tooltip appends its own shortcut automatically.

### Screen 1 — Computers

| Element | Interaction | Result |
|---|---|---|
| PC card (online, paired) | Click / A / Enter | Opens the App grid for that PC |
| PC card (online, unpaired) | Click / A / Enter | Generates a PIN and opens the pairing dialog |
| PC card (online, unsupported host version) | Click / A / Enter | Error: host's GeForce Experience is too new for this build |
| PC card (offline) | Click / A / Enter | Opens the card's context menu instead of doing nothing |
| PC card | Right-click / long-press / X button | Opens the context menu at the pointer |
| PC card | Delete key | Jumps straight to the "remove this PC?" confirmation |

**PC context menu** — items appear conditionally:

| Item | Shown when | Result |
|---|---|---|
| "PC Status: Online/Offline" | Always | Nothing — it's a disabled header |
| View All Apps | PC is online and paired | Opens the App grid *including* hidden games |
| Wake PC | PC is offline and supports wake-on-LAN | Sends a wake packet |
| Test Network | Always | Runs a port-blocking test, shows a progress dialog then a result |
| Rename PC | Always | Opens a text field pre-filled with the current name as placeholder |
| Delete PC | Always | Opens a confirmation |
| View Details | Always | Opens a read-only dialog of technical details |

### Screen 2 — App grid

| Element | Interaction | Result |
|---|---|---|
| Game tile (not running) | Click / A / Enter | Launches the game |
| Game tile (running) | Click | **Ignored** — you must use the overlay buttons |
| Game tile (running) | A / Enter | Opens the context menu |
| Game tile | Right-click / long-press / X | Opens the context menu |
| Round play button | Click only | Resumes the running game |
| Round stop button | Click only | Opens "quit this game?" confirmation |

Note the two round buttons are **mouse-only** — they're explicitly set to never take
keyboard focus (`AppView.qml:127`, `153`), so a gamepad user reaches the same actions
through the context menu instead.

**Game context menu:**

| Item | Shown when | Result |
|---|---|---|
| Launch Game / Resume Game | Always (label depends on running state) | Starts or resumes |
| Quit Game | Game is running | Confirmation, then quits it |
| Direct Launch (a toggle) | Always; disabled if the game is hidden | Makes this game launch instantly when you pick the host, skipping this grid |
| Hide Game (a toggle) | Always; disabled if running or set to direct-launch | Hides it from the normal grid |

**If you try to launch a game while a different game is already running**, you get "Are you
sure you want to quit *X*? Any unsaved progress will be lost." Saying yes quits the old game
and then launches the new one in one flow.

### Screen 5 — Settings

37 controls in total. Every one saves immediately — **there is no Save or Cancel, and no
confirmation.** Preferences are written when you leave the screen (`SettingsView.qml:87`)
and also if you just quit the app outright (`:93`).

**Basic Settings**

| Control | Type | Notes |
|---|---|---|
| Resolution | Dropdown | 720p / 1080p / 1440p / 4K, plus auto-detected "Native" and "Native (Excluding Notch)" entries per attached display, plus "Custom". Entries above the decoder's maximum are silently removed. |
| Frame rate | Dropdown | 30 / 60 FPS, plus each display's actual refresh rate, plus "Custom" |
| Video bitrate | Slider | 500 Kbps to 150 Mbps in 500-step increments (up to 500 Mbps if the limit is unlocked). The panel heading itself updates live to "Video bitrate: *n* Mbps". |
| Use Default (*n* Mbps) | Button | **Only appears when your bitrate differs from the recommended one.** Resets it. |
| Display mode | Dropdown | Fullscreen / Borderless windowed / Windowed. The OS-recommended one is moved to the top and labelled "(Recommended)". |
| V-Sync | Checkbox | — |
| Frame pacing | Checkbox | Greyed out unless V-Sync is on |
| Enable HDR | Checkbox | Greyed out entirely if the machine can't do HDR |

Picking "Custom" on either dropdown opens a small dialog. The resolution one accepts
256–8192 in each direction; the frame-rate one accepts 10–9999. The OK button stays greyed
out until the input is valid. Cancelling reverts the dropdown to its previous entry.

Changing resolution, frame rate, or the YUV 4:4:4 option **silently rewrites your bitrate**
to the new recommended value — unless you've previously moved the slider by hand, which
permanently marks the bitrate as manual.

**Audio Settings**

| Control | Type |
|---|---|
| Audio configuration | Dropdown: Stereo / 5.1 surround sound / 7.1 surround sound |
| Mute host PC speakers while streaming | Checkbox |
| Mute audio stream when Moonlight is not the active window | Checkbox (desktop only) |

**Host Settings**

| Control | Type |
|---|---|
| Optimize game settings for streaming | Checkbox |
| Quit app on host PC after ending stream | Checkbox |

**UI Settings**

| Control | Type | Notes |
|---|---|---|
| Language | Dropdown | "Automatic" plus 24 languages, each written in its own language |
| GUI display mode | Dropdown | Windowed / Maximized / Fullscreen — how Moonlight's own window opens |
| Show connection quality warnings | Checkbox | — |
| Show configuration warnings | Checkbox | Turns off the four startup dialogs |
| Discord Rich Presence integration | Checkbox | Only in builds with Discord support |
| Keep the display awake while streaming | Checkbox | — |

Changing language re-translates the interface live. If live re-translation fails, a
temporary toast says "You must restart Moonlight for this change to take effect".

**Input Settings**

| Control | Type | Notes |
|---|---|---|
| Optimize mouse for remote desktop instead of games | Checkbox | — |
| Capture system keyboard shortcuts | Checkbox | Paired with a dropdown |
| *(capture scope)* | Dropdown | "in fullscreen" / "always" — greyed out unless the checkbox above is ticked |
| Use touchscreen as a virtual trackpad | Checkbox | — |
| Swap left and right mouse buttons | Checkbox | — |
| Reverse mouse scrolling direction | Checkbox | — |

**Gamepad Settings**

| Control | Type |
|---|---|
| Swap A/B and X/Y gamepad buttons | Checkbox |
| Force gamepad #1 always connected | Checkbox |
| Enable mouse control with gamepads by holding the 'Start' button | Checkbox |
| Process gamepad input when Moonlight is in the background | Checkbox (desktop only) |

**Advanced Settings**

| Control | Type | Notes |
|---|---|---|
| Video decoder | Dropdown | Automatic (Recommended) / Force software / Force hardware |
| Video codec | Dropdown | Automatic (Recommended) / H.264 / HEVC (H.265) / AV1 |
| Renderer | Dropdown | **macOS only.** Automatic / Vulkan / Metal / AVSampleBufferDisplayLayer |
| Enable YUV 4:4:4 | Checkbox | — |
| Unlock bitrate limit (Experimental) | Checkbox | Raises the slider ceiling to 500 Mbps |
| Automatically find PCs on the local network (Recommended) | Checkbox | Restarts network discovery immediately |
| Automatically detect blocked connections (Recommended) | Checkbox | — |
| Show performance stats while streaming | Checkbox | — |

### Dialogs

Every dialog is modal — the rest of the window is frozen. Dialogs come in two shapes: a
**message** (icon on the left, wrapped text on the right, buttons underneath) and an
**input** (a bold prompt above a text field).

The icon is chosen automatically: a question mark if the dialog has a Yes button, otherwise
an error symbol (`NavigableMessageDialog.qml:34`). Some dialogs override it with a warning
triangle, a green check, or a help symbol.

Text fields accept Enter/Return as "confirm" everywhere they appear.

---

## 3. How focus moves with a D-pad

This is the most important section for redesign, because Moonlight has **two completely
different navigation modes** and the mode changes underneath you as you move between screens.

### What the D-pad actually sends

Moonlight doesn't handle a gamepad directly; it translates gamepad presses into keyboard
presses and then behaves like a keyboard app (`sdlgamepadkeynavigation.cpp:151–198`). The
translation depends on the mode:

| You press | In **grid mode** (Computers, App grid) | In **list mode** (Settings) |
|---|---|---|
| D-pad Up | Up arrow | **Shift+Tab** (previous control) |
| D-pad Down | Down arrow | **Tab** (next control) |
| D-pad Left | Left arrow | Left arrow |
| D-pad Right | Right arrow | Right arrow |
| A | Enter | **Space** |
| B | Escape | Escape |
| X | Menu (opens context menus) | Menu |
| Y or Start | Opens Settings | Opens Settings |

The left analogue stick mirrors the D-pad exactly, with a 150 ms repeat delay.

Two consequences worth designing around:

- **Up and Down mean different things on different screens.** In the grids they move
  spatially. In Settings they walk a single flat list, one control at a time, regardless of
  what's visually above or below.
- **Left and Right never change mode.** They stay as arrow keys everywhere, which is why in
  Settings they adjust the focused control's *value* rather than moving focus.

If "Swap A/B and X/Y gamepad buttons" is on, the physical buttons are swapped before any of
this happens, so A and B trade places.

### Computers and App grid — exact order

Both grids behave identically.

1. **Where focus starts.** If a gamepad is connected when you arrive, the first card is
   highlighted. If not, **nothing is highlighted at all** until you press something
   (`PcView.qml:27`, `:38`). Mouse users see no selection; gamepad users do.
2. **Left / Right** move one card at a time through the grid in reading order — so Right at
   the end of a row wraps to the start of the next row.
3. **Down** moves one full row down.
4. **Up** moves one full row up — and if you're already in the top row, **focus jumps out of
   the grid and into the toolbar** (`NavigableItemDelegate.qml:19–25`). It lands on the
   rightmost toolbar button, the gear.
5. **Inside the toolbar**, Left and Right walk along the buttons, and **Down drops you back
   into the grid** (`NavigableToolButton.qml:26–32`). Pressing Right on the last button (the
   gear) also falls into the grid.
6. **A** activates the highlighted card. **X** opens its context menu. **B** goes back — and
   on the Computers screen, where there's nothing to go back to, it opens "Are you sure you
   want to quit?"

So the whole model is: a grid you move around spatially, with the toolbar sitting "above"
the top row as one more row you can reach.

**Inside a context menu**, focus goes to the first item that's both visible and enabled
(`NavigableMenu.qml:10–18`). Up and Down move between items, A triggers, B closes.

### Settings — exact order

Settings switches into list mode the moment it opens, and switches back out when you leave
(`SettingsView.qml:75`, `:84`).

**Where focus starts:** on the Resolution dropdown, but *only* if a gamepad is connected
(`:79`). Otherwise nothing is focused.

**D-pad Down walks these 37 controls in exactly this order.** The numbering is the real
traversal order:

*Left column — Basic Settings*
1. Resolution dropdown
2. Frame rate dropdown
3. Video bitrate slider
4. "Use Default (*n* Mbps)" button — *skipped when hidden*
5. Display mode dropdown
6. V-Sync
7. Frame pacing
8. Enable HDR

*Left column — Audio Settings*
9. Audio configuration dropdown
10. Mute host PC speakers while streaming
11. Mute audio stream when Moonlight is not the active window

*Left column — Host Settings*
12. Optimize game settings for streaming
13. Quit app on host PC after ending stream

*Left column — UI Settings*
14. Language dropdown
15. GUI display mode dropdown
16. Show connection quality warnings
17. Show configuration warnings
18. Discord Rich Presence integration — *skipped in builds without Discord*
19. Keep the display awake while streaming

*Right column — Input Settings*
20. Optimize mouse for remote desktop instead of games
21. Capture system keyboard shortcuts
22. Capture scope dropdown ("in fullscreen" / "always")
23. Use touchscreen as a virtual trackpad
24. Swap left and right mouse buttons
25. Reverse mouse scrolling direction

*Right column — Gamepad Settings*
26. Swap A/B and X/Y gamepad buttons
27. Force gamepad #1 always connected
28. Enable mouse control with gamepads by holding the 'Start' button
29. Process gamepad input when Moonlight is in the background

*Right column — Advanced Settings*
30. Video decoder dropdown
31. Video codec dropdown
32. Renderer dropdown — *macOS only*
33. Enable YUV 4:4:4
34. Unlock bitrate limit (Experimental)
35. Automatically find PCs on the local network (Recommended)
36. Automatically detect blocked connections (Recommended)
37. Show performance stats while streaming

After 37, Tab continues into the toolbar buttons and then wraps back to 1.

**The critical thing here:** focus runs all the way down the left column and then jumps to
the top of the right column. There is **no way to move sideways between the two columns** —
Left and Right are consumed by whatever control is focused. So the two-column layout is
purely visual; navigationally it is one 37-item list. Getting from "Resolution" to the first
Input setting takes 19 presses.

**What Left and Right do to the focused control:**

| Focused control | Left / Right |
|---|---|
| Any dropdown | Steps the selection down / up **without opening the list** (`AutoResizingComboBox.qml:54–60`) |
| Bitrate slider | Nudges the bitrate |
| Any checkbox | Nothing |

**A (Space)** ticks a checkbox, presses a button, or opens a dropdown's list.

**When a dropdown's list is open**, Moonlight temporarily flips *back* to grid mode
(`AutoResizingComboBox.qml:39–52`), so Up and Down become real arrows for moving through the
list, and closing it flips back. This is handled well and is invisible to the user.

**Auto-scrolling.** Because the page is taller than the window, focus moves would otherwise
go off-screen. Moonlight watches whatever has focus and animates the page over 100 ms to keep
it visible with a 50-pixel margin (`SettingsView.qml:45–70`). Toolbar buttons are correctly
excluded so the page doesn't jump when you reach the toolbar.

### Dialogs

When a dialog opens, focus goes to **the last button in the row** (`NavigableMessageDialog.qml:19`).
Left and Right move between buttons, A activates, B dismisses. When the dialog closes, focus
is forced back to the screen underneath — without this, gamepad navigation would break
entirely (`NavigableDialog.qml:8–13`).

Note that "the last button" is positional, not semantic. On a Yes/No dialog that means focus
starts on whichever of the two the platform puts last — it is not deliberately parked on the
safe option.

---

## 4. Reusable components

### Shared across more than one screen

| Component | Where it's used | What it is |
|---|---|---|
| **Toolbar button** (`NavigableToolButton`) | 7 instances in the toolbar → every screen with a toolbar | An icon button that knows how to pass focus left, right, and down |
| **Centred grid** (`CenteredGridView`) | Computers, App grid | The grid container. Works out how many cards fit per row and pads the sides to centre them |
| **Grid card** (`NavigableItemDelegate`) | Computers, App grid | One card. Owns the arrow-key movement and the "escape upward into the toolbar" behaviour |
| **Context menu** (`NavigableMenu`) | Computers, App grid | A right-click menu that hands focus to its first usable item |
| **Context menu item** (`NavigableMenuItem`) | Computers, App grid | One menu row. Collapses to zero height when hidden so it can't be focused |
| **Base dialog** (`NavigableDialog`) | Add PC (Computers), Rename PC (Computers), Custom resolution (Settings), Custom frame rate (Settings) | Modal, centred, restores focus on close |
| **Message dialog** (`NavigableMessageDialog`) | Computers ×4, App grid ×1, startup ×2, Pair screen ×1, CLI start ×1 | Icon + wrapped text + buttons. Auto-picks its icon |
| **Error dialog** (`ErrorMessageDialog`) | Startup ×4, Computers, Quitting, all three CLI screens | A message dialog fixed to OK + Help |

### Reused heavily, but only on one screen

| Component | Instances | Note |
|---|---|---|
| **Auto-sizing dropdown** (`AutoResizingComboBox`) | 10, all in Settings | Measures every option and sizes itself to the widest, capped at half the row. Also owns the mode-switching described in section 3 |

### The pattern that *should* be a component but isn't

A centred row of "spinner + 20pt status label" is the entire visual content of five screens
and the empty state of a sixth. It is written out **six separate times**, near-identically:

`PcView.qml:85`, `StreamSegue.qml:211`, `QuitSegue.qml:57`, `CliPair.qml:49`,
`CliStartStreamSegue.qml:49`, `CliQuitStreamSegue.qml:31`.

If you restyle the loading state, there are six places to change and no shared definition to
change them from.

---

## 5. Every user-visible text string

There are **187 translatable strings** across the interface. Below is all of them, grouped by
where they appear. Placeholders like `%1` are filled in at runtime.

### Window frame and startup (16)

| String | Where |
|---|---|
| Version %1 | Toolbar, Settings only |
| Join our community on Discord | Discord button tooltip |
| Add PC manually | Add PC button tooltip (with shortcut appended) |
| Update available for Moonlight: Version %1 | Update button tooltip |
| Help | Help button tooltip (with shortcut appended) |
| Gamepad Mapper | Hidden button's tooltip |
| Settings | Gear button tooltip (with shortcut appended) |
| No functioning hardware accelerated video decoder was detected by Moonlight. Your streaming performance may be severely degraded in this configuration. | Startup dialog |
| Click the Help button for more information on solving this problem. | Same dialog |
| Hardware acceleration doesn't work on XWayland. Continuing on XWayland may result in poor streaming performance. Try running with QT_QPA_PLATFORM=wayland or switch to X11. | Startup dialog (Linux) |
| Click the Help button for more information. | Same dialog |
| This version of Moonlight isn't optimized for your PC. Please download the '%1' version of Moonlight for the best streaming performance. | Startup dialog |
| Moonlight detected gamepads without a mapping: | Startup dialog |
| Click the Help button for information on how to map your gamepads. | Same dialog |
| Are you sure you want to quit? | Quit confirmation (B/Escape on home screen) |
| Enter the IP address of your host PC: | Add PC dialog |

### Computers screen (27)

| String | Where |
|---|---|
| Computers | Toolbar title |
| Searching for compatible hosts on your local network... | Empty state |
| Automatic PC discovery is disabled. Add your PC manually. | Empty state, discovery off |
| PC Status: %1 | Context menu header |
| Online | Fills the above |
| Offline | Fills the above |
| View All Apps | Context menu |
| Wake PC | Context menu |
| Test Network | Context menu |
| Rename PC | Context menu |
| Delete PC | Context menu |
| View Details | Context menu |
| Unable to connect to the specified PC. | Error after adding a PC |
| This PC's Internet connection is blocking Moonlight. Streaming over the Internet may not work while connected to this network. | Appended to the above |
| Click the Help button for possible solutions. | Appended to the above |
| The version of GeForce Experience on %1 is not supported by this build of Moonlight. You must update Moonlight to stream from %1. | Error on clicking an unsupported host |
| Please enter %1 on your host PC. This dialog will close when pairing is completed. | Pairing dialog |
| If your host PC is running Sunshine, navigate to the Sunshine web UI to enter the PIN. | Same dialog |
| Are you sure you want to remove '%1'? | Delete confirmation |
| Moonlight is testing your network connection to determine if any required ports are blocked. | Network test, in progress |
| This may take a few seconds… | Same |
| The network test could not be performed because none of Moonlight's connection testing servers were reachable from this PC. Check your Internet connection or try again later. | Network test result |
| This network does not appear to be blocking Moonlight. If you still have trouble connecting, check your PC's firewall settings. | Network test result |
| If you are trying to stream over the Internet, install the Moonlight Internet Hosting Tool on your gaming PC and run the included Internet Streaming Tester to check your gaming PC's Internet connection. | Appended to the above |
| Your PC's current network connection seems to be blocking Moonlight. Streaming over the Internet may not work while connected to this network. | Network test result |
| The following network ports were blocked: | Appended to the above |
| Enter the new name for this PC: | Rename dialog |

### App grid (12)

| String | Where |
|---|---|
| Resume Game | Round play button tooltip |
| Quit Game | Round stop button tooltip |
| Resume Game | Context menu, when running |
| Launch Game | Context menu, when not running |
| Quit Game | Context menu |
| Direct Launch | Context menu |
| Launch this app immediately when the host is selected, bypassing the app selection grid. | Direct Launch tooltip |
| Hide Game | Context menu |
| Hide this game from the app grid. To access hidden games, right-click on the host and choose %1. | Hide Game tooltip |
| View All Apps | Fills the `%1` above |
| This computer doesn't seem to have any applications or some applications are hidden | Empty state |
| Are you sure you want to quit %1? Any unsaved progress will be lost. | Quit confirmation |

### Launching / streaming (10)

| String | Where |
|---|---|
| Resuming %1... | Status line |
| Starting %1... | Status line (game name) |
| Starting %1... | Status line (connection stage) |
| Starting %1 failed: Error %2 | Failure dialog |
| Check your firewall and port forwarding rules for port(s): %1 | Appended to failure |
| This PC's Internet connection is blocking Moonlight. Streaming over the Internet may not work while connected to this network. | Appended to failure |
| Tip: | Bottom hint |
| Press %1 to disconnect your session | Bottom hint |
| Start+Select+L1+R1 | Fills the above, gamepad connected |
| Ctrl+Alt+Shift+Q | Fills the above, no gamepad |

### Quitting (1)

| String | Where |
|---|---|
| Quitting %1... | Status line |

### Settings (112)

**Panel headings:** Basic Settings · Audio Settings · Host Settings · UI Settings · Input
Settings · Gamepad Settings · Advanced Settings. Plus the toolbar title, **Settings**.

**Basic Settings labels and options:** Resolution and FPS · Setting values too high for your
PC or network connection may cause lag, stuttering, or errors. · 720p · 1080p · 1440p · 4K ·
Native · Native (Excluding Notch) · Custom · %1 FPS · 30 FPS · 60 FPS · Custom (%1 FPS) ·
Video bitrate: · Lower the bitrate on slower connections. Raise the bitrate to increase image
quality. · Video bitrate: %1 Mbps · Use Default (%1 Mbps) · Display mode · Fullscreen ·
Borderless windowed · Windowed · (Recommended) · V-Sync · Frame pacing · Enable HDR

**Custom resolution dialog:** Custom resolutions are not officially supported by GeForce
Experience, so it will not set your host display resolution. You will need to set it manually
while in game. · Resolutions that are not supported by your client or host PC may cause
streaming errors. · Enter a custom resolution:

**Custom frame rate dialog:** Enter a custom frame rate:

**Basic Settings tooltips:** Fullscreen generally provides the best performance, but
borderless windowed may work better with features like macOS Spaces, Alt+Tab, screenshot
tools, on-screen overlays, etc. · Disabling V-Sync allows sub-frame rendering latency, but it
can display visible tearing · Frame pacing reduces micro-stutter by delaying frames that come
in too early · The stream will be HDR-capable, but some games may require an HDR monitor on
your host PC to enable HDR mode. · HDR streaming is not supported on this PC.

**Audio Settings:** Audio configuration · Stereo · 5.1 surround sound · 7.1 surround sound ·
Mute host PC speakers while streaming · Mute audio stream when Moonlight is not the active
window · *(tooltips)* You must restart any game currently in progress for this setting to take
effect · Mutes Moonlight's audio when you Alt+Tab out of the stream or click on a different
window.

**Host Settings:** Optimize game settings for streaming · Quit app on host PC after ending
stream · *(tooltip)* This will close the app or game you are streaming when you end your
stream. You will lose any unsaved progress!

**UI Settings:** Language · Automatic · GUI display mode · Windowed · Maximized · Fullscreen ·
Show connection quality warnings · Show configuration warnings · Discord Rich Presence
integration · Keep the display awake while streaming · *(toast)* You must restart Moonlight
for this change to take effect · *(tooltips)* Updates your Discord status to display the name
of the game you're streaming. · Prevents the screensaver from starting or the display from
going to sleep while streaming.

**Input Settings:** Optimize mouse for remote desktop instead of games · Capture system
keyboard shortcuts · in fullscreen · always · Use touchscreen as a virtual trackpad · Swap
left and right mouse buttons · Reverse mouse scrolling direction · *(tooltips)* This enables
seamless mouse control without capturing the client's mouse cursor. It is ideal for remote
desktop usage but will not work in most games. · You can toggle this while streaming using
Ctrl+Alt+Shift+M. · NOTE: Due to a bug in GeForce Experience, this option may not work
properly if your host PC has multiple monitors. · This enables the capture of system-wide
keyboard shortcuts like Alt+Tab that would normally be handled by the client OS while
streaming. · NOTE: Certain keyboard shortcuts like Ctrl+Alt+Del on Windows cannot be
intercepted by any application, including Moonlight. · When checked, the touchscreen acts like
a trackpad. When unchecked, the touchscreen will directly control the mouse pointer.

**Gamepad Settings:** Swap A/B and X/Y gamepad buttons · Force gamepad #1 always connected ·
Enable mouse control with gamepads by holding the 'Start' button · Process gamepad input when
Moonlight is in the background · *(tooltips)* This switches gamepads into a Nintendo-style
button layout · Forces a single gamepad to always stay connected to the host, even if no
gamepads are actually connected to this PC. · Only enable this option when streaming a game
that doesn't support gamepads being connected after startup. · Allows Moonlight to capture
gamepad inputs even if it's not the current window in focus

**Advanced Settings:** Video decoder · Automatic (Recommended) · Force software decoding ·
Force hardware decoding · Video codec · H.264 · HEVC (H.265) · AV1 · Renderer · Enable YUV
4:4:4 · Unlock bitrate limit (Experimental) · Automatically find PCs on the local network
(Recommended) · Automatically detect blocked connections (Recommended) · Show performance
stats while streaming · *(tooltips)* Good for streaming desktop and text-heavy games, but not
recommended for fast-paced games. · YUV 4:4:4 is not supported on this PC. · This unlocks
extremely high video bitrates for use with Sunshine hosts. It should only be used when
streaming over an Ethernet LAN connection. · Display real-time stream performance information
while streaming. · You can toggle it at any time while streaming using Ctrl+Alt+Shift+S or
Select+L1+R1+X. · The performance overlay is not supported on Steam Link or Raspberry Pi.

### Command-line screens (6)

| String | Where |
|---|---|
| Establishing connection to PC... | All three CLI screens |
| Pairing... Please enter '%1' on %2. | Pair screen |
| Pairing completed successfully | Pair screen dialog |
| Loading app list... | Start stream screen |
| Are you sure you want to quit %1? Any unsaved progress will be lost. | Start stream screen |
| Quitting app... | Quit stream screen |

### Unreachable (1)

| String | Where |
|---|---|
| Gamepad Mapping | Title of the stub screen no one can open |

### Text that is deliberately *not* translated

- **The 24 language names** in the Language dropdown — each is written in its own language
  ("Deutsch", "日本語", "Português do Brasil"), which is correct practice.
- **Renderer names** — "Vulkan", "Metal", "AVSampleBufferDisplayLayer" are product names.
- **The "x"** between width and height in the custom resolution dialog.

**Seven more languages are written but commented out**, so they don't appear in the dropdown:
Ukrainian, Hindi, Hebrew, Central Kurdish, Lithuanian, Estonian, Esperanto.

**One genuine gap:** after you enter a custom resolution, the dropdown relabels itself using
a hardcoded English "Custom (1920x1080)" (`SettingsView.qml:360`) instead of the translated
word used everywhere else. The custom *frame rate* label right next to it does this correctly
(`:512`). So a French user who sets a custom resolution sees one English word appear.

---

## 6. Contextual button hints

**Short answer: there is exactly one, on one screen.**

### The only on-screen hint

On the **launching/streaming screen**, centred 50 pixels above the bottom edge, at 18pt
(`StreamSegue.qml:232–241`):

> **Tip:** Press **Start+Select+L1+R1** to disconnect your session

…if a gamepad is connected, or:

> **Tip:** Press **Ctrl+Alt+Shift+Q** to disconnect your session

…if not. Moonlight checks for a gamepad at the moment the screen loads and picks one
(`:168–169`). The hint disappears the instant the stream actually starts.

### There is no hint bar anywhere else

No screen has a persistent footer explaining the buttons — nothing like "Ⓐ Select Ⓑ Back Ⓧ
Menu". This is a notable gap given the app is explicitly built for TV and gamepad use (the
toolbar icons are oversized specifically "for TV readability", `NavigableToolButton.qml:14`).

In particular, these gamepad actions are **completely undiscoverable**:

| Action | Button | Discoverable? |
|---|---|---|
| Open a PC's or game's context menu | X | No — nothing says so |
| Open Settings | Y or Start | No |
| Go back | B | No |
| Reach the toolbar | D-pad Up from the top row | No |
| Change a dropdown without opening it | Left / Right | No |

### The closest analogue: hover tooltips

Everything else that explains itself does so through **mouse hover tooltips**, which a
gamepad or TV user can never see. They appear after a 1-second delay and vanish after 3–10
seconds. All tooltip text is capped at 400 pixels wide (`main.qml:96`).

| Screen | Elements with tooltips |
|---|---|
| Toolbar (all screens) | Discord, Add PC, Update, Help, Settings |
| Computers | **None** — including the offline/padlock badge, which has a "TODO: Tooltip" note against it (`PcView.qml:126`) |
| App grid | Box art (shows the full game name, but only when the name is truncated), Resume button, Quit button, Direct Launch, Hide Game |
| Settings | 17 of the 37 controls |
| Launching | Transient toast notifications for launch warnings, 3 seconds each, stacked vertically |

So of the 37 Settings controls, 20 have no explanation at all, and the 17 that do only
explain themselves to someone using a mouse.

---

## 7. Layout at 1280×800

First, context: **Moonlight's own default window is 1280×600** (`main.qml:22–23`). So 1280×800
gives you 200 extra vertical pixels over what the app ships with. On macOS the window may
instead open maximized or fullscreen depending on the "GUI display mode" setting.

### The frame

The toolbar takes a fixed 60 pixels off the top, leaving a **1280×740 content area** for
every screen.

At 1280 wide, the toolbar shows its **centred** title, because there's a breakpoint at 700
pixels: above it the title is centred across the full toolbar; below it, the title switches
to a left-aligned label squeezed between the buttons (`main.qml:244`, `:285`). **This 700-pixel
rule is the only responsive breakpoint in the entire interface.** Nothing else reflows,
re-stacks, or changes at any width.

### Computers grid

Cards are 300×320 in 310×330 slots. The maths:

- Usable width: 1280 − 20 = **1260**
- Cards per row: 1260 ÷ 310 = 4.06, rounded down → **4 per row**
- Rows: (740 − 20 top margin) ÷ 330 = 2.18 → **2 complete rows visible**, plus a 60-pixel
  sliver of row 3 (18% of a card) peeking in to signal there's more

**So 8 PCs are fully visible at once.**

Side margins land on 10 pixels either way at this width, so the grid looks the same whether
you have 2 PCs or 20. But because 4 cards only consume 1240 of the 1260 available pixels, the
row sits about **20 pixels left of true centre** — a slight, consistent asymmetry.

### App grid

Tiles are 220×287 in 230×297 slots, with box art at 200×267.

- Usable width: 1280 − 20 = **1260**
- Tiles per row: 1260 ÷ 230 = 5.48 → **5 per row**
- Rows: (740 − 20) ÷ 297 = 2.42 → **2 complete rows visible**, plus 126 pixels of row 3 (42% of
  a tile — roughly the top 40% of the box art)

**So 10 games are fully visible at once.**

There's a real inconsistency here that 1280 width exposes. The centring rule only kicks in
when there are *more* games than fit in one row (`CenteredGridView.qml:8`):

| Games on the host | Side margin | Result |
|---|---|---|
| 6 or more | 55 px | Roughly centred |
| **Exactly 5** | 10 px | **Row hugs the left edge, ~120 px of dead space on the right** |
| 1–4 | 10 px | Same — pinned left |

So a host with 5 games — a full row's worth — displays them jammed against the left edge,
while a host with 6 displays them centred. The jump is abrupt and visible.

### Settings

The page splits into two columns, each **exactly half the window width** — 640 pixels each at
1280. They always split 50/50 regardless of window size; there's no point at which they
stack into one column.

Panel widths differ slightly between the columns: left-column panels are 620 pixels, right-
column panels are 610, because the right column carries 20 pixels of right padding against
the left column's 10 (`SettingsView.qml:1314`). A 10-pixel asymmetry.

**The page always scrolls at this height.** The left column holds four panels and the right
holds three, and the page's total height is set to whichever column is taller — the left. The
right column therefore ends early, leaving blank space below "Show performance stats" that you
can still scroll through.

The scrollbar is positioned 10 pixels *inside* the right edge rather than against it
(`SettingsView.qml:22–27`), so it overlaps the content rather than sitting beside it.

Within the panels at this width:

- The Resolution and Frame rate dropdowns share a row and are each capped at half of it —
  roughly **298 pixels maximum**. Each sizes itself to its longest option, so they're usually
  narrower.
- The bitrate slider's width is tied to the width of the description text above it, minus the
  "Use Default" button when that's showing. **The slider visibly changes width** when you move
  it off the default value and the button appears.
- Checkbox labels are given the full panel width and wrap when they need to. The longest —
  "Enable mouse control with gamepads by holding the 'Start' button" — fits on one line at
  610 pixels.

### Dialogs at this size

Dialogs are centred over the window and sized to their content, with caps: message text wraps
at 400 pixels and clips at 400 tall; the custom resolution explanation wraps at 300. None of
these caps scale with the window, so dialogs look identical at 1280×800 and at fullscreen.

### Where 1280×800 is comfortable, and where it isn't

Comfortable: both grids get 2 full rows plus a hint of a third, which reads correctly as
"scroll for more". The toolbar is well above its 700-pixel breakpoint.

Tight: Settings needs roughly two-and-a-half screens of scrolling to reach all 37 controls,
and a gamepad user must walk them one at a time in a single 37-step chain.

**Two empty-state messages will overflow if the window ever gets narrower.** "This computer
doesn't seem to have any applications or some applications are hidden" (App grid) and
"Searching for compatible hosts on your local network…" (Computers) are both set to wrap, but
neither is given a width to wrap *within* — so they render as one long line. At 1280 they fit.
Below roughly 820 pixels the app-grid message runs off both edges. This is invisible at
1280×800 but will bite any narrower layout.

---

## 8. Observations for redesign

These are my own notes, not part of the inventory above. Each is a concrete thing I hit while
reading, with a pointer.

**Discoverability is the biggest gap.** One hint, on one screen, for one action. Meanwhile X
opens context menus, Y opens Settings, and D-pad Up escapes to the toolbar — none of it
signposted. A persistent button-hint bar would be the single highest-value addition, and the
app already knows whether a gamepad is connected, so it could show gamepad glyphs or keyboard
shortcuts appropriately.

**Settings navigation contradicts Settings layout.** It looks like two columns; it behaves
like one 37-item list. Either the layout should follow the navigation (one column) or the
navigation should follow the layout (left/right to switch columns) — currently a user has to
learn that the right column is "below" the left.

**Selection is invisible until you touch a gamepad.** Both grids deliberately start with
nothing highlighted, then highlight the first item only if a gamepad is connected. A TV user
who is using, say, a remote rather than a recognised gamepad gets no starting point.

**Twenty of the 37 settings have no explanation, and the other 17 only explain themselves to a
mouse.** Tooltips are the wrong vehicle for a living-room app.

**The loading state is duplicated six times.** Restyling it means editing six files. It's the
clearest candidate for extraction into a shared component.

**The running-game buttons are mouse-only.** Resume and Quit are explicitly excluded from
keyboard focus, so gamepad users must go through a context menu they have no way of knowing
exists.

**Two small correctness issues worth folding into any redesign:** the custom-resolution label
loses its translation (`SettingsView.qml:360`), and the offline/padlock badge on a PC card has
never had its planned tooltip (`PcView.qml:126`) — so the difference between "offline" and
"not paired" is conveyed by icon alone.

**An unreachable screen is still in the build.** The Gamepad Mapping screen and its hidden
toolbar button (`main.qml:407`) are worth either finishing or removing, so the toolbar's
button inventory reflects reality.
