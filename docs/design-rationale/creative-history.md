---
kind: design-rationale
authority: historical-evidence
status: superseded-directions
read_when:
  - investigating-a-past-creative-direction
history_policy: append-only
---

# Creative history — superseded directions and original exploration

Preserved so the project's creative evolution is not lost, and so no agent
re-derives a direction that was already rejected. **None of this is current
authority.** `bulan-creative-brief.md` owns current direction and
`DESIGN-SYSTEM.md` owns current rules and values.

## Where the old section numbers went

QML source comments and older documents cite the creative brief by section
number — "brief §4", "brief §6 rule 1", "brief §8 verbatim". Those numbers were
from the original single-document brief. The content did not change; it moved:

| Old citation | Content | Now in |
|---|---|---|
| §1–§2 | Positioning, reflection concept | `bulan-creative-brief.md` |
| §3 | Logo directions | This file |
| §4 | Colour system, *Depth, Not Darkness* | `DESIGN-SYSTEM.md` |
| §5 | Typography | `DESIGN-SYSTEM.md` |
| §6 | Motion language and the four motion rules | `DESIGN-SYSTEM.md` |
| §7 | Sound identity | `bulan-creative-brief.md` (cue list), `DESIGN-SYSTEM.md` (constraints) |
| §8 | Voice and copy | `bulan-creative-brief.md` |
| §9 | Visual references | This file |
| §10 | Deliverables | `bulan-creative-brief.md` |
| §11 | Guardrails | `bulan-creative-brief.md`, with the invariants in `AGENTS.md` |

The motion rules keep their numbering inside `DESIGN-SYSTEM.md`, so "brief §6
rule 1 — never bounce twice" is still rule 1 there.

## The three original logo directions

Explored at the start of the project. The instruction to lead with Direction A,
or to combine it into the final mark, is **superseded**. No agent should infer a
replacement mark from these sketches.

### Direction A — The Reflected Moon *(superseded; the original lead direction)*

- A crescent above, its mirrored reflection below, separated by a thin horizon
  line.
- The lower reflection softer, blurred, or broken into horizontal bands — this
  *is* the stream.
- Reads at 24 px as a simple stacked lens shape.
- The two nested crescents can imply a subtle **B**.

**Why it is superseded.** It is no longer the lead mark and must not be used as
the assumed solution for new screens or artwork. The horizontal corner wordmark
`app/res/bulan_logo_horiz.svg` is final for its role, and centred-logo screens
wait on client-supplied vectors rather than an enlarged corner mark.

### Direction B — Crescent-as-Play

- The crescent's inner concave curve cut so the negative space resolves into a
  play triangle.
- Ties moon directly to streaming; very strong at small sizes.
- **Risk:** drifts into generic media-player territory. The crescent weight has
  to stay heavy enough to remain distinctive.

### Direction C — Bulan the Companion *(deferred past v1)*

- The moon as a soft, near-featureless character, expressive only through a
  single arc and its glow.
- No face, or the barest suggestion of one.
- Enables delightful motion: blinks while scanning for a host, stretches during
  connect, dozes when idle.

A mascot needs a full expression set — idle, searching, connected, error,
sleeping — and that illustration load belongs after the app ships. The original
pairing with Direction A is no longer binding, because Direction A is
superseded; any future mascot-to-mark relationship needs a new client decision.

### Surface treatment, as originally specified for all three

Keep the mark's interior nearly empty. If texture is needed, use the most
reductive option available: fine concentric arcs following the crescent's curve,
a sparse dot grid at very low contrast, or a single soft gradient across the
crescent body, light edge to dark.

**No illustration, no detail, no craters.** The mark should survive being
reduced to a solid silhouette without losing its identity.

## Visual reference themes

Search themes used to gather reference. They describe **atmosphere**, not
instruction; the hard specs are in `DESIGN-SYSTEM.md`.

**A. Reflection** — `moon reflection on still water at night`. The founding
image: a light source above, a softer double below, a horizon between them. The
Direction A lesson was that a reflection is *broken* — banded, rippled,
imperfect — while the horizon stays quiet. That still informs the atmosphere. It
is **not** an instruction to restore a lower reflected crescent to a new mark.

**B. The mark, reductive** — `minimal geometric moon phases design`,
`pure circle geometry logo`. A crescent built from two overlapping circles is
the most reductive form available and scales to 24 px without adjustment. One
weight, no ornament, no craters.

**C. Where playfulness lives** — `rounded 3d shapes`, `soft volume minimal
form`. **Ignore the palettes in these references.** Take only the form language:
generous corner radii, soft ambient shadow, gentle volume.

**D. Sleek** — `dark mode minimal ui design`. Take the amount of empty space,
and how few elements compete for attention.

**E. Depth without contrast** — `blurred gradient mesh background`,
`indigo twilight sky gradient`. Not one of these is a solid fill — that is the
argument for grain-and-gradient in a single glance.

## Original decisions

| Question | Decision |
|---|---|
| Component library | **Custom components throughout.** No stock Qt Quick Controls styling |
| Mascot (Direction C) | **Deferred past v1.** The primary mark should leave room for one, but not depend on it |
| Dark theme approach | **No true black.** Depth comes from gradient, grain, glow, and blur |

All three are still in force and are restated where they now belong:
`AGENTS.md` for custom components, `DESIGN-SYSTEM.md` for the dark theme,
`ROADMAP.md` for the mascot deferral.

## Deliverables removed from scope

**Steam Deck artwork set** — 460×215 capsule, 920×430 wide capsule, 1920×620
hero, transparent logo PNG. **Removed 2 August 2026.** Client decision: Steam
library artwork is not a Bulan deliverable at all. Game artwork comes from the
host PC, and Bulan renders what the host provides. The **app icon** is
unaffected and still required, because the non-Steam application entry is
Bulan's own.

## Values that evolved

| Item | Original | Now | Why |
|---|---|---|---|
| Focus duration | `140 ms` | `180 ms` | The brief's figure read slightly too fast on the OLED Deck, 28 July 2026 |
| Screen-transition blur | Read as opacity falling away during travel, the inexpensive interpretation | A real runtime blur | The client rejected the cheap reading on 2 August 2026 and accepted the performance cost knowingly |
| Grain opacity | Brief range 2–4% | `0.03`, confirmed | Predicted to be invisible on the OLED panel; the prediction was wrong |
| Caption size | `16 px`, predicted to fail | `16 px`, confirmed | The legibility calculation that said it would fail was wrong |
