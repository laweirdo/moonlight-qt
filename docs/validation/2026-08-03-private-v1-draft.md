---
kind: validation-report
authority: historical-evidence
status: final
read_when:
  - investigating-a-past-validation-claim
history_policy: append-only
---

# Validation report — private v1 draft, 3 August 2026

| Item | Value |
|---|---|
| Date | 3 August 2026 |
| Branch | `v1-review-build`, merged into `bulan` as `173c0497` |
| Commits | `4d22966c`–`a0384d62`, plus the review fixes `00756bc5`, `dc1473ac`, `71598756` |
| Hardware | Windows review station |
| Environment | Qt 6.9.3 / MSVC Release, built per `BUILDING-WINDOWS.md` |
| Client | Reviewed the build live in two rounds and accepted it |

Covers the first-run route, the settings shell and About, the remaining edge
states, and packaging (app icon and desktop entry).

**What was accepted is a draft that runs correctly on a Windows review
station.** It is not a validated release: nothing here has run on a Steam Deck,
against a physical controller, through a real stream, or as a Flatpak.

## Performed

- `git diff --check` clean throughout; every diff reviewed directly.
- `qmllint` on every new and changed QML file, exit 0 throughout, with no new
  warning category beyond the `[import]` / `[missing-property]` /
  `[unqualified]` / `[unresolved-type]` noise these files already produce
  because `qmllint` cannot resolve C++-registered singletons.
- Qt 6.9.3 / MSVC Release builds throughout, linking cleanly. The only link
  warning was the pre-existing `LNK4291`.
- **The whole first-run route was driven and captured**: splash → *Let's find
  your PC* → *Looking for your PC* with two hosts listed → *Almost there* with
  the PIN in four tiles, and B back out through all of it. Each capture was
  compared against the client's board.
- **Settings was driven and captured**: the shell with all eight categories,
  About, the resolution list popup, and the bitrate slider popup.
- The application log was read after each run. It contains no `Critical`, no
  `TypeError`, and none of the QML reference errors.
- The app icon was rendered at 256, 64, and 32 px, and the SVG was validated as
  XML after editing.
- Input was delivered by posting `WM_KEYDOWN` to the window. `SendKeys` is
  useless here: this environment refuses a background process the foreground, so
  scripted keys land in whatever window is in front.

## What the review found

**The client's design boards were finally readable.** Every earlier session had
them attached and could not open them — this machine had no PDF rendering at
all, so reads returned a file size and no image. Poppler was installed on
3 August 2026 and all eight boards were rendered and used. The first-run and
settings screens are built to those boards rather than inferred, which changed
them substantially: the amber *Look* button, the focused row's left bar, the
four separate PIN tiles, the two settings popups, and the host-selector row were
none of them things inference had produced.

**A reported input defect did not exist.** A press was said to be lost after the
splash handed off. The measurement behind it sent one press while the splash was
still up — its hold does not begin until QML has loaded, about a second after
launch — and the splash consumed it exactly as its skip behaviour intends.
Retested with two presses 400 ms apart, the second landing 400 ms after the
stack swap: it was acted on. The speculative `requestActivate()` mitigation
added for it was removed.

**Three real defects were found in review of the settings work and fixed**
rather than reported:

1. The category rail overflowed its pane, so About fell off the bottom of the
   screen entirely and Advanced collided with the hint bar.
2. The choice popup opened at the top of its list while the selection sat on the
   last row, so the current value opened half cut off.
3. Unfocused option rows had no outline at all.

Eighteen key handlers across the new screens took the `event` parameter
implicitly — the deprecation this project had already corrected once — and all
now declare it.

**Two `TypeError`s that the splash's stack swap introduced** in `main.qml`'s
toolbar labels were found by reading the log, and fixed.

## Not performed — do not report any of these as passed

- **No Steam Deck validation**, in Desktop Mode or Game Mode. Nothing about
  these screens has been seen on the target device.
- **No physical controller.** All navigation was controller-equivalent keys.
  L1/R1 still cannot be synthesised at all, so the Recent↔Library tab switch and
  the Library-tab half of the grid context restore remain unexercised by input.
- **No Flatpak build or installation.** This machine is Windows.
- **Steam Game Mode on-screen keyboard is UNVALIDATED** for the manual address
  field. It is the one part of the first-run route that cannot work without the
  OSK, and it has never been tried.
- **No real pairing against a live host.** Only the fake-host branch and the
  already-paired branch were exercised. `pairingCompleted` success routing is
  built and reviewed by reading, not observed.
- **No real stream** was launched, resumed, failed, or quit through any of this.
- **No human judgement of any of it in flight** — the entrance bounce, the
  first-run stagger, the popups. Settled captures establish end states, not feel.
- **No OLED or LCD appearance review.**
- **The transition blur's cost on the Deck is still unmeasured**, by the
  client's deliberate deferral.

## Resulting defect

The client reported that opening Settings → UI → Language crashes the
application. Four reproduction routes were tried against this build and none
reproduced it. Open in `BUGS.md`.
