# Host carousel — as built

The repo is the source of truth for this screen, not the Figma file. This records
what exists, what was decided along the way, and what is deliberately unfinished.

Built at commit `c39437dc`. Screen targets **1280×800**, the Steam Deck panel.

---

## Components

| File | What it is |
|---|---|
| `app/gui/HostCarousel.qml` | The screen. Owns the model, the actions, the input map and the states. |
| `app/gui/HostTile.qml` | One host: circular tile, focus ring, monogram, and a name/status label shown only when *not* focused. |
| `app/gui/HintBar.qml` | The persistent bottom bar. Declarative contents; display-only. |
| `app/gui/ControllerGlyph.qml` | One button glyph, selected by semantic action and current controller. |
| `app/gui/HostPanel.qml` | Modal overlay: scrim, surface, title, body, optional text field. |
| `app/gui/Atmosphere.qml` | Shared ground: gradient, vignette, grain. |
| `app/gui/Bulan.qml` | Design tokens. The only place a colour, size, duration or scale is defined. |

Supporting, not part of this screen but changed for it:

| File | Change |
|---|---|
| `app/gui/computermodel.h/.cpp` | Added `AddressRole` (`model.address`). |
| `app/gui/sdlgamepadkeynavigation.cpp` | Y and Select given distinct keycodes; glyph-family detection; disconnect handling. |
| `app/gui/main.qml` | `Key_Call` falls through to settings. |
| `app/main.cpp` | Initial view is the carousel; `MOONLIGHT_FAKE_HOSTS` hook. |

---

## Navigation, as implemented

| Input | Key delivered | Behaviour |
|---|---|---|
| D-pad Left | `Key_Left` | Previous host. **Clamps** at the first. |
| D-pad Right | `Key_Right` | Next host. **Clamps** at the last. |
| D-pad Up | `Key_Up` | Inert, and **swallowed** — see note below. |
| D-pad Down | `Key_Down` | Inert, and swallowed. |
| **A** | `Key_Return` / `Key_Enter` | Connect to the focused host. On an **offline** host, attempts to wake it instead. On an **unpaired** host, starts pairing. |
| **Y** | `Key_Call` | Wake the focused host. |
| **X** | `Key_Menu` | Add a PC. |
| **START** | `Key_Hangup` | Client settings. |
| **SELECT** | `Key_Context1` | Host settings for the focused host. |
| **B** | `Key_Escape` | Handled by `main.qml`: quit confirmation at the root, back otherwise. |
| Mouse hover | — | Moves focus to the hovered host. |
| Mouse click | — | Focuses, then confirms. |

Up and Down are *accepted* rather than merely ignored. Left unaccepted they bubble
to the StackView and drag focus into toolbar chrome that this screen hides, at
which point the D-pad stops moving between hosts and there is no visible focus
anywhere.

### The input layer had to change for this table to be possible

Three of the five actions were unreachable before:

- **Y and START both sent `Key_Hangup`.** They were indistinguishable to QML, so
  "Y wakes, START opens settings" could not be expressed. Y now sends `Key_Call`.
- **SELECT was not mapped at all.** It now sends `Key_Context1`.

Both are reserved keys with no text meaning, so they cannot collide with typing in
a focused field. This follows the precedent `Key_Hangup` already set in this file.

`main.qml` still treats `Key_Call` as "show settings" at the StackView level, so Y
keeps its previous behaviour on every screen that does not claim it first. The
carousel claims it.

---

## States

| State | What is shown |
|---|---|
| **Focused, online** | Amber focus ring, full-strength halo, `"Ready when you are."` in amber, address beneath. |
| **Focused, offline** | Same ring, halo at 30%, monogram dimmed, `"Couldn't reach <name>. Still on the same network?"` — brief §8 verbatim. |
| **Focused, unpaired** | `"Not paired yet."` A starts pairing and opens the PIN panel. |
| **Status unknown** | `"Looking for your PC…"` — brief §8 verbatim. |
| **Connecting** | `"Connecting…"`. **Minimal, not yet designed.** |
| **Exactly one host** | No flanking neighbours. Verified: the composition holds — the tile stays centred and the detail block keeps its position, because it is anchored up from the hint bar rather than down from the carousel. |
| **Zero hosts** | Two stacked elements: `"you have no pc's lol"` in the display face, and an amber X glyph with `"Press to pair a PC"`. The hint bar reduces to *Add a PC* (emphasised) and *Client Settings*. |

The focus ring is amber in **every** focused state, online or not. Focus has to
read identically everywhere or it stops being a reliable signal; reachability is
carried by the halo, the monogram weight and the status line instead.

---

## Motion

All values from `Bulan.qml`, sourced from brief §6.

| Interaction | Spec | As built |
|---|---|---|
| Focus change | 1.04, 140 ms, ease-out, barely-there overshoot | `Easing.OutBack`, `overshoot: 0.7` |
| Press | 0.97, 80 ms, immediate | `Easing.OutCubic`, 80 ms |
| Carousel slide | — | `highlightMoveDuration: 140` — matches focus, so the tile and the view move as one |

**One Behavior per property, deliberately.** A `Behavior` retargets when its target
value changes mid-flight, so holding a direction tracks the input rather than
queueing one settle per press, and nothing ever bounces twice. No
`SequentialAnimation` anywhere on this screen.

`Easing.OutBack`'s own default overshoot is 1.70158 — about 10%, which reads as a
bounce. **0.7 lands near 3%.** The brief gives no number, so this is the one motion
value that is interpretation rather than transcription.

Controller presses have no release event to hang a state off, so the press scale is
driven by an 80 ms timer (`HostTile.flashPress()`). The mouse drives it directly
from `MouseArea.pressed`.

---

## Decisions not specified in the brief

**PathView, and two things it does that needed real work.** It was the right
primitive — scale and opacity are path attributes, so neighbour dimming is
declarative and `StrictlyEnforceRange` centres the focused item with no
arithmetic. But:

1. *Item spacing is `1/count` below `pathItemCount`, `1/pathItemCount` above.* A
   neighbour therefore sits at path fraction 0.0 with two hosts and 1/6 with three
   — one fixed geometry placed it in two different spots, and with three hosts the
   neighbours slid inward and overlapped the focused tile. Solving `x(fraction)` for
   both cases gives a single factor on the path's extent (`pathStretch`, 1.5 or
   1.0) that holds them still.
2. *PathView instantiates a wrapped neighbour.* Focused on the first host it drew
   the **last** one to the left, silently promising a host that pressing left can
   never reach. Delegates are now drawn only when `|index − currentIndex| ≤ 1`.

**The tile is a monogram, not artwork.** The mockup marks the circle "HOST
ARTWORK"; the model has no concept of host artwork, so the tile shows the first
letter of the host name in the display face. It fills the space meaningfully, needs
no new asset, and is self-evidently a placeholder. **This is the slot for real host
artwork.**

**Neighbours sit lower than the focused tile** (`hostTileNeighbourDrop: 75`),
measured off the mockup. It is what makes the row read as a shallow arc rather than
three circles on a rule.

**The detail block anchors up from the hint bar**, not down from the carousel. The
neighbours' labels overhang the carousel band by a variable amount, so chaining off
`pathView.bottom` let the block drift between the one-host and three-host cases.

**Opening focus lands on the first reachable host**, not index 0. Opening on an
offline machine makes the screen look broken when a working one is one press away.

**Ready count excludes unpaired hosts from both figures.** "N of M ready" counts
paired hosts only, so a discovered-but-unpaired machine appears in the carousel
without inflating the denominator. It is not yours to count until you have paired it.

**`AddressRole` was added to `ComputerModel`.** The mockup shows the address and the
only existing route to it was `DetailsRole` — a *translated* human-readable blob a
view would have to parse back out. The new role is presentational and additive; it
touches no discovery or pairing logic.

**Only a hairline separates the hint bar.** No filled band: the atmosphere gradient
is already at its darkest by the bottom of the screen.

**The hint bar's `emphasis` is per-item, not a rule.** Which action leads is the
screen's decision — a settings screen's primary action is not confirm. On this
screen Connect is emphasised: **amber glyph, unfocused label.**

**`import QtQuick.Controls` appears in `HostCarousel.qml`** solely for the
`StackView` attached properties (`StackView.onActivated`), since this screen pushes
and pops through the app's existing StackView. No stock control from that module is
instantiated in any Bulan screen.

---

## Deliberately unfinished

| Thing | State | Why |
|---|---|---|
| **Connecting** | Status line reads `"Connecting…"` and nothing else changes. | No design exists. Needs specifying. |
| **Host settings (SELECT)** | Opens a panel showing what the old grid's "View Details" showed. | The nav table routes SELECT here but no host-settings screen has been designed. |
| **Rename / Delete / Test Network** | **Not reachable from this screen.** | They live in `PcView.qml`, which is still in the tree but no longer the initial view. They need a designed home — most likely the host-settings screen above. |
| **Host artwork** | Monogram placeholder. | Model has no artwork concept; needs a design and a source. |
| **Deck glyphs** | `deck_*` resolves to the Xbox set. | Art not yet delivered. One line in `resolveGlyphFamily()` when it is. |

---

## Reviewing it without real hardware

```bash
MOONLIGHT_FAKE_HOSTS=mixed MOONLIGHT_SCREENSHOT=/tmp/shot.png QT_QPA_PLATFORM=offscreen \
  app/Moonlight.app/Contents/MacOS/Moonlight
```

`MOONLIGHT_FAKE_HOSTS` accepts `none`, `one`, `offline`, `mixed`. It swaps a fixed
host list into the carousel so every state can be reviewed without pairing or
unpairing real machines, and it is the reason the model is injectable — which is
what makes this screen testable at all. Inert unless set.

`MOONLIGHT_INITIAL_VIEW=qrc:/gui/GlyphProof.qml` opens the glyph proof sheet, which
also previews the hint bar in situ.

Note that `QT_QPA_PLATFORM=offscreen` cannot render shader effects — this is why
glyph colour is baked in at import rather than tinted at runtime with `MultiEffect`.
