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

Source comments citing "creative brief §4/§6/§8" predate this split; the mapping
is in `docs/design-rationale/creative-history.md`.

## Where the values live

**`app/gui/Bulan.qml` is the authority on every token value**, with a comment on
each explaining what the number is and why. This file records the rules and the
values a client review settled; it does not restate the token list, because two
copies of a number drift. `app/gui/BulanTokens.qml` is the proof sheet's review
copy and must stay synchronized with the runtime token.

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

**Lines.** Two weights only, `hairlineWidth` and `focusRingWidth` — never a raw
number or a spacing step divided down to reach one.

**Popups.** One glass treatment: `popupScrim`, `popupGlassSurface`,
`popupGlassBorder`, `radiusXl`, `PopupMotion`, `z: 200`, on a `FocusScope` that
is the last child of its screen — never a stock `Dialog`.

### Depth, not darkness

**True black is rejected as a default.** Pure `#000000` behind warm off-white is
the harshest contrast the screen can produce, and this app is used in a dark
room. Bulan should feel like dusk, not a void. Depth comes from texture and
gradation instead:

| Technique | Application |
|---|---|
| Vertical gradient | `gradientBaseTop` → `gradientBaseBottom`, sky into water |
| Radial glow | Warm bloom behind the focused element and the mark, `accentPrimary` at 3–6% |
| Film grain | Fine monochrome noise, static — animated grain reads as video noise and costs battery |
| Background blur | Artwork behind menus, heavy gaussian plus a darkening scrim: felt, not read |
| Vignette | Barely-there edge darkening, ~8%, drawing the eye inward |

Grain also breaks up **colour banding**, which dark gradients are prone to.

### Non-negotiables

- The palette must survive a dark room at 1 am.
- **No pure black, no pure white** — cap contrast at both ends.
- Cap maximum luminance across the board. Nothing should shout.
- Keep blue-heavy hues out of large fill areas.
- No neon, no saturated primaries.
- Every background effect — grain, ambient motion, blur — must be individually
  disableable, as a real persisted preference.

### Panel handling

Both Deck panels are product targets. Automatic LCD/OLED detection and gradient
adjustment is **product intent, not a built feature**. OLED is validated; LCD is
not.

## Typography

**UI face:** humanist geometric sans, generous x-height, open apertures.
Candidates: Inter, Instrument Sans, General Sans. Legible on a 7-inch panel at
~50 cm.

**Wordmark face:** warmer, rounder than the UI face — soft terminals,
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

### Screen entry — transition first, then a staggered entrance

*Client decision, 2 August 2026. Governs every screen added from here.*

1. **The screen transition happens first.** No element entrance begins while the
   screen itself is still travelling. The signal is `StackView.onActivated`,
   never a timer set to the transition's duration.
2. **Elements animate in after the screen settles**, rising and fading into
   place on a slight stagger.
3. **Stagger by visual reading order**, not source-file order. Keep delays
   subtle and **cap the number of steps**, so a dense screen does not become
   usable noticeably later than a sparse one.
4. **A slight overshoot and a single soft bounce.** Entrances cross their resting
   place once and come back. Tactile, not elastic. This is rule 1 above, not an
   exception to it.
5. **Input remains authoritative.** Focus and controls are usable immediately.
   Input may finish or interrupt an entrance; an entrance must never consume,
   queue, or reject the next action. Every screen with an entrance exposes a way
   to settle it and calls that from its own input handling. A launch pressed
   during the game-artwork entrance settles the artwork immediately and captures
   it, rather than degrading to the fallback.
6. **Do not stagger blindly.** Window-level furniture — the hint bar — holds
   still. Modals, confirmations and the launch and quit surfaces keep their own
   motion. Do not animate every decorative child.
7. **Share the tokens.** Cadence, duration, travel distance, and overshoot live
   in the `Bulan` singleton. No raw per-screen values, and no second
   near-identical copy of the same animation.

An entrance overshoot uses `motionEntranceOvershoot`, **not**
`motionOvershoot` — the latter is tuned for a 4% focus scale change and would
move a screen-scale translation by about a pixel. The reverse is equally wrong:
focus motion uses `motionOvershoot`.

**One implementation each.** `BusyDots.qml` is the only waiting indicator;
`FocusBloom.qml` the only halo, one per screen and moved to the focused item;
`HintBar` one bar owned by the window, which screens and popups feed by
declaring `hintBarVisible` / `hintLeftHints` / `hintRightHints`, a screen naming
the popup that owns input through `hintOwner`.

**The screen transition carries a real runtime blur.** The client rejected
opacity-as-blur on 2 August 2026 and required a real one, accepting the cost
knowingly. Gated to the stack's `busy` window, so a settled screen carries no
layer. Its Deck cost is **still unmeasured**. It blurs the whole stack, the
atmosphere included — **a visual consequence the client has not yet judged.**

## Values a client review settled

On the OLED Deck, 28 July 2026:

| Token | Value | Outcome |
|---|---|---|
| `atmosphereGrainOpacity` | `0.03` | Confirmed, doing its job |
| `sizeCaption` | `16` | Confirmed, legible without leaning in |
| `motionOvershoot` | `0.7` | Confirmed |
| `motionFocusMs` | `180` | Changed from the brief's `140` — evolution, not deviation |

On Windows, at the client's live review, 2 August 2026:

| Token | Value | Outcome |
|---|---|---|
| `motionTransitionMs` | `220` | The brief's figure, kept |
| `motionTransitionRise` | `space3xl` (64) | Kept — a spacing token, not a raw distance |

Evidence: `docs/validation/2026-07-28-deck-oled-review.md`. **The first table is
OLED-only**, and is not evidence for LCD appearance.

## Sound

Not built — v1.x. Soft struck tones, heavily damped, one pentatonic set, well
below dialogue level, with a global volume slider and a hard off switch.
Direction and cue list in `bulan-creative-brief.md`.

## Open

- Whether ambient background motion ships enabled or disabled by default.
- LCD-specific appearance and banding, deferred until LCD hardware exists.
- Three questions from the 15 August 2026 polish work sit in `TASK-BRIEF.md`.
