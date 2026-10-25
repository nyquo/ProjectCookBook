import QtQuick
import QtQuick.Templates as T
import Plating

// A destination of the BottomNav: an icon (icon.name, icon.source) over its
// label. Active: the icon in accent on an accent-soft indicator.
T.TabButton {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: UiMetrics.bottomNavHeight

    padding: 0
    spacing: UiMetrics.bottomNavLabelGap
    icon.width: UiMetrics.sizeIcon
    icon.height: UiMetrics.sizeIcon
    icon.color: control.checked ? control.theme.accent : control.theme.inkMuted
    font: control.checked ? UiTypography.tag : UiTypography.overline

    contentItem: Item {
        implicitWidth: Math.max(indicator.width, label.implicitWidth)
        implicitHeight: indicator.height + control.spacing + label.implicitHeight

        Rectangle {
            id: indicator

            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - parent.implicitHeight) / 2
            width: UiMetrics.bottomNavIndicatorWidth
            height: UiMetrics.bottomNavIndicatorHeight
            radius: height / 2
            color: control.checked ? control.theme.accentSoft : "transparent"

            Icon {
                anchors.centerIn: parent
                width: control.icon.width
                height: control.icon.height
                name: control.icon.name
                source: control.icon.source
                color: control.icon.color
            }

            PressOverlay {
                radius: parent.radius
                pressed: control.down
            }

            FocusRing {
                visible: control.visualFocus
                targetRadius: parent.radius
            }
        }

        Text {
            id: label

            anchors.top: indicator.bottom
            anchors.topMargin: control.spacing
            width: parent.width
            text: control.text
            font: control.font
            color: control.checked ? control.theme.ink : control.theme.inkMuted
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    background: Item {}
}
