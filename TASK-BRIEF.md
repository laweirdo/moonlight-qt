---
kind: active-task
authority: accepted-client-task
read_when:
  - active-task
history_policy: delete-on-acceptance
---

# Polish audit and Bulan layer rework

## State

**Stages 1–6 are merged to `master` (16 August 2026).** Stage 7, the redraw, is
under way on the task branch `responsive-game-surface`: three commits carrying
the responsive design frame, Recent's progressive centre, and the shared
onboarding mark. Not merged, not pushed.

This brief stays open because the task is not accepted: nothing in it has run on
a Steam Deck, no controller has been driven, and the client owes the copy listed
below. It is the shortest honest record of what is still outstanding; delete it
once those gaps close.

## Objective

Make Bulan hold 60 fps, make its motion correct and interruptible, and reduce
the Bulan layer to one shell, one popup mechanism, one hint-bar model and one
motion contract — before any screen is redrawn.

## Accepted design

The client accepted the staged plan on 15 August 2026. Stages, each its own
commit, shown to the client before the next begins:

1. **Measure the frame rate.** **Done, 15 August 2026** —
   `docs/validation/2026-08-15-frame-pacing-baseline.md`. Throughput is not the
   problem on Windows; frame *pacing* is, and the overdraw hazards cost nothing
   measurable on that GPU. Stages reordered on that result: motion correctness
   first, overdraw later. **Stages 2, 3, 5 and 6 are merged.**
2. **One motion contract.** Binding-vs-animation conflicts, one `BusyDots`,
   entrances driven by the transition, `settleEntrance()` everywhere.
3. **Delete the legacy shell.** `SettingsView.qml`, `PcView.qml`, the toolbar
   and everything only they keep alive.
4. **Remove the overdraw hazards.** Per-tile layers, duplicate `Atmosphere`
   instances, per-focus-move layer churn. **Still deferred** — no measurement on
   this hardware justifies them; re-measure when a Deck exists.
5. **One shell architecture.** `BulanPopup` base, one hint-bar model, one
   capture pipeline, `AppView.qml` split, fixtures out of production files.
6. **Design-system cohesion.** `FocusRing`/`FocusBloom`, dead tokens, the
   `lineHeight` ramp decision, `BulanTokens.qml` resolution.
7. **Mockups, then redraw.** Client gate. **Under way** — see below.

Full plan and its audit:
`C:\Users\faris\.claude\plans\superpowers-brainstorming-design-ponyta-glittery-patterson.md`

## Boundaries

Retain discovery, pairing, wake, streaming, CLI and platform behavior. No
navigation framework, no new dependency, no persistence-schema change, no
identifier rename for branding. `codex/rework-core-shell` is not a source.
Layout, spacing and composition are stage 7 and the client's call.

## Verified state at task start

Branch `polish-and-shell-rework`, cut from `master` at `177a58bd`, working tree
clean. `master` and `bulan` are both at that commit.

## Accepted redraw direction

**Client decisions, 16 August 2026**, taken against the deployed Windows build.
They replace Direction B's left-anchored shelf with metadata under the focus.
`SPEC-game-grid.md`, `DESIGN-SYSTEM.md` and `FLOW.md` own the durable form.

- **1280×800 is the canonical composition, not the only viewport.** The whole
  application is laid out at that size and scaled proportionally. No
  breakpoints, no re-flow, five Library columns everywhere.
- **Recent starts left, walks to the centre, then locks**, drawing every game
  that touches the screen so the row reads as one queue.
- **No text below artwork.** The name survives inside the missing-art fallback.
- **The onboarding crescent crosses first run → discovery as one sharp object**,
  while the rest of both screens takes the ordinary blur and fade.
- **Windows fit-and-finish first; Deck, Game Mode and performance are deferred**
  until it is accepted — deferred, not failed.

The navigation model is unchanged: focus stays a ring that moves, which is why
Direction B was chosen over "Hero", which would have redefined Left/Right.

Mockups are in the client's `Bulan` design project on claude.ai/design, under
Screens. They render in fallback faces, not Fraunces and Inter. Evidence:
`docs/validation/2026-08-16-windows-responsive-polish.md`.

## Copy the client owes

The four configuration warnings in `main.qml` and the CLI routes' messages are
upstream's words, naming XWayland, `QT_QPA_PLATFORM` and "hardware accelerated
video decoder" on front-facing screens — which `bulan-creative-brief.md` §5
forbids. Converted to Bulan panels without touching the text, by client decision
on 15 August 2026: the client writes the replacements, and the confirm and
dismiss wording with them.

## Design questions raised, awaiting the client

Recorded here, not in `DESIGN-SYSTEM.md`, because each needs a decision before it
can become a rule.

- **The line-height ramp is not shipping.** Four `lineHeight*` tokens exist and
  no screen binds `Text.lineHeight`. Wiring it in changes vertical rhythm
  everywhere; the alternative is dropping the tokens. A typography call.
- **`BulanTokens.qml` disagrees with the runtime.** The proof sheet claims to be
  the source of truth and draws body and caption a weight lighter than the app
  does. It should read the singleton or stop existing.
- **There is no d-pad glyph.** `ControllerGlyph` covers face buttons, shoulders,
  triggers and start/select, so a Left/Right action cannot be hinted — which is
  why the slider popup shows only its back hint.

## Acceptance

- A measured frame-rate improvement recorded in `docs/validation/`, not an
  impression.
- No screen entrance that plays under a screen transition, and none that input
  cannot settle.
- One popup mechanism, one hint-bar owner, no stock visual control in a Bulan
  screen.
- `qmllint` on every changed QML file, a Windows Release build, a full
  controller walk of the route, `python scripts/context-audit.py`.
- Steam Deck hardware, Game Mode and LCD appearance are **not** available and
  are reported as unchecked. Deferred by client decision until the Windows
  fit-and-finish is accepted.

The controller walk is **still outstanding**: no gamepad is attached to the
Windows review station, so nothing on the game surface or the onboarding route
has been driven by a real press. See the 16 August 2026 validation report.
