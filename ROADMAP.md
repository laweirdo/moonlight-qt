# Bulan — roadmap

**Current as of:** 2 August 2026

**Owner:** Lao

**Current phase:** Phase F — Ship private v1. **Every phase is built.** What
remains is not implementation: a client review of the whole route, and the
target-device validation that cannot happen off a Steam Deck.

**Next milestone:** a Steam Deck session. The private v1 draft was accepted by the client on 3 August 2026 and merged into `bulan`.

**A complete v1 draft exists and is accepted.** The route from cold launch
through first run, pairing, host selection, game selection, launch, quit and
return is built, and no screen along it still reads as upstream Moonlight.
Phases C, D and E and the app icon were built on 3 August 2026, reviewed live
by the client in two rounds, and merged into `bulan`.

**Accepted is not validated.** Steam Deck, real-stream, physical-controller,
real-pairing, Steam on-screen-keyboard and Flatpak validation are all
outstanding, and the transition blur's cost on the Deck is still deliberately
unmeasured. One client-reported defect — opening the Language list — could not
be reproduced and remains open in `BUGS.md`. See `HANDOFF.md` for the honest
list.

This file governs v1 scope, phase order, exit conditions, and the next
milestone. It does not govern live repository state (`HANDOFF.md`), an active
work order (`TASK-BRIEF.md`, when one exists), navigation edges (`FLOW.md`), or
screen-level implementation decisions (`SPEC-*.md`).

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
- The app icon is v1 because the non-Steam application entry should not look
  unfinished. **Steam library artwork is not a Bulan deliverable** — client
  decision, 2 August 2026. Game artwork comes from the host PC.
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

The host-settings work order is complete: the label spacing, controller-first
host overlay, and startup-toolbar boundary were accepted and validated. The
separate root-carousel quit confirmation follow-up is also complete: root
B/Escape now opens a custom Bulan glass confirmation that passed Windows XInput
controller review.

Remaining work, in order:

1. ~~**Connecting state** — replace the placeholder with the approved
   experience.~~ **Done 31 July 2026, accepted 1 August 2026** after a hardware
   gamepad review on the Windows review station. Built as one designed
   tile-level busy state shared with waking (Phase D's *Waking PC waiting
   overlay*, pulled forward — see below). Durable design and the limits of that
   review are in `SPEC-host-carousel.md`. No Deck validation yet.
2. ~~**Game grid** — Recent and Library views.~~ **Done 1 August 2026**, after a
   client review on the Windows review station that produced four changes and
   then the merge. Durable design in `SPEC-game-grid.md`. No Deck validation.
   Three things about it are worth carrying forward:
   - The app now records **when each game was last played**, per host, so
     Recent has something real to sort by. That is an additive client-side
     attribute on `NvApp`, following `hidden` and `directLaunch`.
   - **The shoulder buttons had no keycode at all**, on any screen, until this
     task. L1/R1 now reach QML.
   - **X opens a per-game options popup as its intended private-v1
     destination.** It is not a temporary stand-in. No Game Detail screen is
     planned. See `FLOW.md` and `SPEC-game-grid.md` for the corrected decision.
3. ~~**Launch and quit experience** — replace both stock surfaces.~~ **Done and
   accepted 2 August 2026; merged into `bulan`.** The completed work moves the
   selected game's exact visible artwork from Recent or
   Library into the custom launch surface, and shares that route with popup
   Play/Resume and automatic Direct Launch. Quit Game is recoverable, and
   quit-and-switch waits for a successful quit before entering the same launch
   route. Windows build, deterministic-state, lifecycle, frame-timing, and
   repeated-cycle evidence is recorded in `HANDOFF.md`; target-device and
   real-stream checks are not claimed.
4. **General screen transitions** — wire the existing 220 ms transition token
   into the rest of the completed core route. The selected-game transition in
   item 3 belongs to the launch experience, not to this general pass.
   **Done and accepted 2 August 2026; merged into `bulan`.** One vertical
   push/pop transition declared once on the navigation stack, with the launch
   and quit routes deliberately opted out. The client's live review added three
   accepted changes: a real blur during the transition, game tiles rising from
   below in a stagger instead of sliding in from the side, and a hint bar that
   holds still while the screen moves. Evidence and the honest gaps are in
   `HANDOFF.md`; no target-device or real-stream check is claimed, and the
   blur's Deck cost is deliberately deferred.

**Phase B item 3 closed the two inherited segue gaps.** They were deliberately
left until the grid landed. The accepted implementation replaces the visible
stock `StreamSegue.qml` and `QuitSegue.qml` treatments while preserving their
Session and quit contracts.

**Second Phase B gap, raised 1 August 2026 by the game grid:** the grid has
**no host-settings surface**, so SELECT does nothing there and its hint is
withheld. The client's game-grid mockup shows *SELECT Host Settings* on that
screen. ~~Either the existing `HostSettingsOverlay` is reused from the grid, or
the mockup's hint is dropped — a client decision, not yet taken.~~
**Decided 2 August 2026:** the grid reaches the existing `HostSettingsOverlay`,
and the SELECT hint appears there. **Decided but not yet built** — it belongs to
the Phase E work and is not on `v1-finalisation` yet.

**Exit:** launch → pick host → pick game → stream → return, with no screen in
the user journey that still reads as upstream Moonlight.

### Phase C — First run — built 3 August 2026, not yet client-reviewed

Built on `v1-review-build` to the client's S0–S3 boards.

- ~~Static splash~~ **Done.** Carries the vertical lockup, holds briefly,
  skippable by any press, replaces itself so B never returns to it.
- ~~“Let's find your PC”~~ **Done.**
- ~~“Looking for your PC”~~ **Done.** Discovered hosts as selectable rows.
- ~~PIN entry~~ **Done.** Four tiles, per the board.
- ~~Manual IP entry~~ **Done**, reusing the carousel's existing panel and
  `addNewHostManually`. **Steam on-screen-keyboard handling in Game Mode
  remains UNVALIDATED** — it cannot be tested off the Deck, and the source
  says so.
- ~~First-run routing and the post-pairing destination~~ **Done.** Launch goes
  to first run only when no paired host is known; pairing success lands on the
  host carousel with the onboarding screens cleared off the stack.

The reflected-moon mark is superseded. The horizontal corner wordmark is final
for that role, but it must not be enlarged or recomposed for centred-logo
screens. Existing onboarding boards remain useful for content and copy; their
centred treatment depends on vector assets designed and supplied by the client.

**Exit:** a first-time user can discover or enter a host, pair, and arrive in
the normal loop without encountering an upstream screen.

### Phase D — Edges — built 3 August 2026, not yet client-reviewed

- ~~Couldn't reach PC~~ **Already existed** from the carousel work.
- ~~Couldn't start stream~~ **Already existed** from the launch and quit work.
- ~~Empty library for a paired host~~ **Done.** Replaces the single line of
  holding copy `FLOW.md` recorded as not the designed state. Names the host and
  points at Host Settings, because a library that looks empty is often one
  where everything has been hidden.
- ~~Zero hosts~~ **Done.** The carousel with no hosts was the last obviously
  unfinished surface in the app. It now uses the first-run language and offers
  both *Look again* and *Enter an address instead*.
- ~~Disconnect confirmation~~ **Already existed.** `GameOptionsOverlay`'s
  `quitConfirm` page asks *Quit &lt;game&gt;?* with Cancel and Quit Game, and
  the quit-and-switch confirmation covers the other case.
- ~~Waking PC waiting overlay, held until success or failure~~ **Done, pulled
  forward into Phase B on 31 July 2026.** Its designed form changed on the way:
  the client asked for a waiting *overlay* on 28 July and, when the work was
  scoped on 31 July, chose a host-tile treatment instead — no overlay at all,
  and decided before anything was built rather than after. See
  `SPEC-host-carousel.md`'s "v1 decision — host tile busy state" and the
  client-review table entry for item 4.
- Disconnect confirmation

**Exit:** every reachable failure or empty state has a designed, controller-safe
route back to the loop.

### Phase E — Settings and About — built 3 August 2026, not yet client-reviewed

Built on `v1-review-build` to the client's four settings boards.

- ~~Settings in a Bulan shell using custom components~~ **Done.** Two panes,
  a data-driven row list, and two custom popups. No stock Qt Quick Control is
  instantiated. Nothing in the app routes to `SettingsView.qml` any more.
- ~~D-pad navigation that follows the visual layout~~ **Done.** Left/Right
  moves between the rail and the rows, Up/Down within a pane.
- ~~Controls for the existing atmosphere-effect flags~~ **Done**, and they are
  real persisted preferences now rather than read-only tokens.
- ~~About with the Moonlight credit~~ **Done.** Mark, version, “Built on
  Moonlight”, the fork statement and GPLv3.

**Exit:** required settings and legal attribution are reachable and usable
without a mouse.

### Phase F — Ship private v1

- ~~App icon in required sizes~~ **Done 3 August 2026.** The client's icon
  installs under the application ID and the desktop entry reads *Bulan*. The
  supplied master's white frame backdrop was dropped so the corners are
  transparent. Windows `RC_ICONS` still points at the upstream `.ico`; Windows
  is not a target.
- Flatpak installs cleanly — **not attempted.** The review station is Windows
  and cannot build or install one.
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
