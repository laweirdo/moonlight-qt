# Game grid — as built

This is the durable authority for the Recent and Library surface: component
inventory, navigation, state model, design decisions, compromises, known
unfinished work, and validation evidence. Application source is the objective
authority for what currently runs. Live branch and build state belong in
`HANDOFF.md`; a temporary `TASK-BRIEF.md` exists only while a task is active.

Decision labels in this file carry the same weight `SPEC-host-carousel.md`
defined:

- **Invariant** — a standing product or interaction rule.
- **v1 decision** — accepted for private v1 and revisitable later.
- **Accepted evolution** — an intentional change from the original brief after
  client or hardware review.
- **Accepted compromise** — knowingly imperfect, with its cost recorded.
- **Provisional** — unfinished or awaiting a later client decision.
- **Superseded** — retained as history but no longer authoritative.

Screen targets **1280×800**, the Steam Deck panel.

Four commits carry the original game-grid work order's stages 1–4:

| Commit | Stage | What |
|---|---|---|
| `0e8c8c61` | 1 | The `lastPlayed` field, role and stamping; the review hook; the screen shell and static Library grid |
| `8fd8df94` | 2 | `GameTile.qml`: artwork, crop, fallback, loading cross-fade, focus ring and bloom |
| `1f36244b` | 3 | The Recent view and its ordering, tab switching, full controller navigation, `GameOptionsOverlay.qml`, the quit-and-switch confirmation |
| `e3c1a22d` | 4 | Motion; the Library scroll defect diagnosed and fixed |

The grid's Stage 5 validation and documentation originally produced this file.
The client reviewed the surface on 1 August 2026, requested the four changes
recorded below, accepted them, and merged the task into `bulan`. Phase B item 3
later extended this specification with the selected-game launch and quit
integration; the client accepted that separate task on 2 August 2026 and it is
now merged into `bulan`.

---

## Components

| File | What it is |
|---|---|
| `app/gui/AppView.qml` | The screen. Owns the model, tabs, the Recent ordering, all input, launching, and focus recovery for one host's Recent and Library views. |
| `app/gui/GameTile.qml` | One game: artwork cropped to a rounded rectangle, placeholder fallback, focus ring and bloom, title, running marker. |
| `app/gui/GameOptionsOverlay.qml` | Modal overlay: Play/Resume, Quit Game, Hide Game, Direct Launch, plus the quit-confirm and quit-and-switch-confirm pages it owns internally. |
| `app/gui/Bulan.qml` | Design tokens. The game-grid token block retains its historical `PROPOSED` source comment, but the screen was subsequently reviewed against the real `Steambox` library and accepted with the changes recorded below. |

Supporting, not part of this screen but changed for it:

| File | Change |
|---|---|
| `app/backend/nvapp.h` / `.cpp` | `NvApp` gains a persisted `lastPlayed` (`QDateTime`), serialized as `lastplayed` alongside `hidden` and `directlaunch`. Deliberately excluded from `operator==` so it cannot churn `AppModel::updateAppList`'s add/remove/replace pass. |
| `app/gui/appmodel.h` / `.cpp` | `LastPlayedRole` added to the model's role set. `AppModel::createSessionForApp()` stamps `lastPlayed` on both the computer's own app list and the model's visible-apps copy, then emits `dataChanged` for that role. |
| `app/gui/HostCarousel.qml` | `openAppView()`, the two call sites unchanged in contract; the `MOONLIGHT_OPEN_APPS_FOR_HOST` review hook (a timer that finds a real host by name and opens the grid on it once discovery reports it reachable). |
| `app/gui/sdlgamepadkeynavigation.cpp` | `SDL_CONTROLLER_BUTTON_LEFTSHOULDER`/`RIGHTSHOULDER`, previously unmapped (`default: break` on every screen), now send `Key_Context2`/`Key_Context3`. |
| `app/main.cpp` | Review hooks: `MOONLIGHT_FAKE_GAMES`, `MOONLIGHT_FAKE_GAMES_ART`, `MOONLIGHT_OPEN_APPS_FOR_HOST`, `MOONLIGHT_GAME_REVIEW`, `MOONLIGHT_SCREENSHOT_DELAY_MS`. |
| `app/qml.qrc` | `GameTile.qml` (stage 2) and `GameOptionsOverlay.qml` (stage 3) registered. |

---

## Navigation, as implemented

**Invariant — controller-first operation.** Every action on both views is
reachable without a mouse, focus remains visible, and B always returns to the
host carousel.

| Input | Key delivered | Behaviour |
|---|---|---|
| D-pad Left/Right, Library | `Key_Left` / `Key_Right` | One continuous flat index across the whole model, clamped at the first and last game. Crossing a row boundary is a side effect of the index being contiguous, not special-cased. |
| D-pad Up/Down, Library | `Key_Up` / `Key_Down` | Previous/next row, clamped. A partially filled final row clamps to its last real tile, never an empty cell. |
| D-pad Left/Right, Recent | `Key_Left` / `Key_Right` | Previous/next by rank in the last-played order, clamping at both ends — matching `HostCarousel.moveBy()`. |
| D-pad Up/Down, Recent | `Key_Up` / `Key_Down` | Inert, and **swallowed** (`event.accepted = true`), exactly as on the carousel, so the press cannot bubble to the StackView and drag focus into chrome this screen hides. |
| **A** | `Key_Return` / `Key_Enter` / `Key_Space` | Launches or resumes through the shared selected-game transition and custom `StreamSegue.qml`. If a different game is running, raises the quit-and-switch confirmation; only a successful quit enters that same launch path. |
| **X** | `Key_Menu` | Opens `GameOptionsOverlay` on the focused game. |
| **B, options popup** | `Key_Escape` / `Key_Back` | Closes `GameOptionsOverlay` and restores focus to the same game; the tab selections and Library scroll belong to the retained `AppView`. |
| **B** | `Key_Escape` / `Key_Back` | Normally left unaccepted so it bubbles to `main.qml` and pops back to the host carousel. While launch or quit preparation is busy, `AppView` consumes it so the retained screen cannot be popped from under an in-flight capture, proxy, or prepared Session. |
| **START** | `Key_Hangup` | Client settings. |
| **L1** | `Key_Context2` | Switch to Recent. |
| **R1** | `Key_Context3` | Switch to Library. |
| **SELECT** | `Key_Context1` | **Deliberately unbound.** See below. |
| Mouse hover, options popup | — | Selects the hovered, enabled row. |
| Mouse click, options popup | — | Selects, then activates. |

**Why SELECT is unbound and its hint withheld.** `SPEC-host-carousel.md`
records SELECT opening `HostSettingsOverlay` on the carousel. The client's own
game-grid mockup draws the same Host Settings hint on this screen. This screen
has no host-settings surface of its own, and building a second one is out of
the completed game-grid task's scope. That task explicitly left the launch and
quit segues, general screen transitions, and backend behaviour alone; building
a second host-settings overlay was never in its scope either.
`HintBar.qml`'s own governing rule is that a hint promising an action that
does nothing is worse than showing fewer hints, so the hint is withheld along
with the binding. **This is a known gap, not a completed item** — the mockup
shows a control this build does not have a destination for.

L1/R1 required a C++ change before any of this table was possible: both
shoulder buttons fell through to `default: break` on every screen, so
"tabs switch on L1/R1" could not be expressed in QML at all until
`sdlgamepadkeynavigation.cpp` gave them keycodes. `Key_Context2`/`Key_Context3`
are reserved soft keys with no text meaning, following the precedent
`Key_Context1` set for SELECT on the carousel. Both are accepted whichever tab
is active — including when the press is a no-op because that tab is already
showing — for the same reason Up/Down are swallowed on Recent.

---

## States

| State | What is shown |
|---|---|
| **Focused tile** | 2px `accentPrimary` border (vs 1px `hairline` unfocused), scaled to `motionFocusScale` (1.04) via `Easing.OutBack`/`motionOvershoot`. |
| **Unfocused tile** | 1px hairline border, scale 1.0. |
| **Running game** | Tile carries a `"Running"` label in `statusSuccess`; the header shows a status dot and `"<game> is running"`; on Recent, a focused running tile adds `"Pick up where you left off."` in the accent colour. |
| **Artwork loading** | `art.status !== Image.Ready`: the fallback (surface + title text) shows at full opacity; the artwork cross-fades in over `motionFocusMs` once ready. No spinner. |
| **Artwork missing** | `boxart` is an empty string; `art.status` never reaches `Ready`; the fallback stays shown permanently. |
| **Artwork detected as a GFE placeholder** | `art.status === Ready` but `sourceSize` exactly matches one of the three known GFE/Sunshine placeholder dimensions (130×180, 628×888, 200×266), gated off for `appCollectorGame` (Overcooked's real art matches one of these sizes by coincidence). `showArt` stays false and the fallback is shown even though the image loaded. |
| **Long title** | The fallback wraps up to 4 lines and elides; the label-row title elides against whatever width the "Running" label leaves it. |
| **Empty library** | One line, `"No games here yet."`, in the app's voice — the minimal placeholder scoped by the completed game-grid work order. The designed treatment is Phase D, deferred. |
| **Partial final row** | The Library `Repeater` draws exactly `gameCount` tiles; a short final row simply has fewer items at the row's end, and `moveLibraryRow()`'s clamp keeps Down from landing on a cell that does not exist. |
| **Single game** | Both views render one tile; on Recent, `slot`'s clamp still resolves to a single tile at distance 0 with no neighbours to draw. |

---

## Recent's ordering

**Client's rule, 1 August 2026:** last played first, then alphabetical.
Never-played games sort after every played game, and alphabetically among
themselves — both fall out of one comparator in `recomputeRecentOrder()`,
since "never" flattens to `0` and a descending sort on that puts every `0`
last.

**Where the timestamp comes from.** `AppModel::createSessionForApp()` —
the single point both the A-press and direct-launch paths pass through — reads
the current time once and writes it to both the computer's own `appList` entry
and the model's visible-apps copy, then emits `dataChanged` for
`LastPlayedRole`. This is *you pressed Play*, not *the stream succeeded*; that
is the reading the completed game-grid work order recorded as the honest and
simpler one, and it is what is built.

**Never played.** A game that has never launched has an invalid
(default-constructed) `QDateTime`, which QML sees as a `Date` with a `NaN`
time. Its Recent-neighbour second line is absent, not filled with invented
copy — `relativePlayed()` returns an empty string for `playedAt() === 0` and
the label's `visible` binding is gated on that.

**Computed in QML, not C++, and why.** `recomputeRecentOrder()` sorts an array
of source indices read off an invisible mirror `Repeater` over `gameModel`,
the same pattern `HostCarousel.qml`'s ready-count mirror uses. This is
deliberate: the review hook substitutes a plain `ListModel` for the real
`AppModel`, and a C++-side sort or proxy model could not have served that
substitute — the ordering has to be computable from role data alone, in a
layer both models can feed.

**Consequence: on a fresh install, Recent and Library hold the same games in
the same order.** With no game ever played, every `lastPlayed` is 0, so the
comparator falls through to the alphabetical tiebreak for every row —
identical to Library's own ordering. The two views then differ only in
presentation (coverflow vs grid) until something has been played. This is a
direct, verified consequence of the sort rule, not a defect: `AppModel`'s own
list is alphabetical (`appmodel.cpp:192`, unchanged), and Recent's comparator
degrades to exactly that ordering when every timestamp is equal.

---

## Motion

All values from `Bulan.qml`, sourced from brief §6 and its motion rules
(never bounce twice; nothing outlasts the next input; input always
interrupts; ambient motion is separately disableable).

| Interaction | Token / curve | Satisfies |
|---|---|---|
| GameTile focus scale (`interactionScale`) | `motionFocusMs` (180), `Easing.OutBack`, `motionOvershoot` (0.7) | Brief row 1: "Scale to 1.04 … ease-out with barely-there overshoot." Same values `SPEC-host-carousel.md` records as the client's accepted `180 ms` evolution from the brief's `140 ms`. |
| GameTile press scale | `motionPressMs` (80), `Easing.OutCubic`, `motionPressScale` (0.97) | Brief row 3: "Scale to 0.97, 80ms, immediate." |
| Artwork / fallback cross-fade | `motionFocusMs`, `Easing.OutCubic` | Rule 2 — resolves well inside the next input's likely arrival. |
| Focus-ring border colour | `motionFocusMs` `ColorAnimation` | Rule 1 — one settle on a border-colour change, no re-trigger mid-flight. |
| Recent tile travel (`x`, `y`, `tileScale`, `opacity`) | `motionFocusMs`, `Easing.InOutQuad`, gated on a `settled` flag | Copies `HostCarousel.qml`'s `HostTile` delegate block exactly: one clock for the whole move, so a tile travels, shrinks and dims as one object. `settled` stops the first frame from animating in from a corner. |
| Focus bloom glide (Library) | `motionFocusMs`, `Easing.InOutQuad` | Same clock as the tile it follows, so the halo never visibly lags the selection. |
| Tab cross-fade (Recent ↔ Library) | `motionFocusMs`, `Easing.InOutQuad` | **Deliberately not `motionTransitionMs`** (220 ms). That longer token now drives the selected-game launch handoff and remains intended for Phase B item 4's general screen transitions; switching tabs on one screen is still a focus-scale change. |
| Library scroll-to-focus | Explicit `NumberAnimation` on `contentY`, `motionFocusMs`, `Easing.OutCubic` | Rule 3, in the harder case. |

**Why the Library scroll is an explicit `NumberAnimation`, not a `Behavior`.**
A `Behavior on contentY` retargets on *every* write to `contentY`, including
the ones the `Flickable` makes on its own while a mouse drags or flicks it.
That would fight the drag: every pixel the user drags would kick off its own
eased chase back toward wherever the `Behavior` last saw as the target,
reading as the view fighting the hand on it. The animation used instead
(`libraryScrollAnimation`) is started only by `ensureLibraryFocusVisible()`,
called from a focus change — never from the `Flickable`'s own drag machinery —
and `libraryFlickable.onDraggingChanged` stops it outright the instant a drag
begins, so a manual drag always wins over a focus-follow scroll still in
flight. `restart()` rather than a fresh `start()` on repeated calls
retargets from wherever `contentY` currently sits, satisfying rule 3 without
a second competing animation ever existing.

---

## Durable decisions and accepted compromises

**Accepted evolution — 2:3 tile ratio, not the mockup's ~3:4.** Every tile
in the client's mockup was a grey placeholder, so its proportion was
estimated with no artwork in it. Client's call, 1 August 2026, made against
the real Steambox library: 2:3 is SteamGridDB's standard vertical box-art
size, and it is what 18 of the 25 box-art files already cached on the review
station actually are. At 3:4, crop-to-fill would visibly take a band off the
top and bottom of most of the client's own real library.

**Accepted evolution — Recent's focused tile is 256×384, smaller than the
mockup's ~320×440.** The mockup's proportion is neither 2:3 nor 3:4, and a
320-wide tile at the accepted 2:3 ratio would be 480 tall, which does not fit
under the tab strip with room left for the title and, on a running game, the
tagline beneath it. The first attempt at 288×432 was measured on screen and
still landed the title exactly on the hint bar's hairline. Working back from
the space genuinely available — after `gameRecentLabelGap`, the title line,
and the running-game tagline — gives 256×384. **The ratio was decided on
evidence and the copy underneath has to stay legible, so width is what gave
way**, not the ratio.

**v1 decision — labels sit on a fixed baseline, not following the tile's
drawn edge.** `HostTile.qml`'s label follows its circle's scaled edge because
a carousel tile is alone on its own line. Here, five `GameTile` labels sit
side by side and form a visible row: letting the focused one drop by the few
pixels the 1.04 focus scale adds would break that row every time the
selection moved, and the eye reads a ragged baseline before it reads a tile
being slightly larger. The focus scale is left free to grow the artwork over
the gap (`Bulan.spaceMd`) instead of pushing the label down.

**v1 decision — artwork is inset inside the focus ring (`artInset: 2`), not
drawn to the tile's edge.** Box art is almost always a full-bleed poster; drawn
edge to edge it paints straight over the focus ring, and the focused tile
becomes indistinguishable from its neighbours — the one thing the ring cannot
afford. The inset is a constant, not tied to the live border width, because
tying it to the border would rescale the artwork on every focus change, which
reads as the picture flinching.

**Superseded history — X was temporary until Game Detail.** The earlier flow
sent `Library -->|X on tile| GameDetail`, and the game-grid work order described
`GameOptionsOverlay` as a temporary route until Game Detail took over X. That
was the plan under which the grid was built, so it remains recorded here as
history rather than being silently rewritten. The client subsequently replaced
that direction before the launch-and-quit task began.

**v1 decision — X opens Game Options as its intended destination.** No Game
Detail screen is planned. A launches or resumes directly from the focused game
in Recent or Library, with that selected tile entering the launch transition.
`GameOptionsOverlay` remains the permanent private-v1 home for Play/Resume,
Quit Game, Hide Game, and Direct Launch. B closes it over the same selected
game. Popup Play/Resume uses the same selected-tile launch path as A; an
automatic Direct Launch uses that path too when opening a host. Quit Game uses
the quit path, and quit-and-switch remains a confirmed operation that waits for
a successful quit before entering launch. A quit or launch failure returns to
the retained game-grid context rather than discarding its tab, selection, or
Library scroll.

### Selected-game launch and quit integration

**Accepted and merged 2 August 2026.**
Every launch request is keyed by the existing stable `appid`, not a delegate or
row that can move when `lastPlayed` changes. `AppView` resolves the currently
rendered artwork, grabs its exact on-screen crop and mask before Session
creation, hides only that source artwork, and hands the frozen texture to
`LaunchTransition.qml`. The proxy travels once to the measured 202×302 launch
destination centred at x 640 / y 293 in the 1280×800 Deck composition, then the
custom launch surface takes ownership without a duplicate-source frame.

Recent, Library, scrolled Library, popup Play/Resume, and automatic Direct
Launch share that contract. Missing or destroyed delegates fall back to an
honest title card; capture, component, session, or push failure releases the
busy guard and restores the retained grid. Warning and failure screens show
short front-facing copy and never expose the Session's port, protocol, or raw
error text.

Quit-and-switch captures the next game's source contract first and preserves
the established early `createSessionForApp()` call and `lastPlayed` stamp. The
prepared Session remains inert while the custom quit surface waits. A failed
quit never starts it; a successful quit transfers that one Session into the
same launch path without constructing another. Direct-A quit failure returns
to the retained grid, while popup-origin failure returns to Game Options. If a
popup-origin switch succeeds but the following launch fails, dismissal also
reopens Game Options.

Both segue screens are dynamically created Items. `QuitSegue` releases itself
after removal. `StreamSegue` releases review/session-free instances then, but a
production instance removed during `quitStarting()` survives until Session's
`readyForDeletion` signal so the inherited cleanup and automatic-quit contract
remain intact.

**Accepted compromise — no backdrop blur behind the options popup.**
`HostCarousel.qml` wraps its entire screen content in an `Item` whose
`layer.effect` is a `MultiEffect` blur, gated on `hostSettingsMenu.visible`, so
the carousel blurs behind `HostSettingsOverlay`. `AppView.qml` has no
equivalent wrapping `Item` around its header, tab strip, and views — nothing
in this file gates a blur layer on `gameOptions.visible`. The popup's scrim
(`Bulan.popupScrim`) is the only thing separating it from the screen behind
it. **The cost:** the options popup reads slightly less separated from the
grid than the host-settings overlay does from the carousel. Adding the blur
would mean restructuring this screen's content into the same wrapping-`Item`
shape `HostCarousel.qml` uses, which was not done in this task; the scrim
alone carries the separation for now.

---

## The scroll defect, diagnosed

The former game-grid work order recorded, after stage 2, a Library grid seen
scrolled down one row with no input — captured once, two immediate re-runs were
correct, and explicitly *not reproduced, not diagnosed, not claimed fixed*.

It became reproducible in stage 4, once the Library tab could be opened
directly against the real host: every run landed a row down with the focused
tile off screen above.

**Cause.** A host's app list arrives from the network in chunks. Each chunk's
arrival fires the Library `Repeater`'s `onItemAdded`, and each of those called
`ensureLibraryFocusVisible()` — while the Library was not the visible tab, and
while `libraryFlickable.contentHeight` was still growing row by row as more
chunks landed. The "is the focused row below the viewport" test ran against a
viewport that had not reached its final geometry, computed a `contentY` for a
grid a fraction of its eventual size, and scrolled there. Nothing recomputed
it afterwards, so the number was stale by the time the player actually
switched to Library. It looked intermittent purely because it depended on how
the host happened to chunk its app list on that particular run.

**Fix.** `ensureLibraryFocusVisible()` now declines to run unless the Library
is the visible tab (`root.activeTab !== "library"` returns early) and the
viewport has a real height (`libraryFlickable.height <= 0` returns early). It
is re-run when the tab becomes active (`onActiveTabChanged`) and whenever
either the viewport's height or its content height changes
(`onHeightChanged`, `onContentHeightChanged`). Verified across three
consecutive runs against the real Steambox library.

**The transferable lesson.** A scroll-into-view computation is only as
trustworthy as the geometry it is computed against. A `Repeater` populated
from data that arrives in pieces — a network response, a paginated query, a
lazily-loaded list — can fire its per-item signals many times before the
container it lives in has reached its final size, and code that reacts to
"an item was added" by measuring the current viewport will silently measure
the wrong one, more than once, without ever raising an error. The visible
symptom (intermittent, unrepeatable, low-frequency) looks like a race
condition or a UI-thread timing fluke; the actual cause is a correctness
assumption — "the geometry I'm reading is final" — that nothing in the code
was verifying. The fix pattern is general: gate the reactive computation on
both *is this visible* and *is this geometry settled*, and re-run it on every
signal that could mean either changed, rather than trusting a single trigger
to have caught the final state.

---

## Known unfinished work and v1 compromises

This table records durable surface gaps, not a current task or branch.

| Thing | Label | Durable state |
|---|---|---|
| **SELECT / Host Settings** | **Provisional** | Deliberately unbound; hint withheld. The mockup shows Host Settings on this screen; no host-settings surface exists for it. Not started as a side effect of this task's scope. |
| **Backdrop blur behind the options popup** | **Accepted compromise** | Absent. `HostCarousel.qml`'s blurred-backdrop pattern was not extended here; the scrim alone separates the popup from the grid. Would require restructuring this screen's content into a wrapping layered `Item`. |
| **Designed empty-library state** | **Provisional** | One line, `"No games here yet."`, is the whole treatment. The designed version is Phase D per `ROADMAP.md` and `FLOW.md` records it as unresolved flow design. |
| **Screen transitions (Phase B item 4)** | **Provisional** | The tab cross-fade uses `motionFocusMs`, deliberately not `motionTransitionMs`. Item 3 now uses the 220 ms token for its selected-game launch handoff; wiring it into the rest of the core route remains item 4. |
| **Tile aspect ratio vs. the client's own artwork** | **Provisional** | 18 of 25 cached box-art files on the review station are 2:3, which the build now matches; the remaining 7 are 3:4 and lose a band top and bottom under crop-to-fill. Raised for client decision at stage 2 review, not settled. |
| **Rename PC, merged multi-host library** | **Deferred** | Explicitly excluded from the completed game-grid and launch/quit work orders; unrelated to these surfaces. |

---

## Reviewing it without a real host

```
MOONLIGHT_FAKE_GAMES=mixed MOONLIGHT_INITIAL_VIEW=qrc:/gui/AppView.qml ^
  MOONLIGHT_SCREENSHOT=C:\path\shot.png Moonlight.exe
```

(Windows runs windowed rather than offscreen — see `BUILDING-WINDOWS.md`.)

| Variable | What it does |
|---|---|
| `MOONLIGHT_FAKE_GAMES=<preset>` | Substitutes a fixed `ListModel` for the real `AppModel` in `AppView.qml`. Required, not optional: a fake host's row in the carousel names a real machine at the same position, and `HostCarousel.actConfirm()` blocks the real-action path outright for fake hosts — reading past the end of the real list segfaulted the app once already — so there is no other way to open this screen at all without a real paired host. Presets: `none` (proves the empty-library placeholder), `one` (single-item grid, no partial-row arithmetic), `partial` (7 games — one full row of 5 plus a partial row of 2), `many` (23 games — more than one screen, partial final row), and `mixed` (default for any unrecognised value; ~12 games covering a running game, a 45+ character title, and a mix of played/never-played dates in one list). |
| `MOONLIGHT_FAKE_GAMES_ART=<dir>` | Fake games take real box art (`1.jpg`, `2.jpg`, … in call order, consistent across every preset) instead of always falling back to the placeholder tile. Unset, every fake game has no artwork at all — the common review case. |
| `MOONLIGHT_OPEN_APPS_FOR_HOST=<name>` | Opens the game grid for a **real, paired** host by name once the carousel settles, through `HostCarousel`'s ordinary `openAppView()` — so an offline, unpaired, or unsupported host is refused exactly as a real A-press would refuse it. The opposite of `MOONLIGHT_FAKE_GAMES`, and the two must not be combined: only a real host proves box art actually arriving from `BoxArtManager` — real files, real aspect ratios, real load timing, real GFE placeholder detection. **Needs `MOONLIGHT_SCREENSHOT_DELAY_MS`** because a saved host loads offline at startup and only reports itself reachable once the discovery poll answers; without extra delay, the screenshot grabs the carousel instead of the grid. |
| `MOONLIGHT_GAME_REVIEW=<case>` | Keeps `options`, `switch`, and `library`, and adds fake-only launch/quit routes: Recent, Library, scrolled Library, resume, warning, launch failure, valid/no-source fallback, repeated launch cycles, quit progress/failure, quit-and-switch success/failure, and popup-origin switch-then-launch failure. These routes exercise QML state and navigation without touching a real host; they do not prove a real stream or quit. |
| `MOONLIGHT_SCREENSHOT_DELAY_MS=<ms>` | Extra wait added to the screenshot timer's base interval (2500 ms) before the grab. The base interval is enough for any screen built from state the app already has; it is not enough for one that has to wait on the network, which is exactly `MOONLIGHT_OPEN_APPS_FOR_HOST`'s case — a saved host loads offline and only becomes reachable when the discovery poll answers. Zero unless set, so every existing recipe times exactly as before. |

Existing carousel hooks (`MOONLIGHT_FAKE_HOSTS`, `MOONLIGHT_INITIAL_VIEW`,
`MOONLIGHT_SCREENSHOT`, `QT_QPA_PLATFORM=offscreen`) apply unchanged.

---

## Validation record

### Performed

- Windows review-station builds with Qt 6.9.3 / MSVC, `qmlcachegen` compiling
  every changed QML file.
- `qmllint` on every changed QML file. The current launch/quit pass exits 0
  with `[import]`, `[index]`, `[missing-property]`, `[unqualified]`,
  `[unresolved-type]`, and `[use-proper-function]` warnings around registered
  runtime types, dynamic properties/callbacks, and existing delegate patterns.
- Screenshot review against the real paired host `Steambox` (roughly twenty
  games, real box art from `BoxArtManager`) on both the Recent and Library tabs.
- Screenshot review against every `MOONLIGHT_FAKE_GAMES` preset (`none`,
  `one`, `partial`, `many`, `mixed`) on both tabs.
- The per-game options popup and the quit-and-switch confirmation, captured
  via the `MOONLIGHT_GAME_REVIEW` hook.
- Application logs read on every run. Only two known-environmental lines
  appear: `mDNS is disabled by user preference` (a local machine preference,
  not a code fault) and the `ToolTip attached property`
  line from `main.qml` (the same pre-existing environmental warning
  `HANDOFF.md` records for the prior task).
- The Library scroll defect: reproduced against the real host, diagnosed, and
  the fix verified across three consecutive runs against the real Steambox
  library.
- The launch/quit task's Windows Release target rebuilt after each stage; the
  final build compiled the revised QML through `qmlcachegen` and linked with
  only the pre-existing `LNK4291` warning.
- The complete deterministic launch/quit matrix rendered to screenshots with
  no critical QML runtime error. The only repeated QML warning was the existing
  `main.qml` `ToolTip attached property` line.
- A 51-cycle repeated-launch run showed no upward working-set accumulation:
  the first five warm samples averaged 168.4 MiB and the last five 162.3 MiB.
  A Windows `QSG_RENDER_TIMING` trace, after discarding startup and screenshot
  frames, recorded 84 steady frames at p95 1 ms, maximum 13 ms, with none over
  16.67 ms. This is supporting evidence from an RTX 4070 Ti SUPER using Qt's
  basic render loop, not a Steam Deck performance result.
- Two independent read-only lifecycle/performance audits found retained segue
  Items, per-frame JavaScript dot motion, a replay-pop race, Session cleanup
  ownership, and repeated failure dismissal risks. The fixes were re-audited,
  rebuilt, and the affected deterministic routes rerun successfully.
- A live Windows Computer Use pass sent controller-equivalent keys through the
  rendered fake-game route: B recovered from launch failure, Right visibly
  moved Recent focus, X opened the selected game's options, and B closed the
  popup with that game still selected. The first pass exposed Qt's deprecated
  implicit `event` injection warning; commit `285ff231` declares all nine
  options key-handler parameters. After rebuild and rerun, the log contained
  only the known `main.qml` ToolTip warning.

### Not performed

- Any Steam Deck check, in Desktop Mode or Game Mode.
- Any LCD or OLED appearance check.
- Any hardware-gamepad review. Every controller path described in this file
  (D-pad, A, X, B, L1/R1, START) has been reasoned about, built, and read as
  keyboard-delivered keycodes in code and in the review hooks — none of it has
  been driven with a physical gamepad by anyone, client or otherwise.
- Any actual stream launch, quit, or quit-and-switch. No game has been started
  or stopped through this screen; `launchOrResumeApp()`, `quitRunningGame()`,
  and the quit-and-switch dispatch have been read and reasoned about, not
  exercised end to end against a live stream.
- Any physical-controller or live human judgement of the launch motion in
  flight. The Windows automation proves key delivery and recovery on the
  rendered fake route; it does not establish how the motion feels under a
  player's thumb.

---

## Client review, 1 August 2026 — four changes

The client drove the deployed review build against the real `Steambox` library
and reported four faults. All four are fixed.

**1. The focused game's title block broke on a running game.** `Running` was
drawn in a `Row` beside a much larger title, and a `Row` aligns tops, so the
smaller word rode up near cap height; centring the *pair* also dragged the
title off-centre from its own artwork. `Running` now shares the title's
baseline, and the title stays centred on the tile with `Running` hanging off
its right-hand end. The title is bounded and elides — it previously carried
`elide` with no width, which does nothing.

**2. Recent showed three games however wide the screen was.** The ±2 slot clamp
was copied from `HostCarousel.qml`, where three circular tiles is the whole
design, and it was wrong here. The visible radius is now computed from the
view's width, the spread and the neighbour's width, and only counts a slot
whose tile lands **whole** inside `layoutScreenMarginX` — the first attempt
counted slots whose centre fitted and sliced the outermost tile in half against
the window edge. `gameRecentSpread` tightened from 290 to 250 so five tiles fit
at 1280 rather than three. **Accepted evolution:** about 32px of clear ground
between the focused tile and its neighbour, against the ~65px it started with.
Seeing more of the library beats air around the selection.

**3. The typeface changed as a game scrolled through focus.** The focused title
was `familyDisplay` and the neighbours' `familyUi`, as two elements swapped by
visibility. `HostTile.qml` had already met and settled this: *one text that
grows into the other cannot change typeface on the way, so the branded face
wins.* There is now one title per tile, always `familyDisplay`, with size and
colour interpolated on a `focusAmount` animated on the same clock as the tile's
travel. Secondary lines stay `familyUi`, matching `HostTile`'s status lines.

**4. Upstream's toolbar flashed between the host carousel and the grid.**
Toolbar visibility is imperative across this application — each screen writes
`toolBar.visible` in its own activation handlers. That worked while every
screen agreed, and stopped working once Bulan screens arrived: the carousel
handed the toolbar back on the way out, the grid took it away on the way in,
and the frames between the two handlers drew it.

Neither Bulan screen restores it any more. Screens that genuinely want the
toolbar already turn it on themselves. At the time of the grid task, the
remaining case was an upstream `StreamSegue` or `QuitSegue` handing it back to
the Bulan grid underneath, so a Bulan screen declared `bulanScreen: true` and
`main.qml` hid the toolbar after a settled push or pop. **Later Phase B item 3
evolution:** both segues are now custom Bulan screens and participate directly
in that same hidden-toolbar contract; the backstop remains for safe recovery.

**Not verified:** the transition itself cannot be photographed — a screenshot
hook grabs a settled frame, and the flash is the frames in between. The code
path is deterministic by construction; whether the flash is gone needs an eye
on it.

---

## Client review outcome

Held on 1 August 2026. The client drove the deployed grid against the real
`Steambox` library, requested the four changes recorded above, accepted the
result, and instructed the merge into `bulan`. The client accepted the separate
launch-and-quit work order on 2 August 2026 after its final completion audit;
it is merged into `bulan` and its temporary task brief has been retired.
