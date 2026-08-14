---
kind: current-authority
authority: release-scope
read_when:
  - scope-or-sequencing-is-in-question
history_policy: replace-not-append
---

# Bulan — roadmap

## Current phase: core shell vertical slice

Bulan is replacing its inherited and first-generation QML architecture in
reviewable vertical slices. The current phase delivers one complete loop:

> responsive startup → remembered PC → Continue → full library → connection →
> stream → exact return

It also includes the minimal PC and game trays required to make every exposed
action real.

### Included

- Thin `BulanShell` over existing `ComputerModel`, `AppModel`, `Session` and
  `StreamingPreferences` APIs.
- Responsive wordmark, game-first home, alphabetical grid, offline recovery,
  minimal PC switcher and per-game menu.
- Screenshot-free artwork handoff, honest cancellation, failure, retry,
  quit-and-switch and session return.
- Stable identity across model reorder and isolated deterministic review data.
- Fraunces Semibold for new display headings.

### Compatibility routes

Existing discovery and pairing, Settings, advanced host management and all CLI
entry points remain reachable and behaviorally unchanged. Their UI may remain
legacy until its own migration slice.

### Explicitly excluded

- Rewriting discovery, pairing, wake, streaming or platform infrastructure.
- New persistence schemas, application identifiers, settings paths or upstream
  endpoints.
- A generic navigation framework, new visual dependency, stream overlay,
  sound, ambient motion or whole-application redesign in this phase.

## Exit conditions

1. Normal GUI startup does not instantiate the old host carousel or game view.
2. The complete core loop is controller-operable with recoverable focus.
3. New surfaces contain no stock visual controls, raw visual values, screenshot
   capture or production fake-data branches.
4. Host and game actions survive model reorder by carrying UUID/app ID.
5. Static checks, Windows Release build and relevant CI jobs pass.
6. Arrival, library motion, trays, artwork handoff, cancellation and return are
   reviewed in Steam Deck Game Mode. Blur survives only if smooth there.

## Later slices

1. First-run discovery and pairing.
2. Settings and About.
3. Advanced host management.
4. Remaining dialogs and inherited utility surfaces.
5. Optional sound, ambient motion and stream overlay after controller binding
   and hardware cost are proven.
