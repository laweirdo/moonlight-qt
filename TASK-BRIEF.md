# Task brief — general screen transitions (Phase B item 4)

**Branch:** `general-screen-transitions`, cut from `bulan` at `7da2ce60`.
**Status:** implemented and locally validated at `78c05eee`. **Not accepted by
the client**, not merged, not pushed. Two decisions below are awaiting the
client's confirmation — see "Open for the client".

This brief is temporary. `AGENTS.md` owns permanent rules, `ROADMAP.md` owns
sequencing, `FLOW.md` owns navigation edges, `HANDOFF.md` owns repository state.

## Objective

Give ordinary screen-level navigation in the completed Phase B core route one
coherent, reusable vertical transition built on the existing 220 ms token.

Accepted motion direction (creative brief §6, "Screen transition"): content
surfaces vertically, 220 ms, fast and restrained, one settle, no repeated
bounce, and input always interrupts.

## Route inventory

The application has exactly one `StackView`, `stackView` in
`app/gui/main.qml:189`. Every screen-level route change goes through it.

### In scope — ordinary screen navigation

| Edge | Call site |
|---|---|
| Host carousel → game grid | `HostCarousel.qml:515` `stackView.push(view)` |
| Game grid → host carousel (B / Esc) | `main.qml:123` `goBack()` → `pop()` / `pop(null)` |
| Game grid → host carousel (PC lost) | `AppView.qml:261` `stackView.pop()` |
| Any screen → settings and back | `main.qml:359` `navigateTo()` → `push(url)` / `pop(existingItem)` |

`SettingsView.qml` is inherited and unredesigned. It receives the shared stack
transition. **Do not redesign it.**

### Out of scope — must keep current behavior

| Edge | Call site |
|---|---|
| Launch segue push | `AppView.qml:1081` (`pushLaunchSegue`), `AppView.qml:2127` |
| Launch review replay pop | `AppView.qml:1453` |
| Segue → segue replace | `StreamSegue.qml:102` (already `StackView.Immediate`) |
| Segue pops | `StreamSegue.qml:139`, `StreamSegue.qml:165`, `QuitSegue.qml:75`, `QuitSegue.qml:87` |
| CLI entry routes | `CliStartStreamSegue.qml:24`, `:87`, `CliPair.qml`, `CliQuitStreamSegue.qml` |

The launch composition is the accepted `LaunchTransition.qml` proxy, which is a
sibling of `stackView` in `main.qml:287` and is unaffected by stack transitions.
The stack operation underneath it must not gain competing motion.

## Accepted decisions

1. **One mechanism.** Declare `pushEnter` / `pushExit` / `popEnter` / `popExit`
   transitions once on `stackView` in `main.qml`. Do not attach per-screen
   animations.
2. **Direction.** Push: the incoming screen rises into place from below while
   the outgoing screen continues upward. Pop is the exact mirror: the incoming
   screen settles down from above, the outgoing screen descends. Forward and
   back therefore read as one reversible movement.
3. **Duration.** `Bulan.motionTransitionMs` only. No literal `220` anywhere, and
   no per-route duration.
4. **"Slight motion blur"** is expressed as opacity falling off during travel.
   Do **not** add a shader, `MultiEffect` blur, or any continuously animated
   effect. This is the established inexpensive precedent.
5. **Travel distance** reuses the accepted `Bulan.space3xl` (64) through a named
   derived token. Do not invent a new raw number.
6. **Easing** is ease-out without overshoot. `Bulan.motionOvershoot` belongs to
   focus motion; a screen must not bounce.
7. **Opt-out.** Launch and quit route operations pass `StackView.Immediate`,
   following the precedent already set at `StreamSegue.qml:102`. This is the
   minimal compatibility adjustment that keeps the accepted launch and quit
   experience free of competing stack motion.
8. **First push.** The initial `push(initialView)` in
   `main.qml:232` must not animate — there is nothing to transition from.
9. `Bulan.qml:167-169` still calls `motionTransitionMs` unused. Correct that
   comment; do not restate project history in it.

## File ownership

Owned and editable:

- `app/gui/main.qml`
- `app/gui/Bulan.qml`
- `app/gui/AppView.qml`
- `app/gui/StreamSegue.qml`
- `app/gui/QuitSegue.qml`
- `app/gui/HostCarousel.qml`
- `app/gui/CliStartStreamSegue.qml`

Read-only unless an ownership expansion is requested: everything else, including
all Markdown. Opus owns documentation.

## Scope exclusions

No redesign of the selected-game launch transition, `StreamSegue.qml`, or
`QuitSegue.qml`. No new launch, resume, quit, or quit-and-switch behavior. No
SELECT / Host Settings decision. No Game Options redesign. No onboarding, Phase
C, Phase D empty/failure states, or Phase E settings redesign. No sound, ambient
motion, shaders, or decorative effects. No backend, discovery, pairing,
persistence, streaming, or quit-contract change. No unrelated refactoring. No
Steam Deck artwork, icons, or packaging.

## Stage acceptance criteria

**Stage 2 — mechanism.** Transitions declared once on `stackView`; uses
`Bulan.motionTransitionMs`; no duplicated route timing; completion and
interruption are deterministic; no backend contract touched; `qmllint` clean on
changed QML.

**Stage 3 — integration.** Every in-scope edge animates; push and pop mirror
each other; launch, quit, and CLI routes are unchanged in behavior; focus and
selection recover; rapid navigation cannot create duplicate or stranded routes.

**Stage 4 — hardening.** Rapid input never leaves controls dead or focus
stranded; logs show no new critical QML or runtime error; and the transition
neither introduces route accumulation nor degrades any return state that the
pre-transition baseline preserved.

The original wording of this criterion — that selected game, tab, and Library
scroll must "survive the return" to the carousel — was a drafting error. The
baseline never preserved them on that edge, so it was never a property this task
could preserve. Both facts are now recorded in `BUGS.md`. The criterion above is
the one this task is actually accountable for.

## Required checks

1. `git diff --check`
2. `qmllint` on every changed QML file
3. Windows Release build per `BUILDING-WINDOWS.md` (`qmake` + `scripts\jom.exe
   release`, then redeploy the exe), confirming `qmlcachegen` ran over each
   revised QML
4. Deterministic review runs using the existing fake infrastructure:
   `MOONLIGHT_FAKE_HOSTS`, `MOONLIGHT_OPEN_APPS_FOR_HOST`, `MOONLIGHT_FAKE_GAMES`,
   `MOONLIGHT_GAME_REVIEW`, `MOONLIGHT_SCREENSHOT`, `MOONLIGHT_SCREENSHOT_DELAY_MS`
5. Rapid and repeated input during transitions; repeated navigation cycles
6. Return-state verification: host, game, tab, Library scroll, overlay origin
7. Runtime log inspection for new critical warnings or errors

Do not build new test infrastructure for this task.

## Open for the client

Neither blocks the branch; both are visual judgements that only a live look can
settle.

1. **"Slight motion blur" is not a blur.** Brief §6 asks for one. A real blur on
   a moving full screen is the single most expensive thing this transition could
   do, and the work order rules out shaders and runtime blur for it. It is built
   as opacity falling away during travel, which is the standard inexpensive
   reading. If the client wants an actual blur, that is a separate decision with
   a real Steam Deck cost.
2. **How far a screen travels: 64 px.** Reused from the accepted `space3xl`
   spacing token rather than invented, so no new visual value was introduced
   without the client. It is a deliberately short rise. Easy to change.

## Known validation limits

Carried forward from `HANDOFF.md` and not resolved here: no Steam Deck
validation, no OLED or LCD appearance review, no real stream, no physical
controller, and no live human judgement of motion in flight. A Windows frame
timing result is supporting evidence only.
