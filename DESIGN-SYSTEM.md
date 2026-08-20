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
Superseded directions, and the mapping for source comments citing "creative
brief §4/§6/§8": `docs/design-rationale/creative-history.md`.

## Where the values live

**`app/gui/Bulan.qml` is the authority on every token value**, each commented
with what the number is and why. This file records the rules and what a client
review settled, never the token list — two copies of a number drift.
`app/gui/BulanTokens.qml` is the proof sheet's review copy and must stay
synchronized.

## The design frame

**Every value here is measured against one composition,
`Bulan.designWidth` × `designHeight` — 1280×800, the Deck panel.** `main.qml`
lays the application out at that size and scales that one frame to fit the
window. **No screen asks how large the window is.** *Client decision, 16 August
2026:* proportional only — a larger display buys breathing room down each side,
never a column, a re-flow or a breakpoint. `main.qml` and `GameTile.qml` carry
what scaling costs.

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

`Bulan.qml` carries the rest: hover, pressed, hairline, gradient stops, glass.

**Lines.** Two weights only, `hairlineWidth` and `focusRingWidth` — never a raw
number or a spacing step divided down.

**Popups.** One glass treatment — the `popupGlass*` tokens, `radiusXl` and
`PopupMotion`, on a `FocusScope` last in its screen — never a stock `Dialog`.

### Depth, not darkness

**True black is rejected as a default** — Bulan should read as dusk, not a void.
Depth comes from texture and gradation:

| Technique | Application |
|---|---|
| Vertical gradient | `gradientBaseTop` → `gradientBaseBottom`, sky into water |
| Radial glow | Warm bloom behind the focused element, `accentPrimary` at 3–6% |
| Film grain | Fine monochrome noise, static — animated reads as video noise |
| Background blur | Artwork behind menus, gaussian plus scrim: felt, not read |
| Vignette | Barely-there edge darkening, ~8%, drawing the eye inward |

Grain also breaks up the **colour banding** dark gradients are prone to.

### Non-negotiables

- The palette must survive a dark room at 1 am.
- **No pure black, no pure white** — cap contrast at both ends and cap maximum
  luminance. Nothing should shout.
- Keep blue-heavy hues out of large fills. No neon, no saturated primaries.
- Every background effect must be individually disableable, as a real persisted
  preference.

### Panel handling

Both Deck panels are product targets. Automatic LCD/OLED detection and gradient
adjustment is **intent, not a built feature**. OLED is validated; LCD is not,
and stays deferred until LCD hardware exists.

## Typography

**UI face:** humanist geometric sans, generous x-height, open apertures, legible
on a 7-inch panel at ~50 cm. **Wordmark face:** warmer and rounder — soft
terminals, **rounded not bubbly**; the tell for "playful but mature" is subtle
corner radii, not cartoon weight. **Licensing:** ship only **SIL OFL** fonts, so
QML embedding stays clean under GPLv3.

Sizes run `sizeDisplay` 56 → `sizeCaption` 16. Bind `font.pixelSize`, never
`font.pointSize`.

## Motion

**Fast and confident**, not elaborate.

| Interaction | Spec |
|---|---|
| Focus / hover | Scale to 1.04 plus a soft moonglow bloom, **180 ms**, ease-out with barely-there overshoot |
| Screen transition | Vertical reveal with motion blur, **220 ms** — content ascends like something surfacing |
| Press | Scale to 0.97, 80 ms, immediate |
| Ambient background | Slow parallax, very low contrast, pausable. **Not built — v1.x** |

### Rules

1. **Never bounce twice.** One settle, done.
2. Nothing animates for longer than the user's next input can arrive.
3. **Input always interrupts animation.** No exceptions.
4. Ambient motion must be disableable in one toggle.

### Screen entry — transition first, then a staggered entrance

*Client decision, 2 August 2026. Governs every screen added from here.*

1. **The screen transition happens first.** No entrance begins while the screen
   is still travelling. The signal is `StackView.onActivated`, never a timer set
   to the transition's duration.
2. **Elements animate in after the screen settles**, rising and fading on a
   slight stagger.
3. **Stagger by visual reading order**, not source order, and **cap the steps**
   so a dense screen is not usable later than a sparse one.
4. **A slight overshoot and a single soft bounce** — tactile, not elastic; rule
   1 above, not an exception to it.
5. **Input remains authoritative.** Controls are usable immediately; an entrance
   never consumes, queues or rejects the next action. Every screen with one
   exposes a way to settle it and calls that from its own input handling.
6. **Do not stagger blindly.** Window furniture holds still; modals and the
   launch and quit surfaces keep their own motion.
7. **Share the tokens.** Cadence, duration, travel and overshoot come from the
   `Bulan` singleton.

An entrance overshoot uses `motionEntranceOvershoot`, **not**
`motionOvershoot`, which is tuned for a 4% focus scale and would move a
screen-scale translation by about a pixel. The reverse is equally wrong.

**One implementation each.** `BusyDots.qml` is the only waiting indicator;
`FocusBloom.qml` the only halo, one per screen, moved to the focused item; one
`HintBar`, owned by the window, which screens and popups feed by declaring
their own hints and naming whichever popup owns input.

**Two things belong to the window, not to a screen, and neither takes the
transition.** The **atmosphere** is one instance behind everything, which never
moves, fades or blurs with navigation — screens surface over a world that holds
still, routes are transparent, and a future ambient gradient animates that one
instance (*20 August 2026*). The **onboarding crescent** is drawn once, so
crossing between first run and discovery moves one object while everything else
takes the ordinary blur, fade and travel (*16 August 2026*). **Named exceptions
that stay named** — no per-route animation; a third needs its own decision.
`FLOW.md` records the routes.

**Two blur scopes.** Navigation blurs the screens alone, gated to the stack's
`busy` window, so a settled screen carries no layer. A modal blurs the complete
scene, atmosphere included, and stands navigation blur down while it is up, so
nothing is blurred twice. Opacity-as-blur was rejected on 2 August 2026 for a
real one, cost accepted; that Deck cost is **still unmeasured**.

**Startup.** The logo dissolves in over `motionSplashFadeMs` (300 ms, OutCubic),
holds for `onboardingSplashHoldMs`, dissolves out, and only then does the first
real screen appear — never crossfaded with it. Input reverses the dissolve from
wherever it is, scaled by the current opacity, so a skip is never a cut. Opacity
only, on a startup clock kept apart from `motionTransitionMs`. *20 Aug 2026.*

## Values a client review settled

**OLED Deck, 28 July 2026 — OLED-only, not evidence for LCD.**
`atmosphereGrainOpacity` `0.03`, `sizeCaption` `16` and `motionOvershoot` `0.7`
all confirmed; `motionFocusMs` moved from the brief's `140` to `180` —
evolution, not deviation.

**Windows, at the client's live review, 2 August 2026.** `motionTransitionMs`
`220` kept as the brief wrote it, and `motionTransitionRise` kept at `space3xl`
(64) — a token, not a raw distance.

Evidence: `docs/validation/2026-07-28-deck-oled-review.md`.

## Sound

Not built — v1.x. Soft struck tones, well below dialogue level, with a volume
slider and a hard off switch. Direction and cue list:
`bulan-creative-brief.md`.

## Open

- Whether ambient background motion ships enabled or disabled by default.
- Whether the `lineHeight*` tokens ship or are dropped — nothing binds
  `Text.lineHeight`, and wiring them in reflows every screen.
