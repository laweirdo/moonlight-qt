# Bulan — open defects

**Current as of:** 31 July 2026

This file contains acknowledged, open unintended behavior only. Active product
work belongs in `TASK-BRIEF.md`; scope and sequencing belong in `ROADMAP.md`;
upstream redesign findings remain historical in `UI-AUDIT.md`.

## Carousel B opens an inherited quit confirmation

**Status:** Open

**Impact:** High for controller-first operation. Pressing B from the carousel
opens a confirmation that does not use Bulan's popup language, and the client
reported that its controls do not respond to the XInput controller.

**Milestone:** Follow-up task after the completed host-settings work order

### Reproduction

1. Start on the Bulan host carousel.
2. Press B on an XInput controller.
3. The inherited "Are you sure you want to quit?" confirmation appears.
4. Try to navigate or dismiss it with the controller.

### Evidence

The client reported this during the 31 July 2026 real-controller review of the
host-settings build. The host carousel correctly receives B while the new host
menu is open, but B at the root carousel is handled by `stackView` in
`app/gui/main.qml`, which opens `quitConfirmationDialog`.

### Current diagnosis

`quitConfirmationDialog` is an existing `NavigableMessageDialog` with the
upstream visual treatment. It is not a Bulan glass popup and, on the reported
controller path, does not expose a usable controller focus route. This is not
a host-settings-menu behavior and must not be repaired as incidental cleanup
in that task.

### Next action

Create a separate, controller-first Bulan quit confirmation. It must use the
approved popup glass language, make the focused choice visible, default to the
safe cancel choice, and let B dismiss it reliably. Validate it with a real
controller before closing this defect.

### Relevant files

| Reference | Relevance |
|---|---|
| `app/gui/main.qml` | Opens the inherited confirmation for root-level B/Escape |
| `app/gui/NavigableMessageDialog.qml` | Existing upstream dialog implementation |
| `app/gui/HostSettingsOverlay.qml` | Reference implementation for Bulan's popup glass and controller focus |
| `AGENTS.md` | Controller-first and custom-component requirements |
