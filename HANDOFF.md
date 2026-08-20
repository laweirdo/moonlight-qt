---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: ce98ebc2
---

# Bulan — current state

**Verified 20 August 2026.** A snapshot — inspect Git before relying on it.
Replaced, never appended to; past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| `master` | Carries the atmosphere and splash work, **pushed and level with `origin/master`** |
| Task branch | None. `fix/persistent-atmosphere-splash-motion` merged fast-forward 20 August 2026 on client acceptance, then deleted; never pushed |
| Working tree | Clean apart from this file |
| Active task | **None.** The brief was deleted on acceptance |
| Remote | `origin` only — `laweirdo/bulan-qt`. Pushed 20 August 2026 on client authorization |
| Other branches | `bulan` at `177a58bd`; `codex/rework-core-shell` excluded by client decision, 15 August 2026 |

## Where the product is

**Alpha v0.0.1**; `ROADMAP.md` owns scope and phase. Everything merged on 16 and
17 August still stands — see those days' commits and their validation reports.

Merged 20 August 2026, in three stages:

- `bb700d9a` — one persistent atmosphere, owned by the window, behind every
  screen. Routes are transparent and none paints its own, so navigation moves
  the screens over a world that holds still. Blur split into its two real
  scopes: navigation blurs the screens alone, a modal blurs the whole composed
  scene and stands the navigation blur down so the two can never nest. The five
  window modals sit in a new `overlayFrame`, outside what they blur.
- `2ab9a5f2` — the startup logo dissolves in over the new `motionSplashFadeMs`,
  holds, dissolves out, and only then hands off. A skip reverses the dissolve
  from wherever it is rather than cutting. The splash accepts input only in the
  two phases that can act on it.
- `e1b5246c`, `ce98ebc2` — documentation.

`DESIGN-SYSTEM.md` owns the rules. `FLOW.md` needed no change: the routes
themselves are unchanged. The plan and its orchestration handoff are in
`docs/superpowers/plans/`.

## Validation status

Full evidence: `docs/validation/2026-08-20-persistent-atmosphere-splash-motion.md`.

**Passed**, against the committed tree. Release build exit 0; `qmllint` exit 0 on
all thirteen changed QML files, categories compared against `master` in a clean
worktree; six settled screens and one route popup captured and inspected; the
gradient and vignette preference toggles verified against the persistent
instance; a real launch with no review hooks running the whole splash sequence
and landing on first run.

**Not established.** **No in-flight frame was ever captured** — no splash fade,
no skip during fade-in or hold, no mid-transition, no rapid push/back, and
nothing about where a press during the fade-out goes now that the splash
declines it. **The window-modal blur was never seen**, and it is the riskiest
part of the change; it is also where the quit dialog's now-blurred hints would
show. **No Deck ran**, in either mode. Grain is not judgeable on a desktop grab.

## Open blockers

None blocking. `BUGS.md` holds three open defects, two waiting on the client;
none of them is touched here.

## Next action

1. **A Deck session**, in Desktop and Game Mode. Nothing in this pass, or the
   three before it, has run on the target device, and Game Mode is where Steam
   Input sits between the hardware and the application.
2. **The visual checks no screenshot could reach** — the splash dissolve and its
   skip, a window modal over a settled screen, and rapid push/back. All four
   need a person watching, and all four are consequences the client accepted
   without seeing.
3. **The three unrun startup cases** — remembered host offline, remembered UUID
   gone, no remembered host.
4. **Two controllers at once**, still never driven by real hardware.
5. `HANDOFF.md` and `DESIGN-SYSTEM.md` both sit close to their context budgets.
   Trim before adding.
