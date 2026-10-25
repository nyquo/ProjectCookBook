import QtQuick
import QtQuick.Templates as T
import Plating

// A hairline between menu items, before the destructive ones
T.MenuSeparator {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: UiMetrics.menuSeparatorMarginV
    bottomPadding: UiMetrics.menuSeparatorMarginV
    leftPadding: UiMetrics.menuSeparatorMarginH
    rightPadding: UiMetrics.menuSeparatorMarginH

    contentItem: Rectangle {
        implicitHeight: UiMetrics.hairline
        color: control.theme.line
    }
}
