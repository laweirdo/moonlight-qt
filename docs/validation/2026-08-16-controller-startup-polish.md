---
kind: validation-report
authority: dated-evidence
read_when:
  - investigating-history
history_policy: append-never-edit
---

# Controller hold navigation, hint cleanup, startup flash

**Windows review station, 16–17 August 2026.** Branch `polish-input-startup`,
cut from `master` at `e05adf7b`. Three fixes, three commits, each shown to the
client before it was committed.

Qt 6.9.3 / MSVC Release, built with the `qmake` + `jom` recipe in
`BUILDING-WINDOWS.md`. `scripts\build-arch.bat` was not used — it is the wrong
tool for a review station, as that guide records.

## What was changed

| Commit | Change |
|---|---|
| `7a0123c4` | Held d-pad and analogue navigation repeat like a held arrow key |
| `462699ec` | The redundant L1 "Switch tab" entry leaves the hint bar |
| `207894c7` | A remembered host's library is placed without revealing the carousel |
| `1b5fe61b` | Defects found reviewing the above (see "Review", below) |

## Passed — machine checks

**Repeat-clock unit tests.** 12 passed, 0 failed. New standalone Qt Test target
at `tests/navigationrepeat/`, deliberately **not** a `SUBDIRS` entry of
`moonlight-qt.pro`, so nothing about the shipping build or the packaging scripts
changed because a test exists. Build and run it with:

```
qmake tests\navigationrepeat\navigationrepeat.pro
jom
tst_navigationrepeat.exe
```

The cases that matter are the ones a controller cannot demonstrate on demand: no
repeat before the initial delay, the switch from the 350 ms delay to the 100 ms
interval, one repeat per poll however late the poll arrives, a duplicate press
from a second source not restarting the delay, and the SDL tick wrap at 49 days.
The suite was run before the implementation existed and failed to compile for
the expected reason, then run again after.

**Release build.** `jom` exit 0 at every stage. No new compiler warnings.

**`qmllint`.** Exit 0 on both changed QML files. Each was compared against its
own version on `master` **in place**, in the same directory, so the import
resolution was identical on both sides:

- `AppView.qml` — warning counts identical, category for category.
- `HostCarousel.qml` — categories unchanged; `[unqualified]` rose from 67 to 69.
  Both additions are further references to `stackView` and `openAppsForHost`,
  context properties that already produce that warning on neighbouring lines and
  that `qmllint` cannot resolve. Nothing new in kind.

The `[index]` category appears on both files and on `master`. The 16 August
report's category list did not mention it; it is pre-existing, not introduced
here.

**`scripts/context-audit.py`.** Exit 0. See "Documentation" below.

## Passed — screens

**Hint bar.** Recent and Library captured off a fresh build with the fake-game
preset. No "Switch tab" entry in the bar; Recent and Library still carry their
LB/RB glyphs on the tab strip itself; Start and Select reflowed with no manual
spacing.

**Remembered-host startup, real host.** A real launch with no fake presets
reached `Steambox`'s actual library, captured six seconds in. Real box art at a
scaled resolution renders correctly — a case `HANDOFF.md` had listed as never
tested, answered incidentally here.

## Client, on real hardware

An Xbox 360 controller was attached throughout; the log confirms it
(`"XInput Controller" vendor=3537 product=105f type=2 -> xinput`).

The client walked the hold-navigation matrix and reported it good: one tap gives
one move, a hold moves immediately then repeats after a pause, releasing stops
it, and the clamped ends of a row produce no delayed burst — across the
carousel, Recent, Library and Settings, on both the d-pad and the stick. Holding
a direction across a Settings open and close produced no runaway navigation, and
disconnecting a pad mid-hold left no stuck key.

That is the whole of what the client reported performing. Stage 2 and stage 3
were approved from the evidence above rather than from a reported walk-through,
so the following remain **unconfirmed** and are not claimed as passed:

- the launch watched live, for a carousel frame between splash and library;
- B landing on an already-settled carousel, and staying past the grace window
  without the library reopening;
- A on a carousel host still getting the ordinary vertical transition — the
  check that proves the immediate push did not become the default;
- A still working after visiting Client Settings, and after opening and closing
  the Resolution dropdown. `REVIEW-CHECKLIST.md` treats the loss of A after
  Settings as a stop-the-review failure, so this one matters most;
- Start, Select, and L1/R1 tab switching after the input change.

## Not tested

**No Deck ran**, in Desktop Mode or Game Mode. Game Mode is the gap that matters
most: Steam Input sits between the hardware and the application there, and none
of this work has been through it.

**Two controllers at once was not exercised.** Only one pad was attached, so the
per-controller held-direction tracking — the reason releasing or unplugging one
pad does not cancel a direction the other is still pushing — is reasoned and
unit-tested but never driven by two real devices.

**The remaining three startup cases were not run**: remembered host offline,
remembered UUID no longer present, and no remembered host at all. Each depends
on the review station's stored preferences, which were left untouched
deliberately. Only the reachable case was exercised.

**macOS and the WiX MSI were not built.**

## Review, 17 August 2026

The branch was reviewed against `master` by a separate reader before merge. It
found one blocking defect, which is fixed in `1b5fe61b`.

**Focus loss taken mid-hold could kill controller navigation outright.** Holding
a d-pad direction, losing window focus, releasing while unfocused, and returning
left that direction recorded as held forever: the first poll's
`SDL_JoystickUpdate()` generates the queued release and the stale-input flush on
the following line discards it. One stale bit prevents the suppression flag from
lifting, and the flag is global, so every direction on every controller went
dead until that one button was pressed and released again. Reachable by an
ordinary alt-tab, and routinely by the Steam overlay on a Deck. **Introduced by
this branch** — the previous code kept no state that could go stale.

Two smaller items were fixed with it: `disable()` cleared its held-source tables
after cancelling rather than before, latching the same flag on with nothing left
to lift it (self-healing, but latent), and the startup bootstrap carried a branch
whose two arms were identical.

**One behaviour change the branch had not noticed it made.** Because an
established analogue direction is tested before the vertical-first chain, rolling
from a held Right into down-right now continues right until the stick re-centres;
the old code re-resolved every 150 ms and switched to Down at once. The client
accepted the new behaviour on 17 August 2026 as the intended trade for not
chattering near the diagonal. The comment that claimed the ordering was unchanged
has been corrected — it was true only for a direction acquired from neutral.

Review points **not** acted on, deliberately: a request to cut the comment volume
in `navigationrepeat.h` and the bridge, which is the established style of the
surrounding file and mostly predates this task; the tests' literal timing values;
and `NavigationRepeatState`'s constructor parameters. The latter two are the
interface the accepted plan specified.

After the fixes: release build clean, 12 unit tests passing, `qmllint` exit 0 on
`HostCarousel.qml` with one fewer `[unqualified]` warning than before. **The
repro was not driven on hardware** — alt-tab away and back while holding the
d-pad is the check that proves it, and it is not yet confirmed.

## Confirmed after the review, 17 August 2026

Appended rather than folded into the sections above, which record what was true
when they were written.

The client ran four checks against the final merged build and reported all four
good: **alt-tab away and back while holding the d-pad** (the repro for the defect
`1b5fe61b` fixed, and the one thing on this branch that had only ever been
reasoned about), **A after visiting Client Settings**, **A after opening and
closing the Resolution dropdown**, and **a held direction moving, pausing, then
repeating**. That closes the stop-the-review item `REVIEW-CHECKLIST.md` names.

The stage 3 startup checks listed above — the launch watched live for a carousel
frame, B landing on a settled carousel, and A keeping the ordinary transition —
were **not** part of that set and remain unconfirmed.

A portable package was built from `f314ae84` and smoke-tested: launched from
outside the build tree with no Qt on `PATH`, rendered, exited 0. The settings
file that run wrote — containing a freshly generated client certificate and its
private key — and the two runtime cache directories were deleted before the
folder was kept, per `BUILDING-WINDOWS.md`.

`master` was fast-forwarded to `f314ae84` and pushed to `origin` on client
authorization, 17 August 2026. The task branch was deleted; it was never pushed.

## Documentation

`FLOW.md` gained the remembered-host startup as a settled flow decision, which
it owns as route and transition semantics.

That pushed it past its size budget and the audit failed. It was already over
budget before this task — roughly 2772 tokens against a 2700 limit, with about
60 tokens of slack — so no rewording could absorb a new decision. On the
client's decision of 16 August 2026, the paragraph explaining that the exported
board artwork is not authoritative was removed and replaced with a pointer:
`docs/design-rationale/flow-rationale.md` already stated the same thing in the
same words, so `FLOW.md` was holding a duplicate of a fact another document
owns. Nothing was lost.

`FLOW.md` now sits at ~2821 tokens, still over its 2700 budget and **about 14
tokens below the point where the audit fails again**. The next addition to it
will need a trim first.
