# Bulan — permanent agent instructions

Project rules for every coding or reviewing agent here. Not a description of the
current branch, task, or defects.

## Start every session here

1. Read this file.
2. Inspect Git: branch, HEAD, tracking branch, remotes, working-tree status, and
   the commits relevant to the work.
3. Read `HANDOFF.md` — current repository and validation state.
4. Read the active task brief if `HANDOFF.md` names one.
5. Load only what the routing table sends you to.
6. Inspect the relevant source files and symbols.

**Do not read every project document at startup.** Steps 1–4 are the whole
default package. Load the rest on demand, only the sections bearing on the task,
and never reread what an accepted task brief quotes.

Repository documents outrank prior chat context. Objective facts come from Git
and the source, not remembered branch names, hashes, or summaries.

### Delegated agents

The lead session owns repository-wide startup and routing. A delegated agent
skips that sequence when its packet carries the verified branch, HEAD,
working-tree state, accepted task brief, and relevant authority sections. A
packet never overrides repository authority or excuses skipping authority
material the assignment touches, and `HANDOFF.md` is read only when
repository-wide state bears on it.

An editing agent still verifies the working tree immediately before editing.
Review and investigation agents stay read-only unless explicitly given
implementation ownership.

## Authority and routing

**The client outranks every document** on product, UX, visual design, copy,
scope, licensing, and compromises. **Git and the source outrank any document's
claim about them.**

| Document | Owns | Load when |
|---|---|---|
| `HANDOFF.md` | Repository and validation state | Startup, always |
| `TASK-BRIEF.md` | The one active task's scope | `HANDOFF.md` names one |
| `FLOW.md` | Navigation states, transitions, flow decisions | Routes or transitions change |
| `ROADMAP.md` | Release scope, phase order, exit conditions | Scope or sequencing |
| `DESIGN-SYSTEM.md` | Colour, type, motion, spacing, token values | Any visual value |
| `bulan-creative-brief.md` | Positioning, concept, voice, copy | A visual or copy call is stuck |
| `SPEC-*.md` | Durable decisions for one surface | Working that surface |
| `BUGS.md` | Open defects | Investigating a defect |
| `REVIEW-CHECKLIST.md` | The reusable Deck review procedure | A hardware review |
| `BUILDING-*.md` | Machine-specific build procedure | A platform build |
| `UI-AUDIT.md` | What upstream Moonlight does today | Comparing with upstream |
| `docs/` | Historical evidence — `decisions/`, `validation/`, `design-rationale/`, `history/`, `retrospectives/` | Investigating history |

`docs/` records previous answers; it never overrides current authority and is
never startup reading. A task brief is temporary: it may narrow the work, but it
never overrides this file, the flow, the roadmap, or the design system.

## When authorities disagree

Never silently choose between contradictory sources. Settle first whatever Git,
the tree, or the source can settle. Resolve what remains in this order: current
application source where a document claims to describe it → the latest accepted
client decision → the latest `docs/validation/` report → the relevant
`SPEC-*.md` → `ROADMAP.md`, `FLOW.md`, `DESIGN-SYSTEM.md` → recent Git history →
older prose.

That order is not permission to invent a product decision. If the repository
cannot settle it: stop before editing, quote both statements with their files
and headings, explain in plain English what each reading changes, recommend one,
and wait for the client.

Stop and ask when a product, UX, visual, copy, scope, licensing, branching, or
platform decision would change meaning; when a permanent rule could instead be a
task instruction; when a decision changed without an explicit replacement; when
a completed item may still be operationally relevant; when moving or deleting
material could hide project history; or when more than one structure is
defensible.

The client is the creative director and does not read code. State what a
recommendation changes for the product, workflow, or risk, not its mechanics.

## Product and interface invariants

**Controller first.** Every user-facing screen must be fully operable with a
gamepad alone; anything needing a mouse, touch, or trackpad is incomplete. Focus
must stay visible and navigation recoverable after dialogs, overlays, and screen
changes.

**Custom components only.** Do not instantiate a stock Qt Quick Control in a
Bulan screen. An import used only for attached infrastructure, such as
`StackView` attached properties, is allowed when it creates no stock visual
control and the specification records why.

**Tokens own visual values.** Colours, sizes, spacing, radii, opacity, and
durations come from the `Bulan` design-token singleton. Never put a raw visual
value in a product screen because a token is missing — propose the token,
grounded in the creative brief, and wait for the client. `DESIGN-SYSTEM.md` owns
the rules, values, and runtime/review-copy split.

**Minimum focus target.** Interactive focus targets are at least 64×64 px at the
native 1280×800 Deck layout. Display-only elements are exempt.

**Bulan is the project; Moonlight is its credited upstream.** Rename what a user
reads. Never rename an identifier for branding — application and organization
names, app IDs, upgrade codes, settings paths, the binary, upstream endpoints.
They decide what an existing install recognises, so a rename strands user data
and needs a migration and a client decision. Each is commented where defined.

## Branches, commits, and remotes

- `master` is Bulan's primary integration and default branch. The historical
  `bulan` branch was retired on 20 August 2026, locally and on the fork; its
  history is wholly contained in `master`.
- Work on a short, clearly named task branch cut from `master`. Merge only after
  the client signs off, then delete it locally and on the fork.
- `origin` is the client's fork. Never push to upstream Moonlight. Upstream is
  tracked through an `upstream` remote, never by keeping a Bulan branch
  pristine; that remote may not exist on every machine — inspect first.
- **Do not push any branch unless the client has authorized that push.**

One logical, independently reviewable change per commit. Show the client each
approved stage before committing it and before moving on. Never combine
unrelated changes because they shared a session.

## Working-tree and ownership safety

- Never edit an unexplained dirty working tree. Do not overwrite, discard,
  reformat, or include unrelated work, and never assume another agent's
  uncommitted work is done.
- One agent owns implementation at a time. A reviewer reports issues; it never
  silently rewrites the implementation. Transfer ownership only at a clean
  commit boundary, or after documenting every uncommitted file and its state.
- Do not modify discovery, pairing, streaming, or other application behavior
  unless the task requires it and the client accepted that scope.

## Build and test honesty

- Read the relevant `BUILDING-*.md` before a platform build; confirm which
  checkout, branch, and source path the recipe actually uses.
- Run the smallest meaningful static checks first, including `qmllint` on changed
  QML.
- Validate controller navigation and every affected state, not the easiest mouse
  path. Fake-host presets are review inputs, not real hosts.
- Read the application log before deciding a build, screen, or action did not run.
- **Never claim a build, test, screenshot review, Game Mode check, or hardware
  check passed unless it was actually performed.** Report skipped checks and the
  reason plainly.

## Documentation lifecycle

Each category of truth has one owner — see the table above. Do not copy a mutable
fact into a second document; link to its owner.

- `HANDOFF.md` is replaced, never appended to, and keeps no archive. Update it
  last, after tests and the final repository state are known.
- **One active task brief at a time**, `TASK-BRIEF.md`, created at task start,
  deleted on acceptance. Move anything durable to its owning authority or
  `docs/` first.
- Current documents state the current answer, never through a strikethrough or a
  correction bolted onto a stale claim.
- Dated results belong in `docs/validation/`, never in a reusable procedure.
  `BUGS.md` holds open defects only; a resolved defect's evidence moves to a
  validation report, a retrospective, or Git history.
- Move superseded material into `docs/` with its date and reason rather than
  deleting it, using `git mv` where practical. Rely on Git history for incidental
  obsolete prose; do not create an archive file per status update.
- Do not claim the documentation is consistent until every relevant Markdown
  file has been checked.

Run `python scripts/context-audit.py` from the repository root after a
documentation change; it measures the startup package and fails on the patterns
above.
