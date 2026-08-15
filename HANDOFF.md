---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: bb291747
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

15 August 2026, on the polish branch, in order: the frame rate was measured
before anything changed; the busy-dots animation was unified and two broken
copies removed; entrances now start from the transition instead of a timer and
can be settled by input; Rename PC was ported into the host settings overlay;
the inherited Moonlight shell — toolbar, `SettingsView.qml`, `PcView.qml` and
every stock control only they kept alive — was deleted; the hint bar became one
bar owned by the window; line weights got tokens and `HostPanel` finished the
glass migration; the focus bloom became one component instead of four; the
overdraw the measurement could justify was cut; and the last eight stock Dialogs
became Bulan panels. **No stock visual control remains in a Bulan surface.**

**Only the redraw is left, gated on mockups the client has not seen.**
`TASK-BRIEF.md` carries what the client owes.

## Validation status

**Passed, on the Windows review station:** Qt 6.9.3 / MSVC Release build;
`qmllint` exit 0 on every QML file, warning categories unchanged from the
documented baseline; the carousel, game grid, settings shell, discovery and
first-run screens each booted directly and rendered with zero QML errors; the
host settings menu showing Rename PC; a settings popup showing its own hints
rather than the shell's.

One regression was introduced and fixed within the session: both overlays sized
their surface against the hint bar they used to draw, and that binding failed
once the bar was removed. Caught by reading the log, not the build.

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
