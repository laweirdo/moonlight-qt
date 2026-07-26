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
    // individually disableable" a non-negotiable. There is no settings UI to
    // bind these to yet, so they are the defaults each Atmosphere starts from;
    // any instance can override them, and they can later be bound to real
    // preferences without touching the component.
    readonly property bool atmosphereGradientEnabled: true
    readonly property bool atmosphereVignetteEnabled: true
    readonly property bool atmosphereGrainEnabled:    true
}
