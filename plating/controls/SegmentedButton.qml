import QtQuick
import QtQuick.Templates as T
import Plating

// An option of a SegmentedControl: a label, with an optional icon before it
// (icon.name, icon.source) or a second line under it (detail)
T.TabButton {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string detail

    readonly property bool plain: (T.TabBar.tabBar as SegmentedControl)?.plain ?? false
    readonly property bool hasIcon: control.icon.name !== "" || control.icon.source.toString() !== ""
    readonly property color labelColor: control.checked ? control.theme.bg : control.theme.ink

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0
    leftPadding: UiMetrics.segmentPadding
    rightPadding: UiMetrics.segmentPadding
    spacing: UiMetrics.space2

    icon.width: UiMetrics.iconM
    icon.height: UiMetrics.iconM
    icon.color: control.labelColor
    font: control.plain ? UiTypography.labelSBold
                        : control.checked ? UiTypography.labelBold : UiTypography.label

    contentItem: Item {
        id: content

        readonly property real iconSpace: control.hasIcon ? control.icon.width + control.spacing : 0

        implicitWidth: Math.max(content.iconSpace + label.implicitWidth, detailText.implicitWidth)
        implicitHeight: label.implicitHeight + (detailText.visible ? detailText.implicitHeight : 0)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - parent.implicitHeight) / 2
            spacing: control.spacing

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.hasIcon
                width: control.icon.width
                height: control.icon.height
                name: control.icon.name
                source: control.icon.source
                color: control.icon.color
            }

            Text {
                id: label

                width: Math.min(implicitWidth, content.width - content.iconSpace)
                text: control.text
                font: control.font
                color: control.labelColor
                elide: Text.ElideRight
            }
        }

        Text {
            id: detailText

            anchors.horizontalCenter: parent.horizontalCenter
            y: (parent.height - parent.implicitHeight) / 2 + label.implicitHeight
            width: Math.min(implicitWidth, content.width)
            visible: control.detail !== ""
            text: control.detail
            font: UiTypography.microMedium
            color: control.checked ? Qt.alpha(control.theme.bg, UiMetrics.opacityMuted) : control.theme.inkMuted
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        implicitHeight: UiMetrics.segmentHeight
        radius: height / 2
        color: control.checked ? control.theme.ink : control.plain ? control.theme.bg : "transparent"

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
