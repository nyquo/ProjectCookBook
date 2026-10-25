import QtQuick

// The theme contract: every color token that differs between light and dark.
// Each one is required, so a theme that misses one fails to instantiate. Sizes,
// spacing and fonts don't change with the theme: they're in UiMetrics and
// UiTypography. Colors that are data rather than tokens (tags, aisles) come with
// a light and a dark variant: `dark` says which one to use. The four tag
// families below are the design's defaults: chrome (tagButter for notes) and
// previews use them, data keeps its own colors.
//
// Token names map to properties as follows:
// - kebab-case becomes camelCase: ink-muted → inkMuted, accent-basil-soft → accentBasilSoft;
// - "on-x" and "accent-x-on" become "xInk", since "onAccent:" would parse as a
//   signal handler: on-danger → dangerInk, accent-basil-on → accentBasilInk;
// - accent, on-accent, accent-soft and focus aren't set by a theme: they follow
//   accentChoice (accent, accentInk, accentSoft, focus);
// - shadow-raised keeps only its color here; its geometry is in UiMetrics.
QtObject {
    id: theme

    enum Accent {
        Raspberry,
        Spirulina,
        Blueberry,
        Saffron,
        Basil
    }

    // True in a dark theme
    required property bool dark

    // Behind every screen; also the inside of the servings stepper
    required property color bg
    // Cards, list rows, search field, chips, round buttons and the bottom bar, on bg
    required property color surface
    // Primary text and icons on bg and surface. As a fill: the secondary button,
    // with bg as its text.
    required property color ink
    // Secondary text (meta lines, times, notes, captions), on bg and surface
    required property color inkMuted
    // Hairlines between rows and spec-strip cells. Decorative only: never the
    // only boundary of a control.
    required property color line
    // Destructive actions only, always with a word, never color alone. Text on
    // bg and surface.
    required property color danger
    required property color dangerInk
    // Behind bottom sheets and dialogs
    required property color scrim
    // Over a pressed control: pressOverlay on light fills, pressOverlayOnFill on
    // ink, accent and danger fills
    required property color pressOverlay
    required property color pressOverlayOnFill

    // The four color families, each a fill and the ink drawn on it (7:1+).
    // They belong to data (tags, aisles), never to chrome, except tagButter for
    // note cards.
    required property color tagMint
    required property color tagMintInk
    required property color tagButter
    required property color tagButterInk
    required property color tagSky
    required property color tagSkyInk
    required property color tagPeach
    required property color tagPeachInk

    // The five accent sets. Each accent passes 4.5:1 as text on bg, surface and
    // its own soft fill. Basil is close to the mint tag color: such tags lose
    // some contrast with actions.
    required property color accentRaspberry
    required property color accentRaspberryInk
    required property color accentRaspberrySoft
    required property color accentSpirulina
    required property color accentSpirulinaInk
    required property color accentSpirulinaSoft
    required property color accentBlueberry
    required property color accentBlueberryInk
    required property color accentBlueberrySoft
    required property color accentSaffron
    required property color accentSaffronInk
    required property color accentSaffronSoft
    required property color accentBasil
    required property color accentBasilInk
    required property color accentBasilSoft

    // Cast by the primary Button and the floating action button only
    required property color shadowRaised
    // Cast by menus, with a line outline; their only shadow
    required property color shadowMenu

    // One of UiTheme.Accent. Only the four properties below follow it
    property int accentChoice: UiTheme.Raspberry

    // Primary actions, active nav item, favorite heart, links; also text on bg,
    // surface and accentSoft.
    readonly property color accent: {
        switch (theme.accentChoice) {
        case UiTheme.Spirulina:
            return theme.accentSpirulina
        case UiTheme.Blueberry:
            return theme.accentBlueberry
        case UiTheme.Saffron:
            return theme.accentSaffron
        case UiTheme.Basil:
            return theme.accentBasil
        default:
            return theme.accentRaspberry
        }
    }
    // Text and icons on an accent fill
    readonly property color accentInk: {
        switch (theme.accentChoice) {
        case UiTheme.Spirulina:
            return theme.accentSpirulinaInk
        case UiTheme.Blueberry:
            return theme.accentBlueberryInk
        case UiTheme.Saffron:
            return theme.accentSaffronInk
        case UiTheme.Basil:
            return theme.accentBasilInk
        default:
            return theme.accentRaspberryInk
        }
    }
    // Tinted fill behind accent text: quantity pills, step numbers, the active
    // nav indicator.
    readonly property color accentSoft: {
        switch (theme.accentChoice) {
        case UiTheme.Spirulina:
            return theme.accentSpirulinaSoft
        case UiTheme.Blueberry:
            return theme.accentBlueberrySoft
        case UiTheme.Saffron:
            return theme.accentSaffronSoft
        case UiTheme.Basil:
            return theme.accentBasilSoft
        default:
            return theme.accentRaspberrySoft
        }
    }
    // Keyboard focus ring (geometry in UiMetrics)
    readonly property color focus: theme.accent

    onAccentChoiceChanged: {
        if (theme.accentChoice < UiTheme.Raspberry || theme.accentChoice > UiTheme.Basil)
            console.warn(`UiTheme: unknown accent ${theme.accentChoice}, using Raspberry`)
    }
}
