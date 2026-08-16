---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: e6b7d5ea
---

# Bulan — current state

**Verified 16 August 2026.** Inspect Git before relying on this — it is a
snapshot, not an authority on what Git says. Replaced, never appended to; past
states are in Git history, past evidence in `docs/validation/`.

## Repository

| Item | State |
|---|---|
| Branches | **On `responsive-game-surface`** at `e6b7d5ea`, cut from `master` and 3 ahead of it. `master` is at `b4ecc709`, level with `origin/master`. `bulan` is still at `177a58bd` and no longer matches `master` |
| Remote | `origin` only — `laweirdo/bulan-qt`. **Nothing pushed, and no push is authorized** |
| Working tree | Documentation only, uncommitted: this file, `SPEC-game-grid.md`, `DESIGN-SYSTEM.md`, `FLOW.md`, `TASK-BRIEF.md`, and the new validation report |
| Active task | **Yes.** `TASK-BRIEF.md`, now at its stage 7 redraw |
| Other branches | `codex/rework-core-shell` is excluded by client decision, 15 August 2026 |

## Where the product is

**Alpha v0.0.1.** `ROADMAP.md` owns scope and phase.

Merged to `master` on 15–16 August 2026: the frame-rate measurement, one motion
contract, the deletion of the inherited Moonlight shell, one shell architecture,
design-system cohesion, and five accepted mockups. **No stock visual control
remains in a Bulan surface.**

Three commits on the task branch carry the client's 16 August 2026 decisions;
`SPEC-game-grid.md`, `DESIGN-SYSTEM.md` and `FLOW.md` own what they mean:

- `90e929a3` — the application is composed at 1280×800 and that one frame is
  scaled to fit the window. Also removes every line of text under game artwork;
  the name survives inside the missing-art fallback.
- `4fc52111` — Recent's focused game starts on the margin, walks to the middle
  and locks there; the row draws every game that touches the screen.
- `e6b7d5ea` — the onboarding crescent is one window-level image the two
  onboarding screens share. Also states the window children's stacking outright.

## Validation status

Full evidence: `docs/validation/2026-08-16-windows-responsive-polish.md`.

**Passed, on the Windows review station:** Qt 6.9.3 / MSVC Release build;
`qmllint` exit 0 on all six changed QML files, warning categories unchanged from
the baseline; Recent and Library captured at all five target viewports,
composition identical, scales measuring 1.00 / 1.35 / 1.80 / 2.00 / 2.70;
Recent's left → centre → lock progression measured off the focus ring; every
fake-game preset, including the empty library, a partial final row, a long title
and a running game; onboarding mark and hint bar present.

One defect was introduced and fixed within the session: moving the window's
furniture inside the new frame reordered painting and left the hint bar under an
opaque screen. It was absent from the stage 1 and 2 screenshots shown to the
client and was not noticed at the time.

**Not established.** No controller was driven — no gamepad is attached, so every
state was reached through review hooks and the route's input path is unverified.
The transitions were not watched; the hook grabs settled frames only. Real box
art at a scaled resolution is untested, which is the case that would show
whether magnified artwork stays sharp. The three viewports above 1920×1080
exceed this display and were captured offscreen, which renders true geometry but
no layered effects. **No Deck ran** — deferred by client decision. macOS and the
WiX MSI were not built.

Earlier reports: `docs/validation/2026-08-15-frame-pacing-baseline.md`,
`docs/validation/2026-08-08-osk-diagnosis-and-resolution.md`.

## Open blockers

None. `BUGS.md` is empty.

## Next action

1. **Client review of the stage 7 redraw**, then merge and delete the branch.
2. **A controller walk** on Windows — needs a gamepad attached, and is the
   cheapest outstanding gap to close.
3. **A Deck session.** Nothing in this pass, or the frame-pacing work before it,
   has run on the target device.
4. **A real paired host**, for box art at a scaled resolution and for the rename
   panel and busy dots, which have never been seen on screen.
