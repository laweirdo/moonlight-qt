# Bulan — handoff

Context for whoever picks this up next, human or otherwise. Current as of
**28 July 2026**, branch `bulan`.

**Two Steam Deck sessions and one Mac session have happened. Phase A is closed
and now owes nothing.** See "Deck verification — what has actually been checked"
near the end for the results, and `REVIEW-CHECKLIST.md` for the full answers.

**The three global tokens are settled**, from observation on the real panel
rather than arithmetic: `atmosphereGrainOpacity` stays **0.03**, `sizeCaption`
stays **16**, `motionOvershoot` stays **0.7**. `motionFocusMs` moved **140 → 180**
on the client's call. **Construction is no longer gated** — `ROADMAP.md` Phase B
can start.

**Game Mode is verified** and it passed, which closes the project's largest
untested assumption: Steam Input interposes a virtual controller but carries
Valve's vendor ID through, so glyph detection and all five bindings survive.

**Wake works.** The last Phase A question was answered on the Mac on 28 July: a
paired host put genuinely to sleep was woken from the carousel with Y and was
back a minute later. *"Asleep"* is a promise the app can keep, and the copy
stands as written.

**The three defects `BUGS-open.md` was opened for are all closed.** Two more were
found while closing them; one of those is fixed too, and **one is still open** —
the carousel still wraps once per move at **two** hosts, which is the client's
real host count.

**Two of the three original entries had a wrong diagnosis on record**, and both
wrong diagnoses cost this session time before they were caught. Read
`BUGS-open.md` before trusting the phrase "ruled out" in any bug write-up on this
project — the note at the top of it explains how both went wrong in the same way,
and it is the same way twice.

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
| `7e8506c1` | The build stamp — the log now names the commit and build time it is running |
| `d3c57f95` | The fake-host crash, and `MOONLIGHT_FAKE_HOSTS=many` |
| `9c721e13` | The carousel's visible wrap at three hosts |
| `1ba04c01` | The Mac session write-up, and two corrected diagnoses |
| `402b37d4` | Wake no longer offered on hosts that cannot be woken |

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

## Defects from the Deck sessions

Defects 1–4 were fixed on `fix/input-defects` (merged 27 July 2026) and **all
four were then confirmed by hand on real hardware** on 28 July. Defect 5 is a
design task, not a bug, and is scheduled as Phase B work.

| # | What it was | Status |
|---|---|---|
| 1 | A was a dead button after a Client Settings round trip | Fixed. Hardware-confirmed — but see below, hardware found a *third* cause |
| 2 | The hint bar offered Wake on hosts that were already awake | Fixed. Hardware-confirmed; reflow accepted as built |
| 3 | `actConfirm()` pushed the game grid without checking it loaded | Fixed — both failure paths now report |
| 4 | Glyphs followed the most recently *attached* pad, not the most recently *used* | Fixed. Hardware-confirmed |

**Defect 1 had a third mechanism the original diagnosis missed**, found on
hardware and fixed in `be874bf8`: a popup elsewhere in the window restores focus
to a control that no longer exists on the way back, landing *after* the carousel
has claimed it. The carousel now reclaims focus whenever it loses it rather than
claiming it once, which cannot be raced.

That symptom — **exactly one button dead, everything else fine** — has now come
from three different causes. It happens because A is the only button with no
window-level shortcut behind it, so anything that stops the screen listening
takes out A alone and leaves everything looking healthy. Do not read it as a
pairing or binding problem. See `BUGS-open.md`.

**Three defects are currently open**, all in `BUGS-open.md`, none of which needs
a Deck to reproduce.

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
| **`deck_*` glyphs** | 10 files. Until they land, `deck` resolves to the Xbox set via `resolveGlyphFamily()` in `sdlgamepadkeynavigation.cpp` — deleting one line is the whole change. **Detection is confirmed working on real hardware in both Desktop Mode and Game Mode**, so those 10 files are the only thing between here and Deck glyphs. |
| **Vignette / hint-bar band** | The client confirmed hairline-only for the hint bar. No filled surface token exists; if one is ever wanted, it is theirs to specify. |
| **Status colour on in-between states** | Red and green now carry reachability on the host status line. *Looking for your PC…*, *Connecting…* and *Not paired yet* were left on the neutral text colour, on the reasoning that red and green are verdicts and those states have not reached one. Assistant's call, flagged to the client, not yet overturned. |
| **The two-host carousel wrap** | `BUGS-open.md` defect 4. Still visible once per move at the client's real host count. Curing it properly is most of a session and carries real regression risk on the first screen. Worth a decision before it is started. |
| **Review-mode copy** | Pressing A on a review-mode host now raises a *"Review mode"* panel. Placeholder wording, never seen by a real user, changeable on request. |

**Settled 28 July, no longer waiting:** grain intensity (`atmosphereGrainOpacity`
stays 0.03), caption size (`sizeCaption` stays 16), overshoot
(`motionOvershoot` stays 0.7), the hint-bar reflow (accepted as built),
**the wake question — wake works, so the "Asleep" copy stands**, and Wake being
withheld on hosts that cannot be woken.

---

## Hard-won knowledge — do not rediscover these

These each cost real time. They are the reason several files look the way they do.

### A rebuild can install perfectly and still not be what you are looking at

**This cost most of the 28 July session and produced three wrong conclusions in a
row.** Three separate things can put an old interface in front of you, and they
stack:

1. **An old instance is still running.** `flatpak run` on a running app raises
   the existing window instead of starting the new build. Exactly the trap `-n`
   solves on macOS. Check `flatpak ps | grep -c MoonlightFork` is 0 before
   launching and 1 after.
2. **The interface is served from a stale on-disk cache** that survives
   rebuilds. Files days older than the build is the tell. Path and removal
   command are in `BUILDING-DECK.md`.
3. **A broken screen falls back to upstream's interface.** If a Bulan screen
   fails to load, the app quietly shows upstream's grid instead. That reads as
   "my build didn't take" and is actually "my build took and my screen is
   broken".

**The recovery is always the same: read the log.** It states load failures in
plain language, with file and line. Two sessions have now been lost to inferring
build state from the outside when the app was saying it outright.

**As of `7e8506c1` the log answers the first two outright**, so stop inferring
them. Second line of every run:

```
Build: fix/carousel-defects @ deck-test-1-56-g9c721e13 | binary built "2026-07-28T16:43:59"
```

The commit answers *is this the code I think it is*, which catches building a
different source tree — the Deck recipe's hardcoded source path makes that a live
risk there. The timestamp answers *is this the build I just made*, which catches
an old instance in front of you. They fail independently, which is why both are
printed. `-dirty` on the commit means uncommitted changes, which mid-session is
normal and itself worth seeing.

It is regenerated by `scripts/gen-buildstamp.sh` on **every** build, not at
`qmake` time. A stamp generated once at configure time would go on describing
whichever commit happened to be checked out then, which would not merely fail to
help — it would lie, which is the exact failure it exists to prevent. The script
only rewrites its header when the value changes, so ordinary rebuilds do not
recompile `main.cpp`.

### Do not grep the binary to check what is in a build

Interface code is not stored as plain text in the executable. `grep` returns zero
for identifiers that have been in a file for weeks, which looks exactly like
proof of a stale build. It is not proof of anything. This directly caused a wrong
diagnosis on 28 July.

The log is the source of truth for what loaded.

### QML `console.log` never reaches the log **on the Deck**; on the Mac both do

Debug output from the interface layer is dropped **in the Flatpak build**.
Warnings are not, and print as `Qt Warning:` lines. `qDebug()` from C++ also
arrives.

**Checked on the Mac on 28 July and it is different there**: `console.log`
arrives as `Qt Debug:` and `console.warn` as `Qt Warning:`. Both work. So this is
a property of how the Deck build is run, not of QML.

The rule that survives is the second-order one, not the first: **prove your
logging appears before drawing any inference from its absence**, because the
answer differs between the two machines this project builds for. Using
`console.warn` everywhere costs nothing and works on both.

An empty log was read as "the handler never fired" when the handler had run
perfectly and the logging was the thing that never arrived — the opposite
conclusion, and it sent a diagnosis down the wrong path for hours. **Prove your
logging appears before drawing any inference from its absence.**

### A `Behavior` cannot animate a `readonly property`

Marking one readonly and attaching a `Behavior` makes the whole component fail to
load, which cascades: the component using it fails, its screen fails, and the app
falls back to upstream's interface with no hosts. The visible symptom looks
nothing like a motion bug.

This is worth generalising: **in this codebase a single bad property assignment
takes out an entire screen, silently, and lands you on upstream's UI.** Suspect
it whenever a screen "reverts".

### `pkill -f` with the app ID kills your own shell

The pattern matches the command line of the shell running it. Use
`flatpak kill io.github.laweirdo.MoonlightFork`, or kill by PID from
`flatpak ps`. Cost two aborted commands in one session.

### Battery readings are silently zero on mains power

`current_now` reads 0 whenever the charger is connected, so the arithmetic
produces a confident, entirely fictional **0.00 W**. Check
`/sys/class/power_supply/ACAD/online` is `0` and `BAT1/status` is `Discharging`
before trusting anything. Note also that **there is no `bc`** on this machine —
use `awk`.

Do not sample while a build is running; compiling swamps the reading.

### `MOONLIGHT_FAKE_HOSTS` cannot be used past the carousel

Fake hosts are for reviewing the carousel and nothing beyond it; anything that
needs A pressed to completion needs a real host. Screens past the carousel are
reachable with `MOONLIGHT_INITIAL_VIEW` instead, so this is not a blocker for
Phase B review.

**A now says so rather than crashing** (`d3c57f95`), and the reason it used to
crash is worth carrying forward, because the same shape will recur anywhere a
view is fed an injectable model:

**Everything past the offline branch of `actConfirm()` addresses a machine by its
POSITION in the real host list**, and a fake host's position means nothing there.
With two real machines paired, pressing A on the second fake host quietly opened
the *second real machine's* games and looked like it worked. Pressing A on the
fifth read off the end of the list and segfaulted. Whether it died depended on how
many real machines happened to be paired — which is why it reproduced on the Deck
and not on the Mac until it was looked for deliberately.

**The silent wrong action was worse than the crash**, and a crash is what got
reported. Assume any injectable-model debug hook has this failure mode until the
guard is shown to cover every branch, not just the one that was noticed.

### Removing a PC in Moonlight does not unpair it

Learned while trying to produce an online-but-unpaired host to confirm defect 1
in Desktop Mode.

"Delete PC" removes the machine from **this** client's list. It does not tell the
host to forget this client. Add it back and the host recognises the client
certificate, reports itself as already paired, and no PIN panel ever appears —
so the pairing flow cannot be exercised this way.

**The unpair has to happen on the host.** Both of the client's machines run
Sunshine (`state` reports `SUNSHINE_SERVER_FREE`), so it is done in Sunshine's
own web interface, under Troubleshooting. That needs the client's login and is
therefore theirs to do.

Re-pairing afterwards is one PIN typed on the host. A completed pairing runs five
requests ending in an HTTPS `pairchallenge`; an abandoned one stops after the
first and eventually logs `RemoteHostClosedError`. That difference is how to tell
from the log whether a pairing actually completed rather than taking it on trust.

### Wake needs a hardware address the host has to volunteer

`wakeable` in `computermodel.cpp` is simply "we have a MAC stored", and the MAC
comes from the host's own `serverinfo` reply. **Moonlight rejects
`00:00:00:00:00:00`**, which is what Sunshine reports over plain HTTP and, on at
least one of the client's machines, over HTTPS too.

The practical consequence: **`Steambox` is wakeable and `Shoebox` is not**, and no
amount of app-side work changes that. Any future wake testing has to use
Steambox. The hint bar checks `wakeable` before offering Wake as of `402b37d4`; before
that it offered Wake on `Shoebox` and could only ever refuse.

Wake itself broadcasts on every network interface as well as to the addresses it
knows, so a host known only by a VPN address is still wakeable provided it is
physically on the same network. Confirmed working on 28 July.

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

### A full PathView loop always has one item crossing the join

This is the root of `BUGS-open.md` defects 2 and 4 and is worth understanding
once rather than rediscovering per host count.

`PathView` arranges items around a **closed loop**. While the host count is at or
below `pathItemCount` the items fill that loop exactly, so every move forces one
of them to travel from one end of the path to the other — it leaves one edge of
the screen and reappears at the opposite one in a single frame. The join sits at a
visible screen position, so that crossing is visible.

Once the host count **exceeds** `pathItemCount` the surplus items are never built
at all. Nothing crosses, and new neighbours slide in from beyond the edge exactly
as they should. Verified by frame-by-frame trace at five hosts: completely clean.

**Two consequences that are easy to get backwards:**

- **Raising `pathItemCount` does not give the loop slack.** Spacing is
  `1/count` in that regime, so the items still fill the loop however high you
  push it. Slack only comes from having *more hosts than tiles drawn*, which is
  the opposite adjustment. A previous write-up recommended raising it first; it
  cannot work.
- **`movementDirection` defaults to "shortest way round the loop"**, which is
  right for something that wraps and wrong for this, which clamps. Left to itself
  it sent every tile the long way round on one transition at three hosts.
  `moveBy()` in `HostCarousel.qml` now states the direction instead.

### A settled value cannot tell you how something got there

**This is the single most expensive mistake on record for this project, and it
has now happened twice under different disguises.**

The carousel wrap was diagnosed by logging `PathView.offset` after each move,
observing it changed by exactly one unit every time, and concluding the carousel
could not be travelling the wrong way round its loop. The client, who had watched
it, said it was. The client was right: the animation really did take the long way
on one transition. **Where something ends up cannot say which way it travelled to
get there**, and the measurement was of where it ended up.

The fix for this class of error is cheap: log the value **every frame** rather
than once it settles. In QML, `onXChanged` on a delegate is enough, and 250 lines
of trace answered in one run what a settled-value measurement had got wrong for a
week. See the same shape in defect 1's history, where an empty log was read as
"the handler never fired".

**If a write-up says something is ruled out, check what measurement ruled it
out** before building on it.

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

### There are two token files, and only one of them changes the app

`app/gui/Bulan.qml` is the live design system — the singleton every screen
imports. Changing a value here changes the application.

`app/gui/BulanTokens.qml` is a **separate copy**, and it feeds `TokenProof.qml`,
the offline review sheet. Changing a value here changes nothing the user ever
sees. It exists because the proof sheet documents provenance per token, which the
runtime singleton has no reason to carry.

**`sizeCaption` lives in both** — as `sizeCaption: 16` in `Bulan.qml`, and as
`size: 16` on the `caption` entry of the type ramp in `BulanTokens.qml`. Change
one and the review sheet shows the client a value the app is not using, which is
the worst possible failure for a document whose entire job is to be reviewed.
Grep both files for any token before changing it.

`atmosphereGrainOpacity` and `motionOvershoot` are only in `Bulan.qml`. The
palette and the type ramp are the parts that are duplicated.

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
| `MOONLIGHT_FAKE_HOSTS=none\|one\|offline\|mixed\|many` | Swaps a fixed host list into the carousel, so its states can be reviewed without pairing or unpairing real machines. `mixed` is three hosts, `many` is five — the count matters, see the PathView note above. |

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

## Deck verification — what has actually been checked

Two sessions on a Steam Deck OLED ("Galileo"), with the client pressing the
buttons. **26 July 2026** covered checks 1-3 in Desktop Mode. **28 July 2026**
covered the regression pass, the judgement calls, and Game Mode.

`REVIEW-CHECKLIST.md` is the working document for these and carries the full
answers. Summary:

### Regression — the fixes held

| Check | Result |
|---|---|
| 1.1 A after a plain Client Settings round trip | **Passed** |
| 1.2 A after opening the Resolution dropdown | **Failed, then fixed** in `be874bf8`, retested by hand, passes |
| 1.3 Wake shown only where it does something | **Passed.** Reflow reads as responsive, not twitchy -- accepted as built |
| 1.4 Glyphs follow the pad in use | **Passed** |
| 1.5 Detection reported at startup | **Passed** -- `detected deck` |

1.2 failing turned out to be a **third** mechanism behind the same one-dead-button
symptom, not a regression of defect 1: a popup elsewhere in the window restores
focus to a control that no longer exists on the way back, landing after the
carousel has already claimed it. The screen now takes focus back whenever it
loses it rather than claiming it once, which cannot be raced.

### Judgement calls — the three global tokens are settled

| Token | Outcome |
|---|---|
| `atmosphereGrainOpacity` | **Stays 0.03.** Judged fine on the panel |
| `sizeCaption` | **Stays 16.** Legible at holding distance, no squinting |
| `motionOvershoot` | **Stays 0.7** |

**Both standing risks in `ROADMAP.md` were wrong, and in the reassuring
direction.** `sizeCaption: 16` was predicted to fail at arm's length by
calculation and does not. Grain at 0.03 was predicted to be invisible on this
panel and is not. **The arithmetic was more pessimistic than the eye** -- worth
remembering before the next value gets argued from a spreadsheet.

Two changes did come out of it, both client calls from observation:

- `motionFocusMs` **140 -> 180**. The brief's figure read a touch too fast.
- The host status line: shorter copy, the status swatches carrying
  reachability, and the redundant dot removed.

Also fixed, and it was a real fault rather than a preference: the tile's scale-up
lagged its travel because an animation was chasing a value that was itself still
animating.

### Game Mode — check 9, passed

**The largest untested assumption in the project, and it held.** Verified 28 July
2026 with `gamescope` confirmed running.

Steam Input does interpose a virtual controller -- the app sees
`Steam Virtual Gamepad` with product `11ff`, not `Steam Deck Controller` with
`1205`. But **the Valve vendor ID `28de` is carried through**, and that is what
detection keys on, so it reports `detected deck` exactly as in Desktop Mode. All
five bindings arrive and fire the right handler.

`BUILDING-DECK.md` records how to capture the log from Game Mode. The short
version: Steam does not run Launch Options through a shell, so use the launcher
script at `/home/deck/Documents/bulan-gamemode.sh`.

### Colour banding — cannot be completed on this hardware

The brief's concern targets the **LCD** Deck and this is an **OLED**; the two
fail differently. Stays open unless an LCD Deck comes into scope. Nothing was
observed on the OLED that needed action.

### Menu battery cost — provisional

**4.31 W** on the carousel against a **3.92 W** baseline with the app closed, so
roughly **0.4 W**, about a tenth. Treat as indicative, not settled: the app
crashed part-way through the sampling window, so some readings are of an idle
machine and the true figure is likely a little higher.

Sampling must be done with the Deck **actually unplugged** -- `current_now` reads
0 whenever mains is connected, which produces a confident-looking 0.00 W. Check
`/sys/class/power_supply/ACAD/online` is 0 first. There is no `bc` on this
machine; use `awk`.

### Can Bulan actually wake a sleeping PC? — yes, answered 28 July 2026

**The last Phase A item, and it passed.** Answered on the Mac, not the Deck, with
the client pressing the button.

`Steambox` was unpaired in Sunshine, re-paired from the carousel, then put
genuinely to sleep. The app logged it going offline, the status line read
*Couldn't reach Steambox*, and the hint bar offered **Y Wake**. One press and it
was back online 64 seconds later.

**Why this counts as a real answer rather than a hopeful one.** `NvComputer::wake()`
has exactly two ways to decline quietly — the host is already online, or no MAC
is stored — and warns for both. Neither warning appears in the log, so it sent the
packet rather than declining. The host was verifiably asleep beforehand: not
responding to the app, and not responding to a direct `serverinfo` query either.

**Consequence:** the *"Asleep"* state is a promise the app can keep and the copy
stands as written. No copy decision is owed.

Two things learned in the process, both recorded under hard-won knowledge: only
`Steambox` is wakeable at all, because `Shoebox` never supplies a hardware
address; and the hint bar offers Wake without checking, which is
`BUGS-open.md` defect 5.

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
