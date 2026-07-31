# Bulan — roadmap

**Current as of:** 30 July 2026

**Owner:** Lao

**Current phase:** Phase B — Close the core loop

**Next milestone:** Finish the host-settings work order

This file governs v1 scope, phase order, exit conditions, and the next
milestone. It does not govern live repository state (`HANDOFF.md`), the active
work order (`TASK-BRIEF.md`), navigation edges (`FLOW.md`), or screen-level
implementation decisions (`SPEC-*.md`).

## Definition of v1

> **A complete, unembarrassing loop from cold launch to streaming and back, on
> a Steam Deck, with no screen along the way that still looks like upstream
> Moonlight.**

The test is a first-time user on a fresh install: they should never hit a screen
that breaks the spell. Anything encountered on the way to a game is v1.
Improvements to an already coherent loop are v1.x.

Private v1 targets both Steam Deck models: the 7-inch LCD and 7.4-inch OLED.
OLED hardware has been used for visual validation. LCD visual validation is
deferred until hardware is available and does not block private v1.

Private v1 is not a public release.

## Scope decisions

| Area | v1 decision |
|---|---|
| Technical foundation | Retain upstream discovery, pairing, streaming, and platform infrastructure. Replace individual UI components only when the approved design justifies it. |
| Host libraries | Keep a separate library for each host. A merged multi-host library may be reconsidered after v1. |
| Onboarding | Include the designed first-run path and manual-address escape hatch. |
| Settings | Provide a Bulan shell and usable spatial controller navigation. A full re-architecture of every setting is not required. |
| Stream overlay | Defer Bulan's proposed overlay until its summon binding can be checked against real games. Retain upstream streaming infrastructure. |
| Splash | Ship a static splash; animation is v1.x. |
| Sound and ambient motion | v1.x. They are differentiators, not dependencies for closing the loop. |
| Custom Steam Deck glyph art | Not required for v1 because the practical shapes are identical to the current XInput glyphs. |
| Mascot | Deferred beyond v1. |
| HDR and non-Deck product targets | Out of scope. |

The creative brief's deliverables remain the long-term creative list and a guide
when a visual decision is stuck. They do not all define private-v1 scope.

## Distribution

Private v1 is for Lao and a handful of people, installed by hand as a non-Steam
game through Flatpak.

- The app must carry its licence and a clear “Built on Moonlight” credit. A
  simple About treatment is sufficient for private v1.
- The app icon and Steam artwork are v1 because the non-Steam library entry
  should not look unfinished.
- Public-facing release preparation, a full brand rules sheet, and broader
  contributor guidance are later work.
- The root README keeps its upstream content. A concise Bulan-fork notice is
  documentation orientation, not public-release marketing.

Public release is a v2 decision.

## Milestones

### Phase A — Stabilise — completed 28 July 2026

The first known-good `bulan` baseline was established after controller, wake,
Game Mode, and visual checks on available hardware. The upstream sync policy,
review checklist, build procedures, and design sources were recorded.

The OLED review settled the live values below:

| Token | Validated value |
|---|---|
| `atmosphereGrainOpacity` | `0.03` |
| `sizeCaption` | `16` |
| `motionOvershoot` | `0.7` |
| `motionFocusMs` | `180` |

The first three values were confirmed; `motionFocusMs` deliberately evolved
from the brief's original `140` after hardware review.

**Exit:** met. The integration baseline existed, the original stabilization
defects were resolved and checked, and the global tokens were judged on a real
OLED Steam Deck.

### Phase B — Close the core loop — current

The accepted carousel rebuild is the completed Phase B milestone. Its durable
design and engineering reasoning is in `SPEC-host-carousel.md`.

Remaining work, in order:

1. **Finish the host-settings work order** — host-label spacing and the
   controller-first host overlay are merged. Repair and validate the inherited
   startup toolbar next; `TASK-BRIEF.md` remains the active work order and
   `BUGS.md` owns the defect.
2. **Connecting state** — replace the placeholder with the approved experience.
3. **Game grid** — Recent and Library views.
4. **Game detail and launch** — follow the navigation authority in `FLOW.md`.
5. **Screen transitions** — wire the existing 220 ms transition token into the
   completed core route.

The host-settings work order also includes the startup-toolbar defect because
the fix must preserve inherited toolbars. That defect is tracked in `BUGS.md`.

**Exit:** launch → pick host → pick game → stream → return, with no screen in
the user journey that still reads as upstream Moonlight.

### Phase C — First run

- Static splash
- “Let's find your PC”
- “Looking for your PC”
- PIN entry
- Manual IP entry, including deliberate Steam on-screen-keyboard handling
- First-run routing and the post-pairing destination

The reflected-moon mark is superseded. The horizontal corner wordmark is final
for that role, but it must not be enlarged or recomposed for centred-logo
screens. Existing onboarding boards remain useful for content and copy; their
centred treatment depends on vector assets designed and supplied by the client.

**Exit:** a first-time user can discover or enter a host, pair, and arrive in
the normal loop without encountering an upstream screen.

### Phase D — Edges

- Couldn't reach PC
- Couldn't start stream
- Empty library for a paired host
- Zero hosts
- Waking PC waiting overlay, held until success or failure
- Quit and disconnect confirmation

**Exit:** every reachable failure or empty state has a designed, controller-safe
route back to the loop.

### Phase E — Settings and About

- Settings in a Bulan shell using custom components
- D-pad navigation that follows the visual layout
- Controls for the existing atmosphere-effect flags
- About with the Moonlight credit

**Exit:** required settings and legal attribution are reachable and usable
without a mouse.

### Phase F — Ship private v1

- App icon in required sizes
- Steam Deck artwork set
- Flatpak installs cleanly
- Full `REVIEW-CHECKLIST.md` pass on available Deck hardware
- Creative brief reconciled with deliberate evolution clearly labelled

**Exit:** the private build installs, presents correctly in Steam, completes the
full loop, and has an honest validation record.

## After private v1

Ordered by expected value, not effort:

1. Host-menu parity: Rename PC, deferred from private v1 for Deck keyboard work.
   Test Network was initially deferred with it, then restored to private-v1
   scope by the client on 31 July 2026.
2. Sound pack
3. Boot animation
4. Ambient background motion
5. Stream overlay, if hardware validation shows Bulan needs one
6. Merged multi-host library, if separate libraries prove awkward in use
7. Public-release preparation

## Standing risks

- **Startup toolbar:** changing its visible-by-default behavior is small in code
  but can silently remove navigation from inherited screens. The active task
  requires checking every screen that should retain it.
- **Manual address entry:** the onboarding escape hatch still needs a design
  that works with Steam's on-screen keyboard in Game Mode.
- **Stream overlay input:** `Start+Select` remains an unvalidated proposed
  binding. The Bulan overlay is deferred rather than allowed to block v1.
- **LCD appearance:** LCD-specific visual validation remains outstanding until
  hardware is available. It does not block private v1, but must not be reported
  as passed.

Retired risks and their reusable lessons belong in
`docs/retrospectives/DEBUGGING-LESSONS.md`, not in the active roadmap. Detailed
carousel decisions remain in `SPEC-host-carousel.md`.
