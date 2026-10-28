pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// The amount and unit of a shopping item: − and + around an input, then the
// units. Controlled: it emits amountEdited() and unitEdited(), and the caller
// updates amount, unit and their display strings. − and + step by the unit's
// step; − is off when one more step would reach 0. Switching to a unit of the
// same kind converts the amount (500 ml → 0.5 l); across kinds it keeps the
// number. The input takes a comma or a dot.
T.Control {
    id: control

    enum Variant {
        // A card with a header and a grid of units
        Default,
        // No card: a small stepper, then the units in one scrolling row
        Compact
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int variant: QuantityField.Default
    // [{ key, label, step, kind, factor }]: units of the same kind ("mass",
    // "volume"; "" for none) convert into each other, factor being the unit's
    // size in the kind's smallest unit (g: 1, kg: 1000)
    property var units: []
    // A key of `units`
    property string unit
    property real amount
    // The amount as shown in the input ("0,5")
    property string amountText
    // Default: the header's pill ("500 ml")
    property string summary
    // Default: the "Quantity" header and its pill. Off, the caller labels the
    // card itself.
    property bool header: true

    signal amountEdited(real amount)
    signal unitEdited(string unit, real amount)

    readonly property bool compact: control.variant === QuantityField.Compact
    readonly property var current: control.units.find(unit => unit.key === control.unit)
    readonly property real step: control.current?.step ?? 1

    function chooseUnit(next: var) {
        if (next.key === control.unit)
            return
        const sameKind = control.current && next.kind !== "" && next.kind === control.current.kind
        control.unitEdited(next.key, sameKind ? round(control.amount * control.current.factor / next.factor)
                                              : control.amount)
    }

    // Steps and conversions shouldn't leave 0.30000000000000004 behind
    function round(value: real): real {
        return Math.round(value * 1000) / 1000
    }

    // The amount, typed. Shows amountText unless it's being edited.
    component AmountInput: T.TextField {
        id: input

        implicitWidth: control.compact ? CookbookMetrics.quantityCompactInputWidth
                                       : CookbookMetrics.quantityInputWidth
        implicitHeight: control.compact ? UiMetrics.stepperButtonS : CookbookMetrics.quantityInputHeight
        padding: 0
        font: control.compact ? UiTypography.value : CookbookTypography.quantityInput
        color: control.theme.ink
        selectionColor: control.theme.accentSoft
        selectedTextColor: control.theme.ink
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        validator: RegularExpressionValidator {
            regularExpression: /^[0-9]*([.,][0-9]*)?$/
        }
        Accessible.name: qsTr("Quantity")

        onTextEdited: {
            const typed = Number(input.text.replace(",", "."))
            if (input.text !== "" && !isNaN(typed) && typed > 0)
                control.amountEdited(typed)
        }

        Binding on text {
            when: !input.activeFocus
            value: control.amountText
        }

        background: Rectangle {
            radius: control.compact ? height / 2 : UiMetrics.radiusMd
            color: control.compact ? "transparent" : control.theme.bg
            border.width: input.activeFocus ? UiMetrics.borderStrong : 0
            border.color: control.theme.accent
        }
    }

    // A unit to pick: a ChoiceChip, checked when it's the current one
    component UnitChip: ChoiceChip {
        id: chip

        required property var modelData

        text: chip.modelData.label
        checkable: false
        checked: chip.modelData.key === control.unit
        inset: true
        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: chip.checked
        onClicked: control.chooseUnit(chip.modelData)
    }

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: control.compact ? 0 : CookbookMetrics.quantityFieldPadding

    contentItem: Loader {
        sourceComponent: control.compact ? compactLayout : cardLayout
    }

    background: Rectangle {
        visible: !control.compact
        radius: UiMetrics.radiusLg
        color: control.theme.surface
    }

    Component {
        id: cardLayout

        ColumnLayout {
            spacing: CookbookMetrics.quantityFieldGap

            RowLayout {
                visible: control.header
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Quantity")
                    font: UiTypography.labelLBold
                    color: control.theme.ink
                    Accessible.role: Accessible.Heading
                }

                QuantityPill {
                    variant: QuantityPill.List
                    quantity: control.summary
                }
            }

            Stepper {
                Layout.alignment: Qt.AlignHCenter
                size: Stepper.Large
                spacing: CookbookMetrics.quantityFieldStepperGap
                canDecrease: control.amount - control.step > 0
                valueItem: AmountInput {}
                onDecreaseClicked: control.amountEdited(control.round(control.amount - control.step))
                onIncreaseClicked: control.amountEdited(control.round(control.amount + control.step))
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: CookbookMetrics.quantityUnitGap
                rowSpacing: CookbookMetrics.quantityUnitGap

                Repeater {
                    model: control.units

                    delegate: UnitChip {
                        Layout.fillWidth: true
                        // Equal columns, whatever the labels' widths
                        Layout.preferredWidth: 1
                        size: ChoiceChip.Grid
                        font: checked ? UiTypography.labelExtraBold : UiTypography.label
                    }
                }
            }
        }
    }

    Component {
        id: compactLayout

        RowLayout {
            spacing: UiMetrics.space2

            Stepper {
                size: Stepper.Small
                padding: CookbookMetrics.quantityCompactPadding
                canDecrease: control.amount - control.step > 0
                valueItem: AmountInput {}
                onDecreaseClicked: control.amountEdited(control.round(control.amount - control.step))
                onIncreaseClicked: control.amountEdited(control.round(control.amount + control.step))
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: unitScroller.height + 2 * CookbookMetrics.quantityCompactPadding
                radius: height / 2
                color: control.theme.bg
                clip: true

                ScrollArea {
                    id: unitScroller

                    x: CookbookMetrics.quantityCompactPadding
                    y: CookbookMetrics.quantityCompactPadding
                    width: parent.width - 2 * CookbookMetrics.quantityCompactPadding
                    height: unitRow.implicitHeight
                    contentWidth: unitRow.implicitWidth
                    orientation: Qt.Horizontal

                    Row {
                        id: unitRow

                        Repeater {
                            model: control.units

                            delegate: UnitChip {
                                width: Math.max(implicitWidth, CookbookMetrics.quantityUnitMinWidth)
                            }
                        }
                    }
                }
            }
        }
    }
}
