import QtQuick
import QtQuick.Templates as T
import Plating

// A color to choose, as a radio button: a disc of family.fill; checked, a ring
// at the target's edge and a check in family.ink. `text` isn't shown: it's the
// color's accessible name, so always set it. Swatches in the same parent are
// exclusive.
T.RadioButton {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // For an accent: its value and its on-color; for a tag family: its fill and ink
    property colorFamily family

    implicitWidth: UiMetrics.swatchSize
    implicitHeight: UiMetrics.swatchSize

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    indicator: null
    contentItem: null

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: control.checked
            radius: width / 2
            color: "transparent"
            border.width: UiMetrics.borderStrong
            border.color: control.theme.ink
        }

        Rectangle {
            anchors.centerIn: parent
            width: UiMetrics.swatchDisc
            height: UiMetrics.swatchDisc
            radius: width / 2
            color: control.family.fill

            Icon {
                anchors.centerIn: parent
                width: UiMetrics.iconM
                height: UiMetrics.iconM
                visible: control.checked
                name: "check"
                color: control.family.ink
                strokeWidth: UiMetrics.iconStrokeSwatchCheck
            }

            PressOverlay {
                radius: width / 2
                pressed: control.down
            }
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: width / 2
        }
    }

    Component.onCompleted: {
        if (control.text === "")
            console.warn("ColorSwatch: set text, the color's accessible name")
    }
}
