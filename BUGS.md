# Bulan - open defects

**Current as of:** 2 August 2026

This file contains acknowledged, open unintended behavior only. Active product
work belongs in `TASK-BRIEF.md` when one exists; scope and sequencing belong in
`ROADMAP.md`; upstream redesign findings remain historical in `UI-AUDIT.md`.

## No open defects

Both carousel round-trip defects recorded here on 2 August 2026 — the game grid
forgetting its per-host context, and memory growing on every grid entry — were
fixed on the `v1-finalisation` branch the same day and are closed.

The fix and its evidence are in `HANDOFF.md`. The reusable lesson from it is in
`docs/retrospectives/DEBUGGING-LESSONS.md` under "A restore that succeeds and
then quietly undoes itself".

Neither has been seen on Steam Deck hardware, because no Deck session has
happened yet. That is a standing validation gap recorded in `HANDOFF.md`, not a
defect.
