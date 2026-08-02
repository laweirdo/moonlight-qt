# Bulan - open defects

**Current as of:** 2 August 2026

This file contains acknowledged, open unintended behavior only. Active product
work belongs in `TASK-BRIEF.md` when one exists; scope and sequencing belong in
`ROADMAP.md`; upstream redesign findings remain historical in `UI-AUDIT.md`.

Both defects below are **pre-existing**. They were found on 2 August 2026 while
validating the general screen transition, and both reproduce identically on the
pre-transition baseline `09f9d576`. Neither is caused by the transition work.

## The game grid forgets itself when you come back from the host carousel

Leave a host's game grid with B, then open the same host again. The grid
reopens on Recent with the first game selected: the game you had selected, the
tab you were on, and how far you had scrolled into the Library are all lost.
The host you were on *is* remembered correctly on the carousel.

`HostCarousel.openAppView()` builds a brand-new `AppView` on every entry
(`app/gui/HostCarousel.qml:507`), and nothing reads a saved position back into
it, so the fresh grid starts at its defaults.

This is a different path from the retained grid that survives a launch or quit.
That one works: the same `AppView` stays alive underneath the launch surface and
restores focus and scroll by stable app ID. Only the carousel round trip is
affected.

**Not yet triaged for v1.** Fixing it means deciding what Bulan should remember
per host and for how long — a product question, not only an implementation one.

## Memory grows every time you enter and leave a game grid

Fifty carousel → grid → back cycles grew the process by roughly 515–520 MB on
both the current build and the pre-transition baseline, about 10.8 MB per cycle,
with no sign of levelling off. The application stayed responsive throughout and
handle count was effectively flat.

Consistent with the same root cause: each entry creates an `AppView` parented to
the `StackView`, and `AppView.qml` has no `StackView.onRemoved: destroy()` — the
treatment `StreamSegue.qml:229` and `QuitSegue.qml:129` both use. The
measurement is process-level working set, not an instrumented QML object count,
so the mechanism is strongly indicated rather than directly proven.

**Severity is unclear and should be established before v1.** Fifty round trips
is heavy use for one session, and the Steam Deck has less memory headroom than
the review station. `AppView`'s lifetime is part of the accepted launch and quit
contract, so any fix needs to be worked and re-audited deliberately rather than
folded into unrelated work.
