import QtQuick
import QtQuick.Templates as T
import Plating

// A round check box with its label on the right; the whole row toggles it
T.CheckBox {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding,
                             UiMetrics.sizeTouch)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    spacing: UiMetrics.checkBoxGap
    font: UiTypography.label

    indicator: Rectangle {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: UiMetrics.checkBoxSize
        implicitHeight: UiMetrics.checkBoxSize
        radius: width / 2
        color: control.checked ? control.theme.accent : "transparent"
        border.width: control.checked ? 0 : UiMetrics.borderStrong
        border.color: control.theme.ink

        Icon {
            anchors.centerIn: parent
            width: UiMetrics.iconS
            height: UiMetrics.iconS
            visible: control.checked
            name: "check"
            color: control.theme.accentInk
            strokeWidth: UiMetrics.iconStrokeCheck
        }

        PressOverlay {
            radius: width / 2
            pressed: control.down
            onStrongFill: control.checked
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: width / 2
        }
    }

    contentItem: Text {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: control.theme.ink
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
