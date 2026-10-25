import QtQuick
import QtQuick.Effects
import Plating

// The background of a menu, and of the ComboBox popup that looks like one: a
// surface with a line outline and the menu shadow
Rectangle {
    id: panel

    readonly property UiTheme theme: Plating.theme as UiTheme

    implicitWidth: UiMetrics.menuMinWidth
    radius: UiMetrics.menuRadius
    color: panel.theme.surface
    border.width: UiMetrics.hairline
    border.color: panel.theme.line

    RectangularShadow {
        anchors.fill: parent
        z: -1
        radius: panel.radius
        offset.y: UiMetrics.shadowMenuOffsetY
        // Qt documents 1.2 × the CSS blur as the closest match to a CSS box-shadow
        blur: 1.2 * UiMetrics.shadowMenuBlur
        color: panel.theme.shadowMenu
    }
}
