---
kind: validation-report
authority: dated-evidence
date: 2026-08-16
platform: windows-review-station
---

# Windows responsive polish — validation, 16 August 2026

Evidence for the three implementation stages on branch
`responsive-game-surface`: the design frame and artwork-only tiles
(`90e929a3`), Recent's progressive centre (`4fc52111`), and the shared
onboarding mark (`e6b7d5ea`).

Authority for what the screens now do lives in `SPEC-game-grid.md`,
`DESIGN-SYSTEM.md` and `FLOW.md`. This file records only what was and was not
actually run, on this machine, on this date.

## Toolchain

| Piece | Version |
|---|---|
| Qt | 6.9.3 msvc2022_64 |
| Compiler | MSVC 14.44, Visual Studio Build Tools 2022 17.14.37 |
| Build | `qmake` + `scripts\jom.exe release`, per `BUILDING-WINDOWS.md` |

`scripts\build-arch.bat` was not used — it is the wrong tool for a review
station, as that guide records.

## Passed

**Build.** Release built clean at every stage, `jom` exit 0. The only linker
diagnostic is the pre-existing `LNK4291` from `Qt6EntryPoint.lib`.

**`qmllint`.** Exit 0 on every changed QML file: `Bulan.qml`, `main.qml`,
`GameTile.qml`, `AppView.qml`, `FirstRun.qml`, `HostDiscovery.qml`. Warning
categories are unchanged from the documented baseline — `[import]`,
`[unqualified]`, `[missing-property]`, `[unresolved-type]` — all of them
around C++-registered singletons `qmllint` cannot resolve. One
`[unused-imports]` on `QtQuick.Layouts` in `main.qml` predates this work.

**Five-resolution composition.** Recent and Library captured at 1280×800,
1920×1080, 2560×1440, 2560×1600 and 3840×2160. At every size: exactly five
Library columns, no text below any artwork, 2:3 artwork preserved, focus ring
aligned, and the 16:9 sizes centred with symmetric side margins.

Scale and frame offset measured off the captures at 1280×800 and confirmed
against the geometry at the rest:

| Viewport | Scale | Frame left |
|---|---|---|
| 1280×800 | 1.00 | 0 |
| 1920×1080 | 1.35 | 96 |
| 2560×1440 | 1.80 | 128 |
| 2560×1600 | 2.00 | 0 — fills the frame |
| 3840×2160 | 2.70 | 192 |

**Recent's progression**, measured off the focus ring at 1280×800 with the
`partial` preset: first game at 48 px (the screen margin), second at 298 px,
third at 640 px (centre), fourth and later locked at 640 px. The lock index
falls out of the geometry rather than being stated anywhere. The focus halo
travels with the selected game.

**Recent's continuity.** With `many`, the row fills the width and runs past
both edges with the selection at the margin, mid-progression, and centre-locked.
No void at either end in any of the three.

**Content variants** at 1280×800, both tabs: `none` (empty-library placeholder,
crescent and copy intact), `one`, `partial`, `mixed`, `many`.

- Missing artwork still names its game inside the tile, in every preset —
  every fake game is artless, so this is the case every capture exercises.
- A 45-character title (`mixed`) wraps to four lines and stays inside the tile.
- A running game (`mixed`) is still reported: "Portal 2 is running" in the
  header, and A reads Resume rather than Play.

**Library scrolling.** `many` (23 games) at focus index 21: the partial final
row of three renders, the view has scrolled to it, and the focus ring is on the
correct tile.

**Onboarding mark.** Present and centred on both first run and discovery, at
their two different heights, sharp and fully opaque in both.

**Hint bar.** Present on the game screen and on both onboarding screens.

## Fixed during the pass

**The hint bar was invisible.** Moving the window's furniture inside the new
design frame reordered painting: the reparented children landed underneath the
StackView and were covered by each screen's opaque atmosphere. Introduced in
`90e929a3`, found in `e6b7d5ea` when the onboarding mark failed to appear for
the same reason, fixed by every window-level child stating its own `z`. It was
absent from the Stage 1 and Stage 2 screenshots shown to the client and was not
noticed at the time.

## Skipped

**Controller walk.** No gamepad is attached to this machine and this was not an
interactive session, so no button was pressed. Recent's positions, the Library's
partial-row state and the onboarding screens were reached through the review
hooks instead, which set the same properties a press sets but do not prove the
input path. **Left/Right, Up/Down, A, X, B and tab switching are unverified by
this report.** No code on any input path was changed by these three commits.

**The transition itself.** The screenshot hook grabs a settled frame, so the
mark's crossing between first run and discovery — the thing Stage 3 exists for —
was reasoned about and built, not watched. Its endpoints are photographed; its
middle is not.

**Real box art.** Every capture used artless fake games. The artwork layer now
sizes its texture against the frame scale specifically so posters stay sharp
when magnified, and **that is exactly what these captures cannot show**. It
needs a real paired host at a high resolution.

## Unavailable or deferred

**Steam Deck, Game Mode, and hardware performance.** No Deck ran. Deferred by
client decision until the Windows fit-and-finish is accepted; not failed, not
attempted.

**2560×1440, 2560×1600 and 3840×2160 as real windows.** The review station's
display is 3845×2125 device pixels at 175% scaling, so Windows clamps a window
requested at any of those three. They were captured with `QT_QPA_PLATFORM=offscreen`
instead, which does render the true viewport — but **does not render layered
effects**: the active tab's glow is missing from those three captures, and the
artwork mask would be equally unreliable had there been artwork. Geometry from
them is trustworthy; effect fidelity at those sizes is not established. 1280×800
and 1920×1080 were captured as real windows and carry no such caveat.

The offscreen platform plugin is not part of the documented Windows deploy;
`qoffscreen.dll` was copied into the review build's `platforms` directory by
hand for this pass.

**macOS and the WiX MSI.** Not built.
