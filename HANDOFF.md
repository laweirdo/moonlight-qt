# Bulan — current handoff

Current as of **30 July 2026**.

This file is the authority for current repository and validation state. Permanent
operating rules are in `AGENTS.md`; product intent is in the creative brief;
sequencing is in the roadmap; the implementation work order is in
`TASK-BRIEF.md`.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan`; this snapshot is prepared on a short state-only branch |
| Published documentation baseline | `73be60bc` on `origin/bulan` |
| Documentation branch baseline | `bulan` at `30aaa57d` |
| Documentation state | Stages 1 through 6 are merged and pushed; the completed task branch was deleted |
| Working tree before this state-only snapshot | Clean |
| Configured remotes | `origin` only in this checkout |
| Application source changes in the documentation work | None |

Always inspect Git before relying on this snapshot. Do not copy these values into
permanent rules or specifications.

## Last completed work

### Documentation

Stages 1 through 6 of the documentation reorganization are complete:

- `d49d3a90` created `AGENTS.md` as the permanent operating authority and moved
  stable rules out of mutable session documents.
- `b7eeb09f` reduced this handoff and established `TASK-BRIEF.md` as the single
  active work order.
- `87d305f9` separated roadmap sequencing from project history, reconciled the
  flow questions, and created the cross-cutting debugging retrospective.
- `2fbdfc9f` separated the open startup-toolbar defect from the closed carousel
  investigations and preserved the ledger as a detected Git rename.
- `141462d2` reconciled deliberate creative evolution, logo roles, hardware
  validation, and the durable carousel specification.
- `73be60bc` added the Bulan README notice, reconciled stale review and build
  references, and completed the repository-wide Markdown validation.

No application file changed and no application build was needed for these
stages. The six commits were fast-forwarded into `bulan`, pushed to `origin`,
and the completed documentation task branch was deleted.

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

## Documentation task status

The documentation-architecture task is **complete**. Stage 6:

- adds a concise Bulan orientation notice without rewriting the upstream
  README;
- makes `UI-AUDIT.md` explicitly historical rather than tied to an obsolete
  branch;
- removes stale handoff references from machine build instructions and records
  all six fake-host presets;
- reconciles the hardware checklist with the later Wake pass, 180 ms focus
  timing, private-v1 glyph decision, and fake-host guard; and
- checks all 18 tracked project Markdown files and their local references.

The client approved the Stage 6 result and it is committed. No documentation
stage is awaiting review.

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
| Centred-logo assets | Client must design and provide vectors; the final horizontal corner wordmark is not a substitute |
| Moonlight credit | Required and not yet added |

## Last known build and validation status

No application build or runtime test was performed for documentation Stages 1
through 6 because they do not change application files.

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
| Stage 3 documentation | UTF-8, whitespace, reference, Mermaid-fence, and documentation-only scope checks passed |
| Stage 4 documentation | UTF-8, whitespace, reference, open/closed separation, rename-detection, and documentation-only scope checks passed |
| Stage 5 documentation | Committed as `141462d2` after UTF-8, whitespace, reference, source-value, logo-placement, and documentation-only checks passed |
| Stage 6 documentation | All 18 tracked project Markdown files reread; UTF-8, whitespace, local links, code fences, stale-state scans, and documentation-only scope checks passed |

The relevant `BUILDING-*.md` file must be read before the next application
build. Do not infer that an old validation covers new application changes.

## Open defects relevant to the next session

One acknowledged open defect exists:

### Upstream toolbar appears during launch

The inherited toolbar starts visible and remains on screen for approximately
567 ms before the carousel hides it. `BUGS.md` owns its reproduction, evidence,
diagnosis, uncertainty, next action, priority, and relevant files.

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

Centred-logo screens require vector assets designed and supplied by the client.
Agents must not enlarge, recompose, or substitute the final horizontal corner
wordmark. This does not block the active host-settings task, but it is a client
dependency for the relevant onboarding and artwork work.

## Decisions made in the latest documentation session

These decisions are settled and must be carried into future work:

| Topic | Decision |
|---|---|
| Active product task | Host settings remains active; implementation has not started |
| Commit policy | One logical, independently reviewable change per commit; stop for approval between stages |
| Creative deliverables | Long-term list and creative guide, not the definition of v1 |
| Steam Deck glyph art | Not required for v1; current XInput glyphs are practically identical |
| Reflected-moon mark | Superseded |
| Horizontal corner wordmark | `app/res/bulan_logo_horiz.svg` is final for that role |
| Centred-logo assets | Client will design and supply separate vectors; agents must not infer them |
| Hardware target | LCD and OLED remain targets; LCD visual validation is deferred, not blocking |
| Host settings classification | Product task and functional regression, not a numbered defect |
| Upstream UI audit findings | Historical redesign findings, not active defects |
| v1 technical foundation | Retain upstream discovery, pairing, streaming, and platform infrastructure; replace individual UI components only when justified |
| Historical organization | Use a small retrospective set and preserve Git-aware moves |
| Root README | Keep upstream content and add a concise Bulan orientation notice without public-release marketing |

Stage 6 applied the agreed README notice and objective cross-file corrections.
It introduced no new product or design decision.

## Required reading

Read in this order before the next product task:

1. `AGENTS.md`
2. Inspect the branch, HEAD, remotes, and working tree.
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `TASK-BRIEF.md`
8. `BUGS.md`
9. `SPEC-host-carousel.md`
10. The relevant `BUILDING-*.md` before any build

`UI-AUDIT.md` is an upstream historical baseline, not a current implementation
authority.

## Next recommended action

For the host-settings implementation:

1. Ask the four client questions in `TASK-BRIEF.md`.
2. Inspect the latest approved `bulan` and create the implementation branch.
3. Record that exact branch and baseline here.
4. Implement and validate one approved logical change at a time.

## Do not touch before the host-settings implementation

- Application source, QML, C++, build logic, assets, or design files
- Host discovery, pairing, streaming, or platform infrastructure
- The accepted carousel implementation
- Build procedures

The host-settings task brief owns the exact implementation scope, including the
startup-toolbar defect.
