---
kind: validation-report
authority: historical-evidence
status: final
read_when:
  - investigating-a-past-validation-claim
history_policy: append-only
---

# Validation report — Steam Deck OLED, 28 July 2026

| Item | Value |
|---|---|
| Date | 28 July 2026, with same-day follow-up |
| Branch | `bulan` |
| Commit | Not recorded at the time. The 1.2 repair landed afterwards as `be874bf8` |
| Hardware | Steam Deck OLED ("Galileo"), 7.4-inch, 1280×800 |
| Environment | Flatpak build, Desktop Mode **and** Game Mode |
| Procedure | `REVIEW-CHECKLIST.md`, Parts 1–3 |
| Who | Client pressing the buttons; assistant on the Deck reading the log live |

This session closed Phase A and settled the global token values now recorded in
`DESIGN-SYSTEM.md`.

## Part 1 — regression

| Check | Result |
|---|---|
| 1.1 A after a plain settings round trip | **Pass** |
| 1.2 A after opening the Resolution dropdown | **FAIL**, then fixed in `be874bf8` and retested by hand — now passes |
| 1.3 Wake shown only where it does something | **Pass.** Reflow judged responsive, not twitchy — accepted as built, no glyph artwork or new token needed |
| 1.4 Glyphs follow the pad in use | **Pass** |
| 1.5 Detection reported at startup | **Pass** — `detected deck` |

**1.2 was the hard stop and it triggered.** The cause was a *third* mechanism
behind the same symptom, not a regression: a popup elsewhere in the window
restores focus to a control that no longer exists on the way back, landing after
the carousel has already claimed it. Fixed by having the carousel reclaim focus
whenever it loses it, which cannot be raced.

## Part 2 — the judgement calls

| Check | Answer |
|---|---|
| 2.1 Grain | **Keep `atmosphereGrainOpacity: 0.03`.** Visible and doing its job. The prediction that it would be invisible on this panel was wrong |
| 2.2 Banding | **Could not be completed** — this is an OLED and the concern targets the LCD. Nothing needing action was observed |
| 2.3 Type | **Keep `sizeCaption: 16`.** Legible without leaning in. The calculation that said it would fail was wrong |
| 2.4 Motion | **Keep `motionOvershoot: 0.7`.** `motionFocusMs` **140 → 180** — the brief's figure read a touch too fast. "May need fine tuning in future" |
| 2.5 Battery | **Provisional: 4.31 W** on the carousel against a **3.92 W** app-closed baseline, roughly 0.4 W. Not settled; the app crashed part-way through sampling |

2.3 also produced three design corrections to the host status line, since built:
shorter copy on unreachable hosts, the status swatches carrying reachability
(red unreachable, green ready), and the redundant status dot removed.

## Part 3 — Game Mode and wake

| Check | Answer |
|---|---|
| 3.1 Game Mode | **Pass.** `detected deck` in Game Mode with `gamescope` confirmed running. All five bindings arrive |
| 3.2 Wake | **Not answered in the first pass; passed later the same day.** A genuinely sleeping, wakeable host returned after Y was pressed |

Game Mode was the project's largest untested assumption. Steam Input **does**
interpose a virtual controller — `Steam Virtual Gamepad`, product `11ff` rather
than `1205` — but it carries Valve's vendor ID `28de` through, and detection keys
on the vendor ID. So it survives.

## Skipped and unanswered

- **2.2 colour banding on an LCD Deck.** No LCD hardware was available. Still
  outstanding, and recorded as a standing risk in `ROADMAP.md`.
- **Whether *every* glyph in the hint bar changes on hot-swap**, or whether any
  stay Xbox. Carried forward into `REVIEW-CHECKLIST.md` check 1.4.
- **2.5 battery cost is provisional**, not settled — the sampling run was cut
  short by a crash.
- **3.3, the host tile waiting state, did not exist yet.** It was added to the
  procedure on 1 August 2026 and has never been run on hardware.

## What this session cost, and why

Three things went wrong with running the session itself and cost more time than
the checks did. All three are now preconditions in `REVIEW-CHECKLIST.md` Part 0:

1. An old Flatpak instance was in front of the new one, invalidating every
   observation made against it.
2. The interface cache survived an install, so the app showed a build from days
   earlier.
3. A screen that failed to load dropped the app back to upstream's interface,
   which looks exactly like a stale build and is not one — the log said so, and
   was not read first.
