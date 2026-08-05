---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 173c0497
---

# Bulan — current state

**Verified 5 August 2026.** The application state described here is
`173c0497`, the accepted private v1 merge; every commit since is documentation
only. Inspect Git before relying on this — it is a snapshot, not an authority on
what Git says.

Replaced, never appended to. Past states are in Git history, past evidence in
`docs/validation/`, past build narrative in
`docs/history/private-v1-build-record.md`.

## Repository

| Item | State |
|---|---|
| Branch | `bulan`, the integration branch |
| Remote | `origin` only, the client's fork |
| Push state | This documentation update is accepted by the client and pushed to `origin/bulan` |
| Working tree | Clean |
| Task branch | None. `docs/deck-validation-2026-08-05` was merged into `bulan` and deleted |
| Active task | **None.** No `TASK-BRIEF.md` exists |

## Where the product is

**Phase F — ship private v1.** `ROADMAP.md` owns the phase, its exit criteria
and what v1 means. The accepted baseline is `173c0497`, the private v1 draft the
client reviewed live in two rounds on 3 August 2026.

**A Steam Deck session has now happened.** On 5 August 2026 the client manually
worked the applicable items in `REVIEW-CHECKLIST.md` on their Deck. Every
applicable check passed except one: the SteamOS on-screen keyboard does not
appear for text-entry fields, which blocks manual address entry in Game Mode.

## Validation status

**Passed:** static checks and Qt 6.9.3 / MSVC Release builds at every accepted
merge; the whole route on the Windows review station; and, as of 5 August 2026,
the applicable Deck checklist — pairing, streaming, controller navigation,
Game Mode bindings, wake, waiting state, Part 2 judgement calls — all
client-observed and passing.

**Not passed / not established:** manual address entry in Game Mode fails, the
SteamOS OSK does not appear — the primary Phase F blocker now. LCD-specific
appearance is still unvalidated (panel type not recorded this session).
Precise measurements the checklist calls for (battery draw, waiting-state
timings, blur cost) were not part of the reported result.

Latest reports: `docs/validation/2026-08-05-private-v1-deck.md`,
`docs/validation/2026-08-03-private-v1-draft.md`,
`docs/validation/2026-08-02-phase-b-closeout.md`.

## Open blockers

- **The SteamOS on-screen keyboard does not appear for Bulan text fields** —
  new, client-reported and reproduced on 5 August 2026. `BUGS.md` has it. This
  blocks the Phase F full-loop exit condition.
- None outstanding on the documentation itself. It changed no application
  source. `python scripts/context-audit.py` passes.

## Next action

1. **Investigate and fix SteamOS on-screen keyboard invocation** for Bulan's
   text field, then retest manual address entry — and any other Game Mode
   text-entry surface it may affect — on the Deck. `BUGS.md` has the
   investigation starting points.
2. **An LCD Deck session**, once that hardware is available, to close the
   remaining panel-appearance gap.

The client may revisit the screen transition later to push it further toward the
brief's "whimsical" character. A future task, not an open item.
