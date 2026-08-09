---
kind: current-state
authority: repository-state
read_when:
  - session-start
history_policy: replace-not-append
last_verified_commit: 686cda70
---

# Bulan — current state

**Verified 9 August 2026.** Inspect Git before relying on this — it is a
snapshot, not an authority on what Git says.

Replaced, never appended to. Past states are in Git history, past evidence in
`docs/validation/`.

## Repository

| Item | State |
|---|---|
| Branches | `master` and `bulan`, both at this session's tip. `master` is now the primary integration branch |
| Remote | `origin` only. **Nothing is pushed** — client decision, 9 August 2026. `origin/master` is still the old upstream mirror; `origin/bulan` is behind |
| Working tree | Clean |
| Task branch | None. `fix-deck-osk` was merged and is gone |
| Active task | **None.** No `TASK-BRIEF.md` exists |

**The branch model changed.** `master` was a pristine upstream mirror; it is now
Bulan's default branch, fast-forwarded to `bulan` with no history rewritten.
`bulan` is kept until the client retires it. `AGENTS.md` owns the rule.

## Where the product is

**Alpha v0.0.1.** The version the app reports is its own `0.0.1`, not the
inherited Moonlight `6.1.0`. `ROADMAP.md` owns scope and phase.

The 9 August 2026 session did Alpha polish and identity: post-transition
entrances on `FirstRun`, `HostDiscovery` and `PairView` via a new shared
`EntranceMotion.qml`; a shorter transition fade so travel leads; the version
identity; Bulan branding on display-only surfaces; and a Bulan README.

## Validation status

**Passed, this session, on the Windows review station:** Qt 6.9.3 / MSVC Release
build; `qmllint` on every changed QML file, adding no new warning class; the
version flag, Win32 resource, window title and About all reporting Bulan and
`0.0.1`, checked against the built binary; `FirstRun` and `HostDiscovery`
settling correctly after their entrance; `python scripts/context-audit.py`.

**Not established.** No Deck ran this session, so nothing on hardware was
checked — including the entrances and the shortened fade in Game Mode, and cold
boot. The macOS bundle and the WiX MSI were not built; their metadata changes
are statically inspected only. LCD-specific appearance remains unvalidated.

Latest reports: `docs/validation/2026-08-08-osk-diagnosis-and-resolution.md`,
`docs/validation/2026-08-05-private-v1-deck.md`.

## Open blockers

None. `BUGS.md` is empty.

## Next action

1. **Push, once the client says so.** `master` and `bulan` are both ready.
2. **Rename the GitHub repository to `Bulan`**, with its description and default
   branch — a client action in repository settings. Documentation and package
   metadata already name the post-rename URL; GitHub redirects the old one.
3. **A Deck session** to see the new entrances and the transition on hardware,
   and an LCD unit for the remaining panel-appearance gap.
