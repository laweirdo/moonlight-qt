# Bulan - current handoff

Current as of **2 August 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. Always inspect Git before relying on this
snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan`, carrying the accepted screen transition work, pushed to `origin/bulan` |
| Task branch | `general-screen-transitions` was deleted locally after the accepted merge and never existed on `origin` |
| Remote | `origin` only, the client's fork. `bulan` has been pushed with the client's explicit authorisation |
| Active task | **None.** `TASK-BRIEF.md` was retired on client acceptance |
| Open defects | **Two**, both pre-existing, both recorded in `BUGS.md` on 2 August 2026 |
| Working tree | Clean |

The previous task, the launch and quit experience, was accepted on 2 August 2026
and merged locally as `c0e79970`; its branch is deleted. This entry supersedes
that snapshot.

Phase B item 4 was reviewed live by the client in two rounds on 2 August 2026
and accepted. The client authorised the merge and the push, then authorised the
branch deletion separately. Acceptance cleanup is complete.

## Phase B item 4 — what is on the branch

| Commit | What |
|---|---|
| `fa060c63` | Added root `CLAUDE.md`, Claude Code's orchestration rules under `AGENTS.md` |
| `09f9d576` | Opened the work order: route inventory, accepted motion direction, ownership |
| `0670b48e` | Added the push/pop transition and the launch/quit opt-out |
| `78c05eee` | Corrected the interruption comment on the mechanism |
| `435bf2f0` | Recorded state and opened two pre-existing defects in `BUGS.md` |
| `36e5e7f9` | Added real blur to the transition, on the client's override |
| `b93a8bb0` | Replaced the tiles' sideways slide with a staggered rise from below |
| `1e37e223` | Lifted the hint bar out of the screens into the window |
| `7c23b804` | Made a launch end the tile entrance rather than refuse the artwork capture |

Ordinary screen changes now move vertically. Forward, the arriving screen rises
into place from below while the one it replaces continues upward; back is the
exact mirror, so the two read as one reversible movement. 220 ms, ease-out with
no overshoot, one settle.

It is declared once, on the single navigation stack in `main.qml`, rather than
attached screen by screen — so the host carousel, the game grid, and settings
all inherit it and nothing has its own private timing. Only vertical position
and opacity are animated: no shader, no blur effect, nothing running
continuously. The creative brief's "slight motion blur" is read as opacity
falling away during travel, which costs nothing.

The launch and quit routes deliberately opt out and change without stack motion,
so nothing competes with the accepted artwork launch transition. The first
screen at startup does not animate either — there is nothing to move from.

The travel distance reuses the accepted `space3xl` (64 px) through a named
token rather than introducing a new visual value.

### Second round, after the client's 2 August review

The client saw the transition live, kept the 220 ms and the 64 px rise, and
asked for three changes. All three were built and reviewed live by the client in
a second session the same day, and accepted.

**A real blur now runs during the transition.** The client overrode the
inexpensive opacity-only reading and accepted the performance cost explicitly,
to be measured on the Deck after private v1. It is gated to the stack's own
`busy` window, so a settled screen carries no layer and no effect. It shares one
layer with the quit-dialog backdrop rather than competing for it. Note that it
blurs the whole stack including the atmosphere behind the screens, not only the
moving content — that is a visual consequence the client has not yet judged.

**The game tiles rise from below instead of sliding in from the side.** The old
horizontal slide into ranked position was what the client saw as "swiping in
from the side, way too quickly". Tiles now rise and fade in on a short cascade
that starts once the screen has arrived. Recent radiates outward from the
focused tile; the Library reads left to right, top to bottom. The cascade is
capped at six steps so a full library does not take seconds to finish arriving.

**The hint bar no longer moves with the screen.** Both screen-level bars were
lifted into the window beside the stack, where `LaunchTransition` already lives,
because a child cannot opt out of its parent's animated opacity. The carousel
and the grid now publish their hints and one window-level bar reads whichever
screen is current. Hint content, filtering, and appearance are unchanged, and
the overlay bars were not touched.

**A launch that interrupts the entrance ends it rather than degrading.** Pressing
A while tiles are still rising finishes the entrance immediately and then
captures the settled artwork, so the accepted launch treatment is preserved. The
plain title card stays reserved for a genuinely missing source, which is what it
was built for.

## What was built — Phase B item 3, launch and quit

Phase B item 3 replaces the inherited visible launch and quit screens while
preserving the existing Session, streaming, persistence, and quit backends.
`SPEC-game-grid.md` owns the durable design and lifecycle reasoning.

| Commit | What |
|---|---|
| `94d92bf4` | Corrected flow authority and defined the launch/quit work order |
| `dc0bc8a9` | Added deterministic fake-only launch and quit review routes |
| `c3625cba` | Added stable app-ID dispatch, exact artwork capture, and `LaunchTransition.qml` |
| `74a20505` | Built the custom launch/resume, warning, and failure experience |
| `b01a408e` | Built custom quit, quit failure, and success-gated quit-and-switch |
| `30f7cad4` | Hardened cross-surface routing, route lifetime, replay, and animation cost |
| `285ff231` | Declared options key-event parameters after live input exposed Qt's implicit-injection warning |
| `cd26aefa` | Recorded the final live controller-equivalent review and validation limits |
| `5d1ff48b` | Closed the accepted work order and retired its temporary task brief |
| `c0e79970` | Merged the accepted launch and quit experience into local `bulan` |

## Current product state

| Area | Current state |
|---|---|
| Selected-game launch | A in Recent or Library captures the exact visible selected artwork, hides only that source, and moves one frozen proxy into the 202×302 centred launch composition. Stable `appid` owns identity across `lastPlayed` reordering and model updates. |
| Shared entry points | A, popup Play/Resume, and automatic Direct Launch use the same source and transition contract. Missing/destroyed sources fall back to a title card instead of launching the wrong delegate. |
| Launch surface | Custom Bulan `StreamSegue`: Starting/Resuming progress, three declaratively animated dots, a timed warning, and recoverable failure with sanitized copy. The retained `AppView` remains underneath. |
| Quit surface | Custom Bulan `QuitSegue`: progress, quit-and-switch copy, and recoverable failure. Direct-A failure returns to the grid; popup-origin failure returns to Game Options. |
| Quit-and-switch | Captures the next source first, preserves the existing early Session creation and `lastPlayed` stamp, starts nothing before quit success, and transfers the one prepared Session into the shared launch path. Popup-origin switch success followed by launch failure returns to Game Options. |
| Focus and duplicate input | Busy guards reject repeated confirm. Failure dismissal is one-shot. A/B share the same visible 64 px recovery target, and retained grid focus/selection/scroll are restored by stable app ID. |
| Lifetime | Dynamically pushed review/quit routes destroy after removal. A production `StreamSegue` removed by ordinary completion or `quitStarting()` survives until Session emits `readyForDeletion`, preserving its cleanup contract. |
| Backends | Discovery, pairing, session, streaming, persistence, and quit backend source were not changed. |
| Screen transitions | Ordinary screen changes rise vertically over 220 ms and reverse on the way back, declared once on the navigation stack. Launch, quit, CLI entry, and the first screen at startup change without stack motion. Built on a task branch, **not yet accepted**. |
| Returning from the grid to the carousel | The host you left from is remembered. The selected game, tab, and Library scroll are **not** — a fresh grid is built on every entry, and memory grows each cycle. Both are pre-existing and are recorded in `BUGS.md`; the retained-grid path under launch and quit is unaffected and still works. |

## Validation record — Phase B item 3, launch and quit

### Performed

- `git diff --check`, complete diff inspection, branch/status checks, and
  scoped staged-file checks at each commit boundary.
- `qmllint` on all changed QML. It exits 0; its warning categories are
  `[import]`, `[index]`, `[missing-property]`, `[unqualified]`,
  `[unresolved-type]`, and `[use-proper-function]` around registered runtime
  types, dynamic properties/callbacks, and existing delegate patterns.
- Qt 6.9.3 / MSVC Release builds throughout implementation. The final rebuilds
  ran `qmlcachegen` over each revised QML source and linked successfully. Their
  only link warning was the pre-existing `LNK4291`.
- The full deterministic review matrix rendered successfully: launch from
  Recent, Library, and a scrolled lower Library row; resume; warning; failure;
  valid and no-source fallback; repeated cycles; quit progress/failure;
  quit-and-switch success/failure; and popup-origin switch success followed by
  launch failure. Final logs contained no critical QML/runtime error. The known
  `main.qml` `ToolTip attached property` warning appeared on every run.
- The normal launch composition, repeated-cycle return to the same retained
  grid, and popup-origin **Back to options** launch-failure target were visually
  inspected from the final captures.
- Windows `QSG_RENDER_TIMING` supporting evidence on an RTX 4070 Ti SUPER with
  Qt's basic render loop: 84 steady frames after excluding cold-start and
  screenshot frames, p95 1 ms, maximum 13 ms, zero frames over 16.67 ms. Across
  all 88 captured frames, p95 was 12 ms and maximum 31 ms; the two over-budget
  frames were startup/screenshot boundary work.
- A roughly 51-cycle repeated-launch run showed no upward memory accumulation:
  the first five warm working-set samples averaged 168.4 MiB and the last five
  162.3 MiB (observed range 158–177.1 MiB; the final screenshot was the high).
- Two independent read-only audits covered source/proxy ownership, replay,
  repeated route cleanup, quit-switch prepared Sessions, return routing,
  Session cleanup, focus recovery, and progress animation cost. All concrete
  findings were fixed; the lifecycle fixes were independently re-audited, then
  rebuilt and rerun through the three affected routes.
- A final read-only audit across all six Stage 6 documents corrected the two
  remaining stale grid-era claims: conditional B handling during busy work and
  the launch transition's legitimate use of `motionTransitionMs`. No other
  documentation contradiction or validation overclaim was found.
- A live Windows Computer Use pass exercised controller-equivalent keys on the
  rendered fake-game route. B returned from launch failure to the same grid;
  Right moved Recent focus from Portal 2 to Celeste; X opened Celeste's options;
  and B closed them with Celeste still selected. The first pass exposed Qt's
  deprecated implicit `event` injection warning in `GameOptionsOverlay`; all
  nine key handlers were corrected, linted, rebuilt, and rerun. The final log
  contained no critical runtime error and only the known `main.qml` ToolTip
  warning.

### Not performed

- **No Steam Deck validation**, in Desktop Mode or Game Mode. The Windows frame
  trace is supporting evidence only; it does not satisfy the 60 fps target-device
  criterion.
- **No OLED or LCD appearance review** of these new surfaces.
- **No real stream was launched, resumed, failed, or quit** through this task's
  paths. The real Session and quit backend contracts were preserved and audited,
  but fake QML outcomes cannot prove network or host behavior.
- **No physical-controller review** of the affected paths. Computer Use proves
  controller-equivalent key delivery and visible focus recovery on Windows,
  but it is not a gamepad, Steam Input, or target-device result.
- **No live human judgement of the transition in flight.** Timing traces and
  settled captures establish cost and end states, not feel.

These are honest validation gaps, not acknowledged product defects.

## Validation record — Phase B item 4, screen transitions

### Performed

- `git diff --check` clean, and the complete diff from `7da2ce60` was reviewed
  directly.
- `qmllint` on all six changed QML files, all exit 0. The only new warnings are
  `[missing-property]` on the two `Bulan.*` motion tokens, the same category
  every other `Bulan.*` singleton reference in that file already produces
  because `qmllint` cannot resolve a C++-registered singleton. No new warning
  category anywhere.
- Qt 6.9.3 / MSVC Release build per `BUILDING-WINDOWS.md`. `qmlcachegen` ran
  over each of the six revised QML sources and the build linked. The only link
  warning was the pre-existing `LNK4291`.
- Deterministic review runs on the fake host and fake game routes: the carousel
  settled, the game grid settled on Recent, and the Library route via
  `MOONLIGHT_GAME_REVIEW=library`. Every capture showed screens at rest — full
  opacity, no leftover vertical offset. Logs contained no critical QML or
  runtime error; only the known `main.qml` `ToolTip attached property` warning
  and the expected `mDNS is disabled` line appeared.
- Rapid input during transitions: synthetic Escape/Enter driving the live window
  at 100–120 ms intervals, deliberately faster than the 220 ms transition, so a
  new stack operation begins while the previous one is still running. Across
  two runs of 15–20 cycles the process stayed responsive, the settled screen
  was at full opacity with no stray offset, and no new warning appeared.
- **A/B route accumulation.** A second binary was built from the pre-transition
  baseline `09f9d576` in a separate worktree, and an identical 50-cycle
  carousel↔grid script was run against both. Baseline grew ~520 MB, the
  transition build ~515 MB; handle counts moved by 10 and 11. Both remained
  responsive. The accumulation is real and pre-existing, and the transition does
  not measurably worsen it. This is why `BUGS.md` now has an entry rather than
  this task having a regression.

### Not performed

- **No Steam Deck validation**, in Desktop Mode or Game Mode.
- The client judged both rounds live on Windows and accepted them. That is a
  design acceptance on a desktop GPU, **not** a target-device result.
- **No performance measurement of the blur.** The client accepted the cost
  knowingly and deferred the Deck measurement until after private v1. Nothing
  here establishes what it costs.
- **The entrance skipped on a background tab is unobserved.** A launch completes
  both grids' entrances at once, so a tab that was not visible at the time
  arrives already settled rather than playing its cascade. Deliberate, but
  nobody has looked at it.
- **Recent↔Library tab switching by real input was never exercised** in either
  round: L1/R1 come only from a gamepad and none was attached to the review
  station.
- **No frame-timing trace of the transition itself.** The earlier
  `QSG_RENDER_TIMING` figures belong to the launch work, not to this.
- **No physical-controller review.** Rapid input was synthetic keys on Windows.
- **No Recent↔Library tab switch by real input.** L1/R1 are synthesized only
  from real gamepad shoulder buttons and no controller is attached to the review
  station, so the Library route was reached through its documented review hook
  instead. Tab retention across a round trip is therefore untested by direct
  input.
- **No OLED or LCD appearance review** of the new motion.
- The accumulation measurement is process working set, not an instrumented QML
  object count.

## Required reading before continuation

1. `AGENTS.md`
2. Git branch, HEAD, tracking branch, remotes, working tree, and relevant log
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `BUGS.md`
8. `SPEC-host-carousel.md` and `SPEC-game-grid.md`
9. `BUILDING-WINDOWS.md` or the applicable target build guide before a build

## Next action

Phase B is complete on paper. Before treating it as closed, note what is owed:

1. **The two defects in `BUGS.md` need triage.** The first is partly a product
   question — what the grid should remember per host, and for how long. The
   second, memory growing on every grid entry, matters more on a Deck than it
   did on the review station.
2. **The blur's cost on the Deck is unmeasured**, by the client's deliberate
   deferral. It is the first thing to measure when Deck hardware is next
   available.
3. **Carry the standing validation debt forward** rather than claiming it:
   no Steam Deck session, no physical controller, no real stream through the
   launch and quit paths, no OLED or LCD appearance review of the new motion.

The client mentioned possibly revisiting the screen transition later to push it
further toward the brief's "whimsical" character. That is a future task, not an
open item on this one.
