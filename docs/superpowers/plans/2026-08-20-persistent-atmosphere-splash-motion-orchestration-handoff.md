# Persistent Atmosphere and Splash Motion Orchestration Handoff Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hand the committed Bulan motion change to the main orchestration agent for one minimal documentation-state correction and final evidence review.

**Architecture:** The three UI commits are already complete and must not be rewritten. The only required correction is a docs-only update to `HANDOFF.md`, which must describe the actual clean branch and preserve the explicitly untested runtime and Deck checks.

**Tech Stack:** Git, Markdown, Python `context-audit.py`, Qt/QML validation records.

**Spec:** `docs/superpowers/plans/2026-08-20-persistent-atmosphere-splash-motion.md`

## Global Constraints

- Base: `master` / `ea46a661`.
- Current branch: `fix/persistent-atmosphere-splash-motion`.
- Current HEAD: `e1b5246ceae844b64c765f34a5774473e9caf6f0`.
- The three commits already exist: `bb700d9a`, `2ab9a5f2`, `e1b5246c`.
- Do not rewrite, reset, squash, amend, push, or merge the three commits.
- Do not change QML, C++, discovery, pairing, streaming, or route behavior.
- Do not claim splash-transition, modal-blur, rapid-navigation, or Deck validation unless actually performed.
- Keep `TASK-BRIEF.md` until client acceptance.

---

## Ready-to-paste handoff prompt

```text
You are the main orchestration agent for the Bulan persistent-atmosphere and splash-motion task.

Repository state is authoritative from Git:
- branch: fix/persistent-atmosphere-splash-motion
- base/master: ea46a661872f80ef452b71ecfa09dbbf98483bbb
- HEAD: e1b5246ceae844b64c765f34a5774473e9caf6f0
- working tree: clean before this handoff
- origin: https://github.com/laweirdo/bulan-qt.git
- nothing is pushed or merged

The three implementation commits are already committed and must remain intact:
1. bb700d9a fix(ui): keep the atmosphere still during navigation
2. 2ab9a5f2 fix(ui): fade the Bulan splash during startup
3. e1b5246c docs: record the persistent atmosphere and the splash motion

Read AGENTS.md, the current HANDOFF.md, TASK-BRIEF.md, and the approved plan at:
docs/superpowers/plans/2026-08-20-persistent-atmosphere-splash-motion.md

Review finding to resolve:
HANDOFF.md is stale. It still says the branch has no commits and is dirty, and
its last_verified_commit is ea46a661. Update HANDOFF.md to describe the actual
state at e1b5246c:
- master remains ea46a661 and untouched;
- the task branch contains the three commits above;
- the working tree is clean before the documentation correction;
- nothing is pushed or merged;
- the validation report records the actual Windows/QML evidence;
- splash in-flight, skip timing, modal blur, rapid push/back, Deck Desktop Mode,
  and Deck Game Mode remain NOT TESTED unless you personally run them;
- client sign-off is the remaining blocker.

Do not rewrite the three commits or alter implementation files. A new docs-only
commit is allowed only after showing the client the diff and the exact validation
state, per AGENTS.md. If you inspect DESIGN-SYSTEM.md, keep any cleanup minimal:
preserve the approved atmosphere/blur/splash rules and avoid a broad prose
rewrite for aesthetics alone.

Run only checks that produce real evidence:
1. git status --short
2. git diff --check
3. python scripts/context-audit.py
4. compare git diff master..HEAD for scope drift

Do not rerun or claim a Windows build, desktop visual review, or Deck review
unless actually performed using the repository's documented procedure.

Final response must report:
- the corrected branch and HEAD;
- whether a docs-only commit was created;
- files changed;
- checks actually run and outcomes;
- runtime/Deck checks still NOT TESTED;
- whether anything was pushed or merged.
```

## Execution checklist

- [ ] Verify the branch, HEAD, remotes, and clean state before editing.
- [ ] Update only stale repository-state facts in `HANDOFF.md`.
- [ ] Run `git diff --check` and `python scripts/context-audit.py`.
- [ ] Compare the complete branch against `master` for scope drift.
- [ ] Show the docs diff and evidence to the client before any new commit.
- [ ] If authorized, create one docs-only commit; otherwise leave the correction uncommitted and report it.
- [ ] Do not push or merge.
