# Task brief — launch and quit experience

**Opened:** 1 August 2026
**Branch:** `launch-quit-experience`, cut from `bulan` at `f54d3648`
**Roadmap item:** Phase B item 3 — *Launch and quit experience*
**Current stage:** Stage 6 complete — awaiting final client acceptance

This file is temporary. It owns the scope, stage boundaries, and acceptance
criteria of this task. It does not override `AGENTS.md`,
`bulan-creative-brief.md`, `FLOW.md`, or `ROADMAP.md`. It is removed after the
client accepts the completed work and its durable decisions have moved to the
appropriate specifications.

At Stage 0, `HANDOFF.md` was deliberately left unchanged. `AGENTS.md` requires
live repository-state documentation to be written last, after implementation
and validation facts are known; Stage 6 now records those facts there.

---

## Corrected product flow

The client corrected the former plan before this task began:

- There is **no Game Detail screen planned**. It is explicitly excluded.
- **A launches or resumes directly** from the selected game in Recent or
  Library.
- **X opens `GameOptionsOverlay` as its intended private-v1 destination**, not
  as a temporary substitute.
- B closes the options popup and restores the same tab, selected game, and
  Library scroll position.
- Popup Play/Resume uses the same selected-game launch path as A.
- Quit Game uses the quit path.
- If another game is running, quit-and-switch waits for a successful quit
  before it enters the selected-game launch path. A failed quit does not launch
  the replacement game.
- General screen transitions remain Phase B item 4. The selected-game motion
  from Recent or Library belongs to this item because it is part of launching,
  not general navigation polish.

The corrected authority is now recorded in `FLOW.md`, `ROADMAP.md`, and
`SPEC-game-grid.md`. The earlier detail-screen direction remains only as
explicitly labelled superseded history in the specification.

---

## Design evidence and its limits

### Supplied normal-launch mockup

The client supplied a **1867×1153 raster attachment** in the task conversation
for the ordinary selected-game launch state. Measurements were normalized to
the Deck's 1280-wide coordinate system: its destination tile is approximately
**202×302**, spanning **x ≈ 540..741** and **y ≈ 142..444** after that
normalization. Its centre is therefore approximately the screen centre on x.
The attachment is vertically cropped and its aspect ratio does not match the
Deck's 1280×800 panel, so the y position and height are less certain than the x
measurements.

These are measurements from an attached raster, not a repository vector or an
editable layout source. Antialiasing, the vertical crop, aspect mismatch, and
normalization make the edges approximate. The numbers are evidence for the
destination composition, not permission to introduce permanent raw visual
values or to treat a screenshot pixel as a design token. If implementation
needs a new duration, size, radius, opacity, or spacing token, the value is
proposed to the client and reviewed before it enters `Bulan.qml`.

### Missing visual states

No mockups were supplied for quit, launch warnings, launch failure, quit
failure, or quit-and-switch waiting. Their first implementation is inferred
**provisionally** from:

- `bulan-creative-brief.md` — warm/cool palette, brief voice, controller-first
  behaviour, one-settle motion, and recoverable failure;
- the established custom Bulan popup and panel language in
  `BulanQuitConfirmation.qml`, `HostSettingsOverlay.qml`, and
  `GameOptionsOverlay.qml`; and
- the existing grid, hint-bar, focus, and atmosphere patterns.

Those inferences are review material, not permanent visual decisions. The
client reviews each affected stage before any commit. No missing mockup is
filled by silently inventing a project-wide token.

`design/navigation-flow-board.png` is known stale and has no reproducible
editable source. Stage 0 does not alter it. `FLOW.md` records the exact changes
required whenever the board can be genuinely re-exported.

---

## In scope

### Selected-game launch

- One launch path shared by:
  - A on the selected Recent game;
  - A on the selected Library game;
  - popup Play/Resume; and
  - automatic Direct Launch when a host opens.
- The transition begins at the exact rendered artwork rectangle currently
  visible on screen and moves toward the normal-launch destination documented
  above.
- Recent is covered at rest and while its rank-based travel, neighbour scale,
  focus scale, and tab opacity are in flight.
- Library is covered at rest, while focus-follow scroll is in flight, and after
  the grid has been manually scrolled. Its `Flickable.contentY`, clip viewport,
  focus scale, artwork crop, and rounded mask are part of the source geometry.
- The handoff has no one-frame jump and never shows the source tile and its
  transition copy simultaneously.
- Returning after launch failure preserves the same AppView instance, tab,
  selected game, and Library scroll.

### Launch surface

- Replace the stock visible `StreamSegue.qml` treatment with a custom Bulan
  launch/resume experience.
- Preserve the existing streaming session contract and lifecycle.
- Replace stock warning and error presentation encountered on this route with
  controller-safe Bulan treatment, without exposing front-facing protocol or
  port language.
- Keep every warning and failure recoverable and return focus visibly.

### Quit surface

- Replace the stock visible `QuitSegue.qml` treatment with a custom Bulan quit
  experience.
- Preserve Quit Game, quit failure, and quit-and-switch.
- Quit-and-switch preserves the existing early `Session` construction and
  `lastPlayed` stamping unless the client separately approves a semantic
  change. The prepared Session must not start and the launch surface must not
  appear until the quit operation reports success. On success it enters the
  same launch path as A and popup Play/Resume. On failure, a direct-A origin
  restores the retained grid context, while a popup Play/Resume origin restores
  Game Options.

### Options contract

`GameOptionsOverlay` keeps all four accepted actions and their existing enable
rules:

- Play/Resume
- Quit Game
- Hide Game
- Direct Launch

Direct Launch in the popup remains a preference toggle. When that preference
later auto-starts a game on host entry, the automatic start uses the same
stable game identity, source-tile resolution, and launch transition as a manual
launch.

---

## Required implementation contracts

### Stable identity

Model row, Recent rank, and delegate address are not durable game identity.
Every pending launch or options action is keyed by the existing `appid` role.

- A captures the selected app ID.
- Opening Game Options captures app ID and origin tab, not only a source row.
- Activating Play/Resume re-resolves the current row and rendered delegate from
  that app ID.
- Direct Launch resolves the configured app ID and makes that game the launch
  source before transition capture.
- A model insertion, removal, Recent reorder, or popup delay must not redirect
  an action to a different game.

No backend redesign is needed or allowed for this. The stable `appid` role
already exists; an O(n) QML lookup at action time is acceptable because it runs
once, not per frame.

### Geometry before session mutation

Source geometry and identity are captured **before**
`AppModel::createSessionForApp()`. That call stamps `lastPlayed`, emits a model
change, and can immediately reorder Recent. Creating the session first can move
the source tile, change the selected Recent rank, and produce the exact
one-frame jump this task must prevent.

For quit-and-switch, this means capture the pending game's source contract
before the existing early Session construction, then hold both safely while
quit runs. It does **not** defer Session construction or `lastPlayed` stamping
until quit success; changing that established semantic is outside this task.

The source contract records, once:

- stable app ID and current source row;
- origin tab;
- the actual rendered artwork/focus-ring item;
- its screen-space rectangle after every inherited transform;
- the intersection with the active clip viewport;
- the matching source-local crop rectangle; and
- the effective starting opacity.

The mapping uses the rendered item and a top-level transition layer. It does
not reconstruct screen coordinates from rank, row, `x`, or `contentY` by hand.
The captured visual preserves the currently displayed crop, mask, fallback,
border, and focus treatment.

### State and interruption

- The underlying `AppView` stays on the stack; it is not recreated for launch.
- Tab, selected app IDs, and Library scroll remain owned by that retained view.
- A launch-busy guard prevents duplicate sessions and queued transitions.
- Input interrupts the visual animation by completing it immediately; it does
  not queue a second settle. B cancelling an already requested launch would be
  a new product decision and is not assumed here.
- Capture, component creation, session creation, and push failures all release
  source hiding, clear busy state, restore focus, and leave a usable grid.
- If the app disappears before capture completes, the animation falls back
  safely instead of retaining a destroyed delegate or launching a replacement
  row.

### 60 fps budget

The Steam Deck target is **60 fps**, so each frame has **16.67 ms**.

- Map geometry and resolve model identity once before animation.
- No per-frame JavaScript, `mapToItem()`, model scan, delegate creation, layout
  calculation, image decode, Canvas repaint, or object churn.
- Use one transient captured texture and one declarative animation clock, not a
  second live `GameTile` tree with another asynchronous image and mask.
- Freeze the captured texture after the source/proxy handoff; do not keep the
  nested artwork mask rendering live for the whole transition.
- Animate transforms and opacity rather than repeatedly changing anchors,
  width/height, image crop, or Flickable geometry.
- General background and grid motion hidden behind the transition must not
  continue doing avoidable per-frame work.
- Measure frame timing on the available Windows GPU during development, then
  verify on Steam Deck before claiming the 60 fps target passed.

---

## Explicit exclusions

- **Game Detail**, in any form.
- Phase B item 4's general screen transitions outside the selected-game launch
  handoff.
- Redesigning discovery, pairing, host monitoring, session negotiation,
  streaming, quitting, or persistence backends.
- Changing the Recent or Library visual design, sorting rule, tile aspect
  ratio, or controller navigation except where stable launch-source recovery
  requires retaining the same game.
- Removing or redesigning Hide Game or Direct Launch.
- The deferred stream overlay and its unvalidated summon binding.
- Onboarding, settings, host settings, empty-library design, and unrelated
  defects.
- Any push, merge, branch deletion, or upstream remote operation.

Nearby issues are recorded and raised; they are not repaired as side effects.

---

## Stages and allowed files

The original work order required a client stop before every commit. After
accepting Stage 1, the client explicitly authorized Stages 2–6 to proceed with
one approval only after all work was complete. Files not named for a stage
remain out of scope. A stage may use fewer files than its allowance.

### Deterministic review matrix

Stage 1 is review infrastructure, before any transition implementation or
visual redesign. Without a real host it must expose deterministic routes for:

- launch from Recent;
- launch from Library;
- launch from a scrolled, lower-row Library selection;
- resume;
- launch warning;
- launch failure;
- quit;
- quit-and-switch success;
- quit failure;
- a valid source tile and the no-source fallback; and
- repeatable animation-cycle triggering, so Stage 2 motion can be replayed
  without restarting or relying on network timing.

Prefer extending the existing `MOONLIGHT_GAME_REVIEW` string and its already
available global QML context property. Parse and dispatch the additional cases
in QML, so `app/main.cpp` does not change. If that proves impossible, stop and
ask before expanding the allowed files; this brief does not pre-authorize the
C++ change. The stage adds deterministic state and dispatch only—no visual
redesign and no claim that a fake outcome proves a real stream.

| Stage | Outcome | Allowed files |
|---|---|---|
| **0 — authority and work order** | Correct `ROADMAP.md`, `FLOW.md`, and the durable grid decision; create this brief. No runtime change. | `ROADMAP.md`, `FLOW.md`, `SPEC-game-grid.md`, `TASK-BRIEF.md` |
| **1 — deterministic review infrastructure** | Expose the matrix above through QML-only fake/review state. No visual or product change. | `app/gui/AppView.qml`, `app/gui/GameOptionsOverlay.qml`, `app/gui/StreamSegue.qml`, `app/gui/QuitSegue.qml`, `app/gui/main.qml`, and `app/qml.qrc` only if a review-only QML helper is required |
| **2 — source contract and selected-game transition** | Stable app-ID dispatch, exact geometry from Recent/Library/scrolled Library, one source/proxy handoff, interruption and rollback, ordinary A launch wired through it. | `app/gui/AppView.qml`, `app/gui/GameTile.qml`, `app/gui/main.qml`, one new launch-transition QML component, `app/qml.qrc`; `app/gui/Bulan.qml` and `app/gui/BulanTokens.qml` only for client-approved tokens |
| **3 — launch surface, warnings, and failure** | Custom Bulan launch/resume surface; provisional warning/failure treatments; popup Play/Resume and automatic Direct Launch share Stage 2. | `app/gui/StreamSegue.qml`, `app/gui/AppView.qml`, `app/gui/main.qml`, new launch-only QML components, `app/qml.qrc`; token files only after approval |
| **4 — quit and quit-and-switch** | Custom quit surface, recoverable quit failure, and success-gated start/visible handoff into the shared launch path, preserving early Session creation. | `app/gui/QuitSegue.qml`, `app/gui/GameOptionsOverlay.qml`, `app/gui/AppView.qml`, `app/gui/main.qml`, new quit-only QML components, `app/qml.qrc`; token files only after approval |
| **5 — integration and performance** | Controller/focus recovery, interruption races, model-update races, one-frame/duplicate review, repeatable cycles, and 60 fps measurement; only defects within the preceding surfaces are corrected. | The QML/resource/token files explicitly allowed in Stages 1–4 |
| **6 — final validation and documentation** | Record actual evidence, reconcile durable documents, update repository state last, and remove this brief only after client acceptance. | `ROADMAP.md`, `FLOW.md`, `SPEC-game-grid.md`, `HANDOFF.md`, `BUGS.md` only if a genuine open defect was accepted, and `TASK-BRIEF.md` |

No C++ or backend file is allowed by this plan. If implementation proves one is
necessary, work stops and the client decides whether to expand scope before
that file is touched. In particular, Stage 1 does not authorize
`app/main.cpp`.

### Implementation record

| Stage | Commit | Result |
|---|---|---|
| 0 | `94d92bf4` | Corrected the product flow and defined this work order. |
| 1 | `dc0bc8a9` | Added the fake-only deterministic launch/quit review matrix. |
| 2 | `c3625cba` | Added stable app-ID dispatch, exact source capture, and the selected-game transition. |
| 3 | `74a20505` | Replaced the visible launch, warning, and failure treatment with custom Bulan QML. |
| 4 | `b01a408e` | Replaced the quit surface and added success-gated quit-and-switch using one prepared Session. |
| 5 | `30f7cad4` | Hardened cross-surface return routing, repeated-cycle cleanup, Session lifetime, dismissal idempotence, and progress animation cost. |
| 6 | This documentation stage | Records final evidence and repository state; the brief remains until client acceptance. |

---

## Acceptance criteria

1. A on a selected game in Recent and in Library launches or resumes directly
   when no different game is running; otherwise it enters quit-and-switch. No
   excluded intermediate screen exists.
2. The transition starts from the exact visible selected artwork rectangle,
   including an in-flight Recent move, an in-flight Library scroll, and a
   manually scrolled Library.
3. The normal-launch destination matches the supplied raster composition within
   its measurement uncertainty: approximately 202×302 at
   x ≈ 540..741 / y ≈ 142..444 in normalized Deck coordinates, with y treated
   as approximate because the attachment is vertically cropped.
4. There is no one-frame position/scale jump and no frame containing both the
   original source artwork and its transition copy.
5. Launch is keyed by stable app ID and geometry is captured before session
   creation can stamp `lastPlayed` and reorder Recent.
6. Returning from launch failure restores the same tab, selected game, Library
   scroll, visible focus, and controller operation.
7. X opens the intended `GameOptionsOverlay`; B closes it over the same game.
8. Popup Play/Resume and automatic Direct Launch use the same source-tile and
   launch contracts as A.
9. Hide Game and Direct Launch retain their accepted menu behaviour and enable
   rules.
10. Quit Game uses the custom quit path. Quit-and-switch may preserve the
    existing early Session construction and `lastPlayed` stamp, but that
    Session does not start and the launch surface does not appear until quit
    succeeds. Direct-A failure returns to the retained grid context; popup
    Play/Resume failure returns to Game Options.
11. Launch warnings, launch failure, quit progress, and quit failure use custom
    Bulan components, controller-safe focus, and front-facing copy without
    protocol, port, or stack-trace language.
12. All visible components are custom. Every visual value comes from an existing
    approved token or a new token explicitly approved after client review.
13. Input interrupts motion; repeated confirm cannot start duplicate sessions or
    queue animations.
14. The transition meets 60 fps / 16.67 ms on the target Steam Deck before that
    result is claimed. Windows measurements are supporting evidence only.
15. Discovery, pairing, session, streaming, persistence, and quit backend
    behaviour remain unchanged.
16. Stage 1 exposes every deterministic review case listed above without a real
    host, including valid/no-source fallback and repeatable animation cycles.

---

## Validation record and current limits

### Performed

- Repository search, complete diff inspection, `git diff --check`, and status
  checks at each stage boundary.
- `qmllint` on every changed QML file. It exits 0; warnings fall into
  `[import]`, `[index]`, `[missing-property]`, `[unqualified]`,
  `[unresolved-type]`, and `[use-proper-function]` around registered runtime
  types, dynamic properties/callbacks, and existing delegate patterns.
- Repeated Qt 6.9.3 / MSVC Release builds on the Windows review station. The
  final build ran `qmlcachegen` over the revised lifecycle source and linked
  successfully with only the pre-existing `LNK4291` warning.
- The full deterministic review matrix rendered at 1280×800 composition:
  launch from Recent/Library/scrolled Library, resume, warning, launch failure,
  valid/no-source fallback, repeated cycles, quit, quit failure,
  quit-and-switch success/failure, and popup-origin switch-then-launch failure.
  Final logs contained no critical QML/runtime errors; the known
  `ToolTip attached property` warning remained.
- Visual inspection of the supplied normal-launch composition, repeated-cycle
  return to the same retained grid, and popup-origin launch failure's visible
  **Back to options** target.
- Windows `QSG_RENDER_TIMING` supporting evidence: 84 steady frames after
  excluding cold-start and screenshot frames, p95 1 ms, maximum 13 ms, zero
  frames over 16.67 ms. Hardware was an RTX 4070 Ti SUPER using Qt's basic
  render loop; this is not target-device proof.
- A roughly 51-cycle repeated-launch run showed no upward working-set trend:
  first five warm samples averaged 168.4 MiB, last five 162.3 MiB.
- Independent read-only performance and lifecycle audits. Their findings were
  fixed and re-audited: manually created route cleanup, per-frame JavaScript
  dot motion, replay-pop state, production Session cleanup ownership, and
  repeated failure dismissal.

### Not performed

- Steam Deck Desktop Mode and Game Mode validation.
- OLED/LCD appearance and target-device frame timing.
- Real-stream launch, resume, warning, failure, quit, and quit-and-switch.
- Physical-controller review of every affected path.
- Live Windows controller-style interaction: the in-app automation attempt
  could not obtain approval to control the local Moonlight window before its
  timeout. No input result is inferred from static key handlers or screenshots.

None of those outstanding checks may be reported as passed from Windows,
screenshots, source inspection, or fake data.

---

## Git and review boundary

- Stage 1 was reviewed and accepted before commit. The client then authorized
  Stages 2–6 to proceed without intermediate approval and requested one final
  approval after all tasks were complete.
- One independently reviewable change per approved commit.
- No push is authorized by this brief.
- No merge into `bulan` is authorized by this brief.
- `HANDOFF.md` is updated last, after final validation and repository state are
  known, never in anticipation of them.
