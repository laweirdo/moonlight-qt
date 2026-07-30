# Bulan — current handoff

Current as of **30 July 2026**.

This file is the authority for current repository and validation state. Permanent
operating rules are in `AGENTS.md`; product intent is in the creative brief;
sequencing is in the roadmap; the implementation work order is in
`TASK-BRIEF.md`.

## Repository state when written

| Item | State |
|---|---|
| Current branch | `codex/docs-architecture` |
| Current HEAD before the Stage 3 review diff | `b7eeb09f` — `docs: simplify current handoff and task brief` |
| Documentation branch baseline | `bulan` at `30aaa57d` |
| Integration branch | `bulan`, matching `origin/bulan` at `30aaa57d` when this branch was created |
| Working tree | **Dirty by design:** Stage 3 simplifies the roadmap, reconciles the flow, and moves general lessons into one retrospective; awaiting client review |
| Configured remotes | `origin` only in this checkout |
| Application source changes on this branch | None |

Always inspect Git before relying on this snapshot. Do not copy these values into
permanent rules or specifications.

## Last completed work

### Documentation

Stages 1 and 2 of the documentation reorganization are complete:

- `d49d3a90` created `AGENTS.md` as the permanent operating authority and moved
  stable rules out of mutable session documents.
- `b7eeb09f` reduced this handoff and replaced
  `PROMPT-next-session.md` with the single active `TASK-BRIEF.md`.

No application file changed and no application build was needed for either
stage.

### Application

The last completed product task was the host-carousel rebuild, merged into
`bulan` in `942e3d02` and accepted by the client.

The rebuilt carousel:

- positions tiles directly rather than using `PathView`;
- keeps host text attached to its tile;
- counts every visible machine in the ready-count denominator;
- clamps at both ends without wrapping; and
- no longer lets mouse hover steer selection.

`SPEC-host-carousel.md` is the durable authority for that surface.

## Work currently in progress

The documentation-architecture task is in **Stage 3 — roadmap and flow**. The
review diff:

- narrows `ROADMAP.md` to scope, sequencing, milestones, exits, and genuine
  standing risks;
- gives `FLOW.md` an explicit authority header;
- resolves or defers the old flow questions using the client's settled
  decisions; and
- moves reusable historical lessons to
  `docs/retrospectives/DEBUGGING-LESSONS.md`.

Stages 4–6 have not started. The documentation is therefore **not yet fully
reconciled**, and `BUGS-open.md`, the creative brief, specifications, and README
still await their scheduled stages.

## Active implementation task

The host-settings task remains the single active product work order, but its
implementation session has **not started**.

`TASK-BRIEF.md` owns its objective, scope, non-goals, unresolved client
questions, risks, acceptance criteria, and required tests. No implementation
branch exists yet.

The task contains three logical changes:

1. Change `hostTileLabelGap` from 56 to 46.
2. Replace SELECT's temporary details panel with the approved host menu.
3. Fix the startup toolbar defect without removing inherited toolbars.

These lines are only a pointer. If they disagree with `TASK-BRIEF.md`, stop and
reconcile the documents rather than expanding this summary.

## Current application state relevant to the next task

| Area | Current state |
|---|---|
| Initial screen | Bulan host carousel |
| Host settings on SELECT | Temporary read-only details panel |
| Rename / Forget / Test Network | Still present in upstream `PcView.qml`, unreachable from the carousel |
| Host label gap | 56; client-approved target is 46 |
| Startup toolbar | Visible for about 567 ms; open defect |
| Wake | Works on a host that provides a hardware address |
| Wake hint | Shown only when the focused host is offline and wakeable |
| Game Mode | Verified; Steam Input preserves Valve's vendor ID and all five bindings work |
| Deck glyph drawing | Deck is detected, but v1 intentionally uses the practically identical XInput glyph set |
| App grid, settings, and segue screens | Still inherited upstream screens, restyled but not rebuilt |
| Onboarding | Designed in reference frames but not implemented |
| Moonlight credit | Required and not yet added |

## Last known build and validation status

No application build or runtime test was performed for documentation Stages 1
or 2 because they do not change application files.

| Validation | Last known result |
|---|---|
| Windows review build | Carousel rebuild loaded and was checked frame by frame on 28 July 2026 |
| Steam Deck Desktop Mode | Controller regressions, token values, and host navigation passed on 28 July 2026 |
| Steam Deck Game Mode | Passed on 28 July 2026 with `gamescope` confirmed; all five bindings arrived |
| Wake-on-LAN | Passed on 28 July 2026 using a genuinely sleeping wakeable host |
| Carousel hover | Client-confirmed with a mouse; closed |
| LCD visual validation | Deferred until LCD hardware is available; not a private-v1 blocker |
| Stage 1 documentation | UTF-8, whitespace, staged-diff, and documentation-only scope checks passed |
| Stage 2 documentation | UTF-8, whitespace, staged-diff, and documentation-only scope checks passed |

The relevant `BUILDING-*.md` file must be read before the next application
build. Do not infer that an old validation covers new application changes.

## Open defects relevant to the next session

One acknowledged open defect exists:

### Upstream toolbar appears during launch

The inherited toolbar starts visible and remains on screen for approximately
567 ms before the carousel hides it. The diagnosis and evidence are currently
in `BUGS-open.md`; Stage 4 will move the active entry to `BUGS.md`.

The host-settings menu is not a numbered defect. It is an active product task
and a functional regression from upstream.

The upstream observations in `UI-AUDIT.md` remain historical redesign findings,
not accepted Bulan defects.

## Unresolved decisions and blockers

There is no known technical blocker to beginning the host-settings task.

Four client design decisions are required before implementation:

1. Overlay or pushed screen?
2. What should the menu show for an offline host?
3. Does Forget PC require confirmation?
4. Do Rename PC and Test Network belong in the v1 menu?

They are recorded in `TASK-BRIEF.md`. The implementing agent must bring a
recommendation and consequence for each rather than deciding silently.

LCD banding and panel-specific visual validation remain deferred until LCD
hardware is available. They do not block private v1.

## Decisions made in the latest documentation session

These decisions are settled and must be carried into the remaining
documentation stages:

| Topic | Decision |
|---|---|
| Active product task | Host settings remains active; implementation has not started |
| Commit policy | One logical, independently reviewable change per commit; stop for approval between stages |
| Creative deliverables | Long-term list and creative guide, not the definition of v1 |
| Steam Deck glyph art | Not required for v1; current XInput glyphs are practically identical |
| Reflected-moon mark | Superseded |
| Hardware target | LCD and OLED remain targets; LCD visual validation is deferred, not blocking |
| Host settings classification | Product task and functional regression, not a numbered defect |
| Upstream UI audit findings | Historical redesign findings, not active defects |
| v1 technical foundation | Retain upstream discovery, pairing, streaming, and platform infrastructure; replace individual UI components only when justified |
| Historical organization | Use a small retrospective set and preserve Git-aware moves |
| Root README | Keep upstream content and add a concise Bulan orientation notice without public-release marketing |

These decisions have not all been applied yet. The roadmap, flow, defects,
brief, specifications, historical files, and README are handled in later stages.

## Required reading

Read in this order before the next documentation stage:

1. `AGENTS.md`
2. This file
3. `TASK-BRIEF.md` when discussing the next application task
4. `bulan-creative-brief.md`
5. `FLOW.md`
6. `ROADMAP.md`
7. `BUGS-open.md` until Stage 4 creates `BUGS.md`
8. `SPEC-host-carousel.md`
9. The relevant `BUILDING-*.md` before any build

`UI-AUDIT.md` is an upstream historical baseline, not a current implementation
authority.

## Next recommended action

For the current documentation task:

1. Review this Stage 3 diff.
2. If approved, commit it as a separate documentation-only change.
3. Begin Stage 4 by separating the open startup-toolbar defect from the closed
   carousel investigations.

For the later host-settings implementation:

1. Finish and merge the documentation reorganization first.
2. Ask the four client questions in `TASK-BRIEF.md`.
3. Inspect the latest approved `bulan` and create the implementation branch.
4. Record that exact branch and baseline here.
5. Implement and validate one approved logical change at a time.

## Do not touch during the next documentation stage

- Application source, QML, C++, build logic, assets, or design files
- Host discovery, pairing, streaming, or platform infrastructure
- The accepted carousel implementation
- The host-settings implementation
- The active startup-toolbar defect
- Build procedures, except where a later documentation stage explicitly moves
  duplicated historical material without changing commands

Stage 3 is documentation architecture only: roadmap, flow, and relocation of
their durable historical lessons.
