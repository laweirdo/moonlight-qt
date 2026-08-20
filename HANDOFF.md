---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: ea46a661
---

# Bulan — current state

**Verified 20 August 2026.** A snapshot — inspect Git before relying on it.
Replaced, never appended to; past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| `master` | At `ea46a661`, level with `origin/master`. Untouched by this work |
| Task branch | **`fix/persistent-atmosphere-splash-motion`**, cut from `master` at `ea46a661`. **No commits yet** |
| Working tree | **Dirty on that branch — the whole change is uncommitted, awaiting client sign-off** |
| Remote | `origin` only. **Nothing pushed, nothing merged** |
| Active task | `TASK-BRIEF.md`; plan in `docs/superpowers/plans/2026-08-20-persistent-atmosphere-splash-motion.md` |
| Other branches | `bulan` at `177a58bd`; `codex/rework-core-shell` excluded by client decision, 15 August 2026 |

## Where the product is

**Alpha v0.0.1**; `ROADMAP.md` owns scope and phase. Everything merged on 16 and
17 August still stands — see those days' commits and their validation reports.

Uncommitted on the task branch, 13 QML files and one C++ comment:

- One persistent atmosphere, owned by the window, behind every screen. Routes no
  longer paint their own, so navigation moves the screens over a world that
  holds still.
- Two blur scopes: navigation blurs the screens alone; a modal blurs the whole
  scene — atmosphere, screens, crescent, launch proxy and hint bar — and stands
  the navigation blur down so nothing is blurred twice. Only the five window
  modals moved out, into a new `overlayFrame`, where they stay sharp.
- The startup logo fades in over the new `motionSplashFadeMs` (300), holds, and
  fades out; the destination appears only after it reaches nothing. A skip
  reverses the fade from wherever it is instead of cutting. The splash accepts
  input only in the two phases that can act on it.

`DESIGN-SYSTEM.md` owns the rules; `FLOW.md` needed no change, as the routes
themselves are unchanged.

## Validation status

Full evidence: `docs/validation/2026-08-20-persistent-atmosphere-splash-motion.md`.

**Passed.** Release build, exit 0. `qmllint` exit 0 on all thirteen files,
categories compared against `master` in a clean worktree. Six settled screens
and one route popup captured and inspected. Gradient and vignette preference
toggles verified against the persistent instance. A real launch, no review
hooks, still runs the whole splash sequence and lands on first run.

**Not established.** **No in-flight frame was captured** — no splash fade, no
skip, no mid-transition, no rapid push/back, and nothing about where a press
during the fade-out goes now that the splash declines it. **The window-modal
blur was never seen**, and it is the riskiest part of the change. **No Deck
ran**, in either mode. Grain-off is not judgeable on a desktop grab.

## Open blockers

Client sign-off on the uncommitted change, and the visual checks above, which
need a person at the machine. `BUGS.md` holds three open defects; none is
touched here.

## Next action

1. **Client review of the built change**, especially the four consequences the
   validation report raises: a route popup no longer blurs the ground behind it;
   two screens' content overlaps briefly mid-transition; the quit dialog's own
   hints now render through a blurred bar; and a press during the splash
   fade-out is no longer consumed by the splash.
2. **Sign-off, then commit** in the three stages the plan names.
3. **A Deck session**, Desktop and Game Mode. Nothing in this pass or the three
   before it has run on the target device.
4. **The three unrun startup cases** — remembered host offline, remembered UUID
   gone, no remembered host.
