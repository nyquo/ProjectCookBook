pragma Singleton

import QtQuick

// Ingredient icons: single-color SVG files in icons/ingredients/, drawn in black
// with a 1.8 stroke on a 24 grid, so Icon recolors them. An ingredient without
// its own icon gets the jar. To add one, put <name>.svg in that folder, list it
// in CMakeLists.txt and in `names`.
QtObject {
    id: root

    readonly property list<string> names: ["jar"]

    // The file for an icon name, or the jar's
    function source(name: string): url {
        const known = root.names.indexOf(name) >= 0 ? name : "jar"
        return Qt.resolvedUrl(`icons/ingredients/${known}.svg`)
    }
}
