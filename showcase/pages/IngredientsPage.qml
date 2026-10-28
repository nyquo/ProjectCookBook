pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

GroupPage {
    id: page

    property int servings: 6
    property int editedStep: 1

    // Quantities for 6 servings, rescaled and formatted here as the app would
    readonly property real factor: page.servings / 6

    function format(value: real): string {
        const text = value.toLocaleString(Qt.locale(), "f", 1)
        const point = Qt.locale().decimalPoint
        return text.endsWith(`${point}0`) ? text.slice(0, -2) : text
    }

    function grams(value: real): string {
        return value >= 1000 ? qsTr("%1 kg").arg(page.format(value / 1000))
                             : qsTr("%1 g").arg(Math.round(value))
    }

    // The servings stepper, as the recipe screen gives its ingredients card
    component ServingsStepper: Stepper {
        text: `${page.servings}`
        unit: page.servings === 1 ? qsTr("serving") : qsTr("servings")
        canDecrease: page.servings > 1
        onDecreaseClicked: page.servings--
        onIncreaseClicked: page.servings++
    }

    title: qsTr("Ingredients and steps")
    subtitle: qsTr("IngredientsCard, IngredientRow, StepCard")

    Specimen {
        title: qsTr("IngredientRow in its card")
        note: qsTr("The stepper rescales the quantities; Substitute expands the alternatives.")

        IngredientsCard {
            width: parent.width
            trailing: ServingsStepper {}

            IngredientRow {
                Layout.fillWidth: true
                quantity: page.grams(1200 * page.factor)
                name: qsTr("Potatoes")
                note: qsTr("Firm-fleshed, such as Charlotte")
            }
            IngredientRow {
                Layout.fillWidth: true
                quantity: qsTr("%1 cl").arg(page.format(50 * page.factor))
                name: qsTr("Whole milk")
            }
            IngredientRow {
                Layout.fillWidth: true
                quantity: qsTr("%1 cl").arg(page.format(20 * page.factor))
                name: qsTr("Cream")
                alternatives: [qsTr("or %1 cl crème fraîche").arg(page.format(20 * page.factor)),
                    qsTr("or %1 cl whole milk and a knob of butter").arg(page.format(25 * page.factor))]
            }
            IngredientRow {
                Layout.fillWidth: true
                quantity: qsTr("%1 cloves").arg(Math.max(1, Math.round(2 * page.factor)))
                name: qsTr("Garlic")
                note: qsTr("Halved, to rub the dish")
            }
            IngredientRow {
                Layout.fillWidth: true
                name: qsTr("Nutmeg")
                optional: true
            }
        }
    }

    Specimen {
        title: qsTr("IngredientRow: editing")

        IngredientsCard {
            width: parent.width

            IngredientRow {
                Layout.fillWidth: true
                editing: true
                quantity: qsTr("1,2 kg")
                name: qsTr("Potatoes")
                note: qsTr("Firm-fleshed, such as Charlotte")
                usageText: qsTr("Steps 1 and 2")
            }
            IngredientRow {
                Layout.fillWidth: true
                editing: true
                quantity: qsTr("2 cloves")
                name: qsTr("Garlic cloves")
                linkedText: qsTr("On the list as Garlic")
                usageText: qsTr("Step 2")
            }
            IngredientRow {
                Layout.fillWidth: true
                editing: true
                name: qsTr("Nutmeg")
                optional: true
                usageText: qsTr("Not in a step yet")
                usedInSteps: false
                onMoreClicked: ShowcaseState.notify(qsTr("More"), null)
            }
        }
    }

    Specimen {
        title: qsTr("StepCard")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space3

            StepCard {
                Layout.fillWidth: true
                number: "1"
                segments: [
                    { text: qsTr("Peel the "), ingredient: false },
                    { text: qsTr("potatoes"), ingredient: true },
                    { text: qsTr(" and slice them 3 mm thick. Rub the dish with the "), ingredient: false },
                    { text: qsTr("garlic"), ingredient: true },
                    { text: qsTr(", then butter it."), ingredient: false }
                ]
                amounts: [
                    { quantity: qsTr("1,2 kg"), name: qsTr("Potatoes") },
                    { quantity: qsTr("1 clove"), name: qsTr("Garlic") },
                    { quantity: qsTr("30 g"), name: qsTr("Butter") }
                ]
            }
            StepCard {
                Layout.fillWidth: true
                number: "2"
                plain: true
                segments: [
                    { text: qsTr("Bake for 1 h 15 at 160 °C, until the top is golden and a knife slides through."),
                        ingredient: false }
                ]
            }
        }
    }

    Specimen {
        title: qsTr("StepCard: editing")
        note: qsTr("Tap a card to edit it; mentions are tokens that wrap with the text.")

        ColumnLayout {
            width: parent.width
            spacing: 0

            Repeater {
                model: [
                    {
                        segments: [
                            { text: qsTr("Bring the "), ingredient: false },
                            { text: qsTr("whole milk"), ingredient: true },
                            { text: qsTr(" and the "), ingredient: false },
                            { text: qsTr("cream"), ingredient: true },
                            { text: qsTr(" to a simmer with the "), ingredient: false },
                            { text: qsTr("nutmeg"), ingredient: true },
                            { text: qsTr("."), ingredient: false }
                        ],
                        amounts: [
                            { quantity: qsTr("50 cl"), name: qsTr("Whole milk") },
                            { quantity: qsTr("20 cl"), name: qsTr("Cream") }
                        ]
                    },
                    {
                        segments: [
                            { text: qsTr("Layer the "), ingredient: false },
                            { text: qsTr("potatoes"), ingredient: true },
                            { text: qsTr(" in the dish, pour the milk over and bake."), ingredient: false }
                        ],
                        amounts: [{ quantity: qsTr("1,2 kg"), name: qsTr("Potatoes") }]
                    }
                ]

                delegate: StepCard {
                    id: step

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    editing: true
                    selected: page.editedStep === step.index
                    number: `${step.index + 1}`
                    segments: step.modelData.segments
                    amounts: step.modelData.amounts
                    insertRow: true
                    onAmountClicked: index => ShowcaseState.notify(qsTr("Edit %1").arg(step.modelData.amounts[index].name), null)
                    onAddIngredientClicked: ShowcaseState.notify(qsTr("Add an ingredient"), null)
                    onInsertClicked: ShowcaseState.notify(qsTr("Insert a step after %1").arg(step.index + 1), null)

                    TapHandler {
                        onTapped: page.editedStep = step.index
                    }
                }
            }
        }
    }
}
