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

This file is replaced, never appended to. Past states are in Git history, past
evidence in `docs/validation/`, past build narrative in
`docs/history/private-v1-build-record.md`.

## Repository

| Item | State |
|---|---|
| Branch | `bulan`, the integration branch |
| Remote | `origin` only, the client's fork |
| Push state | **`bulan` is ahead of `origin/bulan` by the documentation refactor and has NOT been pushed.** No push has been authorised. Everything up to `4c482e95` is pushed. Confirm with `git rev-list --left-right --count origin/bulan...bulan` |
| Working tree | Clean |
| Task branch | None. The refactor was committed directly to `bulan` at the client's direction |
| Active task | **None.** No `TASK-BRIEF.md` exists |

## Where the product is

**Phase F — ship private v1.** Every phase is built. The complete v1 draft —
cold launch through first run, pairing, host selection, game selection, launch,
quit and return — was reviewed live by the client in two rounds and accepted on
3 August 2026, merged as `173c0497`. No screen on that route still reads as
upstream Moonlight.

**Accepted is not validated.** Nothing has run on a Steam Deck, against a
physical controller, through a real stream, or as a Flatpak. See
`docs/validation/2026-08-03-private-v1-draft.md` for the full honest list, and
`ROADMAP.md` for what still has to be true before private v1 ships.

## Validation status

| Area | Status |
|---|---|
| Static checks and Windows builds | Passing at every accepted merge |
| Windows review-station behaviour | Driven and captured across the whole route |
| Steam Deck, Desktop and Game Mode | **Not performed** since 28 July 2026 |
| Physical controller | **Not performed** on any current screen |
| Real pairing and real stream | **Not performed** |
| Flatpak build and install | **Not attempted** — the review station is Windows |
| Steam on-screen keyboard, manual address field | **Unvalidated**, and cannot work without it |
| Transition blur cost on the Deck | **Unmeasured**, by the client's deliberate deferral |
| LCD panel appearance | **Deferred** until hardware is available |

Latest reports: `docs/validation/2026-08-03-private-v1-draft.md`,
`docs/validation/2026-08-02-phase-b-closeout.md`,
`docs/validation/2026-07-28-deck-oled-review.md`.

## Open blockers

- **One open defect**, client-reported and not reproduced: opening
  Settings → UI → Language. See `BUGS.md`. It needs a reproduction from the
  client before it can be chased further.
- **No Steam Deck hardware session has happened** since 28 July 2026, and every
  screen built since then is unseen on the target device.
- **The documentation refactor is unpushed and unreviewed by the client.** It
  changed no application source. `python scripts/context-audit.py` passes.

## Next action

1. **A Steam Deck session** in Desktop Mode and Game Mode, with a physical
   controller and a real host, following `REVIEW-CHECKLIST.md` — Part 4 is
   exactly this list. It is the critical path: one session clears most of the
   table above. Record the result as a new report in `docs/validation/`.
2. **A Flatpak build and a clean install**, per `BUILDING-DECK.md`. It cannot be
   done from Windows.
3. **The Language defect in `BUGS.md`**, once the client can reproduce it.

The client mentioned possibly revisiting the screen transition later to push it
further toward the brief's "whimsical" character. That is a future task, not an
open item.
