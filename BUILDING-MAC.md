# Building Moonlight on this Mac

This is a personal setup note, not official project documentation. It records exactly
how this machine was set up to build Moonlight from source, so the setup can be
repeated or repaired later. Written to be followed without any coding knowledge.

Verified working on **25 July 2026**, building commit `17d5b1a8` (Moonlight version 6.1.0).

---

## The one command

To rebuild the app after any change and launch it, copy this whole line into Terminal
and press Return:

```bash
cd ~/Developer/moonlight-qt && make -j$(sysctl -n hw.ncpu) release && open -n app/Moonlight.app
```

In plain English, this does three things in order, and stops if any of them fails:

1. `cd ~/Developer/moonlight-qt` — moves into the project folder.
2. `make -j... release` — rebuilds only the parts that actually changed, using all
   10 of this Mac's processor cores at once. If nothing changed, this finishes in
   under a second.
3. `open -n app/Moonlight.app` — starts the app you just built.

The `-n` matters. Without it, macOS will just bring an already-open Moonlight window
to the front instead of starting your new build, and you would be looking at the old
version without realising it.

**This launches your build, not the official one.** There is a separate, official
Moonlight installed in your Applications folder. The two are unrelated and can run at
the same time. If you ever need to tell them apart, the command above always runs the
one from `~/Developer/moonlight-qt`.

---

## The machine this was set up on

| | |
|---|---|
| Computer | MacBook Pro 14", Apple M1 Pro, 10 cores |
| Processor type | `arm64` (Apple Silicon) |
| macOS | 26.5.2 (build 25F84) |

---

## What was already installed

None of these were installed during setup. They were already present and working.

| Software | Version | Where it lives | What it is |
|---|---|---|---|
| Homebrew | 6.0.12 | `/opt/homebrew` | The installer that manages the other tools |
| Qt | 6.11.1 | `/opt/homebrew` | The toolkit Moonlight's windows and menus are built with |
| Apple Command Line Tools | 26.5.0 | `/Library/Developer/CommandLineTools` | Apple's compiler; turns source code into a runnable app |
| Apple clang | 21.0.0 | (part of the above) | The compiler itself |
| Python | 3.9.6 | `/usr/bin/python3` | Apple's built-in Python; runs the dependency downloader |

Two things here are worth understanding, because they are the most likely causes of
future trouble:

**Homebrew is in the right place.** It is installed at `/opt/homebrew`, which is the
correct location for Apple Silicon Macs. The other possible location, `/usr/local`, is
for older Intel Macs. Had it been installed there, Qt would have been built for the
wrong processor type and the build would have failed in a confusing way. It isn't, so
this is fine.

**Full Xcode was never needed.** The project's own README asks for Xcode 14 or later,
which is a 10+ GB download. This machine only has the much smaller Command Line Tools,
and the build worked anyway. Keep this in mind: if a future build fails with a strange
compiler error, installing full Xcode is a reasonable thing to try, but don't install
it pre-emptively.

---

## What was actually installed during setup

Only two things.

### 1. Moonlight's prebuilt dependencies (96 MB)

These are ready-made pieces of software Moonlight relies on — video decoding, audio,
encryption, and game controller support. They were downloaded by running the
project's own script:

```bash
python3 setup-deps.py
```

They live in `libs/mac/` and are copied into the finished app. They are not tracked by
Git, so they will not appear in any list of your changes.

### 2. GitHub CLI 2.96.0 — installed, but not needed

```bash
brew install gh
```

This was installed early in setup, before it became clear the fork and clone already
existed. **It ended up serving no purpose and is not used by the build.** It is also
not signed in to your GitHub account.

You can safely ignore it. If you ever want to use it for GitHub work from the Terminal,
it will first need `gh auth login` run from a normal interactive Terminal window. If
you would rather remove it entirely:

```bash
brew uninstall gh
```

---

## After downloading updates from GitHub

Whenever you pull new code, the dependencies must be refreshed too. The project's
README is explicit about this. Run this **once** after pulling, then go back to using
the one command at the top of this file:

```bash
cd ~/Developer/moonlight-qt && git submodule update --init --recursive && python3 setup-deps.py
```

---

## If you need to start over completely

This throws away everything built so far and rebuilds from scratch. It takes several
minutes rather than seconds. Only reach for this if normal rebuilds are failing in
ways you can't explain:

```bash
cd ~/Developer/moonlight-qt && make clean && qmake6 moonlight-qt.pro && make -j$(sysctl -n hw.ncpu) release
```

`qmake6` is the step that regenerates the build instructions. It only needs to be run
after a fresh checkout, after changing project settings, or as part of a clean rebuild
like this one — which is why it is deliberately absent from the everyday command.

---

## Things that look like problems but aren't

**"1 file changed" in `app/Info.plist`, and a stray `app/Info.plist-e` file.**
The build stamps the version number directly into this file as it runs, and leaves a
backup copy behind ([`app/app.pro`](app/app.pro), near the macOS bundle
generation block). Both are normal side effects of building.
Don't try to undo them.

**Warnings about `Info.plist` during the build.** Lines reading
`warning: overriding commands for target` come from the project's own build files and
appear on every build, including clean ones.

**Warnings mentioning `ToolTip` or `Shortcut` when the app starts.** These come from
Moonlight's own interface code and appear in the official release too.

**`Checking for SL... no` and `Checking for EGL... no` during `qmake6`.** These are
checks for Steam Link and Linux graphics support. They correctly report "no" on a Mac.

**A "damaged app" or unidentified-developer warning from macOS.** Your build isn't
signed by Apple. Right-click the app and choose Open, rather than double-clicking.

---

## How to tell the build genuinely worked

The app writes a log file each time it starts. To read the most recent one:

```bash
cat "$(ls -t /tmp/Moonlight-*.log | head -1)"
```

On a healthy launch it contains lines like these:

```
SDL Info (0): Selected Metal device: Apple M1 Pro
SDL Info (0): Using Metal renderer with hardware decoding
Qt Debug: Current Moonlight version: "6.1.0"
```

The first two confirm the app found the real graphics hardware and is using the M1
Pro's built-in video decoding rather than a slow software fallback. That is the
meaningful proof that the environment is correct — not merely that a window appeared.

---

## Where the code came from

| | |
|---|---|
| `origin` | `https://github.com/laweirdo/moonlight-qt.git` — Bulan, where your work goes |
| `upstream` | `https://github.com/moonlight-stream/moonlight-qt.git` — Moonlight, where updates come from |

`master` is Bulan's default branch; cut task branches from it. Upstream is
tracked through the `upstream` remote, not by keeping a Bulan branch pristine.

**The repository is being renamed to `Bulan`.** Once that happens the URL above
becomes `https://github.com/laweirdo/Bulan.git`. GitHub redirects the old URL,
so an existing clone and remote keep working either way.

---

## One thing to watch out for

Homebrew upgrades Qt automatically when you run `brew upgrade`. If a future Qt version
ever breaks the build, you can see which version you're on with:

```bash
qmake6 -query QT_VERSION
```

Anything from Qt 6.7 upward is supported by the project. This setup was verified on
6.11.1.
