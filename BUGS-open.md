# Bulan — open defects

All three were found on hardware during the Deck review session on **28 July
2026**, on a Steam Deck OLED ("Galileo"), with the client pressing the buttons.
**Two are open; the third appears fixed and wants one confirming press.**

None of them needs a Deck to reproduce or to fix.

| # | What | Status |
|---|---|---|
| 1 | A is dead after dismissing the pairing PIN panel | **Appears fixed** — confirmed in Game Mode, unconfirmed in Desktop Mode |
| 2 | The carousel's third tile wraps visibly on every move | Open. Cosmetic, but "screams unpolished" — client's words |
| 3 | Pressing A on a fake host crashes the app | Open. Review tooling only; no real user hits it |

**Read "Instrumenting this" under defect 1 before adding any logging.** It
records which logging call actually reaches the Deck log, and which silently
does not. Getting that wrong cost most of a session.

**Read "The stale QML cache" under defect 1 too.** It is the reason defect 1 was
wrongly recorded as unfixed, and it will waste a whole session for anyone who
does not know about it.

---

# 1. A is dead after dismissing the pairing PIN panel

**Found** 28 July 2026 by the client. **Appears fixed** in `be874bf8`, confirmed
by hand in Game Mode on 28 July 2026.

**This entry was originally written up as an unfixed bug with two failed fix
attempts. That was wrong, and the reason is worth more than the bug.** The
second fix attempt was tested against a build whose interface was being served
from a stale on-disk cache, so the fix was never actually running. It was
recorded as "no effect" when it had almost certainly worked. Everything below is
kept because the diagnosis is still useful and the mechanism may recur — but read
it knowing the conclusion was reversed.

**Still worth one check:** it is confirmed in Game Mode, on a host part-way
through pairing. Press it once in Desktop Mode to be sure the fix is real and not
mode-specific.

This is **not** a regression of defect 1. Defect 1's fix is present and working,
and the related failure it shares a symptom with — check 1.2, the Client Settings
dropdown — was fixed in `be874bf8` and confirmed by hand. This is a third
mechanism behind the same symptom.

---

## Reproducing it

1. Host carousel, on a host that is **online but not yet paired**.
2. Press **A**. Pairing starts and the PIN panel appears — it displays a PIN to
   type *on the host PC*. It is not a text entry field in the app.
3. Press **B** to dismiss the panel.
4. Press **A** on any host.

**Expected:** A acts on the host.
**Actual:** A does nothing at all, permanently, until the app is restarted.
Every other button continues to work normally.

Confirmed reproducible across three builds, including two containing fix
attempts.

---

## Why this symptom is worth recognising

**Exactly one button dead, everything else fine.** That signature has now
appeared three times on this project from three different causes. It happens
because **A is the only button with no window-level shortcut standing behind
it** — X and START also reach the app through `Shortcut` elements in `main.qml`,
which fire regardless of what holds focus. A is handled only by the screen. So
any fault that stops the carousel being the thing listening takes out A alone
and leaves everything else looking healthy.

Do not read "only A is broken" as evidence of a binding or pairing problem. It
is the expected shape of a focus or key-routing fault on this screen.

---

## Leading hypothesis — unconfirmed

**The dismissed PIN panel still holds focus and swallows A.**

`HostPanel` handles `Keys.onReturnPressed` and `onEnterPressed` by calling
`accept()`. A sends Return (or Space, if the settings tab-chain mode is armed).
If a panel retains active focus after being hidden, then:

- **A** is consumed by the invisible panel — `accept()` on a non-editable panel
  just calls `close()`, which does nothing visible. The press is swallowed.
- **Every other button** is not handled by `HostPanel`, so it bubbles up to the
  carousel and works normally.

That accounts for the symptom exactly, including which buttons survive. It is
consistent with every observation, but it has **not been directly confirmed** —
see "the instrumentation failed" below.

---

## What has been ruled out

| Ruled out | How |
|---|---|
| **Defect 1 returning** (navigation mode stuck, A becomes Space) | The carousel now handles Return, Enter **and** Space. A stuck mode can no longer produce a dead A. |
| **The "Couldn't pair" message panel appearing and eating the press** | `pairingComplete()` never fires in the log — pairing starts and never reports back. No message panel is raised. |
| **A QML error breaking the handler** | No QML errors or warnings in the log beyond the known-harmless ones. |
| **The carousel losing focus entirely** | Other key handlers on the carousel demonstrably fire after the panel is dismissed, so the carousel is receiving keys. |

That last row is the important one, and it is what makes the hypothesis above the
leading one: the carousel **is** listening, so this is about A specifically being
consumed or transformed, not about the screen going deaf.

---

## The stale QML cache — the reason this was misdiagnosed

**The app caches its compiled interface on disk, and that cache can survive
rebuilds.** It lives at:

```
~/.var/app/io.github.laweirdo.MoonlightFork/cache/Moonlight Game Streaming Project/Moonlight/qmlcache/
```

On 28 July 2026 that directory held 19 files dated **25 July** — three days and
many rebuilds old. The app was loading those in preference to the interface in
the freshly installed build. Every rebuild genuinely installed; the app genuinely
ignored it.

**Symptoms, all of which were misread at the time:**

- Screens do not change no matter how many times you rebuild.
- A fix "does not work" when it is in fact never running.
- The build output is clean and reports recompiling — because it is. The build is
  not the problem.

**Clear it, and confirm it regenerates with today's date:**

```bash
rm -rf ~/.var/app/io.github.laweirdo.MoonlightFork/cache/Moonlight\ Game\ Streaming\ Project/Moonlight/qmlcache
```

**A second, compounding trap:** `flatpak run` on an already-running instance
raises the existing window rather than starting the new build, so an old process
can sit in front of you looking like the new one. Always check
`flatpak ps | grep -c MoonlightFork` is 0 before launching, and 1 after. This is
the same trap `BUILDING-MAC.md` records for `open -n` on macOS.

Between them these two cost most of a session and produced three wrong
conclusions in a row.

---

## Fix attempts, and what actually happened

Both are committed in `be874bf8`. Attempt 1 demonstrably fixed check 1.2.
Attempt 2 was recorded as having no effect, but was tested against the stale
cache described above and is the most likely reason this defect is now gone.

1. **Clearing the panel's own focus before handing it back.** A `FocusScope`
   gives active focus to whichever child last held it, so handing focus back to
   the parent could route it straight back into the panel that had just closed.
   Clearing first prevents that. **Fixed check 1.2**, the Client Settings
   dropdown route, confirmed by hand.

2. **`enabled: visible` on `HostPanel`, plus a focus handback on every hide.**
   A disabled item cannot hold active focus, so a hidden panel is incapable of
   keeping it. The second half covers `pairingComplete()`, which hides the PIN
   panel by setting `visible` directly and therefore never runs `close()` or its
   handback at all. **Almost certainly the fix for this defect** — it was tested
   against the stale cache and wrongly recorded as having no effect.

The hypothesis above — that the dismissed panel keeps focus and swallows the one
key it handles — is therefore probably correct, and attempt 2 is what addressed
it. It was never disproved; it was never actually tested.

---

## Instrumenting this — solved, use `console.warn`

**`console.log()` from QML does not reach the Deck log. `console.warn()` does.**

This was established the hard way. A first attempt logged focus state on every A
press with `console.log()` and produced **not one line** — including at a moment
when A demonstrably worked, since pairing had started and that only happens
through the A handler. The handler ran; the log stayed empty. That silence was
briefly read as "the handler never fired", which is the opposite of the truth and
sent the diagnosis down the wrong path entirely.

`console.warn()` was later used for defect 2 and worked immediately, printing as
`Qt Warning:` lines. Use it. `qDebug()` from C++ also reaches the log.

**Verify your logging appears at all before drawing any conclusion from its
absence.** That is the whole lesson.

---

## Suggested next steps

1. **Get working logging first.** Nothing below is worth doing blind.
2. **Confirm or kill the hypothesis** by logging the window's active focus item
   at the moment A is pressed, after the panel has been dismissed.
3. If the panel is holding focus, the structural fix is probably to stop
   `HostPanel` claiming Return/Enter unconditionally — it should only accept
   them while it is genuinely on screen — rather than continuing to fight over
   who holds focus.
4. Consider whether **pairing still being in flight** matters. The log shows
   pairing starts and never completes when the panel is dismissed early, and the
   host stays unpaired. It is not obviously related to the dead button, but it
   is an untidy state that no session has looked at.

---

## Related, noticed in passing

`HostCarousel.qml` triggers repeated Qt warnings:

```
Parameter "event" is not declared. Injection of parameters into signal
handlers is deprecated.
```

Several key handlers use `event.accepted = true` without declaring `event`. It
works today and is only a warning, but when that injection is eventually removed
those statements will throw, and each one sits **after** the action it guards —
so the visible behaviour would survive while key propagation silently broke.
Worth fixing before it becomes a mystery. Not urgent, not related to this bug.

---

# 2. The carousel's third tile wraps visibly on every move

**Found** 28 July 2026 by the client, who described it as: *"navigating to the
3rd PC appears to animate in the incorrect direction. It should smoothly
transition into the center from the right, but it seems to roll over toward the
right and come in from the left."* **Still open. Not yet attempted.**

Reproduce with `MOONLIGHT_FAKE_HOSTS=mixed`, which gives exactly three hosts.
Press left and right; the effect is clearest arriving on the third.

## What the diagnostics proved

`console.warn` was added to `PathView.onCurrentIndexChanged` logging
`currentIndex`, `offset` and `count`, plus a 400ms timer logging the settled
offset. The full trace is reproducible in a minute; the finding was:

| currentIndex | settled offset |
|---|---|
| 0 | 0.000 |
| 1 | 2.000 |
| 2 | 1.000 |

So `offset = (count - index) mod count`, and **every single-step press moves the
offset by exactly one unit** — never two. Observed across roughly twenty presses
in both directions with no exception.

**This rules out the obvious explanation.** If the carousel were choosing the
wrong way round the loop, a one-step press would move the offset by two units.
It never does. The selected tile genuinely travels the short way and enters from
the correct side.

## What is actually happening

`pathItemCount` is 3 and there are 3 hosts, so the items fill the entire path
loop with no slack. On every move, the tile that is not one of the two visible
neighbours must wrap from one end of the path to the other — it crosses from the
left slot to the right slot, or back, in a single frame.

`HostCarousel.qml` already mitigates this: delegates draw only when
`|index − currentIndex| <= 1`, which is meant to hide exactly that tile. The
binding re-evaluates the instant `currentIndex` changes, i.e. at the *start* of
the animation, so on paper the wrapping tile is hidden before it moves.

It is evidently not quite hidden in time. **This is a frame-timing problem, not a
direction problem** — which is why it reads as a roll rather than as an obvious
jump.

Three is the worst possible host count for this. `HANDOFF.md` already records
that `PathView` changes its spacing behaviour at exactly three items and that
working this out cost a session; this is the same component and the same
threshold.

## Suggested approaches, in the order they seem worth trying

1. **Give the loop slack.** If `pathItemCount` exceeds `count`, the items no
   longer fill the path and the wrapping tile can sit in the gap instead of
   crossing the visible arc. **Careful:** `pathStretch` in this file exists
   precisely because spacing is `1/count` below `pathItemCount` and
   `1/pathItemCount` above it, so changing `pathItemCount` changes the geometry
   the neighbours depend on. Expect to re-derive `pathStretch`.
2. **Hide the wrapping tile more decisively** than a `visible` binding — for
   example holding it at zero opacity through the transition, so there is no
   frame in which it can be drawn mid-wrap.
3. **Confirm the host count is the trigger** by testing with four or five fake
   hosts. If the artefact disappears above three, that confirms the loop-is-full
   reading and points squarely at approach 1.

Budget two or three build-and-look cycles. This does **not** need real hardware —
it reproduces against the fake host list on any machine, which is why it was
deferred out of the hardware session rather than chased there.

---

# 3. Pressing A on a fake host crashes the app

**Found** 28 July 2026, incidentally, during defect 2's diagnosis.

`MOONLIGHT_FAKE_HOSTS` marks its hosts as online and paired, so `actConfirm()`
walks past the pairing branch and tries to open the game library for a machine
that does not exist. The app dies.

**Consequence for review sessions:** fake host mode is usable for the carousel
and nothing beyond it. Any check that involves pressing A to completion needs a
real host. Worth knowing before planning a session around it.

`actConfirm()` already returns early on fake hosts in the *unpaired* branch
(`if (root.useFakeHosts) return`). The same guard is missing on the path that
opens the library.
