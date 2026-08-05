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

## SteamOS on-screen keyboard does not appear for Bulan text fields

| Field | Value |
|---|---|
| Status | **Open — reproduced on Steam Deck, not diagnosed, not fixed** |
| Reported | 5 August 2026, by the client |
| Affected commit | `173c0497`, not independently confirmed by this session |
| Surface | At minimum, first-run manual address entry in Game Mode |

**Symptom.** A focused text field in Game Mode should invoke SteamOS text
entry. Instead the OSK never appears, so it cannot be completed
controller-only. Blocks the Part 4 full-loop exit condition and the matching
`ROADMAP.md` Phase F criterion.

**Evidence.** Client-observed, 5 August 2026 Deck session; no log available.

**Next investigation.** How the field requests focus/text input; whether Steam
Input sees a valid request; Flatpak/Game Mode context; comparison with
upstream fields; whether `Steam + X` works (untested).

**Related.** `docs/validation/2026-08-05-private-v1-deck.md`.
