# Task brief — tile-level busy state

**Opened:** 31 July 2026
**Branch:** `tile-busy-state`, cut from `bulan` at `351de13c`
**Roadmap item:** Phase B item 1, *Connecting state*, with the deferred wake
overlay from the 28 July client review (`SPEC-host-carousel.md:335`, item 4)
folded in by client decision.

This brief is temporary. It narrows the work; it does not override `AGENTS.md`,
`bulan-creative-brief.md`, `FLOW.md`, or `ROADMAP.md`.

## What the client approved

The circular host tile **dims**, and **three animated bouncing dots** are drawn
over the circle. No new screen, no full-screen overlay, no popup. One treatment
serves two cases:

- **Connecting** — pressing A on an online paired host while `AppView.qml` is
  built and pushed. Replaces the provisional `"Connecting…"` text-only state.
- **Waking** — A on an offline host, Y, or *Wake PC* in the host-settings
  overlay. Replaces the `HostPanel` popup the client rejected, and **resolves**:
  the tile stops when the host returns, or says it could not wake it.

Client decisions taken during planning:

| Decision | Answer |
|---|---|
| Scope | Carousel tile treatment only |
| Stream-launch screen (`StreamSegue.qml`) | **Out of scope.** Still stock Qt; remains a Phase B gap to raise after the game grid |
| Design source | Derived from the brief and existing tokens; approved on the Windows review build |
| Wake give-up time | 30 seconds |
| Dot size at neighbour scale | Dots shrink with the tile |

## Acceptance criteria

1. A busy tile dims its disc interior and shows three bouncing dots. The amber
   focus ring is **not** dimmed — focus must read identically in every state.
2. Busy state is keyed on host **UUID**, not carousel index, so a discovery
   reorder or the user navigating away cannot misattribute or lose it.
3. Waking resolves on the host coming back online, or fails after 30 seconds and
   reverts to the tile's normal offline copy without anything to dismiss.
4. Both wake call sites — `actWake()` and the host-settings *Wake PC* action —
   use the new state. Neither raises the old popup.
5. Left/Right navigation is never trapped. A and Y are no-ops on the busy host.
   B still reaches the root quit confirmation. B is deliberately **not** a
   cancel: a wake magic packet cannot be recalled.
6. The busy state is reviewable on the Windows fake-host build for both the
   success and the failure outcome.

## Out of scope

- `StreamSegue.qml` and anything in the stream launch path
- Any change to discovery, pairing, or streaming behaviour
- `BulanTokens.qml` (Figma review copy; these tokens are brief-derived)

## Stages

Committed one at a time, with a client review stop between each.

1. `Bulan.qml` — eight new tokens
2. `HostTile.qml` — dim, dots, `connecting` → `busyKind`, status copy
3. `HostCarousel.qml` — UUID-keyed busy state replacing `connectingIndex`
4. Wake feature: both call sites, resolver, timers
5. Input polish: busy no-ops, *Wake PC* suppressed, hint-bar
6. Fake-host review hooks
7. Documentation, `HANDOFF.md` last

## Close-out

Delete this file when the task is accepted and merged.
