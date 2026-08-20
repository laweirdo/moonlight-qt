---
kind: validation-report
date: 2026-08-20
branch: fix/persistent-atmosphere-splash-motion
base: master @ ea46a661
---

# Persistent atmosphere and splash motion — what was actually checked

Windows review station (`Shoebox`), Qt 6.9.3, Release. Nothing ran on a Deck.

## Passed

**Release build.** `qmake` tree already configured; `jom release` exit 0 through
a full QML recompile. The only link warning was the pre-existing `LNK4291`. The
rebuilt exe was copied into `build\deploy-x64-release` as `BUILDING-WINDOWS.md`
requires.

**`qmllint`.** Exit 0 on all thirteen changed QML files. Each was compared
category for category against its own version on `master`, linted from an
identical `app/gui` directory in a throwaway `git worktree`, so import
resolution was the same on both sides. Two differences, both explained:

- `main.qml` — `[unqualified]` fell from 42 to 40, the two removed references to
  the old `stackView.windowModalOpen`.
- `Splash.qml` — `[missing-property]` rose from 4 to 8. All four additions are
  `Member "motionSplashFadeMs" not found on type "Bulan"`, the warning every
  `Bulan.*` reference in the app already produces because `qmllint` cannot
  resolve a C++-registered singleton. Nothing new in kind.

Every other file was identical, category for category.

**Screens render on the one persistent atmosphere.** Captured at 2240×1400 and
inspected: first run (reached through the real splash), the host carousel, the
game grid, settings, host discovery, pair view. Foreground content is sharp and
correctly composited; the gradient, vignette and grain are present behind all of
them from a single instance; the hint bar and the onboarding crescent are in the
right place and the right order. No black or transparent gap anywhere.

**A route popup over a settled screen.** The carousel's host-settings panel,
opened through `MOONLIGHT_OPEN_HOST_SETTINGS`. The panel is sharp, the carousel
behind it is blurred, the composition reads as it did before.

**Atmosphere preferences still reach the persistent instance.** The persisted
toggles were flipped one at a time in the review station's own settings and
restored afterwards. Gradient off produced the flat base colour; vignette off
removed the edge darkening. Both are visibly correct through the single
instance. Grain off was captured but **cannot be judged** from a static desktop
grab — `BUILDING-WINDOWS.md` says outright that grain is a Deck question.

**No new QML diagnostics at runtime.** Every run's stderr carried only the two
pre-existing lines: the `ToolTip` attached-property warning on
`main.qml:15` and "mDNS is disabled by user preference".

## Found and fixed during this pass

`Splash.qml` imported `QtQuick 2.9`, and `Animation`'s `finished` signal did not
exist until 2.12. The component failed to load, the initial push did nothing,
and the application came up showing the atmosphere and nothing else. It was
caught by reading the log rather than by trusting the blank screenshot, and the
import was raised to 2.12 with a comment saying why that version and not the
inherited one. The build and every capture above are from after the fix.

## Settled on review, 20 August 2026

Two findings from the review of the uncommitted change were resolved on the
client's direction.

**The shared hint bar stays in the scene.** It had briefly been lifted above the
blur, on the reasoning that the quit confirmation prints its hints through that
bar and a blurred bar would be showing that dialog's own hints. The client's
call is that the bar is shared scene furniture and a modal blurs the complete
picture, so it sits under `designFrame` with the screens, the onboarding
crescent and the launch proxy. Only the five window-modal panels stand outside
the blurred scene, in `overlayFrame`. **The consequence is unwitnessed and
should be looked at:** with the quit dialog open, its Select/Cancel hints render
through a blurred bar, where under `master` that bar stayed sharp.

**The splash accepts input only while it can act on it.** `fadingIn` and
`holding` accept a press and start the dissolve; `fadingOut` and `handedOff`
decline it. The earlier version accepted during the fade-out so that a press
could not fall through to the StackView's own handlers, where at depth 1 B and
Escape open the quit confirmation. **That path is now reachable and untested:** a
second press during the roughly 300 ms fade-out is no longer consumed here, and
whether it reaches those handlers has not been checked at runtime.

The splash also now starts its fade-in from `StackView.onActivated` rather than
at construction, so an item built off the stack cannot spend its fade-in
somewhere the player cannot see. **Verified:** a real launch with no review hooks
still runs the whole sequence and lands on first run.

One deliberate behaviour change goes with the blur split: the onboarding
crescent, the launch proxy and the hint bar all stay in the scene, so a window
modal blurs them with the screens and the background. Under `master` only the
stack was blurred and all three stayed sharp.

## Not established

**No in-flight frame was captured.** The screenshot hook grabs one settled frame
at a fixed delay and cannot photograph an animation. So none of the following
was checked and none of it should be assumed:

- splash fade-in, full-opacity hold, fade-out
- skip during fade-in, skip during hold, and the reversal being continuous
- a second press during the fade-out, and where that unaccepted press goes
- the first input after handoff reaching the destination
- a mid-push or mid-pop transition, or rapid push/back interruption
- that the atmosphere holds still while a screen travels

**The window-modal blur was not seen.** No review hook opens the quit
confirmation or a configuration warning, and two attempts to open one with
synthetic input did not reach the Qt window. That the modal blurs the complete
scene — atmosphere, screens, crescent, launch proxy and hint bar — while its own
panel stays sharp and the navigation blur stands down is **implemented and
reasoned but unwitnessed**. It is the structurally riskiest part of this change,
because the modals moved out of the design frame into a new `overlayFrame` above
the blurred scene, and it is where the blurred-hints consequence above would
show.

**No Deck ran**, in Desktop Mode or Game Mode. Frame pacing, hitching, modal
open/close cost and splash smoothness on the target device are all untested.

**The remaining startup cases were not run** — remembered host offline,
remembered UUID gone, no remembered host.

## Open with the client

Two consequences follow from the approved design and want the client's eye:

1. A route's own popup no longer blurs the ground behind it, only the screen's
   content. On a gradient and a soft vignette that is invisible; the grain
   behind a popup now stays sharp.
2. During a transition both screens' content is briefly visible at once, for the
   length of `motionTransitionFadeMs`, because routes are transparent now.
