# Building Bulan on Windows

Written 28 July 2026, on the client's desktop PC — which is **`Shoebox`**, one of
the two real hosts this project streams from.

**Windows is not a target.** `ROADMAP.md` says so plainly: the Steam Deck is the
product. This machine exists as a **review station** — somewhere to build, look at
a screen, and prove a change works without needing the Mac or the Deck. Nothing
here should be read as Windows becoming a supported platform.

What it is good for: does the screen load, do the tiles move correctly, does the
count read right, does the mouse behave. What it is **not** good for: grain,
caption size, motion feel in the hand, or anything else that depends on a 7-inch
panel at 204 ppi. Those stay Deck questions and saying otherwise wastes a Deck
session.

---

## What is installed

| Piece | Version | Where |
|---|---|---|
| Visual Studio Build Tools 2022 | 17.14.37, MSVC 14.44 | `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools` |
| Windows SDK | 10.0.26100 | `C:\Program Files (x86)\Windows Kits\10` |
| Qt | **6.9.3** msvc2022_64 | `C:\Users\faris\Qt\6.9.3\msvc2022_64` |
| Python | 3.14.6, via scoop | `C:\Users\faris\scoop\apps\python\current` |
| Prebuilt deps | `v10` | `libs\windows`, via `setup-deps.ps1` |

---

## Build and look

Three steps. The first two are one-time after a fresh checkout.

```
git submodule update --init --recursive
powershell .\setup-deps.ps1
```

Then configure and compile. **The project's own `scripts\build-arch.bat` is the
wrong tool here** — it builds an MSI with WiX, signs binaries and packs a
portable zip, none of which a review station needs and all of which will fail.
Call `qmake` and `jom` directly instead:

```
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
set PATH=C:\Users\faris\Qt\6.9.3\msvc2022_64\bin;%PATH%
mkdir build\build-x64-release
cd build\build-x64-release
qmake ..\..\moonlight-qt.pro
..\..\scripts\jom.exe release
```

The binary lands at `build\build-x64-release\app\release\Moonlight.exe` and
**will not run from there** — it needs the Qt runtime and the prebuilt DLLs
beside it. Deploy once:

```
copy build\build-x64-release\app\release\Moonlight.exe build\deploy-x64-release\
copy libs\windows\lib\x64\*.dll build\deploy-x64-release\
copy build\build-x64-release\AntiHooking\release\AntiHooking.dll build\deploy-x64-release\
copy app\SDL_GameControllerDB\gamecontrollerdb.txt build\deploy-x64-release\
windeployqt --dir build\deploy-x64-release --release --qmldir app\gui --no-opengl-sw --no-compiler-runtime --no-sql build\deploy-x64-release\Moonlight.exe
```

After that, rebuilding is `jom release` plus copying the one exe over. The Qt
runtime does not need redeploying unless Qt itself changes.

Screens are captured the same way as on the Mac:

```
set MOONLIGHT_FAKE_HOSTS=two
set MOONLIGHT_SCREENSHOT=C:\Users\faris\AppData\Local\Temp\shot.png
build\deploy-x64-release\Moonlight.exe
```

---

## A portable package to hand someone

`scripts\build-arch.bat` is still the wrong tool: it wants WiX and a signing
certificate. A portable build is the deploy above, into a **fresh** folder, plus
two things it does not include.

```
rmdir /s /q build\Bulan-0.0.1-portable-x64
mkdir build\Bulan-0.0.1-portable-x64
copy build\build-x64-release\app\release\Moonlight.exe build\Bulan-0.0.1-portable-x64\
copy build\build-x64-release\AntiHooking\release\AntiHooking.dll build\Bulan-0.0.1-portable-x64\
copy libs\windows\lib\x64\*.dll build\Bulan-0.0.1-portable-x64\
copy app\SDL_GameControllerDB\gamecontrollerdb.txt build\Bulan-0.0.1-portable-x64\
copy "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC\14.44.35112\x64\Microsoft.VC143.CRT\*.dll" build\Bulan-0.0.1-portable-x64\
windeployqt --dir build\Bulan-0.0.1-portable-x64 --release --qmldir app\gui --no-opengl-sw --no-compiler-runtime --no-sql build\Bulan-0.0.1-portable-x64\Moonlight.exe
type nul > build\Bulan-0.0.1-portable-x64\portable.dat
```

The two additions are the **VC runtime DLLs**, which the deploy step above
deliberately omits with `--no-compiler-runtime` because a dev machine already
has them, and **`portable.dat`**, which `main.cpp` looks for to keep settings in
an INI beside the exe instead of under the user profile.

Three things to get right, all of which bit on 9 August 2026:

- **Build into a fresh folder, not `deploy-x64-release`.** That folder is
  long-lived and accumulates: it still held a `BulanReview.exe` from 31 July,
  untracked and referenced nowhere, which would have shipped to a client.
- **Run it once, then delete what it wrote.** A portable run creates
  `Moonlight Game Streaming Project\Moonlight.ini` beside the exe containing a
  freshly generated client certificate, its **private key**, and any hosts
  discovery found. Never zip that.
- **Do not use `Compress-Archive`.** It writes `\` as the entry separator, which
  the ZIP spec forbids; anything unpacking it on Linux gets single files named
  `platforms\qwindows.dll`. `System.IO.Compression.ZipArchive` with the
  separator replaced by hand is the fix on PowerShell 5.1, whose
  `ZipFile.CreateFromDirectory` has the same defect.

---

## Traps, all of which cost time on 28 July

### Qt 6.11 and later cannot be installed with `aqtinstall`

`aqtinstall` 3.3.0 — the newest release — asks for
`.../qt6_6111/qt6_6111/Updates.xml`, but Qt reorganised the repository at 6.11
and the file now lives at `.../qt6_6111/qt6_6111_msvc2022_64/Updates.xml`. The
error it prints is a **checksum** failure, which reads like a network problem and
is not one: the folder simply does not exist. 6.9.3 and 6.10.x use the old layout
and install fine.

**This machine therefore runs Qt 6.9.3 while CI and the Mac run 6.11.1.** For
QML review that gap has not mattered, but it is the first thing to suspect if
this machine ever disagrees with the Mac about how something looks.

### The offscreen platform is not deployed, and is not wanted here

`windeployqt` ships only the `windows` platform plugin, so
`QT_QPA_PLATFORM=offscreen` fails outright with *"no Qt platform plugin could be
initialized"*.

Do not fix this. **Run windowed.** This machine has a real GPU and a real display,
so the window renders properly — including shader effects, which the Mac's
offscreen path cannot do at all. The screenshot hook pins the window to 1280×800,
grabs it and exits, so a window appears for a few seconds and closes.

Screenshots come out at **2240×1400**, not 1280×800, because the display is
scaled. That is more detail, not a layout difference.

### The log goes to stderr, and redirecting only stdout gets you nothing

`Moonlight.exe` is built as a GUI subsystem binary and writes its log to
**stderr**. Capturing stdout alone produces an empty file — which looks exactly
like proof that nothing ran.

This nearly caused a wrong conclusion on 28 July: a frame-by-frame trace came back
with zero lines and read as "the tiles never moved". They had. Only the stream was
wrong.

```
Start-Process ... -RedirectStandardOutput out.txt -RedirectStandardError err.txt
```

**Prove your logging appears before drawing any inference from its absence.** That
rule now has three separate confirmations on this project, on three platforms.

### The build stamp does not work here

`app.pro` generates `buildstamp.h` inside a `unix { }` block, because it is a
shell script and the two platforms this fork targets are both unix. On Windows the
log's second line reads:

```
Build: unknown | binary built "2026-07-28T20:39:13"
```

The commit is absent. **The timestamp still works and is the thing to check** —
compare it against the time you built. Do not extend the stamp to Windows unless
Windows becomes a real target; it is a review station, and the binary is never
more than a few minutes old.

### Do not edit source files with PowerShell's `Get-Content` / `Set-Content`

**This corrupted two files on 28 July and the damage reached a commit.**

PowerShell 5.1 reads files without a BOM as ANSI, so a UTF-8 `§` or `…` comes
back as two or three separate characters. Writing that out as UTF-8 double-encodes
it: `§` becomes `Â§`, `…` becomes `â€¦`. It also adds a BOM the repository does
not use.

The visible symptom is garbage in on-screen copy — *"Connectingâ€¦"* — which
nobody notices until it ships, because the corrupted strings are in states that
are hard to reach.

Use an editor that preserves encoding. If a file must be rewritten from a script,
read and write it through .NET with an explicit encoding and no BOM:

```powershell
$enc = New-Object System.Text.UTF8Encoding($false)
$t = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($path, $t, $enc)
```

Check any file a script has touched:

```powershell
([regex]::Matches($text, "Â|â€|Ã")).Count   # must be 0
```

### Passing commit messages through PowerShell

`git commit -m` with a here-string breaks apart if the message contains a double
quote — PowerShell re-splits the argument and git reads the fragments as
pathspecs. Write the message to a file and use `git commit -F`.

### Chaining `vcvarsall.bat && set PATH=... && jom` on one line throws away the compiler it just added

An earlier handoff recorded that the Windows shell "could not find the MSVC
tools through the generated makefiles," and that the generated build-tree
makefiles under `build\build-x64-release` were patched locally with absolute
MSVC tool paths plus `/MANIFEST:NO` as a review-build workaround. **That
diagnosis was wrong, and the workaround was unnecessary.** Verified 31 July
2026: with the fix below, a full clean-ish `jom release` succeeded against the
documented build recipe completely unmodified, the manifest embedded normally,
and the only link warning was the pre-existing `LNK4291`.

The real cause is cmd's expansion order. Chaining the three build steps on one
command line —

```
call vcvarsall.bat x64 && set PATH=C:\Users\faris\Qt\6.9.3\msvc2022_64\bin;%PATH% && jom
```

— has cmd substitute `%PATH%` **at parse time, before `vcvarsall.bat` has run**,
because the whole line is tokenized once before any of it executes. The `PATH`
that gets prepended to is the shell's PATH from before `vcvarsall`, and the
MSVC tool directories `vcvarsall` adds a moment later are simply not there yet
when that substitution happens — they are added to the *live* environment
variable, not rewritten back into the command line that already captured
`%PATH%`'s old value. The net effect is that `cl` is missing from `PATH` for
the rest of the chain, and `jom` fails to find the compiler.

**Why the wrong diagnosis was believable.** The failure mode — `cl` not found,
right after a `vcvarsall.bat` call that is supposed to put it there — looks
exactly like the tools not being registered with the generated makefiles at
all, especially once qmake has already written absolute paths for some other
tools into those makefiles. Patching the makefiles with more absolute paths
"fixed" it in the sense that the build then succeeded, which is what made the
workaround look like the real fix rather than a way of stepping around the
actual, unexamined cause.

**The fix:** put the three build commands in a `.bat` file rather than
chaining them on one interactive line. cmd parses and executes a script line by
line, so by the time the `set PATH=...` line runs, `vcvarsall.bat`'s own line
has already executed and already modified the live environment — the `%PATH%`
expansion on the next line sees the updated value. No makefile patching and no
`/MANIFEST:NO` are needed; the documented recipe (`qmake` then `jom.exe
release`) works unmodified once each step is its own parsed-and-executed line
instead of one pre-tokenized chain.

### Installing the toolchain needs an administrator

The Build Tools installer refuses a `--quiet` or `--passive` run that did not
start elevated, and fails with exit code 5007. It must be launched from a
PowerShell opened with **Run as administrator**.

Note also that a partially failed install **reports success**: on 28 July the
compiler installed and the Windows SDK download was cancelled mid-transfer, and
the installer exited 0. Check for the SDK directly rather than trusting the exit
code:

```powershell
Test-Path "C:\Program Files (x86)\Windows Kits\10\Include"
```
