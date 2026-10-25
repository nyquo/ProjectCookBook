import QtQuick
import QtQuick.Shapes
import Plating

// A dashed outline drawn inside its bounds, e.g. a dashed button's border
Shape {
    id: outline

    property color color
    property real strokeWidth: UiMetrics.borderThin
    // Clamped to a pill, like Rectangle's
    property real radius: 0

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: outline.color
        strokeWidth: outline.strokeWidth
        fillColor: "transparent"
        strokeStyle: ShapePath.DashLine
        // In stroke widths
        dashPattern: [UiMetrics.dashLength / outline.strokeWidth,
            UiMetrics.dashGap / outline.strokeWidth]
        capStyle: ShapePath.FlatCap

        PathRectangle {
            x: outline.strokeWidth / 2
            y: outline.strokeWidth / 2
            width: Math.max(0, outline.width - outline.strokeWidth)
            height: Math.max(0, outline.height - outline.strokeWidth)
            radius: Math.max(0, Math.min(outline.radius, outline.width / 2, outline.height / 2)
                                - outline.strokeWidth / 2)
        }
    }
}
