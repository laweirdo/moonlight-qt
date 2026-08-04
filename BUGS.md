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

## Opening the Language list is reported to crash the application

| Field | Value |
|---|---|
| Status | **Open — reported, not reproduced, not fixed** |
| Reported | 3 August 2026, by the client |
| Affected commit | `173c0497` or earlier |
| Surface | Settings → UI → Language |

**Symptom.** The client reports the application crashes when the Language option
is opened.

**Evidence.** Four routes were tried against the same build and none reproduced
it:

1. The review hook opening the popup directly
   (`MOONLIGHT_SETTINGS_REVIEW_CATEGORY=ui`, `..._ROW=language`).
2. Selecting a *different* language, which runs `retranslate()` — it succeeded
   and loaded French.
3. The client's own navigation path: normal launch, Menu to open settings, down
   the rail to UI, right into the rows, A on Language.
4. Scrolling the full 25-entry list to the bottom and back.

Every `LANG_*` value the list offers exists in `streamingpreferences.h`'s enum,
so an undefined enum reaching the C++ property is ruled out. No crash trace,
`Critical`, or QML error appeared in any log.

**Next investigation.** Needs from the client: whether the application dies when
the list *opens* or when an entry is *picked*, whether the window vanishes or
freezes, and the `%TEMP%\Moonlight-*.log` from a run that actually crashed.

**Related.** `docs/validation/2026-08-03-private-v1-draft.md`, `SettingsShell.qml`.
