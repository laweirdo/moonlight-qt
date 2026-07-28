# Bulan — open defects

Current as of **28 July 2026**, after the Mac session.

**The three defects this file was created for are all closed**, and so are two of
the four found while closing them. **Two are open**, both on the host carousel and
both traceable to the same component choice. None of them needs a Deck.

| # | What | Status |
|---|---|---|
| 1 | A is dead after dismissing the pairing PIN panel | **Closed.** Confirmed by hand in Desktop Mode, 28 July |
| 2 | The carousel's third tile wraps visibly on every move | **Fixed** in `9c721e13`, but **the fix is not accepted** — see defect 7 |
| 3 | Pressing A on a fake host crashes the app | **Fixed** in `d3c57f95`. Different mechanism than recorded |
| 4 | The carousel still wraps once per move at **two** hosts | **Open.** Pre-existing, halved by defect 2's fix, not cured |
| 5 | The hint bar offers Wake on hosts that cannot be woken | **Fixed** in `402b37d4`, on the client's call |
| 6 | Left arrow runs the carousel away; right arrow is fine | **Fixed** in `8c40e196` — hover no longer steers. The first fix, `0a305af2`, did not work |
| 7 | The far tile vanishes instead of leaving | **Open.** Defect 2's fix, rejected on sight by the client |

**Two entries in the previous version of this file sent this session down the
wrong path.** Both are corrected below, and both failed the same way: a
conclusion was drawn from a measurement that could not see the thing it was being
used to rule out. That is the transferable lesson, and it is worth more than
either bug.

**Defects 2, 4 and 7 are very likely one problem.** `PathView` moves items
endlessly around a **closed loop**; this carousel **clamps** and never wraps.
`SPEC-host-carousel.md` carries the argument and a recommendation to position the
tiles directly instead. Two sessions have now worked around the mismatch rather
than removing it, and the workarounds are themselves what the client is now
objecting to. **Read that before fixing any of these individually.**

---

# 7. The far tile vanishes instead of leaving

**Found** 28 July 2026 by the client, looking at defect 2's fix. **Open.**

> *"The far tile jarringly disappears instead of shifting farther or fading out.
> Seems not polished."*

Defect 2's fix stops the tile crossing the screen by cutting it instantly the
moment it would start. The cut is instant **by design** — a fade-out would have
played while the tile was travelling, which is the artefact being removed — but
instant means visible, and it reads as a glitch rather than as an exit.

**What is wanted:** the far tile should **travel further out and fade**, i.e.
leave the way something leaves, rather than stop existing.

**Why it cannot simply be faded where it is.** The tile has nowhere to go. With
the loop exactly full its next position is on the other side of the screen, so
any motion during the fade is motion across the arc. There is no off-screen slot
for it to retreat into, because every slot is occupied.

That is the same sentence as defects 2 and 4, and it is why this is listed as one
of the four rather than as a separate piece of polish. Give the carousel real
off-screen space — which positioning the tiles directly does — and the tile can
simply continue outward and fade, which is what was asked for.

---

# 6. Left arrow runs the carousel away — fixed

**Found** 28 July 2026 by the client. **Cause confirmed by the client the same
day. Fixed in `8c40e196`, at the second attempt** — the first, `0a305af2`, was
reported as a fix and was not one. Wants one pass with a mouse to close.

**Not the same problem as defects 2, 4 and 7.** This one is the mouse handler,
not the carousel component, and it would have survived replacing that component
untouched.

> *"Left arrow key turns the carousel into an infinite scroll until right arrow
> key is pressed. Right arrow behaves correctly."*

## What has been ruled out, and how

**The key handler is not at fault.** `moveBy()` was called eight times in each
direction from a probe, logging the index each time: it stops dead at 0 going
left and at `count - 1` going right. The selection clamps. **This was measured,
not reasoned** — see `HANDOFF.md` on why that distinction matters on this
project.

So the index is not running away by itself. Something else is moving it, or the
motion is visual rather than a selection change.

## The cause — confirmed

**The mouse-hover handler feeds back into itself.** The client confirmed it: with
the pointer moved off the carousel, the left arrow behaves correctly.

`HostTile` has `hoverEnabled: true` and moves the selection on hover, so the
pointer and the D-pad agree about what is focused. But the tiles **move under a
stationary pointer**. A press shifts the row, a different tile arrives beneath the
cursor, its `entered()` fires, the selection moves again, the row shifts again.

That is self-sustaining, and it would be **direction-dependent** exactly as
reported: which way it runs depends on which side of centre the pointer is
resting, and any other input can knock it out of phase — which matches "until
right arrow key is pressed".

**This is not new.** The handler had the same shape before this session; only the
call it makes changed. It was reported now because the pointer happened to be
resting over the carousel.

## The failed fix, and why it failed

**`0a305af2` kept hover-to-focus and tried to filter the false events out**, on
the theory that `entered` cannot distinguish the pointer arriving at a tile from
a tile arriving at the pointer, but `positionChanged` fires only for genuine
pointer movement.

**That theory is wrong.** The position `positionChanged` reports is relative to
the tile, so a tile sliding under a still cursor changes it exactly as it changes
`entered`. The filter admitted everything it was meant to exclude.

The mistake is worth naming precisely, because it is the same one this project
has now made three times in a week: **the evidence that `entered` fires on item
movement is also evidence that the item's other hover signals do**, and that was
in hand before the replacement was chosen. A conclusion was drawn from a property
that had already been demonstrated not to hold.

**There is no local signal that distinguishes the two cases.** Telling them apart
requires tracking the pointer in screen coordinates, above the level of any
individual item. That is real machinery.

## The fix that works

**Hover no longer steers at all** — client's call, reversing the original design.
Clicking a host still selects it and acts on it.

`hoverEnabled` is off rather than filtered, so the misleading events are never
generated and there is no path from pointer position to selection left to get
wrong. On a screen whose whole premise is a gamepad, that was the proportionate
answer.

**Worth generalising:** any hover-to-focus on a view whose items move contains
this loop. It is not specific to this carousel, it will not be removed by
replacing the carousel's component, and it cannot be fixed with the hover signals
of the moving item alone.

---

# 4. The carousel wraps once per move at two hosts

**Found** 28 July 2026 on the Mac, while verifying defect 2's fix. **Open.**

**This is the client's real configuration.** They have two paired hosts, so this
is what the screen does in daily use, not an edge case.

## What happens

With two hosts, moving the selection one way is clean and moving it back drags
the non-focused tile across the screen — it leaves one edge and reappears at the
other in a single frame, exactly as defect 2 did at three hosts.

**The client also sees it at rest, which is worse than the moving case:**

> *"On 2 hosts, even on the leftmost host selected, I see the host that would've
> been on the right appear faded on the left. This seems to be purely a visual
> glitch as I must navigate to the right."*

That is the same cause seen standing still. With two hosts the non-focused tile
sits **exactly on the loop's join**, and the join is one loop position drawn at
two different screen positions — the far left end of the path and the far right
end are the same point on the loop. Which one it is drawn at depends on the phase
left behind by the last move, so the second host can be shown on the left when it
is logically to the right. The tile is real and focusable; only its side is
wrong.

Before defect 2's fix it did this in **both** directions. It now does it in one.
So the fix halved it rather than curing it.

## Why defect 2's fix does not reach it

That fix hides the tile that has to cross, and identifies it by index: the one
that is not a neighbour of either end of the move.

With two hosts **every tile is a neighbour of every other tile**, so no tile is
ever identified as the crossing one and nothing can be hidden. There is also
nothing to hide it in favour of — with two hosts there is exactly one neighbour,
and blanking it would leave a lone tile on an empty screen.

## The cause, which is the same as defect 2's

`PathView` lays its items out around a closed loop. When there are no more hosts
than the carousel draws at once, the items fill that loop exactly, so one of them
is always crossing the join. The join sits at a visible screen position, so the
crossing is visible.

Above that threshold `PathView` never builds the surplus tiles at all, nothing
has to cross, and new neighbours slide in from beyond the edge correctly. That is
verified: `MOONLIGHT_FAKE_HOSTS=many` traces completely clean, before and after.

## The only fix that reaches every host count

**Feed the carousel a list that is always longer than the number of tiles it
draws**, padded with entries that render nothing. That puts every host count into
the regime that already works, and would retire defects 2 and 4 together along
with the special-casing both needed.

The cost is real, and it is why it was not done in the same session:

- The carousel is fed either the live `ComputerModel` (C++) or the review-mode
  `ListModel`. Padding means putting a layer in front of both.
- `ComputerModel` cannot be indexed from QML without adding an accessor to
  `computermodel.h`, or mirroring it through a `Repeater` the way `counter`
  already does in `HostCarousel.qml`.
- A mirror has to track hosts appearing, disappearing and changing state. A
  single bad binding on this screen takes the whole screen down and drops the app
  onto upstream's interface — see `HANDOFF.md`.

Estimate: most of a session, with real regression risk on the screen every
session begins with.

---

# 5. The hint bar offers Wake on hosts that cannot be woken — fixed

**Found** 28 July 2026 on the Mac, while answering the wake question.
**Fixed** the same day in `402b37d4`, on the client's decision.

The hint bar offered **Y Wake** on any unreachable host without checking whether
the app could actually wake it. It can only wake a machine whose hardware address
it has learned, and it learns that from the host's own reply. **Shoebox never
provides one** — Sunshine reports all zeroes, which Moonlight correctly refuses
to store — so Y on Shoebox could only ever answer *"Shoebox didn't tell us how to
wake it."* `Steambox` does provide one (`e8:9c:25:7d:14:9d`) and wake works there.

This was the rule the client settled on the Deck in July with one case missed:
*offer Wake only where waking means something.* That fix covered hosts already
awake; this covers hosts that cannot be woken at all.

The review-mode `offline` list now leads with a host in exactly that state, so it
is on screen when the preset opens. Until this change nothing could show the case
at all — the fake hosts derived `wakeable` from being offline, which is precisely
the assumption at fault.

---

# Closed — 1, 2 and 3

Kept short. The diagnosis that still matters has moved to `HANDOFF.md`. What is
here is what each one turned out to be, and where the previous write-up was wrong.

## 1. A is dead after dismissing the pairing PIN panel — closed

Fixed in `be874bf8`. Confirmed in Game Mode on the Deck on 28 July, and in
**Desktop Mode on the Mac** the same day. Not mode-specific.

Three A presses each started a fresh pairing after a dismissal, where a dead A
would have produced only the first.

The test needed a host that was online but **not yet paired**, and getting one is
harder than it sounds — see `HANDOFF.md`. Removing a PC in Moonlight does not
unpair it; the host goes on recognising this machine, so it reports itself paired
the moment it is added back and no PIN panel ever appears. The unpair has to
happen on the host, in Sunshine's own settings.

Noticed in passing: each abandoned pairing sits open until the host hangs up on
it (`RemoteHostClosedError`), so dismissing the PIN panel leaves a half-finished
handshake rather than cancelling it. Harmless and invisible; recorded so it is
not rediscovered as something new.

## 2. The carousel's third tile wraps visibly — fixed, and it was two faults

**The previous write-up ruled out the client's own explanation, and the client
was right.** It said the carousel could not be choosing the wrong way round its
loop, because every press moved the offset by exactly one unit. That figure was
the **settled** offset, and where something ends up cannot say which way it
travelled to get there. The measurement could not see the thing it was being used
to rule out.

Tracing every tile's position frame by frame found two separate faults:

1. **The direction genuinely was wrong on one transition.** Going from the second
   host to the third, every visible tile slid *right* and wrapped round the
   screen — two full crossings for a one-step press. `PathView`'s default is to
   take the shorter way round its loop, which is correct for something that wraps
   and wrong for this, which clamps. The direction is now stated in `moveBy()`
   rather than inferred.
2. **The crossing tile was revealed too early.** It was hidden by testing where
   the selection was *going*, which let it back on screen at the instant it began
   crossing. It is now tested against where the selection came from as well, so it
   is hidden for the whole crossing and fades up in place on arrival.

Also corrected: the previous write-up's first suggested approach — raise
`pathItemCount` above the host count to give the loop slack — **cannot work.**
`PathView` spaces items by dividing the loop by the *host count* whenever the
host count is at or below `pathItemCount`, so the items fill the loop exactly and
raising the number changes nothing. Slack exists only when the host count
**exceeds** `pathItemCount`, which is the opposite adjustment. See defect 4.

## 3. Pressing A on a fake host crashes the app — fixed, and it was not what was recorded

The recorded cause was that fake hosts are marked paired, so the action walks past
the pairing branch into opening a game list for a machine that does not exist.
That is half of it. The missing half is why nobody could pin it down.

**Everything past the offline branch of `actConfirm()` addresses a machine by its
position in the real host list**, and a fake host's position means nothing there.
With two real machines paired, pressing A on the second fake host quietly opens
the **second real machine's** games and looks like it worked. Pressing A on the
fifth reads off the end of the list and segfaults.

So whether it dies depends on how many real machines happen to be paired — which
is why it reproduced on the Deck and could not be reproduced here until it was
looked for deliberately. `MOONLIGHT_FAKE_HOSTS=mixed` on this Mac does not crash
at all; it silently acts on the wrong machine, which is worse than crashing.

One guard now covers every branch below rather than one guard per branch, and it
says so on screen rather than returning silently — a silent A is
indistinguishable from defect 1.
