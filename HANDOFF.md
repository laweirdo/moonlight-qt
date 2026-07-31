# Bulan - current handoff

Current as of **1 August 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. There is no active task brief.
Always inspect Git before relying on this snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan`, merged and pushed to `origin/bulan` |
| Task branch | `tile-busy-state`, merged at the client's instruction and deleted |
| Remote | `origin` only, the client's fork. Never pushed to upstream Moonlight |
| Active task | **None.** `TASK-BRIEF.md` was removed on completion |
| Open defects | None recorded in `BUGS.md` |

**The client accepted this work on the Windows review station on 1 August 2026,
driving it with a hardware gamepad, then authorized the merge and the push.** It
has had no Steam Deck, Game Mode, or real-sleeping-host validation of any kind.

The next objective is `ROADMAP.md`'s Phase B item 2, the game grid.

## What was built

Phase B item 1, *Connecting state*, with Phase D's *Waking PC* item pulled
forward into it by client decision on 31 July 2026.

The carousel's two provisional waiting treatments are replaced by one designed
tile-level busy state: the circular tile dims its disc interior and three amber
dots bounce over it. No new screen, no overlay, no popup. `SPEC-host-carousel.md`
owns the durable design and reasoning.

| Commit | What |
|---|---|
| `89e1367a` | Eight busy-state tokens |
| `6d38a8b3` | The tile treatment, the UUID-keyed state, both wake call sites |
| `5cff3caf` | `MOONLIGHT_FAKE_WAKE_OUTCOME`, `MOONLIGHT_FAKE_CONNECT_HOLD_MS` |
| `7ffe1d27` | `MOONLIGHT_FAKE_WAKE_ON_START`, so the state can be photographed |
| `bf92f5a0` | Dot size raised after seeing it on screen |
| `7766b4c4` | Documentation, and the corrected Windows build trap |

## Current product state

| Area | Current state |
|---|---|
| Connecting | Tile disc dims, three amber dots bounce, `"Connecting…"`. |
| Waking | Same treatment. Resolves when the host's model row reports online, or gives up after 30 seconds and says `"Couldn't wake …"` for 3 seconds before reverting to the ordinary offline copy. |
| Wake popup | Gone from both call sites — `actWake()` and host settings *Wake PC*, which now closes itself so the tile it made busy is visible. |
| Input while busy | Left/Right unaffected. A and Y are no-ops on the busy host. The Wake hint and the *Wake PC* entry are withheld while that host wakes. B is unchanged and is deliberately not a cancel. |
| Stream launch | **Unchanged and still stock upstream Qt.** `StreamSegue.qml` was out of scope by client decision; `ROADMAP.md` records it as a Phase B gap for after the game grid. |
| Everything else | Discovery, pairing, streaming, the host overlay, the root quit confirmation and the startup toolbar boundary are untouched. |

## Implementation notes

- Busy state is keyed on host UUID with separate connecting and waking slots.
  An index was safe for a one-tick connection and is not safe for a 30-second
  wake, and a single shared slot would let connecting to a second host silently
  discard a wake still running on the first.
- No C++ backend change was needed. `ComputerModel` already emits a per-row
  `dataChanged` when the monitor thread sees a state flip, so `model.online` was
  already live. Resolution therefore inherits the discovery poll's cadence:
  roughly 3 seconds between the host answering and the app noticing.
- The dots run off one shared looping phase, so this screen still contains no
  `SequentialAnimation` — the property `SPEC-host-carousel.md` claims about it
  remains literally true.
- Three review hooks were added because the review station has no host it can
  put to sleep and a fake host's `online` never changes on its own. All are
  inert unless set.

## Validation record

### Performed

- `qmllint` exited 0 for `Bulan.qml`, `HostTile.qml`, `HostCarousel.qml` and
  `HostSettingsOverlay.qml`. Only the categories this project has always seen
  standalone appeared: `[import]`, `[missing-property]`, `[unqualified]`,
  `[unresolved-type]`. `Bulan.qml` produced no output at all.
- The Windows app target built with Qt 6.9.3 and MSVC Build Tools, and
  `qmlcachegen` compiled every changed QML file — which is a real syntax check,
  not only a lint pass. The only link warning was the pre-existing `LNK4291`.
- The review executable was deployed to `build\deploy-x64-release\Moonlight.exe`
  and launched three times from the checkout path.
- The waking state was captured on the `mixed` fake-host preset and looked at:
  dimmed disc, three staggered amber dots, undimmed focus ring, and the copy
  `"Waking Living-Room. Give it a moment."` The Wake hint was correctly absent
  from the hint bar while that host was waking.
- The `offline` preset was captured and confirmed unchanged: its unwakeable
  first host still shows no Wake hint and no busy state.
- The dot size was raised from 10 to 18 px **because of** that first capture —
  10 px read as specks against a 324 px tile.
- Application logs were read on every launch. The only warning was the known
  environmental `ToolTip attached property` line from `main.qml`.
- A run with no review hooks set was checked against the real host list, to
  confirm the hooks are inert and normal startup is unchanged. `Steambox`
  appeared online and read `"Ready when you are."` as before.

### Client controller review, 1 August 2026

The client drove the deployed review executable on the `mixed` fake-host preset
with a **hardware gamepad**, with the wake outcome set to succeed and the
connecting hold enabled, and reported that everything looked right.

They were asked to exercise: waking by Y and by A, the resolution back to
`"Ready when you are."`, scrolling away from and back to a waking host, the
dots shrinking with the tile, repeated presses on a busy host doing nothing,
the Wake hint and the *Wake PC* entry disappearing while busy, the connecting
dots, and B still reaching the quit confirmation.

**This was one overall judgement, not an item-by-item sign-off.** Treat it as
acceptance of the surface, not as independent confirmation of each behaviour.

### Build caveat resolved

The previous handoff recorded that the Windows shell could not find the MSVC
tools through the generated makefiles, and that build-tree makefiles were
patched with absolute tool paths and `/MANIFEST:NO`. **That diagnosis was wrong
and the workaround was unnecessary.** The real cause was cmd expanding `%PATH%`
at parse time, before `vcvarsall.bat` had run, when the three build steps were
chained on one command line. Putting them in a `.bat` file builds the documented
recipe unmodified, with the manifest embedding normally.
`BUILDING-WINDOWS.md` carries the full account. No source or makefile
workaround is in place on this branch.

### Not performed

- **No Steam Deck validation, in either Desktop Mode or Game Mode.** Everything
  above happened on the Windows review station, which `BUILDING-WINDOWS.md` is
  explicit is not a product target.
- **No real sleeping host.** The 30-second timeout was judged against a fake
  host that returns in three seconds. Whether it suits a machine genuinely
  leaving sleep, and whether the discovery poll's ~3 second notice latency is
  perceptible, remain unanswered.
- **The wake-failure state has never been seen.** The review run was set to
  resolve successfully, so `"Couldn't wake …"` and its 3-second hold never ran.
  The copy is built and shares the status-line code that was reviewed, but
  nobody has read it on screen.
- The dot size, gap and bounce height were judged on a scaled desktop panel, not
  on a 7-inch one at 204 ppi. One of the three was already changed once for
  exactly this reason during the session.
- No stream, pairing, discovery, or real-host destructive flow was invoked.

## Required reading before continuation

1. `AGENTS.md`
2. Git branch, HEAD, tracking branch, remotes, working tree, and relevant log
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `BUGS.md`
8. `SPEC-host-carousel.md`
9. The active task brief, if one has been created
10. The applicable `BUILDING-*.md` before a build
