# Bulan — Deck review checklist

For a session on the hardware. Everything here needs a real Steam Deck; nothing
here can be answered on the design machine, which is why it exists as a list
rather than as something a session just gets round to.

**Work top to bottom.** Part 1 is regression — if a fix did not survive contact
with hardware, the judgement calls in Part 2 are being made about a build that is
already wrong. Part 3 is the one thing that needs a second machine.

Every check says what **right** looks like and what **wrong** looks like. Where
"wrong" has a consequence worth knowing before you decide, it says that too.
**Write the answer down as you go** — the last section is what comes back.

---

## Part 0 — Before you start

**Build and install.** `BUILDING-DECK.md` has the one command. Two traps it
warns about, repeated here because they cost a session each:

- The recipe **hardcodes the source path**. It will happily build a different
  branch than the one you have open, without saying so. Confirm you are building
  `bulan`.
- The offscreen screenshot hooks need `--filesystem=home` or the file silently
  never appears.

**You need to see the log for checks 1 and 9.** On the Deck, Bulan writes its log
to the terminal rather than to a file, so launch it from Konsole in Desktop Mode:

```bash
flatpak run io.github.laweirdo.MoonlightFork 2>&1 | tee ~/Documents/bulan.log
```

For Game Mode, where there is no terminal, set the launch options to write the
log instead — see check 9.

**Have both hosts available.** `Shoebox` and `Steambox`. Several checks need one
online host and one offline host visible at the same time.

---

## Part 1 — Regression: did the fixes survive?

These four defects were found on the Deck, fixed on the Mac, and **have never
been pressed on real hardware**. The fixes were verified by driving the app
programmatically, which is not the same thing as a thumb on a button.

### 1.1 — A still works after visiting Client Settings

The plain version of the defect.

**Do:** On the host carousel, press **START** to open Client Settings, then **B**
to come back, then **A** on a host that is online and paired.

**Right:** A connects, exactly as it did before you went into settings.

**Wrong:** A does nothing at all — no sound, no movement, no error. Every other
button still works, which is what made this look like a pairing problem.

### 1.2 — A still works after a dropdown in Client Settings

**This is the version that actually reproduced.** 1.1 alone may pass on a build
that is still broken.

**Do:** **START** into Client Settings. Open the **Resolution** dropdown, close
it again, press **B** to come back, then **A** on an online paired host.

**Right:** A connects.

**Wrong:** A is silently dead, permanently, until the app is restarted.

**If wrong:** stop and report it rather than continuing. The rest of Part 1 is
about buttons, and a build where A dies mid-session makes every later result
unreliable. It would also mean a third mechanism exists that the diagnosis
missed.

### 1.3 — Wake appears only where it does something

**Do:** On the carousel, scroll between an **online** host and an **offline**
one, watching the hint bar along the bottom.

**Right:** **Y Wake** is present on the offline host and absent on the online
one. The remaining hints reflow to close the gap.

**Wrong:** Wake shown on an online host — the old behaviour, where pressing Y did
nothing and said nothing.

**Also judge, don't just check:** you accepted the reflow when you chose to hide
Y. Watch it at real speed, scrolling back and forth a few times. Does it read as
the bar responding to what you are looking at, or as a twitch? If it is the
second, the alternatives were greying Y out — which costs a whole extra set of
glyph artwork and a new colour token from you — or keeping Y and relabelling it.

### 1.4 — Glyphs follow the controller you are actually using

**Do:** With the Deck's own controls in use, connect a **DualSense**. Then, with
it still connected, press a button or push a stick **on the Deck itself**.

**Right:** Glyphs switch to PlayStation shapes when the DualSense arrives, and
switch **back** when you use the Deck — with the DualSense still plugged in.

**Wrong:** Glyphs stay on PlayStation shapes until the DualSense is physically
disconnected. That was defect 4.

**Also answer the question left open last session:** did **every** glyph in the
hint bar change, or did any stay Xbox? Look along the whole bar, not at one.

### 1.5 — Glyph detection reports itself at startup

**Do:** Read the top of the log from Part 0.

**Right:** Three lines, near the start:

```
Controller glyphs: 1 controller(s) attached
Controller glyphs:   "Steam Deck" vendor=28de product=…  -> deck
Controller glyphs: detected deck, drawing xinput
```

`detected deck` is the answer that matters — it means Valve's vendor ID was
seen. `drawing xinput` is expected and correct until Deck glyph artwork exists.

**Wrong:** `detected fallback` while a controller is attached. That means the
hardware was not recognised.

**Note:** this used to be invisible, and the only way to force it was to connect
a DualSense and unplug it. That trick is no longer needed. If the three lines are
missing entirely, you are running an old build.

---

## Part 2 — The judgement calls

These are yours. They are not pass/fail — they are decisions that have been
waiting on your eyes, and **three of them settle tokens that are frozen until you
answer**. Nothing new gets built until they are settled, because all three are
global: changing them later touches every screen, built and unbuilt.

### 2.1 — Grain density  → settles `atmosphereGrainOpacity`

Currently `0.03`, the midpoint of the brief's 2–4%.

**Do:** Look at a flat mid-screen area of the carousel background at normal
holding distance, roughly 50cm. Then again at about 25cm.

**Expect it to be invisible, not coarse.** The design machine renders at double
density, so grain looked twice as heavy there as it will here. On this panel each
speck covers about a tenth of a millimetre, which is at the edge of what an eye
resolves at arm's length.

**The judgement:** if you cannot see it at 50cm, it is not doing its job — grain
exists to break banding, and grain you cannot see cannot break anything. That
would mean the brief's 2–4% range is wrong for this panel and §4 needs revising
upward, not that the value needs a nudge.

**Judge this together with 2.2, not separately.** They are the same question
asked from two directions.

### 2.2 — Colour banding

**Do:** Look at the darkest part of the background gradient, just above the hint
bar, for stepped bands or a colour cast.

**Important limitation:** the brief's banding concern targets the **LCD** Deck,
and the one in hand is an **OLED**. The two panels fail differently — LCD shows
wide steps, OLED tends to crush toward black and tint. **This check cannot be
completed on this hardware.** If an LCD Deck is ever in scope, it stays open.

What you *can* answer here is whether the OLED shows crushing or tinting in the
darkest region, which is a different problem with a different fix.

### 2.3 — Type at arm's length  → settles `sizeCaption`

**The single riskiest item in this document.**

**Do:** At normal holding distance, read the **address line under the host name**
(`192.168.1.24`) and the **hint bar labels** along the bottom.

**Right:** legible without leaning in or squinting.

**Wrong:** you find yourself moving the Deck closer.

**What it costs if wrong:** `sizeCaption` is 16px, which by calculation sits just
under the comfort threshold at 50cm. It is used across every screen. Changing it
is a token change touching everything built and everything not yet built — which
is exactly why the roadmap puts this before construction rather than after.
`sizeBody` at 22px and up is not at risk.

### 2.4 — Motion feel  → settles `motionOvershoot`

Currently `0.7`, about 3% overshoot, with a 140ms focus transition. The brief
says "barely-there" and gives no number, so this is an interpretation awaiting
your eye.

**Do:** Hold left or right to run the carousel fast, then let go. Then a single
deliberate tap.

**Right:** the fast run lands softly rather than snapping, and the single tap
feels immediate.

**Wrong, two ways:** a visible bounce at the end of the fast run means too much
overshoot. A single tap that feels laggy means the transition is too slow.

### 2.5 — Menu battery cost

**Do:** Sit on the carousel, on battery, and watch power draw over a few minutes.
Baseline with the app closed measured **3.92 W**. The reading is noisy — sample
repeatedly rather than trusting one number.

**Worth knowing before you spend time on this:** the atmosphere measured below
the noise floor on the design machine, and it is structurally zero during a
stream because the interface window is hidden. Grain is a full-screen blend, so
this is the one place it could show.

**Cost of investigating properly:** the three atmosphere effects are compile-time
switches, so an on/off comparison means two full builds, about two minutes each
on the Deck. If this becomes routine, making them runtime-switchable is a small
change — say so and it gets done.

---

## Part 3 — Game Mode, and the wake question

### 3.1 — Game Mode (check 9)

**Everything to date has been Desktop Mode.** Game Mode is where Steam Input
actually sits between the hardware and the app, and none of it has been verified
there. This is the largest untested assumption in the project.

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

### 3.2 — Can Bulan actually wake a sleeping PC?

Open since the flow board. **Needs a host you can genuinely put to sleep** — the
online path proves nothing, because waking an awake machine correctly does
nothing.

**Do:** Put a paired host to sleep properly. On the carousel it should appear
offline, and the hint bar should now offer **Y Wake**. Press it.

**Right:** the machine wakes, and the carousel reflects it coming back.

**Wrong:** nothing happens, or it reports waking and the host never returns.

**If it does not work:** the "Asleep" state shown on hosts is a promise the app
cannot keep, and the wording has to change — that is a copy decision, and yours.

---

## What comes back from the session

Answers to these, in whatever form suits you:

| Item | What is needed |
|---|---|
| Part 1, checks 1.1–1.5 | Passed or failed. A failure here outranks everything below. |
| `atmosphereGrainOpacity` | Keep 0.03, or a new value — and whether grain was visible at all |
| `sizeCaption` | Keep 16, or raise it |
| `motionOvershoot` | Keep 0.7, or a new value |
| Game Mode | `detected deck` or `detected fallback`; which bindings arrived |
| Wake | Works, or the Asleep wording needs changing |
| Hint bar reflow | Reads as responsive, or needs one of the alternatives |
| Every glyph in the hint bar | Did they all change on hot-swap, or did some stay Xbox |

Once the three tokens are settled, Phase A closes and construction can start.
Until then it should not — `ROADMAP.md` says why, and the reason is that
`sizeCaption` failing would mean redoing every screen built in the meantime.
