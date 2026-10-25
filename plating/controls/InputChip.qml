import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A value the user picked, removable with its × button
T.Control {
    id: control

    enum Variant {
        // The family's fill and ink
        Family,
        // Accent-soft and accent, with an optional icon
        Accent,
        // Surface and ink
        Plain
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int variant: InputChip.Plain
    property string text
    property colorFamily family
    // Accent only: a UiIcons name before the label
    property string iconName

    signal removeClicked

    readonly property color fillColor: control.variant === InputChip.Family ? control.family.fill
                                       : control.variant === InputChip.Accent ? control.theme.accentSoft
                                                                              : control.theme.surface
    readonly property color inkColor: control.variant === InputChip.Family ? control.family.ink
                                      : control.variant === InputChip.Accent ? control.theme.accent
                                                                             : control.theme.ink

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: UiMetrics.chipHeightS

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    leftPadding: UiMetrics.inputChipPaddingStart
    rightPadding: UiMetrics.inputChipPaddingEnd
    spacing: UiMetrics.space1
    font: control.variant === InputChip.Plain ? UiTypography.labelS : UiTypography.labelSBold

    Accessible.role: Accessible.StaticText
    Accessible.name: control.text

    contentItem: RowLayout {
        spacing: control.spacing

        Icon {
            visible: control.variant === InputChip.Accent && control.iconName !== ""
            Layout.preferredWidth: UiMetrics.iconXS
            Layout.preferredHeight: UiMetrics.iconXS
            name: control.iconName
            color: control.inkColor
        }

        Text {
            Layout.fillWidth: true
            text: control.text
            font: control.font
            color: control.inkColor
            elide: Text.ElideRight
        }

        T.Button {
            id: remove

            implicitWidth: UiMetrics.inputChipRemove
            implicitHeight: UiMetrics.inputChipRemove
            display: T.AbstractButton.IconOnly
            text: qsTr("Remove %1").arg(control.text)
            containmentMask: TouchTarget {
                target: remove
            }
            onClicked: control.removeClicked()

            contentItem: Item {
                Icon {
                    anchors.centerIn: parent
                    width: UiMetrics.iconXS
                    height: UiMetrics.iconXS
                    name: "close"
                    color: control.inkColor
                    strokeWidth: UiMetrics.iconStrokeChipClose
                }
            }

            background: Rectangle {
                radius: width / 2
                color: "transparent"

                PressOverlay {
                    radius: parent.radius
                    pressed: remove.down
                }

                FocusRing {
                    visible: remove.visualFocus
                    targetRadius: parent.radius
                }
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: control.fillColor
    }
}
