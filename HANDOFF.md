---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: phase-1-authority-reset
---

# Bulan — current state

**Verified 14 August 2026.** Inspect Git before relying on this snapshot.

## Repository

| Item | State |
|---|---|
| Branch | `codex/rework-core-shell`, cut from clean `master` at `177a58bd` |
| Remote | `origin` only — `laweirdo/bulan-qt`; no push authorized |
| Working tree | Stage 1 is recorded by the commit containing this snapshot |
| Active task | `TASK-BRIEF.md` — core shell vertical slice |

## Current stage

Stage 1, repository-authority reset, was approved on 14 August 2026:

- The retired game-grid and host-carousel specifications and the previous full
  creative brief are preserved under
  `docs/history/2026-08-14-pre-clean-slate/`.
- `FLOW.md`, `DESIGN-SYSTEM.md`, `ROADMAP.md` and
  `bulan-creative-brief.md` now describe the accepted clean-slate direction.
- References to the archived specifications were reconciled across the
  Markdown tree.
- No application source has changed yet.

## Validation

`python scripts/context-audit.py` passed after the authority reset. No build,
QML lint, desktop review or hardware review applies to this documentation-only
stage and none has been claimed.

## Next action

Begin stage 2: Fraunces Semibold, minimal tokens and the shell foundation.
