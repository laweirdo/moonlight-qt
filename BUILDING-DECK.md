# Building Bulan on a Steam Deck

How to turn the code in this folder into a real, installable app on a Steam Deck
running SteamOS, and how to run it.

You don't need to understand any of the code. Every command here can be copied
and pasted exactly as written.

Verified on 28 July 2026 against `bulan`, on a Steam Deck OLED, in both Desktop
Mode and Game Mode.

**These commands run on the Deck itself.** Earlier planning assumed a design
machine driving the Deck over SSH. That is not how the July 2026 sessions
worked, and no SSH setup exists on either machine: the assistant runs on the
Deck, builds there, and reads the log there — including from Game Mode, which
has no terminal of its own. If a future session does want SSH, know that SteamOS
ships it switched off with no password on the `deck` account, so enabling it
means setting a password and starting a service, and a SteamOS update can switch
it back off again.

---

## Not building? Take the AppImage

If you only want to run Bulan on the Deck rather than work on it, you do not
need any of this. Every push builds one:

1. Open the repository's **Actions** tab and pick the newest green `Build` run.
2. Download the **`Bulan-LinuxAppImage-…`** artifact. GitHub serves artifacts as
   a zip, so unzip it to get the `.AppImage` inside.
3. On the Deck, in Desktop Mode:

```bash
chmod +x Bulan-*.AppImage
./Bulan-*.AppImage
```

The Flatpak below is still the route this project validates on hardware, and the
one every Deck session so far has used — the AppImage is a convenience, not a
replacement, and it has not been through the review checklist.

Its filename carries the commit it was built from rather than Bulan's release
number, because CI stamps artifacts with the short SHA.

---

## The one command you need

This builds your code, installs it, and launches it. Run it after every change:

```bash
cd /home/deck/Documents/moonlight-flatpak-recipe && flatpak run --filesystem=home --env=FLATPAK_USER_DIR=/home/deck/.local/share/flatpak --command=flatpak-builder org.flatpak.Builder --state-dir=/home/deck/Documents/.flatpak-builder-cache --repo=/home/deck/Documents/.moonlight-repo --force-clean --disable-updates /home/deck/Documents/.build-fork io.github.laweirdo.MoonlightFork.json && flatpak install --user -y --reinstall moonlight-fork-local io.github.laweirdo.MoonlightFork && flatpak run io.github.laweirdo.MoonlightFork
```

It's long, but it's three steps joined by `&&` (meaning "and if that worked,
do the next thing"):

1. **Build** your code into an app package.
2. **Install** that package for your user account.
3. **Run** it.

If you only want to run the app without rebuilding:

```bash
flatpak run io.github.laweirdo.MoonlightFork
```

---

## Which folder gets built — read this before your first build

The recipe does **not** build "whatever branch you have open". It builds one
specific folder path, written inside the recipe file:

```
"path": "/home/deck/Documents/moonlight-qt"
```

That is the main checkout. If that folder is sitting on a different branch than
the one you meant to test, **the build will quietly succeed and give you the
wrong app.** There is no warning. This is the single easiest way to waste an
hour on this project.

Before building, confirm what that folder is on:

```bash
git -C /home/deck/Documents/moonlight-qt branch --show-current
```

If it isn't the branch you want, either check that branch out there, or point a
copy of the recipe at a different folder — see below.

### Building a git worktree instead

If the branch you want is checked out in a worktree rather than the main folder,
copy the recipe and change the path:

```bash
cd /home/deck/Documents/moonlight-flatpak-recipe && python3 -c "
import json
d = json.load(open('io.github.laweirdo.MoonlightFork.json'))
for m in d['modules']:
    if m['name'] == 'moonlight':
        for s in m['sources']:
            if s.get('type') == 'dir':
                s['path'] = '/PUT/YOUR/FOLDER/HERE'
json.dump(d, open('io.github.laweirdo.MoonlightFork.worktree.json', 'w'), indent=4)
"
```

Then use `io.github.laweirdo.MoonlightFork.worktree.json` in the build command
instead of `io.github.laweirdo.MoonlightFork.json`.

**Keep the app ID the same.** The build cache is keyed partly on app ID, so
changing it forces all nine modules to rebuild from scratch. Changing only the
source path still lets the eight cached libraries be skipped.

---

## After pulling new code

Submodules are not automatic, and **a fresh worktree has none of them**. The
build fails without them. In the folder you are about to build:

```bash
git submodule update --init --recursive
```

There are **three** — `moonlight-common-c`, `qmdnsengine` and
`app/SDL_GameControllerDB` — and `moonlight-common-c` has two of its own nested
inside it (`enet` and `nanors`), which is why `--recursive` matters. Five in
total. `git submodule status --recursive` should list all five with no leading
`-` or `+`.

There used to be a fourth. The July 2026 upstream sync replaced the
`h264bitstream` submodule with source committed directly into the repository,
and that leaves an **untracked leftover directory** behind from the old
submodule checkout:

```bash
rm -rf h264bitstream/h264bitstream
```

It is safe to delete — the code that matters is now tracked in
`h264bitstream/` itself, one level up. You will notice it because `git checkout`
prints `warning: unable to rmdir 'h264bitstream/h264bitstream': Directory not
empty`.

You do **not** need to re-run the asset scripts. `scripts/import-controller-glyphs.py`
and `scripts/gen-atmosphere-textures.py` write their output into `app/res/`, and
that output is **committed to the repository** — 60 glyph SVGs (30 glyphs × 2
tones) plus the two atmosphere PNGs. Pulling gets you the generated files
already. The scripts only need re-running when new source art is delivered, and
the source art lives on the design machine, not here.

---

## How long it takes

All measured on a Steam Deck OLED.

| | Time |
|---|---|
| First build ever (compiles 9 things from scratch) | **about 6 minutes** |
| Rebuild after you change some code | **under 2 minutes** |
| The install step on its own | **under 2 seconds** |

The first build compiles nine things: eight supporting libraries (ffmpeg, SDL,
libplacebo, dav1d and others) plus Moonlight itself. Afterwards those eight are
cached and skipped, so only Moonlight recompiles. You'll see this in the output:

```
Cache hit for libplacebo, skipping build
Cache hit for ffmpeg, skipping build
...
Building module moonlight
```

Note that *any* change inside the source folder triggers a Moonlight rebuild —
including editing this very file. That's normal.

---

## Reviewing screens without pressing buttons

The three review hooks below work inside the Flatpak, but they need one extra
flag.

```bash
flatpak run --filesystem=home \
  --env=QT_QPA_PLATFORM=offscreen \
  --env=MOONLIGHT_FAKE_HOSTS=mixed \
  --env=MOONLIGHT_SCREENSHOT=/home/deck/Documents/shot.png \
  io.github.laweirdo.MoonlightFork
```

**`--filesystem=home` is required.** The recipe's `finish-args` grant no access
to your home folder, so without it the app runs, renders, and then silently
fails to write the file. There is no error message — you just get no screenshot.
This is the flag people forget.

| Hook | Effect |
|---|---|
| `MOONLIGHT_SCREENSHOT=<path>` | Pins the window to 1280×800, grabs it, exits. Also writes `<path>-toolbar.png`. |
| `MOONLIGHT_INITIAL_VIEW=qrc:/gui/X.qml` | Boots straight to a screen. `GlyphProof.qml` and `TokenProof.qml` are the review sheets. |
| `MOONLIGHT_FAKE_HOSTS=none\|one\|two\|offline\|mixed\|many` | Swaps a fixed host list into the carousel. |

Two things about this that look like bugs and aren't:

- **`MOONLIGHT_FAKE_HOSTS` does not stop real host discovery.** It only swaps the
  carousel's model. You will still see `"Shoebox" is now online` in the log while
  the screen shows the fake hosts. That is correct behaviour.
- **`SDL_InitSubSystem(SDL_INIT_VIDEO) failed: No available video device`** is
  expected under `QT_QPA_PLATFORM=offscreen` and does not stop the screenshot.

Offscreen mode cannot render shader effects, which is why glyph colour is baked
in at import time rather than tinted at runtime. The durable review-model notes
are in `SPEC-host-carousel.md`.

---

## What you end up with

An app called **"Moonlight (Fork)"**, installed for your user account only.

- It appears in your application launcher in Desktop Mode.
- The official Moonlight from the Steam store is **untouched**. Both are installed
  at once, so you always have a known-good version to compare against.
- Hardware video decoding works — verified: VA-API 1.22 on the Deck's
  `AMD Custom GPU 0932` (`vangogh`) chip.
- Nothing is installed into system folders. The SteamOS read-only filesystem
  stays read-only, so **a SteamOS update will not wipe this.**

Everything lives under `/home`:

| What | Where | Size |
|---|---|---|
| Your source code | `/home/deck/Documents/moonlight-qt` | 373 MB |
| The build recipe | `/home/deck/Documents/moonlight-flatpak-recipe` | small |
| Build cache | `/home/deck/Documents/.flatpak-builder-cache` | 396 MB |
| Built packages | `/home/deck/Documents/.moonlight-repo` | 55 MB |
| Scratch build folder | `/home/deck/Documents/.build-fork` | 99 MB |
| Build tools + installed app | `/home/deck/.local/share/flatpak` | 5.1 GB |

---

## Why it's built this way

SteamOS keeps its system folders read-only on purpose and wipes changes to them
on every update. The normal Linux instructions in `README.md` say to install
development packages system-wide — on SteamOS that means switching off the
read-only protection and losing the work at the next update.

So instead we build a **Flatpak** — a self-contained app bundle. The build tool
is itself a Flatpak, so there's no compiler installed on the system at all.
Tools, libraries, cache and finished app all sit in `/home`, which SteamOS never
touches.

The recipe is Flathub's official Moonlight recipe with five changes. If the
recipe folder is ever missing, recreate it by cloning
`https://github.com/flathub/com.moonlight_stream.Moonlight.git` and reapplying
these (confirmed working, 8 August 2026):

1. **A different app ID** (`io.github.laweirdo.MoonlightFork` rather than
   `com.moonlight_stream.Moonlight`), so it installs alongside the official app
   instead of replacing it.
2. **Two rename instructions**, `rename-desktop-file` and
   `rename-appdata-file`, both set to `com.moonlight_stream.Moonlight`'s
   original filenames — because the app ID appears inside those filenames.
   Without them the app builds but never appears in your launcher.
3. **`rename-icon` must match the source's actual installed icon filename**,
   not the upstream default of `moonlight`. `app/app.pro` installs the app
   icon as `com.moonlight_stream.Moonlight.svg` (see the comment there), so
   `rename-icon` needs the same value — `moonlight` fails the build with
   `Error: icon moonlight not found`. If a future icon-install change renames
   that file, update this to match.
4. **The source points at your local folder** instead of GitHub — see above.
5. **Stale patches removed.** Flathub's recipe carries Qt 6.9 and FFmpeg 7.x
   compatibility patches on top of Moonlight v6.1.0. As of 8 August 2026 this
   was five patches (three Qt, two FFmpeg/Vulkan), and this code already
   contained all five fixes, so all five failed to apply and had to go. Confirm
   each patch's fix is actually present in source (grep for a symbol/line the
   patch touches) before deleting its `sources` entry — see "A patch fails to
   apply" below. The count may change as Flathub's recipe or this fork's
   source evolves; don't assume it stays at five.

### It builds from your folder, not from GitHub

**Upside:** edit a file, run the command, your change is in the app. No commit,
no push, no internet needed.

**Downside:** the result depends on whatever is in that folder right now. Someone
running the same recipe elsewhere wouldn't necessarily get the same app. Good
trade for developing on the device, but the recipe alone isn't a full record of
what you built.

---

## Adding it to Steam / Game Mode

In Desktop Mode, open Steam and go **Games → Add a Non-Steam Game to My Library
→ Browse**. Add any placeholder, then right-click it in your library →
**Properties**, and set:

- **Target:** `/usr/bin/flatpak`
- **Launch Options:** `run io.github.laweirdo.MoonlightFork`

It will then launch from Game Mode.

### Reading the log from Game Mode

Game Mode has no terminal, so the app's output has to be captured to a file.

**Do not put a shell pipe in Launch Options.** Steam does not run Launch Options
through a shell, so `2>&1 | tee somewhere.log` is passed to the app as arguments
and silently produces no log at all. Use a launcher script instead —
`/home/deck/Documents/bulan-gamemode.sh` already exists and does this:

```bash
#!/bin/bash
exec flatpak run io.github.laweirdo.MoonlightFork \
  > /home/deck/Documents/bulan-gamemode.log 2>&1
```

Point the shortcut's **Target** at that script and leave **Launch Options
empty**. In Steam's file picker, switch the filter to **All Files** or the
script will not be listed.

The log can then be read live from Desktop Mode, or by an assistant running on
the Deck, while Game Mode is in use.

### What Steam Input does to the controller

In Game Mode, Steam Input sits between the hardware and the app and presents a
**virtual** controller. Verified 28 July 2026:

| | Desktop Mode | Game Mode |
|---|---|---|
| Name | `Steam Deck Controller` | `Steam Virtual Gamepad` |
| Product | `1205` | `11ff` |
| Vendor | `28de` | `28de` |

The name and product both change; **the Valve vendor ID does not**, and that is
what glyph detection keys on. So detection reports `detected deck` in both modes,
and all five button bindings arrive intact in both. This was the project's
largest untested assumption and it held.

Check `gamescope` is running if you need to be certain you are really in Game
Mode: `pgrep -c gamescope`.

---

## When things go wrong

### The app looks like the old version after a successful build

**This has three causes and they stack. On 28 July 2026 all three were in play at
once and it cost most of a session.** Work down the list in order.

**1. An old copy is still running.** `flatpak run` on an already-running instance
raises the existing window instead of starting the new build, so you can be
looking at a process from three builds ago. Same trap as `open -n` on macOS.

```bash
flatpak ps | grep -c MoonlightFork     # must be 0 before you launch, 1 after
```

To stop them — do **not** use `pkill -f` with the app ID, it matches its own
command line and kills your shell:

```bash
flatpak kill io.github.laweirdo.MoonlightFork
```

**2. The interface is being served from a stale cache.** The app caches its
compiled interface on disk, and that cache can outlive many rebuilds. Files
dated days ago while the build is minutes old is the tell.

```bash
rm -rf ~/.var/app/io.github.laweirdo.MoonlightFork/cache/Moonlight\ Game\ Streaming\ Project/Moonlight/qmlcache
```

Relaunch and confirm the directory reappears with today's date.

**3. You built the wrong folder.** See "Which folder gets built" above.

### Confirming what is actually in the installed app

**Do not grep the binary for QML identifiers.** Interface code is not stored as
plain text in there, so the grep returns zero for code that has been in the file
for weeks — it looks like proof of a stale build and is not. This produced two
wrong conclusions in one session.

**Read the log instead. It says so in plain language.** A screen that fails to
load prints exactly what failed and why:

```
QML StackView: push: qrc:/gui/HostCarousel.qml:473 Type HostTile unavailable
qrc:/gui/HostTile.qml:83 Invalid property assignment: "interactionScale" is a read-only property
```

If a Bulan screen fails to load, the app **falls back to upstream's interface** —
the old grid, no hosts. That looks like "the build didn't take" and is actually
"the build took and the screen is broken". Check the log before concluding
anything about the build.

### "org.kde.Sdk/x86_64/6.10 not installed" — but it *is* installed

The most confusing error you'll hit, and not your fault.

The build tool runs inside its own sandbox and doesn't automatically find things
installed for your user account, even though they're right there. It reports them
as missing.

**The fix is the `--env=FLATPAK_USER_DIR=/home/deck/.local/share/flatpak` part of
the build command.** Don't remove it. If you retype the command from memory and
hit this error, that's the missing piece.

### Clicking the launcher icon does nothing

This happens if you build with `--install` instead of `--repo` + a separate
install step.

With `--install`, the sandboxed build tool installs the app *itself*, and writes
its own internal path into the launcher shortcut:

```
Exec=/app/bin/flatpak run ...      <-- broken, /app only exists inside the sandbox
```

The command at the top of this document avoids that by building to
`/home/deck/Documents/.moonlight-repo` and then installing with your system's own
flatpak, which writes the correct path:

```
Exec=/usr/bin/flatpak run ...      <-- correct
```

To check yours is right:

```bash
grep Exec= /home/deck/.local/share/flatpak/exports/share/applications/io.github.laweirdo.MoonlightFork.desktop
```

### "The state dir is not on the same filesystem as the target dir"

The build cache and the build folder must be on the same drive. Both paths in the
command are under `/home/deck/Documents`, which satisfies this. Moving one to
`/tmp` causes this error.

### A patch fails to apply

If you pull newer code and the build stops with a patch error, that patch is
probably fixing something already fixed in your code. Confirm the fix is present,
then delete that patch's entry from the recipe's `sources` list. That's exactly
why the three Qt 6.9 patches were removed here.

### The app doesn't appear in the launcher at all

The launcher reads a `.desktop` file whose name must match the app ID — that's
what the two rename instructions handle. If you change the app ID, you must also
update the `post-install` commands in the recipe, which rewrite the ID *inside*
those files.

### Messages you can safely ignore

These appear in both this build and the official one:

- `QML ApplicationWindow: ToolTip attached property must be attached to an object deriving from Item`
- `Detected locale "C" ... Qt depends on a UTF-8 locale`
- `Shortcut: Only binding to one of multiple key bindings`

Running from a terminal with no graphical session also gives
`_amdgpu_device_initialize: amdgpu_query_info(ACCEL_WORKING) failed (-13)`. That
just means the desktop session already owns the graphics chip. Launch from the
launcher, or a terminal inside Desktop Mode, and it goes away.

---

## Removing it

Uninstall the fork, leaving official Moonlight untouched:

```bash
flatpak uninstall --user io.github.laweirdo.MoonlightFork
```

Also reclaim the build tools and caches (about 5.5 GB), meaning the next build
starts from scratch:

```bash
flatpak uninstall --user org.flatpak.Builder org.kde.Sdk && rm -rf /home/deck/Documents/.flatpak-builder-cache /home/deck/Documents/.build-fork /home/deck/Documents/.moonlight-repo
```

---

## One-time setup, for reference

Already done on this Deck. You only need this on a fresh machine, or after
removing the build tools above.

**1. Install the build tools** (~1.4 GB download, ~3.4 GB on disk). The `--user`
flag is what keeps everything inside `/home`:

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && flatpak install --user -y flathub org.flatpak.Builder org.kde.Sdk//6.10
```

**2. Get your code**, with submodules — the `--recurse-submodules` part is
required, the build fails without them:

```bash
git clone --recurse-submodules https://github.com/laweirdo/bulan-qt.git /home/deck/Documents/moonlight-qt
```

The local folder name stays `moonlight-qt` on purpose: the recipe and every path
in this document point at it, and renaming the folder would mean rewriting all of
them for nothing. GitHub still redirects the old `moonlight-qt` repository URL,
so an existing checkout keeps working without being re-pointed.

`master` is Bulan's default branch. The clone lands on it, which is the branch
this recipe expects unless you deliberately check out another.

**3. Get the recipe folder** (Flathub's published recipe, which you then modify
with the four changes described above):

```bash
git clone https://github.com/flathub/com.moonlight_stream.Moonlight.git /home/deck/Documents/moonlight-flatpak-recipe
```

**4. Register the local package repository** that the build writes into. Without
this, the install step can't find your built app:

```bash
flatpak remote-add --user --if-not-exists --no-gpg-verify moonlight-fork-local /home/deck/Documents/.moonlight-repo
```
