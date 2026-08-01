import QtQuick 2.9

// -----------------------------------------------------------------------------
// Bulan design tokens — SINGLE SOURCE FOR TokenProof.qml
//
// PROVENANCE. Values below are the Figma variables from
//   figma.com/design/RvcIMzlxM9tKBOuTviQu7P  (?view=variables)
// exported to ~/Downloads/tokens-2.json and transcribed here verbatim.
//
// Two deliberate departures from that file, both flagged on the sheet:
//
//  1. TYPE FAMILY. tokens-2.json carries only `familyUi: Inter`. Faris confirmed
//     the header face is FRAUNCES per the design mockup and that the variable has
//     not been updated yet. So `familyDisplay` below is "Fraunces", sourced from
//     the mockup, NOT from the variables file. Applied to the display/titleLg/
//     title steps; the rest stay on Inter.
//
//  2. UNITS. Figma sizes are px at 1280x800. TokenProof.qml renders them with
//     font.pixelSize, NOT font.pointSize — pointSize would go through Qt's DPI
//     conversion and come out substantially larger than designed.
//
// TO UPDATE: re-export from Figma and edit this file only. Nothing else reads
// token values.
// -----------------------------------------------------------------------------

QtObject {

    // --- Palette -------------------------------------------------------------
    readonly property string paletteSource:
        "figma — colour/base, via tokens-2.json. 10/10 match the creative brief."
    readonly property bool paletteTrusted: true

    readonly property var palette: [
        { name: "bgBase",        value: "#0D1024", note: "Deep indigo-navy" },
        { name: "bgBaseOled",    value: "#080A18", note: "Deepened, never #000000" },
        { name: "bgSurface",     value: "#171B33", note: "One step up from base" },
        { name: "accentPrimary", value: "#FFD9A0", note: "Moonglow amber — the signature" },
        { name: "accentGlow",    value: "#FFB865", note: "Warmer; bloom + focus halos" },
        { name: "secondary",     value: "#8A93C2", note: "Muted periwinkle — inactive" },
        { name: "textPrimary",   value: "#F4EDE2", note: "Warm off-white, never pure" },
        { name: "textSecondary", value: "#A8AECB", note: "" },
        { name: "statusSuccess", value: "#7FC7A8", note: "Desaturated jade" },
        { name: "statusError",   value: "#E08B7D", note: "Dusty coral" }
    ]

    // --- Type ----------------------------------------------------------------
    readonly property string typeSource:
        "figma — type/base. Sizes, line heights and tracking verbatim. " +
        "Display face is Fraunces per the mockup; the Figma variable still says Inter."
    readonly property bool typeTrusted: true

    readonly property string familyUi: "Inter"
    // NOT in tokens-2.json — from the mockup. See header note.
    readonly property string familyDisplay: "Fraunces"

    readonly property var typeRamp: [
        {
            name: "display", size: 56, lineHeight: 64, tracking: -1.2,
            family: familyDisplay, weight: Font.Normal, isDisplayFace: true,
            sample: "Desktop-PC"
        },
        {
            name: "titleLg", size: 40, lineHeight: 48, tracking: -0.5,
            family: familyDisplay, weight: Font.Normal, isDisplayFace: true,
            sample: "Ember Coast"
        },
        {
            name: "title", size: 32, lineHeight: 40, tracking: -0.5,
            family: familyDisplay, weight: Font.Normal, isDisplayFace: true,
            sample: "Harbour Nine"
        },
        {
            name: "bodyLg", size: 26, lineHeight: 34, tracking: 0,
            family: familyUi, weight: Font.Normal, isDisplayFace: false,
            sample: "Pick up where you left off."
        },
        {
            name: "body", size: 22, lineHeight: 30, tracking: 0,
            family: familyUi, weight: Font.Normal, isDisplayFace: false,
            sample: "Optimise game settings for streaming"
        },
        {
            name: "label", size: 18, lineHeight: 24, tracking: 0,
            family: familyUi, weight: Font.Medium, isDisplayFace: false,
            sample: "View all apps"
        },
        {
            name: "caption", size: 16, lineHeight: 22, tracking: 0.2,
            family: familyUi, weight: Font.Normal, isDisplayFace: false,
            sample: "192.168.1.24 · Online"
        }
    ]

    // --- Spacing -------------------------------------------------------------
    readonly property string spacingSource:
        "figma — spacing/base. Step scale plus the layout/target tokens."
    readonly property bool spacingTrusted: true

    readonly property var spacingScale: [
        { name: "space2xs", value: 4 },
        { name: "spaceXs",  value: 8 },
        { name: "spaceSm",  value: 12 },
        { name: "spaceMd",  value: 16 },
        { name: "spaceLg",  value: 24 },
        { name: "spaceXl",  value: 32 },
        { name: "space2xl", value: 48 },
        { name: "space3xl", value: 64 }
    ]

    // Layout + hit-target tokens. targetMin/targetRowHeight matter most on the
    // Deck, so they are drawn to scale alongside the step scale.
    readonly property var layoutScale: [
        { name: "layoutScreenMarginX", value: 48, note: "screen margin, horizontal" },
        { name: "layoutScreenMarginY", value: 32, note: "screen margin, vertical" },
        { name: "layoutSafeInset",     value: 16, note: "safe inset" },
        { name: "targetMin",           value: 64, note: "min touch target" },
        { name: "targetRowHeight",     value: 88, note: "list row height" }
    ]

    // --- Radius --------------------------------------------------------------
    readonly property string radiusSource:
        "figma — radius/base."
    readonly property bool radiusTrusted: true

    readonly property var radiusScale: [
        { name: "radiusXs",   value: 4 },
        { name: "radiusSm",   value: 8 },
        { name: "radiusMd",   value: 14 },
        { name: "radiusLg",   value: 20 },
        { name: "radiusXl",   value: 28 },
        { name: "radiusFull", value: 999 }
    ]

    // --- Interaction states --------------------------------------------------
    // Still the one gap. tokens-2.json defines no state variables, so only focus
    // has a specified treatment (the brief's warm amber bloom). Hover, pressed
    // and disabled are derived from palette values by stated rule.
    readonly property string statesSource:
        "MIXED — focus from brief (amber halo). Hover/pressed/disabled inferred " +
        "from palette by rule; tokens-2.json defines no state variables."

    // --- Gradients -----------------------------------------------------------
    // tokens-2.json carries no gradient variables (Figma variables can't hold
    // gradients), so these remain sourced from the brief.
    readonly property string gradientSource:
        "brief — 'Depth, Not Darkness'. Figma variables cannot express gradients, " +
        "so tokens-2.json has none. Crescent stops inferred."

    readonly property var gradients: [
        {
            name: "Vertical base — sky into water",
            kind: "linear",
            trusted: true,
            spec: "#151A38 (top) → #080A18 (bottom)",
            from: "#151A38",
            to:   "#080A18"
        },
        {
            name: "Radial focus glow",
            kind: "radial",
            trusted: true,
            spec: "#FFD9A0 at 3–6% opacity → transparent",
            from: "#FFD9A0",
            to:   "#00FFD9A0"
        },
        {
            name: "Crescent body (logo)",
            kind: "linear",
            trusted: false,
            spec: "brief says 'light edge to dark' — NO STOPS SPECIFIED, inferred",
            from: "#FFD9A0",
            to:   "#3A3050"
        }
    ]

    // --- Selected-game launch ------------------------------------------------
    // Review copy of the runtime values in Bulan.qml. Measured from the
    // client's 1867x1153 raster after 1280-wide normalization; Y is approximate
    // because the supplied attachment is vertically cropped.
    readonly property int launchDestinationWidth:   202
    readonly property int launchDestinationHeight:  302
    readonly property int launchDestinationCenterX: 640
    readonly property int launchDestinationCenterY: 293
    // Keep synchronized with the runtime token in Bulan.qml.
    readonly property int launchCaptureWatchdogMs: 1100
}
