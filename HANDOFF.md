---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 7fd22e1a
---

# Bulan — current state

**Verified 15 August 2026.** Inspect Git before relying on this — it is a
snapshot, not an authority on what Git says.

Replaced, never appended to. Past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| Branches | `master` and `bulan` both at `177a58bd`. Work is on `polish-and-shell-rework`, cut from `master`, five commits ahead, **not pushed** |
| Remote | `origin` only — `laweirdo/bulan-qt`. Nothing pushed this session |
| Working tree | Clean |
| Task branch | `polish-and-shell-rework` |
| Active task | **Yes.** `TASK-BRIEF.md` — the polish audit and Bulan layer rework |
| Other branches | `codex/rework-core-shell` is excluded by client decision, 15 August 2026, and is not a source for anything |

## Where the product is

**Alpha v0.0.1.** `ROADMAP.md` owns scope and phase.

15 August 2026, on the polish branch: the frame rate was measured before
anything was changed; the busy-dots animation was unified and two broken copies
of it removed; screen entrances now start from the transition rather than a
timer and can be settled by input; Rename PC was ported into the host settings
overlay; and the inherited Moonlight shell — its toolbar, `SettingsView.qml`,
`PcView.qml` and every stock control only they kept alive — was deleted, 2931
lines against 49 added.

The remaining stages of the active task are the overdraw work, one popup
mechanism, one hint-bar owner, the `AppView.qml` split, the token cleanup, and
then mockups before any screen is redrawn.

## Validation status

**Passed, on the Windows review station:** Qt 6.9.3 / MSVC Release build;
`qmllint` exit 0 on all 36 QML files, warning categories unchanged from the
documented baseline; the carousel, game grid, settings shell and first-run screen
each booted directly and rendered with zero QML errors; the host settings menu
showing Rename PC.

**Measured, 15 August 2026:** frame pacing on the game grid — see
`docs/validation/2026-08-15-frame-pacing-baseline.md`. The reported 30 fps did
not reproduce; throughput is fine and the *pacing* is uneven, which is what the
eye reads as a low frame rate. Cause named: `QSG_RENDER_LOOP=basic`, forced on
every platform for streaming's benefit.

**Not established.** No Deck ran, so nothing was checked on hardware — the frame
pacing above, the entrance changes, the launch handoff, Game Mode, LCD
appearance. The busy-dots component compiles and lints but was never caught on
screen; the wake review hook fires against the online host. The rename panel's
own path was not seen either: review mode blocks every real host action before
it, so it needs a real paired PC. macOS and the WiX MSI were not built.

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
