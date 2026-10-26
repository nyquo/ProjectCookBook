pragma Singleton

import QtQuick

// Ingredient icons: single-color SVG files in icons/ingredients/, drawn in black
// with a 1.8 stroke on a 24 grid, so Icon recolors them. An icon's name is the
// key the database stores. An ingredient without its own icon gets the jar. To
// add one, put <name>.svg in that folder, list it in CMakeLists.txt, in `names`
// and in label().
QtObject {
    id: root

    readonly property list<string> names: [
        "apple", "banana", "bottle", "bread", "bulb", "butter", "can", "carrot", "cheese", "cup",
        "drumstick", "egg", "fish", "jar", "leaf", "lemon", "milk", "mushroom", "pepper", "potato",
        "sack", "spice", "tomato"
    ]

    // The file for an icon name, or the jar's
    function source(name: string): url {
        const known = root.names.indexOf(name) >= 0 ? name : "jar"
        return Qt.resolvedUrl(`icons/ingredients/${known}.svg`)
    }

    // What the icon shows, for screen readers
    function label(name: string): string {
        switch (name) {
        case "apple":
            return qsTr("Apple")
        case "banana":
            return qsTr("Banana")
        case "bottle":
            return qsTr("Bottle")
        case "bread":
            return qsTr("Bread")
        case "bulb":
            return qsTr("Bulb")
        case "butter":
            return qsTr("Butter")
        case "can":
            return qsTr("Can")
        case "carrot":
            return qsTr("Carrot")
        case "cheese":
            return qsTr("Cheese")
        case "cup":
            return qsTr("Cup")
        case "drumstick":
            return qsTr("Drumstick")
        case "egg":
            return qsTr("Egg")
        case "fish":
            return qsTr("Fish")
        case "jar":
            return qsTr("Jar")
        case "leaf":
            return qsTr("Leaf")
        case "lemon":
            return qsTr("Lemon")
        case "milk":
            return qsTr("Milk")
        case "mushroom":
            return qsTr("Mushroom")
        case "pepper":
            return qsTr("Pepper")
        case "potato":
            return qsTr("Potato")
        case "sack":
            return qsTr("Sack")
        case "spice":
            return qsTr("Spice")
        case "tomato":
            return qsTr("Tomato")
        default:
            return name
        }
    }
}
