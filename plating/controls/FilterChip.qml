import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A filter to turn on and off: a checkable pill with an optional icon before
// its label (icon.name, icon.source) and, while on, an optional count. Round:
// icon only, `text` is its accessible name, and the icon fills while on.
T.Button {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // As given; shown in a badge while checked
    property string count
    property bool round: false

    readonly property bool hasIcon: control.icon.name !== "" || control.icon.source.toString() !== ""
    readonly property bool showsCount: control.checked && control.count !== "" && !control.round
    readonly property color labelColor: control.checked ? control.theme.bg : control.theme.ink

    implicitWidth: control.round ? UiMetrics.chipHeightL
                                 : Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: UiMetrics.chipHeightL

    checkable: true
    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    leftPadding: control.round ? 0 : control.hasIcon ? UiMetrics.filterChipIconPadding : UiMetrics.filterChipPadding
    rightPadding: control.round ? 0 : control.showsCount ? UiMetrics.filterChipBadgePadding : UiMetrics.filterChipPadding
    spacing: UiMetrics.space2
    display: control.round ? T.AbstractButton.IconOnly : T.AbstractButton.TextBesideIcon

    icon.width: UiMetrics.iconM
    icon.height: UiMetrics.iconM
    icon.color: control.round ? control.theme.accent : control.labelColor
    font: control.checked ? UiTypography.labelBold : UiTypography.label

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        RowLayout {
            id: content

            anchors.centerIn: parent
            width: Math.min(content.implicitWidth, parent.width)
            spacing: control.spacing

            Icon {
                visible: control.hasIcon
                Layout.preferredWidth: control.icon.width
                Layout.preferredHeight: control.icon.height
                name: control.icon.name
                source: control.icon.source
                color: control.icon.color
                filled: control.round && control.checked
            }

            Text {
                visible: !control.round
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.labelColor
                elide: Text.ElideRight
            }

            Rectangle {
                visible: control.showsCount
                implicitWidth: Math.max(UiMetrics.filterChipBadge, countText.implicitWidth + 2 * UiMetrics.space1)
                implicitHeight: UiMetrics.filterChipBadge
                radius: height / 2
                color: control.theme.accent

                Text {
                    id: countText

                    anchors.centerIn: parent
                    text: control.count
                    font: UiTypography.captionExtraBold
                    color: control.theme.accentInk
                }
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: !control.checked ? control.theme.surface
                                : control.round ? control.theme.accentSoft : control.theme.ink

        PressOverlay {
            radius: parent.radius
            pressed: control.down
            onStrongFill: control.checked && !control.round
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }
}
