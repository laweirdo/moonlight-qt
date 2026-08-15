---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: stage-5-session-flow-review
---

# Bulan - current state

**Verified 15 August 2026.** Inspect Git before relying on this snapshot.

## Repository

| Item | State |
|---|---|
| Branch | `codex/rework-core-shell`, cut from clean `master` at `177a58bd` |
| Last commit | Accepted Stage 5 session flow - this commit |
| Remote | `origin` only - `laweirdo/bulan-qt`; no push authorized |
| Working tree | Clean after this commit |
| Active task | `TASK-BRIEF.md` - core shell vertical slice |

## Stage 5 accepted state

- `BulanSessionFlow` owns initialization, generic warning presentation,
  cancellation, cleanup, retry, quit-and-switch and session return without
  changing application routes. Its states match the accepted task brief.
- `BulanConnectionOverlay` keeps Home mounted beneath it and moves a second
  `Image` from the selected tile bounds. Missing artwork remains a blank card;
  no screenshot capture or fake-data branch exists on the production route.
- Play, Quit and direct launch re-resolve app ID immediately before acting.
  Different running games require confirmation; a failed stop can be retried
  and times out after 20 seconds. Retry never creates a second session before
  the previous session reports cleanup complete.
- Cancel remains in “Stopping…” until `sessionFinished` and
  `readyForDeletion`, then reverses the artwork before restoring Home focus.
  Session return preserves the already-mounted host, mode, app ID and scroll.
- The old `StreamSegue.qml` and `QuitSegue.qml` remain for CLI and compatibility
  routes; normal `BulanShell` launch no longer uses them.

## Validation

- QML tests: 37 passed. New coverage proves early-cancel initialization order,
  cleanup-gated retry, quit-before-switch, quit retry, confirmation dismissal,
  host-loss recovery, connection actions and reverse-motion completion.
- `qmllint` exited 0 with no errors. Warnings are the known standalone C++
  module metadata and delegate-scope warnings.
- Windows Qt 6.9.3 Release build passed; only the existing `LNK4291` warning
  remained. QML cache generation compiled both new components.
- Two fresh-binary runtime smokes reached the stored one-shot direct launch and
  live decoder initialization without a new QML error. The stored launch made
  the screenshot hook inapplicable; both review processes were stopped, and no
  screenshot pass is claimed.
- Context audit and `git diff --check` passed. Static scan found no
  `grabToImage`, fake/review branch or Qt Quick Controls import in the new route.
- Steam Deck, physical controller, resize visual review and CI were not run at
  this checkpoint.

## Next action

Build the isolated review harness required by Stage 6. Production views must
remain free of fake-data and review-state branches.
