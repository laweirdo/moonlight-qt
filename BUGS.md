# Bulan — open defects

**Current as of:** 30 July 2026

This file contains acknowledged, open unintended behavior only. Active product
work belongs in `TASK-BRIEF.md`; scope and sequencing belong in `ROADMAP.md`;
upstream redesign findings remain historical in `UI-AUDIT.md`.

## Startup toolbar appears before Bulan

**Status:** Open

**Impact:** High visual impact during every cold launch; no data-loss or
streaming impact

**Milestone:** Phase B, within the active host-settings work order

**Priority:** Complete before the game-grid rebuild

### Reproduction

1. Fully stop the application.
2. Start a Bulan build whose initial screen is the host carousel.
3. Watch from the first visible window frame until the carousel appears.

The inherited Moonlight toolbar is visible before the Bulan screen hides it.

### Evidence

The client first reported the upstream layout remnants during launch on
28 July 2026. A frame probe then recorded:

```text
t=...297  stackView completed, toolBar.visible=true
t=...864  after push,          toolBar.visible=false
```

The toolbar remained visible for approximately **567 ms**, long enough to read
as a different interface appearing before Bulan.

The investigation was recorded in documentation commit `f32ec616`.

### Current diagnosis

The application window's `header` is the toolbar in `app/gui/main.qml`. It has
no initial `visible` value, so it starts shown. The first Bulan screen cannot
hide it until that screen has been pushed and activated after early
initialization.

The likely repair is to start the toolbar hidden and require every inherited
screen that needs it to show it explicitly.

### Uncertainty

The cause of the launch exposure is established. The remaining uncertainty is
the repair's blast radius: inherited screens such as `AppView.qml`,
`SettingsView.qml`, and `PcView.qml` currently rely on the toolbar's visible
default. Missing one could silently remove navigation from that screen.

### Next action

Implement this as the third independently reviewable change in
`TASK-BRIEF.md`, after the host-label spacing and host-settings menu:

1. Start the toolbar hidden.
2. Make each inherited toolbar screen claim it explicitly.
3. Capture launch from the first visible frame.
4. Visit every screen that should retain a toolbar.
5. Close this defect only after both the startup and inherited-screen checks
   pass.

### Relevant files and commits

| Reference | Relevance |
|---|---|
| `app/gui/main.qml` | Owns the toolbar and its initial visibility |
| `app/gui/HostCarousel.qml` | Hides the toolbar after the initial screen activates |
| `app/gui/AppView.qml` | Inherited screen that currently relies on the visible default |
| `app/gui/SettingsView.qml` | Inherited screen that currently relies on the visible default |
| `app/gui/PcView.qml` | Inherited screen that currently relies on the visible default |
| `app/gui/StreamSegue.qml`, `app/gui/QuitSegue.qml`, and CLI segue files | Existing explicit visibility transitions that must remain correct |
| `TASK-BRIEF.md` | Active implementation scope and acceptance criteria |
| `f32ec616` | Commit that recorded the measured defect |

There is no fix commit yet.
