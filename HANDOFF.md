# Bulan — handoff

Context for whoever picks this up next, human or otherwise. Current as of
**26 July 2026**, branch `dev/token-proof`, head `f40a7deb`.

Bulan is a UI/UX-focused fork of moonlight-qt targeting the Steam Deck. The client
is a creative director who does not read code; explanations belong in plain English,
and design decisions are theirs to make, not yours to assume.

---

## Read these first, in this order

| Document | What it is |
|---|---|
| `~/Downloads/bulan-creative-brief.md` | **The authority on design.** Not in the repo — the client's file. §4 depth/atmosphere, §6 motion, §8 voice, §11 guardrails are the sections that get cited constantly. |
| `SPEC-host-carousel.md` | The host screen as built: navigation table, components, decisions, and what is knowingly unfinished. |
| `BUILDING-MAC.md` | How this machine builds and launches the project. |
| `UI-AUDIT.md` | Upstream's interface as it was *before* this work. Historical baseline, not a current description — it says so at the top. |

---

## Standing rules the client has set

These are not suggestions. They have been restated across several sessions.

1. **Custom components only.** No Qt Quick Controls. Stock components are precisely
   what makes upstream read as a utility. `QtQuick.Controls` is imported in exactly
   one Bulan file, `HostCarousel.qml`, solely for the `StackView` attached
   properties — no stock control is instantiated anywhere.
2. **Every value comes from the `Bulan` singleton.** No hardcoded colours, sizes,
   spacings or durations. **If a token is missing, tell the client and let them add
   it** rather than inlining a value. In practice: propose the token with a value
   sourced from the brief, and say plainly that you have done so.
3. **Minimum focus target 64×64px** at native 1280×800. Display-only elements are
   exempt (the hint bar is not focusable).
4. **Controller-first, always.** If something only works with a mouse, it is wrong.
5. **Commit per task, so each stays independently revertible.** Stop and show the
   result before moving on.
6. **Where the mockup and the brief disagree, ask.** Do not pick one silently.

---

## Where things stand

### Done and pushed

| Commit | What |
|---|---|
| `16315ad3` | Atmosphere layer extracted into a component; film grain added |
| `3dbcb6a9` | Controller glyph system |
| `7ed90b16` | Fixed black boxes behind glyphs |
| `7ab5ff1c` | Recoloured rect artwork; dropped the R-trigger workaround |
| `7cb235ed` | Hint bar |
| `c39437dc` | Host carousel replacing the host grid |
| `9bf731f1` | `SPEC-host-carousel.md` |
| `f40a7deb` | `BUILDING-MAC.md`, `UI-AUDIT.md`, gitignore fix |

### The component inventory

```
app/gui/
  Bulan.qml            design tokens — the single source of truth
  Atmosphere.qml       gradient + vignette + grain, each individually switchable
  ControllerGlyph.qml  one button glyph, by semantic action and live controller
  HintBar.qml          persistent bottom bar, declarative contents, display-only
  HostCarousel.qml     the host screen
  HostTile.qml         one host in the carousel
  HostPanel.qml        modal overlay: scrim, surface, title, body, optional field
  GlyphProof.qml       offline review sheet for glyphs; also previews the hint bar
  TokenProof.qml       offline review sheet for the tokens
```

Still upstream's, restyled but not rebuilt: `AppView.qml` (the game grid),
`SettingsView.qml`, `StreamSegue.qml`, `QuitSegue.qml`, the `Cli*` screens,
`PcView.qml`.

---

## What to do next

No instruction has been given yet. The obvious candidates, roughly in order of how
much they are blocking:

1. **The three states left minimal.** `SPEC-host-carousel.md` lists them:
   **Connecting** has no design; **host settings (SELECT)** has no designed screen
   and currently just shows the old "View Details" text; and **rename / delete /
   test-network are not reachable at all** from the carousel — they still live in
   `PcView.qml`, which is no longer the initial view. That last one is a functional
   regression against upstream and needs a home.
2. **The game grid.** `AppView.qml` is still upstream's grid with Bulan colours on
   it. It is the next screen a user hits after the carousel, and the visual jump is
   jarring.
3. **Settings.** `SettingsView.qml` is stock Qt Quick Controls throughout — the
   single largest violation of rule 1 remaining. 37 controls, two columns, and its
   D-pad navigation is a flat 37-step tab chain that ignores the visual layout
   (documented in `UI-AUDIT.md` §3). A real redesign, not a restyle.
4. **Sound.** Brief §7 specifies a full cue set. Nothing has been built.
5. **Screen transitions.** Brief §6 specifies 220ms vertical reveal.
   `Bulan.motionTransitionMs` exists and is unused.

---

## Waiting on the client

| Thing | Detail |
|---|---|
| **`deck_*` glyphs** | 10 files. Until they land, `deck` resolves to the Xbox set via `resolveGlyphFamily()` in `sdlgamepadkeynavigation.cpp` — deleting one line is the whole change. |
| **Grain intensity** | `atmosphereGrainOpacity` is at 0.03, the midpoint of the brief's 2–4%. The brief itself lists this as "Still Open" pending a real Deck panel. |
| **Deck verification** | A list of checks the Mac cannot perform is at the end of this document. |
| **Vignette / hint-bar band** | The client confirmed hairline-only for the hint bar. No filled surface token exists; if one is ever wanted, it is theirs to specify. |

---

## Hard-won knowledge — do not rediscover these

These each cost real time. They are the reason several files look the way they do.

### Qt renders SVG Tiny, and it does not honour `<clipPath>`

Instead of clipping, it **draws the `<rect>` inside the clip path**. Those rects
declare no fill, so they default to black and land as a solid square behind the
artwork. 17 of 30 glyphs had one.

`scripts/import-controller-glyphs.py` strips `<clipPath>` and `<defs>` before
recolouring. **That ordering is load-bearing** — recolouring first would fill the
clip rect and paint a black square over every glyph.

**Corollary that matters more than the bug:** the defect is invisible in macOS
QuickLook, which honours `clipPath` correctly. Checking art in a previewer proves
nothing. Check it in the app.

### `QT_QPA_PLATFORM=offscreen` cannot render shader effects

This is why glyph colour is **baked in at import** rather than tinted at runtime
with `MultiEffect`. A colorization pass renders nothing offscreen — which is exactly
how every screenshot in this project is taken — and it pulls in a Qt module that
would then have to exist inside the Flatpak.

The cost: each glyph tone is a separate generated set. There are currently two,
`res/glyphs/unfocused/` and `res/glyphs/focus/`. A third is one line in `VARIANTS`
plus a re-run. Both colours are read out of `Bulan.qml` by the script, so the design
system still owns the values.

### The art set draws inconsistently

Most shapes are filled with **no fill declared at all** (so they default to
invisible black); the PlayStation cross is `fill:none; stroke:#000`; the bumpers
carry a black stroke over a fill; and the three `start` glyphs draw their inner bars
with `<rect>`, not `<path>`. Both fill and stroke need recolouring, and a shape
declaring `fill:none` must keep it — giving an outline-only shape a fill turns it
into a solid blob.

The element list in the importer is deliberately **wider than what the art currently
uses** (circle, ellipse, polygon, polyline, line) so a future re-export reaching for
a different primitive does not silently come out black. An earlier pass restricted
it to `<path>` after checking four files; three of the thirty used rects.

**After any art delivery, re-run the importer and verify by scanning the output, not
by eye:** 30 files, 110 shape elements, every one carrying the token colour or
declaring `fill:none`.

### PathView spaces items `1/count` below `pathItemCount`

And `1/pathItemCount` above it. So a neighbour sits at path fraction 0.0 with two
hosts but 1/6 with three — one fixed geometry puts it in two different places, and
with three hosts the neighbours slide inward and collide with the focused tile.
`pathView.pathStretch` (1.5 or 1.0) compensates.

**PathView also instantiates a wrapped neighbour** regardless of how selection
moves. Focused on the first host it draws the *last* one to the left, promising a
host that pressing left can never reach. Delegates draw only when
`|index − currentIndex| ≤ 1`.

### The gamepad layer could not express the specified bindings

Y and START **both sent `Key_Hangup`** — indistinguishable to QML — and SELECT was
not mapped at all. Y now sends `Key_Call`, SELECT sends `Key_Context1`, both
reserved keys with no text meaning. `main.qml` still treats `Key_Call` as "show
settings" at the StackView level, so Y keeps its old behaviour on every screen that
does not claim it first.

**`SDL_CONTROLLERDEVICEREMOVED` was never handled** before this work. It leaked the
controller handle and would have left glyphs showing an unplugged pad.

### Steam Deck is not distinguishable by SDL controller type

The enum in the SDL2 headers this links against has no entry for it. Valve hardware
is identified by **vendor ID `0x28DE`**. SDL3 underneath does carry a Steam Deck
HIDAPI driver and reports the name "Steam Deck", but exposes no distinct type
through the SDL2 API.

### This links sdl2-compat, not SDL2

`libSDL2.dylib` reports version 3201.70.0 while the runtime logs "SDL3 version:
3.4.12". It is the SDL2 ABI shim running on real SDL3. All the controller
identification functions exist in both the headers and the shim, so the SDL2 API is
safe to build against — but do not assume SDL2 internals.

### The macOS build rewrites `app/Info.plist` in place

It stamps the literal `VERSION` placeholder to the real version number, so the file
shows as modified after every build. **Revert it before committing.** Committing the
stamped value replaces the placeholder the build's `sed` looks for and silently
breaks every future version bump. `.gitignore` carries a note about this.

### Upstream quirks worth knowing

- **`CenteredGridView` does not centre** when there are fewer items than fill one
  row — the row hugs the left edge. Visible in `AppView` with exactly 5 games.
- **Two empty-state messages have `wrapMode` but no width**, so they cannot wrap and
  run off both edges below roughly 820px. Fine at 1280.
- The custom-resolution label in `SettingsView.qml:360` builds a **hardcoded English
  "Custom"** while the frame-rate label beside it uses `qsTr`.
- **`GamepadMapper.qml` is an unreachable stub** with a permanently hidden toolbar
  button.

---

## Working on this project

### Build and run

```bash
cd ~/Developer/moonlight-qt && make -j$(sysctl -n hw.ncpu) release && open -n app/Moonlight.app
```

`-n` matters. Without it macOS activates an already-running instance instead of
launching the build you just made, and you review the wrong binary.

After pulling: `git submodule update --init --recursive && python3 setup-deps.py`.

### Reviewing screens without a Deck

There is no Screen Recording permission on this machine, so screens are captured
offscreen:

```bash
MOONLIGHT_FAKE_HOSTS=mixed MOONLIGHT_SCREENSHOT=/tmp/shot.png \
QT_QPA_PLATFORM=offscreen app/Moonlight.app/Contents/MacOS/Moonlight
```

| Hook | Effect |
|---|---|
| `MOONLIGHT_SCREENSHOT=<path>` | Pins the window to 1280×800, grabs it, exits. Also writes `<path>-toolbar.png`. |
| `MOONLIGHT_INITIAL_VIEW=qrc:/gui/X.qml` | Boots straight to a screen. `GlyphProof.qml` and `TokenProof.qml` are the review sheets. |
| `MOONLIGHT_FAKE_HOSTS=none\|one\|offline\|mixed` | Swaps a fixed host list into the carousel, so its states can be reviewed without pairing or unpairing real machines. |

All three are inert unless set. Note the grab captures `stackView` only — 1280×712,
without the toolbar — because the window root has no QML engine.

Regenerating assets:

```bash
python3 scripts/gen-atmosphere-textures.py        # grain + vignette
python3 scripts/import-controller-glyphs.py       # glyphs, from ~/Documents/Bulan/controller_glyphs
```

### The client's real hosts

`Shoebox` and `Steambox`, both usually online and paired. Useful for real testing,
and the reason `MOONLIGHT_FAKE_HOSTS` exists — the offline and zero-host states
cannot be produced without either faking or damaging their config.

---

## Deck checks the Mac cannot perform

Still outstanding. The client has the hardware.

**Could be outright wrong:**

1. **Glyph detection on the built-in controls.** Check the log for
   `Controller glyphs: <detected> -> <resolved>`. It should say `deck`. **If Steam
   Input is presenting a virtual gamepad it will say `fallback`**, and Valve's
   vendor ID never gets seen. Most likely failure of the lot.
2. **The Y / SELECT remap on physical buttons.** Never pressed one. Verify Y wakes,
   START opens client settings, SELECT opens host settings — and that Steam Input
   has not rebound them first.
3. **Hot-swap.** Plug a DualSense or Switch Pro in with the app open; every glyph
   should change live. Built and compiling, never observed.

**Judgement calls needing the real panel:**

4. **Grain density.** This Mac renders at 2× DPR, so the 128px noise tile covers 256
   device pixels — **grain looks twice as coarse here as it will on the Deck.**
5. **Colour banding on the gradient.** The Deck's LCD is where banding shows, and
   breaking it is the practical reason grain exists.
6. **Type at arm's length.** Sizes are px at 1280×800, exact on the Deck. Physical
   legibility at ~50cm is untestable on a desktop display.
7. **Motion feel.** `motionOvershoot: 0.7` (~3%) is an interpretation of
   "barely-there" — the brief gives no number.
8. **Menu battery cost.** The atmosphere measured below this machine's noise floor,
   and is structurally zero during a stream (the Qt window is hidden). But grain is
   a full-screen alpha blend, and only the Deck shows whether idling in menus costs
   anything.

---

## Things to be careful about

- **`git push` goes to `origin`, which is the client's fork** (`laweirdo`).
  `upstream` is moonlight-stream. Never push there.
- **The fork is GPLv3.** Brief §11 requires a *"Built on Moonlight"* credit in
  About. **This has not been done yet** and is a licence obligation, not a nicety.
- Do not modify host discovery or pairing logic when changing views. The one
  model change made so far was `AddressRole`, which is presentational and additive.
- The client corrects design work directly and expects it acted on without
  re-litigation. They have also caught two real defects by looking at screenshots
  more carefully than the tooling did — take their visual observations seriously
  even when a check has just passed.
