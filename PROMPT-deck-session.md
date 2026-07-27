# Prompt — the Steam Deck session

**This file is disposable.** It covers one session: closing Phase A on real
hardware. **Delete it when Phase A closes.** It exists as a file rather than a
saved message so the paths and branch names in it can be checked against the
repo, and so it cannot quietly rot the way `BUILDING-DECK.md` did — that file
still cites a branch that was deleted on 27 July 2026.

Paste everything below the line into a new session.

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

Don't retry silently. If something fails, tell me what failed and what you're
trying next. If the same thing fails twice, stop and give me your best read on
why rather than trying a third time.

**Ask before anything that needs my password or changes my system.** This
session has one of those in it — see step 0.

Tell me how to check your work. After a change, tell me what to look at and what
"right" looks like.

## Two things not to do

Don't re-litigate my design decisions. If I've corrected something, act on it.

Don't pad. No preamble, no summarising my request back to me.

---

# The session

**Read these first, in this order:** `HANDOFF.md`, then `REVIEW-CHECKLIST.md`,
then `ROADMAP.md`. In `HANDOFF.md`, the section called *Hard-won knowledge — do
not rediscover these* is the one that saves the most time; several items in it
cost a full session each to learn.

## What this session is for

`ROADMAP.md` Phase A is complete except the parts that need real hardware.
Everything left is in `REVIEW-CHECKLIST.md`, which is your working document.

Two kinds of work:

1. **Regression.** Four defects were found on the Deck last session, fixed on the
   Mac, and **have never been pressed on a real controller.** They were verified
   by driving the app programmatically, which is not the same as a thumb on a
   button.
2. **Judgement calls.** Five things only I can decide by looking at the panel.
   Three of them settle design tokens that are frozen until I answer, and nothing
   new gets built until they're settled.

## How we're set up

You're running on my Mac. **The Deck is reachable over SSH.** You drive
everything technical remotely; I press the buttons and make the visual calls.

| You do | I do |
|---|---|
| git, build and install on the Deck over SSH | Press the buttons |
| Read the log — including live, while I'm in Game Mode | Judge grain, type, motion, banding |
| Sample the battery figures repeatedly and do the arithmetic | Decide the three token values |
| Take screenshots on the Deck and copy them back so you can see them | Say whether the hint-bar reflow reads as responsive or twitchy |

**SSH is the whole reason check 9 is possible.** Game Mode has no terminal, so
previously nobody could read the log there. You can, while I'm in it. Game Mode
is where Steam Input actually sits between the hardware and the app, and none of
this project has ever been verified there — it's the largest untested assumption
in the whole thing.

---

## Step 0 — SSH, which does not exist yet

Checked on 27 July 2026: there's no SSH config on the Mac, no known-hosts entry
for the Deck, and nothing about SSH in any repo document. So this has to be set
up before anything else.

**SteamOS ships with the SSH service switched off and no password on the `deck`
account.** Turning it on means setting a password and enabling a service, on the
Deck, by me.

**Ask me to do it and wait.** Do not attempt it yourself, do not sudo, and don't
suggest workarounds — this is a change to my system and it needs my password.
Tell me the two commands to run in the Deck's Konsole and what each does, then
wait for me to confirm.

Then find the Deck on the network rather than assuming an address, confirm you
can reach it, and tell me the address you settled on so I can reuse it.

**Worth knowing for later:** a SteamOS update can switch the SSH service back
off. If a future session finds SSH dead for no reason, that's why — it's not
broken, it's been reset.

## Step 1 — the checkout on the Deck

**This is the step most likely to waste the session, and it fails silently.**

The Deck's copy of the project lives at `/home/deck/Documents/moonlight-qt`.
It is almost certainly sitting on a branch called `dev/token-proof`, **which no
longer exists** — the branches were restructured on 27 July 2026 and everything
now lives on `bulan`. `BUILDING-DECK.md` still refers to the old name; that's a
stale document, not a live instruction.

Before building:

- Fetch with pruning, then switch that folder to `bulan`. Confirm it.
- Update the submodules, recursively. There are four, and one has two more nested
  inside it. A build without them fails.
- The recent upstream sync replaced one dependency that used to be a submodule
  with source files committed directly. It leaves an empty leftover folder behind
  at `h264bitstream/h264bitstream`. It's safe to delete — I hit this on the Mac
  and removed it there.

**Why this matters more than it looks:** the Flatpak build recipe has that folder
path written inside it. It does not build "whatever branch you have open" — it
builds that folder. If the folder is on the wrong branch, **the build succeeds and
installs the wrong app, with no warning at all.** Confirm the branch before you
build, not after you're confused.

## Step 2 — build and install

`BUILDING-DECK.md` has the single command. First build from scratch is about six
minutes; rebuilds after that are under two, and installing takes seconds.

Tell me when it's on and I'll pick the Deck up.

## Step 3 — work through the checklist

`REVIEW-CHECKLIST.md`, top to bottom. It's written for this. Each check says what
right and wrong look like, and where a wrong answer has a price, it names it.

**Part 1 before Part 2, without exception.** If a fix didn't survive contact with
hardware, every opinion I form afterwards is about a build that's already wrong.

**One hard stop.** Check 1.2 is: open Client Settings, open the Resolution
dropdown, close it, come back, press A. That's the sequence that actually
reproduced the dead-A bug — the simpler version can pass on a build that's still
broken. **If 1.2 fails, stop and tell me.** Don't continue and don't start
fixing. It would mean there's a third cause the diagnosis missed, and I'd rather
decide what to do than have you chase it at the end of a hardware session.

Stop and show me after each part.

## Step 4 — apply the tokens

Once I've given you the three values:

- Change them in **`app/gui/Bulan.qml`** — that's the singleton the running app
  reads. Never inline a value anywhere else; every value comes from that one
  file, and if something needs a token that doesn't exist, tell me and let me add
  it.
- Rebuild and let me look at it on the real panel before moving on.
- One commit per settled token, so I can revert one without losing the others.

The three: `sizeCaption`, `atmosphereGrainOpacity`, `motionOvershoot`.

**One trap worth knowing before you touch either file** — it is in `HANDOFF.md`
under hard-won knowledge, repeated here because you will hit it in this step.
There are two files with similar names and they are not the same thing:

- `app/gui/Bulan.qml` is the live design system. Changing a value here changes
  the app.
- `app/gui/BulanTokens.qml` is a **separate copy** feeding `TokenProof.qml`, the
  offline review sheet. Changing a value here changes nothing about the app.

`sizeCaption` exists in **both** — as `sizeCaption: 16` in the first, and as
`size: 16` on the `caption` entry in the second. **Change both**, or the review
sheet will keep showing me the old size while the app uses the new one, and I'll
be reviewing a lie. `atmosphereGrainOpacity` and `motionOvershoot` are only in
`Bulan.qml`, so those are single edits.

If you find any other token duplicated across the two files, add it to that same
section in `HANDOFF.md` when you get to step 5.

`sizeCaption` is the one with teeth — it's used on every screen, so if it's wrong
it's a change that touches everything built and everything not yet built. That's
the whole reason this session comes before any new screens.

## Step 5 — close Phase A

Update these, in this order:

- **`BUILDING-DECK.md`** — it cites the deleted branch, has no SSH section, and
  doesn't mention the leftover-folder step. Fix all three. This document is how
  the next hardware session starts; it being wrong is what step 1 is defending
  against.
- **`HANDOFF.md`** — rewrite the *Deck checks the Mac cannot perform* section with
  what actually happened, the way it was rewritten after the last Deck session.
  Add anything that cost you time to the hard-won knowledge section.
- **`ROADMAP.md`** — mark Phase A closed and record the settled token values.
- **`REVIEW-CHECKLIST.md`** — record the answers. Keep the document; it's the
  template for every future hardware session.

## Rules for this session

**Branches.** Cut one from `bulan`, named once you know what it is. Merge it back
when I've signed off, then delete it — locally and on my fork.

**Never commit to `master`.** It's a clean mirror of upstream and nothing else.
One fork-only commit on it turns every future upstream sync from a trivial
fast-forward into a conflicted merge. `origin` is my fork; `upstream` is the
original project and you never push there.

**Do not start Phase B.** Not the host settings menu, not any screen, no matter
how well the checks go or how much time is left. The roadmap gates construction
on this session's answers, and I want to decide what gets built next with the
results in front of me.

## What done looks like

- The four fixes confirmed on real hardware, by hand
- The three tokens settled from what I saw, not from arithmetic
- Game Mode answered — do the glyphs and all five buttons survive Steam Input
- The wake question answered, on a machine actually put to sleep
- Documents updated, Phase A closed, and this prompt file deleted
