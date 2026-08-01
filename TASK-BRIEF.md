# Task brief — the game grid

**Opened:** 1 August 2026
**Branch:** `game-grid`, cut from `bulan` at `6712ac83`
**Roadmap item:** Phase B item 2 — *Game grid: Recent and Library views*

This file is temporary. It owns the scope and acceptance criteria of this one
task. It does not override `AGENTS.md`, `bulan-creative-brief.md`, `FLOW.md` or
`ROADMAP.md`, and it is deleted when the client accepts the work. Durable
decisions move to `SPEC-game-grid.md` at the end, not before.

---

## Source of the design

Two client mockups supplied in the session of 1 August 2026:

- Recent view — coverflow of three tiles, focused tile centred
- Library view — five-column scrolling grid, first tile focused

**The mockup files are not yet in the repository.** They must be committed as
`design/game-grid-01-recent.png` and `design/game-grid-02-library.png` before
this task closes, or the spec written at the end will point at nothing.

Where the mockups and a repository authority disagreed, the conflict was put to
the client rather than resolved silently. Those answers are recorded under
*Decisions taken* below.

---

## What is being replaced

`app/gui/AppView.qml` is stock upstream Moonlight with a handful of Bulan
colours substituted into it. It instantiates stock Qt Quick Controls throughout —
`CenteredGridView`, `NavigableItemDelegate`, `RoundButton`, `ToolTip`,
`NavigableMenu`, `NavigableMessageDialog`, `ScrollBar` — which `AGENTS.md`
forbids on a Bulan screen. This is a rebuild of that file, not an edit of it.

It is reached from exactly two places, both in `HostCarousel.qml`:

| Call site | Purpose |
|---|---|
| `actConfirm()` → `openAppView(index, uuid, name, false)` | A on a paired, online host |
| `handleHostMenuAction("apps")` → `openAppView(index, uuid, name, true)` | Host settings → *View all apps* |

Both pass `computerIndex` and `showHiddenGames`. **That contract is preserved**,
so the carousel, the busy state keyed to it, and the CLI paths are untouched.

---

## In scope

### Screens and states

| Item | State |
|---|---|
| Recent view | Full |
| Library view | Full |
| Game tile: artwork, focus ring, focus bloom, title, running marker | Full |
| Missing / placeholder artwork fallback | Full |
| Artwork still loading | Full |
| Long titles | Full |
| Header: host monogram, host name, connection line | Full |
| Header: "<game> is running" banner | Full |
| Tab strip with L1/R1 switching | Full |
| Hint bar for both views | Full |
| Per-game options popup (X) | Full — see *Decisions taken*, item 2 |
| Quit-and-switch confirmation | Full — see *Decisions taken*, item 4 |
| Last-played recording and ordering | Full — see *Decisions taken*, item 1 |
| Empty library for a paired host | **Minimal placeholder only.** One line in the app's voice. The designed treatment is Phase D and `FLOW.md` records it as unresolved flow design. |

### Behaviour

- **A** on a tile launches through the existing `StreamSegue` path, unchanged.
  Reads *Resume* when that game is the one currently running, *Play* otherwise.
- **X** on a tile opens the per-game options popup.
- **B** returns one level, to the host carousel.
- **L1 / R1** switch between Recent and Library.
- **START** opens client settings; **SELECT** opens host settings, matching the
  carousel.
- Directional input follows the visible spatial layout: in Library, Left/Right
  move along a row and Up/Down move between rows; in Recent, Left/Right move
  along the row and Up/Down are inert and swallowed, as on the carousel.
- Focus is visible at all times and recovers after the options popup, the
  quit-and-switch confirmation, a tab change, a model update, and returning from
  a stream.
- Recent and Library remain **host-specific**, per `ROADMAP.md`.

---

## Explicit exclusions

Not built in this task, and not to be started as a side effect:

- Game Detail (`ROADMAP.md` Phase B item 3)
- `StreamSegue.qml` — remains stock upstream Qt, the deferred Phase B gap
- Phase B item 4, screen transitions
- Onboarding, settings, the stream overlay
- Any change to the host carousel beyond what the preserved `openAppView`
  contract already requires
- Discovery, pairing, streaming or any other backend behaviour, except the
  additive last-played record described below
- Phase D empty and failure states other than the minimal placeholder above
- Rename PC, merged multi-host library, and every other deferred item

Nearby upstream problems found on the way are recorded, not fixed.

---

## Decisions taken

Client decisions of 1 August 2026. Each is recorded here as **provisional to
this task**. They become durable only when they are written into
`SPEC-game-grid.md` and `FLOW.md` at the end, after the client accepts the work.

### 1. Recent gets a real last-played record

Nothing in this application has ever recorded when a game was last played.
`NvApp` carries `id`, `name`, `hdrSupported`, `isAppCollectorGame`, `hidden` and
`directLaunch`, and `AppModel` orders its list alphabetically
(`appmodel.cpp:192`). The mockup's *Yesterday* / *Tuesday* lines have no source.

**Decision: the app starts recording it.** `NvApp` gains a persisted
`lastPlayed`, following the exact precedent of `hidden` and `directLaunch` —
client-side attributes serialised with the host and saved through
`clientSideAttributeUpdated()`. No discovery, pairing or streaming behaviour
changes.

Implementation constraints:

- Stamped in `AppModel::createSessionForApp()`, the single point where a session
  is created for an app. This means *you pressed Play*, not *the stream
  succeeded*. That is the honest and simpler reading and is what is being built.
- **`lastPlayed` must not be added to `NvApp::operator==`.** That operator drives
  `updateAppList`'s add/remove/replace pass, and including a timestamp there
  would churn the list on every launch.
- A game that has never been played has no date. Its second line is **absent**,
  not filled with invented copy.

### 2. Sort order, and what Recent is

**Client's wording, 1 August 2026:** Recent sorts by last played first, then
alphabetically. Recent is therefore **never empty** unless the library itself is
empty, and the app always lands on Recent.

Practical consequence the client should see at stage 1: **on a fresh install,
Recent and Library contain the same games in the same order.** The two views
differ only in presentation until something has been played. That is a direct
consequence of the chosen rule and is not a defect.

Library keeps its own alphabetical order regardless.

### 3. X opens options now, Game Detail later

`FLOW.md` states `Library -->|X on tile| GameDetail`. The mockup's hint bar
reads *Options*. Game Detail is not in this task.

**Decision: X opens a Bulan glass options popup** — Play/Resume, Quit Game, Hide
Game, Direct Launch — matching the mockup's label. It is the only route by which
quitting a running game stays reachable before Game Detail exists. When Game
Detail is built it takes over the same button.

`FLOW.md` is **not** edited during this task. The edge is not wrong in intent;
whether it is reworded is a client decision taken at acceptance.

### 4. Quit-and-switch confirmation is kept, rebuilt

Pressing A on a game while a different one is running must still ask before
killing the running session. Upstream does this with a stock
`NavigableMessageDialog`, which is forbidden here.

**Decision: rebuilt as a Bulan glass confirmation**, following
`BulanQuitConfirmation.qml` and `HostSettingsOverlay.qml`.

### 5. Visual decisions taken from the mockups

- **The striped "BOX ART" fill is a mockup placeholder, not a shipped asset.**
  Where a game has no artwork, the tile is a Bulan surface carrying the game's
  title in the display face — the treatment upstream already falls back to,
  drawn properly. Upstream's placeholder detection by exact pixel dimensions
  (`AppView.qml:96–115`) is preserved; it is the only way to tell GFE's
  placeholder art from real art.
- **Artwork is cropped to fill a 3:4 portrait tile**, centred. Sunshine art
  varies wildly; cropping keeps the grid regular, where letterboxing leaves
  inconsistent bars.
- **While artwork loads, the tile shows the fallback and cross-fades to the art
  when it arrives.** No spinner.
- **The tab strip is not a focus target.** L1/R1 switch views; the D-pad only
  ever moves between games. Directional input on this screen stays purely
  spatial, as on the carousel.
- **Both views show the same three right-hand hints** — *Switch tab*, *Client
  Settings*, *Host Settings*. The Recent board shows the first and third, the
  Library board the second and third; that reads as the bar running out of room
  rather than a decision. **Risk to check on screen at 1280×800:** three hints
  on the right may not fit. If they do not, the client decides what goes.

---

## Tokens

Every value below is measured off the client's mockups, normalised to 1280×800.
They follow the precedent set by `hostTileSpread`, `hostTileLabelGap` and
`hostTileBusyDotGap`: screen-specific measurements, not steps on the generic
spacing scale.

**None of these is permanent until the client approves it after seeing it on a
real screen.** The waiting-dot size was changed for exactly this reason during
the previous task.

| Proposed token | Value | Derivation |
|---|---|---|
| `gameTileWidth` | 216 | Library tile, mockup 2 |
| `gameTileHeight` | 288 | 3:4 against the above |
| `gameGridGap` | 26 | Column gap, mockup 2; five columns fit `layoutScreenMarginX` exactly |
| `gameGridColumns` | 5 | Mockup 2 |
| `gameRecentTileWidth` | 324 | Focused Recent tile, mockup 1 |
| `gameRecentTileHeight` | 432 | 3:4 against the above |
| `gameRecentNeighbourScale` | 0.70 | Neighbour ÷ focused width, mockup 1 |
| `gameTileLabelGap` | tbd | Clear space under the tile before the title |

Both tile sizes clear the 64×64 minimum focus target by a wide margin.

`Bulan.qml` is the runtime source. Any value duplicated into `BulanTokens.qml`
for the proof sheet is updated in the same commit.

---

## Reviewing it without a real host

The review station has no paired PC with a game library, and a fake host
deliberately cannot open a real game list — `HostCarousel.actConfirm()` blocks
the entire real-action path in review mode, because a fake row's index names a
real machine at the same position and reading past the end of that list
segfaulted the app once already.

A review hook is therefore **required**, not optional, or this screen cannot be
looked at before the client sees it. Planned, following the established
`MOONLIGHT_FAKE_HOSTS` pattern and inert unless set:

| Variable | What it does |
|---|---|
| `MOONLIGHT_FAKE_GAMES=<preset>` | Substitutes a fixed game list, covering: empty, one game, a partial final row, more than one screen, missing artwork, a very long title, and one game running |

Existing hooks that apply: `MOONLIGHT_INITIAL_VIEW`, `MOONLIGHT_SCREENSHOT`,
`QT_QPA_PLATFORM=offscreen` (Windows runs windowed instead — see
`BUILDING-WINDOWS.md`).

---

## Acceptance criteria

1. No stock Qt Quick Control is instantiated in any visible part of the screen.
   The `QtQuick.Controls` import remains only for `StackView` attached
   properties, as on the carousel, and the reason is recorded.
2. No raw colour, size, spacing, radius, opacity or duration in the screen —
   every one comes from `Bulan.qml`.
3. Every action on both views is reachable with a gamepad alone.
4. Focus is visible at all times and recovers after: the options popup, the
   quit-and-switch confirmation, a tab change, a model update while a tile is
   focused, and returning from a stream.
5. Directional input matches the visible layout in both views, including the
   first row, the last row, a partially filled final row, and a single-item
   library.
6. A launches through the existing `StreamSegue` path with no change to it.
7. X opens the options popup; every entry in it works with a gamepad.
8. B returns to the host carousel with carousel focus intact.
9. Recent orders by last played, then alphabetically, and the ordering survives
   an app restart.
10. A game with no artwork, malformed artwork, or a very long title is legible
    and does not break the grid.
11. `qmllint` is clean-by-project-standard on every changed QML file, and the
    documented Windows build compiles every one of them.
12. The `openAppView` contract and the carousel's busy state are unchanged.

---

## Validation plan

Smallest checks first. Evidence is recorded honestly, including what was not
done.

1. `qmllint` on every changed QML file
2. The documented Windows build per `BUILDING-WINDOWS.md`, confirming
   `qmlcachegen` compiles each changed file
3. Application log read on every launch
4. Screenshot review of every state through `MOONLIGHT_FAKE_GAMES`
5. Keyboard navigation of every boundary case in criterion 5
6. **Hardware gamepad review by the client** of all affected controls
7. Model refresh while a tile is focused
8. Restart, confirming the last-played order persisted

**Will not be claimed:** Steam Deck validation in either mode, LCD or OLED
appearance, real-host box-art delivery, and any real stream launch, unless one
is actually performed and recorded.

---

## Stages

Each stage stops for client review. Nothing is committed before the client
approves that stage. One logical commit per approved stage.

| Stage | Content |
|---|---|
| 1 | Data: `lastPlayed` field, role and stamping. The review hook. The screen shell — atmosphere, host header, running banner, tab strip, hint bar — and the static Library grid with plain tiles. No input, no focus treatment, no motion. |
| 2 | `GameTile.qml`: artwork, crop, fallback, loading cross-fade, focus ring and bloom, title, running marker, long titles. Driven by a plain `focusedIndex` so it is reviewable before input exists. |
| 3 | The Recent view and its ordering. Tab switching. All controller navigation. A / X / B / L1 / R1 / START / SELECT. The options popup. The quit-and-switch confirmation. Focus recovery. The landing rule. |
| 4 | Approved motion and polish. |
| 5 | Validation and documentation. |

Ordering is computed in QML from the model's `lastPlayed` and `name` roles,
using the mirror-`Repeater` pattern `HostCarousel.qml` already uses for its ready
count. No C++ sort or proxy model: the review hook substitutes a plain
`ListModel`, and a C++ ordering could not serve it.

### Delegated assignments

Implementation is delegated to Sonnet agents with narrow, explicit briefs. One
agent owns a file or surface at a time; no agent commits, pushes, merges, or
widens scope. Every diff is reviewed against the mockups, this brief, and
`AGENTS.md` before the client sees it.

Planned ownership:

| Stage | Surface | Owner |
|---|---|---|
| 1 | `nvapp.h/.cpp`, `appmodel.h/.cpp` | one agent |
| 1 | `AppView.qml` static layout, review hook in `main.cpp` | one agent, after the above |
| 2 | The game tile component | one agent |
| 3 | Navigation and route integration in `AppView.qml` | one agent |
| 3 | The options popup and the confirmation | one agent |

Product, UX, visual, copy, scope, token, branching and authority-conflict
decisions are not delegated.

---

## Raised, not fixed

Recorded here during the task and moved to the right home at the end.

- **The hint bar promises Play and Options on an empty library.** Seen in the
  stage 1 `none` capture. That is precisely the fault `HintBar.qml` was built to
  prevent — a hint for a button that does nothing. **In scope: stage 3 withholds
  both when the library is empty.**
- **Direct launch is temporarily gone.** Upstream auto-started an app marked
  *Direct Launch* when its host was opened. The rewrite removed that block with a
  `// STAGE 3:` marker naming what has to come back. **In scope: stage 3.**
- **The tab glyphs read `LB` / `RB`, not `L1` / `R1`.** The mockup drew `L1`/`R1`.
  `ControllerGlyph` resolves shoulder art from the attached controller, and the
  review station reports an Xbox-family pad, so `LB`/`RB` is the system working
  correctly rather than a defect. A Steam Deck resolves to the same art by the
  v1 glyph decision in `ROADMAP.md`. **Client decision, not urgent:** live with
  the hardware's own lettering, or add a Deck/PlayStation-style shoulder set.
- **`AppModel::initialize()` asserts on an out-of-range `computerIndex`.** Not
  introduced here and not reachable in normal use, but it is why review mode has
  to skip creating the real model outright. Recorded for later consideration; not
  fixed in this task.
- ~~**The Library grid scrolled itself down one row, once, and has not done it
  again.**~~ **Diagnosed and fixed in stage 4, 1 August 2026.** It became
  reproducible once the Library tab could be opened directly against the real
  host: every run landed a row down with the focused tile off screen above.

  **Cause.** A host's app list arrives in chunks, so the Repeater's
  `onItemAdded` fires several times as rows land. Each one called
  `ensureLibraryFocusVisible()` — while the Library was not the visible tab and
  while `contentHeight` was still growing. The "is the focused row below the
  viewport" test ran against a viewport that had not reached its final geometry,
  computed a `contentY` for a grid a fraction of its eventual size, and scrolled
  there. Nothing recomputed it afterwards. It looked intermittent because it
  depended on how the host happened to chunk its app list on that run.

  **Fix.** `ensureLibraryFocusVisible()` now declines to run unless the Library
  is the visible tab and the viewport has a real height, and it is re-run when
  the tab becomes active and whenever the viewport's height or content height
  changes. Verified across three consecutive runs against the real host.
- **The tile's aspect ratio may be wrong for the client's own artwork.**
  Measured on 1 August 2026 from the 25 box-art files this machine has already
  cached from the real host `Steambox`: 18 are **2:3** (600×900), 4 are 3:4
  (528×704) and 3 are 3:4 (600×800). The mockup's tile is roughly 3:4 and the
  proposed tokens follow it, so with crop-to-fill the majority of the client's
  real posters lose a band top and bottom. **Client decision, to be put to them
  at stage 2 review with both versions on screen.** Not settled here.
- **None of the cached art matches upstream's placeholder dimensions**
  (130×180, 628×888, 200×266), so the preserved placeholder-detection check has
  nothing to catch on this host. It stays, because a GFE host would produce
  those and this one is Sunshine; but it means the *placeholder* half of the
  artwork fallback still has no real-world evidence behind it.
- **`mDNS is disabled by user preference`** appears in the review station's log
  on every launch. A local preference on this machine, not a code fault.
