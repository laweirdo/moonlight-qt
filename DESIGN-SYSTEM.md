---
kind: current-authority
authority: design-system
read_when:
  - a-visual-value-is-involved
history_policy: replace-not-append
---

# Bulan — design system

This is the clean-slate visual contract for new Bulan surfaces. Legacy screens
may still consume older `Bulan.qml` tokens while they await migration; they do
not establish precedent for new work.

## Composition

- Native reference canvas: 1280×800. Scale proportionally in desktop windows,
  but keep every interactive focus target at least 64×64 on the reference
  canvas.
- Screens are composed when still: one clear focal element, generous negative
  space, minimal permanent chrome and no ornament that competes with content.
- Warm light identifies the source or action; cool blue is its reflected
  response. Status is always paired with text and never conveyed by colour
  alone.
- New Bulan screens instantiate no stock Qt Quick visual controls.

## Colour and type

Runtime values live in the `Bulan` singleton. Use semantic tokens; never place
a raw visual value in a product screen.

| Role | Token | Value |
|---|---|---|
| Ground | `bgBase` | `#0D1024` |
| Deep ground | `bgBaseOled` | `#080A18` |
| Surface | `bgSurface` | `#171B33` |
| Focus/source | `accentPrimary` | `#FFD9A0` |
| Focus bloom | `accentGlow` | `#FFB865` |
| Reflection | `secondary` | `#8A93C2` |
| Primary text | `textPrimary` | `#F4EDE2` |
| Secondary text | `textSecondary` | `#A8AECB` |

- UI and status copy: bundled Inter Medium.
- Destination, game and overlay headings: the real bundled Fraunces Semibold
  instance, never synthetic bold applied to Regular.
- Add only tokens required by an accepted surface. Do not build a second theme
  object or pre-tokenize future work.

## Motion

| Interaction | Contract |
|---|---|
| Focus | 180 ms, one soft overshoot, reserved bounds |
| Press | 80 ms, immediate response |
| Home or overlay handoff | 220 ms, interruptible |
| Reflection | One ripple, then still |

- Never bounce twice, loop foreground motion, or delay the next input.
- The host moon rises once and settles into the header. A focused game lifts
  within space reserved for its larger state, so artwork and copy never clip.
- Connection motion uses a second `Image` with the existing artwork URL. It
  never uses `grabToImage` or a memory-backed screenshot.
- Trays dim and slightly recede the mounted library. Blur is optional only when
  smooth on Steam Deck; dimming is the required fallback.

## Voice

Warm, brief, second-person and quietly confident. Front-facing screens show no
protocol, port, error-code or stack-trace language. Detailed diagnostics remain
in the application log or advanced settings.
