---
kind: procedure
authority: review-procedure
read_when:
  - running-a-hardware-review
history_policy: replace-not-append
---

# Bulan — Deck review checklist

**The reusable procedure for a review on real Steam Deck hardware.** It carries
no results. Record each session as a dated report in `docs/validation/` using
the template at the end, and link the latest from `HANDOFF.md`.

This file does not own repository state, open defects, or token values — see
`HANDOFF.md`, `BUGS.md`, and `DESIGN-SYSTEM.md`.

**Work top to bottom.** Part 1 is regression: if a fix did not survive contact
with hardware, the judgement calls in Part 2 are being made about a build that is
already wrong. Part 3 needs a second machine.

Every check says what **right** looks like and what **wrong** looks like. Where
"wrong" has a consequence worth knowing before you decide, it says that too.
**Write the answer down as you go.**

---

## Part 0 — Before you start

**Build and install.** `BUILDING-DECK.md` has the one command. Two traps it
warns about, repeated here because they have cost a session each:

- The recipe **hardcodes the source path.** It will happily build a different
  checkout or branch than the one you have open, without saying so. Confirm the
  recipe points at the exact checkout, branch, and commit intended for review,
  and write that commit into the report.
- The offscreen screenshot hooks need `--filesystem=home`, or the file silently
  never appears.

**Then verify three things before handing the Deck over.** Each has invalidated
a whole session before:

1. **Exactly one instance is running** — `flatpak ps | grep -c MoonlightFork`.
   An old process in front of you invalidates every observation made against it.
2. **The interface cache was cleared after installing**, or the app may show a
   build from days ago. Path in `BUILDING-DECK.md`.
3. **The log is clean.** A screen that fails to load says so, with file and
   line, and drops the app back to upstream's interface — which looks exactly
   like a stale build and is not one. Read the log before concluding anything.

**You need the log for the startup glyph check and the Game Mode check.** On the
Deck, Bulan writes its log to the terminal rather than to a file, so launch it
from Konsole in Desktop Mode:

```bash
flatpak run io.github.laweirdo.MoonlightFork 2>&1 | tee ~/Documents/bulan.log
```

For Game Mode, where there is no terminal, set the launch options to write the
log instead — see check 3.1.

**Have both hosts available.** `Shoebox` and `Steambox`. Several checks need one
online host and one offline host visible at the same time.

**Fake hosts are review inputs, not action targets.** The guard stops A and Wake
from touching a real machine and gives visible review-mode feedback. Use a real
host for any end-to-end action check.

---

## Part 1 — Regression: did the fixes survive?

### 1.1 — A still works after visiting Client Settings

**Do:** On the host carousel, press **START** to open Client Settings, then **B**
to come back, then **A** on a host that is online and paired.

**Right:** A connects, exactly as it did before you went into settings.

**Wrong:** A does nothing at all — no sound, no movement, no error. Every other
button still works, which is what made this look like a pairing problem.

### 1.2 — A still works after a dropdown in Client Settings

**This is the version that reproduces.** 1.1 alone may pass on a build that is
still broken.

**Do:** **START** into Client Settings. Open the **Resolution** dropdown, close
it again, press **B** to come back, then **A** on an online paired host.

**Right:** A connects.

**Wrong:** A is silently dead, permanently, until the app is restarted.

**If wrong:** stop and report it rather than continuing. The rest of Part 1 is
about buttons, and a build where A dies mid-session makes every later result
unreliable. It would also mean a mechanism exists that the diagnosis missed.

### 1.3 — Wake appears only where it does something

**Do:** On the carousel, scroll between an **online** host and an **offline**
one, watching the hint bar along the bottom.

**Right:** **Y Wake** is present on the offline host and absent on the online
one. The remaining hints reflow to close the gap.

**Wrong:** Wake shown on an online host — the old behaviour, where pressing Y did
nothing and said nothing.

**Also judge, don't just check:** watch the reflow at real speed, scrolling back
and forth a few times. Does it read as the bar responding to what you are looking
at, or as a twitch? If it is the second, the alternatives are greying Y out —
which costs a set of glyph artwork and a new colour token — or keeping Y and
relabelling it.

### 1.4 — Glyphs follow the controller you are actually using

**Do:** With the Deck's own controls in use, connect a **DualSense**. Then, with
it still connected, press a button or push a stick **on the Deck itself**.

**Right:** Glyphs switch to PlayStation shapes when the DualSense arrives, and
switch **back** when you use the Deck, with the DualSense still plugged in.

**Wrong:** Glyphs stay on PlayStation shapes until the DualSense is physically
disconnected.

**Still unanswered from every previous session:** does **every** glyph in the
hint bar change, or does any stay Xbox? Look along the whole bar, not at one.

### 1.5 — Glyph detection reports itself at startup

**Do:** Read the top of the log from Part 0.

**Right:** three lines, near the start:

```
Controller glyphs: 1 controller(s) attached
Controller glyphs:   "Steam Deck" vendor=28de product=…  -> deck
Controller glyphs: detected deck, drawing xinput
```

`detected deck` is the answer that matters — it means Valve's vendor ID was
seen. `drawing xinput` is expected and correct for private v1: the client judged
the practical Deck shapes identical to the accepted XInput set, so custom Deck
art is not required.

**Wrong:** `detected fallback` while a controller is attached. That means the
hardware was not recognised. If the three lines are missing entirely, you are
running an old build.

---

## Part 2 — The judgement calls

These are client judgement calls, not pass/fail tests. Re-run them whenever the
panel, the values, or the surrounding design changes. `DESIGN-SYSTEM.md` records
the accepted values each one reviews.

### 2.1 — Grain density → reviews `atmosphereGrainOpacity`

**Do:** Look at a flat mid-screen area of the carousel background at normal
holding distance, roughly 50 cm. Then again at about 25 cm.

**Expect it to be invisible, not coarse.** A design machine rendering at double
density makes grain look twice as heavy as it will here.

**The judgement:** if you cannot see it at 50 cm it is not doing its job — grain
exists to break banding, and grain you cannot see cannot break anything. That
would mean the accepted 2–4% range is wrong for this panel, not that the value
needs a nudge.

**Judge this together with 2.2.** They are the same question from two directions.

### 2.2 — Colour banding

**Do:** Look at the darkest part of the background gradient, just above the hint
bar, for stepped bands or a colour cast.

**Which panel matters:** the banding concern targets the **LCD** Deck. The two
panels fail differently — LCD shows wide steps, OLED tends to crush toward black
and tint. **On an OLED this check cannot be completed**; record it as skipped and
answer instead whether the OLED shows crushing or tinting in the darkest region,
which is a different problem with a different fix.

### 2.3 — Type at arm's length → reviews `sizeCaption`

**The single riskiest item in this document.**

**Do:** At normal holding distance, read the **address line under the host name**
(`192.168.1.24`) and the **hint bar labels** along the bottom.

**Right:** legible without leaning in or squinting.

**Wrong:** you find yourself moving the Deck closer.

**What it costs if wrong:** `sizeCaption` is used across every screen. Changing
it touches everything built and everything not yet built — which is why it is
reviewed before construction rather than after. `sizeBody` at 22 px and up is
not at risk.

### 2.4 — Motion feel → reviews `motionOvershoot` and `motionFocusMs`

**Do:** Hold left or right to run the carousel fast, then let go. Then a single
deliberate tap.

**Right:** the fast run lands softly rather than snapping, and the single tap
feels immediate.

**Wrong, two ways:** a visible bounce at the end of the fast run means too much
overshoot. A single tap that feels laggy means the transition is too slow.

### 2.5 — Menu battery cost

**Do:** Sit on the carousel, on battery, and watch power draw over a few minutes.
The reading is noisy — sample repeatedly rather than trusting one number, and
record the app-closed baseline alongside it.

**Worth knowing before you spend time on this:** the atmosphere measured below
the noise floor on the design machine, and it is structurally zero during a
stream because the interface window is hidden. Grain is a full-screen blend, so
this is the one place it could show.

**Cost of investigating properly:** the three atmosphere effects are compile-time
switches, so an on/off comparison means two full builds, about two minutes each
on the Deck. If this becomes routine, making them runtime-switchable is a small
change — say so and it gets done.

---

## Part 3 — Game Mode, wake, and the waiting state

### 3.1 — Game Mode

Game Mode is where Steam Input actually sits between the hardware and the app.

**Do:** Add Bulan as a non-Steam game (`BUILDING-DECK.md` has the steps), switch
to Game Mode, and launch it. To capture the log where there is no terminal, set
**Launch Options** to:

```
run io.github.laweirdo.MoonlightFork 2>&1 | tee /home/deck/Documents/bulan-gamemode.log
```

Then check, in order:

1. **The glyph line in the log** — still `detected deck`? If it says `fallback`,
   Steam Input is presenting a virtual pad that hides Valve's vendor ID, and the
   glyph system is looking at the wrong thing in the mode that matters most.
2. **All five bindings still arrive:** A connects, B goes back, X opens Add a PC,
   START opens Client Settings, SELECT opens Host Settings.
3. **Steam Input has not rebound anything.** Confirm "Swap face buttons" is off
   before blaming the app.

**Why this matters more than it looks:** Game Mode is how the app will actually
be used. A binding that works in Desktop Mode and not in Game Mode is a binding
that does not work.

### 3.2 — Can Bulan wake a sleeping PC?

**The procedure needs a host you can genuinely put to sleep.** The online path
proves nothing, because waking an awake machine correctly does nothing.

**Do:** Put a paired host to sleep properly. On the carousel it should appear
offline, and the hint bar should offer **Y Wake**. Press it.

**Right:** the machine wakes, and the carousel reflects it coming back.

**Wrong:** nothing happens, or it reports waking and the host never returns.

**If it does not work:** the "Asleep" state shown on hosts is a promise the app
cannot keep, and the wording has to change — a copy decision, and the client's.

### 3.3 — The waiting state, on a real machine and a real panel

The tile busy state — dimmed disc, three bouncing dots — was accepted on a
Windows review station with a hardware gamepad, but **every number in it was
judged against a fake host that came back in three seconds, on a scaled desktop
monitor.**

**Do:** run 3.2's wake on a genuinely sleeping host and watch the tile rather
than the outcome.

| Item | What is needed |
|---|---|
| 30-second give-up | Did the host return inside it? Too long to sit through, or too short for the machine? |
| Notice latency | Once the PC was up, how long before the dots stopped? Budget is about 3 seconds of discovery poll. Imperceptible, or a visible lag? |
| Dot size, gap, bounce | 18 / 20 / 14 px, set on a desktop panel. Right on a 7-inch one at 204 ppi, or wrong the way `sizeCaption` nearly was? |
| Disc dim | 0.55. Does the monogram still read underneath, and does the tile read as busy rather than disabled? |

**Also see the failure state at least once**, which nobody has yet. Wake a host
that cannot come back — unplug it, or use a fake host with
`MOONLIGHT_FAKE_WAKE_OUTCOME=timeout` — and read *"Couldn't wake `<name>`. It may
still be asleep."* It holds for three seconds and then reverts on its own.
**Judge whether three seconds is long enough to read it**, since there is nothing
to press and no second chance to see it.

---

## Part 4 — The full loop

Private v1's exit condition is the whole journey on the target device. None of
it has ever been run there.

1. **Real pairing** against a live host, through the first-run route. Force it
   with `MOONLIGHT_FORCE_FIRST_RUN=1` if a host is already paired.
2. **Manual address entry in Game Mode**, with Steam's on-screen keyboard. This
   is the one part of the first-run route that cannot work without the OSK.
3. **A real stream** launched, resumed, failed, and quit.
4. **Recent↔Library tab switching with L1/R1**, and the grid's context restore
   across a round trip to the carousel and back.
5. **Screen transitions and entrance motion in flight** — how they actually
   feel, which no capture can establish.
6. **The transition blur's cost**, measured rather than assumed.
7. **OLED appearance**, and LCD appearance if that hardware is present.

---

## Report template

Copy into `docs/validation/YYYY-MM-DD-<what>.md` and fill in. Record skipped
checks explicitly — a check with no answer is not a pass.

```markdown
# Validation report — <what>, <date>

| Item | Value |
|---|---|
| Date | |
| Branch | |
| Commit | |
| Hardware | |
| Environment | Desktop Mode / Game Mode / both |
| Who | |

## Part 1 — regression
| Check | Result |
|---|---|
| 1.1 A after a plain settings round trip | |
| 1.2 A after opening the Resolution dropdown | |
| 1.3 Wake shown only where it does something | |
| 1.4 Glyphs follow the pad in use | |
| 1.5 Detection reported at startup | |

## Part 2 — judgement calls
| Check | Answer |
|---|---|
| 2.1 `atmosphereGrainOpacity` | Keep, or a new value — and whether grain was visible at all |
| 2.2 Banding | |
| 2.3 `sizeCaption` | Keep, or raise it |
| 2.4 `motionOvershoot` / `motionFocusMs` | |
| 2.5 Battery, against the app-closed baseline | |

## Part 3 — Game Mode, wake, waiting state
| Check | Answer |
|---|---|
| 3.1 Game Mode | `detected deck` or `detected fallback`; which bindings arrived |
| 3.2 Wake | Works, or the Asleep wording needs changing |
| 3.3 Waiting state on real hardware | |
| Every glyph in the hint bar | Did they all change on hot-swap, or did some stay Xbox |

## Part 4 — the full loop
| Item | Result |
|---|---|
| Real pairing | |
| Manual address entry with the OSK | |
| Real stream: launch, resume, failure, quit | |
| L1/R1 tab switch and grid context restore | |
| Motion in flight | |
| Blur cost | |
| Panel appearance | |

## Skipped, and why

## Defects or decisions arising
```
