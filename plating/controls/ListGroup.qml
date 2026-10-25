pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Plating

// A card of ListRows, stacked, with hairlines between them. Rows can be
// declared inside or come from a Repeater.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // The rows start with an icon: tighter padding
    property bool iconRows: false
    default property alias rows: column.data

    // The y of each visible row but the first, where a hairline goes
    readonly property list<real> dividers: {
        const ys = []
        let first = true
        for (const row of column.children) {
            if (!row.visible || row.height <= 0)
                continue
            if (!first)
                ys.push(row.y)
            first = false
        }
        return ys
    }

    // From the rows' implicit widths: their widths follow the group's
    implicitWidth: {
        let widest = 0
        for (const row of column.children)
            widest = Math.max(widest, row.implicitWidth)
        return widest + leftPadding + rightPadding
    }
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    topPadding: control.iconRows ? 0 : UiMetrics.listGroupPaddingV
    bottomPadding: control.topPadding
    leftPadding: control.iconRows ? UiMetrics.listGroupIconPaddingH : UiMetrics.listGroupPaddingH
    rightPadding: control.leftPadding

    contentItem: Column {
        id: column

        // Rows span the group
        onChildrenChanged: {
            for (const row of column.children)
                row.width = Qt.binding(() => column.width)
        }
    }

    background: Rectangle {
        color: control.theme.surface
        radius: UiMetrics.radiusLg

        Repeater {
            model: control.dividers

            delegate: Rectangle {
                required property real modelData

                x: control.leftPadding
                y: control.topPadding + modelData
                width: control.availableWidth
                height: UiMetrics.hairline
                color: control.theme.line
            }
        }
    }
}
