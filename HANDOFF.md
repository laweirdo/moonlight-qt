# Bulan - current handoff

Current as of **31 July 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. There is no active task brief.
Always inspect Git before relying on this snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch before this task | `bulan` and `origin/bulan` at `f34576f8` |
| Task branch | `root-quit-confirm`, cut from `bulan` |
| Remote | `origin` only, the client's fork |
| Active task | Replace the inherited root-carousel quit confirmation with a custom Bulan controller-first popup |
| Open defects | None recorded in `BUGS.md` after client XInput validation |

The root-carousel quit-confirmation repair was approved by the client on the
Windows review build after a real XInput controller test. The client then
requested documentation, commit, push, and merge.

## Current product state

| Area | Current state |
|---|---|
| Host carousel | Direct-positioned Bulan carousel with controller-first navigation. |
| SELECT on the carousel | Opens the approved glass host-settings overlay over a blurred carousel. B closes it and restores focus to the same host. |
| Root-carousel B/Escape | Opens the custom Bulan quit confirmation. Cancel is the default focused choice; Left/Right changes choice; A confirms; B dismisses and restores carousel focus. |
| Quit behavior | Quit still calls `Qt.quit()` from the popup's Quit path. Discovery, pairing, streaming, and unrelated UI were not changed. |
| Startup toolbar | Closed: Bulan starts without inherited chrome; inherited screens claim the toolbar explicitly. |

`SPEC-host-carousel.md` owns the durable surface decisions, including the
root-quit popup and the reason it uses application-scoped controller shortcuts.

## Implementation notes

- `app/gui/BulanQuitConfirmation.qml` is a custom `FocusScope`, not a stock Qt
  Quick Controls dialog. It follows the approved glass-popup language from
  `HostSettingsOverlay.qml`.
- `app/gui/main.qml` now opens that popup for root-level B/Escape, blurs the
  carousel behind it, disables the underlying `StackView` while the popup is
  visible, restores carousel focus when dismissed, and preserves `Qt.quit()` for
  the destructive Quit choice.
- `app/qml.qrc` includes the new popup component.
- The first review build looked visually correct but did not respond to the
  client's XInput controller. Investigation found that the SDL bridge sends
  synthetic Qt key events to the focused window, so visual QML focus alone was
  not a sufficient modal guarantee at the root level.
- The accepted fix adds non-visual, application-scoped `Shortcut`s while the
  popup is visible for Left, Right, Return, Enter, Space, Escape, and Back. That
  lets the popup own controller input until dismissed without showing stock Qt
  controls on the Bulan surface.

## Validation record

### Performed

- `qmllint` exited 0 for `app/gui/BulanQuitConfirmation.qml` and
  `app/gui/main.qml`. It emitted the expected standalone registered-import,
  singleton, token, and unqualified-access warnings because the C++ QML modules
  and Bulan singleton metadata are not visible to standalone lint.
- The Windows app target rebuilt with Qt 6.9.3 and MSVC Build Tools.
- The review executable was deployed to
  `build\deploy-x64-release\Moonlight.exe` and launched from the checkout path.
- The client tested the first visual build with a real XInput controller and
  reported that controller input reached nothing useful while the popup was
  visible.
- After adding the application-scoped shortcut path, the rebuilt review
  executable was launched again. The client tested with the same XInput
  controller and reported: "That worked."
- Application logs were inspected during review launches. The latest launch log
  was empty at startup; previous logs for the session contained no QML load
  error. Known standalone/tooltip and restricted-network update warnings remain
  environmental or pre-existing.

### Build caveat

The local Windows shell could not find the MSVC tools through the generated
makefiles without a review-build workaround. Generated build-tree makefiles
under `build\build-x64-release` were patched locally to use absolute MSVC tool
paths, and the linker used `/MANIFEST:NO`; the source tree was not changed for
that workaround. Link warnings included `LNK4075` for the disabled manifest
input and `LNK4291` for conservative EH continuation metadata. Treat the review
build as valid for QML/controller behavior, but do not treat that generated
makefile state as a source change.

### Not performed

- No Steam Deck Desktop Mode or Game Mode validation was performed for this
  popup.
- No stream, pairing, discovery, or real-host destructive flow was invoked.
- No exhaustive controller matrix outside the root quit popup was repeated in
  this task.

## Required reading before continuation

1. `AGENTS.md`
2. Git branch, HEAD, tracking branch, remotes, working tree, and relevant log
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `BUGS.md`
8. `SPEC-host-carousel.md`
9. The applicable `BUILDING-*.md` before a build
