@AGENTS.md

# Claude Code orchestration

This file adds Claude Code orchestration mechanics on top of `AGENTS.md`, which
remains the project authority. Where `AGENTS.md` requires a client stop — stage
sign-off before committing, authority conflicts, product/UX/scope decisions,
pushes, merges, and branch deletion — that requirement still applies unless the
client waives it for a specific task. The stages and autonomy described below
govern how Claude organizes work between those stops, not whether they happen.

## Roles

- The main session uses Opus at medium effort.
- Opus owns planning, orchestration, product-decision detection, task decomposition, integration, direct diff review, and the final report.
- Use one Sonnet implementation agent at medium effort for a task's related implementation stages.
- Keep that implementation work in one uninterrupted agent context where possible. When continuation is supported, resume the same agent rather than starting another.
- Do not create replacement implementation agents merely to obtain a fresh context.
- Opus resolves ordinary engineering questions itself rather than delegating every uncertainty.

## Shared task brief

For multi-stage work, Opus creates one compact `TASK-BRIEF.md` before delegation. It contains only:

- Current branch, baseline commit, and task objective
- Relevant files and symbols
- Accepted product decisions
- Scope exclusions
- Stage acceptance criteria
- Required tests
- Known validation limits

Keep the brief concise and update it only when a decision or scope boundary changes. Do not use it as a running diary.

Agents receive the brief plus an explicit file assignment. Do not paste large repository documents into delegation prompts.

## Context discipline

- Search for symbols and call sites before reading whole files.
- Read only relevant ranges when a full file is unnecessary.
- Do not reread documents already represented accurately in the shared brief.
- Do not scan or summarize the entire repository unless explicitly required.
- Do not restate the task or project background in agent reports.
- Prefer one targeted read over a delegated investigation when Opus can resolve the issue efficiently.
- Avoid loading generated files, vendored code, build output, or unrelated history.

## Implementation agent

- Give the implementation agent explicit file ownership and named symbols or call sites.
- The implementation agent may inspect directly related callers, callees, tests, and build definitions.
- It must request an ownership expansion before editing outside the assigned set.
- Require minimal coherent changes that preserve existing contracts.
- Avoid speculative refactoring and unrelated cleanup.
- Its reports contain only:
  - Changed files
  - Checks run and results
  - Blockers
  - Remaining risks

## Investigation agents

Spawn an additional Sonnet agent only for a narrow, high-risk question that Opus cannot resolve efficiently.

Each investigation must:

- Ask exactly one precise question
- Be read-only
- Be independent of other parallel investigations
- Return no more than 3–5 findings
- Stay within 300–400 words
- Include file paths and symbol references
- Avoid general repository summaries
- Avoid proposing unrelated improvements

## Review

- Opus reviews diffs directly.
- Do not spawn a separate reviewer by default.
- Add one read-only Sonnet reviewer only for changes involving risky backend contracts, object lifetime, concurrency, security, or similarly difficult failure modes.
- The reviewer receives the diff scope and a short risk question, not the full project history.
- Opus verifies every reported finding before changing code.

## Parallelism

- Never run parallel editing agents.
- Parallelize only independent, read-only investigations.
- Do not let multiple agents inspect the same broad area without a specific reason.
- Avoid agent teams for work that can be completed by one implementation agent.

## Decisions and autonomy

- Do not ask the user to choose routine architecture, naming, test, or implementation details.
- Choose the smallest solution consistent with repository authority and existing patterns.
- Ask for a client decision only when authoritative documents and accepted precedents do not settle a materially visible product choice.
- A decision request must include:
  - The exact unresolved choice
  - Two or three concrete options
  - The visible or behavioral consequence of each
  - Opus's recommended option
- Pause only the affected work. Continue independent work when safe.

## Completion

Before reporting completion:

- Inspect the final diff directly.
- Run the task's required checks.
- Confirm the working tree and commit history.
- Record unperformed validation honestly.
- Do not claim hardware, controller, stream, performance, or client acceptance that was not actually obtained.
- Do not push, merge, or perform destructive Git operations without explicit authorization.
