import QtQuick
import QtQuick.Templates as T
import Plating

// The app's bottom navigation: equal BottomNavItems on a surface bar. At the
// bottom of the window it also pads itself above the navigation bar
// (SafeArea).
T.TabBar {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: UiMetrics.bottomNavHeight + topPadding + bottomPadding

    padding: 0
    bottomPadding: control.SafeArea.margins.bottom
    leftPadding: control.SafeArea.margins.left
    rightPadding: control.SafeArea.margins.right
    spacing: 0

    contentItem: ListView {
        model: control.contentModel
        currentIndex: control.currentIndex
        orientation: ListView.Horizontal
        interactive: false
        highlightMoveDuration: 0
    }

    background: Rectangle {
        color: control.theme.surface

        Rectangle {
            width: parent.width
            height: UiMetrics.hairline
            color: control.theme.line
        }
    }
}
