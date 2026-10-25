pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Plating

// The design's Select: a pill showing the current value and a chevron. Its
// popup looks like a Menu, under the field, with the current option checked.
T.ComboBox {
    id: control

    enum Size {
        // h44
        Default,
        // h52
        Medium
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: ComboBox.Default
    // Sits on a surface: fills with bg instead
    property bool inset: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topPadding: 0
    bottomPadding: 0
    leftPadding: UiMetrics.comboBoxPaddingStart
    rightPadding: UiMetrics.comboBoxPaddingEnd + UiMetrics.iconM + UiMetrics.comboBoxIconGap
    font: UiTypography.labelLBold

    delegate: MenuItem {
        required property int index

        width: ListView.view.width
        text: control.textAt(index)
        checked: control.currentIndex === index
        highlighted: control.highlightedIndex === index
    }

    indicator: Icon {
        x: control.width - width - UiMetrics.comboBoxPaddingEnd
        y: (control.height - height) / 2
        width: UiMetrics.iconM
        height: UiMetrics.iconM
        name: "chevron-down"
        color: control.theme.inkMuted
    }

    contentItem: Text {
        text: control.displayText
        font: control.font
        color: control.theme.ink
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: implicitHeight
        implicitHeight: control.size === ComboBox.Medium ? UiMetrics.comboBoxHeightMedium
                                                         : UiMetrics.comboBoxHeight
        radius: height / 2
        color: control.inset ? control.theme.bg : control.theme.surface

        PressOverlay {
            radius: parent.radius
            pressed: control.down
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }

    popup: T.Popup {
        y: control.height + UiMetrics.menuGap
        width: Math.max(control.width, UiMetrics.menuMinWidth)
        implicitHeight: implicitContentHeight + topPadding + bottomPadding
        margins: UiMetrics.menuMargin
        padding: UiMetrics.menuPadding
        transformOrigin: T.Popup.Top

        enter: Transition {
            NumberAnimation {
                property: "scale"
                from: UiMotion.reduced ? 1 : UiMotion.menuOpenScale
                to: 1
                duration: UiMotion.move(UiMotion.menuOpen)
                easing.type: Easing.Bezier
                easing.bezierCurve: UiMotion.decelerate
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: UiMotion.fade(UiMotion.menuOpen)
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: UiMotion.fade(UiMotion.menuClose)
            }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
        }

        background: MenuPanel {}
    }
}
