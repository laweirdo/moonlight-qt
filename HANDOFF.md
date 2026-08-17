---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: f314ae84
---

# Bulan — current state

**Verified 17 August 2026.** A snapshot — inspect Git before relying on it.
Replaced, never appended to; past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| `master` | At `f314ae84`, **pushed and level with `origin/master`** |
| Task branch | None. `polish-input-startup` merged fast-forward 17 August 2026 on client sign-off, then deleted; never pushed |
| Remote | `origin` only — `laweirdo/bulan-qt`. Pushed 17 August 2026 on client authorization |
| Working tree | Clean apart from this file |
| Active task | **None.** The brief was deleted on acceptance of all three fixes |
| Other branches | `bulan` at `177a58bd`; `codex/rework-core-shell` excluded by client decision, 15 August 2026 |

## Where the product is

**Alpha v0.0.1**; `ROADMAP.md` owns scope and phase.

Everything in the 16 August merge still stands — see that day's commits and
`docs/validation/2026-08-16-windows-responsive-polish.md`.

Merged 17 August 2026, fixing three defects reported after that merge:

- `7a0123c4` — d-pad, stick and keyboard share one hold contract: move, pause,
  repeat, release. Timing lives in a testable helper with no SDL or Qt in it;
  the stick gained hysteresis; held directions are tracked per controller; and
  screen or mode changes release what is held, refusing input until the hardware
  returns to neutral.
- `462699ec` — the hint bar drops "Switch tab"; the tab labels already carry the
  shoulder glyphs.
- `207894c7` — a remembered host's library is pushed without a transition and
  the carousel reveals underneath it. `FLOW.md` records the route semantics.
- `1b5fe61b` — defects found reviewing the three above. Chiefly: losing focus
  mid-hold could kill controller navigation outright, the release arriving on
  the next poll being discarded as stale input. Introduced by `7a0123c4`.

## Validation status

Full evidence: `docs/validation/2026-08-16-controller-startup-polish.md`.

**Passed.** Release build; 12 repeat-clock unit tests; `qmllint` exit 0 on both
changed QML files, categories unchanged against `master`; the hint bar captured
on Recent and Library; a real launch reaching `Steambox`'s actual library, which
also settles real box art at a scaled resolution.

**Passed on hardware.** The client walked the hold-navigation matrix across the
carousel, Recent, Library and Settings on both the d-pad and the stick, plus the
Settings-hold and disconnect-while-held regressions — and, against the merged
build, the four pre-merge checks: the focus-loss repro for `1b5fe61b`, A after
Client Settings, A after the Resolution dropdown, and a held direction repeating.

A portable package built from `f314ae84` launched with no Qt on `PATH` and
exited 0; the certificate and caches that run wrote were deleted.

**Not established.** The stage 3 startup checks were never separately reported.
**No Deck ran**, in either mode. Two controllers at once was never driven. Three
of the four startup cases were not run. macOS and the MSI were not built.

## Open blockers

None blocking. `BUGS.md` holds three open defects, two waiting on the client;
none of them is among the three fixed here.

## Next action

1. **A Deck session**, in Desktop and Game Mode. Nothing in this pass, or the
   two before it, has run on the target device, and Game Mode is where Steam
   Input sits between the hardware and the application.
2. **The three unrun startup cases** — remembered host offline, remembered UUID
   gone, no remembered host. Each needs the review station's stored preferences
   changed, which no session has been willing to do casually.
3. **Two controllers at once**, the case the per-controller held-direction
   tracking exists for and the only part of it never driven by real hardware.
4. `FLOW.md` sits ~14 tokens below the point where `context-audit.py` fails.
   Trim it before adding anything.
