# Bulan — open defects

Current as of **28 July 2026**, after the Windows session that replaced the
carousel's engine.

**The two carousel defects this file carried are both closed**, and they were
closed the way `SPEC-host-carousel.md` argued they should be: by removing the
component underneath rather than working around it a third time. **One new defect
is open**, found by the client watching the app start.

**Seven of the eight entries here are now closed.** Only defect 8, the top bar on
launch, is outstanding.

| # | What | Status |
|---|---|---|
| 1 | A is dead after dismissing the pairing PIN panel | **Closed.** Confirmed by hand in Desktop Mode, 28 July |
| 2 | The carousel's third tile wraps visibly on every move | **Closed.** The workaround was replaced along with the engine |
| 3 | Pressing A on a fake host crashes the app | **Fixed** in `d3c57f95`. Different mechanism than recorded |
| 4 | The carousel still wraps once per move at **two** hosts | **Closed** by the engine replacement. Verified frame by frame |
| 5 | The hint bar offers Wake on hosts that cannot be woken | **Fixed** in `402b37d4`, on the client's call |
| 6 | Left arrow runs the carousel away; right arrow is fine | **Closed.** Fixed in `8c40e196`; confirmed by the client with a mouse |
| 7 | The far tile vanishes instead of leaving | **Closed** by the engine replacement |
| 8 | Upstream's top bar is on screen for the first half-second | **OPEN.** Found by the client, 28 July |

---

# 8. Upstream's top bar is on screen for the first half-second — OPEN

**Found** 28 July 2026 by the client, watching the app launch.

> *"Before the carousel loaded, remnants of upstream's layout persisted,
> particularly its top bar."*

## Measured, not inferred

Timed with a probe that logged the bar's state every frame from startup:

```
t=...297  stackView completed, toolBar.visible=true
t=...864  after push,          toolBar.visible=false
```

**567 milliseconds.** That is not a frame of tearing — it is a third of a second
longer than the whole focus animation, and comfortably long enough to read as a
different application starting before Bulan does.

## The cause

The top bar is the window's `header` in `main.qml` and **it has no initial
visibility set, so it defaults to shown.** Nothing hides it until a screen asks
for it to be hidden, and a screen cannot ask until it has been pushed onto the
stack and activated.

Between those two moments the app runs `doEarlyInit()`, which brings up the
gamepad layer. The window is already mapped and painting throughout. So the bar
is not flashing — it is simply the correct, visible state of the app for as long
as startup takes.

**The default is the bug.** Every Bulan screen turns the bar off; only four
places ever turn it back on, and three of those are restoring it on the way out
of a screen that had hidden it.

## The shape of the fix, and its cost

Start the bar **hidden** and let the screens that want it ask for it, rather than
starting it shown and having every screen ask for it to go away.

The cost is that this inverts a default the whole app currently depends on. Four
files turn the bar off and four turn it on, and the ones that never mention it
at all — `AppView`, `SettingsView`, `PcView` — are relying on it being on. Those
would each need to claim it explicitly, and a missed one loses its toolbar
silently on a screen that is still upstream's.

**Estimate: small change, wide blast radius.** It touches every screen that has
a toolbar, including the upstream ones this fork has not rebuilt yet. Worth doing
deliberately rather than as a drive-by, and worth doing before Phase B rebuilds
the game grid, because the game grid is one of the screens that would have to
claim it.

**Not started.**

---

# 6. Left arrow runs the carousel away — closed

**Fixed** in `8c40e196`, at the second attempt — the first, `0a305af2`, was
reported as a fix and was not one. **Confirmed by the client with a mouse**, and
recorded here on 28 July 2026 after the fact; the check had been done and simply
never written down.

Hover no longer steers at all, client's call. `hoverEnabled` is off rather than
filtered, so the misleading events are never generated and there is no path from
pointer position to selection left to get wrong.

**This survived the engine replacement untouched**, as predicted: it was the
mouse handler, not the carousel component. That prediction being right is mild
evidence the diagnosis was right too, but the client's pass is what closed it.

**Worth generalising, and it is why this entry is kept rather than deleted:** any
hover-to-focus on a view whose items move contains this loop, it is not specific
to this carousel, and it cannot be fixed with the hover signals of the moving
item alone. The position `positionChanged` reports is relative to the item, so a
tile sliding under a still cursor changes it exactly as a moving cursor does.
Telling the two apart needs the pointer tracked in **screen** coordinates, above
the level of any individual item.

---

# Closed — 1, 2, 3, 4, 5 and 7

## 4 and 7 — closed by replacing the carousel's engine

Both were the same mismatch, and both are gone for the same reason. `PathView`
moves items endlessly around a **closed loop**; this carousel **clamps** and
never wraps. While the host count was at or below the number of tiles drawn, the
items filled the loop exactly, so one of them was always crossing the join — and
at two hosts the join was a *resting* position, which is why the second host
could be drawn on the wrong side while standing still.

The tiles are now positioned directly. Each one's place is a pure function of how
far its index sits from the selection, so there is no loop, no join and no
direction to guess.

**Verified frame by frame, not by looking at where things settled** — the
distinction that this project has now been burned by twice. A probe logged every
tile's position on every frame while the selection walked to both ends:

| Check | Result |
|---|---|
| Largest single-frame move by a visible tile, three hosts | **57px** |
| Largest single-frame move by a visible tile, two hosts | **61px** |
| A tile crossing the screen would show as | ~1280px |
| Times the second tile was drawn left of centre at two hosts | **0**, across 338 frames |

Defect 7 is closed by the same change for a different reason: the far tile now
has real off-screen space to retreat into, so it travels further out and fades
instead of being cut. Tiles were observed reaching well past both screen edges
at low opacity, which is exactly the exit the client asked for.

## 1. A is dead after dismissing the pairing PIN panel — closed

Fixed in `be874bf8`. Confirmed in Game Mode on the Deck and in Desktop Mode on
the Mac, 28 July. Not mode-specific.

That symptom — **exactly one button dead, everything else fine** — came from
three different causes over the project's life. It happens because A is the only
button with no window-level shortcut behind it, so anything that stops the screen
listening takes out A alone and leaves everything looking healthy. Do not read it
as a pairing or binding problem.

## 2. The carousel's third tile wraps visibly — closed

Fixed in `9c721e13` by hiding the crossing tile, **and the client rejected that
fix on sight** — the tile vanished instead of leaving, which became defect 7. The
whole workaround is gone now along with the component that needed it.

**The previous write-up ruled out the client's own explanation, and the client
was right.** It said the carousel could not be choosing the wrong way round its
loop, because every press moved the offset by exactly one unit. That figure was
the **settled** offset, and where something ends up cannot say which way it
travelled to get there.

## 3. Pressing A on a fake host crashes the app — closed

The recorded cause was that fake hosts are marked paired. That is half of it.
**Everything past the offline branch of `actConfirm()` addresses a machine by its
position in the real host list**, and a fake host's position means nothing there.
With two real machines paired, pressing A on the second fake host quietly opened
the **second real machine's** games and looked like it worked. Pressing A on the
fifth read off the end and segfaulted.

The silent wrong action was worse than the crash, and a crash is what got
reported. Assume any injectable-model debug hook has this failure mode until the
guard is shown to cover every branch.

## 5. The hint bar offers Wake on hosts that cannot be woken — closed

Fixed in `402b37d4`. The app can only wake a machine whose hardware address it
has learned, and it learns that from the host's own reply. **Shoebox never
provides one** — Sunshine reports all zeroes, which Moonlight correctly refuses
to store.
