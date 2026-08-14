---
kind: decision-log
authority: historical-evidence
status: living
read_when:
  - investigating-why-a-decision-was-taken
history_policy: append-only
---

# Bulan — decision log

**Provenance, not authority.** Each entry records what the client decided, when,
and what it replaced. The current answer always lives in the owning document —
this file explains how it got there.

Append new entries at the top of the dated section. Do not edit a past entry
except to add the document that now owns its outcome.

## Dated decisions

### 3 August 2026

| Decision | Replaced | Now owned by |
|---|---|---|
| **The private v1 draft is accepted.** Reviewed live in two rounds on a Windows review station | — | `ROADMAP.md`, `docs/validation/2026-08-03-private-v1-draft.md` |

Acceptance is of a draft that runs correctly on Windows. It is explicitly not a
statement about the Steam Deck, a real stream, a physical controller, or a
Flatpak.

### 2 August 2026

| Decision | Replaced | Now owned by |
|---|---|---|
| **The screen transition carries a real runtime blur**, and its performance cost is accepted knowingly, with the Deck measurement deferred until after private v1 | Opacity falling away during travel — the inexpensive reading of the brief's "slight motion blur" | `DESIGN-SYSTEM.md` |
| **Game tiles rise from below on a staggered cascade** | A horizontal slide into ranked position, which the client saw as "swiping in from the side, way too quickly" | `FLOW.md`, `docs/history/2026-08-14-pre-clean-slate/SPEC-game-grid.md` |
| **The hint bar holds still while the screen moves.** It belongs to the window, not to a screen | Screen-level hint bars that travelled with their screen | `FLOW.md` |
| **Screen entry is transition first, then a staggered element entrance**, with a slight overshoot and one soft bounce | Ad-hoc per-screen entrance motion | `DESIGN-SYSTEM.md` |
| **220 ms and a 64 px rise are kept** after seeing the transition live | — | `DESIGN-SYSTEM.md` |
| **X opens Game Options, and that is its intended private-v1 destination** | A separate game detail screen, drawn on the flow board | `FLOW.md`, `docs/history/2026-08-14-pre-clean-slate/SPEC-game-grid.md` |
| **SELECT on the game grid opens the existing Host Settings overlay** | Dropping the mockup's *SELECT Host Settings* hint | `FLOW.md` |
| **Steam library artwork is not a Bulan deliverable.** Game artwork comes from the host PC | Deliverable 3: capsule, wide capsule, hero, transparent logo PNG | `ROADMAP.md`, `docs/design-rationale/creative-history.md` |

### 1 August 2026

| Decision | Replaced | Now owned by |
|---|---|---|
| **The host tile busy state is accepted** after a hardware gamepad review | — | `docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md` |
| **The game grid is accepted**, after a review that produced four changes | — | `docs/history/2026-08-14-pre-clean-slate/SPEC-game-grid.md` |

### 31 July 2026

| Decision | Replaced | Now owned by |
|---|---|---|
| **Wake resolves on the host tile** — a dimmed disc and three bouncing dots, resolving on the host reporting online or on a 30-second give-up | A waiting overlay held until success or failure. Decided before anything was built, not after | `FLOW.md`, `docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md` |
| **Test Network is restored to private-v1 scope** | Its earlier deferral alongside Rename PC | `ROADMAP.md` |

### 30 July 2026

| Decision | Replaced | Now owned by |
|---|---|---|
| **The reflected-moon mark is superseded** and must not be used as the assumed solution for new screens or artwork | Direction A as the lead mark | `bulan-creative-brief.md`, `docs/design-rationale/creative-history.md` |
| **The horizontal corner wordmark is final for its role** and must not be redesigned, substituted, enlarged, or recomposed into a centred mark | — | `bulan-creative-brief.md` |
| **Centred-logo screens wait on client-supplied vectors** | Inferring a centred treatment from the corner wordmark | `bulan-creative-brief.md` |
| **Custom Steam Deck glyph vectors are not required for private v1** — their practical shapes are identical to the accepted XInput set | Deliverable 7's Deck glyph art as a v1 requirement | `ROADMAP.md`, `bulan-creative-brief.md` |
| **Both Deck panels remain targets; LCD visual validation is deferred** until hardware is available and does not block private v1 | — | `ROADMAP.md`, `DESIGN-SYSTEM.md` |

### 28 July 2026

| Decision | Replaced | Now owned by |
|---|---|---|
| **`motionFocusMs` moves from 140 to 180 ms** after the OLED review | The brief's original `140 ms` | `DESIGN-SYSTEM.md` |
| **`atmosphereGrainOpacity` 0.03, `sizeCaption` 16, and `motionOvershoot` 0.7 are confirmed** on OLED hardware | — | `DESIGN-SYSTEM.md` |
| **The hint bar reflow when Y Wake appears and disappears is accepted as built** | Greying Y out, or keeping Y and relabelling it | `docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md` |

Evidence: `docs/validation/2026-07-28-deck-oled-review.md`.

## Standing decisions from the original brief

Undated — they predate the dated log and remain in force.

| Decision | Now owned by |
|---|---|
| **Custom components throughout.** No stock Qt Quick Controls styling in a Bulan screen | `AGENTS.md` |
| **No true black.** Depth comes from gradient, grain, glow, and blur | `DESIGN-SYSTEM.md` |
| **The mascot is deferred past v1.** The primary mark should leave room for one without depending on it | `ROADMAP.md` |
| **Retain upstream discovery, pairing, streaming, and platform infrastructure.** Replace UI components only where the approved design justifies it | `ROADMAP.md`, `bulan-creative-brief.md` |
| **Separate libraries per host for v1.** A merged multi-host library is reconsidered only if the separate model proves awkward | `ROADMAP.md`, `FLOW.md` |
| **The Bulan stream overlay is deferred** until `Start+Select` can be validated against real games | `ROADMAP.md`, `FLOW.md` |
