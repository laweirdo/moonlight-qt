---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 0394aa26
---

# Bulan — current state

**Verified 15 August 2026.** Inspect Git before relying on this — it is a
snapshot, not an authority on what Git says.

Replaced, never appended to. Past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| Branches | `master` at `0394aa26`, **18 ahead of `origin/master` and not pushed**. `bulan` is still at `177a58bd`, so it no longer matches `master` |
| Remote | `origin` only — `laweirdo/bulan-qt`. Nothing pushed this session |
| Working tree | Clean |
| Task branch | None. `polish-and-shell-rework` was merged fast-forward on 16 August 2026 and deleted |
| Active task | **Yes.** `TASK-BRIEF.md` — the polish audit and Bulan layer rework |
| Other branches | `codex/rework-core-shell` is excluded by client decision, 15 August 2026, and is not a source for anything |

## Where the product is

**Alpha v0.0.1.** `ROADMAP.md` owns scope and phase.

15–16 August 2026, merged to `master`: the frame rate was measured before
anything changed; busy dots, focus bloom and the hint bar each became one
implementation instead of three or four; entrances now start from the transition
and can be settled by input; Rename PC moved into the host settings overlay; the
inherited Moonlight shell — toolbar, `SettingsView.qml`, `PcView.qml` and every
stock control only they kept alive — was deleted, as were the last eight stock
Dialogs; line weights got tokens. **No stock visual control remains in a Bulan
surface.**

Then five accepted mockups: the Recent shelf anchored to the screen margin,
carousel depth, the library count and scrim, the game options card header, and
grouped settings rows. Mockups are in the client's `Bulan` design project.

## Validation status

**Passed, on the Windows review station:** Qt 6.9.3 / MSVC Release build;
`qmllint` exit 0 on every QML file, warning categories unchanged from the
documented baseline; the carousel, game grid, settings shell, discovery and
first-run screens each booted directly and rendered with zero QML errors; the
host settings menu showing Rename PC; a settings popup showing its own hints
rather than the shell's.

Two defects were introduced and fixed within the session: two overlays sized
their surface against a hint bar that had been deleted, and the startup warnings
stranded the gamepad. Neither was a build error — one needed the log read, the
other a reviewer reading call order.

**Measured:** frame pacing on the game grid —
`docs/validation/2026-08-15-frame-pacing-baseline.md`. The reported 30 fps did
not reproduce; throughput is fine and the *pacing* is uneven, which is what the
eye reads as a low frame rate. Cause named: `QSG_RENDER_LOOP=basic`, forced on
every platform for streaming's benefit. The overdraw cuts moved that number not
at all, on a GPU too idle to show it.

**Not established.** No Deck ran, so nothing was checked on hardware. Never seen
on screen, only compiled and linted: the busy dots (the wake hook fires against
the online host), the rename panel and the configuration warnings (review mode
and real startup conditions block them), and the CLI panels. macOS and the WiX
MSI were not built.

Latest reports: `docs/validation/2026-08-15-frame-pacing-baseline.md`,
`docs/validation/2026-08-08-osk-diagnosis-and-resolution.md`.

## Open blockers

None. `BUGS.md` is empty.

## Next action

1. **Continue the active task** at its next stage — see `TASK-BRIEF.md`.
2. **A Deck session.** Everything measured this session was measured on a
   desktop GPU with no vsync; the pacing finding and the overdraw question both
   need re-measuring on the target device.
3. **A real paired host** to see the rename panel and the busy dots on screen.
