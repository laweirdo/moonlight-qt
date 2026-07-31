# Active task — the host settings menu

Status: **in progress; label spacing and host-settings overlay merged; startup-toolbar repair outstanding**

This is the single active product work order. It is temporary and does not
override `AGENTS.md`, the creative brief, the flow, or the roadmap.

Read `HANDOFF.md` for live repository state. The prepared baseline below must be
rechecked and replaced with the implementation branch's exact baseline when the
session starts.

## Objective

Complete three independently reviewable changes, in this order:

1. Apply the client-approved host-label spacing correction.
2. Replace SELECT's temporary host-details panel with the host settings menu.
3. Remove upstream's toolbar from the first half-second of launch without
   removing it from screens that still need it.

The host settings menu is an active product task and a functional regression
from upstream, not a numbered defect. The startup toolbar is an unintended
behavior and remains an open defect.

## Branch and baseline

Completed implementation branch: `codex/host-settings-menu`, fast-forwarded
into `bulan` and `origin/bulan` at `6e345967ce463a0511bae70ce9e5c08e80ca85df`
on 31 July 2026.

Exact baseline: `bulan` and `origin/bulan` at
`6a6ffa7ec677c3a630613c68cfd55ed5a708a082`, verified after fetching
`origin/bulan` on 31 July 2026.

The branch was created from the clean integration branch. Its accepted commits
are `394a2870` (label spacing), `1c941ed5` (host-settings overlay), and
`6e345967` (the separately scoped quit-confirmation defect record).

## Scope

### 1. Host-label spacing

**Completed and merged:** `394a2870` changed `Bulan.hostTileLabelGap` from 56
to 46 and kept the duplicated review token synchronized. No other carousel
visual change was made.

The accepted implementation changed `Bulan.hostTileLabelGap` from **56 to 46**.

The client judged the current gap 10 pixels too large after reviewing the rebuilt
carousel. This is the only approved visual change to that screen in this task.

### 2. Host settings menu

**Completed and merged:** `1c941ed5` replaces SELECT's temporary details panel
with the approved overlay. It records a stable host UUID before dispatching an
action, restores focus to the same carousel host on B, guards fake-host review
mode before a real-host lookup, and uses the approved glass popup treatment.

SELECT now opens the approved host menu rather than the panel that showed what
upstream's “View Details” showed.

The confirmed private-v1 menu contents are:

| Item | Behavior already available |
|---|---|
| View All Apps | Host/app navigation behavior retained from upstream |
| Test Network | Existing Moonlight connectivity test and result signal |
| Host details | `actHostSettings()` in `HostCarousel.qml` |
| Wake PC | `actWake()`; visible only for an offline, wakeable host |
| Forget PC | Host removal behavior in `PcView.qml` |

The initial menu decision deferred both Rename PC and Test Network. On 31 July
2026, the client superseded the Test Network part of that decision after
reviewing the upstream menu: Test Network is included in private v1. Rename PC
remains deferred to v1.x because it requires text entry and Deck keyboard work.
Both upstream behaviors must remain intact.

### 3. Startup toolbar defect

Upstream's toolbar is visible for approximately **567 ms** during launch. It
starts visible and is not hidden until the first Bulan screen activates.

The intended repair is to start the toolbar hidden and require screens that use
it to claim it explicitly. This is small in code but broad in effect because
`AppView`, `SettingsView`, and `PcView` currently rely on the visible default.

## Non-goals

- Connecting state
- Game grid redesign
- Game detail or launch redesign
- Screen-transition implementation
- Wake waiting overlay
- Deck-specific glyph artwork
- Changes to carousel travel, easing, layout, or accepted empty space
- Discovery, pairing, streaming, or video infrastructure changes
- General cleanup of upstream screens

## Decisions already settled

- The carousel rebuild is finished and accepted.
- The menu is an overlay over the carousel. Its background is blurred, and B
  closes it directly back to the same focused host.
- The mockup's glass-effect border is the visual precedent for this and future
  popup menus.
- For an offline host, Host Details and Forget PC remain available. Wake PC is
  shown only when that host is wakeable. Actions that cannot work are omitted
  rather than displayed disabled.
- Forget PC requires confirmation because accidental controller activation
  would otherwise remove the stored host relationship.
- Test Network is included in private v1, superseding its initial deferral. It
  uses Moonlight's existing connectivity test rather than new diagnostic
  infrastructure.
- Rename PC remains deferred to v1.x because it carries text-entry and
  Steam-keyboard work.
- “Forget PC” is the approved wording. Bulan forgets the host; the host does not
  forget Bulan.
- All permanent interface, token, focus, validation, and client-decision rules
  in `AGENTS.md` apply unchanged.
- Retain upstream discovery, pairing, streaming, and platform infrastructure for
  v1. Replace individual UI components only when the existing component cannot
  express the approved design.
- Deck-specific glyph art is not required for v1 because the practical glyph
  shapes are identical to the current XInput set.

## Client decision gate

Resolved on 31 July 2026. The overlay form, offline-host contents, Forget PC
confirmation, Test Network inclusion, and Rename PC deferral are recorded under
*Decisions already settled*. No host-menu design question remains open.

## Implementation risks

### Fake hosts are not real action targets

`MOONLIGHT_FAKE_HOSTS` swaps a review model into the carousel, but host actions
address real machines by position in the real host list. A fake position can
therefore refer to the wrong real machine.

The menu needs one guard covering every real-host action. It must explain the
review-mode limitation on screen rather than silently returning.

### A closing component must not restore stale global state

A dying settings popup previously left A dead on the carousel. A menu or overlay
may declare that it is open, but it must not own or restore global navigation
state after the screen has moved on.

### One invalid QML property can hide the real failure

A screen that fails to load can drop the application onto upstream's interface,
which resembles a stale build. Run `qmllint`, confirm the build stamp, and read
the application log before diagnosing from appearance.

### The toolbar default affects inherited screens

Starting the toolbar hidden fixes Bulan's launch, but any inherited screen that
does not explicitly show it may silently lose navigation. Validate every screen
that is supposed to retain the toolbar.

## Acceptance criteria

- `hostTileLabelGap` is 46 in the live token source and any duplicated review
  token remains synchronized.
- SELECT opens the approved host menu for the focused real host.
- Every visible menu item is reachable and operable by controller.
- B closes the menu and returns visible focus to the same host.
- Fake-host mode cannot act on a real machine and gives visible feedback.
- Host actions cannot target a different machine from the one shown.
- Forget PC uses the approved wording and confirmation behavior.
- No upstream toolbar is visible during startup.
- `AppView`, `SettingsView`, `PcView`, and other inherited toolbar screens still
  show and operate their toolbar when reached.
- The implementation satisfies the applicable invariants in `AGENTS.md`.
- No discovery, pairing, or streaming behavior changes.

## Required validation

1. Run `qmllint` on every changed QML file.
2. Build on the selected review machine using its `BUILDING-*.md` procedure.
3. Confirm the build stamp and inspect the log for QML errors.
4. Load all fake-host presets: `none`, `one`, `two`, `offline`, `mixed`, and
   `many`.
5. Exercise menu navigation with controller input in online, offline, unpaired,
   and review-mode states.
6. Prove every menu branch maps to the focused real host. Do not perform a
   destructive real-host action without the client's explicit participation.
7. Measure or capture launch from the first visible frame and confirm the
   toolbar never appears.
8. Visit every inherited screen that should retain a toolbar.
9. Report any hardware check not performed; this task does not inherently
   require a Steam Deck.

## Documentation to update at completion

- `SPEC-host-carousel.md` — menu behavior, state model, accepted compromises,
  and validation evidence
- `BUGS.md` — close the startup-toolbar defect only after it is verified
- `ROADMAP.md` — completed milestone summary and next item
- `HANDOFF.md` — final branch, commit, test status, blockers, and next action,
  written after implementation and validation are complete

Delete or archive this file after its task is complete and its durable decisions
have moved to their permanent homes.

## Required reading

1. `AGENTS.md`
2. `HANDOFF.md`
3. `BUGS.md`
4. `SPEC-host-carousel.md`
5. `ROADMAP.md`
6. The `BUILDING-*.md` file for the review machine

## Next action

Implement the startup-toolbar repair as the third and final logical change in
this task. It must begin with the toolbar hidden, make every inherited screen
that needs it claim it explicitly, capture the first visible launch frames, and
verify controller navigation on each retained-toolbar screen. Keep this brief
active until that work and its durable documentation are complete.
