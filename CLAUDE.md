@AGENTS.md

# Claude Code orchestration

`AGENTS.md` is the project authority, loaded above. This adds Claude Code
specifics only; every client stop it requires still applies.

## Roles

The main session is Opus at medium effort. Opus owns planning, product-decision
detection, task decomposition, integration, direct diff review and the final
report, and resolves ordinary engineering questions itself rather than
delegating uncertainty.

**Opus implements directly by default.** Delegation duplicates a context —
packet, rebuilt state, report, and Opus rereading the diff anyway — so judge
total tokens across both sessions, not main-session context alone.

**Stay in the main session** for a quick targeted change, a small documentation
or QML edit, a one-to-three-file fix, source Opus has already read, work needing
frequent product decisions or checkpoints, or work whose planning,
implementation and validation share context.

**Delegate to one Sonnet agent at medium effort** only when the work is
self-contained and large enough to amortize a separate context: a substantial
implementation, a bounded multi-file subsystem change, extensive source
exploration, verbose build or test output, or intermediate context disposable
once the diff exists. Judgment factors, not thresholds.

## Context packet

For multi-stage delegation Opus writes the one active `TASK-BRIEF.md`, whose
lifecycle `AGENTS.md` owns: objective · scope · out of scope · relevant
authority sections · likely files and symbols · accepted decisions · known risks
· validation expectations · completion criteria · a context manifest naming what
is *not* needed · the verified branch, HEAD and working-tree state.

An agent gets the brief plus an explicit file assignment, never a pasted
repository document. Whoever implements: find symbols and call sites before
opening whole files.

## Implementation agent

- Explicit file ownership and named symbols or call sites. It may inspect
  related callers, callees, tests and build definitions, and must request an
  expansion before editing outside that set.
- Minimal coherent changes preserving contracts. No speculative refactoring, no
  unrelated cleanup.
- Its report: changed files · checks and results · blockers · risks. Nothing
  else.
- Structure delegated work as one complete invocation where practical. Resume
  that agent if this configuration supports it; otherwise continue in the main
  session rather than spawning a replacement to recreate its context.

## Investigation

Opus answers ordinary engineering questions itself. Basic file, symbol, caller
and dependency discovery goes to whatever lightweight exploration this
configuration provides. A read-only Sonnet investigation agent is the last
resort, for one narrow high-risk semantic question Opus cannot resolve
efficiently — never to find files or symbols, never to summarize the repository.
One precise question, independent of any parallel one, 3–5 findings in 300–400
words with file paths and symbols.

## Review and parallelism

Opus reviews diffs directly; no reviewer by default. Add one read-only Sonnet
reviewer only for risky backend contracts, object lifetime, concurrency or
security, with the diff scope and a short risk question, not project history.
Opus verifies every finding before changing code.

Never run parallel editing agents. Parallelize only independent read-only
investigations, and not two into one broad area without reason.

## Decisions and autonomy

Choose the smallest solution consistent with repository authority and existing
patterns, and never ask the client to settle routine architecture, naming, test
or implementation details. An escalation carries the exact unresolved choice,
two or three options, the visible consequence of each, and a recommendation.
Pause only the affected work.

## Completion

Inspect the final diff, run the required checks, and confirm the working tree
and commit history against Git rather than memory.
