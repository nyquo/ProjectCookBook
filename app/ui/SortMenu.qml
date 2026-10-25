pragma ComponentBehavior: Bound

import QtQuick
import Plating

// "Sort by": options with two directions each, both labelled by the caller.
// Another option is chosen in its first direction; the checked one again
// reverses it. The checked row shows its direction's arrow and a hint naming
// the other one. Controlled: it emits chosen() and the caller updates
// selectedIndex and reversed. It stays open while choosing.
Menu {
    id: control

    // [{ label, reversedLabel }]: an option's first and second direction
    property var options: []
    property int selectedIndex: 0
    property bool reversed: false

    signal chosen(int index, bool reversed)

    title: qsTr("Sort by")

    // Rows inside a Column aren't the menu's own items, so choosing one doesn't
    // close the menu
    Column {
        Repeater {
            model: control.options

            delegate: MenuItem {
                id: row

                required property int index
                required property var modelData

                readonly property bool current: row.index === control.selectedIndex
                readonly property string otherLabel: control.reversed ? row.modelData.label
                                                                      : row.modelData.reversedLabel

                width: parent?.width ?? 0
                text: row.current && control.reversed ? row.modelData.reversedLabel : row.modelData.label
                checked: row.current
                hint: row.current ? qsTr("Tap again for %1").arg(row.otherLabel.charAt(0).toLocaleLowerCase()
                                                                 + row.otherLabel.slice(1))
                                  : ""
                trailingArrow: !row.current ? MenuItem.NoArrow : control.reversed ? MenuItem.Down : MenuItem.Up
                onClicked: control.chosen(row.index, row.current ? !control.reversed : false)
            }
        }
    }
}
