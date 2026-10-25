import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A choice in a row of options, checkable, with an optional colored dot before
// its label. Exclusive when in a ButtonGroup or autoExclusive. `add` makes it
// the outlined "+ New…" chip that ends a grid; it isn't checkable then.
T.Button {
    id: control

    enum Size {
        // h40
        Default,
        // h36
        Small,
        // h44, in a two-column grid
        Grid
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: ChoiceChip.Default
    // Sits on a surface: fills with bg instead
    property bool inset: false
    // A dot before the label, e.g. an aisle's color; none while transparent
    property color dotColor: "transparent"
    property bool add: false

    readonly property bool hasDot: control.dotColor.a > 0 && !control.add
    readonly property color labelColor: control.add ? control.theme.accent
                                                    : control.checked ? control.theme.bg : control.theme.ink

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: control.size === ChoiceChip.Small ? UiMetrics.chipHeightS
                                                      : control.size === ChoiceChip.Grid ? UiMetrics.chipHeightL
                                                                                         : UiMetrics.chipHeight

    checkable: !control.add
    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    leftPadding: control.hasDot || control.add ? UiMetrics.chipDotPadding : UiMetrics.chipPadding
    rightPadding: UiMetrics.chipPadding
    spacing: UiMetrics.space2

    icon.name: control.add ? "plus" : ""
    icon.width: UiMetrics.iconM
    icon.height: UiMetrics.iconM
    icon.color: control.labelColor
    font: control.checked ? UiTypography.labelSBold : UiTypography.labelS

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        RowLayout {
            id: content

            anchors.centerIn: parent
            width: Math.min(content.implicitWidth, parent.width)
            spacing: control.spacing

            Rectangle {
                visible: control.hasDot
                implicitWidth: UiMetrics.chipDot
                implicitHeight: UiMetrics.chipDot
                radius: width / 2
                color: control.dotColor
            }

            Icon {
                visible: control.icon.name !== "" || control.icon.source.toString() !== ""
                Layout.preferredWidth: control.icon.width
                Layout.preferredHeight: control.icon.height
                name: control.icon.name
                source: control.icon.source
                color: control.icon.color
            }

            Text {
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.labelColor
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: control.add ? "transparent"
                           : control.checked ? control.theme.ink
                                             : control.inset ? control.theme.bg : control.theme.surface
        border.width: control.add ? UiMetrics.borderThin : 0
        border.color: control.theme.line

        PressOverlay {
            radius: parent.radius
            pressed: control.down
            onStrongFill: control.checked
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }
}
