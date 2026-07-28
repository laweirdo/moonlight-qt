# Next session — rebuild the carousel

Written 28 July 2026, at the end of the Mac session. Branch `bulan`, which is
pushed and matches the fork.

**Read `HANDOFF.md` first**, and in it *Hard-won knowledge* before anything else.
Then `BUGS-open.md` — two open defects, both this screen — and
`SPEC-host-carousel.md`, which carries the argument for what you are about to do
and the six review items driving it.

**This does not need a Steam Deck.** Everything below reproduces and is reviewable
on the Mac with the fake host presets.

---

## Why this session exists

The host carousel has been reviewed twice by the client and failed twice. Not
because either fix was wrong — the wrong-direction fault was real and is gone —
but because the component underneath cannot express what the design asks for, so
each fix has traded one artefact for another. The client rejected the second on
sight: *"the far tile jarringly disappears instead of shifting farther or fading
out."*

`PathView` moves items endlessly around a **closed loop**. This carousel **clamps**
at both ends and never wraps. Both open defects are that one mismatch.

**The client has decided: replace the engine, before starting the host settings
menu.** That decision is made. Do not re-open it.

---

## Objective 1 — replace the carousel's engine

Drop `PathView`. Position the tiles directly — a `Repeater` with an animated
position per tile — so the screen owns every coordinate instead of asking a
looping component for them.

`app/gui/HostCarousel.qml` and `app/gui/HostTile.qml`. Nothing else should need
to change.

### What it must still do

Reproduce the current look exactly. All of these are already tokens in
`app/gui/Bulan.qml` and none of them changes:

| | |
|---|---|
| `hostTileSize` | 324 |
| `hostTileSpread` | 338 — neighbour offset from centre |
| `hostTileNeighbourDrop` | 75 — how far neighbours sit below the focused tile |
| `hostTileNeighbourScale` | 0.64 |
| `motionFocusMs` | 180 — travel and focus, one duration |
| `motionOvershoot` | 0.7 — on the tile's own focus scale, not on travel |

Neighbour opacity is 0.5 and the focused tile is 1.0; the focused tile draws above
its neighbours.

**Note the `pathStretch` hack disappears.** It exists only to compensate for
`PathView` spacing items differently above and below three hosts. Owning the
positions removes the thing it was compensating for. Do not port it.

### What it must fix

Each of these is verifiable, and none of them is a matter of opinion:

1. **No tile is ever drawn crossing the screen.** There is no loop and no join,
   so nothing has anywhere to cross to.
2. **A tile leaving travels further out and fades.** This is the client's
   objection to the current fix and the reason the engine is being replaced —
   the old one cut the tile because it had nowhere to go. Now it does.
3. **Two hosts sit on the correct sides at rest.** Focused on the first host, the
   second is on the **right**. Today it can be drawn on the left.
4. **Direction always follows the index.** A higher index slides the row left, a
   lower one slides it right, always.
5. **Movement clamps.** No wrap, at either end, ever.
6. **Hover still does not move the selection.** Removed on the client's call this
   session; do not reintroduce it while rewriting the mouse handling. Click still
   selects and acts.

### The one thing you have to decide rather than copy

`PathView` was easing the travel itself. Positioning tiles by hand means choosing
that easing explicitly rather than inheriting it. **Reproduce the current feel
first and let the client judge it on screen** — do not redesign the motion in the
same change as the engine, or neither of you will know which one they are
reacting to.

`motionOvershoot` belongs on the focused tile's scale, where it already is. Travel
overshoot is a separate question and is not currently asked.

---

## Objective 2 — the text becomes part of the carousel

**Client's call, 28 July: the text belongs to each tile.**

Every host carries its own name, status and address, and they travel sideways with
its tile. The focused host's is large and full-strength; the neighbours' is small
and dimmed, as their labels already are. Moving the carousel moves everything as
one object.

This unifies something currently drawn twice: `HostTile` draws a small name and
status under unfocused tiles, and `HostCarousel` draws the focused host's name,
status and address separately, larger, lower down. After this there is one text,
which grows and brightens as its tile becomes focused.

**Do this in the same session but as a separate commit.** It is only cheap
*because* the engine work gives you per-tile positions, but it is a distinct
change and should be revertible on its own.

Watch the type sizes: `sizeTitleLg` (40) for the focused name and `sizeBodyLg`
(26) for the status are what the detail block uses today; the neighbour labels use
`sizeBodyLg` and `sizeBody`. Interpolating between them as a tile focuses is new
behaviour and worth showing the client.

---

## Objective 3 — the ready count includes unpaired hosts

Small, independent of everything above, and its own commit.

*"N of M ready"* counts paired hosts only, so with Steambox unpaired and Shoebox
online it read **"1 of 1 ready"** while two machines were plainly on screen. The
count contradicted the carousel beside it.

**The client wants "1 of 2":** the denominator is machines you have, not machines
you have finished setting up. This reverses a decision recorded in
`SPEC-host-carousel.md`, which has been struck through there.

`recount()` in `HostCarousel.qml`.

---

## How to know it worked

**Do not infer any of this from the outside.** Three sessions have been lost that
way and the tools to avoid it now exist.

### The build on screen is the one you made

The log's second line says so outright:

```
Build: bulan @ deck-test-1-67-gaf4dde45 | binary built "2026-07-28T17:38:06"
```

Commit and build time, both. `-dirty` means uncommitted changes.

### Nothing is drawn mid-crossing

The method that found the original fault, and it is the acceptance test for
objective 1. Add temporarily to the tile:

```qml
onXChanged: console.warn("TRACE i=" + index + " cur=" + <current>
                         + " x=" + Math.round(x)
                         + " op=" + opacity.toFixed(2) + " vis=" + visible)
```

plus a timer that walks the selection back and forth, then check that **no tile
whose opacity is above zero ever jumps more than half the screen width between
consecutive frames.** Remove both before committing.

`console.log` and `console.warn` both reach the log on the Mac. On the Deck only
`console.warn` does. Use `console.warn`.

### Every host count still loads

```bash
for SET in none one offline mixed many; do
  MOONLIGHT_FAKE_HOSTS=$SET MOONLIGHT_SCREENSHOT=/tmp/shot-$SET.png \
  QT_QPA_PLATFORM=offscreen app/Moonlight.app/Contents/MacOS/Moonlight
done
```

Then read the log for QML errors. **A broken screen does not look broken — it
silently falls back to upstream's grid**, which reads as "my build didn't take".

**`mixed` is three hosts and `many` is five.** The count changes the behaviour, so
pick deliberately. **There is no two-host preset and defect 4 needs one — add
it**, because two hosts is the client's real configuration and the case most
likely to be missed.

---

## Carried forward, both needing the client

- **The hover fix is unverified.** It was reported as fixed once when it was not.
  Hover events are no longer generated at all now, which is a stronger claim than
  last time, but nobody has watched it. One pass with a mouse over the carousel,
  holding left.
- **Judgement on the new motion**, once objective 1 is on screen. The client is
  the judge of when it reads right and expects two or three build-and-look cycles.

---

## Not this session

- **The host settings menu.** It is next, and the client has confirmed that order.
  Start it only if the carousel lands early, and ask first. Note that *"Forget
  PC"* is settled as the wording — removing a machine is Bulan forgetting the
  host, not the host forgetting Bulan, and the asymmetry is intended.
- **The wake overlay.** Review item 4: not a popup, a waiting state, *"perhaps
  with 3 animated bouncing dots"*, held until the host is awake **or fails to
  wake**. That last part makes it more than a visual change — the screen has to
  notice both outcomes, and today `actWake()` raises a panel and never revisits
  it. It is Phase D's *Waking PC* arriving early and deserves its own session.

---

## Rules that have not changed

- Branch from `bulan`, named once the task is known. Merge back on the client's
  sign-off, then delete it locally and on the fork.
- **Never commit to `master`.** It is a clean mirror of upstream and its only job
  is to fast-forward. `origin` is the client's fork; `upstream` is never pushed to.
- One commit per task, so each stays independently revertible.
- Custom components only. No Qt Quick Controls.
- Controller-first. If something only works with a mouse it is wrong.
- Every value comes from the `Bulan` singleton. If a token is missing, **say so
  and let the client add it** — never inline a value.
- The client is a creative director who does not read code. Explain what the app
  does, not what the code does, and name what things cost.

**Delete this file when the session it describes is done.**
