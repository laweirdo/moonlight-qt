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

### Phase A — Stabilise ✅ **CLOSED 28 July 2026**
*Nothing new gets built until the foundation is trustworthy.*

- ✅ Defects 1, 3, 4 fixed; decision made on 2 — **and all four confirmed by hand on hardware**
- ✅ Unconditional glyph-detection log at startup
- ✅ Deck checks 4–8 reported, plus Game Mode (check 9)
- ⏳ **The wake question — still owed.** The only item not closed. It needs a host that can genuinely be put to sleep, and does **not** need a Deck. Carried into Phase B rather than holding the gate, because nothing depends on the answer except one line of copy.
- ✅ Brief, flow diagram and onboarding frames moved into the repo
- ✅ **Merge to `bulan`** — first known-good baseline
- ✅ Upstream sync — fast-forward `master` from upstream, then merge `master` into `bulan`
- ✅ `REVIEW-CHECKLIST.md`

**Exit:** met. `bulan` exists, the carousel's defects are fixed and hardware-confirmed, and the global tokens are settled from real observation.

#### The settled tokens

Judged on a Steam Deck OLED ("Galileo") on 28 July 2026, by the client, on the real panel.

| Token | Value | Outcome |
|---|---|---|
| `atmosphereGrainOpacity` | **0.03** | Unchanged. Judged fine — visible and doing its job |
| `sizeCaption` | **16** | Unchanged. Legible at holding distance without leaning in |
| `motionOvershoot` | **0.7** | Unchanged |
| `motionFocusMs` | **180** | Changed from 140. The brief's figure read a touch too fast |

**Both standing risks below were wrong, and in the reassuring direction.** Recorded because the lesson generalises: `sizeCaption: 16` was predicted by calculation to fail at arm's length and does not, and grain at 0.03 was predicted to be invisible on this panel and is not. **The arithmetic was more pessimistic than the eye.** Worth remembering before the next value is argued from a spreadsheet rather than looked at.

#### What Phase A also produced

Three open defects, all in `BUGS-open.md`, none needing a Deck to reproduce. One of them — the carousel's third tile wrapping visibly on every move — the client called out as reading unpolished, and it is worth clearing early in Phase B since it sits on the screen every session starts with.

**Branch names.** This originally said "merge to `main`". There is no `main`: the fork's default branch is `master` and it is kept as a clean mirror of upstream, while `bulan` is the integration branch and the baseline. Corrected here so nobody goes looking for a branch that does not exist. See `HANDOFF.md` § *How this repository is branched*.

**Sync, not rebase.** This originally said "upstream rebase". `bulan` is pushed and shared, so rebasing it would rewrite history other checkouts already have. The sync is a merge in one direction only, which is why `master` must never carry Bulan work — that is what keeps the first half a fast-forward.

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

**Logo composition — decided, 27 July 2026.** The reflected mark is not used in these frames. They use the wordmark already in the repo, `app/res/bulan_logo_horiz.svg`, which is the same mark the carousel already draws. This unblocks the phase, and it means all four frames need recomposing: they were laid out around a tall centred element and the wordmark is small and horizontal, so the vertical space it vacates has to be deliberately reallocated rather than left as a gap. The frames in `design/` are the *old* composition and are now reference for content and copy, not for layout.

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

~~**`sizeCaption: 16` may fail at arm's length.**~~ **Retired 28 July 2026 — did not happen.** Read comfortably on the panel. Stays 16.

~~**Grain at 0.03 may be invisible on the OLED.**~~ **Retired 28 July 2026 — did not happen.** Visible and doing its job. Stays 0.03. The brief's 2–4% range needs no revision.

~~**Steam Input sits between hardware and app in Game Mode.**~~ **Retired 28 July 2026 — verified and passed.** Steam Input does interpose a virtual controller (`Steam Virtual Gamepad`, product `11ff` rather than `1205`), but carries Valve's vendor ID `28de` through, which is what detection keys on. All five bindings arrive. See `BUILDING-DECK.md`.

**All three of the risks this document carried were retired by one afternoon of looking at the hardware, and all three had been more frightening on paper than in fact.** The pattern is worth keeping in view: this project's estimates of its own perceptual risks have run pessimistic. That argues for reaching hardware earlier, not for trusting the estimates less.

### Current standing risks

**Wake is unproven.** Bulan offers to wake a sleeping host and nobody has ever seen it work. If it does not, the "Asleep" state is a promise the app cannot keep and the copy has to change. Cheap to answer, and does not need a Deck.

**The carousel wraps visibly at three hosts.** `BUGS-open.md` defect 2. Cosmetic, on the screen every session begins with, and the fix is not yet attempted.
