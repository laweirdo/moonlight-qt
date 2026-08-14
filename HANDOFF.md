---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: phase-2-shell-foundation
---

# Bulan — current state

**Verified 14 August 2026.** Inspect Git before relying on this snapshot.

## Repository

| Item | State |
|---|---|
| Branch | `codex/rework-core-shell`, cut from clean `master` at `177a58bd` |
| Remote | `origin` only — `laweirdo/bulan-qt`; no push authorized |
| Working tree | Stage 2 is recorded by the commit containing this snapshot |
| Active task | `TASK-BRIEF.md` — core shell vertical slice |

## Current stage

Stage 1 was committed as `b2ed9cbd`. Stage 2, shell foundation, was approved on
14 August 2026:

- Normal GUI startup enters `BulanShell`; explicit CLI routes are unchanged.
- The shell owns the live `ComputerModel`, remembered host UUID and future
  host/app context slots over the retained outer `StackView`.
- A 1280×800 composition scales proportionally to the window. The startup
  wordmark ends within 600 ms or on the first key/click.
- Official Fraunces is baked at `opsz=14`, `SOFT=100`, `WONK=0`, `wght=600`,
  named as the existing `Fraunces` family and registered as a resource.
- Home/library content intentionally begins in stage 3; after arrival this
  foundation displays only the mounted atmosphere.

## Validation

- QML startup tests: 5 passed, including timeout, one-shot skip and real key
  delivery.
- `qmllint` completed with exit 0. It reports the existing lack of lint-time
  metadata for runtime-registered C++ modules and the `Bulan` singleton.
- Windows Qt 6.9.3 Release build passed; binary timestamp 14 August 2026
  21:06:25.
- Deployed runtime smoke exited 0 and produced a 2240×1400 capture with no new
  QML/resource errors. Existing toolbar, mapping-download and SDL warnings
  remain.
- The smoke used the non-portable deploy folder and generated identity/settings
  after confirming none existed. That user-profile data was not removed.
- Steam Deck and CI were not run for this intermediate stage.

## Next action

Begin stage 3: remembered-host home and library.
