import QtQuick
import QtQuick.Templates as T
import Plating

// A surface card holding one item (a ColumnLayout…), padded. `ringColor`
// draws a ring inside its edge, e.g. around a form that adds something.
T.Pane {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // None while transparent
    property color ringColor: "transparent"

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    padding: UiMetrics.space4

    // Its item spans the card's width
    onContentChildrenChanged: {
        for (const child of control.contentChildren)
            child.width = Qt.binding(() => control.availableWidth)
    }

    background: Rectangle {
        radius: UiMetrics.radiusLg
        color: control.theme.surface
        border.width: control.ringColor.a > 0 ? UiMetrics.borderStrong : 0
        border.color: control.ringColor
    }
}
