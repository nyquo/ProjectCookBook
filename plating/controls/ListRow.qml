import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A clickable row, usually in a ListGroup: leading icon or item, title and
// subtitle, then a value and a chevron, or a trailing item. Clicking a row
// whose trailing item is a Switch toggles it. `highlighted` makes it the ink
// call-to-action row that ends with an arrow.
T.ItemDelegate {
    id: control

    enum Tone {
        // Accent icon on accent-soft
        Accent,
        // Ink icon on bg
        Neutral
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string subtitle
    // The subtitle says something is left to do: accent, bolder
    property bool subtitleAccent: false
    // Bolder title
    property bool strong: false
    // Already used: faded
    property bool used: false
    // The disc behind icon.name or icon.source
    property int iconTone: ListRow.Accent
    // Instead of the icon disc: an IconBadge, a TagPill…
    property Item leading
    property string value
    property bool chevron: false
    // A Switch, a small Stepper, a small IconButton…
    property Item trailing

    readonly property bool hasIcon: control.icon.name !== "" || control.icon.source.toString() !== ""
    readonly property bool tall: control.highlighted || control.hasIcon || control.leading !== null
                                 || control.subtitle !== ""

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(control.tall ? UiMetrics.listRowHeightTall : UiMetrics.listRowHeight,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: !control.enabled ? UiMetrics.opacityDisabled : control.used ? UiMetrics.opacitySecondary : 1
    topPadding: UiMetrics.listRowPaddingV
    bottomPadding: UiMetrics.listRowPaddingV
    leftPadding: !control.highlighted ? 0
                                      : control.mirrored ? UiMetrics.listRowHighlightPaddingEnd
                                                         : UiMetrics.listRowHighlightPaddingStart
    rightPadding: !control.highlighted ? 0
                                       : control.mirrored ? UiMetrics.listRowHighlightPaddingStart
                                                          : UiMetrics.listRowHighlightPaddingEnd
    spacing: UiMetrics.listRowGap

    icon.width: UiMetrics.iconL
    icon.height: UiMetrics.iconL
    icon.color: control.iconTone === ListRow.Accent ? control.theme.accent : control.theme.ink
    font: control.highlighted ? UiTypography.labelLExtraBold
                              : control.strong ? UiTypography.labelLBold : UiTypography.labelL

    onClicked: {
        if (control.trailing instanceof T.Switch)
            (control.trailing as T.Switch).click()
    }

    contentItem: RowLayout {
        spacing: control.spacing

        Rectangle {
            visible: control.hasIcon && control.leading === null
            implicitWidth: UiMetrics.listRowDisc
            implicitHeight: UiMetrics.listRowDisc
            radius: width / 2
            color: control.iconTone === ListRow.Accent ? control.theme.accentSoft : control.theme.bg

            Icon {
                anchors.centerIn: parent
                width: control.icon.width
                height: control.icon.height
                name: control.icon.name
                source: control.icon.source
                color: control.icon.color
            }
        }

        Item {
            visible: control.leading !== null
            implicitWidth: control.leading?.implicitWidth ?? 0
            implicitHeight: control.leading?.implicitHeight ?? 0
            children: control.leading ? [control.leading] : []
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.highlighted ? control.theme.bg : control.theme.ink
                elide: Text.ElideRight
            }

            Text {
                visible: control.subtitle !== ""
                Layout.fillWidth: true
                text: control.subtitle
                font: control.subtitleAccent ? UiTypography.captionSemiBold : UiTypography.caption
                color: control.highlighted ? control.theme.bg
                                           : control.subtitleAccent ? control.theme.accent
                                                                    : control.theme.inkMuted
                opacity: control.highlighted ? UiMetrics.opacitySecondary : 1
                elide: Text.ElideRight
            }
        }

        Text {
            visible: control.value !== "" && !control.highlighted
            text: control.value
            font: UiTypography.bodyS
            color: control.theme.inkMuted
        }

        Icon {
            visible: control.chevron && !control.highlighted
            Layout.preferredWidth: UiMetrics.iconM
            Layout.preferredHeight: UiMetrics.iconM
            name: "chevron-right"
            color: control.theme.inkMuted
        }

        Item {
            visible: control.trailing !== null
            implicitWidth: control.trailing?.implicitWidth ?? 0
            implicitHeight: control.trailing?.implicitHeight ?? 0
            children: control.trailing ? [control.trailing] : []
        }

        Rectangle {
            visible: control.highlighted
            implicitWidth: UiMetrics.listRowDisc
            implicitHeight: UiMetrics.listRowDisc
            radius: width / 2
            color: control.theme.accent

            Icon {
                anchors.centerIn: parent
                width: UiMetrics.iconL
                height: UiMetrics.iconL
                name: "arrow-right"
                color: control.theme.accentInk
            }
        }
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: control.highlighted
            radius: UiMetrics.listRowHighlightRadius
            color: control.theme.ink
        }

        // Past the sides of a plain row, so its content doesn't touch the edge
        Item {
            anchors.fill: parent
            anchors.leftMargin: control.highlighted ? 0 : -UiMetrics.listRowPressBleed
            anchors.rightMargin: control.highlighted ? 0 : -UiMetrics.listRowPressBleed

            PressOverlay {
                radius: control.highlighted ? UiMetrics.listRowHighlightRadius : UiMetrics.radiusMd
                pressed: control.down
                onStrongFill: control.highlighted
            }

            FocusRing {
                visible: control.visualFocus
                targetRadius: control.highlighted ? UiMetrics.listRowHighlightRadius : UiMetrics.radiusMd
            }
        }
    }
}
