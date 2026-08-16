---
kind: current-authority
authority: open-defects
read_when:
  - investigating-a-defect
history_policy: replace-not-append
---

# Bulan — open defects

**Open, acknowledged unintended behavior only.** A resolved defect leaves this
file: its evidence goes to the validation report, retrospective, or commit that
closed it. Scope and sequencing belong in `ROADMAP.md`; current repository state
in `HANDOFF.md`; upstream redesign findings in `UI-AUDIT.md`.

Three carried over from the polish task's brief when it was retired on
16 August 2026. None is a regression from that work; each predates it.

## Front-facing screens still speak upstream's words

The four configuration warnings in `main.qml` and the CLI routes' messages name
XWayland, `QT_QPA_PLATFORM` and "hardware accelerated video decoder" to the
player — which `bulan-creative-brief.md` §5 forbids. They were converted to
Bulan panels on 15 August 2026 **without touching the text**, by client
decision: a placeholder is a thing that ships by accident, so upstream's wording
stands until replaced.

**Blocked on the client**, who writes the replacements, and the confirm and
dismiss wording on those panels with them.

## `BulanTokens.qml` disagrees with the runtime

The proof sheet's copy of the tokens claims to be the source of truth and draws
body and caption a weight lighter than the application actually does. Two copies
of the same numbers, and the wrong one is labelled authoritative.

Fix is to make it read the `Bulan` singleton or stop existing — a call the
client has not made.

## No d-pad glyph, so a real binding cannot be hinted

`ControllerGlyph` covers face buttons, shoulders, triggers and start/select, but
not the d-pad. A Left/Right action therefore has no glyph to show, which is why
the settings slider popup shows only its back hint. **This is a
controller-first gap**: the hint bar exists to stop a real binding going
unmentioned, and here it cannot mention one.
