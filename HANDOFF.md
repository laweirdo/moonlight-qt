# Bulan - current handoff

Current as of **2 August 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. Always inspect Git before relying on this
snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan` at `5a344145`, carrying the accepted navigation-lifetime and entrance-bounce work. **Five commits ahead of `origin/bulan` and NOT pushed** — no push has been authorised |
| Task branch | **`v1-review-build`**, cut from `bulan` at `5a344145`. Local only, never pushed, **not merged** |
| Remote | `origin` only, the client's fork |
| Active task | **`TASK-BRIEF.md`, private v1 finalisation.** Every implementation stage is built. What remains is a client review and target-device validation |
| Open defects | **None recorded.** See the honest gaps below |
| Working tree | Clean |

## `v1-review-build` — what is on the branch

| Commit | What |
|---|---|
| `4d22966c` | The vertical logo lockup, composed from the client's two supplied sources |
| `01bb43ab` | The first-run route: splash, find, discovery, pairing |
| `2f91a306` | The Bulan settings shell and About, replacing the upstream screen |
| `2f88565c` | The Bulan app icon and a desktop entry that reads *Bulan* |
| `97fcc481` | Reconciled the documents against what was built |
| `a0384d62` | The remaining edge states, and SELECT's destination on the grid |

## The v1 draft is complete

The route a first-time user takes is built end to end and no screen along it
still reads as upstream Moonlight:

launch → splash → *Let's find your PC* → *Looking for your PC* → pair →
host carousel → game grid → launch → stream → quit → back to the grid.

Settings and About are Bulan screens reachable by START from anywhere. The
reachable edge states are drawn: no hosts, unreachable host, empty library,
couldn't start stream, quit confirmation, and the wake states. SELECT reaches
host settings from both the carousel and the grid. The application entry
carries the Bulan icon and name.

**This is a draft, not an accepted release.** None of it has been seen by the
client, and none of it has run on a Steam Deck.

**The client's design boards were finally readable.** Every earlier session had
them attached and could not open them: this machine had no PDF rendering at
all, so the reads returned a file size and no image. Poppler was installed on
3 August 2026 and all eight boards were rendered and used. The first-run and
settings screens are built to those boards rather than inferred, which changed
them substantially — the amber *Look* button, the focused row's left bar, the
four separate PIN tiles, the two settings popups and the host-selector row were
none of them things inference had produced.

**A reported input defect did not exist.** A press was said to be lost after
the splash handed off. The measurement behind it sent one press while the
splash was still up — its hold does not begin until QML has loaded, about a
second after launch — and the splash consumed it exactly as its skip behaviour
intends. Retested with two presses 400 ms apart, the second landing 400 ms
after the stack swap: it was acted on. The speculative `requestActivate()`
mitigation added for it was removed.

**Three real defects were found in review of the settings work and fixed**
rather than reported: the category rail overflowed its pane so About fell off
the bottom of the screen entirely and Advanced collided with the hint bar; the
choice popup opened at the top of its list while the selection sat on the last
row, so the current value opened half cut off; and unfocused option rows had no
outline at all. Eighteen key handlers across the new screens took the `event`
parameter implicitly — the deprecation this project had already corrected once
— and all now declare it.

## `bulan` — the accepted work merged on 2 August 2026

| Commit | What |
|---|---|
| `bca4d86f` | Opened the work order: client decisions, motion rule, stage table, scope exclusions |
| `783bca16` | Destroyed discarded grids and gave each host its remembered place back |
| `7f10fe06` | Landed the grid entrance with an overshoot and one soft bounce |
| `b813bd0e` | Closed both defects and reconciled the private v1 scope correction |
| `5a344145` | Merge, accepted by the client as the Phase B closeout |

**The two `BUGS.md` defects are fixed.** A discarded `AppView` now publishes
what it was showing and destroys itself, following the treatment `StreamSegue`
and `QuitSegue` already use. `HostCarousel` keeps that context in memory keyed
by host UUID for the app session, and the next grid opened for the same host
restores the tab, the selected game by stable app id, and the Library scroll.

The retained-grid contract is untouched. A launch or quit pushes its segue on
top of the grid without popping it, and `StackView.onRemoved` fires only when
the item itself leaves the stack.

**The restore re-applies on every model change rather than stopping at its
first success.** `recentFocusedIndex` is a rank in `recentOrder`, and each
arriving chunk of the host's app list recomputes that order — so a rank
restored early points at a different game once the list finishes arriving. This
was observed, not theorised: the first implementation restored correctly at
four games loaded and was showing the wrong game by twenty-two. The player's
first press retires the restore outright, so a late chunk can never override
someone already moving.

**The grid entrance now overshoots and settles with one bounce.** Both cascades
moved from `Easing.OutCubic` to `Easing.OutBack`, which crosses its target
exactly once. The overshoot is its own token, `motionEntranceOvershoot`, rather
than a reuse of `motionOvershoot` — that value is tuned for a 4% focus scale
change and moves this 32px rise by about a pixel. Opacity is clamped in both
grids so only the travel bounces. Direction, stagger order, the six-step cap,
interruption behaviour and the launch-artwork capture contract are unchanged.

### Validation performed for stages 1 and 2

- `git diff --check` clean; the full diff from `cbf04a80` reviewed directly.
- `qmllint` on every changed QML file, exit 0 throughout. Compared against the
  same files on `bulan`: exactly three new warnings, all in categories those
  files already produce (`contextSaved` on a `createObject` result, typed
  `QObject`, matching the existing `segue.reviewCycleRequested` pattern; two
  unqualified `fakeGames` accesses matching the existing `fakeConnectHoldMs`
  pattern in the same function), plus `[missing-property]` on the new
  `Bulan.motionEntranceOvershoot`, the category every `Bulan.*` reference
  produces because `qmllint` cannot resolve a C++-registered singleton. **No new
  warning category.**
- Qt 6.9.3 / MSVC Release builds per `BUILDING-WINDOWS.md`, linking cleanly.
  The only link warning was the pre-existing `LNK4291`.
- **A/B memory measurement, same route, 50 carousel↔grid cycles each.** With the
  destroy in place the process was flat: first-five-sample average 166.1 MiB,
  last-five 164.5 MiB, a change of **−1.6 MiB**, handles steady at 1195–1208.
  A binary differing only by the removal of that one `destroy()` grew from
  191.6 MiB to 674.6 MiB, **+483.0 MiB**, about 9.7 MiB per cycle, still
  climbing at cycle 50 with handles flat. That reproduces `BUGS.md`'s recorded
  ~10.8 MB per cycle and identifies the mechanism directly.
- **Per-host restore verified on screen.** Leaving the grid on Celeste and
  reopening the same host reopened on Celeste, with the full library loaded
  around it.
- **Input authority verified on screen.** Pressing Right 120 ms after
  re-entering — while the app list was still arriving — moved to Outer Wilds
  and the restore did not pull it back.
- Rapid interruption: 50 cycles at 750 ms and a further 15 on the new easing,
  faster than the transition and the entrance. The process stayed responsive,
  the settled screen showed no stray offset or opacity, and the log contained
  no critical QML or runtime error.
- The fake-host review route was added so this cycle is reachable without a real
  paired host. It does not weaken `actConfirm()`'s fake-host guard: that guard
  exists because the branches below it index the real host list at a fake row's
  position, and `AppView` with `fakeGames` active returns from `createModel()`
  before reading `computerIndex` at all. Verified by reading every
  `computerIndex` reference in the file.

### Not performed for stages 1 and 2

- **No Steam Deck validation**, in Desktop Mode or Game Mode.
- **No physical-controller review.** Input was `WM_KEYDOWN` posted to the window.
  `SendKeys` is unusable here — this environment refuses a background process
  the foreground, so scripted keys land in whatever window is in front.
- **No Recent↔Library tab switch by input, and therefore no restore of the
  Library tab or its scroll by input.** L1/R1 reach QML only from a real gamepad
  shoulder button (`Key_Context2`/`Key_Context3`), which cannot be synthesised
  as a virtual keycode, and no controller is attached. The Library branch of the
  restore is built and reviewed by reading, **not observed running.**
- **No second-host check.** The only other fake host is unpaired, so pressing A
  on it pairs rather than opening a grid. That per-host contexts do not leak
  into each other is argued from the UUID key, not observed.
- **No human judgement of the new overshoot and bounce in flight.** The settled
  result was captured and is correct; the bounce is about three pixels over
  180 ms and no captured frame proves how it feels. **This needs a person on
  hardware.**
- **No real stream** was launched, resumed, failed or quit through these paths.
- **No OLED or LCD appearance review** of the new motion.

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
| Returning from the grid to the carousel | The host you left from is remembered, and so are the tab, the selected game and the Library scroll, per host, for the app session. A fresh grid is still built on every entry, but the discarded one now destroys itself, so repeated cycles no longer accumulate. Fixed on `v1-finalisation`; the retained-grid path under launch and quit is unaffected. |

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

## Validation performed for the first-run, settings and packaging work

- `git diff --check` clean throughout; every diff reviewed directly.
- `qmllint` on every new and changed QML file, exit 0 throughout, with no new
  warning category beyond the `[import]`/`[missing-property]`/`[unqualified]`/
  `[unresolved-type]` noise these files already produce because `qmllint`
  cannot resolve C++-registered singletons.
- Qt 6.9.3 / MSVC Release builds throughout, linking cleanly. The only link
  warning was the pre-existing `LNK4291`.
- **The whole first-run route was driven and captured**: splash → *Let's find
  your PC* → *Looking for your PC* with two hosts listed → *Almost there* with
  the PIN in four tiles, and B back out through all of it. Each capture was
  compared against the client's board.
- **Settings was driven and captured**: the shell with all eight categories,
  About, the resolution list popup and the bitrate slider popup.
- The application log was read after each run. It contains no `Critical`, no
  `TypeError`, and none of the QML reference errors. Two `TypeError`s that the
  splash's stack swap introduced in `main.qml`'s toolbar labels were found this
  way and fixed.
- The app icon was rendered at 256, 64 and 32 px and the SVG was validated as
  XML after editing.
- Input is delivered by posting `WM_KEYDOWN` to the window. `SendKeys` is
  useless here: this environment refuses a background process the foreground,
  so scripted keys land in whatever window is in front.

## Not performed — do not report any of these as passed

- **No Steam Deck validation**, in Desktop Mode or Game Mode. Nothing about
  these screens has been seen on the target device.
- **No physical controller.** All navigation was controller-equivalent keys.
  L1/R1 still cannot be synthesised at all, so the Recent↔Library tab switch
  and the Library-tab half of the grid context restore remain unexercised by
  input.
- **No Flatpak build or installation.** This machine is Windows.
- **Steam Game Mode on-screen keyboard is UNVALIDATED** for the manual address
  field. It is the one part of the first-run route that cannot work without the
  OSK, and it has never been tried.
- **No real pairing against a live host.** Only the fake-host branch and the
  already-paired branch were exercised. `pairingCompleted` success routing is
  built and reviewed by reading, not observed.
- **No real stream** launched, resumed, failed or quit through any of this.
- **No human judgement of any of it in flight** — the entrance bounce, the
  first-run stagger, the popups. Settled captures establish end states, not
  feel.
- **No OLED or LCD appearance review.**
- **The blur's cost on the Deck is still unmeasured**, by the client's
  deliberate deferral.

## Next action

1. **A client review of `v1-review-build`.** Nothing on it has been seen. It is
   built to the boards and it runs clean, but "runs clean on a Windows review
   station" is not the same as accepted. Reviewing before a Deck session is
   worth it: a change of direction is cheaper to act on now than after the
   hardware pass.
2. **A Steam Deck session**, in Desktop Mode and Game Mode, with a physical
   controller and a real host. That single session clears most of the
   unperformed list above: real pairing, real streaming, the Steam on-screen
   keyboard on the manual-address field, the L1/R1 tab switch and the Library
   half of the grid context restore, how the motion actually feels, OLED
   appearance, and the transition blur's cost.
3. **A Flatpak build and a clean install**, which cannot be done from Windows.

Nothing has been pushed. `bulan` is five commits ahead of `origin/bulan` and
`v1-review-build` is seven ahead of `bulan`, both local only, awaiting the
client's authorisation.

The client mentioned possibly revisiting the screen transition later to push it
further toward the brief's "whimsical" character. That is a future task, not an
open item on this one.
