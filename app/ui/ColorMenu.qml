pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Plating

// A small menu of colors to pick from, in a row of ColorDots. openUnder(item)
// opens it under an item; picking a color emits colorClicked() and closes it.
T.Popup {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // [{ name, family }]
    property var colors: []
    // The checked color's index, or -1
    property int currentIndex: -1

    signal colorClicked(int index)

    function openUnder(item: Item) {
        const below = item.mapToItem(control.parent, 0, item.height + UiMetrics.menuGap)
        control.x = Math.max(UiMetrics.menuMargin,
                             Math.min(below.x, (control.parent?.width ?? 0) - control.width - UiMetrics.menuMargin))
        control.y = below.y
        control.open()
    }

    parent: T.Overlay.overlay
    modal: false
    focus: true
    // Over sheets, which open later
    z: 1

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    padding: UiMetrics.menuPadding

    contentItem: Row {
        Repeater {
            model: control.colors

            delegate: ColorDot {
                required property var modelData
                required property int index

                text: modelData.name
                family: modelData.family
                checked: index === control.currentIndex
                onClicked: {
                    control.colorClicked(index)
                    control.close()
                }
            }
        }
    }

    background: MenuPanel {
        implicitWidth: 0
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: UiMotion.fade(UiMotion.menuOpen)
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: UiMotion.fade(UiMotion.menuClose)
        }
    }
}
