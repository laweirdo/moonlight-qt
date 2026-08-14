---
kind: build-record
authority: historical-evidence
status: final
read_when:
  - investigating-what-a-past-phase-built
history_policy: append-only
---

# Build record — the private v1 draft

What each phase built on the way to the private v1 draft accepted on 3 August
2026, and the commits that carry it. Superseded by nothing: this is the
narrative `HANDOFF.md` and `ROADMAP.md` no longer carry.

Evidence for what was actually checked is in `docs/validation/`. Durable
screen-level design reasoning stays in
`docs/history/2026-08-14-pre-clean-slate/SPEC-host-carousel.md` and
`docs/history/2026-08-14-pre-clean-slate/SPEC-game-grid.md`.

## Phase A — Stabilise, completed 28 July 2026

The first known-good `bulan` baseline, established after controller, wake, Game
Mode, and visual checks on available hardware. The upstream sync policy, review
checklist, build procedures, and design sources were recorded.

The OLED session settled `atmosphereGrainOpacity` at `0.03`, `sizeCaption` at
`16`, and `motionOvershoot` at `0.7`, and moved `motionFocusMs` from the brief's
`140` to `180`. See `docs/validation/2026-07-28-deck-oled-review.md`.

## Phase B — Close the core loop

### Items 1 and 2 — connecting state and the game grid

The **connecting state** was built as one designed tile-level busy state shared
with waking — Phase D's *waking PC waiting overlay* pulled forward. Done 31 July
2026, accepted 1 August 2026 after a hardware gamepad review on the Windows
review station.

The **game grid** landed 1 August 2026 after a client review that produced four
changes and then the merge. Three consequences worth remembering:

- The app now records **when each game was last played**, per host, so Recent
  has something real to sort by. An additive client-side attribute on `NvApp`,
  following `hidden` and `directLaunch`.
- **The shoulder buttons had no keycode at all**, on any screen, until this
  task. L1/R1 now reach QML.
- **X opens a per-game options popup as its intended private-v1 destination.**
  It is not a stand-in, and no Game Detail screen is planned.

### Item 3 — launch and quit, accepted 2 August 2026

Replaced the inherited visible launch and quit screens while preserving the
existing Session, streaming, persistence, and quit backends.

| Commit | What |
|---|---|
| `94d92bf4` | Corrected flow authority and defined the launch/quit work order |
| `dc0bc8a9` | Added deterministic fake-only launch and quit review routes |
| `c3625cba` | Stable app-ID dispatch, exact artwork capture, and `LaunchTransition.qml` |
| `74a20505` | The custom launch/resume, warning, and failure experience |
| `b01a408e` | Custom quit, quit failure, and success-gated quit-and-switch |
| `30f7cad4` | Hardened cross-surface routing, route lifetime, replay, and animation cost |
| `285ff231` | Declared options key-event parameters after live input exposed Qt's implicit-injection warning |
| `cd26aefa` | Recorded the final live controller-equivalent review and validation limits |
| `5d1ff48b` | Closed the accepted work order and retired its temporary task brief |
| `c0e79970` | Merged into local `bulan` |

A in Recent or Library captures the exact visible selected artwork, hides only
that source, and moves one frozen proxy into the 202×302 centred launch
composition. Popup Play/Resume and automatic Direct Launch share that route.
Quit Game is recoverable; quit-and-switch waits for a successful quit before
entering the same launch route.

### Item 4 — screen transitions, accepted 2 August 2026

| Commit | What |
|---|---|
| `fa060c63` | Added root `CLAUDE.md`, Claude Code's orchestration rules under `AGENTS.md` |
| `09f9d576` | Opened the work order: route inventory, accepted motion direction, ownership |
| `0670b48e` | The push/pop transition and the launch/quit opt-out |
| `78c05eee` | Corrected the interruption comment on the mechanism |
| `435bf2f0` | Recorded state and opened two pre-existing defects |
| `36e5e7f9` | Real blur on the transition, on the client's override |
| `b93a8bb0` | Replaced the tiles' sideways slide with a staggered rise from below |
| `1e37e223` | Lifted the hint bar out of the screens into the window |
| `7c23b804` | Made a launch end the tile entrance rather than refuse the artwork capture |

The transition is declared once on the single navigation stack in `main.qml`
rather than attached screen by screen, so every screen inherits it and nothing
has private timing. The travel distance reuses the accepted `space3xl` (64 px)
through a named token rather than introducing a new visual value.

**The client's second round produced three accepted changes.** A real runtime
blur, overriding the inexpensive opacity-only reading of the brief's "slight
motion blur" — gated to the stack's own `busy` window, sharing one layer with
the quit-dialog backdrop. Game tiles rising from below on a capped six-step
cascade instead of the horizontal slide the client saw as "swiping in from the
side, way too quickly". And a hint bar lifted into the window beside the stack,
because a child cannot opt out of its parent's animated opacity.

The blur blurs the whole stack including the atmosphere behind the screens, not
only the moving content. That is a visual consequence the client has not judged.

### `v1-finalisation` — grid lifetime and per-host context, merged 2 August 2026

| Commit | What |
|---|---|
| `bca4d86f` | Opened the work order: client decisions, motion rule, stage table, scope exclusions |
| `783bca16` | Destroyed discarded grids and gave each host its remembered place back |
| `7f10fe06` | Landed the grid entrance with an overshoot and one soft bounce |
| `b813bd0e` | Closed both defects and reconciled the private v1 scope correction |
| `5a344145` | Merge, accepted by the client as the Phase B closeout |

A discarded `AppView` now publishes what it was showing and destroys itself,
following the treatment `StreamSegue` and `QuitSegue` already use.
`HostCarousel` keeps that context in memory keyed by host UUID for the app
session, and the next grid opened for the same host restores the tab, the
selected game by stable app id, and the Library scroll. The retained-grid
contract is untouched.

**The restore re-applies on every model change rather than stopping at its first
success.** `recentFocusedIndex` is a rank in `recentOrder`, and each arriving
chunk of the host's app list recomputes that order — so a rank restored early
points at a different game once the list finishes arriving. Observed, not
theorised: the first implementation restored correctly at four games loaded and
was showing the wrong game by twenty-two. The player's first press retires the
restore outright, so a late chunk can never override someone already moving.

**The grid entrance overshoots and settles with one bounce.** Both cascades
moved from `Easing.OutCubic` to `Easing.OutBack`, which crosses its target
exactly once. The overshoot is its own token, `motionEntranceOvershoot`, rather
than a reuse of `motionOvershoot` — that value is tuned for a 4% focus scale
change and moves this 32 px rise by about a pixel.

## Phases C, D, E and F — the private v1 draft, merged 3 August 2026

| Commit | What |
|---|---|
| `4d22966c` | The vertical logo lockup, composed from the client's two supplied sources |
| `01bb43ab` | The first-run route: splash, find, discovery, pairing |
| `2f91a306` | The Bulan settings shell and About, replacing the upstream screen |
| `2f88565c` | The Bulan app icon and a desktop entry that reads *Bulan* |
| `97fcc481` | Reconciled the documents against what was built |
| `a0384d62` | The remaining edge states, and SELECT's destination on the grid |
| `00756bc5`, `dc1473ac`, `71598756` | Client review rounds one and two |
| `173c0497` | Merged into `bulan` |

**Phase C — first run**, built to the client's S0–S3 boards: a static splash
carrying the vertical lockup, skippable by any press and replacing itself so B
never returns to it; *Let's find your PC*; *Looking for your PC* with discovered
hosts as selectable rows; PIN entry in four tiles; manual IP entry reusing the
carousel's existing panel and `addNewHostManually`. Launch goes to first run only
when no paired host is known, and pairing success lands on the host carousel
with the onboarding screens cleared off the stack.

**Phase D — edges.** *Couldn't reach PC* and *Couldn't start stream* already
existed from earlier work. The empty library for a paired host now names the host
and points at Host Settings, because a library that looks empty is often one
where everything has been hidden. The zero-host carousel — the last obviously
unfinished surface in the app — uses the first-run language and offers both
*Look again* and *Enter an address instead*. Disconnect confirmation already
existed in `GameOptionsOverlay`'s `quitConfirm` page.

**Phase E — settings and About.** Two panes, a data-driven row list, and two
custom popups; no stock Qt Quick Control is instantiated, and nothing in the app
routes to `SettingsView.qml` any more. Left/Right moves between the rail and the
rows, Up/Down within a pane. The atmosphere-effect flags became real persisted
preferences rather than read-only tokens. About carries the mark, the version,
"Built on Moonlight", the fork statement, and GPLv3.

**Phase F — packaging.** The client's icon installs under the application ID and
the desktop entry reads *Bulan*. The supplied master's white frame backdrop was
dropped so the corners are transparent. Windows `RC_ICONS` still points at the
upstream `.ico`; Windows is not a target.

The route a first-time user takes is built end to end and no screen along it
still reads as upstream Moonlight:

launch → splash → *Let's find your PC* → *Looking for your PC* → pair → host
carousel → game grid → launch → stream → quit → back to the grid.
