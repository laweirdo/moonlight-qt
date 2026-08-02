# Task brief — private v1 finalisation

**Opened:** 2 August 2026
**Branch:** `v1-finalisation`, cut from `bulan` at `cbf04a80`
**Owner:** one implementation agent at a time; Opus integrates and reviews.

This brief is temporary. It narrows the work; it does not override `AGENTS.md`,
`bulan-creative-brief.md`, `FLOW.md`, or `ROADMAP.md`.

## Objective

Take the repository from the accepted Phase B state to a review-ready private
v1: a complete, controller-first route from cold launch through pairing, host
selection, game selection, real streaming and return, with no reachable screen
that still reads as upstream Moonlight.

## Client decisions accepted for this task

These were given directly by the client on 2 August 2026 and settle questions
that were previously open or contradicted by the documents.

1. **Steam library artwork is not a Bulan deliverable.** Game artwork comes from
   the host PC. Documentation requiring Bulan to supply capsule, hero, or other
   Steam artwork is stale and must be removed. `ROADMAP.md` Phase F and
   `bulan-creative-brief.md` §10 item 3 both carry that stale requirement.
2. **The Bulan app icon remains required** for the application and non-Steam
   entry.
3. **SELECT on the game grid opens the existing host-settings surface**, with
   the matching hint. This closes the "second Phase B gap" recorded in
   `ROADMAP.md`, which was awaiting a client decision.
4. **The grid must remember per-host context during the app session** — active
   tab, selected game, Library scroll — closing the first `BUGS.md` defect's
   product question.
5. **Onboarding, error and settings screens are inferred**, not mocked up
   individually. Deliberate evolution is recorded rather than requested.
6. **A centred-logo vector and a final app-icon source are client assets.** If
   absent, use an isolated temporary placeholder, finish the surrounding work,
   and record the replacement as a final blocker.

## Motion rule — post-transition staggered entrance

Durable design guidance introduced by this task. It applies to every newly
introduced screen and reconciles existing screen-entry animation.

1. The screen transition happens first. Use the established vertical push/pop.
   No content entrance begins while the screen is still travelling.
2. Principal elements rise and fade in after the screen settles.
3. Stagger by visual reading order, not source order. Cap the stagger steps.
4. Entrances settle with a restrained overshoot and **one** soft bounce. Never
   two — `bulan-creative-brief.md` §6 rule 1.
5. The existing game-artwork cascade omitted the overshoot and bounce. Correct
   it while retaining its accepted direction, stagger order, interruption
   behaviour, and launch-artwork capture contract.
6. Input remains authoritative. Focus and controls are usable immediately;
   input may finish or interrupt an entrance and must never be queued or
   rejected. A launch during the artwork entrance still settles the artwork
   immediately before capture.
7. Do not stagger blindly. The window-level hint bar stays still. Modals,
   confirmations, and the launch/quit surfaces keep their established motion.
8. Centralise cadence, duration, travel and overshoot in shared tokens and
   helpers. No raw per-screen values, no near-duplicate copies.

## Stages

| Stage | Scope | Acceptance |
|---|---|---|
| 1 | Navigation lifetime: destroy discarded `AppView`s; restore per-host grid context (tab, selected game, Library scroll) for the app session | Repeated carousel↔grid cycles do not accumulate; returning to a host restores context; the retained-grid launch/quit contract is unchanged |
| 2 | Shared entrance motion tokens and helper; correct the game-artwork cascade to overshoot with one bounce | One helper, one token set; existing cascade direction, order, interruption and capture contract preserved |
| 3 | First run: splash, "Let's find your PC", searching, host selection, PIN pairing, manual-address escape hatch, Steam-keyboard-compatible entry, first-run and post-pair destinations | Controller-only route end to end on existing discovery/pairing backends |
| 4 | Edge states: zero hosts, unreachable host, empty library, couldn't start stream, disconnect confirmation, wake success/timeout/failure | Every state has a controller-safe recovery route and preserves context |
| 5 | Settings shell and About: spatial D-pad navigation, custom Bulan controls, atmosphere-effect flags, "Built on Moonlight" attribution, grid SELECT → host settings | No stock Qt Quick Controls in a Bulan screen; usable without a mouse |
| 6 | Packaging: Bulan app icon in application and Flatpak locations; clean Flatpak build path; non-Steam entry does not look unfinished | No Steam capsule/hero/library artwork created or required |
| 7 | Documentation reconciliation and honest validation record | Every relevant Markdown file checked; no stale Steam-artwork requirement remains |

## Relevant files and symbols

- `app/gui/main.qml` — the single navigation stack, push/pop transitions,
  window-level `HintBar` and `LaunchTransition`, quit confirmation.
- `app/gui/Bulan.qml` — runtime design tokens. `app/gui/BulanTokens.qml` is the
  proof-sheet review copy and must stay synchronized.
- `app/gui/HostCarousel.qml` — `openAppView()` (line ~485) creates a fresh
  `AppView` per entry; owns discovery, wake, pairing panels, host menu.
- `app/gui/AppView.qml` — the game grid. `gridEntranceStarted`,
  `markRecentEntranceSeen()`, `markLibraryEntranceSeen()`, `activeTab`,
  `libraryFocusedIndex`, `recentFocusedIndex`, `selectAppById()`,
  `ensureLibraryFocusVisible()`, `libraryFlickable.contentY`,
  `restoreAfterLaunch()`.
- `app/gui/StreamSegue.qml:229` and `app/gui/QuitSegue.qml:129` — the
  `StackView.onRemoved: destroy()` precedent to follow.
- `app/gui/SettingsView.qml`, `app/gui/PcView.qml` — inherited upstream screens.
- `app/main.cpp` — `initialView` selection and the review context properties.
- `app/qml.qrc`, `app/resources.qrc` — every new QML file and asset must be
  registered.

## Scope exclusions

- No replacement of discovery, pairing, streaming, or `Session` infrastructure
  unless a proven defect requires it.
- No wholesale settings re-architecture.
- No Bulan stream overlay; `Start+Select` remains unvalidated and deferred.
- No Steam capsule, hero, or game-library artwork.
- No sound pack, boot animation, ambient background motion, or mascot.
- No push, no merge into `bulan`, no branch deletion, no remote changes.

## Required checks

- `git diff --check`
- `qmllint` on every changed QML file
- Qt 6.9.3 / MSVC Release build per `BUILDING-WINDOWS.md`
- Deterministic review route for every new state
- Controller-equivalent key navigation
- Repeated carousel↔grid lifetime and memory measurement
- In-flight review of transition-then-stagger, overshoot and single bounce
- Rapid input and interruption during every new entrance

## Known validation limits

The review station is Windows with a desktop GPU. No Steam Deck, no physical
controller, and no real host with a game library is attached. Deck appearance,
Game Mode, physical controller, real stream, Flatpak installation, and
transition-blur cost on the Deck cannot be validated here and must be reported
as unperformed rather than passed.
