@AGENTS.md

# Claude Code orchestration

`AGENTS.md` is the project authority and is loaded above. This file adds only
what is specific to running Claude Code here. Where `AGENTS.md` requires a
client stop — stage sign-off before committing, authority conflicts,
product/UX/scope decisions, pushes, merges, branch deletion — that requirement
still applies. Nothing below relaxes it.

## Roles

- The main session is Opus at medium effort. Opus owns planning, orchestration,
  product-decision detection, task decomposition, integration, direct diff
  review, and the final report.
- Use **one** Sonnet implementation agent at medium effort for a task's related
  implementation stages, and keep that work in one uninterrupted context.
  Resume it rather than starting another; do not create a replacement agent
  merely to obtain a fresh context.
- Opus resolves ordinary engineering questions itself instead of delegating
  every uncertainty.

## Context packet

`AGENTS.md` owns the task-brief lifecycle. For multi-stage work Opus writes the
one active `TASK-BRIEF.md` before delegating, containing only:

objective · scope · out of scope · relevant authority sections · likely files
and symbols · accepted decisions · known risks · validation expectations ·
completion criteria · a context manifest naming what is *not* needed.

An agent receives the brief plus an explicit file assignment. Do not paste large
repository documents into a delegation prompt, and do not reread material the
accepted brief already quotes.

Beyond that: search for symbols and call sites before opening whole files, read
only the ranges that matter, and never load vendored code, build output, or
unrelated history.

## Implementation agent

- Give it explicit file ownership and named symbols or call sites. It may
  inspect directly related callers, callees, tests, and build definitions, and
  must request an ownership expansion before editing outside that set.
- Require minimal coherent changes that preserve existing contracts. No
  speculative refactoring, no unrelated cleanup.
- Its report contains only: changed files · checks run and results · blockers ·
  remaining risks. No task restatement, no project background.

## Investigation agents

Spawn one only for a narrow, high-risk question Opus cannot resolve efficiently.
Each must ask exactly one precise question, be read-only, be independent of any
parallel investigation, return 3–5 findings in 300–400 words with file paths and
symbol references, and propose nothing unrelated.

## Review

Opus reviews diffs directly and does not spawn a reviewer by default. Add one
read-only Sonnet reviewer only for risky backend contracts, object lifetime,
concurrency, security, or similarly difficult failure modes; give it the diff
scope and a short risk question, not project history. Opus verifies every
reported finding before changing code.

## Parallelism

Never run parallel editing agents. Parallelize only independent read-only
investigations, and do not send two agents into the same broad area without a
specific reason.

## Decisions and autonomy

Choose the smallest solution consistent with repository authority and existing
patterns. Do not ask the client to settle routine architecture, naming, test, or
implementation details. Escalate only a materially visible product choice that
the authoritative documents and accepted precedents do not settle, and include
the exact unresolved choice, two or three concrete options, the visible
consequence of each, and Opus's recommendation. Pause only the affected work.

## Completion

Inspect the final diff directly, run the task's required checks, confirm the
working tree and commit history against Git rather than memory, and record
unperformed validation honestly.
