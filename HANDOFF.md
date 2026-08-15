---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: stage-4-trays-review
---

# Bulan - current state

**Verified 15 August 2026.** Inspect Git before relying on this snapshot.

## Repository

| Item | State |
|---|---|
| Branch | `codex/rework-core-shell`, cut from clean `master` at `177a58bd` |
| Last commit | Accepted Stage 4 reflection trays - this commit |
| Remote | `origin` only - `laweirdo/bulan-qt`; no push authorized |
| Working tree | Clean after this commit |
| Active task | `TASK-BRIEF.md` - core shell vertical slice |

## Stage 4 accepted state

- A shared reflection-tray frame keeps Home mounted and dimmed underneath,
  replaces the action bar while open, animates once, and restores Home focus on
  close.
- The PC tray selects hosts by UUID across model reorder and offers Choose,
  Wake, Retry, Add PC and Details. Add, unpaired hosts and Details use the
  existing PC-management compatibility route; Settings uses its existing route.
- The game tray snapshots app ID and current state for Play/Resume, Quit, Hide
  or Show, and Set/Clear direct launch. Every mutation re-resolves app ID first.
  Hiding closes the tray and records the nearest remaining title.
- `AppModel` now exposes the specified app-ID resolver and direct-launch app ID;
  the latter returns `0` when no app is configured.
- Startup host resolution now decides focus after resolving the remembered host,
  so an automatically opened no-host tray cannot lose controller focus to Home.
- Session creation and quit choreography remain intentionally deferred to
  Stage 5; the shell emits stable-ID Play and Quit intentions for that owner.

## Validation

- QML tests: 23 passed, including host-UUID preservation across reorder,
  game-menu app-ID preservation, and menu state carried by Home snapshots.
- `qmllint` exited 0 with no errors. Its warnings remain the known standalone
  metadata gaps for C++-registered modules and the `Bulan` singleton.
- Windows Qt 6.9.3 Release build passed; only the existing `LNK4291` warning
  remained.
- The freshly built portable binary exited 0 through the built-in screenshot
  hook and logged no new QML errors. A fresh approval-gate Release rebuild,
  including the `AppModel` APIs, passed on 15 August.
- A temporary external review fixture rendered both production tray components
  at 1280x800. It was removed after capture; no fake-data or capture branch was
  added to production. PC tray: `bulan-stage4-pc-tray.png`; game tray:
  `bulan-stage4-game-menu.png` in the local temp directory.
- New Bulan surfaces contain no stock Qt Quick Controls, fake-data branches or
  screenshot capture. `git diff --check` passed.
- Computer Use could not initialize after its prescribed retry (`EPERM` on the
  Codex app directory), so it did not perform input automation.
- Steam Deck, a physical controller pass and CI were not run at this review
  checkpoint.

## Next action

Begin the connection overlay and nonvisual session flow. Preserve the mounted
Home state and do not create a replacement session until cleanup is complete.
