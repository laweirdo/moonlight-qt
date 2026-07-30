# Host carousel — as built

This is the durable authority for the accepted host-carousel surface: component
inventory, navigation, state model, design decisions, compromises, known
unfinished work, and validation evidence. Application source is the objective
authority for what currently runs. Live branch, task, and build state belong in
`HANDOFF.md` and `TASK-BRIEF.md`.

Decision labels in this file have specific weight:

- **Invariant** — a standing product or interaction rule.
- **v1 decision** — accepted for private v1 and revisitable later.
- **Accepted evolution** — an intentional change from the original brief after
  client or hardware review.
- **Accepted compromise** — knowingly imperfect, with its cost recorded.
- **Provisional** — unfinished or awaiting a later client decision.
- **Superseded** — retained as history but no longer authoritative.

Screen targets **1280×800**, the Steam Deck panel.

**Completed 28 July 2026.** `PathView` is gone; the tiles are positioned
directly. The host's name, status, and address belong to its tile and travel
with it rather than being drawn separately near the bottom. Four commits provide
the implementation record:

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

**Invariant — controller-first operation.** Every action needed on this screen
is reachable without a mouse, focus remains visible, and B always has a
recoverable route.

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
`docs/retrospectives/DEFECTS-carousel.md` carries the full account, including a
filtering attempt that was committed as a fix and was not one.

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
| **Exactly one host** | No flanking neighbours. Verified: the composition holds — the tile remains centred and its own labels remain attached beneath it. |
| **Zero hosts** | Two stacked elements: `"you have no pc's lol"` in the display face, and an amber X glyph with `"Press to pair a PC"`. The hint bar reduces to *Add a PC* (emphasised) and *Client Settings*. |

The focus ring is amber in **every** focused state, online or not. Focus has to
read identically everywhere or it stops being a reliable signal; reachability is
carried by the halo, the monogram weight and the status line instead.

---

## Motion

All values from `Bulan.qml`, sourced from brief §6.

**Accepted evolution — focus timing.** The brief's original `140 ms` read
slightly too fast on the OLED Deck. The client accepted `180 ms` after hardware
review; this is a deliberate change rather than accidental drift.

| Interaction | Spec | As built |
|---|---|---|
| Focus change | 1.04, 140 ms, ease-out, barely-there overshoot | `Easing.OutBack`, `overshoot: 0.7`, `motionFocusMs: 180` |
| Press | 0.97, 80 ms, immediate | `Easing.OutCubic`, 80 ms |
| Carousel slide | — | Per-tile `Behavior` on position, scale, opacity and focus, all `motionFocusMs` on `Easing.InOutQuad` |

**Accepted compromise — travel easing.** This is the one value that is neither
transcribed nor measured.
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

## Durable decisions and accepted compromises

**v1 decision — directly positioned tiles, with no view component.** A
`Repeater` builds one tile per host, and each tile's place is a pure function of
how far its own index sits from the selection. That distance is clamped to two
slots either side:

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

**Superseded — `pathStretch`.** It existed only to compensate for `PathView`
spacing items `1/count` apart below `pathItemCount` and `1/pathItemCount` above
it, which put a neighbour in two different places depending on host count.
Owning the coordinates removed the thing it was compensating for.

**Accepted compromise — the tile is a monogram, not artwork.** The mockup marks
the circle "HOST ARTWORK"; the model has no concept of host artwork, so the tile
shows the first letter of the host name in the display face. It fills the space
meaningfully and needs no new asset. This remains the slot for future host
artwork.

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

**v1 decision — opening focus lands on the first reachable host**, not index 0.
Opening on an offline machine makes the screen look broken when a working one is
one press away.

**Superseded — ready count excludes unpaired hosts from both figures.** The
client overturned this on 28 July 2026, and `58de72f1` implements the replacement.
The old rule counted paired hosts only, on the reasoning that a machine is not
yours to count until you have paired it.

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

**v1 decision — `AddressRole` is presentational and additive.** The mockup shows
the address and the only existing route to it was `DetailsRole` — a translated
human-readable blob a view would have to parse back out. The new role touches no
discovery or pairing logic.

**Only a hairline separates the hint bar.** No filled band: the atmosphere gradient
is already at its darkest by the bottom of the screen.

**The hint bar's `emphasis` is per-item, not a rule.** Which action leads is the
screen's decision — a settings screen's primary action is not confirm. On this
screen Connect is emphasised: **amber glyph, unfocused label.**

**Invariant boundary — no stock visual control is instantiated.**
`import QtQuick.Controls` appears in `HostCarousel.qml` solely for the
`StackView` attached properties (`StackView.onActivated`), since this screen
pushes and pops through the app's existing StackView.

---

## Client review, 28 July 2026 — six changes wanted

Given on the Mac after the wrap fix, watching the real build. The table records
their durable disposition; `ROADMAP.md` owns sequencing for unfinished work.

| # | What the client said | Status |
|---|---|---|
| 1 | *"The far tile jarringly disappears instead of shifting farther or fading out."* | **Done** in `1d813d2e`. The tile now travels out past the screen edge while fading, because the engine gives it somewhere to go. |
| 2 | *"Text stays static at the bottom of the screen. The text should be part of the carousel."* | **Done** in `f0635789`. Every host carries its own name, status and address, which travel with its tile and grow and brighten into focus. |
| 3 | *"It read '1 of 1 ready' instead of '1 of 2' when Steambox was unpaired."* | **Done** in `58de72f1`. |
| 4 | *"Waking should not create a popup. It should create a 'loading' overlay, perhaps with 3 animated bouncing dots, until the host is awake or fails to wake."* | **Not started.** `actWake()` still raises `HostPanel` with *"Give it a moment to come back."* and never revisits it. It should hold a waiting state and resolve on the host coming back **or failing to**, which means the screen has to notice both — so this is more than a visual change. Phase D's *Waking PC* arriving early. |
| 5 | *"Left arrow key turns the carousel into an infinite scroll until right arrow key is pressed."* plus *"mouse hover still focuses the hovered host"* | **Closed.** Fixed in `8c40e196` and confirmed by the client with a mouse. See `docs/retrospectives/DEFECTS-carousel.md`, investigation 6. |
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

## Validation and retrospective

The rebuild was verified frame by frame at low host counts and accepted by the
client. The detailed defect evidence and failed workarounds are preserved in
`docs/retrospectives/DEFECTS-carousel.md`; the transferable component-selection
lesson is in `docs/retrospectives/DEBUGGING-LESSONS.md`.

---

## Known unfinished work and v1 compromises

This table records durable surface gaps, not the current task or branch.
`TASK-BRIEF.md` owns active implementation scope.

| Thing | Label | Durable state |
|---|---|---|
| **Connecting** | **Provisional** | Status line reads `"Connecting…"` and nothing else changes. No design exists yet. |
| **Host settings (SELECT)** | **Provisional** | Opens the old read-only details panel. The active task brief owns the replacement menu. |
| **Rename / Forget / Test Network** | **Provisional** | Not reachable from this screen. The upstream actions remain in `PcView.qml`; the task brief owns which ones enter the v1 menu. |
| **Host artwork** | **Accepted compromise** | The monogram is the current placeholder because the model has no artwork concept. |
| **Deck glyphs** | **v1 decision** | Deck hardware is detected and intentionally resolves to the practically identical XInput art. Custom Deck vectors are not required for private v1. |

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
| `two` | 2 | Low-count regression case; Steambox is discovered but **unpaired**, the state the ready count was wrong about |
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
