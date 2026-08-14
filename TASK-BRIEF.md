---
kind: active-task
authority: accepted-client-task
read_when:
  - active-task
history_policy: delete-on-acceptance
---

# Core shell vertical slice

## Goal

Replace normal GUI startup, the remembered-host library and the connection
handoff with a thin, polished Bulan shell while preserving Moonlight's backend
and explicit legacy compatibility routes.

## Accepted design

- Responsive wordmark, then the remembered PC's cached library.
- Host identity arrives once and settles into the header; games own the centre.
- Continue contains five recent titles and transforms downward into one
  alphabetical grid without navigating away.
- Offline startup retains the cached library with Wake, Retry and Switch PC.
- PC and game actions use centered reflection trays over the mounted library.
- Connection reuses the artwork URL in a shell-owned overlay; no screenshot
  capture. Cancel waits for real session cleanup before reversing.
- New display headings use Fraunces Semibold.

## Boundaries

Retain application identity, settings, discovery, pairing, wake, streaming,
CLI and platform behavior. Legacy Settings, pairing and advanced host management
remain reachable. Do not add a navigation framework, dependency, backend facade
or persistence schema.

## Delivery stages

1. Reset documentation authority.
2. Add typography, tokens and the shell foundation.
3. Build home and library.
4. Build PC and game trays.
5. Replace launch, cancellation and quit-and-switch choreography.
6. Isolate review fixtures, validate, then replace `HANDOFF.md`.

Show the client each stage after its checks and before its independent commit.
Never push without explicit authorization.

## Acceptance

- Controller-only core loop with stable focus and identity across reorder.
- No old carousel/game view on normal startup.
- No stock visual controls, raw product-screen values, `grabToImage` or fake
  branches in new production views.
- `qmllint`, context audit, Windows Release build and relevant CI pass.
- Final Steam Deck Game Mode review; blur is kept only if smooth.
