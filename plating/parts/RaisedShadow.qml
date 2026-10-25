import QtQuick
import QtQuick.Effects
import Plating

// shadow-raised, cast by the primary Button and the floating action button
// only. Fills its parent, a pill or a disc, and draws behind it.
RectangularShadow {
    id: shadow

    readonly property UiTheme theme: Plating.theme as UiTheme

    anchors.fill: parent
    z: -1
    offset.y: UiMetrics.shadowRaisedOffsetY
    // Qt documents 1.2 × the CSS blur as the closest match to a CSS box-shadow
    blur: 1.2 * UiMetrics.shadowRaisedBlur
    radius: Math.min(shadow.width, shadow.height) / 2
    color: shadow.theme.shadowRaised
}
