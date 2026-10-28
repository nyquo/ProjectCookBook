pragma Singleton

import QtQuick

// The app's interface icons: single-color SVG files in icons/ui/, drawn in
// black on a 24 grid, so Icon recolors them. Controls take them as icon.source
// or iconSource. To add one, put <name>.svg in that folder, then list it in
// CMakeLists.txt and in `names`.
QtObject {
    id: root

    readonly property list<string> names: [
        "back", "check", "chevron-right", "down", "edit", "minus", "moon", "phone", "planning",
        "plus", "recipes", "search", "settings", "shopping", "sun", "trash", "up"
    ]

    // The file for an icon name
    function source(name: string): url {
        if (root.names.indexOf(name) < 0)
            console.warn(`CookbookIcons: no icon named "${name}"`)
        return Qt.resolvedUrl(`icons/ui/${name}.svg`)
    }
}
