import QtQuick
import QtQuick.Templates as T
import Plating

// A color to choose, smaller than ColorSwatch: a disc of family.fill, ringed in
// ink when checked. `text` isn't shown: it's the color's accessible name, so
// always set it. Controlled: bind `checked`, and change it from clicked().
T.RadioButton {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property colorFamily family

    implicitWidth: CookbookMetrics.colorDotTarget
    implicitHeight: CookbookMetrics.colorDotTarget

    checkable: false
    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    indicator: null
    contentItem: null

    background: Item {
        Rectangle {
            anchors.centerIn: parent
            width: CookbookMetrics.colorDotRing
            height: width
            visible: control.checked
            radius: width / 2
            color: "transparent"
            border.width: UiMetrics.borderStrong
            border.color: control.theme.ink
        }

        Rectangle {
            anchors.centerIn: parent
            width: CookbookMetrics.colorDotDisc
            height: width
            radius: width / 2
            color: control.family.fill

            PressOverlay {
                radius: width / 2
                pressed: control.down
            }

            FocusRing {
                visible: control.visualFocus
                targetRadius: width / 2
            }
        }
    }

    Component.onCompleted: {
        if (control.text === "")
            console.warn("ColorDot: set text, the color's accessible name")
    }
}
