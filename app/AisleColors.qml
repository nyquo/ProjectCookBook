pragma Singleton

import QtQuick
import Plating

// The four colors an aisle can take: the theme's tag families. An aisle stores
// both the light and the dark variant, so each comes from both default themes.
QtObject {
    id: root

    // [{ name, fill, ink, darkFill, darkInk }]
    readonly property var all: [
        {
            name: qsTr("Mint"),
            fill: DefaultLightTheme.tagMint,
            ink: DefaultLightTheme.tagMintInk,
            darkFill: DefaultDarkTheme.tagMint,
            darkInk: DefaultDarkTheme.tagMintInk
        },
        {
            name: qsTr("Butter"),
            fill: DefaultLightTheme.tagButter,
            ink: DefaultLightTheme.tagButterInk,
            darkFill: DefaultDarkTheme.tagButter,
            darkInk: DefaultDarkTheme.tagButterInk
        },
        {
            name: qsTr("Sky"),
            fill: DefaultLightTheme.tagSky,
            ink: DefaultLightTheme.tagSkyInk,
            darkFill: DefaultDarkTheme.tagSky,
            darkInk: DefaultDarkTheme.tagSkyInk
        },
        {
            name: qsTr("Peach"),
            fill: DefaultLightTheme.tagPeach,
            ink: DefaultLightTheme.tagPeachInk,
            darkFill: DefaultDarkTheme.tagPeach,
            darkInk: DefaultDarkTheme.tagPeachInk
        }
    ]

    // As `theme` shows them, for ColorDot and ColorMenu: [{ name, family }]
    function choices(theme: UiTheme): var {
        return root.all.map(c => ({
                                      name: c.name,
                                      family: {
                                          fill: theme.dark ? c.darkFill : c.fill,
                                          ink: theme.dark ? c.darkInk : c.ink
                                      }
                                  }))
    }

    // The index of the color whose light fill is `fill`, or -1 for another
    function indexOf(fill: color): int {
        return root.all.findIndex(c => Qt.colorEqual(c.fill, fill))
    }
}
