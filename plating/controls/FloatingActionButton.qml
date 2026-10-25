import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// The floating action button: an accent disc with a plus, raised. Extended, it
// also shows `text`; otherwise `text` is only its accessible name, so always
// set it.
T.Button {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property bool extended: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    leftPadding: !control.extended ? 0 : control.mirrored ? UiMetrics.fabPadding : UiMetrics.fabPaddingIcon
    rightPadding: !control.extended ? 0 : control.mirrored ? UiMetrics.fabPaddingIcon : UiMetrics.fabPadding
    spacing: UiMetrics.buttonIconGap
    display: control.extended ? T.AbstractButton.TextBesideIcon : T.AbstractButton.IconOnly

    icon.name: "plus"
    icon.width: UiMetrics.fabIcon
    icon.height: UiMetrics.fabIcon
    icon.color: control.theme.accentInk
    font: UiTypography.labelLExtraBold

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        RowLayout {
            id: content

            anchors.centerIn: parent
            width: Math.min(content.implicitWidth, parent.width)
            spacing: control.spacing

            Icon {
                Layout.preferredWidth: control.icon.width
                Layout.preferredHeight: control.icon.height
                name: control.icon.name
                source: control.icon.source
                color: control.icon.color
                strokeWidth: UiMetrics.iconStrokeEmphasis
            }

            Text {
                visible: control.extended
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.theme.accentInk
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        implicitWidth: UiMetrics.fabSize
        implicitHeight: UiMetrics.fabSize
        radius: height / 2
        color: control.theme.accent

        RaisedShadow {}

        PressOverlay {
            radius: height / 2
            pressed: control.down
            onStrongFill: true
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: height / 2
        }
    }

    Component.onCompleted: {
        if (control.text === "")
            console.warn("FloatingActionButton: set text, its accessible name")
    }
}
