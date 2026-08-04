---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 173c0497
---

# Bulan — current state

**Verified 4 August 2026.** The application state described here is
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
| Push state | Documentation work through 4 August 2026 is pushed with the client's authorisation |
| Working tree | Clean |
| Task branch | None. Documentation work was committed directly to `bulan` at the client's direction |
| Active task | **None.** No `TASK-BRIEF.md` exists |

## Where the product is

**Phase F — ship private v1.** `ROADMAP.md` owns the phase, its exit criteria
and what v1 means. The accepted baseline is `173c0497`, the private v1 draft the
client reviewed live in two rounds on 3 August 2026.

**Accepted is not validated.** Nothing has run on a Steam Deck, against a
physical controller, through a real stream, or as a Flatpak.

## Validation status

**Passed:** static checks and Qt 6.9.3 / MSVC Release builds at every accepted
merge, and the whole route driven and captured on the Windows review station.

**Not passed:** everything requiring the target device. `ROADMAP.md`'s Phase F
table owns that list. Nothing has run on a Steam Deck since 28 July 2026, and
LCD appearance is deferred until that hardware exists.

Latest reports: `docs/validation/2026-08-03-private-v1-draft.md`,
`docs/validation/2026-08-02-phase-b-closeout.md`,
`docs/validation/2026-07-28-deck-oled-review.md`.

## Open blockers

- **One open defect**, client-reported and not reproduced: Settings → UI →
  Language. `BUGS.md` has it; it needs a client reproduction to go further.
- **No Steam Deck session since 28 July 2026.** Every screen built since is
  unseen on the target device.
- **The documentation work is pushed but not client-reviewed.** It changed no
  application source. `python scripts/context-audit.py` passes.

## Next action

1. **A Steam Deck session** in Desktop Mode and Game Mode, with a physical
   controller and a real host, following `REVIEW-CHECKLIST.md` — Part 4 is
   exactly this list. The critical path: one session clears most of it. Record
   the result as a new report in `docs/validation/`.
2. **A Flatpak build and clean install**, per `BUILDING-DECK.md`. Not possible
   from Windows.
3. **The Language defect**, once the client can reproduce it.

The client may revisit the screen transition later to push it further toward the
brief's "whimsical" character. A future task, not an open item.
