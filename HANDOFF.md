---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 686cda70
---

# Bulan — current state

**Verified 9 August 2026.** Inspect Git before relying on this — it is a
snapshot, not an authority on what Git says.

Replaced, never appended to. Past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| Branches | `master` and `bulan`, both at this session's tip. `master` is now the primary integration branch |
| Remote | `origin` only. **Nothing is pushed** — client decision, 9 August 2026. `origin/master` is still the old upstream mirror; `origin/bulan` is behind |
| Working tree | Clean |
| Task branch | None. `fix-deck-osk` was merged and is gone |
| Active task | **None.** No `TASK-BRIEF.md` exists |

**The branch model changed.** `master` was a pristine upstream mirror; it is now
Bulan's default branch, fast-forwarded to `bulan`, no history rewritten. `bulan`
is kept until the client retires it. `AGENTS.md` owns the rule.

## Where the product is

**Alpha v0.0.1.** The version the app reports is its own `0.0.1`, not the
inherited Moonlight `6.1.0`. `ROADMAP.md` owns scope and phase.

9 August 2026: entrances on `FirstRun`, `HostDiscovery` and `PairView` via a
shared `EntranceMotion.qml`; a shorter transition fade so travel leads; the
version identity; Bulan branding on display-only surfaces; a Bulan README. Then,
from a client review: Bulan's own app icon, built from
`app/res/bulan_app_icon.svg` by `scripts/gen-app-icon.*`; the carousel no longer
showing or sliding at startup, so launch goes straight to the last host's
library; and the library fading out as the artwork flies to the Connecting
screen.

## Validation status

**Passed, on the Windows review station:** Qt 6.9.3 / MSVC Release build;
`qmllint` on every changed QML file; the version flag, Win32 resource, window
title, About and embedded icon checked against the built binary; startup going
straight to the last host's library; the launch route reaching the Connecting
screen; `python scripts/context-audit.py`.

**Not established.** No Deck ran, so nothing was checked on hardware —
entrances, the shortened fade, the launch handoff and cold boot in Game Mode.
The macOS bundle and the WiX MSI were not built; their metadata is inspected
statically only, and `app/moonlight.icns` is still upstream's because icns needs
macOS tooling. The launch handoff's mid-flight frames were not captured, only
that it runs and lands. LCD appearance remains unvalidated.

Latest reports: `docs/validation/2026-08-08-osk-diagnosis-and-resolution.md`,
`docs/validation/2026-08-05-private-v1-deck.md`.

## Open blockers

None. `BUGS.md` is empty.

## Next action

1. **Push, once the client says so.** `master` and `bulan` are both ready.
2. **Rename the GitHub repository to `Bulan`**, with its description and default
   branch — a client action in repository settings. Documentation and package
   metadata already name the post-rename URL; GitHub redirects the old one.
3. **A Deck session** to see the new entrances and the transition on hardware,
   and an LCD unit for the remaining panel-appearance gap.
