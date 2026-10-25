pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// Key facts on one line, in equal cells split by hairlines. `model` gives each
// cell a label, a value and a detail (strings, "" for none); a missing value
// shows "–" so the strip keeps its shape.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property var model

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    topPadding: UiMetrics.specStripPaddingV
    bottomPadding: UiMetrics.specStripPaddingV
    leftPadding: 0
    rightPadding: 0

    contentItem: RowLayout {
        spacing: 0

        Repeater {
            model: control.model

            delegate: Item {
                id: cell

                required property int index
                required property string label
                required property string value
                required property string detail

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                implicitHeight: column.implicitHeight

                Rectangle {
                    visible: cell.index > 0
                    width: UiMetrics.hairline
                    height: parent.height
                    color: control.theme.line
                }

                ColumnLayout {
                    id: column

                    anchors.centerIn: parent
                    width: parent.width - 2 * UiMetrics.specCellPadding
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: cell.label
                        font: UiTypography.overline
                        color: control.theme.inkMuted
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: cell.value !== "" ? cell.value : "–"
                        font: UiTypography.value
                        color: control.theme.ink
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: cell.detail !== ""
                        Layout.fillWidth: true
                        text: cell.detail
                        font: UiTypography.overlineMedium
                        color: control.theme.inkMuted
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    background: Rectangle {
        radius: UiMetrics.radiusLg
        color: control.theme.surface
    }
}
