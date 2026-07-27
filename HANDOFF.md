# Bulan — handoff

Context for whoever picks this up next, human or otherwise. Current as of
**27 July 2026**, branch `bulan`.

The first Steam Deck verification session has happened, and the defects it found
are fixed. Deck checks 1–3 are done; checks 4–8 are still open and need the
client's eyes on the real panel. See "Deck checks the Mac cannot perform" at the
end.

**Roadmap Phase A is complete except for the parts only the client can do.**
Defects 1–4 are fixed and merged, the source documents are in the repo, `bulan`
exists as the known-good baseline, and upstream has been merged. What Phase A
still wants: Deck checks 4–8 reported, Game Mode verified, the wake question
answered. `REVIEW-CHECKLIST.md` now exists and is what that session should work
from. **The three global tokens are still
unsettled** — `sizeCaption`, `atmosphereGrainOpacity` and `motionOvershoot` are
frozen pending real observation, and `ROADMAP.md` is explicit that construction
should not start before they are.

Bulan is a UI/UX-focused fork of moonlight-qt targeting the Steam Deck. The client
is a creative director who does not read code; explanations belong in plain English,
and design decisions are theirs to make, not yours to assume.

---

## Read these first, in this order

| Document | What it is |
|---|---|
| `bulan-creative-brief.md` | **The authority on design.** §4 depth/atmosphere, §6 motion, §8 voice, §11 guardrails are the sections that get cited constantly. |
| `FLOW.md` | Where every screen sits and how you get between them, as Mermaid. Two diagrams: Bulan as designed, and upstream as it is today. Carries the board's open questions as prose. |
| `ROADMAP.md` | **The authority on sequencing.** What v1 is, the scope decisions that stopped being re-derived, and the phase order. |
| `REVIEW-CHECKLIST.md` | The next Deck session, as a list. Regression on the four fixes, then the judgement calls that settle the three frozen tokens. |
| `SPEC-host-carousel.md` | The host screen as built: navigation table, components, decisions, and what is knowingly unfinished. |
| `BUILDING-MAC.md` | How the design machine builds and launches the project. |
| `BUILDING-DECK.md` | How the Steam Deck builds, installs and runs it. Read before any Deck session — the recipe hardcodes a source path and will silently build the wrong branch. |
| `UI-AUDIT.md` | Upstream's interface as it was *before* this work. Historical baseline, not a current description — it says so at the top. |

Design source material lives in `design/`:

| File | What it is |
|---|---|
| `design/onboarding-01-splash.png` … `-04-pairing-pin.png` | The four onboarding frames, 1× at 1280×800. Named so a future `SPEC-onboarding.md` can cite a single frame. **Nothing in this sequence is built** — the app has no onboarding at all today, and these frames show the *superseded* composition built around the reflected mark. Content and copy still hold; the layout does not. See Phase C. |
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

**Done once, 27 July 2026, and it worked as designed.** Twelve upstream commits
fast-forwarded onto `master`, then merged into `bulan` with **no conflicts**.
Only two files are touched by both sides — `app/main.cpp` and `app/app.pro` —
and both merged cleanly because the edits sit in different regions. Upstream
also replaced the `h264bitstream` submodule with vendored sources; that lands
cleanly but leaves an untracked `h264bitstream/h264bitstream/` directory behind
from the old submodule checkout. It is safe to delete and was.

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
| `460e7436` | Merged the macOS Info.plist build fix — builds no longer dirty the tree |
| `b4110453` | Defects 1 and 3: the dead A button, and the silent game-grid failure |
| `95efe680` | Defect 4: glyphs follow the pad in use; unconditional detection log |
| `93394eaf` | Defect 2: hints appear only in states where their button does something |
| `cfb9d25b` | Brief, `FLOW.md`, onboarding frames and the flow board moved into the repo |
| `d52c1435` | `ROADMAP.md` |
| `40b9d938` | Merged upstream moonlight-qt — 12 commits, no conflicts |

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

## Defects from the Deck session

Defects 1–4 are **fixed and merged** (`fix/input-defects`, merged 27 July 2026).
Defect 5 is a design task, not a bug, and is scheduled as Phase B work.

| # | What it was | Status |
|---|---|---|
| 1 | A was a dead button after a Client Settings round trip | Fixed |
| 2 | The hint bar offered Wake on hosts that were already awake | Fixed — the hint is hidden on an online host |
| 3 | `actConfirm()` pushed the game grid without checking it loaded | Fixed — both failure paths now report |
| 4 | Glyphs followed the most recently *attached* pad, not the most recently *used* | Fixed |

### 5. Host Settings (SELECT) shows details, but should be a menu — STILL OPEN

The client has scoped it: SELECT should open the right-click context menu
equivalent — **host details, wake PC, and forget PC** — not the bare details
panel it currently shows.

This also absorbs the "rename / delete / test-network are unreachable"
regression: those still live in `PcView.qml`, which is no longer the initial
view, and that menu is where they belong. `ROADMAP.md` puts this first in
Phase B, and calls it a functional loss against upstream.

---

## What to do next

**`ROADMAP.md` is now the authority on sequencing.** It supersedes the informal
candidate list that used to live here. The short version:

Phase A (stabilise) is done apart from what only the client can do —
**Deck checks 4–8, Game Mode verification, the wake question, and
`REVIEW-CHECKLIST.md`.** Phase A explicitly gates construction, because
`sizeCaption`, `atmosphereGrainOpacity` and `motionOvershoot` are global: if
`sizeCaption` fails at arm's length it is a token change touching every screen
built and unbuilt. **Do not start Phase B screens while those are unsettled.**

Phase B closes the core loop: host settings menu, the Connecting state, the game
grid, game detail, and wiring up the 220ms screen transition that
`Bulan.motionTransitionMs` already defines and nothing uses.

`REVIEW-CHECKLIST.md` is what the remaining Phase A work looks like in practice.
It is written to be worked top to bottom on the hardware, and its last section is
the list of answers that need to come back.

**Phase C is no longer blocked.** The client decided the onboarding frames do not
use the reflected mark — they use `app/res/bulan_logo_horiz.svg`, the wordmark
the carousel already draws. The consequence is that all four frames need
recomposing rather than resizing: they were built around a tall centred element,
and the wordmark is small and horizontal, so the vertical space it vacates has to
be deliberately reallocated. **The PNGs in `design/` are the old composition** —
reference for content and copy, not for layout.

---

## Waiting on the client

| Thing | Detail |
|---|---|
| **`deck_*` glyphs** | 10 files. Until they land, `deck` resolves to the Xbox set via `resolveGlyphFamily()` in `sdlgamepadkeynavigation.cpp` — deleting one line is the whole change. **Detection is now confirmed working on real hardware**, so those 10 files are the only thing between here and Deck glyphs. |
| **Grain intensity** | `atmosphereGrainOpacity` is at 0.03, the midpoint of the brief's 2–4%. The brief itself lists this as "Still Open" pending a real Deck panel. |
| **Deck verification** | Checks 1–3 done — see the end of this document. Checks 4–8 need the client's eyes on the panel and are still open, and `ROADMAP.md` gates all construction on them. Game Mode is check 9. |
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

### Global state written by a component that is being destroyed

**This was defect 1, and the shape of it will recur.** The settings page arms a
tab-chain navigation mode in which A sends Space instead of Return. Its combo
box turned that mode off while its dropdown was open and asserted it back *on*
when the dropdown closed — including when the dropdown was being torn down along
with the page, which happens *after* the page has already reset the mode. The
carousel then ran its own reset and happened to land last, which is the only
reason the bug was intermittent rather than constant.

Two things worth carrying forward:

- **A dying component cannot tell that it is dying.** At `aboutToHide` during
  teardown, the combo box's `visible`, `enabled`, `parent` and `Window.window`
  are all indistinguishable from a normal close. Checked directly; there is no
  discriminator to branch on. Any fix that depends on detecting teardown is
  built on sand.
- **The fix was to remove the authority, not to order the writes.** The screen
  owns the navigation style; a popup now only declares that it is open
  (`setNavModeSuspended`). Clearing a suspension cannot resurrect a stale value,
  so ordering stops mattering. If you find yourself reasoning about which
  handler runs last, that is the signal to split the state instead.

The symptom is worth recognising: **exactly one button dead, everything else
fine.** Only two places in the app ever turn that mode on, so a stuck mode is
always one of them — that argument narrows this class of bug faster than any
experiment.

### Glyph detection is logged unconditionally at startup

It did not used to be. `resolveGlyphFamily()` maps both `deck` and `fallback` to
`xinput`, and the old log fired only when the *drawn* family changed — so on a
Deck the line was silent whether detection succeeded or failed, and the only way
to force it was to connect a DualSense and unplug it. Every Deck session paid
that tax.

Three lines now print at startup regardless:

```
Controller glyphs: 1 controller(s) attached
Controller glyphs:   "Steam Deck" vendor=28de product=1205 type=0 -> deck
Controller glyphs: detected deck, drawing xinput
```

`detected deck` means Valve's vendor ID was seen. `detected fallback` with a
controller attached means it was not. `drawing xinput` is expected either way
until `deck_*` art exists. The change-triggered line now keys off what was
**detected** rather than what is drawn, so hot-swaps are visible too.

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

One caveat remains: this was **Desktop Mode**. Game Mode, where Steam Input
actually sits in the path, is still unverified — `ROADMAP.md` lists it as check
9. The old caveat about the line being unobservable is gone: detection is now
printed unconditionally at startup, so reading the log is enough.

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

What it also exposed was defect 4: glyphs did **not** switch back when the
built-in controls resumed input while the DualSense was still connected. That is
now fixed — they follow the pad most recently used. **Re-test on hardware**: with
a DualSense connected, press something on the Deck itself and the glyphs should
revert without unplugging anything.

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
