---
kind: validation-report
date: 2026-08-15
machine: Windows review station
build: polish-and-shell-rework, from master 177a58bd
---

# Frame-rate and pacing baseline — Windows review station

Stage 1 of the polish and shell rework. The client reported that animation
"seems to run at around 30 fps". This is the measurement that was taken before
any change was made to the motion or effect layers.

## What was measured, and how

Qt Release build, Qt 6.9.3 / MSVC, `QSG_RENDER_TIMING=1`, log captured from
stderr. The game grid was booted directly with
`MOONLIGHT_INITIAL_VIEW=qrc:/gui/AppView.qml`, `MOONLIGHT_FAKE_HOSTS=two`,
`MOONLIGHT_FAKE_GAMES=many`, and `MOONLIGHT_FAKE_GAMES_ART` pointed at 30
generated 600×900 JPEGs so the tiles carried real textures rather than the
fallback. The window was pinned to 1280×800, the Deck's panel size. Focus was
moved continuously with the keyboard for fourteen seconds, so the samples are
animated frames, not an idle scene.

Scripts are in the session scratchpad; they are review tooling and are not
committed.

## Result — the frame rate is not the problem here

| Run | Median frame delta | p90 | Jitter (p90/median) | Renderer cost |
|---|---|---|---|---|
| Shipping default (`basic` render loop), 1280×800, box art | 4 ms — 250 fps | 12 ms | **3.0×** | 0.30 ms/frame |
| Same, 2560×1600 (4× the pixels) | 8 ms — 125 fps | 12 ms | 1.5× | 0.25 ms/frame |
| `threaded` render loop, 1280×800, box art | 4 ms — 250 fps | 4 ms | **1.0×** | 0.01 ms/frame |

**Throughput is not the issue on this machine.** Quadrupling the pixel count
moved the renderer from 0.25 to 0.30 ms per frame, so the GPU is nowhere near
saturated and the ungated per-tile render targets in `GameTile.qml` cost nothing
measurable *here*. The 30 fps report could not be reproduced on Windows.

**Pacing is the issue.** On the shipping default, the interval between frames
has a p90 three times its median: frames arrive at 4 ms, then 12 ms, then 4 ms.
Uneven delivery of otherwise fast frames is what the eye reports as a low frame
rate. On the threaded render loop, under identical work, that jitter is 1.0× —
completely even.

## The cause of the jitter

`app/main.cpp:676` forces `QSG_RENDER_LOOP=basic` on every platform. The comment
gives the reason plainly: streaming depends on being able to block the render
thread from the main thread, which the threaded loop does not allow. The whole
user interface therefore runs on the non-threaded loop, where animation
advancement and rendering share the GUI thread and frame delivery is not paced.

To measure this at all, that line was changed to honour a `QSG_RENDER_LOOP` that
is already set, following the pattern the `QT_OPENGL` guard above it already
uses. **The shipping default is unchanged** — a build that does not set the
variable still gets `basic`.

## What this does not establish

- **Nothing about the Steam Deck.** No Deck was run. The Deck's GPU is far
  weaker and gamescope holds a 60 Hz vsync that this desktop window does not,
  so both the throughput and the pacing findings must be re-measured there
  before either is trusted. The ungated `GameTile` layers may well cost real
  time on that GPU while costing nothing here.
- **That the threaded loop is usable.** It was measured on the user interface
  only. No stream was started. Upstream's stated reason for forcing `basic` is a
  streaming requirement, and nothing here tests whether that requirement is
  still real on Qt 6.
- **That the client's 30 fps observation was wrong.** It was made on a build
  this session cannot identify. A separate build of a different branch existed on
  this machine, dated the same morning.
