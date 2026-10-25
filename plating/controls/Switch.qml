import QtQuick
import QtQuick.Templates as T
import Plating

// An on/off switch, with an optional label on the right. Off, a small muted
// thumb in an outlined track; on, a bigger thumb in an accent track. The thumb
// follows a drag.
T.Switch {
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
        id: track

        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: UiMetrics.switchWidth
        implicitHeight: UiMetrics.switchHeight
        radius: height / 2
        color: control.checked ? control.theme.accent : control.theme.bg
        border.width: control.checked ? 0 : UiMetrics.borderStrong
        border.color: control.theme.inkMuted

        Rectangle {
            id: thumb

            // 0 off, 1 on, in between while dragged
            readonly property real position: control.visualPosition

            x: UiMetrics.switchThumbInsetOff
               + thumb.position * (track.width - UiMetrics.switchThumbInsetOn - UiMetrics.switchThumbOn
                                   - UiMetrics.switchThumbInsetOff)
            y: (track.height - height) / 2
            width: UiMetrics.switchThumbOff + thumb.position * (UiMetrics.switchThumbOn - UiMetrics.switchThumbOff)
            height: width
            radius: width / 2
            color: control.checked ? control.theme.accentInk : control.theme.inkMuted

            Behavior on x {
                enabled: !control.pressed

                NumberAnimation {
                    duration: UiMotion.move(UiMotion.toggle)
                    easing.type: Easing.Bezier
                    easing.bezierCurve: UiMotion.decelerate
                }
            }

            Behavior on width {
                enabled: !control.pressed

                NumberAnimation {
                    duration: UiMotion.move(UiMotion.toggle)
                    easing.type: Easing.Bezier
                    easing.bezierCurve: UiMotion.decelerate
                }
            }
        }

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

    contentItem: Text {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        visible: control.text !== ""
        text: control.text
        font: control.font
        color: control.theme.ink
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
