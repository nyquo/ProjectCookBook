import QtQuick
import QtQuick.Templates as T
import Plating

// A color to choose: a disc of family.fill, ringed in ink outside a gap when
// checked. Default: smaller than ColorSwatch. Large: a bigger disc, with a
// check in family.ink when checked. `text` isn't shown: it's the color's
// accessible name, so always set it. Controlled: bind `checked`, and change it
// from clicked().
T.RadioButton {
    id: control

    enum Size {
        Default,
        Large
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property colorFamily family
    property int size: ColorDot.Default

    readonly property bool large: control.size === ColorDot.Large

    implicitWidth: control.large ? CookbookMetrics.colorDotRingL : CookbookMetrics.colorDotTarget
    implicitHeight: implicitWidth

    checkable: false
    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0
    indicator: null
    contentItem: null

    background: Item {
        Rectangle {
            anchors.centerIn: parent
            width: control.large ? CookbookMetrics.colorDotRingL : CookbookMetrics.colorDotRing
            height: width
            visible: control.checked
            radius: width / 2
            color: "transparent"
            border.width: UiMetrics.borderStrong
            border.color: control.theme.ink
        }

        Rectangle {
            anchors.centerIn: parent
            width: control.large ? CookbookMetrics.colorDotDiscL : CookbookMetrics.colorDotDisc
            height: width
            radius: width / 2
            color: control.family.fill

            Icon {
                anchors.centerIn: parent
                width: CookbookMetrics.colorDotCheckL
                height: CookbookMetrics.colorDotCheckL
                visible: control.large && control.checked
                source: CookbookIcons.source("check")
                color: control.family.ink
            }

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
