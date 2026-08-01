# Bulan - current handoff

Current as of **1 August 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. Always inspect Git before relying on this
snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan` at `6712ac83`. **Unchanged by this work.** |
| Task branch | `game-grid`, cut from `bulan` at `6712ac83`. **Not merged. Not pushed. Not deleted.** |
| Remote | `origin` only, the client's fork. Nothing has been pushed for this task |
| Active task | **`TASK-BRIEF.md`, the game grid.** Built through stage 4; the client has not yet accepted it |
| Open defects | None recorded in `BUGS.md` |

**The client has approved stages 1 and 2 and instructed the work to continue
through the remaining stages. They have not seen stages 3, 4 or 5.** Nothing on
this branch has been driven with a hardware gamepad, by anyone.

The next objective after acceptance is `ROADMAP.md`'s Phase B item 3, game
detail and launch — and the two Phase B gaps the grid raised, recorded there.

## What was built

Phase B item 2, the game grid: `AppView.qml` rebuilt as a Bulan screen with
Recent and Library views. `SPEC-game-grid.md` owns the durable design and the
full reasoning.

| Commit | What |
|---|---|
| `0e8c8c61` | The shell, the static Library, the `lastPlayed` record, the review hook |
| `8fd8df94` | `GameTile.qml` — real box art, fallback, focus ring and bloom |
| `1f36244b` | Controller navigation, Recent, tabs, launching, the options popup |
| `e3c1a22d` | Motion, and the diagnosis of the Library scroll defect |

## Current product state

| Area | Current state |
|---|---|
| Recent | Horizontal row, focused tile centred, ordered by last played then alphabetically. Focused game carries its title, a `Running` marker, and `"Pick up where you left off."` when it is the running one. Neighbours carry a relative last-played line, or none if never played. |
| Library | Five-column scrolling grid, 216×324 tiles at 2:3. Scroll follows focus. |
| Artwork | Cropped to fill, rounded, inset inside the focus ring. Games with none, or with GFE's placeholder, fall back to their title on a plain surface. Upstream's exact-pixel placeholder detection is preserved. |
| Launching | **Unchanged.** A pushes the existing `StreamSegue`. Quit and quit-and-switch push the existing `QuitSegue`. Both remain stock upstream Qt. |
| Options (X) | Custom Bulan glass popup: Resume/Play, Quit Game, Hide Game, Direct Launch, with upstream's enable rules preserved and a blocked entry saying why. |
| Last played | New persisted per-app attribute on `NvApp`, stamped in `AppModel::createSessionForApp()` — i.e. when you press Play, not when the stream succeeds. |
| L1 / R1 | **Newly mapped.** Both shoulder buttons previously delivered no keycode to QML at all, on any screen. |
| SELECT on the grid | **Unbound, and its hint withheld.** The grid has no host-settings surface. The client's mockup shows one. Recorded as a Phase B gap. |
| Empty library | One line, `"No games here yet."` A holding treatment; the designed state is Phase D. |
| Everything else | Discovery, pairing, streaming, the host carousel, its busy state and the root quit confirmation are untouched. |

## Implementation notes

- Recent's ordering is computed **in QML**, from the model's own roles, using
  the mirror-`Repeater` pattern the carousel already uses. Not a C++ sort and
  not a proxy model: the review hook substitutes a plain `ListModel`, and
  neither could have served it.
- `lastPlayed` is deliberately **excluded from `NvApp::operator==`**. That
  operator drives `updateAppList`'s add/remove/replace pass, and a timestamp
  there would churn the whole list on every launch.
- The shoulder buttons send `Key_Context2` / `Key_Context3`, following the
  precedent set when Y and Select had the same problem. They are deliberately
  **not** switched by the swap-face-buttons preference.
- The options popup has **no backdrop blur**, unlike the host-settings overlay.
  Giving it one means wrapping the whole screen in a single layered item, which
  is a structural change to a file this task had already rewritten twice. The
  scrim carries it alone. Recorded as an accepted compromise in
  `SPEC-game-grid.md`.
- Artwork masking uses `MultiEffect`, which is a shader effect. **It renders as
  nothing under `QT_QPA_PLATFORM=offscreen`**, so the Mac's offscreen
  screenshot path cannot review artwork. Windows and the Deck both have a real
  GPU and are unaffected.

## Validation record

### Performed

- The Windows app target built with Qt 6.9.3 and MSVC Build Tools on every
  change, and `qmlcachegen` compiled each changed QML file — a real syntax
  check, not only a lint pass. The only link warning was the pre-existing
  `LNK4291`.
- `qmllint` on `AppView.qml`, `GameTile.qml`, `GameOptionsOverlay.qml`,
  `Bulan.qml`, `HostCarousel.qml` and `main.qml`. Only this project's four
  long-standing categories appeared: `[import]`, `[missing-property]`,
  `[unqualified]`, `[unresolved-type]`. `Bulan.qml` produced no output at all.
- **Reviewed against the real paired host `Steambox`**, on both tabs, with real
  box art delivered by `BoxArtManager` from its own cache — roughly twenty
  games at three different source aspect ratios. This is the first Bulan screen
  in this project to have been checked against real host data rather than a
  fake preset.
- Reviewed against every `MOONLIGHT_FAKE_GAMES` preset — `none`, `one`,
  `partial`, `many`, `mixed` — on both tabs. That covers an empty library, a
  single game, a partially filled final row, more than one screen of scrolling,
  a 45-character title, and a running game.
- The options popup and the quit-and-switch confirmation captured and read.
- Application logs read on every run. Only two lines ever appear, both
  environmental: the `ToolTip attached property` warning from `main.qml` that
  this project has always had, and `mDNS is disabled by user preference`, which
  is a local preference on the review station.
- **A model update while the screen was live** was exercised without meaning to
  be: a host's app list arrives in chunks, and that is what surfaced the scroll
  defect below.

### The scroll defect, found and diagnosed

The Library grid was seen **scrolled down one row with no input and no focus
ring on screen**, once, during stage 2. Two immediate re-runs were correct, so
it was recorded as unreproduced and explicitly **not** claimed fixed.

It became reproducible in stage 4, once the Library tab could be opened
directly against the real host. A host's app list arrives in chunks; each
arrival recomputed the scroll — while the Library was not the visible tab and
while the content height was still growing. The viewport test ran against a
grid a fraction of its eventual size, scrolled there, and nothing recomputed it
afterwards. It looked intermittent because it depended on how the host happened
to chunk its list on that run.

Fixed, and verified across three consecutive runs against the real host. The
transferable lesson is in `SPEC-game-grid.md`.

### Not performed

- **No Steam Deck validation, in either Desktop Mode or Game Mode.** Everything
  above happened on the Windows review station, which `BUILDING-WINDOWS.md` is
  explicit is not a product target.
- **No LCD or OLED appearance check.** Tile sizes, the 2:3 ratio and the Recent
  composition were judged on a scaled desktop panel, not a 7-inch one at
  204 ppi. The previous task had to change a value for exactly this reason.
- **No hardware-gamepad review, by anyone.** Every controller path here —
  the D-pad in both views, A, X, B, L1/R1, START — has been built and reasoned
  about and checked in code. None of it has been driven with a physical
  controller. **This is the single largest gap in this record**, and the newly
  mapped shoulder buttons are the part of it least supported by precedent.
- **No stream has been started or stopped through this screen.** Launch,
  resume, Quit Game and quit-and-switch all push existing upstream components,
  and none of those paths has been exercised end to end against a live game.
- **The motion has never been watched.** Stills cannot show it. Every animation
  was built against the brief's rules and read back in the source; that is not
  the same as seeing whether it feels right.
- **Hide Game and Direct Launch have never been triggered against a real host.**
  They are wired to the existing model calls and were only exercised in review
  mode, which refuses them by design.

## Required reading before continuation

1. `AGENTS.md`
2. Git branch, HEAD, tracking branch, remotes, working tree, and relevant log
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `BUGS.md`
8. `SPEC-host-carousel.md` and `SPEC-game-grid.md`
9. The active task brief, `TASK-BRIEF.md`
10. The applicable `BUILDING-*.md` before a build
