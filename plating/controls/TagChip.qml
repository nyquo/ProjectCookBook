import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A tag to select, in its color family. Off: a dot of the family's fill before
// the name. On: the family's fill and ink, a ring and a check.
T.Button {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property colorFamily family
    // Sits on a surface: fills with bg instead while off
    property bool inset: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: UiMetrics.chipHeight

    checkable: true
    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    leftPadding: UiMetrics.tagChipPaddingStart
    rightPadding: UiMetrics.chipPadding
    spacing: UiMetrics.space2
    font: control.checked ? UiTypography.labelSBold : UiTypography.labelS

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        RowLayout {
            id: content

            anchors.centerIn: parent
            width: Math.min(content.implicitWidth, parent.width)
            spacing: control.spacing

            Item {
                implicitWidth: control.checked ? UiMetrics.iconS : UiMetrics.chipDot
                implicitHeight: UiMetrics.iconS

                Rectangle {
                    anchors.centerIn: parent
                    visible: !control.checked
                    width: UiMetrics.chipDot
                    height: UiMetrics.chipDot
                    radius: width / 2
                    color: control.family.fill
                }

                Icon {
                    anchors.fill: parent
                    visible: control.checked
                    name: "check"
                    color: control.family.ink
                }
            }

            Text {
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.checked ? control.family.ink : control.theme.ink
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: control.checked ? control.family.fill : control.inset ? control.theme.bg : control.theme.surface
        border.width: control.checked ? UiMetrics.borderStrong : 0
        border.color: control.family.ink

        PressOverlay {
            radius: parent.radius
            pressed: control.down
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }
}
