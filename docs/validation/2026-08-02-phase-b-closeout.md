---
kind: validation-report
authority: historical-evidence
status: final
read_when:
  - investigating-a-past-validation-claim
history_policy: append-only
---

# Validation report — Phase B closeout, 2 August 2026

| Item | Value |
|---|---|
| Date | 2 August 2026 |
| Branch | Task branches merged into `bulan` as `c0e79970`, `5a344145`, and the transition merge |
| Commits | Launch/quit `94d92bf4`–`c0e79970`; screen transitions `09f9d576`–`7c23b804`; grid lifetime and entrance `bca4d86f`–`5a344145` |
| Hardware | Windows review station, RTX 4070 Ti SUPER, scaled desktop monitor |
| Environment | Qt 6.9.3 / MSVC Release, built per `BUILDING-WINDOWS.md` |
| Client | Reviewed live on Windows in two rounds and accepted |

This report covers the three pieces of work accepted on the same day: Phase B
item 3 (launch and quit), Phase B item 4 (screen transitions), and the
`v1-finalisation` fixes for the two carousel round-trip defects.

**No part of this was seen on a Steam Deck.** The client's acceptance is a
design acceptance on a desktop GPU, not a target-device result.

---

## Phase B item 3 — launch and quit

### Performed

- `git diff --check`, complete diff inspection, branch/status checks, and
  scoped staged-file checks at each commit boundary.
- `qmllint` on all changed QML, exit 0. Warning categories were `[import]`,
  `[index]`, `[missing-property]`, `[unqualified]`, `[unresolved-type]`, and
  `[use-proper-function]`, all around registered runtime types, dynamic
  properties, and existing delegate patterns.
- Qt 6.9.3 / MSVC Release builds throughout. The final rebuilds ran
  `qmlcachegen` over each revised QML source and linked. The only link warning
  was the pre-existing `LNK4291`.
- The full deterministic review matrix rendered: launch from Recent, Library,
  and a scrolled lower Library row; resume; warning; failure; valid and
  no-source fallback; repeated cycles; quit progress and failure;
  quit-and-switch success and failure; and popup-origin switch success followed
  by launch failure. Logs contained no critical QML or runtime error. The known
  `main.qml` `ToolTip attached property` warning appeared on every run.
- The launch composition, repeated-cycle return to the same retained grid, and
  the popup-origin **Back to options** failure target were visually inspected
  from the final captures.
- `QSG_RENDER_TIMING` with Qt's basic render loop: 84 steady frames after
  excluding cold-start and screenshot frames — p95 1 ms, maximum 13 ms, zero
  frames over 16.67 ms. Across all 88 captured frames p95 was 12 ms and maximum
  31 ms; the two over-budget frames were startup/screenshot boundary work.
- A ~51-cycle repeated-launch run showed no upward memory accumulation: first
  five warm working-set samples averaged 168.4 MiB, last five 162.3 MiB
  (observed range 158–177.1 MiB; the final screenshot was the high).
- Two independent read-only audits covered source/proxy ownership, replay,
  repeated route cleanup, quit-switch prepared Sessions, return routing, Session
  cleanup, focus recovery, and progress animation cost. All concrete findings
  were fixed; the lifecycle fixes were re-audited, rebuilt, and rerun through
  the three affected routes.
- A final read-only documentation audit corrected two stale grid-era claims:
  conditional B handling during busy work, and the launch transition's use of
  `motionTransitionMs`.
- A live Windows Computer Use pass exercised controller-equivalent keys on the
  fake-game route: B returned from launch failure to the same grid, Right moved
  Recent focus from Portal 2 to Celeste, X opened Celeste's options, and B
  closed them with Celeste still selected.

### Defects found and fixed during review

Qt's deprecated implicit `event` injection warning surfaced in
`GameOptionsOverlay` on the first Computer Use pass. All nine key handlers were
corrected, linted, rebuilt, and rerun (`285ff231`).

### Not performed

- **No Steam Deck validation**, in Desktop Mode or Game Mode. The Windows frame
  trace is supporting evidence only and does not satisfy the 60 fps
  target-device criterion.
- **No OLED or LCD appearance review** of these surfaces.
- **No real stream** was launched, resumed, failed, or quit through these paths.
  The real Session and quit backend contracts were preserved and audited, but
  fake QML outcomes cannot prove network or host behavior.
- **No physical-controller review.** Computer Use proves controller-equivalent
  key delivery and visible focus recovery on Windows; it is not a gamepad,
  Steam Input, or target-device result.
- **No live human judgement of the transition in flight.** Timing traces and
  settled captures establish cost and end states, not feel.

---

## Phase B item 4 — screen transitions

### Performed

- `git diff --check` clean; the complete diff from `7da2ce60` reviewed directly.
- `qmllint` on all six changed QML files, all exit 0. The only new warnings were
  `[missing-property]` on the two `Bulan.*` motion tokens — the category every
  `Bulan.*` reference produces, because `qmllint` cannot resolve a
  C++-registered singleton. No new warning category anywhere.
- Qt 6.9.3 / MSVC Release build. `qmlcachegen` ran over each of the six revised
  QML sources and the build linked; only the pre-existing `LNK4291`.
- Deterministic review runs on the fake host and fake game routes: the carousel
  settled, the grid settled on Recent, and the Library route ran via
  `MOONLIGHT_GAME_REVIEW=library`. Every capture showed screens at rest — full
  opacity, no leftover vertical offset. Logs contained no critical error; only
  the known `main.qml` ToolTip warning and the expected `mDNS is disabled` line.
- Rapid input during transitions: synthetic Escape/Enter at 100–120 ms
  intervals, deliberately faster than the 220 ms transition, so a new stack
  operation begins while the previous is still running. Across two runs of 15–20
  cycles the process stayed responsive, the settled screen was at full opacity
  with no stray offset, and no new warning appeared.
- **A/B route accumulation.** A second binary was built from the pre-transition
  baseline `09f9d576` in a separate worktree and an identical 50-cycle
  carousel↔grid script run against both. Baseline grew ~520 MB, the transition
  build ~515 MB; handle counts moved by 10 and 11. Both stayed responsive. The
  accumulation is real and pre-existing, and the transition does not measurably
  worsen it — which is why it became a defect entry rather than a regression.

### Not performed

- **No Steam Deck validation**, in Desktop Mode or Game Mode.
- **No performance measurement of the blur.** The client accepted its cost
  knowingly and deferred the Deck measurement until after private v1.
- **The entrance skipped on a background tab is unobserved.** A launch completes
  both grids' entrances at once, so a tab that was not visible arrives already
  settled rather than playing its cascade. Deliberate, but nobody has looked
  at it.
- **No Recent↔Library tab switch by real input.** L1/R1 are synthesized only
  from real gamepad shoulder buttons and no controller was attached, so the
  Library route was reached through its documented review hook. Tab retention
  across a round trip is untested by direct input.
- **No frame-timing trace of the transition itself.** The `QSG_RENDER_TIMING`
  figures above belong to the launch work.
- **No physical-controller review.** Rapid input was synthetic keys on Windows.
- **No OLED or LCD appearance review** of the new motion.
- The accumulation measurement is process working set, not an instrumented QML
  object count.

---

## `v1-finalisation` — grid lifetime and entrance bounce

Closed the two carousel round-trip defects: the grid forgetting its per-host
context, and memory growing on every grid entry.

### Performed

- `git diff --check` clean; the full diff from `cbf04a80` reviewed directly.
- `qmllint` on every changed QML file, exit 0 throughout. Compared against the
  same files on `bulan`: exactly three new warnings, all in categories those
  files already produce, plus `[missing-property]` on the new
  `Bulan.motionEntranceOvershoot`. **No new warning category.**
- Qt 6.9.3 / MSVC Release build, linking cleanly; only the pre-existing
  `LNK4291`.
- **A/B memory measurement, same route, 50 carousel↔grid cycles each.** With the
  destroy in place the process was flat: first-five-sample average 166.1 MiB,
  last-five 164.5 MiB, a change of **−1.6 MiB**, handles steady at 1195–1208. A
  binary differing only by removal of that one `destroy()` grew from 191.6 MiB
  to 674.6 MiB, **+483.0 MiB** — about 9.7 MiB per cycle, still climbing at
  cycle 50 with handles flat. That reproduces the recorded ~10.8 MB per cycle
  and identifies the mechanism directly.
- **Per-host restore verified on screen.** Leaving the grid on Celeste and
  reopening the same host reopened on Celeste, with the full library loaded
  around it.
- **Input authority verified on screen.** Pressing Right 120 ms after
  re-entering, while the app list was still arriving, moved to Outer Wilds and
  the restore did not pull it back.
- Rapid interruption: 50 cycles at 750 ms and a further 15 on the new easing,
  faster than both the transition and the entrance. The process stayed
  responsive, the settled screen showed no stray offset or opacity, and the log
  contained no critical error.
- The fake-host review route was added so this cycle is reachable without a real
  paired host. It does not weaken `actConfirm()`'s fake-host guard: `AppView`
  with `fakeGames` active returns from `createModel()` before reading
  `computerIndex` at all. Verified by reading every `computerIndex` reference in
  the file.

### Not performed

- **No Steam Deck validation**, in Desktop Mode or Game Mode.
- **No physical-controller review.** Input was `WM_KEYDOWN` posted to the
  window. `SendKeys` is unusable here: this environment refuses a background
  process the foreground, so scripted keys land in whatever window is in front.
- **No Recent↔Library tab switch by input**, and therefore no restore of the
  Library tab or its scroll by input. L1/R1 reach QML only from a real gamepad
  shoulder button (`Key_Context2`/`Key_Context3`), which cannot be synthesised
  as a virtual keycode. The Library branch of the restore is built and reviewed
  by reading, **not observed running**.
- **No second-host check.** The only other fake host is unpaired, so pressing A
  on it pairs rather than opening a grid. That per-host contexts do not leak
  into each other is argued from the UUID key, not observed.
- **No human judgement of the new overshoot and bounce in flight.** The settled
  result was captured and is correct; the bounce is about three pixels over
  180 ms and no captured frame proves how it feels. **This needs a person on
  hardware.**
- **No real stream** was launched, resumed, failed, or quit through these paths.
- **No OLED or LCD appearance review** of the new motion.
