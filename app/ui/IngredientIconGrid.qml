pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// The ingredient icons to pick from, six to a row on a surface card. The
// current one takes the family's fill, ringed in its ink. Controlled: emits
// iconClicked(), the caller changes currentIcon.
Card {
    id: control

    // IngredientIcons names
    property list<string> icons: IngredientIcons.names
    property string currentIcon
    // The aisle's family
    property colorFamily family

    signal iconClicked(string name)

    padding: CookbookMetrics.iconGridPadding

    GridLayout {
        columns: 6
        columnSpacing: 0
        rowSpacing: CookbookMetrics.iconGridGap

        Repeater {
            model: control.icons

            // Columns share the width; the cell sits in the middle of its column
            delegate: Item {
                id: column

                required property string modelData

                Layout.fillWidth: true
                implicitWidth: CookbookMetrics.iconGridCell
                implicitHeight: CookbookMetrics.iconGridCell

                T.AbstractButton {
                    id: cell

                    readonly property bool current: column.modelData === control.currentIcon

                    anchors.centerIn: parent
                    width: CookbookMetrics.iconGridCell
                    height: CookbookMetrics.iconGridCell
                    text: IngredientIcons.label(column.modelData)
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: cell.text
                    Accessible.checkable: true
                    Accessible.checked: cell.current
                    onClicked: control.iconClicked(column.modelData)

                    contentItem: Item {
                        Icon {
                            anchors.centerIn: parent
                            width: UiMetrics.sizeIcon
                            height: UiMetrics.sizeIcon
                            source: IngredientIcons.source(column.modelData)
                            color: cell.current ? control.family.ink : control.theme.ink
                        }
                    }

                    background: Rectangle {
                        radius: CookbookMetrics.iconGridCellRadius
                        color: cell.current ? control.family.fill : "transparent"
                        border.width: cell.current ? UiMetrics.borderStrong : 0
                        border.color: control.family.ink

                        PressOverlay {
                            radius: parent.radius
                            pressed: cell.down
                        }

                        FocusRing {
                            visible: cell.visualFocus
                            targetRadius: parent.radius
                        }
                    }
                }
            }
        }
    }
}
