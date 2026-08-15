---
kind: active-task
authority: accepted-client-task
read_when:
  - active-task
history_policy: delete-on-acceptance
---

# Polish audit and Bulan layer rework

## Objective

Make Bulan hold 60 fps, make its motion correct and interruptible, and reduce
the Bulan layer to one shell, one popup mechanism, one hint-bar model and one
motion contract — before any screen is redrawn.

## Accepted design

The client accepted the staged plan on 15 August 2026. Stages, each its own
commit, shown to the client before the next begins:

1. **Measure the frame rate.** Name the cause before changing code.
   **Done, 15 August 2026** — `docs/validation/2026-08-15-frame-pacing-baseline.md`.
   Throughput is not the problem on Windows; frame *pacing* is, and the overdraw
   hazards cost nothing measurable on that GPU. Stages reordered by the client
   on that result: motion correctness first, overdraw later.
2. **One motion contract.** Binding-vs-animation conflicts, one `BusyDots`,
   entrances driven by the transition rather than a timer, `settleEntrance()`
   everywhere, token durations and explicit easing.
3. **Delete the legacy shell.** After a Settings parity check reported to the
   client: `SettingsView.qml`, `PcView.qml`, the toolbar and everything only they
   keep alive.
4. **Remove the overdraw hazards.** `GameTile` per-tile layers, nine duplicate
   `Atmosphere` instances, per-focus-move layer churn. Deferred behind the stages
   above because no measurement on this hardware justifies them; the Deck may
   still. Re-measure when a Deck exists.
5. **One shell architecture.** `BulanPopup` base, single hint-bar model, one
   capture pipeline, `AppView.qml` split, fixtures out of production files.
6. **Design-system cohesion.** `FocusRing`/`FocusBloom`, dead tokens, the
   `lineHeight` ramp decision, `BulanTokens.qml` resolution, docs updated.
7. **Mockups, then redraw.** Client gate. No layout code before the client picks
   a direction.

Full plan and the audit it rests on:
`C:\Users\faris\.claude\plans\superpowers-brainstorming-design-ponyta-glittery-patterson.md`

## Boundaries

Retain discovery, pairing, wake, streaming, CLI and platform behavior. No
navigation framework, no new dependency, no persistence-schema change, no
identifier rename for branding. `codex/rework-core-shell` is excluded by client
decision and is not a source.

Layout, spacing and composition are stage 7 and are the client's call.

## Verified state at task start

Branch `polish-and-shell-rework`, cut from `master` at `177a58bd`, working tree
clean. `master` and `bulan` are both at that commit.

## Acceptance

- A measured frame-rate improvement recorded in `docs/validation/`, not an
  impression.
- No screen entrance that plays under a screen transition, and none that input
  cannot settle.
- One popup mechanism, one hint-bar owner, no stock visual control in a Bulan
  screen.
- `qmllint` on every changed QML file, a Windows Release build, a full
  controller walk of the route, `python scripts/context-audit.py`.
- Steam Deck hardware, Game Mode and LCD appearance are **not** available this
  session and will be reported as unchecked.
