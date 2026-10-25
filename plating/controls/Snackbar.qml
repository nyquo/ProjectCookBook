import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A short message at the bottom of the window, with an optional action
// ("Undo"). show() opens it for snackbarStay; one at a time, so showing another
// replaces it. Put one per window, and set bottomOffset to the height of the
// bottom navigation or actions it sits above.
T.Popup {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string text
    property string actionText
    // The height of what it sits above; without any it sits above the safe area
    property real bottomOffset: 0
    // Animated on entry: it rises from snackbarMargin lower
    property real rise: 0

    signal actionClicked

    function show(message: string, action: string) {
        control.text = message
        control.actionText = action
        stay.restart()
        if (control.opened)
            replace.restart()
        else
            control.open()
    }

    parent: T.Overlay.overlay
    modal: false
    focus: false
    closePolicy: T.Popup.NoAutoClose

    x: UiMetrics.snackbarMargin + control.SafeArea.margins.left
    y: (control.parent?.height ?? 0) - height - UiMetrics.snackbarMargin
       - Math.max(control.bottomOffset, control.SafeArea.margins.bottom) + control.rise
    width: (control.parent?.width ?? 0) - 2 * UiMetrics.snackbarMargin
           - control.SafeArea.margins.left - control.SafeArea.margins.right
    implicitHeight: UiMetrics.snackbarHeight

    padding: 0
    leftPadding: UiMetrics.snackbarPaddingStart
    rightPadding: UiMetrics.snackbarPaddingEnd

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: UiMotion.fade(UiMotion.snackbarEnter)
        }
        NumberAnimation {
            property: "rise"
            from: UiMotion.reduced ? 0 : UiMetrics.snackbarMargin
            to: 0
            duration: UiMotion.move(UiMotion.snackbarEnter)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: UiMotion.fade(UiMotion.snackbarLeave)
        }
    }

    Timer {
        id: stay

        interval: UiMotion.snackbarStay
        onTriggered: control.close()
    }

    // The new message arrives like a new snackbar
    ParallelAnimation {
        id: replace

        NumberAnimation {
            target: control
            property: "opacity"
            from: 0
            to: 1
            duration: UiMotion.fade(UiMotion.snackbarEnter)
        }
        NumberAnimation {
            target: control
            property: "rise"
            from: UiMotion.reduced ? 0 : UiMetrics.snackbarMargin
            to: 0
            duration: UiMotion.move(UiMotion.snackbarEnter)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
    }

    contentItem: RowLayout {
        spacing: UiMetrics.space3

        Text {
            Layout.fillWidth: true
            text: control.text
            font: UiTypography.label
            color: control.theme.bg
            elide: Text.ElideRight
            Accessible.role: Accessible.AlertMessage
            Accessible.name: control.text
        }

        T.Button {
            id: action

            visible: control.actionText !== ""
            implicitWidth: implicitContentWidth + leftPadding + rightPadding
            implicitHeight: UiMetrics.snackbarActionHeight
            leftPadding: UiMetrics.snackbarActionPadding
            rightPadding: UiMetrics.snackbarActionPadding
            text: control.actionText
            font: UiTypography.labelExtraBold
            onClicked: {
                control.actionClicked()
                control.close()
            }

            contentItem: Text {
                text: action.text
                font: action.font
                color: control.theme.accentInk
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: height / 2
                color: control.theme.accent

                PressOverlay {
                    radius: parent.radius
                    pressed: action.down
                    onStrongFill: true
                }

                FocusRing {
                    visible: action.visualFocus
                    targetRadius: parent.radius
                }
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: control.theme.ink
    }
}
