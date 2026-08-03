# Bulan - open defects

**Current as of:** 2 August 2026

This file contains acknowledged, open unintended behavior only. Active product
work belongs in `TASK-BRIEF.md` when one exists; scope and sequencing belong in
`ROADMAP.md`; upstream redesign findings remain historical in `UI-AUDIT.md`.

## Opening the Language list is reported to crash the application

**Reported by the client, 3 August 2026. Not reproduced. Not fixed.**

Settings → UI → Language. The client reports the application crashes when the
option is opened.

Four routes were tried against the same build and none reproduced it:

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

**What would narrow it:** whether the application dies when the list *opens* or
when an entry is *picked*, whether the window vanishes or freezes, and the
`%TEMP%\Moonlight-*.log` from a run that actually crashed.

## Closed

Both carousel round-trip defects recorded here on 2 August 2026 — the game grid
forgetting its per-host context, and memory growing on every grid entry — were
fixed on the `v1-finalisation` branch the same day and are closed.

The fix and its evidence are in `HANDOFF.md`. The reusable lesson from it is in
`docs/retrospectives/DEBUGGING-LESSONS.md` under "A restore that succeeds and
then quietly undoes itself".

Neither has been seen on Steam Deck hardware, because no Deck session has
happened yet. That is a standing validation gap recorded in `HANDOFF.md`, not a
defect.
