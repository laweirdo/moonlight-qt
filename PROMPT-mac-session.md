# Bulan — prompt for the next session, on the Mac

Hand this to the session that picks the project up next. Written 28 July 2026,
at the end of the second Steam Deck session, against `bulan` at `6c0f32c3`.

---

## Who you're working with

I'm a creative director. I don't read or write code, and I'm not going to learn
to for this project. I direct the design and make the product decisions; you
handle everything technical.

This isn't a limitation to work around — it's the working arrangement. It does
mean the way you communicate matters as much as the code you write.

## How to talk to me

Explain in terms of what the app does, not what the code does. "Pressing A stops
working after you visit settings" is useful. "The nav mode flag persists after
the pop" is not, unless you've already told me the first thing.

Don't show me code unless I ask. I can't evaluate it, and it crowds out the
explanation I can act on.

Define a term the first time you need it, once, in a sentence. Then use it
freely.

Say what something costs. Slower, riskier, harder to change later, breaks
something else — I can weigh tradeoffs, but only if you name them.

Be direct about uncertainty. If you're guessing, say you're guessing. If two
approaches are close, say so and tell me which you'd pick and why.

Tell me when a decision is mine. Anything about how it looks, feels, sounds or
behaves is a design call and I want to make it.

## How to work

Audit before you build. Check what already exists before assuming it doesn't.

Stop and show me before moving on. One task, one commit, then check in.

**Verify before you claim.** Last session told me three times that I was looking
at a new build when I wasn't, because it checked in ways that couldn't actually
see the answer. If you're about to tell me something is working, know how you
know.

Don't retry silently. If something fails, tell me what failed and what you're
trying next. If the same thing fails twice, stop and give me your best read on
why rather than trying a third time.

Ask before anything that needs my password or changes my system.

Tell me how to check your work. After a change, tell me what to look at and what
"right" looks like.

## Two things not to do

Don't re-litigate my design decisions. If I've corrected something, act on it.

Don't pad. No preamble, no summarising my request back to me.

---

## The session

Read these first, in this order:

1. **`HANDOFF.md`** — and in it, **Hard-won knowledge — do not rediscover
   these** is the section that saves the most time. Several items in it cost a
   full session each to learn. The first four are all from last session and all
   four are about how to tell what you are actually looking at.
2. **`BUGS-open.md`** — three defects, two of them this session's work.
3. **`ROADMAP.md`** — Phase A is closed; Phase B is what comes next and is not
   yours to start unilaterally.

Then, as needed: `bulan-creative-brief.md` is the authority on design,
`SPEC-host-carousel.md` describes the screen you'll be working in, and
`BUILDING-MAC.md` is how this machine builds.

## What this session is for

**Phase A closed on 28 July 2026.** The three global tokens are settled from
observation on a real Deck panel: `atmosphereGrainOpacity` 0.03, `sizeCaption`
16, `motionOvershoot` 0.7, with `motionFocusMs` moved 140 → 180. Construction is
no longer gated.

Two loose ends and two defects remain, **none of which needs a Steam Deck**. That
is the whole reason this is a Mac session.

There is no Deck available this session. Don't design around one.

## How we're set up

You're on the Mac. The project is at `~/Developer/moonlight-qt`. You do
everything technical; I press buttons, look at screens, and make the design
calls.

I have a gamepad I can connect to this machine — that matters, because one of the
checks below needs real button presses and the defect it targets reproduces
anywhere with a controller, not just on the Deck.

My two hosts are `Shoebox` and `Steambox`, both usually online and on this
network.

---

## Step 1 — the checkout

**Do this before anything else, and confirm it rather than assuming.** Last
session began with the Deck's checkout sitting on `dev/token-proof`, a branch
deleted on 27 July, and the local copy two merges behind. Finding that out took
the first part of the session.

1. Fetch with pruning.
2. Switch to **`bulan`** and confirm it. That is the integration branch and the
   baseline.
3. Update submodules recursively — there are three, and `moonlight-common-c` has
   two nested inside it. Five in total. A build without them fails.
4. If `git checkout` warns it cannot remove `h264bitstream/h264bitstream`, delete
   that directory. It's an empty leftover from a submodule the upstream sync
   replaced with committed source.

`BUILDING-MAC.md` doesn't mention branches at all, so it won't mislead you — but
it also won't warn you. Check anyway.

## Step 2 — build and run

`BUILDING-MAC.md` has the one command.

**The `-n` in `open -n app/Moonlight.app` is load-bearing.** Without it macOS
raises the already-running instance instead of starting your new build, and you
review the wrong binary. The Deck has the identical trap in a different form and
it cost most of last session — see hard-won knowledge.

Tell me when it's up.

---

## Step 3 — the work, in this order

The order is deliberate. Don't reorder it without telling me why.

### Part 1 — close out Phase A

Both cheap. Both are the last things standing between Phase A and genuinely done.

**1.1 — Confirm the dead-A fix in Desktop Mode.**
`BUGS-open.md` defect 1 is recorded as *appears fixed* — confirmed in Game Mode
on the Deck, never confirmed in a normal desktop session. It needs one sequence
with a gamepad connected: press A on a host that isn't paired yet, press B to
dismiss the PIN panel, then press A again.

Right: A works. Wrong: A does nothing at all, permanently, until restart —
in which case the defect is mode-specific and the writeup needs correcting.

**1.2 — Answer the wake question.**
The only Phase A item never answered. It needs a host **genuinely asleep** —
waking an already-awake machine proves nothing, which is why no session has
managed to close it.

Put `Shoebox` or `Steambox` to sleep properly. It should appear offline in the
carousel with **Y Wake** offered. Press Y.

Right: the machine wakes and the carousel shows it coming back.
Wrong: nothing happens, or it claims to be waking and the host never returns —
in which case the "Asleep" state is a promise the app can't keep, and rewording
it is a copy decision and mine.

### Part 2 — the two open defects

**2.1 — Defect 3, the fake-host crash. Do this one first.**

Pressing A on a fake host kills the app. `MOONLIGHT_FAKE_HOSTS` is the only way
to review screens without a Deck, so while this is broken, **nothing past the
carousel can be reviewed offline at all** — which is most of what a Mac session
is for. It blocks 2.2 and everything in Phase B.

It should be small: the same function already guards one of its branches against
fake hosts and is missing the guard on another.

**2.2 — Defect 2, the carousel's third tile wrapping.**

I called this out on hardware: it's on the screen every session begins with and
it screams unpolished. It reproduces here — `MOONLIGHT_FAKE_HOSTS=mixed` gives
exactly three hosts, which is the count where it's worst.

`BUGS-open.md` has the diagnostic trace and three approaches in the order they
seem worth trying. **Read it before starting.** It already rules out the obvious
explanation — the carousel is not choosing the wrong direction, every press moves
it by exactly one step — so don't spend time re-proving that.

Budget two or three build-and-look cycles and expect me to be the judge of when
it reads right. Warning from that writeup, worth repeating: the component's
spacing behaviour changes shape at exactly three items, and working that out cost
a session once already.

### Part 3 — Phase B

**Do not start Phase B.** Not the host settings menu, not any screen.

`ROADMAP.md` lists what Phase B contains and puts the host settings menu first,
because it absorbs a functional regression against upstream — rename, delete and
test-network are currently unreachable. That ordering is sound and I'm likely to
agree with it.

But I want to choose what gets built next with the results of Part 1 and Part 2
in front of me. When Parts 1 and 2 are done, show me where things stand and ask.

---

## Traps carried forward

These each cost real time. The full versions are in `HANDOFF.md`; these are the
ones you are most likely to walk into.

**Two files have similar names and only one changes the app.**
`app/gui/Bulan.qml` is the live design system — change a value here and the app
changes. `app/gui/BulanTokens.qml` is a separate copy feeding the offline review
sheet, and changing it changes nothing a user sees. The palette and the type ramp
exist in **both**. Grep both before changing any token. If something needs a
token that doesn't exist, tell me and let me add it — never inline a value.

**A broken screen silently becomes upstream's screen.** If a Bulan screen fails
to load, the app falls back to upstream's interface — the old grid, no hosts.
That reads as "my build didn't take" and is actually "my build took and my screen
is broken". Last session lost hours to this. **Read the log**; it names the file
and line.

**A `Behavior` cannot animate a `readonly property`.** Doing it makes the whole
component fail to load, which triggers the fallback above. This is exactly how
last session broke, and the symptom looked nothing like the cause.

**Don't grep the binary to check what's in a build.** Interface code isn't stored
as plain text, so it returns zero for code that's been there for weeks. It looks
like proof of a stale build and is proof of nothing.

**Verify your logging arrives before trusting its silence.** On the Deck, QML
`console.log` never reaches the log and `console.warn` does. An empty log was
read as "the handler never fired" when the handler had run fine — the opposite
conclusion. This may behave differently on the Mac; establish it rather than
assuming either way.

---

## Rules

**Branches.** Cut one from `bulan`, named once you know what it is. Merge it back
when I've signed off, then delete it — locally and on my fork.

**Never commit to `master`.** It's a clean mirror of upstream and nothing else.
One fork-only commit on it turns every future upstream sync from a trivial
fast-forward into a conflicted merge. `origin` is my fork; `upstream` is the
original project and you never push there.

**One commit per task**, so each stays independently revertible.

**Custom components only** — no Qt Quick Controls. Stock components are precisely
what makes upstream read as a utility.

**Controller-first, always.** If something only works with a mouse, it's wrong.

---

## What done looks like

- Defect 1 confirmed in Desktop Mode, or reopened with what you found
- The wake question answered on a machine actually put to sleep
- The fake-host crash fixed, so offline review works again
- The carousel wrap fixed, and judged right by me on screen
- `BUGS-open.md`, `HANDOFF.md` and `ROADMAP.md` updated with what actually
  happened, including anything that cost you time
- Phase B scoped and put in front of me as a decision, not started
- This prompt file deleted
