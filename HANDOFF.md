---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: stage-3-home-library
---

# Bulan — current state

**Verified 14 August 2026.** Inspect Git before relying on this snapshot.

## Repository

| Item | State |
|---|---|
| Branch | `codex/rework-core-shell`, cut from clean `master` at `177a58bd` |
| Last commit | Stage 3 home/library slice — this commit |
| Remote | `origin` only — `laweirdo/bulan-qt`; no push authorized |
| Working tree | Clean after this commit |
| Active task | `TASK-BRIEF.md` — core shell vertical slice |

## Stage 3 accepted state

- The shell resolves `StreamingPreferences.lastHostUuid`, mounts one `AppModel`
  for that stable host identity and keeps per-host mode, app ID and scroll
  context in memory.
- Home shows the remembered host's cached library without waiting for discovery.
  Continue contains five valid recent titles, newest first; with no history it
  uses the first five alphabetical games under **Your games**.
- The selected title owns the centre of the shelf. Down opens the alphabetical
  five-column library on the same route; Up from its first row returns. Selection
  follows app ID through model reorder.
- Missing and stock placeholder artwork renders as a quiet blank card; the game
  title appears only beneath it.
  Cached artwork remains available offline; missing offline covers no longer
  start network work and are invalidated for retry when the host comes online.
- Home emits stable-ID intentions for Play and Game Options plus Switch PC,
  Wake and Settings. Trays and session ownership intentionally begin in Stages
  4 and 5.

## Validation

- QML tests: 16 passed. They cover startup, recency/alphabetical ordering,
  shelf centrality, shelf-to-grid navigation, ID-preserving reorder, stable-ID
  intentions, reserved title bounds and placeholder handling. The standalone
  runner warns about resources and fonts that are registered by the real app.
- `qmllint` exited 0; its output retains the known missing lint-time metadata
  warnings for C++-registered modules and the `Bulan` singleton.
- Windows Qt 6.9.3 Release build passed. The only link warning was the existing
  `LNK4291` guard-metadata warning.
- A fresh portable fixture rendered the populated Continue shelf at 2240×1400
  on the 3840×2160 review monitor. The selected card was centred, missing-art
  cards remained intentionally blank, title bounds were clear and the action
  bar remained separated.
- The portable offline log contained no `appasset` requests after the artwork
  guard and no new QML or resource errors. Existing toolbar, mapping-download,
  compatibility-download and renderer diagnostics remain.
- `git diff --check` and the new-surface scan for stock controls, fake branches,
  screenshot capture and legacy core views passed.
- Computer Use could not capture the live grid: window discovery failed twice
  with `EPERM` on the Codex app directory. Direct key-navigation tests passed;
  visual grid review remains for the isolated harness.
- Steam Deck and CI were not run for this intermediate stage.

## Next action

Begin the shared PC and game reflection trays. Keep the accepted home mounted
underneath them and preserve every action by stable host UUID or app ID.
