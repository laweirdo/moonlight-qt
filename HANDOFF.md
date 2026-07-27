# Bulan — handoff

Context for whoever picks this up next, human or otherwise. Current as of
**27 July 2026**, branch `bulan`.

The first Steam Deck verification session has now happened. Checks 1–3 are done
and turned up two real defects; checks 4–8 are still open. See
"Deck checks the Mac cannot perform" at the end — **that section has been
rewritten with results and is no longer a to-do list.**

Bulan is a UI/UX-focused fork of moonlight-qt targeting the Steam Deck. The client
is a creative director who does not read code; explanations belong in plain English,
and design decisions are theirs to make, not yours to assume.

---

## Read these first, in this order

| Document | What it is |
|---|---|
| `bulan-creative-brief.md` | **The authority on design.** §4 depth/atmosphere, §6 motion, §8 voice, §11 guardrails are the sections that get cited constantly. |
| `FLOW.md` | Where every screen sits and how you get between them, as Mermaid. Two diagrams: Bulan as designed, and upstream as it is today. Carries the board's open questions as prose. |
| `SPEC-host-carousel.md` | The host screen as built: navigation table, components, decisions, and what is knowingly unfinished. |
| `BUILDING-MAC.md` | How the design machine builds and launches the project. |
| `BUILDING-DECK.md` | How the Steam Deck builds, installs and runs it. Read before any Deck session — the recipe hardcodes a source path and will silently build the wrong branch. |
| `UI-AUDIT.md` | Upstream's interface as it was *before* this work. Historical baseline, not a current description — it says so at the top. |

Design source material lives in `design/`:

| File | What it is |
|---|---|
| `design/onboarding-01-splash.png` … `-04-pairing-pin.png` | The four onboarding frames, 1× at 1280×800. Named so a future `SPEC-onboarding.md` can cite a single frame. **Nothing in this sequence is built** — the app has no onboarding at all today. |
| `design/navigation-flow-board.png` | The flow board as exported, 9902×1828. Mermaid lays out its own graph, so `FLOW.md` cannot reproduce the spatial reading; this is the reference for that. |

**These were all outside the repo until 27 July 2026.** Every session cited the
brief as authority while it sat in the client's Downloads folder, which meant no
session could be reproduced from a checkout alone. If a new authority document
appears, move it in rather than citing a path on someone's machine.

---

## How this repository is branched

Settled 27 July 2026. `dev/token-proof` is gone; everything it carried is on
`bulan`. Follow this — the shape exists to keep upstream syncs cheap.

| Branch | Role |
|---|---|
| `master` | **The fork's default branch, and a clean mirror of upstream.** Never commit Bulan work here. Its only job is to fast-forward from `upstream/master`. The moment it carries a fork-only commit, every future sync becomes a conflicted merge instead of a fast-forward. |
| `bulan` | **The integration branch and the baseline.** All Bulan work lands here. This is what you build, what you flash to the Deck, and what "known-good" means. |
| short task branches | One per task, cut from `bulan`, merged back when the client signs off, then deleted — local and remote. |

Task branches are **named at creation, once the task is actually known.** The old
`dev/token-proof` stopped describing its contents about eight commits in, which
is the failure this rule prevents. Prefixes in use: `fix/`, `docs/`, `feat/`.

Syncing with upstream is therefore: fast-forward `master` from
`upstream/master`, then merge `master` into `bulan`. Conflicts, if any, are
confined to that second step — the mirror itself never conflicts.

`origin` is the client's fork (`laweirdo`). `upstream` is moonlight-stream.
**Never push to `upstream`.**

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
| `4d967758` | This handoff document |
| `79f2baea` | `BUILDING-DECK.md` |
| `76e1fcb3` | The first Steam Deck verification session, and the defects it found |

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

## Known defects, found on the Deck

Nothing here has been fixed. The client asked for the full picture before any
changes, and then to decide. Do not fix without their say-so.

### 1. A is a dead button after visiting Client Settings — confirmed, reproducible

**The worst of the lot, and not Deck-specific.** It reproduces anywhere with a
gamepad; it surfaced here only because this was the first time anyone pressed
physical buttons in sequence rather than reviewing screens in isolation.

Go to the carousel, press START to open Client Settings, press B to come back,
press A. Nothing happens, permanently, until the app restarts.

`m_UiNavMode` is stuck `true` after the round-trip. That mode changes the keycode
for exactly two things — **A** (`Key_Return` → `Key_Space`) and D-pad up/down
(arrows → Tab/Shift+Tab). `HostCarousel` handles `onReturnPressed` and
`onEnterPressed` but **not Space**, so A silently reaches nothing. Every other
button is unaffected, which is what makes it look like a pairing bug rather than
a focus bug.

Confirmed by elimination: after the round-trip **X still opens "Add a PC"**, so
`root` has not lost active focus and the bindings are alive.

Both `SettingsView.onDeactivating` and `HostCarousel.onActivated` call
`setUiNavMode(false)`, so on paper the reset is correct. Two candidate
mechanisms, not yet distinguished:

- **`AutoResizingComboBox`** toggles nav mode around its popup and sets it back
  to `true` on close (`AutoResizingComboBox.qml:51`). If that fires *after* the
  pop, it re-arms the mode on a screen that has already reset it.
- **`HostCarousel.onActivated` never fires on pop-back**, so the reset never runs.

The experiment that splits them: enter settings and come straight back
(A should work), then enter settings, open the Resolution dropdown, close it,
come back (A should be dead). If only the second kills it, it is the combo box.

### 2. The hint bar offers "Wake" on hosts that cannot be woken

`actWake()` returns immediately when `host.online`, so on an online host Y does
nothing, by design — you cannot wake a machine that is already awake. But the
hint bar advertises **Wake** regardless of host state. Press it, nothing happens,
no explanation.

This is a design defect, not a binding one. The binding is correct. The client
saw it as a broken button, which is the point.

The offline path is still unverified — it needs a machine that can actually be
put to sleep.

### 3. `actConfirm()` pushes `AppView` without checking the component loaded

`HostCarousel.qml:186` does `Qt.createComponent("AppView.qml")` and pushes
`createObject(...)` with **no `component.status` check**. If `AppView.qml` ever
fails to load, `createObject` returns `null`, `stackView.push(null)` does
nothing, and the result is a dead A button with no error on screen.

This was *not* the cause of defect 1 — it is latent. But it converts any future
`AppView` breakage into exactly the same silent symptom, which cost real time to
diagnose once already.

### 4. Glyph family follows the most recently *attached* pad, not the most recently *used*

`refreshGlyphFamily()` reads `m_Gamepads.last()`, which only changes on hotplug.
Observed on the Deck: connect a DualSense and the glyphs switch to PlayStation
shapes; then pick the Deck back up and use its built-in controls, and the glyphs
**stay** on PlayStation. They only revert when the DualSense is disconnected.

**The client has specified the intended rule:** glyphs should follow whichever
controller most recently sent input. That is a different mechanism — it needs
input polling, not hotplug events.

### 5. Host Settings (SELECT) shows details, but should be a menu

Previously logged as "not yet designed". The client has now scoped it: SELECT
should open the right-click context menu equivalent — **host details, wake PC,
and forget PC** — not the bare details panel it currently shows. They have
flagged the host details screen as a priority candidate.

This also absorbs the "rename / delete / test-network are unreachable"
regression noted below: that menu is where they belong.

---

## What to do next

The client has seen the full picture and will decide. The candidates, with the
Deck findings folded in:

0. **The defects above**, of which defect 1 is the only one that makes the app
   feel broken in normal use.

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
| **`deck_*` glyphs** | 10 files. Until they land, `deck` resolves to the Xbox set via `resolveGlyphFamily()` in `sdlgamepadkeynavigation.cpp` — deleting one line is the whole change. **Detection is now confirmed working on real hardware**, so those 10 files are the only thing between here and Deck glyphs. |
| **Grain intensity** | `atmosphereGrainOpacity` is at 0.03, the midpoint of the brief's 2–4%. The brief itself lists this as "Still Open" pending a real Deck panel. |
| **Deck verification** | Checks 1–3 done — see the end of this document. Checks 4–8 need the client's eyes on the panel and are still open. |
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

**Verified on hardware: this works.** The built-in controls resolve to `deck`.
The earlier worry that Steam Input would mask Valve's vendor ID appears
unfounded — its virtual pad is `Vendor=28de Product=11ff` in
`/proc/bus/input/devices`, i.e. it carries Valve's vendor ID too. Still unproven
in **Game Mode**, which is where Steam Input actually sits in the path; the
confirmed run was Desktop Mode.

### The glyph detection log line cannot be seen the obvious way

`resolveGlyphFamily()` maps **both** `deck` and `fallback` to `xinput`, the
constructor initialises `m_GlyphFamily` to `xinput`, and `refreshGlyphFamily()`
only logs when `resolved != m_GlyphFamily`. So on a Deck the line is **silent
whether detection succeeds or fails**, and the on-screen glyphs are identical
either way. Simply launching the app and reading the log proves nothing.

The way to force it, with no code change: connect a DualSense (glyphs go
PlayStation, logs `ds -> ds`), then **disconnect it**. Removal calls
`refreshGlyphFamily()` while the built-in pad is still open, and the previous
value is now `ds`, so the comparison passes and the real answer prints:

- `Controller glyphs: deck -> xinput` — detection works.
- `Controller glyphs: fallback -> xinput` — detection failed.

This is the only known way to observe it today. A permanent fix would be an
unconditional log at startup.

### The Deck in hand is a "Galileo" — the OLED, not the LCD

`/sys/class/dmi/id/product_name` reports `Galileo`. 1280×800 at roughly
**204 ppi**.

This matters for the atmosphere checks. The brief's banding concern targets the
**LCD**, and the two panels fail differently — LCD shows wide stepped bands,
OLED tends toward near-black crush and tinting. **The LCD banding case cannot be
checked on this hardware at all.**

It also sharpens the grain question. At 2× DPR on the design machine each grain
speck covered 2 device pixels; here it covers 1 physical pixel, about 0.12 mm,
which at a 50 cm viewing distance is roughly 0.9 arcmin — at or below the limit
of human acuity. **The likely failure mode for grain on the Deck is "invisible",
not "too coarse."** And invisible grain cannot break banding, so grain density
and banding have to be judged together rather than as separate checks.

Same arithmetic flags `sizeCaption: 16` as the type size at risk: about
13.7 arcmin at 50 cm, below the ~16 arcmin comfort threshold. `sizeBody: 22` and
up are fine.

### The atmosphere switches are compile-time, which makes A/B measurement slow

`atmosphereGrainEnabled`, `atmosphereVignetteEnabled` and
`atmosphereGradientEnabled` are `readonly property` in `Bulan.qml`. Toggling one
needs a rebuild — about two minutes on the Deck. Any grain-on/grain-off power
comparison therefore costs two builds. If that becomes routine, making them
runtime-switchable is a small change.

Idle draw with the app closed, on battery, measured at **3.92 W**
(`current_now × voltage_now` from `/sys/class/power_supply/BAT1`; there is no
`power_now` on this machine). The reading is noisy — sample repeatedly.

### This links sdl2-compat, not SDL2

`libSDL2.dylib` reports version 3201.70.0 while the runtime logs "SDL3 version:
3.4.12". It is the SDL2 ABI shim running on real SDL3. All the controller
identification functions exist in both the headers and the shim, so the SDL2 API is
safe to build against — but do not assume SDL2 internals.

### The macOS build used to rewrite `app/Info.plist` in place — fixed

**Historical, kept because the symptom is memorable and the trap could be
reintroduced.** Until `460e7436` the build stamped the literal `VERSION`
placeholder to the real version number *in the tracked template*, so the file
showed as modified after every build and had to be reverted by hand. Committing
the stamped value would have destroyed the placeholder the build's `sed` looks
for and silently broken every future version bump.

Two causes, both now fixed in `app/app.pro`:

- The old rule copied the template to `$$OUT_PWD/Info.plist`. In a **shadow**
  build that is a different file; in an **in-source** build — which is what this
  project does — `OUT_PWD == PWD`, so the copy was a no-op and the `sed` landed
  on the tracked template.
- It used `sed -i -e`, and BSD `sed` reads the argument after `-i` as a backup
  suffix. So macOS consumed the `-e` and dropped a stray `Info.plist-e` beside
  the template on every build.

The build now writes `app/Info.generated.plist` — a different filename from the
template, so in-source and shadow builds behave identically — with a plain
redirect rather than in-place editing. **Building no longer dirties the working
tree.** If `git status` is ever non-empty after a build again, this regressed.

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

On the Deck it is a Flatpak build instead — see `BUILDING-DECK.md`. Three traps
worth knowing before you start, all of which cost time this session:

- **The recipe hardcodes the source path** and will happily build a different
  branch than the one you have open, with no warning.
- **Submodules are per-worktree** and a fresh worktree has none.
- **The offscreen hooks need `--filesystem=home`** or the screenshot silently
  never appears.

The generated glyph and atmosphere assets are **committed**, so the two asset
scripts do not need re-running after a pull — only after new art is delivered.

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

First verification session done **26 July 2026** on a Steam Deck OLED
("Galileo"), Desktop Mode, real hosts on the client's network.

### 1. Glyph detection on the built-in controls — PASSED

Confirmed `Controller glyphs: deck -> xinput`. Valve's vendor ID **is** seen and
the built-in controls are correctly identified as `deck`. It resolves to
`xinput` only because no `deck_*` art exists yet.

This was predicted to be "most likely failure of the lot". It was not a failure.

Two caveats: the line cannot be observed by simply reading the log — see
"hard-won knowledge" for the DualSense-disconnect trick that forces it — and this
was **Desktop Mode**. Game Mode, where Steam Input actually sits in the path, is
still unverified.

### 2. The Y / SELECT remap on physical buttons — PASSED, but see defects

All five bindings arrive and fire the right handler, including the two that were
structurally broken before this work (Y and START sharing a keycode, SELECT
unmapped entirely). **Steam Input has not rebound them.** "Swap face buttons" was
confirmed off, ruling out that confounder.

| Press | Sends | Result |
|---|---|---|
| A | `Key_Return` | Works — but see defect 1, it dies after a Client Settings round-trip |
| Y | `Key_Call` | Binding correct; silently returns on online hosts — defect 2 |
| X | `Key_Menu` | Opens "Add a PC" |
| START | `Key_Hangup` | Opens Client Settings |
| SELECT | `Key_Context1` | Opens Host Settings — the destination is unbuilt, defect 5 |
| B | `Key_Escape` | Back / close |

The remap is sound. What the session found was two problems sitting *behind*
correct bindings.

### 3. Hot-swap — PASSED, one question open

Connecting a DualSense with the app open switched the glyphs live. Disconnecting
reverted them.

What it also exposed is defect 4: glyphs do **not** switch back when the built-in
controls resume input while the DualSense is still connected.

Still unanswered: did *every* glyph in the hint bar change, or did any stay Xbox?

### 4–8. Judgement calls needing the real panel — STILL OPEN

Not yet reported by the client. Predictions from the hardware, so the next
session knows what "wrong" looks like:

4. **Grain density.** `atmosphereGrainOpacity: 0.03`, 128×128 tile. Expect
   **invisible**, not coarse — see the Galileo note above. Look at the flat area
   mid-screen at 50 cm, then again at 25 cm.
5. **Colour banding.** **Cannot be completed on this hardware** — the concern
   targets the LCD and this is an OLED. What can be checked is the darkest region
   of the gradient, above the hint bar, for stepping or colour cast. If a Deck LCD
   is in scope, this stays open.
6. **Type at arm's length.** `sizeCaption: 16` is the one at risk (~13.7 arcmin at
   50 cm). Read the address line under the host name, and the hint bar labels, at
   normal holding distance.
7. **Motion feel.** `motionOvershoot: 0.7`, `motionFocusMs: 140`. Hold left/right
   to run the carousel fast — soft landing or visible bounce? Then a single tap:
   immediate or laggy?
8. **Menu battery cost.** Baseline with the app closed is 3.92 W. Note the
   compile-time-switch problem above: an on/off comparison costs two builds.

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
