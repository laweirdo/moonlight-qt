# Bulan — Creative Brief
### Logo & Visual Identity for a Console-Style Moonlight Fork

**Project:** Bulan — a UI/UX-focused fork of the Moonlight game streaming client, targeting Steam Deck
**Name meaning:** *Bulan* = "moon" in Indonesian
**Platform:** Steam Deck (7" 1280×800 LCD / 7.4" OLED), handheld, controller-only input
**Tech stack:** Qt / QML — **custom components throughout, not stock Qt Quick Controls**
**Upstream:** moonlight-qt (GPLv3)

---

## Current interpretation — 30 July 2026

This brief preserves the original creative direction. The labels below record
later client decisions and hardware validation without rewriting that history.
`ROADMAP.md` owns release scope; `HANDOFF.md` owns current implementation state.

| Label | Topic | Current interpretation |
| --- | --- | --- |
| **Invariant** | Reflection | The reflection metaphor, warm-light/cool-ground system, voice, and atmosphere remain the creative foundation. Superseding one logo direction does not supersede the concept. |
| **Superseded** | Reflected-moon mark | Direction A is no longer the lead mark and must not be used as the assumed solution for new screens or artwork. Its original exploration remains below as history. |
| **Final for its role** | Horizontal corner wordmark | `app/res/bulan_logo_horiz.svg` is the final horizontal wordmark on screens where it appears in a corner. Do not redesign or substitute it. |
| **Client asset required** | Centred-logo screens | A corner wordmark must not be enlarged or recomposed into a centred mark. The client will design and provide the required vector files for screens with a centred logo treatment. |
| **v1 decision** | Hardware target | Both Steam Deck LCD and OLED remain product targets. OLED visual validation has been performed; LCD-specific visual validation is deferred until hardware is available and does not block private v1. |
| **Accepted evolution** | Focus motion | Hardware review changed focus duration from the original `140 ms` to `180 ms`. The original value remains below as creative history; `180 ms` is the accepted live value. |
| **v1 decision** | Screen transition blur | §6 asks for "slight motion blur" on the screen transition. It was first built as opacity falling away during travel, the inexpensive reading. The client rejected that on 2 August 2026 and required a real runtime blur, accepting the performance cost knowingly; the Steam Deck measurement is deferred until after private v1. |
| **Validated on OLED** | Grain and type | Grain at `0.03`, caption text at `16 px`, and motion overshoot at `0.7` were accepted on the OLED Deck. This is not evidence for LCD-specific banding or appearance. |
| **v1 decision** | Controller glyph art | Custom Steam Deck glyph vectors are not required for private v1 because their practical shapes are identical to the accepted XInput set. Deck detection remains meaningful even when it resolves to that art. |
| **Long-term** | Deliverables | Section 10 is the long-term creative list and a guide when a visual decision is stuck. It is not the private-v1 acceptance checklist. |
| **v1 engineering boundary** | Upstream foundation | Retain upstream discovery, pairing, streaming, and platform infrastructure. New or rebuilt Bulan visual controls remain custom; this does not require wholesale replacement of inherited infrastructure or every upstream screen at once. |
| **Conceptual** | Panel handling and effect controls | Automatic LCD/OLED visual selection and user-facing toggles for every atmosphere effect remain product intent rather than completed features. |

---

## 1. Positioning

**Moonlight is a tool. Bulan is a place you arrive.**

Moonlight's current identity reads as competent open-source utility: cold blue, flat, functional. Bulan's job is to feel like **first-party console system software that happened to be made with love** — the thing you'd believe shipped in the box.

Every design decision should answer one question:

> *Would this look out of place next to a console home screen?*

**Brand statement:** *Your rig, reflected — wherever you are.*

**Tone target:** playful but not childish. Warm but not soft. Confident but not cold.

---

## 2. Core Concept — Reflection

The organising idea for the entire identity:

> **The moon doesn't make its own light. It reflects the sun. Bulan doesn't render your game — it reflects your PC.**

Remote play *is* reflection. This makes the name functional rather than decorative, and it hands over a complete visual system: moon + still water, source + reflection, warm light above and cool ground below.

Use this metaphor to resolve ambiguity. When unsure how something should look, ask what "reflection" would do.

---

## 3. Logo Directions

The three original explorations are preserved below. The instruction to lead
with Direction A or combine it into the final mark is superseded; no agent should
infer a replacement mark from these sketches.

### Direction A — The Reflected Moon *(superseded; original lead direction)*
- A crescent above, its mirrored reflection below, separated by a thin horizon line
- The lower reflection is softer, blurred, or broken into horizontal bands — this *is* the stream
- Reads at 24px as a simple stacked lens shape
- Bonus: the two nested crescents can imply a subtle **B**

### Direction B — Crescent-as-Play
- The crescent's inner concave curve is cut so the negative space resolves into a play triangle
- Ties moon directly to streaming; very strong at small sizes
- **Risk:** can drift into generic media-player territory. Push the crescent weight to stay distinctive.

### Direction C — Bulan the Companion *(deferred — post-v1)*
- The moon as a soft, near-featureless character — expressive only through a single arc and its glow
- No face, or the barest suggestion of one
- Enables delightful motion: blinks while scanning for a host, stretches during connect, dozes when idle
- **Use as a mascot alongside the mark from A, not as the primary mark itself**

> **Not in scope for v1.** A mascot needs a full expression set (idle, searching, connected, error, sleeping) and that illustration load should come after the app ships. Design the primary mark so a companion character *could* be added later without rework — leave conceptual room, don't build the room yet.

The original pairing with Direction A is no longer binding because Direction A
is superseded. Any future mascot-to-mark relationship requires a new client
decision.

### Surface treatment *(applies to all directions)*
Keep the mark's interior nearly empty. If texture is needed, use the most reductive option available:
- Fine concentric arcs following the crescent's curve
- A sparse dot grid at very low contrast
- A single soft gradient across the crescent body, light edge to dark

**No illustration, no detail, no craters.** The mark should survive being reduced to a solid silhouette without losing its identity.

---

## 4. Color System

**The rule: warm light on cool ground.** Everything follows from this.

| Role | Value | Notes |
| --- | --- | --- |
| Base background | `#0D1024` | Deep indigo-navy. Warmth and depth — pure black reads clinical |
| OLED background | `#080A18` | Deepened, **never `#000000`** — see *Depth, Not Darkness* below |
| Surface / card | `#171B33` | One step up from base |
| **Primary accent** | `#FFD9A0` | **Moonglow amber.** The signature — separates Bulan from Moonlight's blue *and* Steam's blue |
| Accent glow | `#FFB865` | Warmer, for bloom and focus halos |
| Secondary | `#8A93C2` | Muted periwinkle — water, reflection, inactive states |
| Text primary | `#F4EDE2` | Warm off-white. **Never pure white** |
| Text secondary | `#A8AECB` | |
| Success | `#7FC7A8` | Desaturated jade |
| Error | `#E08B7D` | Dusty coral |

### Depth, Not Darkness

**True black is rejected as a default.** Pure `#000000` behind warm off-white text creates the harshest contrast ratio the screen can produce — visually fatiguing in a dark room, which is exactly when this app gets used. Bulan should feel like dusk, not like a void.

Instead, build depth through **texture and gradation**:

| Technique | Application |
| --- | --- |
| **Vertical gradient** | Base fades from `#151A38` at top to `#080A18` at bottom — sky into water. Reinforces the reflection concept |
| **Radial glow** | Very soft warm bloom behind the focused element and behind the moon mark, `#FFD9A0` at 3–6% opacity |
| **Film grain** | Fine monochrome noise overlay, 2–4% opacity, static (not animated — animated grain reads as video noise and costs battery) |
| **Background blur** | Artwork and box art behind menus at heavy gaussian blur + darkening scrim, so the background is felt rather than read |
| **Vignette** | Barely-there darkening at screen edges, ~8% — draws the eye inward on a small panel |

Grain has a practical bonus: it breaks up **colour banding**, which gradients on dark backgrounds are prone to. Without it, smooth fades can show visible stripes.

### OLED handling
Detect panel type and deepen the gradient's lower end slightly on OLED — but keep it above true black. The battery saving from pure black is small at these luminance levels and not worth the eye strain.

This remains conceptual. Both panels remain targets, but automatic panel
selection has not been implemented and LCD-specific appearance is not yet
validated.

### Non-negotiables
- The palette must survive a dark room at 1am
- **No pure black, no pure white** — cap contrast at both ends
- Cap maximum luminance across the board — nothing should shout
- Keep blue-heavy hues out of large fill areas
- No neon, no saturated primaries
- Every background effect (grain, ambient motion, blur) must be individually disableable

---

## 5. Typography

**UI face:** humanist geometric sans with generous x-height and open apertures.
Candidates: **Inter**, **Instrument Sans**, **General Sans**.
Must be legible at arm's length on a 7" panel held at ~50cm.

**Wordmark face:** slightly warmer and rounder than the UI face.
- Soft terminals
- Single-storey `a` optional
- **Rounded, not bubbly**

> The tell for "playful but mature" is subtle corner radii on the letterforms — *not* cartoon weight.

**Licensing constraint:** ship only **SIL OFL** fonts so QML embedding stays clean under GPLv3 distribution.

---

## 6. Motion Language

Nintendo Switch 2's UI feels good because it is **fast and confident**, not because it's elaborate. Match that discipline.

| Interaction | Spec |
| --- | --- |
| Focus / hover | Scale to 1.04 + soft outer moonglow bloom, **140ms**, ease-out with barely-there overshoot |
| Screen transition | Vertical reveal with slight motion blur, **220ms** — content ascends like something surfacing |
| Press | Scale to 0.97, 80ms, immediate |
| Ambient background | Slow parallax starfield or water-shimmer, extremely low contrast, pausable for battery |

The live focus duration is `180 ms`, accepted after the original `140 ms` read
slightly too fast on the OLED Deck. This is deliberate evolution, not an
accidental implementation deviation.

### Motion rules
1. **Never bounce twice.** One settle, done.
2. Nothing animates for longer than the user's next input can arrive.
3. **Input always interrupts animation.** No exceptions.
4. Ambient motion must be disableable in one toggle.

### Screen entry — transition first, then a staggered element entrance

*Client decision, 2 August 2026. Durable guidance: it governs every screen
added from here, and existing screen-entry motion is reconciled to it.*

1. **The screen transition happens first.** Ordinary navigation uses the
   established vertical push/pop. No element entrance begins while the screen
   itself is still travelling.
2. **Elements animate in after the screen settles.** Once it has arrived, the
   screen's principal elements rise and fade into place on a slight stagger.
3. **Stagger by visual reading order**, not source-file order — the order the
   eye should meet things. Keep the delays subtle and **cap the number of
   stagger steps**, so a dense screen does not take noticeably longer to
   become usable than a sparse one.
4. **A slight overshoot and a single soft bounce.** Entrances settle by
   crossing their resting place once and coming back. Playful and tactile, not
   elastic. This is rule 1 above, not an exception to it.
5. **Input remains authoritative.** Focus and controls are usable immediately.
   Input may finish or interrupt an entrance; an entrance must never consume,
   queue, or reject the next action. A launch pressed during the game-artwork
   entrance settles the artwork immediately and captures it, rather than
   degrading to the fallback.
6. **Do not stagger blindly.** Persistent window-level furniture — the hint bar
   — holds still. Modals, confirmations, and the launch and quit surfaces keep
   their own established motion. Do not animate every decorative child
   independently.
7. **Share the tokens.** Cadence, duration, travel distance and overshoot live
   in the `Bulan` singleton. No raw per-screen values, and no second
   near-identical copy of the same animation.

The overshoot deliberately uses its own token rather than the focus overshoot:
`motionOvershoot` is tuned for a 4% scale change, and the same figure applied
to a screen-scale translation is invisible. See `motionEntranceOvershoot`.

---

## 7. Sound Identity *(key differentiator)*

Build the palette from **soft struck tones** — felt mallets on wood or glass, heavily damped, with short reverb tails. Warm, round, no attack transient. Think of something being touched rather than pressed.

Tune every cue to a single **pentatonic set**. This is a functional decision, not a stylistic one: pentatonic intervals contain no dissonant pairs, so no sequence of rapid user inputs can ever produce a sour combination. Fast scrolling stays musical instead of turning into noise.

| Cue | Spec |
| --- | --- |
| Focus move | 40ms muted mallet, alternating between two pitches |
| Confirm | Two-note rise |
| Back | Single lower note, shorter tail |
| Connect success | Gentle ascending arpeggio + air swell |
| Connect failure | Low damped tone — no buzz, no harshness |
| Toggle | Soft dry tick |

**Constraints:** everything sits well below dialogue level. Global volume slider plus a hard off switch — people play at 2am next to a sleeping partner.

---

## 8. Voice & Copy

Warm, brief, second person, quietly confident. Technical language lives in Advanced settings and nowhere else.

| Context | Copy |
| --- | --- |
| Scanning | *"Looking for your PC…"* |
| Host idle | *"Ready when you are."* |
| Host offline | *"Couldn't reach Desktop-PC. Still on the same network?"* |
| First launch | *"Let's find your PC."* |

**Never** put a stack trace, error code, or protocol name on a front-facing screen.

---

## 9. Visual References

Search themes for gathering reference. These describe **atmosphere**, not instruction — the hard specs live in sections 4–7. The moodboard answers the question specs can't: *what should this feel like?*

### A. Reflection
> `moon reflection on still water at night`

The founding image: a light source above, a softer double below, a horizon between them.

**Historical Direction A reference:** the original mark lesson was that a
reflection is *broken* — banded, rippled, imperfect — while the horizon remains
quiet. This still informs the atmosphere, but it is not an instruction to
restore a lower reflected crescent to a new mark.

### B. The Mark — Reductive
> `minimal geometric moon phases design` · `pure circle geometry logo`

**What to take:** a crescent built from two overlapping circles is the most reductive form available and scales to 24px without adjustment. One weight, no ornament, no craters. The silhouette carries the identity alone.

### C. Where Playfulness Lives
> `rounded 3d shapes` · `soft volume minimal form`

**Ignore the palettes in these references.** Take only the *form language*: generous corner radii, soft ambient shadow, gentle volume. Translated into indigo and amber, this is what stops the interface feeling austere.

### D. Sleek — Dark Interface Restraint
> `dark mode minimal ui design`

**What to take:** the amount of empty space, and how few elements compete for attention. One accent colour, one focused element, everything else recedes.

### E. Depth Without Contrast
> `blurred gradient mesh background` · `indigo twilight sky gradient`

Supports *Depth, Not Darkness*. **What to take:** not one of these is a solid fill. That's the argument for the grain-and-gradient approach in a single glance.

---

### The Balance, In One Rule

Minimal and playful pull against each other, so give each a territory:

| Element | Register |
| --- | --- |
| Logo, icons, typography, layout | **Strictly minimal** — geometric, one weight, no ornament |
| Motion, sound, focus states, corner radii | **Playful** — soft overshoot, warm bloom, generous rounding |

> The interface should look **composed when still** and feel **delighted when touched.**

The personality is carried by behaviour, not decoration. Practical consequence: the mark can afford to be *more* reductive than instinct suggests, because motion and sound are covering the warmth. **Push the logo further toward pure geometry than feels comfortable.**

### Deliberate omission
**Do not collect Nintendo Switch 2 interface screenshots.** Having their actual screens in the moodboard produces imitation rather than interpretation. Take the written principles — fast focus, generous spacing, restrained ornament — and source visual reference from the moon-and-water world that belongs to this project.

---

## 10. Deliverables

This is the long-term creative production list and a reference when visual work
is blocked. `ROADMAP.md`, not this list, decides what private v1 requires.

1. **Primary mark** — full-color, mono, inverse + safe-area and minimum-size specs
2. **App icon** — 512, 256, 128, 64, 32 px
3. ~~**Steam Deck artwork set** — 460×215 capsule, 920×430 wide capsule, 1920×620 hero, transparent logo PNG~~ **Removed from the deliverables, 2 August 2026.** Client decision: Steam library artwork is not a Bulan deliverable at all. Game artwork comes from the host PC, and Bulan renders what the host provides rather than shipping capsule, hero, or wide-capsule art of its own. The **app icon** (item 2) is unaffected and is still required, because the non-Steam application entry is Bulan's own.
4. **Wordmark lockups** — horizontal, stacked, icon-only
5. **Boot / splash animation** — ≤1.2s, skippable
6. **Color tokens** — as a QML singleton *and* design-token JSON
7. **Icon set** — navigation, status, and Steam Deck controller glyphs (A/B/X/Y, L/R bumpers, Steam, QAM); custom Deck glyph vectors are not required for private v1
8. **Sound pack** — 8–12 cues, normalized, OGG format
9. **One-page brand rules sheet**

---

## 11. Guardrails

### Design
- **Reference Switch 2's *discipline*, don't reproduce its *assets*.** Take the principles — high contrast, fast focus, generous spacing, restrained ornament. No borrowed icon shapes, no lookalike home screen chrome, no Nintendo-adjacent naming.
- **Do not reuse or recolor Moonlight's existing mark.** Bulan needs a clean, unrelated identity.
- **Custom components only.** Do not design against stock Qt Quick Controls defaults. Stock components are precisely what makes Moonlight read as a utility — every button, list, slider, toggle and dialog is drawn from scratch for this identity.
- **Controller-first, always.** Every screen must be fully operable with the gamepad alone. If a design element only works with touch or trackpad, it's wrong.
- Minimum touch/focus target: 64×64px at native Deck resolution.

### Legal
- **moonlight-qt is GPLv3.** The fork must carry the license and clearly credit upstream — a *"Built on Moonlight"* line in About is both required practice and good manners.
- Distinct branding helps here: it prevents users mistaking this build for official Moonlight.

---

## Original decisions made

Later decisions and validated evolution are recorded in *Current
interpretation* near the top.

| Question | Decision |
| --- | --- |
| Component library | **Custom components throughout.** No stock Qt Quick Controls styling. |
| Mascot (Direction C) | **Deferred past v1.** Primary mark should leave room for one, but not depend on it. |
| Dark theme approach | **No true black.** Depth comes from gradient, grain, glow and blur — see *Depth, Not Darkness*. |

## Still Open

- Centred-logo vector assets — the client must design and provide these; the
  final horizontal corner wordmark is not a substitute
- Whether ambient background motion ships enabled or disabled by default

Grain intensity is no longer generally open: `0.03` passed on OLED. LCD-specific
visual validation remains deferred until LCD hardware is available.
