pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// How a total splits into parts: a bar of segments in proportion to them, the
// current part in accent and what's left of the total in accent-soft, then one
// line per part.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // An array of { label, value (as shown), amount (a number), current }
    property var parts: []
    // What the amounts add up to at most; the rest shows as the remainder
    property real total

    readonly property real used: control.parts.reduce((sum, part) => sum + part.amount, 0)
    readonly property real remainder: Math.max(0, control.total - control.used)
    readonly property real whole: Math.max(control.total, control.used)
    // The bar's segments: the parts, then the remainder if any
    readonly property var segments: control.remainder > 0
                                    ? control.parts.concat([{ amount: control.remainder, current: false, rest: true }])
                                    : control.parts

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    padding: 0

    contentItem: ColumnLayout {
        spacing: UiMetrics.splitBarLinesGap

        Item {
            id: bar

            Layout.fillWidth: true
            implicitHeight: UiMetrics.splitBarHeight

            Row {
                spacing: UiMetrics.splitBarGap

                Repeater {
                    model: control.segments

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        readonly property bool first: index === 0
                        readonly property bool last: index === control.segments.length - 1

                        width: control.whole > 0
                               ? (bar.width - (control.segments.length - 1) * UiMetrics.splitBarGap)
                                 * modelData.amount / control.whole
                               : 0
                        height: bar.height
                        topLeftRadius: first ? UiMetrics.splitBarRadius : 0
                        bottomLeftRadius: first ? UiMetrics.splitBarRadius : 0
                        topRightRadius: last ? UiMetrics.splitBarRadius : 0
                        bottomRightRadius: last ? UiMetrics.splitBarRadius : 0
                        color: modelData.current ? control.theme.accent
                                                 : modelData.rest ? control.theme.accentSoft : control.theme.line
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: UiMetrics.splitBarLineSpacing

            Repeater {
                model: control.parts

                delegate: RowLayout {
                    id: line

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: UiMetrics.space2

                    Text {
                        Layout.fillWidth: true
                        text: line.modelData.label
                        font: UiTypography.bodyS
                        color: line.modelData.current ? control.theme.accent : control.theme.inkMuted
                        elide: Text.ElideRight
                    }

                    Text {
                        text: line.modelData.value
                        font: line.modelData.current ? UiTypography.qty : UiTypography.labelSBold
                        color: line.modelData.current ? control.theme.accent : control.theme.ink
                    }
                }
            }
        }
    }
}
