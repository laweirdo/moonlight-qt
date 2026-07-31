# Bulan — current handoff

Current as of **31 July 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `TASK-BRIEF.md` is the
single active work order; `BUGS.md` owns acknowledged unintended behavior.
Always inspect Git before relying on this snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch before this work | `bulan` and `origin/bulan` at `9122299e92d015c7c6b77cc02ca774bb1e8c2185` |
| Accepted task change | `ff42d3d1`, startup-toolbar repair merged into `bulan` and `origin/bulan`; task branch deleted after merge |
| Original task baseline | `bulan` and `origin/bulan` at `6a6ffa7ec677c3a630613c68cfd55ed5a708a082` |
| Original task branch | `codex/host-settings-menu`, fast-forwarded into `bulan` and deleted locally; its accepted commits remain reachable from `bulan` |
| Remote | `origin` only, the client's fork |
| Current worktree state | Clean `bulan` worktree after the accepted merge |

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
| Startup toolbar | First-frame capture shows no upstream header; defect remains open pending inherited-screen and controller validation. |
| Root-carousel B | Opens an inherited, non-Bulan quit confirmation that the client reported as non-responsive to XInput; separate open defect. |

The menu's glass border and blurred backdrop are the approved precedent for
future popup menus. `SPEC-host-carousel.md` owns the durable surface decisions.

The startup-toolbar repair is implemented in `ff42d3d1` on `bulan`. The
first-frame capture now passes; the defect remains open pending the inherited
screen regression and controller validation.

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
- Commit `ff42d3d1` starts the inherited toolbar hidden in
  `app/gui/main.qml` and explicitly restores it in `AppView.qml`,
  `SettingsView.qml`, and `PcView.qml`.
- `qmllint` exited 0 for the four changed QML files. It emitted the expected
  standalone registered-import and unqualified-access warnings, with no
  syntax errors.
- The Windows review executable was rebuilt with Qt 6.9.3 and carried build
  stamp `2026-07-31T21:08:22`. Settled startup captures showed the Bulan
  carousel without the upstream header for fake-host presets `none`, `one`,
  `two`, `offline`, `mixed`, and `many`.
- The latest review log contained no QML load error. It retained the existing
  tooltip warning and restricted-network update warnings.
- A first-frame validation capture is saved at `build\first-frame.png`. It was
  taken from an exact copy of the checkout-built executable,
  `build\deploy-x64-release\BulanReview.exe`, with only the debug capture timer
  shortened for that run. The normal timer was restored before the final build.
  The frame shows the Bulan carousel and hint bar with no upstream header.
- The final deployed checkout executable,
  `build\deploy-x64-release\Moonlight.exe`, was rebuilt afterward with build
  stamp `2026-07-31T21:08:22`; its settled startup capture is
  `build\final-startup.png`.
- The installed upstream executable was not used as review evidence. The
  Windows app launcher resolved it when given the generic Moonlight identity,
  so that process was stopped and subsequent review used the checkout path
  explicitly.

### Not performed or not yet clean

- No Steam Deck Desktop Mode or Game Mode validation was performed for the new
  overlay.
- A complete real-controller acceptance matrix for every overlay action is not
  separately recorded; do not infer it from the client approval or from the
  fake-host screenshots.
- Controller navigation for the startup-toolbar stage and a complete
  inherited-toolbar-screen regression pass were not performed. A standalone
  `PcView.qml`/`AppView.qml` debug launch entered unrelated fake-stream/error
  paths, so those results were excluded rather than treated as acceptance.
- One interactive Windows launch using the default D3D11 path showed an
  application-error dialog in `d3d11.dll`. Relaunching the review build with
  `QSG_RHI_BACKEND=opengl` displayed the app. This is an unconfirmed
  review-environment issue, not an accepted product defect; reproduce it before
  treating Windows interactive review as clean.

## Open defects and active task

`BUGS.md` has two open defects:

1. The inherited toolbar was visible for about 567 ms during cold launch. The
   repair is implemented in `ff42d3d1` on `bulan`, and the first-frame check
   passes. The defect remains **open** until the inherited-screen and
   controller checks are complete.
2. Root-carousel B opens an inherited quit confirmation that neither uses the
   approved popup language nor reliably responds to the client's XInput
   controller. It is a follow-up task, not incidental host-menu cleanup.

The host-settings task remains active solely for its third logical change:
repair the startup toolbar without removing toolbars required by inherited
screens. `TASK-BRIEF.md` stays active until then.

## Next recommended action

Visit every inherited screen that retains a toolbar, inspect the log, and
obtain controller review before closing that defect.

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
