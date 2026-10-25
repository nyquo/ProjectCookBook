import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A menu row, with an optional leading icon (icon.name, icon.source). Checked,
// it's tinted and bolder, and can show a hint under its label and an arrow
// disc on the right.
T.MenuItem {
    id: control

    enum Arrow {
        NoArrow,
        Up,
        Down
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    // In danger; goes last, after a MenuSeparator
    property bool destructive: false
    // A line under the label, e.g. what tapping the checked item again does
    property string hint
    // An accent disc with an arrow, on the right
    property int trailingArrow: MenuItem.NoArrow

    readonly property bool hasIcon: control.icon.name !== "" || control.icon.source.toString() !== ""
    readonly property color labelColor: control.destructive ? control.theme.danger
                                                            : control.checked ? control.theme.accent
                                                                              : control.theme.ink

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topPadding: UiMetrics.menuItemPaddingV
    bottomPadding: UiMetrics.menuItemPaddingV
    leftPadding: UiMetrics.menuItemPaddingH
    rightPadding: UiMetrics.menuItemPaddingH
    spacing: UiMetrics.space3

    icon.width: UiMetrics.iconL
    icon.height: UiMetrics.iconL
    icon.color: control.labelColor
    font: control.checked ? UiTypography.labelLExtraBold : UiTypography.labelL

    indicator: null
    arrow: null

    contentItem: RowLayout {
        spacing: control.spacing

        Icon {
            visible: control.hasIcon
            Layout.preferredWidth: control.icon.width
            Layout.preferredHeight: control.icon.height
            name: control.icon.name
            source: control.icon.source
            color: control.icon.color
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.labelColor
                elide: Text.ElideRight
            }

            Text {
                visible: control.hint !== ""
                Layout.fillWidth: true
                text: control.hint
                font: UiTypography.overlineMedium
                color: control.theme.inkMuted
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: control.trailingArrow !== MenuItem.NoArrow
            implicitWidth: UiMetrics.menuItemArrowDisc
            implicitHeight: UiMetrics.menuItemArrowDisc
            radius: width / 2
            color: control.theme.accent

            Icon {
                anchors.centerIn: parent
                width: UiMetrics.iconM
                height: UiMetrics.iconM
                name: control.trailingArrow === MenuItem.Up ? "arrow-up" : "arrow-down"
                color: control.theme.accentInk
            }
        }
    }

    background: Rectangle {
        implicitHeight: UiMetrics.menuItemHeight
        radius: UiMetrics.menuItemRadius
        color: control.checked ? control.theme.accentSoft : "transparent"

        PressOverlay {
            radius: parent.radius
            pressed: control.down || (control.highlighted && !control.checked)
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }
}
