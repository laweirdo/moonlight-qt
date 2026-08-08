---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 54f46db7
---

# Bulan — current state

**Verified 8 August 2026.** State is `54f46db7` plus one uncommitted,
client-approved change on branch `fix-deck-osk`. Inspect Git before relying
on this — it is a snapshot, not an authority on what Git says.

Replaced, never appended to. Past states are in Git history, past evidence in
`docs/validation/`, past build narrative in
`docs/history/private-v1-build-record.md`.

## Repository

| Item | State |
|---|---|
| Branch | `fix-deck-osk`, cut from `bulan` at `54f46db7` |
| Remote | `origin` only. Not pushed, not merged, no push authorized |
| Working tree | Uncommitted: `app/gui/HostPanel.qml` (client-approved fix), `BUGS.md`, `ROADMAP.md`, this file, `docs/validation/2026-08-08-osk-diagnosis-and-resolution.md` |
| Task branch | `fix-deck-osk`. `TASK-BRIEF.md` present — remove on commit/merge acceptance |
| Active task | SteamOS OSK investigation — diagnosed, resolved by client decision, validated. Awaiting commit/merge instruction |

## Where the product is

**Phase F — ship private v1.** `ROADMAP.md` owns the phase and exit criteria.

**SteamOS on-screen keyboard blocker resolved, 8 August 2026.** Full
diagnosis and validation in
`docs/validation/2026-08-08-osk-diagnosis-and-resolution.md`. Short version:
Bulan's field never requested the input panel (fixed in `HostPanel.qml`);
separately, gamescope gates automatic OSK invocation against non-Steam-game
windows regardless of correct app behaviour (a platform limit, not a Bulan
defect). Client's accepted resolution: **Steam+X** remains the supported way
to bring up the keyboard. Validated end to end on both `HostPanel` entry
points, controller-only, no focus regression.

This session's checkout was found empty at start and re-cloned from
`https://github.com/laweirdo/moonlight-qt.git`; the Flatpak recipe was also
missing and recreated — see `BUILDING-DECK.md` (recipe now needs five patch
removals, not three, plus a `rename-icon` correction).

## Validation status

**Passed:** static checks and builds at every accepted merge; the Windows
review route; the 5 August 2026 Deck checklist; the 8 August 2026 OSK
resolution end to end in real Game Mode.

**Not established:** LCD-specific appearance (panel type unrecorded either
Deck session); battery draw, waiting-state timings, blur cost (blur cost
deliberately deferred by the client).

Latest reports: `docs/validation/2026-08-08-osk-diagnosis-and-resolution.md`,
`docs/validation/2026-08-05-private-v1-deck.md`.

## Open blockers

None on Phase F's mandatory exit criteria — see `ROADMAP.md`. `BUGS.md` is
empty.

## Next action

1. **Client decision needed:** commit this session's change and docs, then
   merge `fix-deck-osk` into `bulan` or otherwise direct next steps.
2. An LCD Deck session, once available, for the remaining panel-appearance
   gap.
