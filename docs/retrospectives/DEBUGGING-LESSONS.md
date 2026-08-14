# Bulan — debugging and validation lessons

This retrospective preserves lessons that should influence future work but do
not belong in the active roadmap, handoff, or defect list. It is not an
authority for current repository state or open defects.

Compiled on 30 July 2026 from the Phase A and carousel investigations. Detailed
closed defect accounts are in `DEFECTS-carousel.md`; this file is the small
cross-cutting summary.

## Look at perceptual questions on the target hardware

Early estimates predicted that the 16-pixel caption would be hard to read and
that grain at 0.03 would disappear on the OLED panel. Both predictions were
wrong when the client reviewed the real screen. The original 140 ms focus
motion also looked slightly too fast and was deliberately changed to 180 ms.

Use calculation to identify what to inspect, not to overrule a hardware review.
Record which panel was actually checked. OLED evidence does not count as LCD
evidence; LCD validation remains deferred until that hardware is available.

## Measure the transition, not only the resting result

The carousel's settled position was once used to rule out the client's
explanation of a motion defect. It could show where a tile ended, but not which
way the tile travelled. Frame-by-frame measurements later exposed the missing
evidence.

Choose an observation that can see the behavior being ruled out. For animation
and startup defects, inspect the interval from the first visible frame through
settling rather than only the final frame.

## Repeated workaround trade-offs point to the component

The old carousel needed a closed-loop `PathView` to behave like a list that
clamps at both ends. One workaround removed a visible wrap by making the tile
visibly disappear instead. The fix worked mechanically but did not improve the
experience.

When every repair can only exchange one visible artifact for another, check
whether the underlying component expresses the approved interaction at all.
The eventual direct-positioning rebuild removed the loop, join, and route
choice together. The full rationale remains in
`docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md`.

## Review models must not address real objects by position

Fake hosts occupied positions that were later used to address the real host
list. One fake selection could silently open the wrong real machine; a later
selection could read past the list and crash.

Any injectable review model needs one guard across every action that can reach
production data. A harmless-looking demo item must never inherit a real item's
identity merely because their indexes match.

## A single dead button may be a focus-lifecycle failure

The carousel once stopped responding to A after a panel closed while other
buttons continued to work. A was the only input without a window-level shortcut,
so the symptom looked like a binding problem even though the screen had stopped
listening.

When one input fails after a modal or screen transition, inspect focus and
component lifetime before changing controller mappings.

## A restore that succeeds and then quietly undoes itself

Restoring the game grid's remembered selection worked on the first attempt and
still showed the wrong game. The saved app id was found, the selection was set,
and the restore marked itself done — and then the rest of the host's app list
arrived, the Recent order was recomputed, and the rank that had pointed at the
restored game pointed at a different one.

The bug was invisible in the log, which showed the restore succeeding. It was
only visible on screen, one full list-load later.

When restoring a position into a model that is still loading, decide whether
what you restored is stable under everything that arrives afterwards. A stable
identity resolved once into a positional index is only correct until the next
reorder. Re-apply the identity until the user takes over, rather than resolving
it once and trusting the result.

The matching rule is that the restore must lose to the player. Re-applying on
every model change is only safe because the first press retires it outright;
without that, a late chunk pulls the selection out from under someone already
moving.

## Synthetic input needs a delivery mechanism the environment permits

Scripted `SendKeys` review runs appeared to work and were in fact landing in
whatever window happened to be in front, because this environment refuses to
give a background process the foreground. The app looked like it was ignoring
input, and one run looked like a crash that had not happened.

Check that the input actually reached the application before drawing any
conclusion from what the screen shows. Posting `WM_KEYDOWN` straight to the
window handle does not need the foreground and was what worked here.

## A check is not recorded until its evidence is written down

Mouse behavior was verified by the client but remained labelled unverified in a
later document. The implementation was sound; the repository state was not.

Update durable decisions and current-state documents after the check and final
repository state are known. Do not turn an intended test, an inferred result, or
an unwritten memory into a reported pass.
