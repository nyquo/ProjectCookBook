import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A pill button. The label and the optional leading icon (icon.name or
// icon.source) are centered; to fill the available width, size it from the
// outside (Layout.fillWidth, anchors).
T.Button {
    id: control

    enum Variant {
        // Accent fill, raised: the screen's main action
        Primary,
        // Ink fill
        Secondary,
        // Surface fill, or bg when inset
        Quiet,
        // Accent-soft fill, accent label
        Tonal,
        // No fill, accent label
        Text,
        // No fill, dashed line border, accent label
        Dashed,
        // Danger fill; rare
        Danger
    }

    enum Size {
        Large,
        Medium,
        Small,
        ExtraSmall
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int variant: Button.Primary
    property int size: Button.Medium
    // Sits on a surface: Quiet fills with bg instead
    property bool inset: false
    // Quiet or Text: accent label and a plus icon, unless icon.name is set
    property bool add: false
    // Quiet or Text: danger label
    property bool destructive: false
    // Quiet or Text: ink-muted label, e.g. a sheet's "Cancel"
    property bool muted: false

    readonly property bool hasIcon: control.icon.name !== "" || control.icon.source.toString() !== ""
    readonly property bool strongFill: control.variant === Button.Primary
                                       || control.variant === Button.Secondary
                                       || control.variant === Button.Danger
    readonly property real sidePadding: {
        switch (control.size) {
        case Button.Large:
            return UiMetrics.buttonPaddingL
        case Button.Small:
            return UiMetrics.buttonPaddingS
        case Button.ExtraSmall:
            return UiMetrics.buttonPaddingXS
        default:
            return UiMetrics.buttonPaddingM
        }
    }
    readonly property real iconSidePadding: {
        switch (control.size) {
        case Button.Large:
            return UiMetrics.buttonIconPaddingL
        case Button.Small:
            return UiMetrics.buttonIconPaddingS
        case Button.ExtraSmall:
            return UiMetrics.buttonIconPaddingXS
        default:
            return UiMetrics.buttonIconPaddingM
        }
    }
    readonly property color fillColor: {
        switch (control.variant) {
        case Button.Primary:
            return control.theme.accent
        case Button.Secondary:
            return control.theme.ink
        case Button.Quiet:
            return control.inset ? control.theme.bg : control.theme.surface
        case Button.Tonal:
            return control.theme.accentSoft
        case Button.Danger:
            return control.theme.danger
        default:
            return "transparent"
        }
    }
    readonly property color labelColor: {
        switch (control.variant) {
        case Button.Primary:
            return control.theme.accentInk
        case Button.Secondary:
            return control.theme.bg
        case Button.Danger:
            return control.theme.dangerInk
        case Button.Tonal:
        case Button.Dashed:
            return control.theme.accent
        default:
            if (control.destructive)
                return control.theme.danger
            if (control.muted)
                return control.theme.inkMuted
            if (control.add || control.variant === Button.Text)
                return control.theme.accent
            return control.theme.ink
        }
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    leftPadding: control.hasIcon && !control.mirrored ? control.iconSidePadding : control.sidePadding
    rightPadding: control.hasIcon && control.mirrored ? control.iconSidePadding : control.sidePadding
    spacing: control.size === Button.ExtraSmall ? UiMetrics.buttonIconGapXS : UiMetrics.buttonIconGap

    readonly property real iconSize: {
        switch (control.size) {
        case Button.Large:
            return UiMetrics.buttonIconL
        case Button.ExtraSmall:
            return UiMetrics.buttonIconXS
        default:
            return UiMetrics.buttonIcon
        }
    }

    icon.name: control.add ? "plus" : ""
    icon.color: control.labelColor
    icon.width: control.iconSize
    icon.height: control.iconSize

    font: {
        const primary = control.variant === Button.Primary
        switch (control.size) {
        case Button.Large:
            return primary ? UiTypography.value : UiTypography.labelLBold
        case Button.Small:
            return primary ? UiTypography.labelLExtraBold : UiTypography.labelBold
        case Button.ExtraSmall:
            return primary ? UiTypography.qty : UiTypography.labelSBold
        default:
            return primary ? UiTypography.labelLExtraBold : UiTypography.labelLBold
        }
    }

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
            }

            Text {
                visible: control.text !== ""
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.labelColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    background: Rectangle {
        implicitWidth: implicitHeight
        implicitHeight: {
            switch (control.size) {
            case Button.Large:
                return UiMetrics.buttonHeightL
            case Button.Small:
                return UiMetrics.buttonHeightS
            case Button.ExtraSmall:
                return UiMetrics.buttonHeightXS
            default:
                return UiMetrics.buttonHeightM
            }
        }
        radius: height / 2
        color: control.fillColor

        RaisedShadow {
            visible: control.variant === Button.Primary
        }

        DashedOutline {
            anchors.fill: parent
            visible: control.variant === Button.Dashed
            color: control.theme.line
            radius: height / 2
        }

        PressOverlay {
            radius: height / 2
            pressed: control.down
            onStrongFill: control.strongFill
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: height / 2
        }
    }
}
