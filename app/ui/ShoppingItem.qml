pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// An item of the shopping list: the whole row is a check box. Its ingredient
// icon in its aisle's color family, its name over where it comes from, and its
// quantities (several when their units can't merge). Checked, it's struck
// through and quieter. Press and hold (or the context-menu key) emits
// longPressed() instead of toggling.
T.CheckBox {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // As given ("Gratin, Dahl", "Added by you")
    property string sources
    // As given ("500 g", "2 pcs")
    property var quantities: []
    // An IngredientIcons name; the jar without one
    property string ingredientIcon
    // The aisle's family
    property colorFamily family

    signal longPressed

    // Set when a hold fired, so the release doesn't toggle
    property bool held: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(control.checked ? CookbookMetrics.shoppingItemHeightChecked
                                             : CookbookMetrics.shoppingItemHeight,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topPadding: control.checked ? CookbookMetrics.shoppingItemPaddingVChecked : CookbookMetrics.shoppingItemPaddingV
    bottomPadding: control.topPadding
    leftPadding: 0
    rightPadding: 0
    spacing: CookbookMetrics.shoppingItemGap
    font: control.checked ? UiTypography.strikeout(UiTypography.valueSemiBold) : UiTypography.valueBold

    nextCheckState: function() {
        if (control.held) {
            control.held = false
            return control.checkState
        }
        return control.checked ? Qt.Unchecked : Qt.Checked
    }

    onPressedChanged: {
        if (control.pressed) {
            control.held = false
            hold.restart()
            shrink.restart()
        } else {
            hold.stop()
            shrink.stop()
            release.restart()
        }
    }

    onCheckedChanged: {
        if (control.checked && !UiMotion.reduced)
            pop.restart()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu) {
            control.longPressed()
            event.accepted = true
        }
    }

    Timer {
        id: hold

        interval: UiMotion.longPress
        onTriggered: {
            control.held = true
            control.longPressed()
        }
    }

    // The row shrinks over the hold, and springs back if released early
    NumberAnimation {
        id: shrink

        target: control
        property: "scale"
        to: UiMotion.reduced ? 1 : UiMotion.longPressScale
        duration: UiMotion.move(UiMotion.longPress)
    }

    NumberAnimation {
        id: release

        target: control
        property: "scale"
        to: 1
        duration: UiMotion.move(UiMotion.longPressRelease)
        easing.type: Easing.OutBack
    }

    indicator: Rectangle {
        id: circle

        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: CookbookMetrics.shoppingCheck
        implicitHeight: CookbookMetrics.shoppingCheck
        radius: width / 2
        color: control.checked ? control.theme.accent : "transparent"
        border.width: control.checked ? 0 : CookbookMetrics.shoppingCheckRing
        border.color: control.theme.ink

        Icon {
            anchors.centerIn: parent
            width: UiMetrics.iconM
            height: UiMetrics.iconM
            visible: control.checked
            name: "check"
            color: control.theme.accentInk
            strokeWidth: UiMetrics.iconStrokeCheck
        }

        NumberAnimation {
            id: pop

            target: circle
            property: "scale"
            from: UiMotion.checkPopScale
            to: 1
            duration: UiMotion.move(UiMotion.checkPop)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
    }

    contentItem: RowLayout {
        spacing: control.spacing

        Item {
            implicitWidth: control.indicator.width
        }

        IconBadge {
            shape: IconBadge.Tile
            size: IconBadge.Small
            iconSource: IngredientIcons.source(control.ingredientIcon)
            family: control.family
            muted: control.checked
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: control.text
                font: control.font
                color: control.checked ? control.theme.inkMuted : control.theme.ink
                elide: Text.ElideRight
            }

            Text {
                visible: !control.checked && control.sources !== ""
                Layout.fillWidth: true
                text: control.sources
                font: UiTypography.caption
                color: control.theme.inkMuted
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            spacing: CookbookMetrics.shoppingQuantityGap

            Repeater {
                model: control.quantities

                delegate: Item {
                    id: amountLine

                    required property string modelData

                    Layout.alignment: Qt.AlignRight
                    implicitWidth: control.checked ? plainQuantity.implicitWidth : pill.implicitWidth
                    implicitHeight: control.checked ? plainQuantity.implicitHeight : pill.implicitHeight

                    QuantityPill {
                        id: pill

                        anchors.right: parent.right
                        visible: !control.checked
                        variant: QuantityPill.List
                        quantity: amountLine.modelData
                    }

                    Text {
                        id: plainQuantity

                        anchors.right: parent.right
                        visible: control.checked
                        text: amountLine.modelData
                        font: UiTypography.labelBold
                        color: control.theme.inkMuted
                    }
                }
            }
        }
    }

    background: Item {
        PressOverlay {
            anchors.leftMargin: -UiMetrics.listRowPressBleed
            anchors.rightMargin: -UiMetrics.listRowPressBleed
            radius: UiMetrics.radiusMd
            pressed: control.down
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: UiMetrics.radiusMd
        }
    }
}
