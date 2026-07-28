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

~~**Ready count excludes unpaired hosts from both figures.**~~ **Overturned by the
client, 28 July 2026.** The rule was: "N of M ready" counts paired hosts only, so
a discovered-but-unpaired machine appears in the carousel without inflating the
denominator, on the reasoning that it is not yours to count until you have paired
it.

Seen in use it reads wrong. With Steambox unpaired and Shoebox online the line
said **"1 of 1 ready"** while two machines were plainly on screen, so the count
contradicted the carousel beside it — which looks like a fault rather than a
principle. The client wants **"1 of 2"**: the denominator is machines you have,
not machines you have finished setting up. **Not yet implemented.**

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

## Client review, 28 July 2026 — six changes wanted

Given on the Mac after the wrap fix, watching the real build. **None of these are
started.** They are recorded here because this is the screen they belong to; the
sequencing question is `ROADMAP.md`'s.

| # | What the client said | What it means here |
|---|---|---|
| 1 | *"The far tile jarringly disappears instead of shifting farther or fading out."* | The wrap fix traded a tile crossing the screen for a tile vanishing. Not accepted. The far tile should **travel further out and fade**, not cut. |
| 2 | *"Text stays static at the bottom of the screen. The text should be part of the carousel."* | The focused host's name, status and address are drawn in a fixed block anchored above the hint bar. They should move with the selection instead of sitting still while the tiles move under them. |
| 3 | *"It read '1 of 1 ready' instead of '1 of 2' when Steambox was unpaired."* | **Reverses a decision recorded below.** Discovered-but-unpaired hosts were deliberately excluded from both figures. The client wants them in the denominator: the count is of machines you have, not machines you have finished setting up. |
| 4 | *"Waking should not create a popup. It should create a 'loading' overlay, perhaps with 3 animated bouncing dots, until the host is awake or fails to wake."* | `actWake()` currently raises `HostPanel` with *"Give it a moment to come back."* and returns. It should hold a determinate-feeling waiting state and resolve on the host coming back **or failing to**, which means the screen has to notice both. |
| 5 | *"Left arrow key turns the carousel into an infinite scroll until right arrow key is pressed. Right arrow behaves correctly."* | **Fixed** in `0a305af2`. The mouse-hover handler, not the key handler — tiles slide under a stationary cursor and are treated as though the user pointed at them. Hover-to-focus is unchanged; only which hover events count. |
| 6 | *"On 2 hosts, even on the leftmost host selected, I see the host that would've been on the right appear faded on the left."* | `BUGS-open.md` defect 4, seen at rest rather than in motion. With two hosts the non-focused tile sits exactly on the loop's join, which is one loop position drawn at two different screen positions. |

**Item 5 is fixed. Four of the remaining five — 1, 2, 4 and 6 — are cheaper after
the carousel's engine is replaced than before it.** 1 and 6 are the loop's join; 2 needs per-tile
positions the current component does not expose. See the note below.

---

## The component underneath is the wrong shape — recommendation, not yet decided

`PathView` exists to move items endlessly around a **closed path**. This carousel
**clamps** at both ends and never wraps. Everything in defects 2, 4 and 6, and
client review items 1 and 6, is that single mismatch:

- items fill the loop exactly at low host counts, so one must always be crossing
  the join;
- the join is at a visible screen position, so the crossing is visible;
- the component picks its own direction round the loop, and picked wrong;
- at two hosts the join *is* a resting position, so a tile is drawn on the wrong
  side at rest.

Two sessions have now worked around this rather than removing it, and the
workarounds are themselves what the client is objecting to.

**The alternative is to position the tiles directly** — a `Repeater` with an
animated `x` per tile — which removes the loop, the join, the direction guessing
and the special-casing by host count all at once, and hands over the per-tile
positions items 1 and 2 need.

**What that costs.** `PathView` was chosen for reasons still recorded under
*Decisions* below, and they were good ones: it interpolates scale and opacity
along its path for free, and `StrictlyEnforceRange` centres the focused item with
no arithmetic. Replacing it means writing both by hand. More code in exchange for
total control.

Estimated at about a session, contained to `HostCarousel.qml` and `HostTile.qml`,
and reviewable offline: the fake-host presets and the frame-by-frame tracing
method are both in place.

**Recommended, and awaiting the client's decision.**

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

`MOONLIGHT_FAKE_HOSTS` accepts `none`, `one`, `offline`, `mixed` and `many`.
**The host count changes the carousel's behaviour**, so pick deliberately: `mixed`
is three, which is where the loop is exactly full and worst; `many` is five, which
is above the threshold and behaves correctly. `offline` leads with a host that is
unreachable *and* cannot be woken. It swaps a fixed
host list into the carousel so every state can be reviewed without pairing or
unpairing real machines, and it is the reason the model is injectable — which is
what makes this screen testable at all. Inert unless set.

`MOONLIGHT_INITIAL_VIEW=qrc:/gui/GlyphProof.qml` opens the glyph proof sheet, which
also previews the hint bar in situ.

Note that `QT_QPA_PLATFORM=offscreen` cannot render shader effects — this is why
glyph colour is baked in at import rather than tinted at runtime with `MultiEffect`.
