# Bulan — current handoff

Current as of **31 July 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `TASK-BRIEF.md` is the
single active work order; `BUGS.md` owns acknowledged unintended behavior.
Always inspect Git before relying on this snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch before this progress-documentation update | `bulan` and `origin/bulan` at `6e345967ce463a0511bae70ce9e5c08e80ca85df` |
| Progress-documentation branch | `codex/host-settings-progress-docs`, cut from that accepted integration state and approved for merge into `bulan` |
| Original task baseline | `bulan` and `origin/bulan` at `6a6ffa7ec677c3a630613c68cfd55ed5a708a082` |
| Original task branch | `codex/host-settings-menu`, fast-forwarded into `bulan` and deleted locally; its accepted commits remain reachable from `bulan` |
| Remote | `origin` only, the client's fork |
| Current worktree state | This snapshot documents the approved progress update; inspect Git before acting |

The active host-settings task is not complete. Do not delete or archive
`TASK-BRIEF.md` until the toolbar repair is implemented, validated, and its
durable decisions have moved to the appropriate authorities.

## Completed work in this session

The client approved and integrated the first two logical application changes:

| Commit | Result |
|---|---|
| `394a2870` | Changed `Bulan.hostTileLabelGap` from 56 to 46, with no other carousel visual change. |
| `1c941ed5` | Replaced SELECT's temporary details panel with the custom host-settings overlay. |
| `6e345967` | Recorded the separately scoped root-carousel B/quit-confirmation defect. |

`6e345967` is the current accepted integration commit and was pushed to
`origin/bulan` on 31 July 2026.

## Current product state

| Area | Current state |
|---|---|
| Host label gap | 46. |
| SELECT on the carousel | Opens the approved glass host-settings overlay over a blurred carousel. B closes it and restores focus to the same host. |
| Menu actions | View all apps for online paired hosts; Test Network, Host Details, and Forget PC for every host; Wake PC only for an offline wakeable host. Forget PC requires confirmation. |
| Host identity | Real actions resolve the saved UUID at activation time, not a carousel index. |
| Fake-host mode | Blocks before any real-host lookup or action and gives visible review feedback. |
| Test Network | Included in private v1 through Moonlight's existing connection-test path. |
| Rename PC | Deferred to v1.x for Steam keyboard and text-entry work. |
| Startup toolbar | Still appears during first launch frames; open defect and final stage of the active task. |
| Root-carousel B | Opens an inherited, non-Bulan quit confirmation that the client reported as non-responsive to XInput; separate open defect. |

The menu's glass border and blurred backdrop are the approved precedent for
future popup menus. `SPEC-host-carousel.md` owns the durable surface decisions.

## Validation record

### Performed

- `qmllint` completed successfully for every changed QML file. Standalone lint
  emitted the expected registered-import/singleton warnings but no syntax
  failure.
- The Windows review build completed with Qt 6.9.3. The reviewed deployed
  executable carried the 31 July 2026 build timestamp.
- The application log was inspected. It had no new host-overlay warning after
  the QML signal fix; the remaining startup tooltip warning and restricted
  network-update failures were pre-existing or environment-related.
- Fake-host captures covered `none`, `one`, `two`, `offline`, `mixed`, and
  `many`, plus online, offline-not-wakeable, offline-wakeable, confirmation,
  details, and fake-action feedback states.
- No fake-host action was allowed to reach a real machine. No destructive
  real-host action was performed.
- The client used a real XInput controller in the Windows review build and
  reported the root-carousel B defect now recorded in `BUGS.md`.

### Not performed or not yet clean

- No Steam Deck Desktop Mode or Game Mode validation was performed for the new
  overlay.
- A complete real-controller acceptance matrix for every overlay action is not
  separately recorded; do not infer it from the client approval or from the
  fake-host screenshots.
- The startup-toolbar repair was not implemented, so no first-frame launch
  capture or inherited-toolbar-screen regression pass exists for it.
- One interactive Windows launch using the default D3D11 path showed an
  application-error dialog in `d3d11.dll`. Relaunching the review build with
  `QSG_RHI_BACKEND=opengl` displayed the app. This is an unconfirmed
  review-environment issue, not an accepted product defect; reproduce it before
  treating Windows interactive review as clean.

## Open defects and active task

`BUGS.md` has two open defects:

1. The inherited toolbar is visible for about 567 ms during cold launch. It
   remains **open** and must be closed only after the repaired launch and every
   inherited toolbar screen have been verified.
2. Root-carousel B opens an inherited quit confirmation that neither uses the
   approved popup language nor reliably responds to the client's XInput
   controller. It is a follow-up task, not incidental host-menu cleanup.

The host-settings task remains active solely for its third logical change:
repair the startup toolbar without removing toolbars required by inherited
screens. `TASK-BRIEF.md` stays active until then.

## Next recommended action

After this documentation update is merged into `bulan`, start a fresh short
implementation branch from the latest accepted `bulan`.
Implement the toolbar repair with the minimum scope described in `BUGS.md` and
`TASK-BRIEF.md`, then capture from the first visible launch frame, visit every
inherited screen that retains a toolbar, inspect the log, and obtain controller
review before closing that defect.

## Required reading before continuation

1. `AGENTS.md`
2. Git branch, HEAD, tracking branch, remotes, working tree, and relevant log
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `TASK-BRIEF.md`
8. `BUGS.md`
9. `SPEC-host-carousel.md`
10. The applicable `BUILDING-*.md` before a build
