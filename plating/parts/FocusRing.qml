import QtQuick
import Plating

// Keyboard focus: a solid focus-colored ring focusRingOffset outside its parent,
// usually a control's background. Bind `visible` to the control's visualFocus.
Rectangle {
    id: ring

    readonly property UiTheme theme: Plating.theme as UiTheme
    readonly property real outset: UiMetrics.focusRingOffset + UiMetrics.focusRingWidth

    // The corner radius of the shape it surrounds
    property real targetRadius: 0

    anchors.fill: parent
    anchors.margins: -ring.outset
    radius: ring.targetRadius > 0 ? ring.targetRadius + ring.outset : 0
    color: "transparent"
    border.width: UiMetrics.focusRingWidth
    border.color: ring.theme.focus
}
