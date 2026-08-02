# Bulan - current handoff

Current as of **2 August 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. Always inspect Git before relying on this
snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan` at `f54d3648`, tracking `origin/bulan` |
| Task branch | `launch-quit-experience`; accepted, with its acceptance-cleanup commit at the current branch head; no tracking branch |
| Remote | `origin` only, the client's fork. Nothing from this task has been pushed |
| Active task | **None.** `TASK-BRIEF.md` was removed after final client acceptance |
| Open defects | None recorded in `BUGS.md` |

The task branch was cut from the accepted game-grid merge. The client accepted
Stage 1, then authorized the remaining stages to proceed without intermediate
stops and requested one approval after all work was complete. The client gave
that final approval on 2 August 2026 and authorized local acceptance cleanup,
merge into `bulan`, and task-branch deletion. The cleanup is complete; the
local merge is next. Push remains unauthorized.

## What was built

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

## Validation record

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

These are honest validation gaps, not acknowledged product defects. `BUGS.md`
therefore remains empty.

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

Merge `launch-quit-experience` into `bulan`, delete the accepted local task
branch, then update this repository-state file again after those operations.
Nothing may be pushed unless the client separately authorizes the push.
