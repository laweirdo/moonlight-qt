---
kind: active-task
authority: accepted-client-task
read_when:
  - active-task
history_policy: delete-on-acceptance
---

# Polish audit and Bulan layer rework

## State

**The implementation is merged to `master` (16 August 2026) and the task branch
is gone.** This brief stays open because the task is not accepted: nothing in it
has run on a Steam Deck, and the client owes the copy and the decisions listed
below. It is the shortest honest record of what is still outstanding; delete it
once a Deck session closes the validation gap and those decisions are made.

## Objective

Make Bulan hold 60 fps, make its motion correct and interruptible, and reduce
the Bulan layer to one shell, one popup mechanism, one hint-bar model and one
motion contract — before any screen is redrawn.

## Accepted design

The client accepted the staged plan on 15 August 2026. Stages, each its own
commit, shown to the client before the next begins:

1. **Measure the frame rate.** Name the cause before changing code.
   **Done, 15 August 2026** — `docs/validation/2026-08-15-frame-pacing-baseline.md`.
   Throughput is not the problem on Windows; frame *pacing* is, and the overdraw
   hazards cost nothing measurable on that GPU. Stages reordered by the client
   on that result: motion correctness first, overdraw later.
2. **One motion contract.** Binding-vs-animation conflicts, one `BusyDots`,
   entrances driven by the transition rather than a timer, `settleEntrance()`
   everywhere, token durations and explicit easing.
3. **Delete the legacy shell.** After a Settings parity check reported to the
   client: `SettingsView.qml`, `PcView.qml`, the toolbar and everything only they
   keep alive.
4. **Remove the overdraw hazards.** `GameTile` per-tile layers, nine duplicate
   `Atmosphere` instances, per-focus-move layer churn. Deferred behind the stages
   above because no measurement on this hardware justifies them; the Deck may
   still. Re-measure when a Deck exists.
5. **One shell architecture.** `BulanPopup` base, single hint-bar model, one
   capture pipeline, `AppView.qml` split, fixtures out of production files.
6. **Design-system cohesion.** `FocusRing`/`FocusBloom`, dead tokens, the
   `lineHeight` ramp decision, `BulanTokens.qml` resolution, docs updated.
7. **Mockups, then redraw.** Client gate. No layout code before the client picks
   a direction.

Full plan and the audit it rests on:
`C:\Users\faris\.claude\plans\superpowers-brainstorming-design-ponyta-glittery-patterson.md`

## Boundaries

Retain discovery, pairing, wake, streaming, CLI and platform behavior. No
navigation framework, no new dependency, no persistence-schema change, no
identifier rename for branding. `codex/rework-core-shell` is excluded by client
decision and is not a source.

Layout, spacing and composition are stage 7 and are the client's call.

## Verified state at task start

Branch `polish-and-shell-rework`, cut from `master` at `177a58bd`, working tree
clean. `master` and `bulan` are both at that commit.

## Accepted redraw direction

**Direction B, "Shelf", client decision 15 August 2026.** The Recent row starts
at the screen margin and runs off the right edge instead of being centred with a
permanent void down the left third, and its metadata left-aligns under the
focused tile rather than centring under the row. The navigation model is
unchanged — focus stays a ring that moves — which is why this was chosen over
the "Hero" alternative, which would have redefined Left/Right.

Mockups are in the client's `Bulan` design project on claude.ai/design, under
Screens. They render in fallback faces, not Fraunces and Inter.

## Copy the client owes

The four configuration warnings in `main.qml` and the CLI routes' messages are
upstream's words, unchanged, and they name XWayland, `QT_QPA_PLATFORM`, and
"hardware accelerated video decoder" on front-facing screens — which
`bulan-creative-brief.md` §5 forbids. They were converted to Bulan panels
without touching the text, by client decision on 15 August 2026: the client
writes the replacements. The confirm and dismiss wording on those panels is the
same decision.

## Design questions raised, awaiting the client

Recorded here, not in `DESIGN-SYSTEM.md`, because each needs a decision before it
can become a rule.

- **The line-height ramp is not shipping.** Four `lineHeight*` tokens exist and
  no screen binds `Text.lineHeight`. Wiring it in changes vertical rhythm on
  every screen; the alternative is dropping the tokens. A typography call, so it
  belongs with the redraw review.
- **`BulanTokens.qml` disagrees with the runtime.** The proof sheet's copy claims
  to be the source of truth and draws body and caption a weight lighter than the
  app does. It should read the singleton or stop existing.
- **There is no d-pad glyph.** `ControllerGlyph` covers face buttons, shoulders,
  triggers and start/select, so a Left/Right action cannot be hinted — the slider
  popup shows only its back hint because of it.

## Acceptance

- A measured frame-rate improvement recorded in `docs/validation/`, not an
  impression.
- No screen entrance that plays under a screen transition, and none that input
  cannot settle.
- One popup mechanism, one hint-bar owner, no stock visual control in a Bulan
  screen.
- `qmllint` on every changed QML file, a Windows Release build, a full
  controller walk of the route, `python scripts/context-audit.py`.
- Steam Deck hardware, Game Mode and LCD appearance are **not** available this
  session and will be reported as unchecked.
