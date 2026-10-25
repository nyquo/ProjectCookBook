import QtQuick
import QtQuick.Templates as T
import Plating

// One choice among a few SegmentedButtons of equal width, in a bg capsule.
// Plain: no capsule, separate options.
T.TabBar {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property bool plain: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: control.plain ? 0 : UiMetrics.segmentedPadding
    spacing: control.plain ? UiMetrics.segmentedGapPlain : UiMetrics.segmentedGap

    contentItem: ListView {
        model: control.contentModel
        currentIndex: control.currentIndex
        spacing: control.spacing
        orientation: ListView.Horizontal
        interactive: false
        highlightMoveDuration: 0
    }

    background: Rectangle {
        visible: !control.plain
        radius: height / 2
        color: control.theme.bg
    }
}
