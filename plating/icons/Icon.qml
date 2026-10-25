import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Plating

// A line icon tinted with `color`: an interface glyph from UiIcons by `name`, or
// a single-color SVG file by `source`, drawn in black and recolored. The size
// is the item's size.
Item {
    id: icon

    property string name
    property url source
    property color color
    // Fills a glyph whose path closes, e.g. a heart that is on
    property bool filled: false
    // In screen px, whatever the icon's size (a UiMetrics.iconStroke… token); NaN
    // keeps the glyph's own. Ignored for SVG files, which carry their own.
    property real strokeWidth: NaN

    implicitWidth: UiMetrics.sizeIcon
    implicitHeight: UiMetrics.sizeIcon

    Shape {
        anchors.fill: parent
        visible: icon.name !== ""
        // Antialiased and sharp at any size, without multisampling
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: glyph

            readonly property real unit: icon.width / UiIcons.gridSize

            scale: Qt.size(glyph.unit, glyph.unit)
            strokeColor: icon.color
            strokeWidth: isNaN(icon.strokeWidth) ? UiIcons.strokeOf(icon.name) : icon.strokeWidth
            fillColor: icon.filled ? icon.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: icon.name !== "" ? UiIcons.path(icon.name) : ""
            }
        }
    }

    Image {
        id: file

        anchors.fill: parent
        visible: false
        source: icon.source
        sourceSize: Qt.size(icon.width, icon.height)
        fillMode: Image.PreserveAspectFit
    }

    // Brightness turns the black drawing white, colorization then tints it
    MultiEffect {
        anchors.fill: parent
        visible: icon.source.toString() !== ""
        source: file
        brightness: 1
        colorization: 1
        colorizationColor: icon.color
    }
}
