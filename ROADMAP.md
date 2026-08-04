---
kind: current-authority
authority: release-scope
read_when:
  - scope-or-sequencing-is-in-question
history_policy: replace-not-append
---

# Bulan — roadmap

**Current as of:** 4 August 2026 · **Owner:** Lao

**Current phase:** F — ship private v1. **Every phase is built.** What remains
is not implementation: it is the target-device validation that cannot happen off
a Steam Deck.

**Next milestone:** a Steam Deck session. See `HANDOFF.md` for the exact next
action.

This file governs v1 scope, phase order, exit conditions, and sequencing. It
does not govern live repository state (`HANDOFF.md`), navigation edges
(`FLOW.md`), design values (`DESIGN-SYSTEM.md`), or screen-level implementation
(`SPEC-*.md`).

## Definition of v1

> **A complete, unembarrassing loop from cold launch to streaming and back, on a
> Steam Deck, with no screen along the way that still looks like upstream
> Moonlight.**

The test is a first-time user on a fresh install: they should never hit a screen
that breaks the spell. Anything encountered on the way to a game is v1.
Improvements to an already coherent loop are v1.x.

Private v1 targets both Steam Deck models, the 7-inch LCD and the 7.4-inch OLED.
OLED hardware has been used for visual validation; LCD validation is deferred
until hardware is available and does not block private v1.

**Private v1 is not a public release.** Public release is a v2 decision.

## Scope decisions

| Area | v1 decision |
|---|---|
| Technical foundation | Retain upstream discovery, pairing, streaming, and platform infrastructure. Replace individual UI components only when the approved design justifies it |
| Host libraries | Keep a separate library per host. A merged multi-host library may be reconsidered after v1 |
| Onboarding | Include the designed first-run path and the manual-address escape hatch |
| Settings | A Bulan shell with usable spatial controller navigation. A full re-architecture of every setting is not required |
| Stream overlay | Deferred until its summon binding can be checked against real games. Retain upstream streaming infrastructure |
| Splash | Static. Animation is v1.x |
| Sound and ambient motion | v1.x. Differentiators, not dependencies for closing the loop |
| Custom Steam Deck glyph art | Not required — the practical shapes are identical to the current XInput glyphs |
| Mascot | Deferred beyond v1 |
| HDR and non-Deck targets | Out of scope |

The creative brief's deliverables are the long-term creative list, not the
private-v1 scope.

## Distribution

Private v1 is for Lao and a handful of people, installed by hand as a non-Steam
game through Flatpak.

- The app must carry its licence and a clear "Built on Moonlight" credit. A
  simple About treatment is sufficient.
- The app icon is v1, because the non-Steam application entry should not look
  unfinished. **Steam library artwork is not a Bulan deliverable** — client
  decision, 2 August 2026. Game artwork comes from the host PC.
- Public-facing release preparation, a full brand rules sheet, and broader
  contributor guidance are later work.
- The root README keeps its upstream content. A concise Bulan-fork notice is
  documentation orientation, not marketing.

## Phase F — remaining exit criteria

Nothing here is implementation. Each item is a check that has not been made.

| Criterion | State |
|---|---|
| A full `REVIEW-CHECKLIST.md` pass on Deck hardware | **Not done.** No Deck session since 28 July 2026 |
| Real pairing against a live host | **Not done** |
| A real stream launched, resumed, failed, and quit | **Not done** |
| Physical controller review of the whole route | **Not done** |
| Steam Game Mode on-screen keyboard on the manual-address field | **Unvalidated**, and the field cannot work without it |
| Flatpak builds and installs cleanly | **Not attempted** — the review station is Windows |
| Screen-transition blur cost measured on the Deck | **Deliberately deferred** by the client |
| The open Language defect | **Open**, awaiting a client reproduction — see `BUGS.md` |

**Exit:** the private build installs, presents correctly in Steam, completes the
full loop, and has an honest validation record.

## Completed phases

| Phase | Closed | Evidence |
|---|---|---|
| A — Stabilise | 28 July 2026 | `docs/validation/2026-07-28-deck-oled-review.md` |
| B — Close the core loop | 2 August 2026 | `docs/validation/2026-08-02-phase-b-closeout.md`, `SPEC-host-carousel.md`, `SPEC-game-grid.md` |
| C — First run | 3 August 2026 | `docs/validation/2026-08-03-private-v1-draft.md` |
| D — Edges | 3 August 2026 | `docs/validation/2026-08-03-private-v1-draft.md` |
| E — Settings and About | 3 August 2026 | `docs/validation/2026-08-03-private-v1-draft.md` |

What each phase actually built is in `docs/history/private-v1-build-record.md`.

The complete v1 draft — cold launch through first run, pairing, host selection,
game selection, launch, quit and return — was reviewed live by the client in two
rounds and accepted on 3 August 2026. No screen on that route still reads as
upstream Moonlight. **Accepted is not validated:** the table above is what
"validated" would require.

## After private v1

Ordered by expected value, not effort:

1. Host-menu parity: **Rename PC**, deferred from private v1 pending Deck
   keyboard work. Test Network was deferred with it, then restored to private-v1
   scope by the client on 31 July 2026.
2. Sound pack
3. Boot animation
4. Ambient background motion
5. Stream overlay, if hardware validation shows Bulan needs one
6. Merged multi-host library, if separate libraries prove awkward in use
7. Public-release preparation

The client mentioned possibly revisiting the screen transition to push it
further toward the brief's "whimsical" character. Unscheduled.

## Standing risks

- **Manual address entry.** The onboarding escape hatch still needs a design
  that works with Steam's on-screen keyboard in Game Mode.
- **Stream overlay input.** `Start+Select` remains an unvalidated proposed
  binding. The Bulan overlay is deferred rather than allowed to block v1.
- **LCD appearance.** LCD-specific visual validation is outstanding until
  hardware is available. It does not block private v1, but must never be
  reported as passed.
- **Everything built since 28 July 2026 is unseen on the target device.** The
  whole current route has only ever run on a Windows review station.

Retired risks and their reusable lessons are in
`docs/retrospectives/DEBUGGING-LESSONS.md`.
