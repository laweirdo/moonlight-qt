pragma Singleton
import QtQuick 2.9

// -----------------------------------------------------------------------------
// Bulan design system — the single source of truth for the whole application.
//
// Registered as a QML singleton in main.cpp, so any view can `import Bulan 1.0`
// and reference `Bulan.accentPrimary`, `Bulan.sizeTitle`, etc.
//
// Values are the Figma variables from
//   figma.com/design/RvcIMzlxM9tKBOuTviQu7P  (?view=variables)
// exported to tokens-2.json and transcribed verbatim. Two documented departures:
//
//  1. familyDisplay is Fraunces, from the design mockup. The Figma `type.familyUi`
//     variable still says Inter for everything; the header face has not been
//     updated there yet.
//  2. Gradients are not present in the export at all — Figma variables cannot
//     express gradients — so those come from the creative brief.
//
// UNITS: Figma sizes are px at 1280x800. Always bind these to `font.pixelSize`,
// never `font.pointSize` — pointSize goes through Qt's DPI conversion and comes
// out roughly a third too large.
// -----------------------------------------------------------------------------

QtObject {

    // --- Colour (figma: colour/base) -----------------------------------------
    readonly property color bgBase:        "#0D1024"
    readonly property color bgBaseOled:    "#080A18"
    readonly property color bgSurface:     "#171B33"
    readonly property color accentPrimary: "#FFD9A0"
    readonly property color accentGlow:    "#FFB865"
    readonly property color secondary:     "#8A93C2"
    readonly property color textPrimary:   "#F4EDE2"
    readonly property color textSecondary: "#A8AECB"
    readonly property color statusSuccess: "#7FC7A8"
    readonly property color statusError:   "#E08B7D"
    readonly property color transparent:   "transparent"

    // Derived surfaces. Not in Figma — needed for interaction states, which the
    // token file does not define. Rules stated so they can be replaced when it
    // does: hover lifts the surface toward secondary, pressed sinks it toward
    // base, hairline is the quietest visible division on bgSurface.
    readonly property color surfaceHover:   "#1E2440"
    readonly property color surfacePressed: "#10142A"
    readonly property color hairline:       "#2A3050"
    readonly property real  disabledOpacity: 0.38

    // --- Type (figma: type/base) ---------------------------------------------
    readonly property string familyUi: "Inter"

    // The one body weight. Client review, 3 August 2026: selected rows were
    // drawn semibold against medium neighbours, and the weight jumping as
    // focus moved read as the text itself changing rather than the selection
    // moving. Focus is carried by colour, the amber ring and the left bar --
    // it does not also need to reflow the glyphs.
    //
    // Set as the window-wide default in main.qml, so a Text that says nothing
    // about weight already gets this; the token exists for the places that
    // used to say `font.bold` and now have to say something.
    readonly property int weightBody: Font.Medium
    // From the mockup, not the variables file. See header.
    readonly property string familyDisplay: "Fraunces"

    readonly property int sizeDisplay: 56
    readonly property int sizeTitleLg: 40
    readonly property int sizeTitle:   32
    readonly property int sizeBodyLg:  26
    readonly property int sizeBody:    22
    readonly property int sizeLabel:   18
    readonly property int sizeCaption: 16

    readonly property int lineHeightDisplay: 64
    readonly property int lineHeightTitleLg: 48
    readonly property int lineHeightTitle:   40
    readonly property int lineHeightBodyLg:  34
    readonly property int lineHeightBody:    30
    readonly property int lineHeightLabel:   24
    readonly property int lineHeightCaption: 22

    readonly property real trackingDisplay: -1.2
    readonly property real trackingTitle:   -0.5
    readonly property real trackingBody:     0
    readonly property real trackingCaption:  0.2

    // --- Spacing (figma: spacing/base) ---------------------------------------
    readonly property int space2xs: 4
    readonly property int spaceXs:  8
    readonly property int spaceSm:  12
    readonly property int spaceMd:  16
    readonly property int spaceLg:  24
    readonly property int spaceXl:  32
    readonly property int space2xl: 48
    readonly property int space3xl: 64

    readonly property int layoutScreenMarginX: 48
    readonly property int layoutScreenMarginY: 32
    readonly property int layoutSafeInset:     16
    readonly property int targetMin:           64
    readonly property int targetRowHeight:     88

    // --- Radius (figma: radius/base) -----------------------------------------
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 14
    readonly property int radiusLg: 20
    readonly property int radiusXl: 28
    // Sentinel meaning "fully rounded". Clamp against the item's own height
    // rather than passing it straight to Rectangle.radius.
    readonly property int radiusFull: 999

    // --- Gradients (creative brief, not Figma) -------------------------------
    readonly property color gradientBaseTop:    "#151A38"
    readonly property color gradientBaseBottom: "#080A18"

    // --- Atmosphere (creative brief §4, "Depth, Not Darkness") ---------------
    // Consumed by Atmosphere.qml, the shared ground under every screen. Not in
    // Figma: the brief states these as ranges, and Figma variables cannot
    // express the textures they drive.
    //
    // The two PNGs referenced by Atmosphere carry *shape only* — pattern in the
    // alpha channel, flat RGB. Strength is applied entirely by these opacities,
    // so retuning the look never means regenerating a texture.

    // Brief says 2–4%. This is the midpoint. The brief also lists grain
    // intensity under "Still Open" pending a test on real Deck hardware, so
    // treat this as a starting point rather than a settled value.
    readonly property real atmosphereGrainOpacity:    0.03

    // Brief says "barely-there ... ~8%".
    readonly property real atmosphereVignetteOpacity: 0.08

    // Per-effect kill switches. The brief makes "every background effect must be
    // individually disableable" a non-negotiable. Settings > UI now exposes real,
    // persisted toggles for all three (StreamingPreferences.atmosphere*Enabled,
    // private v1 finalisation stage 5) and Atmosphere.qml reads those instead of
    // these tokens. Kept here only as the documented out-of-the-box default that
    // StreamingPreferences::reload() mirrors -- nothing at runtime reads these
    // three properties any more.
    readonly property bool atmosphereGradientEnabled: true
    readonly property bool atmosphereVignetteEnabled: true
    readonly property bool atmosphereGrainEnabled:    true

    // --- Popup glass ---------------------------------------------------------
    // Client-approved for the host-settings overlay on 31 July 2026, and the
    // visual precedent for popup menus moving forward. The background remains
    // recognisable as context but cannot compete with the menu above it.
    readonly property int  popupBackdropBlurRadius:   48
    readonly property real popupBackdropBlurStrength: 1.0
    readonly property real popupScrimOpacity:          0.62
    readonly property real popupGlassSurfaceOpacity:   0.92
    readonly property real popupGlassBorderOpacity:    0.28

    readonly property color popupScrim:
        Qt.rgba(bgBaseOled.r, bgBaseOled.g, bgBaseOled.b, popupScrimOpacity)
    readonly property color popupGlassSurface:
        Qt.rgba(bgSurface.r, bgSurface.g, bgSurface.b, popupGlassSurfaceOpacity)
    readonly property color popupGlassBorder:
        Qt.rgba(textSecondary.r, textSecondary.g, textSecondary.b,
                popupGlassBorderOpacity)

    // --- Motion (creative brief §6) -------------------------------------------
    // Durations and scales are the brief's stated values. Not in Figma: variables
    // cannot express motion.
    // 140 was the brief's figure and read a touch too fast on the real panel --
    // judged on a Steam Deck OLED, 28 July 2026. 180 is the client's call from
    // that session, not a recalculation.
    readonly property int  motionFocusMs:    180
    readonly property int  motionPressMs:     80
    readonly property real motionFocusScale: 1.04
    readonly property real motionPressScale: 0.97

    // "ease-out with barely-there overshoot". Easing.OutBack's own default is
    // 1.70158, which overshoots by about 10% and reads as a bounce -- far more
    // than the brief wants. 0.7 lands around 3%: enough to feel sprung, not
    // enough to look playful about it. The brief gives no number, so this is the
    // one motion value here that is interpretation rather than transcription.
    readonly property real motionOvershoot:  0.7

    // Screen transition, brief §6. Drives LaunchTransition.qml and the
    // stackView push/pop transitions in main.qml.
    readonly property int  motionTransitionMs: 220

    // Screen transition travel distance, brief §6. Reuses the accepted
    // space3xl (64) rather than inventing a new raw number for how far a
    // screen rises or descends during a stack transition.
    readonly property int  motionTransitionRise: space3xl

    // The opacity half of a stack transition, which finishes before the
    // travel does. Client decision, 9 August 2026: with real transition blur
    // now carrying the sense of movement, a fade running the full duration
    // flattened the intended "surfacing" feel -- the screen spent its whole
    // arrival semi-transparent, so what the eye read was a cross-dissolve
    // with some drift rather than a surface rising into place.
    //
    // Ending the fade early means the last stretch of the movement is pure
    // travel, at full opacity, which is the part that reads as surfacing. The
    // fade is kept rather than removed because both screens are opaque and
    // full-bleed: without it, the outgoing screen would stay solid the whole
    // way off, showing two stacked backgrounds for the duration.
    //
    // Derived from motionTransitionMs rather than set independently, so the
    // two can never drift apart.
    readonly property int  motionTransitionFadeMs: motionTransitionMs / 2

    // Screen transition blur. Client override, 2 August 2026 review: the
    // opacity falloff alone was not enough, and real runtime blur is
    // accepted with the Deck performance cost to be measured after private
    // v1. Deliberately its own pair of tokens rather than reusing
    // popupBackdropBlurStrength/Radius -- the popup glass sits still at a
    // fixed strength behind a stationary menu, while this exists only for
    // the ~220ms a screen is actually travelling and has to read as motion
    // blur, not glass. Half the popup's own numbers: strong enough to read
    // as blur on a moving screen, restrained enough not to look like the
    // popup treatment when there is no popup involved.
    readonly property real motionTransitionBlurStrength: popupBackdropBlurStrength / 2
    readonly property int  motionTransitionBlurRadius:   popupBackdropBlurRadius / 2

    // Grid entrance: Recent and Library tiles rising from below in a short
    // cascade, replacing the old horizontal slide-into-rank motion the
    // client saw as "swiping in from the side, way too quickly" (2 August
    // 2026 review). Timed off the screen transition itself so the grid
    // reads as coming to life once the screen has arrived, not during it.

    // How long the screen transition takes to visually settle before the
    // first tile starts rising. Reuses motionTransitionMs itself rather
    // than a new number -- the wait IS "let the screen finish arriving".
    readonly property int  motionGridEntranceDelayMs: motionTransitionMs

    // How long one tile takes to rise into place. motionFocusMs, the same
    // clock the grid's own reactive motion already runs on, so the
    // entrance does not introduce a fourth timing feel next to focus,
    // press and screen motion.
    readonly property int  motionGridEntranceRiseMs: motionFocusMs

    // Delay between one tile's rise starting and the next's. A fifth of
    // motionFocusMs: close enough together to read as one cascade, far
    // enough apart that consecutive tiles are visibly sequential rather
    // than simultaneous.
    readonly property int  motionGridEntranceStaggerMs: motionFocusMs / 5

    // How many stagger steps the cascade counts before the remainder of
    // the grid rises together as one wave. Without a cap, a full Library
    // screen (20+ tiles) would take seconds to finish arriving; six reads
    // as a deliberate cascade and keeps the whole entrance short.
    readonly property int  motionGridEntranceMaxSteps: 6

    // How far a tile rises from, in pixels. Half of motionTransitionRise
    // (space3xl/64) -- felt at tile scale rather than screen scale, so it
    // reads as a smaller motion nested inside the screen's own arrival
    // rather than a second copy of it.
    readonly property int  motionGridEntranceRise: space3xl / 2

    // How far an element entrance overshoots its resting place before
    // settling, as Easing.OutBack's overshoot parameter. One overshoot, one
    // settle -- OutBack crosses its target exactly once, which is what keeps
    // this inside brief §6 rule 1, "never bounce twice". Anything elastic is
    // forbidden here for the same reason.
    //
    // Deliberately NOT motionOvershoot. That value is 0.7 because it is
    // applied to a 4% focus SCALE change, where the brief wants the overshoot
    // barely perceptible; the same 0.7 applied to this 32px translation
    // overshoots by about a pixel, which is not a bounce anyone can see. This
    // is Easing.OutBack's own default to one decimal, roughly 10% -- about 3px
    // here, which reads as a soft landing rather than a spring.
    //
    // The two are separate tokens so entrance feel and focus feel can be
    // retuned independently on hardware without one dragging the other with
    // it. Client decision, 2 August 2026: newly arriving elements settle with
    // a restrained overshoot and a single soft bounce.
    readonly property real motionEntranceOvershoot: 1.7

    // How small a popup starts before it settles into place. Popups used to
    // appear instantly, with no motion at all, which the client called out on
    // 3 August 2026 -- every other arrival in the app moves, so a menu simply
    // existing read as a missing frame.
    //
    // Deliberately near 1: this is the same restrained register as
    // motionPressScale's 0.97, scaled up a little because a whole panel
    // travelling reads as more movement than a tile does. Combined with
    // motionEntranceOvershoot above, a popup grows past its resting size once
    // and settles back -- one bounce, never two.
    readonly property real motionPopupEnterScale: 0.92

    // How long that takes. motionFocusMs, the clock every other reactive
    // motion in the app already runs on, so a popup does not introduce a
    // timing feel of its own.
    readonly property int  motionPopupEnterMs: motionFocusMs

    // Waiting motion: the three bouncing dots drawn over a busy host tile.
    //
    // Brief §6 rule 1 is "never bounce twice", and this loops forever, so it
    // needs saying why that is not a contradiction. That rule -- and the "no
    // SequentialAnimation on the carousel" decision in SPEC-host-carousel.md --
    // are both about motion that ANSWERS AN INPUT: one press, one settle. A
    // waiting indicator answers nothing and has no target to settle into. It
    // belongs to the brief's other motion category, ambient: continuous, low
    // contrast, and deliberately slower than anything reactive.
    //
    // Hence 900 against motionFocusMs's 180 -- five times slower, so it reads as
    // breathing rather than as the interface responding to something.
    readonly property int  motionBusyBounceMs:      900

    // Offset between one dot and the next, as a fraction of the period. Enough
    // that the three read as a cascade; synchronised dots read as a blink.
    readonly property int  motionBusyStaggerMs:     140

    // How far a dot travels. Small on purpose: the tile is already dimmed and
    // the dots are the only thing moving on the screen, so they do not need
    // amplitude to be noticed.
    readonly property int  motionBusyBounceHeight:   14

    // --- Host carousel --------------------------------------------------------
    // Proportions measured off the design mockup at 1280x800: the focused tile is
    // a little over a quarter of the panel width, and its neighbours are just
    // under two thirds of its size.
    // Focused tile diameter before the 1.04 focus scale is applied: the mockup's
    // focused circle measures ~337px at 1280x800, and 337 / 1.04 is 324.
    readonly property int  hostTileSize:           324
    readonly property real hostTileNeighbourScale: 0.64

    // Horizontal distance from the focused tile's centre to a neighbour's centre.
    // Measured off the mockup, where it leaves ~86px of clear ground between the
    // focused edge and the neighbour edge. A path starting at x=0 would centre the
    // first neighbour on the screen edge and cut half of it off.
    readonly property int  hostTileSpread:         338

    // Neighbours sit lower than the focused tile, which is what gives the row its
    // gentle arc rather than reading as three circles on a rule. Also measured off
    // the mockup.
    readonly property int  hostTileNeighbourDrop:   75

    // Clear space between the circle's drawn edge and the host's name.
    //
    // Not a step on the spacing scale, deliberately: the scale tops out at 64 and
    // has nothing at 56, and this is a carousel measurement like the two above
    // rather than generic padding. Client's call, 28 July 2026 -- the label was
    // set at spaceMd (16) when the text moved onto the tile, and they asked for
    // 30 more.
    readonly property int  hostTileLabelGap:        46

    // --- Host tile: the waiting state -----------------------------------------
    // Drawn while a host is connecting or being woken. The disc interior dims and
    // three dots bounce over it; the focus ring is left alone, because focus has
    // to read the same in every state or it stops being a reliable signal.

    // How far the disc dims. disabledOpacity (0.38) reads as "not available" and
    // popupScrimOpacity (0.62) reads as "something else is in front of this".
    // Neither is right: this host is busy, not gone. 0.55 sits between them,
    // closer to the scrim, so the monogram stays legible underneath.
    readonly property real hostTileBusyDimOpacity:   0.55

    // Dot diameter, about 3% of the tile. Large enough to see at neighbour scale,
    // small enough not to compete with the monogram behind it.
    readonly property int  hostTileBusyDotSize:       18

    // Gap between dots. A carousel measurement like hostTileSpread and
    // hostTileLabelGap, not a step on the generic spacing scale.
    readonly property int  hostTileBusyDotGap:        20

    // How long a wake attempt bounces before the app admits it did not work.
    // Client's call, 31 July 2026: 30 seconds. Long enough for a PC to leave
    // sleep and bring its network back, short enough that a machine that is not
    // coming back does not leave you watching dots. The app notices a host
    // answering within roughly one 3s discovery poll of it doing so, so almost
    // all of this budget is the machine's, not ours.
    readonly property int  hostTileWakeTimeoutMs:  30000

    // How long "Couldn't wake" holds before the tile falls back to its normal
    // offline copy. The failure needs to be read, not dismissed -- there is no
    // popup here and nothing for the player to press.
    readonly property int  hostTileBusyResultHoldMs: 3000

    // Peak alpha of the warm halo behind the focused tile. The brief's ambient
    // radial glow is 3-6%; a focus halo is the foreground case of the same
    // effect and carries more weight, matching the existing card focus bloom.
    readonly property real focusBloomOpacity: 0.22

    // --- Game grid (PROPOSED -- pending client approval on real hardware) ----
    // Measured off the client's mockups for the game-grid task, normalised to
    // 1280x800, following the precedent of hostTileSpread, hostTileLabelGap and
    // hostTileBusyDotGap: screen-specific measurements, not steps on the
    // generic spacing scale. None of these is a settled value the way
    // motionFocusMs's 180 became one after the 28 July review -- these have not
    // yet been seen on a real screen at all.

    // Library tile width, measured off the client's mockup at 1280x800.
    readonly property int  gameTileWidth:       216

    // 2:3 portrait against the width. NOT the mockup's proportion, which
    // measures nearer 3:4 -- but every tile in that mockup was a grey
    // placeholder, so the shape was estimated with no artwork in it.
    //
    // Client's call, 1 August 2026, after seeing both against the real
    // Steambox library: 2:3 is SteamGridDB's standard vertical size, and it is
    // what 18 of the 25 box-art files cached on the review station actually
    // are. At 3:4 the crop takes a band off the top and bottom of most of the
    // library -- visibly, on posters whose titles sit near an edge. Accepted
    // evolution from the mockup, not a transcription error.
    readonly property int  gameTileHeight:      324
    // Column count, from the mockup.
    readonly property int  gameGridColumns:     5
    // Column gap: 2*layoutScreenMarginX + 5*216 + 4*26 = exactly 1280, so five
    // tiles fit the mockup's grid with no partial column at either edge.
    readonly property int  gameGridGap:         26
    // The small host disc in the header, measured off the mockup.
    readonly property int  gameHeaderAvatarSize: 40

    // --- Recent view -----------------------------------------------------------
    // The focused tile and its two dimmed neighbours, the same composition as the
    // host carousel. Measured off design/game-grid-01-recent.png, then constrained
    // by the height actually available.
    //
    // The mockup's focused tile scales to about 320x440. That is neither 2:3 nor
    // 3:4, and at 2:3 a 320-wide tile would be 480 tall -- which does not fit.
    // The tile keeps the accepted 2:3 ratio and gives up width instead.
    //
    // Sized against what is actually left rather than what was estimated. The
    // first attempt at 288x432 was measured on screen: the tile starts 223px
    // down, the focus scale adds 4% to its height, and the title landed exactly
    // on the hint bar's hairline. Working back from the 489px that genuinely
    // remain -- minus gameRecentLabelGap, the title line, and the tagline the
    // running game adds under it -- gives 396, and 264 is that at 2:3.
    //
    // Smaller than the mockup drew. The ratio was decided on evidence and the
    // copy beneath has to be readable, so the width is what gives way.
    readonly property int  gameRecentTileWidth:      256
    readonly property int  gameRecentTileHeight:     384

    // Neighbour size relative to the focused tile. The carousel's own
    // hostTileNeighbourScale is 0.64; this is looser because a rectangular tile
    // at 0.64 reads as a different object rather than the same one further away.
    readonly property real gameRecentNeighbourScale: 0.70

    // Focused centre to neighbour centre.
    //
    // Tightened from 290 on the client's instruction of 1 August 2026: Recent
    // was showing three games however wide the screen was, and they asked it to
    // expose as many as the space and the spacing permit. At 290 a fourth and
    // fifth tile only fit by hanging over the screen edge; at 250, five sit
    // whole inside layoutScreenMarginX at 1280 wide, with about 32px of clear
    // ground between the focused tile and its neighbour.
    //
    // Closer than the ~65px this started at, and closer than hostTileSpread's
    // equivalent on the carousel. That is the trade the instruction asks for --
    // seeing more of the library beats air around the selected game.
    readonly property int  gameRecentSpread:         250

    // Clear space under the focused tile before its title block.
    readonly property int  gameRecentLabelGap:        16

    // --- Selected-game launch ------------------------------------------------
    // Measured from the client's 1867x1153 normal-launch raster and normalized
    // to its 1280-wide Deck composition. The attachment is vertically cropped,
    // so centre Y remains approximate; these are evidence-backed launch-only
    // geometry values, not additions to the generic spacing scale.
    readonly property int launchDestinationWidth:   202
    readonly property int launchDestinationHeight:  302
    readonly property int launchDestinationCenterX: 640
    readonly property int launchDestinationCenterY: 293
    // Five transition clocks gives an accepted scene-graph grab time to
    // complete without allowing a lost callback to strand launch input.
    readonly property int launchCaptureWatchdogMs: motionTransitionMs * 5
    // A launch warning holds long enough to read once, then continues without
    // asking the player to acknowledge infrastructure they cannot act on.
    readonly property int launchWarningDurationMs: 3500
    // Deterministic review replay cadence; long enough for the transition to
    // finish and rest before the next captured cycle begins.
    readonly property int launchReviewCycleMs: motionTransitionMs * 4

    // --- First-run onboarding (private v1 finalisation, stage 3) -------------
    // S0-S3 introduce no new colours or type -- the mockups reuse the palette
    // and faces already declared above -- so this section is geometry and
    // timing only, following the established precedent of hostTileSpread,
    // gameTileWidth and launchDestinationWidth: screen-specific measurements
    // rather than steps on the generic spacing scale.

    // How long the splash holds before moving on, skippable by any press. Not
    // in the creative brief -- there is no splash screen there at all -- so
    // this is a judgement call rather than a transcription. Shorter than
    // every other held state in this file (hostTileBusyResultHoldMs 3000,
    // launchWarningDurationMs 3500): those hold a VERDICT that needs reading,
    // this holds a logo with nothing to read, so it only has to register as a
    // deliberate beat rather than flash past unseen.
    readonly property int onboardingSplashHoldMs: 1200

    // How long the carousel stays out of sight at launch while it waits for the
    // remembered host to come online, before giving up and showing itself.
    //
    // Client decision, 9 August 2026: launching into the host list is wrong when
    // there is a PC to go back to, and the carousel appearing for a moment and
    // then being replaced by the library is worse than either. So the carousel
    // holds its content back until the auto-open either fires or times out.
    //
    // A saved host loads OFFLINE and only reports itself reachable when the
    // discovery poll answers, which the wake path measures at roughly three
    // seconds. This is that, with room for one poll to be missed. Past it the
    // player is waiting on a screen that has not said anything, which is worse
    // than showing them the carousel they can actually use.
    readonly property int carouselAutoOpenGraceMs: 5000

    // The crescent alone (bulan_logomark.svg), as it appears on S1 and S2.
    // Measured off S1's mockup at its 1707px reference width, normalized to
    // the 1280x800 layout every other measurement in this file targets.
    readonly property int onboardingMarkSize: 112

    // The S1 primary button's warm glow and the S2 focused row's glow, both
    // applied via MultiEffect's shadow* properties rather than a second
    // Canvas radial gradient copied from focusBloom -- that technique is
    // built for a fixed circular halo behind a stationary host tile; a button
    // and a list row are rectangular and can appear anywhere in a layout, so
    // a drop-shadow-shaped glow suits them better than reproducing the halo.
    // Grounded in focusBloomOpacity's own role -- a warm halo behind the one
    // focused or primary element -- rather than invented fresh.
    readonly property real buttonGlowOpacity: 0.5
    readonly property real buttonGlowBlur:    0.6

    // S3's four PIN tiles, measured off its mockup at the same 1707px
    // reference width.
    readonly property int pairPinTileWidth:  104
    readonly property int pairPinTileHeight: 120

    // --- Settings shell (private v1 finalisation, stage 5) --------------------
    // Read off the client's settings mockups the same way hostTileSpread and
    // gameTileWidth were: a screen-specific measurement, not a step on the
    // generic spacing scale. Unlike those, no pixel ruler was available for
    // this task -- this is an estimate from the rendered mockup rather than a
    // transcription, following the same caveat as the "Game grid (PROPOSED)"
    // section above, and has not yet been seen on a real screen.
    readonly property int settingsRailWidth: 260
}
