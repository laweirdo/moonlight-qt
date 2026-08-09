# Bulan

A UI/UX-focused fork of [Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt),
built for the Steam Deck.

Moonlight already solved streaming. Bulan rebuilds everything in front of it:
a controller-first, console-shaped interface for the handheld it actually runs
on, on top of Moonlight's mature streaming foundation.

> **Moonlight is a tool. Bulan is a place you arrive.**

*Bulan* is Indonesian for "moon". The moon doesn't make its own light — it
reflects the sun, the same way Bulan doesn't render your game, it reflects your
PC.

---

## Status — Alpha v0.0.1

**Early, private alpha.** The core loop works end to end: cold launch,
onboarding, pairing, host selection, game selection, launch, quit and back
again — validated on Steam Deck hardware.

It is not finished software. Polish and validation are ongoing, it is not
publicly released, and it has not been tested outside a small number of
machines. Expect rough edges.

## What Bulan changes

Everything the player sees:

- **A custom interface.** No stock Qt controls anywhere on a Bulan screen —
  every button, list, slider, toggle and dialog is drawn from scratch.
- **Controller-first navigation.** Every screen is fully operable with a gamepad
  alone. That is a product invariant, not a feature.
- **Onboarding.** A first-run path that finds your PC, with a manual-address
  escape hatch.
- **A host carousel** for choosing between machines, and a **game library** per
  host.
- **A settings shell** with spatial controller navigation.
- **A design system** — colour, type, spacing, motion and atmosphere as tokens,
  so the whole app moves and reads as one thing.
- **Motion and atmosphere.** Screens surface rather than cut. Content arrives
  rather than appearing.
- **Steam+X for text entry** on the Steam Deck, which is the supported way to
  type into Bulan's fields in Game Mode.

## What remains Moonlight

Bulan did not invent a streaming stack and does not pretend to. Everything about
how a stream reaches your PC and comes back to the screen is Moonlight's
engineering:

- host discovery
- pairing
- the streaming session itself
- video decode, codecs, audio, input forwarding and platform infrastructure

Bulan built the front door.

## Target and limitations

- **The Steam Deck is the principal alpha target** — both the 7-inch LCD and the
  7.4-inch OLED, though LCD-specific visual validation is still outstanding.
- **Controller-only operation is a product invariant.** Anything needing a mouse
  or trackpad is a defect.
- Other platforms still build, because Moonlight's do, but they are not what
  Bulan is designed or validated for.
- HDR, a stream overlay, a sound pack, ambient background motion and a merged
  multi-host library are **deferred**, not present. See
  [ROADMAP.md](ROADMAP.md) for what is in scope and what is not.

## Building

Bulan builds the same way Moonlight Qt does, with machine-specific recipes:

- **[BUILDING-DECK.md](BUILDING-DECK.md)** — Steam Deck via Flatpak. **Start
  here** if you want to run Bulan on the hardware it is for.
- [BUILDING-WINDOWS.md](BUILDING-WINDOWS.md) — Windows, Qt 6.9.3 and MSVC
- [BUILDING-MAC.md](BUILDING-MAC.md) — macOS

Those documents own the procedures; they are not duplicated here.

## Upstream and licence

Bulan is an **unofficial fork**. It is **not** an official Moonlight release and
is not affiliated with or endorsed by the Moonlight Game Streaming Project.
Please do not report Bulan's bugs to them.

Upstream is [moonlight-stream/moonlight-qt](https://github.com/moonlight-stream/moonlight-qt),
and it deserves the credit for everything that makes streaming work.

Moonlight Qt is licensed under the **GNU General Public License v3.0**. Bulan
carries the same licence, and its full text is in [LICENSE](LICENSE). Upstream's
copyright notices and attribution remain intact.

## Development

Bulan's documentation is structured for both people and coding agents.
[AGENTS.md](AGENTS.md) is the project authority and the place to start — it
describes the rules, the branch model and which document owns which kind of
truth.

The current-state and authority documents:

| Document | Owns |
|---|---|
| [HANDOFF.md](HANDOFF.md) | Current repository and validation state |
| [ROADMAP.md](ROADMAP.md) | Release scope, phase order, exit conditions |
| [FLOW.md](FLOW.md) | Navigation states and transitions |
| [DESIGN-SYSTEM.md](DESIGN-SYSTEM.md) | Colour, type, motion, spacing, tokens |
| [bulan-creative-brief.md](bulan-creative-brief.md) | Positioning, concept, voice |
| [BUGS.md](BUGS.md) | Open defects |
| [REVIEW-CHECKLIST.md](REVIEW-CHECKLIST.md) | The Steam Deck review procedure |

Historical evidence — decisions, validation reports, design rationale — lives in
[docs/](docs/).
