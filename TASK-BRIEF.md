---
kind: task-brief
authority: active-task-scope
lifecycle: delete-on-client-acceptance
started: 2026-08-20
---

# Active task — persistent atmosphere and splash motion

Branch `fix/persistent-atmosphere-splash-motion`, cut from `master` at
`ea46a661`.

**The full approved design, the atmosphere ownership map, the blur scopes, the
splash state machine and the exclusions live in
`docs/superpowers/plans/2026-08-20-persistent-atmosphere-splash-motion.md`.**
Read that; it is not repeated here.

## Objective

One persistent Bulan atmosphere owns the background. Screens move over it;
it does not move, fade or take navigation blur. The startup logo dissolves in,
holds, dissolves out, and only then hands off.

## Scope

`app/gui/main.qml`, `app/gui/Splash.qml`, `app/gui/Bulan.qml`, and the removal
of the route-local common atmosphere from `FirstRun.qml`, `HostDiscovery.qml`,
`PairView.qml`, `HostCarousel.qml`, `AppView.qml`, `SettingsShell.qml`,
`StreamSegue.qml`, `QuitSegue.qml`, `GlyphProof.qml`.

## Out of scope

Ambient gradient animation, navigation timing and travel, blur strength and
radius, popup styling, onboarding design, discovery, pairing, streaming,
remembered-host routing, other open bugs, upstream sync, unrelated refactoring.

## Open with the client

Two accepted consequences are recorded in the plan under "Accepted consequence
A" (a route's own popup no longer blurs the ground behind it) and "Accepted
consequence B" (two screens' content overlap briefly mid-transition). Both
follow directly from the approved direction; both need the client's eye on the
built result.
