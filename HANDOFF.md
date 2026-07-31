# Bulan - current handoff

Current as of **31 July 2026**.

This file records live repository and validation state. `AGENTS.md` owns
permanent operating rules; `ROADMAP.md` owns sequencing; `BUGS.md` owns
acknowledged unintended behavior. The active task brief is `TASK-BRIEF.md`.
Always inspect Git before relying on this snapshot.

## Repository state when written

| Item | State |
|---|---|
| Integration branch | `bulan` and `origin/bulan` at `351de13c` |
| Task branch | `tile-busy-state`, cut from `bulan`, six commits ahead |
| Remote | `origin` only, the client's fork |
| Pushed | **No.** Nothing on this branch has been pushed or merged |
| Active task | `TASK-BRIEF.md` — the host tile's connecting and waking busy state |
| Open defects | None recorded in `BUGS.md` |

**The client has not yet reviewed this work.** It is built, it builds clean, and
it has been looked at in screenshots on the Windows review station. It has not
been accepted.

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

- **No client review.** Nobody has pressed a button on this build.
- No controller test of any kind. The whole busy state has been seen only in
  still screenshots driven by an environment variable.
- No Steam Deck Desktop Mode or Game Mode validation.
- No real sleeping host. The 30-second timeout, whether it feels right in the
  hand, and whether the ~3 second notice latency is perceptible are all
  unanswered and can only be answered on real hardware.
- The **connecting** dots and the **wake failed** state were not captured. Both
  are built and both share the tile code path that was captured, but neither has
  been seen. `MOONLIGHT_FAKE_CONNECT_HOLD_MS` exists to capture the first; the
  second needs a 30-second wait the screenshot hook does not allow for.
- No stream, pairing, discovery, or real-host destructive flow was invoked.

## Required reading before continuation

1. `AGENTS.md`
2. Git branch, HEAD, tracking branch, remotes, working tree, and relevant log
3. `bulan-creative-brief.md`
4. `FLOW.md`
5. `ROADMAP.md`
6. This file
7. `TASK-BRIEF.md`
8. `BUGS.md`
9. `SPEC-host-carousel.md`
10. The applicable `BUILDING-*.md` before a build
