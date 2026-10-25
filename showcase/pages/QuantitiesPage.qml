import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

GroupPage {
    id: page

    // Sample unit lists, as the app would get them from the core
    readonly property var metricUnits: [
        { key: "pcs", label: qsTr("pcs"), step: 1, kind: "", factor: 1 },
        { key: "g", label: qsTr("g"), step: 50, kind: "mass", factor: 1 },
        { key: "kg", label: qsTr("kg"), step: 0.5, kind: "mass", factor: 1000 },
        { key: "ml", label: qsTr("ml"), step: 50, kind: "volume", factor: 1 },
        { key: "cl", label: qsTr("cl"), step: 10, kind: "volume", factor: 10 },
        { key: "l", label: qsTr("l"), step: 0.5, kind: "volume", factor: 1000 },
        { key: "pack", label: qsTr("pack"), step: 1, kind: "", factor: 1 },
        { key: "bunch", label: qsTr("bunch"), step: 1, kind: "", factor: 1 }
    ]
    readonly property var usUnits: [
        { key: "pcs", label: qsTr("pcs"), step: 1, kind: "", factor: 1 },
        { key: "oz", label: qsTr("oz"), step: 1, kind: "mass", factor: 28.3495 },
        { key: "lb", label: qsTr("lb"), step: 0.5, kind: "mass", factor: 453.592 },
        { key: "floz", label: qsTr("fl oz"), step: 1, kind: "volume", factor: 29.5735 },
        { key: "pack", label: qsTr("pack"), step: 1, kind: "", factor: 1 },
        { key: "bunch", label: qsTr("bunch"), step: 1, kind: "", factor: 1 }
    ]

    property bool us: false
    property real amount: 500
    property string unit: "ml"
    property real compactAmount: 2
    property string compactUnit: "lb"

    // The caller formats numbers: up to two decimals, in the user's locale
    function format(value: real): string {
        const text = value.toLocaleString(Qt.locale(), "f", 2)
        const point = Qt.locale().decimalPoint
        return text.indexOf(point) < 0 ? text : text.replace(/0+$/, "").replace(new RegExp(`\\${point}$`), "")
    }

    function labelOf(units: var, key: string): string {
        return units.find(unit => unit.key === key)?.label ?? ""
    }

    title: qsTr("Quantities")
    subtitle: qsTr("QuantityPill, QuantityField")

    Specimen {
        title: qsTr("QuantityPill: default")

        QuantityPill {
            quantity: qsTr("200 g")
        }
        QuantityPill {
            quantity: qsTr("1,2 kg")
        }
        QuantityPill {
            quantity: "2"
        }
        QuantityPill {
            quantity: qsTr("3 tbsp + 1 tsp")
        }
        QuantityPill {}
    }

    Specimen {
        title: qsTr("QuantityPill: list and small")

        QuantityPill {
            variant: QuantityPill.List
            quantity: qsTr("2 pcs")
        }
        QuantityPill {
            variant: QuantityPill.List
            quantity: qsTr("500 ml")
        }
        QuantityPill {
            variant: QuantityPill.Small
            quantity: "1"
        }
        QuantityPill {
            variant: QuantityPill.Small
            quantity: qsTr("50 g")
        }
        QuantityPill {
            variant: QuantityPill.Small
        }
    }

    Specimen {
        title: qsTr("QuantityField")
        note: qsTr("Steps follow the unit. Switching between ml, cl and l converts; switching to pcs keeps the number.")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space4

            SegmentedControl {
                Layout.fillWidth: true
                currentIndex: page.us ? 1 : 0
                onCurrentIndexChanged: {
                    const us = currentIndex === 1
                    if (us === page.us)
                        return
                    page.us = us
                    page.unit = us ? "floz" : "ml"
                    page.amount = us ? 16 : 500
                }

                SegmentedButton {
                    text: qsTr("Metric")
                }
                SegmentedButton {
                    text: qsTr("US")
                }
            }

            QuantityField {
                Layout.fillWidth: true
                units: page.us ? page.usUnits : page.metricUnits
                unit: page.unit
                amount: page.amount
                amountText: page.format(page.amount)
                summary: `${page.format(page.amount)} ${page.labelOf(units, page.unit)}`
                onAmountEdited: amount => page.amount = amount
                onUnitEdited: (unit, amount) => {
                    page.unit = unit
                    page.amount = amount
                }
            }
        }
    }

    Specimen {
        title: qsTr("QuantityField: compact, on a surface")
        onSurface: true

        QuantityField {
            width: parent.width
            variant: QuantityField.Compact
            units: page.usUnits
            unit: page.compactUnit
            amount: page.compactAmount
            amountText: page.format(page.compactAmount)
            onAmountEdited: amount => page.compactAmount = amount
            onUnitEdited: (unit, amount) => {
                page.compactUnit = unit
                page.compactAmount = amount
            }
        }
    }
}
