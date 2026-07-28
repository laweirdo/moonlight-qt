# Host carousel — as built

The repo is the source of truth for this screen, not the Figma file. This records
what exists, what was decided along the way, and what is deliberately unfinished.

Screen targets **1280×800**, the Steam Deck panel.

**Rebuilt 28 July 2026 on `feat/carousel-engine`.** `PathView` is gone; the tiles
are positioned directly. The host's name, status and address now belong to its
own tile and travel with it, rather than being drawn separately near the bottom
of the screen. Four commits:

| Commit | What |
|---|---|
| `1d813d2e` | The engine: tiles positioned directly, `PathView` removed |
| `f0635789` | The text belongs to the tile |
| `ee801af1` | `hostTileLabelGap`, the clear space under each circle |
| `58de72f1` | The ready count counts machines you have |

---

## Components

| File | What it is |
|---|---|
| `app/gui/HostCarousel.qml` | The screen. Owns the model, the actions, the input map and the states. |
| `app/gui/HostTile.qml` | One host: circular tile, focus ring, monogram, and the host's own name, status and address, which grow and brighten as it takes focus. |
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
| Mouse hover | — | **Nothing.** Reversed by the client on 28 July 2026; it used to move focus to the hovered host. |
| Mouse click | — | Focuses, then confirms. |

**Why hover was dropped.** The rule was that hover should move focus so the
pointer and the D-pad could never disagree about what is selected. That assumed a
still carousel. These tiles move, and a moving view cannot tell the pointer
arriving at a tile apart from a tile arriving at the pointer — both raise the same
hover events at the same item, and there is no local signal that separates them.
Acting on them turned one keypress into a selection that walked away on its own.
`BUGS-open.md` defect 6 carries the full account, including a filtering attempt
that was committed as a fix and was not one.

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
| Focus change | 1.04, 140 ms, ease-out, barely-there overshoot | `Easing.OutBack`, `overshoot: 0.7`, `motionFocusMs: 180` |
| Press | 0.97, 80 ms, immediate | `Easing.OutCubic`, 80 ms |
| Carousel slide | — | Per-tile `Behavior` on position, scale, opacity and focus, all `motionFocusMs` on `Easing.InOutQuad` |

**The travel easing is the one value that is neither transcribed nor measured.**
`PathView` used to ease its own travel and never exposed the curve, so replacing
it meant choosing one. `Easing.InOutQuad` was picked as the closest reproduction
of how the old one read, and **the client accepted it on screen on 28 July as
good enough for v1**. It is not a considered motion design; it is a faithful
copy of an accident. If the motion is ever revisited deliberately, start here.

**One clock for the whole move.** A tile's position, drop, scale, fade and the
size and brightness of its text all run for `motionFocusMs` on the same curve, so
a host travels, shrinks, dims and hands over its label as one object rather than
five. The tile's own focus scale keeps `motionOvershoot` and is the only sprung
part of the motion.

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

**The tiles are positioned directly — no view component.** A `Repeater` builds one
tile per host, and each tile's place is a pure function of how far its own index
sits from the selection. That distance is clamped to two slots either side:

| Distance from selection | Where it is | How it looks |
|---|---|---|
| 0 | Screen centre, at `focusY` | Full size, full strength, drawn above the rest |
| 1 | ±`hostTileSpread`, dropped by `hostTileNeighbourDrop` | `hostTileNeighbourScale`, half opacity |
| 2 or more | ±2 × `hostTileSpread` | Invisible, off the edge of the screen |

**The clamp at two slots is what gives the carousel its off-screen room**, and it
is the whole reason a departing tile can leave rather than being cut. It also
bounds the motion: a host at the far end of a long list parks one slot beyond the
edge rather than at some arbitrary distance, so anything sliding into view always
travels exactly one slot however far down the list it started.

**Three things this removed rather than fixed.** There is no loop, so nothing can
cross the screen. There is no join, so no tile can be drawn on the wrong side at
rest. There is no route to choose, so direction always follows the index — the
old component picked its own way round and picked wrong at exactly three hosts.

**What it cost.** `PathView` interpolated scale and opacity along its path for
free and `StrictlyEnforceRange` centred the focused item with no arithmetic. Both
are now written by hand. More code in exchange for total control, and the trade
was made deliberately after two sessions of workarounds were rejected.

**`pathStretch` is gone and must not be reintroduced.** It existed only to
compensate for `PathView` spacing items `1/count` apart below `pathItemCount` and
`1/pathItemCount` above it, which put a neighbour in two different places
depending on the host count. Owning the coordinates removed the thing it was
compensating for.

**The tile is a monogram, not artwork.** The mockup marks the circle "HOST
ARTWORK"; the model has no concept of host artwork, so the tile shows the first
letter of the host name in the display face. It fills the space meaningfully, needs
no new asset, and is self-evidently a placeholder. **This is the slot for real host
artwork.**

**Neighbours sit lower than the focused tile** (`hostTileNeighbourDrop: 75`),
measured off the mockup. It is what makes the row read as a shallow arc rather than
three circles on a rule.

~~**The detail block anchors up from the hint bar**, not down from the carousel.~~
**Gone.** There is no detail block any more — the text belongs to each tile. The
problem it solved has gone with it: the block used to drift between the one-host
and three-host cases because the neighbours' labels overhang the carousel band by
a variable amount, and a label that belongs to its own tile cannot drift relative
to it.

Each label is instead anchored to **its own circle's drawn edge**, at
`hostTileLabelGap`. That scale already carries the neighbour scale, the focus
scale and the press dip, so the gap under the artwork is constant through all
three rather than being measured from anything that moves independently.

**Opening focus lands on the first reachable host**, not index 0. Opening on an
offline machine makes the screen look broken when a working one is one press away.

~~**Ready count excludes unpaired hosts from both figures.**~~ **Overturned by the
client, 28 July 2026, and now implemented** in `58de72f1`. The old rule counted
paired hosts only, on the reasoning that a machine is not yours to count until
you have paired it.

Seen in use it read as a fault rather than a principle: with Steambox unpaired
and Shoebox online the line said **"1 of 1 ready"** while two machines were
plainly on screen, so the count contradicted the carousel beside it. The
denominator is now **every machine in the carousel**.

The numerator is unchanged and still means *ready to stream* — online **and**
paired. An unpaired host is visible and selectable but A starts pairing rather
than connecting, so counting it as ready would promise something the button does
not deliver.

`pairedCount` was renamed `totalCount`, because it no longer counts what its name
said.

**The two-host review preset now carries an unpaired host** — Steambox,
discovered but not paired, which is the state the client was looking at when they
reported this. No preset had one before, so the rule could not be reviewed on
screen at all. That is how it survived being wrong.

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

| # | What the client said | Status |
|---|---|---|
| 1 | *"The far tile jarringly disappears instead of shifting farther or fading out."* | **Done** in `1d813d2e`. The tile now travels out past the screen edge while fading, because the engine gives it somewhere to go. |
| 2 | *"Text stays static at the bottom of the screen. The text should be part of the carousel."* | **Done** in `f0635789`. Every host carries its own name, status and address, which travel with its tile and grow and brighten into focus. |
| 3 | *"It read '1 of 1 ready' instead of '1 of 2' when Steambox was unpaired."* | **Done** in `58de72f1`. |
| 4 | *"Waking should not create a popup. It should create a 'loading' overlay, perhaps with 3 animated bouncing dots, until the host is awake or fails to wake."* | **Not started.** `actWake()` still raises `HostPanel` with *"Give it a moment to come back."* and never revisits it. It should hold a waiting state and resolve on the host coming back **or failing to**, which means the screen has to notice both — so this is more than a visual change. Phase D's *Waking PC* arriving early. |
| 5 | *"Left arrow key turns the carousel into an infinite scroll until right arrow key is pressed."* plus *"mouse hover still focuses the hovered host"* | **Fixed** in `8c40e196`, **not yet watched by a human.** See `BUGS-open.md` defect 6. |
| 6 | *"On 2 hosts, even on the leftmost host selected, I see the host that would've been on the right appear faded on the left."* | **Done** in `1d813d2e`. Verified frame by frame: across 338 frames at two hosts, the second tile was drawn left of centre zero times. |

**Five of the six are done, and one — the wake
overlay — is untouched and belongs to a session of its own.**

Three further calls were made while building items 1–3, all reversible and all
the client's to overturn:

- **The display face is used for every host name**, not only the focused one. One
  text that grows into another cannot change typeface on the way.
- **The status line is two texts cross-faded**, not one that swaps. The focused
  copy is brief §8 verbatim and is the app's voice; at neighbour size the full
  offline sentence wraps and shouts louder than the host that is selected. Short
  form for neighbours, full form for focused.
- **The address stays the focused host's alone.** Under every tile it would
  compete with the names.

**The empty band left at the bottom of the screen was reviewed and accepted** by
the client on 28 July. Moving the text onto the tiles vacated the lower third;
the composition sits high and the space is deliberate.

---

## The component underneath was the wrong shape — DONE, 28 July 2026

Kept because the argument is what justified the rebuild, and because the same
reasoning will be needed the next time a stock view is reached for.

`PathView` exists to move items endlessly around a **closed path**. This carousel
**clamps** at both ends and never wraps. Everything in defects 2, 4 and 7, and
client review items 1 and 6, was that single mismatch:

- items fill the loop exactly at low host counts, so one must always be crossing
  the join;
- the join is at a visible screen position, so the crossing is visible;
- the component picks its own direction round the loop, and picked wrong;
- at two hosts the join *is* a resting position, so a tile is drawn on the wrong
  side at rest.

Two sessions worked around this rather than removing it, and both workarounds
were what the client ended up objecting to. **The estimate — about a session, two
files — held.** It came to four commits and cost no regressions in any host
count.

**The transferable lesson is about the second workaround, not the first.** The
first fix was wrong and was replaced. The second was *correct* — it did stop the
tile crossing the screen — and the client rejected it anyway, because trading a
visible wrap for a visible disappearance is not progress. When a fix has to trade
one artefact for another, that is the signal that the component is the problem,
and it arrives one session before anyone wants to hear it.

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

`MOONLIGHT_FAKE_HOSTS` accepts `none`, `one`, `two`, `offline`, `mixed` and
`many`. It swaps a fixed host list into the carousel so every state can be
reviewed without pairing or unpairing real machines, and it is the reason the
model is injectable — which is what makes this screen testable at all. Inert
unless set.

| Preset | Hosts | Why it exists |
|---|---|---|
| `none` | 0 | The zero-host screen |
| `one` | 1 | No flanking neighbours; checks the composition holds |
| `two` | 2 | **The client's real host count**, and Steambox is discovered but **unpaired** — the state the ready count was wrong about |
| `offline` | 3 | Leads with a host that is unreachable *and* cannot be woken |
| `mixed` | 3 | The mockup's arrangement, one reachable and two not |
| `many` | 5 | More hosts than the carousel draws at once |

The host count no longer changes the carousel's *behaviour* — that was a property
of `PathView` and it went with it — but it still changes the composition, so
check more than one.

**On Windows this runs windowed rather than offscreen**, which renders more
faithfully than the Mac's offscreen path. See `BUILDING-WINDOWS.md`.

`MOONLIGHT_INITIAL_VIEW=qrc:/gui/GlyphProof.qml` opens the glyph proof sheet, which
also previews the hint bar in situ.

Note that `QT_QPA_PLATFORM=offscreen` cannot render shader effects — this is why
glyph colour is baked in at import rather than tinted at runtime with `MultiEffect`.
