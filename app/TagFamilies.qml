pragma Singleton

import QtQuick
import Plating

// The four colors a tag can take: the theme's tag families, by the key the
// database stores. Unlike an aisle, a tag stores only the key, so its colors
// follow the theme.
QtObject {
    id: root

    // In the order pickers show them, which is also the order new tags take
    // them in: [{ key, name }]
    readonly property var all: [
        { key: "mint", name: qsTr("Mint") },
        { key: "butter", name: qsTr("Butter") },
        { key: "sky", name: qsTr("Sky") },
        { key: "peach", name: qsTr("Peach") }
    ]

    // The family of a key, as `theme` shows it
    function family(theme: UiTheme, key: string): colorFamily {
        switch (key) {
        case "butter":
            return { fill: theme.tagButter, ink: theme.tagButterInk }
        case "sky":
            return { fill: theme.tagSky, ink: theme.tagSkyInk }
        case "peach":
            return { fill: theme.tagPeach, ink: theme.tagPeachInk }
        default:
            return { fill: theme.tagMint, ink: theme.tagMintInk }
        }
    }

    // As `theme` shows them, for TagEditRow: [{ name, family }]
    function choices(theme: UiTheme): var {
        return root.all.map(c => ({ name: c.name, family: root.family(theme, c.key) }))
    }

    function indexOf(key: string): int {
        return root.all.findIndex(c => c.key === key)
    }
}
