---
kind: implementation-plan
authority: task-plan
date: 2026-08-20
branch: fix/persistent-atmosphere-splash-motion
base: master @ ea46a661
---

# Persistent atmosphere and splash motion

Approved client direction, 20 August 2026. Binding — not re-opened here.

## Problems

1. Screen transitions move, fade and blur the whole picture, background
   included, because every route paints its own copy of the common atmosphere
   inside the StackView. The world should stand still while the screens move
   over it.
2. The startup logo cuts in and cuts out. It should dissolve in, hold, dissolve
   out, and only then hand the app over to its first real screen.

Out of scope: the future ambient gradient animation. This task only decides who
owns the background; it implements no ambient motion.

## Atmosphere ownership map

`rg -n "Atmosphere\s*\{" app/gui`, every hit classified:

| File | Line | Class | Action |
|---|---|---|---|
| `main.qml` | 202 | persistent scene atmosphere | **Keep — promote into `sceneRoot`** |
| `main.qml` | 390 | `StackView.background`, gradient-only | Remove — redundant once routes are transparent |
| `Splash.qml` | 164 | common route background | Remove |
| `FirstRun.qml` | 104 | common route background | Remove |
| `HostDiscovery.qml` | 278 | common route background | Remove |
| `PairView.qml` | 128 | common route background | Remove |
| `HostCarousel.qml` | 1169 | common route background, inside the route's own popup-backdrop layer | Remove — see note |
| `AppView.qml` | 2791 | common route background | Remove |
| `SettingsShell.qml` | 286 | common route background, inside the route's own popup-backdrop layer | Remove — see note |
| `StreamSegue.qml` | 291 | common route background | Remove |
| `QuitSegue.qml` | 131 | common route background | Remove |
| `GlyphProof.qml` | 53 | common route background (review-only screen) | Remove |

No instance carries screen-specific semantics. Two carry a *scope* consequence,
recorded below.

### Accepted consequence A — route popup backdrops

`HostCarousel` and `SettingsShell` wrap their atmosphere inside the layer they
blur when one of their own popups opens; `AppView` blurs per section. Those
popups live inside their route, so they cannot be lifted to the scene-level
modal blur without moving every route popup out of its route — explicitly out of
scope. After this change a route popup blurs the foreground only; the gradient,
vignette and grain behind it stay sharp. Blurring a smooth gradient and a soft
vignette is imperceptible; losing the grain blur is the only real difference and
is not visible without an A/B. Flagged to the client rather than fixed here.

### Accepted consequence B — mid-transition overlap

`main.qml:376` records that each route's own atmosphere is what hides the
outgoing screen while the incoming one travels. With transparent routes, both
screens' *content* is briefly visible at once during `motionTransitionFadeMs`.
That is the direct consequence of the approved design — foreground content keeps
its existing opacity behaviour over a world that no longer moves — so the
comment is rewritten, not worked around.

## Hierarchy

```
contentCapture                      <- screenshot surface, unchanged
└─ sceneRoot            z 0         <- MODAL blur target
   ├─ Atmosphere                    <- the one persistent world layer
   └─ designFrame                   <- unchanged proportional scaling
      ├─ StackView      z 0         <- NAVIGATION blur target
      ├─ onboardingMark z 1
      ├─ LaunchTransition z 2
      └─ HintBar        z 3
└─ overlayFrame         z 1         <- same geometry and scale as designFrame
   └─ the five window modals  z 4
```

`overlayFrame` is new and is the only structural addition. The window modals
were children of `designFrame`; they must sit *outside* the item the modal blur
is applied to, or they would blur themselves. They keep design-frame coordinates
and the design frame's scale, so nothing about their layout changes.

`onboardingMark`, `LaunchTransition` and `HintBar` stay outside the StackView,
for the reasons their own comments give.

## Blur scopes

One source of truth, promoted to the window:

```
windowModalOwner  = first visible of quit, noHwDecoder, xWayland, wow64, unmapped
windowModalOpen   = windowModalOwner !== null
```

- `sharedHintBar.owner` reuses `windowModalOwner` instead of restating the list.
- `sceneRoot.layer.enabled = windowModalOpen` — popup backdrop blur, whole scene.
- `stackView.layer.enabled = stackView.busy && !windowModalOpen` — motion blur,
  foreground only.

The two can never both be on, so no nesting and no double blur. Modal wins;
when it closes, navigation blur resumes normally. Strengths and radii are the
existing tokens, unchanged.

## Splash state machine

`Splash.qml` gains four explicit phases in one `phase` property:

```
"fadingIn"  -> logo 0 -> 1 over motionSplashFadeMs, OutCubic
"holding"   -> onboardingSplashHoldMs, unchanged
"fadingOut" -> logo current -> 0, OutCubic
"handedOff" -> handoff performed, exactly once
```

Transitions:

- `StackView.onActivated` → `fadingIn`.
- fade-in completes → `holding`.
- hold completes → `fadingOut` at the full `motionSplashFadeMs`.
- input during `fadingIn` or `holding` → stop that phase, enter `fadingOut`
  immediately from the current opacity, duration
  `Math.round(Bulan.motionSplashFadeMs * logo.opacity)` so opacity velocity
  stays roughly constant and the reversal has no discontinuity.
- input during `fadingOut` or `handedOff` → ignored, and **not accepted**, so a
  stale splash cannot swallow a press meant for its replacement.
- fade-out completes → `handedOff`, then the handoff, guarded so it runs once.

`requestExit()` and `handOff()` replace the single `proceed()`. Destination
selection is unchanged (`anyPairedHost && !forceFirstRun` → `HostCarousel.qml`,
otherwise `FirstRun.qml`), as is `clear(Immediate)` + `push(Immediate)`. The
mouse skip calls `requestExit()`, the same path as key and controller input.

No clamp on the computed duration unless runtime shows a zero-duration edge.

## Token

`Bulan.qml`, with the other motion tokens:

```
readonly property int motionSplashFadeMs: 300
```

A startup-specific clock, deliberately not `motionTransitionMs`. Applies to the
logo's opacity only.

## Exclusions

No change to: navigation animation design, `motionTransitionMs`,
`motionTransitionFadeMs`, transition rise, blur radius or strength, popup
styling, ambient background animation, sound, boot assets, onboarding design,
discovery, pairing, streaming, remembered-host routing, other open bugs.
No upstream sync. No unrelated refactoring. No speculative motion tokens.

## Verification

`qmllint` on every changed QML file, categories compared against `master`;
`python scripts/context-audit.py` after the documentation changes; a Release
build and desktop visual review per `BUILDING-WINDOWS.md`; Deck Desktop and Game
Mode reported honestly or marked NOT TESTED.
