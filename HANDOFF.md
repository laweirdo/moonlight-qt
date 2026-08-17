---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 1b5fe61b
---

# Bulan — current state

**Verified 17 August 2026.** A snapshot — inspect Git before relying on it.
Replaced, never appended to; past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| Branch | **`polish-input-startup`**, five commits ahead of `master`. Not merged, **not pushed** |
| `master` | At `e05adf7b`, level with `origin/master` |
| Remote | `origin` only — `laweirdo/bulan-qt`. No push authorized since 16 August 2026 |
| Working tree | Clean apart from this file and the new validation report |
| Active task | **None.** The brief was deleted on acceptance of all three fixes |
| Other branches | `bulan` at `177a58bd`; `codex/rework-core-shell` excluded by client decision, 15 August 2026 |

## Where the product is

**Alpha v0.0.1**; `ROADMAP.md` owns scope and phase.

Everything in the 16 August merge still stands — see that day's commits and
`docs/validation/2026-08-16-windows-responsive-polish.md`.

On the task branch, three defects reported after that merge are fixed:

- `7a0123c4` — the d-pad, the analogue stick and the keyboard now share one
  hold contract: move, pause, repeat, release. Timing lives in a testable
  helper with no SDL or Qt in it; the stick gained hysteresis; held directions
  are tracked per controller; screen and mode changes release what is held and
  refuse input until the hardware returns to neutral.
- `462699ec` — the hint bar drops "Switch tab". The Recent/Library labels
  already carry the shoulder glyphs.
- `207894c7` — a remembered host's library is pushed without a transition and
  the carousel reveals underneath it, so launch no longer flashes a screen the
  player did not ask for. `FLOW.md` records the route semantics.
- `1b5fe61b` — defects found reviewing the three above. Chiefly: losing focus
  mid-hold could kill controller navigation outright, the release arriving on
  the next poll being discarded as stale input. Introduced by `7a0123c4`, fixed
  before merge.

## Validation status

Full evidence: `docs/validation/2026-08-16-controller-startup-polish.md`.

**Passed.** Release build; 12 repeat-clock unit tests; `qmllint` exit 0 on both
changed QML files, categories unchanged against `master`; the hint bar captured
on Recent and Library; a real launch reaching `Steambox`'s actual library, which
also settles real box art at a scaled resolution.

**Passed on hardware.** With a controller attached, the client walked the
hold-navigation matrix across the carousel, Recent, Library and Settings on both
the d-pad and the stick, plus the Settings-hold and disconnect-while-held
regressions.

**Not established.** The stage 3 live checks, the post-Settings A-button
regression and the focus-loss repro for `1b5fe61b` were not reported as
performed; the validation report lists them individually. **No Deck ran**, in
either mode — Game Mode is the larger gap, Steam Input sitting between the
hardware and the app there. Two controllers at once was never driven. Three of
the four startup cases were not run. macOS and the MSI were not built.

## Open blockers

None blocking. `BUGS.md` holds three open defects, two waiting on the client;
none of them is among the three fixed here.

## Next action

1. **The unconfirmed checks in the validation report** — chiefly A still working
   after Client Settings and after the Resolution dropdown, and **alt-tabbing
   away and back while holding the d-pad**, which is the repro for the defect
   `1b5fe61b` fixed. Cheapest thing outstanding, and the checklist calls losing
   A a stop-the-review failure.
2. **Merge `polish-input-startup` into `master`** once those pass, then delete
   the branch. No push is authorized.
3. **A Deck session.** Nothing in this pass, or the two before it, has run on
   the target device.
4. `FLOW.md` sits ~14 tokens below the point where `context-audit.py` fails.
   Trim it before adding anything.
