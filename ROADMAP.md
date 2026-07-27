# Bulan — Roadmap

**Status:** draft, 27 July 2026
**Owner:** Lao

---

## What v1 is

> **A complete, unembarrassing loop from cold launch to streaming and back, on a Steam Deck, with no screen along the way that still looks like upstream Moonlight.**

The test is a first-time user on a fresh install: they should never hit a screen that breaks the spell. That's the line. Anything a user encounters on the way to a game is v1. Anything that makes an already-working thing nicer is v1.x.

**What v1 is not:** a public release. See *Distribution* below.

---

## Scope decisions

These are the calls that were open. Recorded here so they stop being re-derived.

| Question | Decision | Reasoning |
|---|---|---|
| Multiple hosts → one merged library? | **No. Separate libraries per host.** | The carousel already establishes host as the primary axis. Merging contradicts it and roughly doubles the game grid's complexity. Revisit for v1.x if it ever feels wrong in use. |
| Sound pack (brief §7) | **v1.x** | 8–12 cues is a genuine production effort, and nothing breaks without it. It's a differentiator, not a dependency — which makes it the first thing to build after the loop is closed, not part of closing it. |
| Onboarding | **v1** | Already designed, and without it first launch is upstream's bare grid. It runs once and is invisible in daily testing, which is exactly why it needs scheduling rather than remembering. |
| Settings redesign | **v1, partial** | Full re-architecture of 37 controls is out of scope. But the flat 37-step D-pad chain is a real controller usability bug, and stock Qt Quick Controls is the largest standing violation of the custom-components rule. v1 gets a Bulan shell and working navigation. |
| Stream overlay (Start+Select) | **Deferred pending hardware check** | The binding is an untested guess and upstream's overlay presumably works. If the Deck check shows it's broken, it becomes v1. |
| Boot animation | **v1.x** | Static splash ships in v1. Animating it is additive. |
| Mascot (brief Direction C) | **Deferred** — already decided in brief | |
| Ambient background motion | **v1.x** | Battery cost unmeasured, and the atmosphere layer already carries the mood without it. |
| HDR | **Not doing** | Brief-level complexity for marginal gain on this panel. |
| Windows / other platforms | **Not doing** | Steam Deck is the product. |

---

## Distribution

**v1 is for Lao and a handful of people, installed by hand as a non-Steam game via Flatpak.**

This sizes several things that were otherwise unsizeable:

- **"Built on Moonlight" in About** — still required, still a licence obligation, but it does not need a polished About screen. A line of text satisfies it.
- **App icon and Steam artwork** — needed, because a non-Steam game entry with no artwork looks broken in the library. In v1.
- **README, brand rules sheet, reproducible builds** — v1.x or never. These matter when other people contribute or install, and nobody does yet.

Public release is a v2 conversation.

---

## Phases

Each phase ends on the Deck before the next begins. That cadence is the point, not a formality.

### Phase A — Stabilise
*Nothing new gets built until the foundation is trustworthy.*

- Defects 1, 3, 4 fixed; decision made on 2
- Unconditional glyph-detection log at startup
- Deck checks 4–8 reported, plus Game Mode (check 9) and the wake question
- Brief, flow diagram and onboarding frames moved into the repo
- **Merge to `main`** — first known-good baseline
- Upstream rebase
- `REVIEW-CHECKLIST.md`

**Exit:** `main` exists, the carousel is defect-free on hardware, and global tokens (grain, `sizeCaption`, overshoot) are settled from real observation rather than arithmetic.

### Phase B — Close the core loop
*The path a user walks every single session.*

- **Host settings menu** (SELECT) — absorbs the rename / delete / test-network regression, which is currently a functional loss against upstream
- **Connecting state** — designed properly, replacing the placeholder
- **Game grid** (`AppView.qml`) — Recent and Library tabs, per the existing frames
- **Game detail / launch** — per the flow diagram
- Screen transitions wired up (220ms, brief §6 — the token exists and is unused)

**Exit:** launch → pick host → pick game → stream → return, with no upstream screen visible.

### Phase C — First run
*Runs once, invisible in daily testing, breaks the spell if missing.*

- Splash
- "Let's find your PC"
- "Looking for your PC"
- PIN entry
- **Manual IP entry** — referenced by two designed screens as "Enter an address instead" and currently undesigned. Needs deliberate handling of Steam's on-screen keyboard in Game Mode.
- First-run routing logic — what "first launch" means mechanically, and where pairing lands the user

**Blocked on:** the logo composition question. Replacing the large reflected mark with the small wordmark leaves a void in frames composed around it. Resolve before building, since it changes all four.

### Phase D — Edges
*Where the flow diagram already says things are missing.*

- Couldn't reach PC
- Couldn't start stream
- Library empty state for a paired host with no games — flagged on the board as not drawn
- Zero hosts
- Waking PC
- Quit / disconnect confirmation

### Phase E — Settings and About
- Settings in a Bulan shell, custom components
- D-pad navigation that follows the visual layout instead of a flat 37-step chain
- Toggles for the atmosphere effects that already have flags wired but no UI
- About, with the Moonlight credit

### Phase F — Ship
- App icon, five sizes
- Steam Deck artwork set — capsule, wide capsule, hero, transparent logo
- Flatpak packaged and installing cleanly
- Full `REVIEW-CHECKLIST.md` pass on the Deck
- Brief reconciled one final time; `Decisions Made` complete

---

## v1.x — the queue after

Ordered by expected value, not effort.

1. **Sound pack** — the largest single differentiator still unbuilt
2. Boot animation
3. Ambient background motion
4. Stream overlay, if hardware testing showed it needed
5. Merged multi-host library, if separate libraries prove annoying in use
6. README and public release preparation

---

## Not doing

HDR · Windows and other platforms · the mascot · a brand rules sheet while nobody else contributes

---

## Standing risks

**`sizeCaption: 16` may fail at arm's length.** It sits under the comfort threshold at 50cm by calculation. If it fails, it's a token change touching every screen built and unbuilt. This is why Phase A precedes all construction.

**Grain at 0.03 may be invisible on the OLED**, not coarse. If so, the brief's 2–4% range is wrong for this panel and §4 needs revising — grain that can't be seen can't break the banding it exists to break.

**Steam Input sits between hardware and app in Game Mode**, and nothing has been verified there. Everything to date was Desktop Mode.
