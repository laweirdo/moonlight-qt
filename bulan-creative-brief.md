---
kind: current-authority
authority: creative-direction
read_when:
  - a-visual-or-copy-decision-is-stuck
history_policy: replace-not-append
---

# Bulan — creative direction

**Project:** a UI/UX-focused fork of the Moonlight game streaming client,
targeting Steam Deck
**Name meaning:** *Bulan* = "moon" in Indonesian
**Platform:** Steam Deck — 7-inch 1280×800 LCD and 7.4-inch OLED, handheld,
controller-only input
**Tech stack:** Qt / QML, custom components throughout
**Upstream:** moonlight-qt (GPLv3)

This file owns *why* Bulan looks and sounds the way it does. `DESIGN-SYSTEM.md`
owns the rules and values that follow from it; `ROADMAP.md` decides what private
v1 actually requires. Superseded directions and the original logo exploration
are in `docs/design-rationale/creative-history.md`.

## 1. Positioning

**Moonlight is a tool. Bulan is a place you arrive.**

Moonlight's identity reads as competent open-source utility: cold blue, flat,
functional. Bulan's job is to feel like **first-party console system software
that happened to be made with love** — the thing you'd believe shipped in the
box.

Every design decision should answer one question:

> *Would this look out of place next to a console home screen?*

**Brand statement:** *Your rig, reflected — wherever you are.*

**Tone target:** playful but not childish. Warm but not soft. Confident but not
cold.

## 2. Core concept — reflection

> **The moon doesn't make its own light. It reflects the sun. Bulan doesn't
> render your game — it reflects your PC.**

Remote play *is* reflection. That makes the name functional rather than
decorative, and it hands over a complete visual system: moon and still water,
source and reflection, warm light above and cool ground below.

Use this metaphor to resolve ambiguity. When unsure how something should look,
ask what "reflection" would do. Superseding one logo direction does not supersede
the concept — it is the invariant everything else is built on.

## 3. The mark, as it stands

| Asset | Status |
|---|---|
| Horizontal corner wordmark, `app/res/bulan_logo_horiz.svg` | **Final for its role.** Do not redesign or substitute it |
| Vertical lockup | Built from the client's two supplied sources, used on the splash |
| Centred-logo screens | **Waiting on the client.** A corner wordmark must not be enlarged or recomposed into a centred mark; the client will design and supply the vector files |
| App icon | Installed under the application ID; the desktop entry reads *Bulan* |
| Mascot | Deferred past v1 |

**Push the mark further toward pure geometry than feels comfortable.** The
personality is carried by behaviour, not decoration — motion and sound cover the
warmth, so the mark can afford to be more reductive than instinct suggests.

## 4. The balance, in one rule

Minimal and playful pull against each other, so give each a territory:

| Element | Register |
|---|---|
| Logo, icons, typography, layout | **Strictly minimal** — geometric, one weight, no ornament |
| Motion, sound, focus states, corner radii | **Playful** — soft overshoot, warm bloom, generous rounding |

> The interface should look **composed when still** and feel **delighted when
> touched.**

## 5. Voice and copy

Warm, brief, second person, quietly confident. Technical language lives in
Advanced settings and nowhere else.

| Context | Copy |
|---|---|
| Scanning | *"Looking for your PC…"* |
| Host idle | *"Ready when you are."* |
| Host offline | *"Couldn't reach Desktop-PC. Still on the same network?"* |
| First launch | *"Let's find your PC."* |

**Never** put a stack trace, error code, or protocol name on a front-facing
screen.

## 6. Sound identity — a key differentiator

Not built; v1.x. `DESIGN-SYSTEM.md` records the constraints. The cue list:

| Cue | Spec |
|---|---|
| Focus move | 40 ms muted mallet, alternating between two pitches |
| Confirm | Two-note rise |
| Back | Single lower note, shorter tail |
| Connect success | Gentle ascending arpeggio plus air swell |
| Connect failure | Low damped tone — no buzz, no harshness |
| Toggle | Soft dry tick |

Tuned to a single pentatonic set. This is functional, not stylistic: pentatonic
intervals contain no dissonant pairs, so no sequence of rapid inputs can produce
a sour combination. People play at 2 am next to a sleeping partner — hence the
hard off switch.

## 7. Guardrails

### Design

- **Reference Switch 2's *discipline*, not its *assets*.** Take the principles —
  high contrast, fast focus, generous spacing, restrained ornament. No borrowed
  icon shapes, no lookalike home-screen chrome, no Nintendo-adjacent naming.
  **Do not collect Switch 2 interface screenshots**; having their actual screens
  in the moodboard produces imitation rather than interpretation.
- **Do not reuse or recolor Moonlight's existing mark.** Bulan needs a clean,
  unrelated identity.
- **Custom components only.** Stock components are precisely what makes
  Moonlight read as a utility. Every button, list, slider, toggle, and dialog is
  drawn from scratch.
- **Controller-first, always.** Minimum touch/focus target 64×64 px at native
  Deck resolution.

### Legal

- **moonlight-qt is GPLv3.** The fork must carry the licence and clearly credit
  upstream — a *"Built on Moonlight"* line in About is both required practice and
  good manners.
- Distinct branding helps here: it prevents users mistaking this build for
  official Moonlight.

### Engineering boundary

Retain upstream discovery, pairing, streaming, and platform infrastructure. New
or rebuilt Bulan visual controls are custom; that does not require replacing
every inherited screen or subsystem at once.

## 8. Long-term deliverables

The creative production list, and a reference when visual work is blocked.
**`ROADMAP.md`, not this list, decides what private v1 requires.**

1. **Primary mark** — full-colour, mono, inverse, plus safe-area and
   minimum-size specs
2. **App icon** — 512, 256, 128, 64, 32 px
3. **Wordmark lockups** — horizontal, stacked, icon-only
4. **Boot / splash animation** — ≤1.2 s, skippable
5. **Colour tokens** — as a QML singleton *and* design-token JSON
6. **Icon set** — navigation, status, and Steam Deck controller glyphs. Custom
   Deck glyph vectors are **not** required for private v1: their practical
   shapes are identical to the accepted XInput set, and Deck detection stays
   meaningful even when it resolves to that art
7. **Sound pack** — 8–12 cues, normalized, OGG
8. **One-page brand rules sheet**

Steam library artwork was removed from this list on 2 August 2026 — see
`docs/design-rationale/creative-history.md`.
