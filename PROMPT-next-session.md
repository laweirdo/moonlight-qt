# Next session — the host settings menu

Written 28 July 2026, at the end of the Windows session that rebuilt the carousel.

**Read `HANDOFF.md` first**, and in it *Hard-won knowledge* before anything else.
Then `BUGS-open.md` — one open defect and one fix nobody has watched — and
`SPEC-host-carousel.md`, which describes the screen you are about to add to.

**Branch state:** `feat/carousel-engine` carries four commits and is **not
merged**. Merge it on the client's sign-off, delete it locally and on the fork,
and cut a new branch from `bulan` before starting anything below.

**This does not need a Steam Deck.** Everything here is reviewable on the Windows
machine or the Mac with the fake host presets.

---

## Why this session exists

`ROADMAP.md` Phase B closes the core loop, and the client confirmed the order:
the host settings menu is first. It is also the only **functional loss against
upstream** this fork currently carries — rename, delete and test-network exist in
`PcView.qml`, which is no longer the initial view, so today they are unreachable.

The carousel is done and accepted. Do not reopen it.

---

## Objective 0 — one number, first, before anything else

`Bulan.hostTileLabelGap`: **56 → 46.**

The gap between a host's circle and its name was opened by 40px last session and
the client then judged it 10px too much. That is the whole change. Its own commit,
thirty seconds, and it clears the last outstanding note on a screen the client has
otherwise signed off.

---

## Objective 1 — the host settings menu

**SELECT currently opens a panel showing what upstream's "View Details" showed.**
It should open a menu. The client scoped its contents in July:

| Item | What it does | Where the behaviour already exists |
|---|---|---|
| Host details | What SELECT shows today | `actHostSettings()` in `HostCarousel.qml` |
| Wake PC | What Y does today | `actWake()` |
| Forget PC | Removes the machine from this client's list | `PcView.qml` |

**Rename and test-network also live in `PcView.qml` and have no home.** Ask the
client whether they belong in this menu before adding them — the July scoping
named three items, and adding two more silently is exactly the kind of decision
that is theirs.

### What is settled and must not be reopened

- **"Forget PC" is the wording.** Client's call, 28 July. Removing a machine does
  not unpair it: the host goes on recognising this client, so it reappears as
  already paired if it is added back. **Bulan forgets the host; the host does not
  forget Bulan.** The asymmetry is intended. Do not raise it as a bug.
- **Custom components only.** There is no menu component in `app/gui/` yet, so
  this session builds one. `HostPanel.qml` is the closest existing thing — a
  modal overlay with scrim, surface and title — and is the right thing to model
  it on or extend. No Qt Quick Controls.

### What you have to decide with the client, not for them

Everything about how it looks and behaves is theirs. At minimum, ask about:

- **Where it appears** — over the carousel as an overlay, or a screen you push?
- **What it looks like when the focused host is offline** — Wake is meaningful,
  Forget is meaningful, details are thin.
- **Whether Forget asks for confirmation.** It is destructive and it is one
  button press from the screen every session starts on.

Come with a recommendation for each rather than an open question.

### Things that will bite

- **`MOONLIGHT_FAKE_HOSTS` cannot be used past the carousel** — and everything
  this menu does acts on a real machine **by its position in the real host
  list**, which is exactly the shape that caused the fake-host crash. A fake
  host's position means nothing there. `actConfirm()` already has one guard
  covering every branch below it; **this menu needs the same, and it needs to say
  so on screen rather than returning silently.** A silent button is
  indistinguishable from the dead-A defect this project chased three times.
- **A dying screen must not write global navigation state.** The settings page's
  combo box caused defect 1 this way. If this menu is a popup, it declares that
  it is open and nothing more.
- **A single bad property assignment takes out the whole screen**, silently, and
  drops the app onto upstream's interface. Suspect it whenever a screen
  "reverts". Run `qmllint` before building — it catches this class in seconds.

---

## Objective 2 — the top bar on launch

`BUGS-open.md` defect 8, found by the client and **measured at 567ms**. Upstream's
top bar is on screen for the first half-second of every run.

The bar defaults to visible and nothing hides it until a screen is pushed and
activated, which cannot happen until early initialisation finishes.

**Start it hidden and let the screens that want it ask.** The cost is that this
inverts a default the whole app depends on: four files turn the bar off, four turn
it on, and the screens that never mention it — `AppView`, `SettingsView`,
`PcView` — are relying on it being on. Each would have to claim it, and a missed
one loses its toolbar silently.

**Do this before the game grid is rebuilt**, because the game grid is one of the
screens that would have to claim it, and doing it after means doing it twice.

Its own commit, and worth a careful pass over every screen rather than a quick
one.

---

## How to know it worked

**Do not infer any of this from the outside.** Four sessions have now been lost
that way and the tools to avoid it exist.

### The build on screen is the one you made

On the Mac and the Deck the log's second line names the commit and the build time.
**On Windows the commit reads `unknown`** — the stamp is generated by a shell
script inside a `unix { }` block. The timestamp still works; check it against the
time you built.

### Every host count still loads

Run all six presets — `none`, `one`, `two`, `offline`, `mixed`, `many` — and read
the log for QML errors each time. **A broken screen does not look broken; it
silently falls back to upstream's grid**, which reads as "my build didn't take".

`two` is the client's real configuration and the only preset with an unpaired
host in it.

### The menu acts on the right machine

The failure mode to design the test around is **not** a crash. With real hosts
paired, a menu that addresses machines by list position will act on the *wrong
machine* and look like it worked. That is worse than crashing and it is what
happened last time. Prove the guard covers every branch, not just the one you
noticed.

---

## Carried forward, needing the client

- **The hover fix is unverified.** Reported as fixed once when it was not. Hover
  events are no longer generated at all now, which is a stronger claim, but nobody
  has watched it. One pass with a mouse resting over the carousel while holding
  left — the Windows machine can do this in a minute.
- **The wake overlay.** Review item 4: not a popup, a waiting state, *"perhaps
  with 3 animated bouncing dots"*, held until the host is awake **or fails to
  wake**. That last part makes it more than a visual change — the screen has to
  notice both outcomes, and today `actWake()` raises a panel and never revisits
  it. Phase D's *Waking PC* arriving early; it deserves its own session.
- **`deck_*` glyphs.** Ten files. Until they land, `deck` resolves to the Xbox
  set. Detection is confirmed working on hardware in both Desktop and Game Mode,
  so those ten files are the only thing in the way.
- **The Moonlight credit in About.** Brief §11, and a licence obligation rather
  than a nicety. Still not done. `ROADMAP.md` sizes it at a line of text.

---

## Not this session

- **The Connecting state, the game grid, game detail, screen transitions.** They
  follow, in that order.
- **Anything on the carousel.** It has been accepted. The travel easing is a
  faithful copy of what `PathView` used to do rather than a considered design, and
  the client has signed it off as good enough for v1 — revisit it deliberately or
  not at all.

---

## Rules that have not changed

- Branch from `bulan`, named once the task is known. Merge back on the client's
  sign-off, then delete it locally and on the fork.
- **Never commit to `master`.** It is a clean mirror of upstream and its only job
  is to fast-forward. `origin` is the client's fork; `upstream` is never pushed to.
- One commit per task, so each stays independently revertible. **Stop and show the
  client before moving on.**
- Custom components only. No Qt Quick Controls.
- Controller-first. If something only works with a mouse it is wrong.
- Minimum focus target 64×64 at 1280×800.
- Every value comes from the `Bulan` singleton. If a token is missing, **say so
  and let the client add it** — propose it with a value sourced from the brief and
  say plainly that you have done so.
- The client is a creative director who does not read code. Explain what the app
  does, not what the code does, and name what things cost.

**Delete this file when the session it describes is done.**
