import QtQuick
import QtQuick.Templates as T
import Plating

// A round icon-only button. `text` isn't shown: it's the accessible name, so
// always set it. A checkable one fills its icon when checked (a favorite heart).
T.Button {
    id: control

    enum Variant {
        // Surface fill, ink icon
        Surface,
        // No fill, muted icon
        Ghost,
        // Surface fill, accent icon
        Tint,
        // Accent fill
        Accent,
        // Accent-soft fill, accent icon
        Tonal,
        // No fill, danger icon
        Destructive
    }

    enum Size {
        // 44: the default
        Default,
        // 40, inside rows and fields; still takes 44 presses
        Small,
        // 48: header actions, buttons over a photo
        Large
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int variant: IconButton.Surface
    property int size: IconButton.Default

    readonly property real discSize: {
        switch (control.size) {
        case IconButton.Small:
            return UiMetrics.iconButtonSizeS
        case IconButton.Large:
            return UiMetrics.iconButtonSizeL
        default:
            return UiMetrics.iconButtonSize
        }
    }
    readonly property real iconSize: {
        switch (control.size) {
        case IconButton.Small:
            return UiMetrics.iconM
        case IconButton.Large:
            return UiMetrics.sizeIcon
        default:
            return UiMetrics.iconL
        }
    }

    implicitWidth: control.discSize
    implicitHeight: control.discSize

    padding: 0
    display: T.AbstractButton.IconOnly
    containmentMask: TouchTarget {
        target: control
    }

    icon.width: control.iconSize
    icon.height: control.iconSize
    // Disabled has its own look: no fill, the icon in line
    icon.color: {
        if (!control.enabled)
            return control.theme.line
        switch (control.variant) {
        case IconButton.Ghost:
            return control.theme.inkMuted
        case IconButton.Tint:
        case IconButton.Tonal:
            return control.theme.accent
        case IconButton.Accent:
            return control.theme.accentInk
        case IconButton.Destructive:
            return control.theme.danger
        default:
            return control.theme.ink
        }
    }

    contentItem: Item {
        Icon {
            anchors.centerIn: parent
            width: control.icon.width
            height: control.icon.height
            name: control.icon.name
            source: control.icon.source
            color: control.icon.color
            filled: control.checked
        }
    }

    background: Rectangle {
        radius: width / 2
        color: {
            if (!control.enabled)
                return "transparent"
            switch (control.variant) {
            case IconButton.Surface:
            case IconButton.Tint:
                return control.theme.surface
            case IconButton.Accent:
                return control.theme.accent
            case IconButton.Tonal:
                return control.theme.accentSoft
            default:
                return "transparent"
            }
        }

        PressOverlay {
            radius: width / 2
            pressed: control.down
            onStrongFill: control.variant === IconButton.Accent
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: width / 2
        }
    }

    Component.onCompleted: {
        if (control.text === "")
            console.warn("IconButton: set text, its accessible name")
    }
}
