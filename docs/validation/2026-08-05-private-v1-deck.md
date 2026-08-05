# Validation report — private v1 on Steam Deck, 5 August 2026

| Item | Value |
|---|---|
| Date | 5 August 2026 |
| Branch | `bulan` |
| Commit | `173c0497` — the accepted private v1 merge. No application commit has landed since; every commit between it and this session's HEAD is documentation only. Not independently confirmed against the Deck build by this Claude session — recorded from repository history. |
| Hardware | Not recorded (Deck model, panel type, and SteamOS version were not supplied) |
| Environment | Desktop Mode and Game Mode, both — per the client's report that the applicable checklist was worked |
| Who | Lao |

**Evidence basis.** This report transcribes the client's manual, first-hand
review of `REVIEW-CHECKLIST.md` on their own Steam Deck. It is client-observed
evidence, not evidence gathered by this Claude session — no build, log, or
screenshot from the session was available to inspect directly.

## Part 1 — regression

| Check | Result |
|---|---|
| 1.1 A after a plain settings round trip | Pass (client-observed) |
| 1.2 A after opening the Resolution dropdown | Pass (client-observed) |
| 1.3 Wake shown only where it does something | Pass (client-observed) |
| 1.4 Glyphs follow the pad in use | Pass (client-observed) |
| 1.5 Detection reported at startup | Pass (client-observed) |

## Part 2 — judgement calls

| Check | Answer |
|---|---|
| 2.1 `atmosphereGrainOpacity` | Pass (client-observed). No new value requested. |
| 2.2 Banding | Skipped: hardware unavailable if the Deck used is OLED — panel type not recorded, so this cannot be stated more precisely than "no defect observed." |
| 2.3 `sizeCaption` | Pass (client-observed). No change requested. |
| 2.4 `motionOvershoot` / `motionFocusMs` | Pass (client-observed). |
| 2.5 Battery, against the app-closed baseline | Not recorded — no numerical measurement was supplied. Do not read this as a failure; it means the fine-grained battery-draw exercise was not part of the reported result. |

## Part 3 — Game Mode, wake, waiting state

| Check | Answer |
|---|---|
| 3.1 Game Mode | Pass (client-observed): bindings arrived, glyph detection behaved correctly, per the client's report that all applicable items passed. Exact log line (`detected deck` vs. `detected fallback`) not available to this session. |
| 3.2 Wake | Pass (client-observed). |
| 3.3 Waiting state on real hardware | Pass (client-observed). Specific timings (30-second give-up, notice latency) were not supplied and are not recorded. |
| Every glyph in the hint bar | Pass (client-observed) — no stale Xbox glyph reported. |

## Part 4 — the full loop

| Item | Result |
|---|---|
| Real pairing | Pass (client-observed) |
| Manual address entry with the OSK | **Failed.** See defect below. |
| Real stream: launch, resume, failure, quit | Pass (client-observed) |
| L1/R1 tab switch and grid context restore | Pass (client-observed) |
| Motion in flight | Pass (client-observed) |
| Blur cost | Not recorded — no measurement was supplied; treat as not exercised to the level `REVIEW-CHECKLIST.md` 2.5/Part 4 asks for. |
| Panel appearance | Not recorded — panel type (OLED vs. LCD) unknown to this session. If the Deck used is OLED, LCD-specific appearance remains unvalidated regardless of this session's outcome. |

## The OSK defect (sole observed issue)

**Expected:** focusing or activating a text field in Game Mode invokes SteamOS
text entry so the field can be completed with controller-only operation.

**Observed:** the text field receives or requests text entry, but the SteamOS
on-screen keyboard does not appear.

**Impact:** manual address entry cannot be completed controller-only in Game
Mode. Any other Bulan flow requiring text input may be affected, but this
session has no evidence establishing broader reproduction.

**Status:** reproducible client-observed defect, not diagnosed, not fixed. See
`BUGS.md`.

## Language-list defect — closed

The Settings → UI → Language crash could not be reproduced during this Deck
session. The client has reviewed this result and considers the defect closed
and fixed; it no longer appears in `BUGS.md`. No root cause was identified —
the closure rests on the client's judgment that the issue no longer occurs,
not on a diagnosed fix.

## Skipped, and why

- **2.2 Banding on LCD** — Deck panel type not recorded; if OLED, this check
  could not have been meaningfully completed.
- **Part 4 panel appearance (LCD)** — same reason.
- Numeric measurements throughout (2.5 battery draw, 3.3 exact timings, blur
  cost) — none were supplied by the client; recorded as not measured rather
  than assumed passing.

## Defects or decisions arising

- New: SteamOS on-screen keyboard does not appear for Bulan text fields — see
  `BUGS.md`.
- Unchanged: Settings → UI → Language reported crash — still open, still not
  reproduced.

## Conclusion

The private-v1 route works on the Steam Deck across pairing, streaming, the
core loop, physical-controller navigation, and Game Mode, with no regressions
against `REVIEW-CHECKLIST.md` Parts 1–3. The route does not yet fully work:
manual address entry in Game Mode cannot be completed, because the SteamOS
on-screen keyboard is not invoked for Bulan's text field. This is now the
primary remaining blocker for Phase F.
