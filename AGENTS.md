# Bulan — permanent agent instructions

These rules apply to Claude Code, Codex, and any other coding or reviewing
agent working in this repository. They are project rules, not a description of
the current branch, task, defects, or session.

## Start every session here

Before proposing or changing anything:

1. Read this file.
2. Inspect the current branch, HEAD, tracking branch, configured remotes, and
   working-tree status.
3. Read the recent commits relevant to the work.
4. Read `bulan-creative-brief.md` for product, brand, voice, visual, and
   interaction intent.
5. Read `FLOW.md` for navigation states and transitions.
6. Read `ROADMAP.md` for scope, phase order, and the next milestone.
7. Read `HANDOFF.md` for the current repository state and last known validation.
8. Read the active task brief named by `HANDOFF.md`, if one exists.
9. Read the relevant `SPEC-*.md`, `BUILDING-*.md`, and `BUGS.md` files for the
   surface, machine, or defect being worked on.

Repository documents outrank prior chat context. Objective repository facts
come from Git and the current source, not from remembered branch names, commit
hashes, or session summaries.

## Authority

Use each document only for the kind of decision it owns:

| Authority | Governs |
|---|---|
| The client | Product, UX, visual design, copy, scope, licensing presentation, and acceptable compromises |
| `bulan-creative-brief.md` | Durable product and creative intent |
| `FLOW.md` | Navigation states, transitions, and flow decisions |
| `ROADMAP.md` | Release scope, phase order, exit conditions, and sequencing |
| `HANDOFF.md` | Current repository and validation state |
| The active task brief | The scope and acceptance criteria of one active task |
| `BUGS.md` | Acknowledged open defects |
| `SPEC-*.md` | Durable decisions and known unfinished work for a product surface |
| `BUILDING-*.md` | Reproducible machine-specific build and review procedures |
| Git and application source | What is objectively present and what the code currently does |

An active task brief is temporary. It may narrow the work, but it does not
silently override this file, the creative brief, the flow, or the roadmap.

## When authorities disagree

Do not silently choose between contradictory sources.

First investigate anything that can be settled objectively from Git history,
the current branch, the working tree, or the application source. If a real
authority conflict remains:

1. Stop before editing the affected material or implementation.
2. Quote or precisely identify both statements.
3. Name the files and headings where they appear.
4. Explain in plain English what choosing either interpretation changes.
5. Give a recommended interpretation and why.
6. Wait for the client to decide.

Always stop and ask when:

- a product, UX, visual, copy, scope, licensing, branching, or platform decision
  would change meaning;
- a permanent rule could instead be a temporary task instruction;
- a decision appears to have changed without an explicit replacement;
- a completed item may still be operationally relevant;
- moving or deleting material could hide useful project history;
- a filename or document purpose is ambiguous; or
- more than one documentation or implementation structure is reasonably
  defensible.

Technical recommendations must state their practical consequences and include
a preferred option. The client is the creative director and does not read code,
so explain what changes for the product, workflow, or risk rather than only
describing implementation mechanics.

## Product and interface invariants

### Controller first

Every user-facing screen must be fully operable with a gamepad alone. If an
interaction works only with a mouse, touch, or trackpad, it is incomplete.
Focus must remain visible and navigation must remain recoverable after dialogs,
overlays, and screen changes.

### Custom components only

Do not instantiate stock Qt Quick Controls in a Bulan screen. Bulan controls,
menus, dialogs, toggles, sliders, and other visible interface elements are
custom components.

An import used only for attached infrastructure, such as `StackView` attached
properties, is allowed when it creates no stock visual control and the relevant
specification records why it is needed.

### Tokens own visual values

Colours, sizes, spacing, radii, opacity, and durations come from the `Bulan`
design-token singleton. Do not introduce a raw visual value in a product screen
because a token is missing.

If a token is missing, explain the need and propose a value grounded in the
creative brief or an explicit client decision. Wait for the client before
turning a new visual judgement into a project-wide token.

`app/gui/Bulan.qml` is the live runtime token source. `BulanTokens.qml` is a
review copy for the token proof sheet; any value duplicated there must remain
synchronized with the runtime token.

### Minimum focus target

Interactive focus targets are at least 64×64 pixels at the native 1280×800
Steam Deck layout. Display-only elements are exempt.

## Branches, commits, and remotes

- `master` is the fork's clean mirror of upstream. Never commit Bulan work to
  it.
- `bulan` is the Bulan integration branch and known-good baseline.
- Do work on a short, clearly named task branch cut from `bulan`.
- Merge a task branch into `bulan` only after the client signs off.
- Delete the task branch locally and on the fork after the accepted merge.
- `origin` is the client's fork. Never push to the upstream Moonlight
  repository. A remote named `upstream` may not be configured on every machine;
  inspect remotes before using one.
- Do not push any branch unless the client has authorized the push.

Make one logical, independently reviewable change per commit. Stop and show the
client the result before committing each approved stage and before moving to
the next stage. Do not combine unrelated changes merely because they were made
in the same session.

## Working-tree and ownership safety

- Never edit an unexplained dirty working tree.
- Do not overwrite, discard, reformat, or include unrelated work.
- Never assume another agent's uncommitted work is complete.
- One agent owns implementation of the active task at a time.
- A reviewing agent may report issues but must not silently rewrite the
  implementation.
- Transfer ownership only at a clean commit boundary or after explicitly
  documenting every uncommitted file and its state.
- Do not modify discovery, pairing, streaming, or other application behavior
  unless the active task explicitly requires it and the client has accepted the
  scope.

## Build and test honesty

- Read the relevant `BUILDING-*.md` before running a platform build.
- Confirm which checkout, branch, and source path a build recipe actually uses.
- Run the smallest meaningful static checks before a build, including
  `qmllint` for changed QML.
- Validate controller navigation and all affected states, not only the easiest
  mouse path.
- Treat fake-host presets as review inputs, not as real hosts.
- Read the application log before deciding that a build, screen, or action did
  not run.
- Never claim a build, test, screenshot review, Game Mode check, or hardware
  check passed unless it was actually performed.
- Report skipped checks and the reason plainly.

## Documentation lifecycle

- Keep permanent operating rules in this file.
- Keep mutable repository state in `HANDOFF.md`.
- Keep only one active task brief. Create it at the start of a task and delete
  or archive it after the task is complete.
- Keep open defects in `BUGS.md`; move useful closed investigations to a
  retrospective rather than leaving them in the active list.
- Preserve deliberate evolution from the creative brief. Label it as an
  accepted change, compromise, provisional decision, deferral, or superseded
  direction instead of rewriting history.
- Prefer links to the appropriate authority over copying mutable facts.
- Preserve useful historical knowledge through Git-aware moves or a small
  retrospective set; do not delete it merely to shorten a current document.
- Update `HANDOFF.md` only after tests and the final repository state are known.
- Write repository-state documents last, never in anticipation of a merge,
  test, or cleanup that has not happened.
- Do not claim the documentation is consistent until every relevant Markdown
  file has been checked.
