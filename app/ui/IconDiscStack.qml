pragma ComponentBehavior: Bound

import QtQuick
import Plating

// Icon discs in a row, each overlapping the previous one and ringed in surface
// so the edge shows, e.g. a glimpse of what a list holds. Decorative.
Item {
    id: stack

    readonly property UiTheme theme: Plating.theme as UiTheme

    // [{ iconSource, family }], first at the back
    property var discs: []

    readonly property real step: CookbookMetrics.discStackDisc - CookbookMetrics.discStackOverlap

    implicitWidth: stack.discs.length > 0 ? CookbookMetrics.discStackDisc + (stack.discs.length - 1) * stack.step : 0
    implicitHeight: CookbookMetrics.discStackDisc

    Accessible.ignored: true

    Repeater {
        model: stack.discs

        // The ring, around the disc and outside the stack's bounds
        delegate: Rectangle {
            id: ring

            required property var modelData
            required property int index

            x: ring.index * stack.step - CookbookMetrics.discStackRing
            y: -CookbookMetrics.discStackRing
            width: CookbookMetrics.discStackDisc + 2 * CookbookMetrics.discStackRing
            height: width
            radius: width / 2
            color: stack.theme.surface

            Rectangle {
                anchors.centerIn: parent
                width: CookbookMetrics.discStackDisc
                height: width
                radius: width / 2
                color: ring.modelData.family.fill

                Icon {
                    anchors.centerIn: parent
                    width: CookbookMetrics.discStackIcon
                    height: width
                    source: ring.modelData.iconSource
                    color: ring.modelData.family.ink
                }
            }
        }
    }
}
