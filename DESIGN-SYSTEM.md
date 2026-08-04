---
kind: current-authority
authority: design-system
read_when:
  - a-visual-value-is-involved
history_policy: replace-not-append
---

# Bulan — design system

Current rules for colour, type, motion, and spacing, and the values the client
has accepted. `bulan-creative-brief.md` owns *why*; this file owns *what*.
Superseded directions: `docs/design-rationale/creative-history.md`.

Source comments citing "creative brief §4", "§6", or "§8" predate this split.
§4 (colour) and §6 (motion) are now here; §8 (voice) is in the brief. Full
mapping in `docs/design-rationale/creative-history.md`.

## Where the values live

**`app/gui/Bulan.qml` is the authority on every token value.** It is the live
runtime singleton and carries a comment on each value explaining what the number
is and why. This file records the rules, and the values a client review actually
settled; it does not restate the whole token list, because two copies of a number
drift. `app/gui/BulanTokens.qml` is a review copy for the token proof sheet and
must stay synchronized with the runtime token.

## Colour

**The rule: warm light on cool ground.** Everything follows from it.

| Role | Token | Value |
|---|---|---|
| Base background | `bgBase` | `#0D1024` — deep indigo-navy |
| OLED background | `bgBaseOled` | `#080A18` — deepened, **never `#000000`** |
| Surface / card | `bgSurface` | `#171B33` |
| **Primary accent** | `accentPrimary` | `#FFD9A0` — moonglow amber, the signature |
| Accent glow | `accentGlow` | `#FFB865` — bloom and focus halos |
| Secondary | `secondary` | `#8A93C2` — muted periwinkle; water, reflection, inactive |
| Text primary | `textPrimary` | `#F4EDE2` — warm off-white, **never pure white** |
| Text secondary | `textSecondary` | `#A8AECB` |
| Success | `statusSuccess` | `#7FC7A8` — desaturated jade |
| Error | `statusError` | `#E08B7D` — dusty coral |

`Bulan.qml` carries the rest: hover, pressed, hairline, gradient stops, and the
popup glass set.

### Depth, not darkness

**True black is rejected as a default.** Pure `#000000` behind warm off-white
text is the harshest contrast the screen can produce, and this app is used in a
dark room. Bulan should feel like dusk, not like a void. Depth comes from
texture and gradation instead:

| Technique | Application |
|---|---|
| Vertical gradient | `gradientBaseTop` → `gradientBaseBottom` — sky into water |
| Radial glow | Soft warm bloom behind the focused element and the mark, `accentPrimary` at 3–6% |
| Film grain | Fine monochrome noise, static — never animated; animated grain reads as video noise and costs battery |
| Background blur | Artwork behind menus at heavy gaussian blur plus a darkening scrim, so it is felt rather than read |
| Vignette | Barely-there edge darkening, ~8%, drawing the eye inward on a small panel |

Grain also breaks up **colour banding**, which dark gradients are prone to.

### Non-negotiables

- The palette must survive a dark room at 1 am.
- **No pure black, no pure white** — cap contrast at both ends.
- Cap maximum luminance across the board. Nothing should shout.
- Keep blue-heavy hues out of large fill areas.
- No neon, no saturated primaries.
- Every background effect — grain, ambient motion, blur — must be individually
  disableable. These are real persisted preferences.

### Panel handling

Both Deck panels are product targets. Automatic LCD/OLED detection and gradient
adjustment is **product intent, not a built feature**. OLED appearance has been
validated; LCD has not.

## Typography

**UI face:** humanist geometric sans, generous x-height, open apertures.
Candidates: Inter, Instrument Sans, General Sans. Must be legible at arm's
length on a 7-inch panel at ~50 cm.

**Wordmark face:** warmer and rounder than the UI face — soft terminals,
**rounded not bubbly**. The tell for "playful but mature" is subtle corner radii
on the letterforms, not cartoon weight.

**Licensing:** ship only **SIL OFL** fonts, so QML embedding stays clean under
GPLv3 distribution.

Sizes run `sizeDisplay` 56 → `sizeCaption` 16 in `Bulan.qml`. Bind to
`font.pixelSize`, never `font.pointSize`.

## Motion

Match Nintendo Switch 2's discipline: **fast and confident**, not elaborate.

| Interaction | Spec |
|---|---|
| Focus / hover | Scale to 1.04 plus a soft outer moonglow bloom, **180 ms**, ease-out with barely-there overshoot |
| Screen transition | Vertical reveal with motion blur, **220 ms** — content ascends like something surfacing |
| Press | Scale to 0.97, 80 ms, immediate |
| Ambient background | Slow parallax starfield or water-shimmer, extremely low contrast, pausable for battery. **Not built — v1.x** |

### Rules

1. **Never bounce twice.** One settle, done.
2. Nothing animates for longer than the user's next input can arrive.
3. **Input always interrupts animation.** No exceptions.
4. Ambient motion must be disableable in one toggle.

### Screen entry — transition first, then a staggered element entrance

*Client decision, 2 August 2026. It governs every screen added from here.*

1. **The screen transition happens first.** No element entrance begins while the
   screen itself is still travelling.
2. **Elements animate in after the screen settles**, rising and fading into
   place on a slight stagger.
3. **Stagger by visual reading order**, not source-file order. Keep delays
   subtle and **cap the number of steps**, so a dense screen does not take
   noticeably longer to become usable than a sparse one.
4. **A slight overshoot and a single soft bounce.** Entrances settle by crossing
   their resting place once and coming back. Playful and tactile, not elastic.
   This is rule 1 above, not an exception to it.
5. **Input remains authoritative.** Focus and controls are usable immediately.
   Input may finish or interrupt an entrance; an entrance must never consume,
   queue, or reject the next action. A launch pressed during the game-artwork
   entrance settles the artwork immediately and captures it, rather than
   degrading to the fallback.
6. **Do not stagger blindly.** Persistent window-level furniture — the hint bar
   — holds still. Modals, confirmations, and the launch and quit surfaces keep
   their own established motion. Do not animate every decorative child.
7. **Share the tokens.** Cadence, duration, travel distance, and overshoot live
   in the `Bulan` singleton. No raw per-screen values, and no second
   near-identical copy of the same animation.

An entrance overshoot uses `motionEntranceOvershoot`, **not**
`motionOvershoot` — the latter is tuned for a 4% focus scale change and would
move a screen-scale translation by about a pixel.

**The screen transition carries a real runtime blur.** The brief's "slight
motion blur" was first built as opacity falling away during travel; the client
rejected that on 2 August 2026 and required a real blur, accepting the cost
knowingly. It is gated to the navigation stack's `busy` window, so a settled
screen carries no layer. Its cost on the Deck is **still unmeasured**, by the
client's deliberate deferral. It blurs the whole stack, including the atmosphere
behind the screens, not only the moving content — **a visual consequence the
client has not yet judged.**

## Values a client review settled

On the OLED Deck, 28 July 2026:

| Token | Value | Outcome |
|---|---|---|
| `atmosphereGrainOpacity` | `0.03` | Confirmed. Visible and doing its job |
| `sizeCaption` | `16` | Confirmed. Legible without leaning in |
| `motionOvershoot` | `0.7` | Confirmed |
| `motionFocusMs` | `180` | Changed from the brief's `140` — deliberate evolution, not a deviation |

On Windows, at the client's live review, 2 August 2026:

| Token | Value | Outcome |
|---|---|---|
| `motionTransitionMs` | `220` | The brief's figure, kept |
| `motionTransitionRise` | `space3xl` (64) | Kept. Reused a spacing token rather than inventing a raw distance |

Evidence: `docs/validation/2026-07-28-deck-oled-review.md`. **The first table is
OLED-only.** It is not evidence for LCD banding or appearance.

## Sound

Not built — v1.x. Soft struck tones, heavily damped, tuned to a single
pentatonic set, sitting well below dialogue level with a global volume slider
and a hard off switch. Direction and cue list in `bulan-creative-brief.md`.

## Open

- Whether ambient background motion ships enabled or disabled by default.
- LCD-specific appearance and banding, deferred until LCD hardware exists.
