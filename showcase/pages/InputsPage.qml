pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

GroupPage {
    id: page

    property int servings: 4
    property int portions: 1
    property int eggs: 2

    scenes: [
        { name: "combobox", show: () => { page.reveal(aisleCombo); aisleCombo.popup.open() }, hide: () => aisleCombo.popup.close() }
    ]

    title: qsTr("Inputs")
    subtitle: qsTr("Text fields, ComboBox, CheckBox, Switch, SegmentedControl, Stepper, chips, ColorSwatch")

    Specimen {
        title: qsTr("TextField")
        note: qsTr("Tap a field: focused, its ring turns accent.")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space4

            TextField {
                Layout.fillWidth: true
                placeholderText: qsTr("Recipe name")
            }
            TextField {
                Layout.fillWidth: true
                label: qsTr("Name")
                text: qsTr("Gratin dauphinois")
                helperText: qsTr("Shown on the recipe card")
            }
            TextField {
                Layout.fillWidth: true
                label: qsTr("Servings")
                text: "0"
                numeric: true
                error: true
                helperText: qsTr("Enter at least 1")
            }
            TextField {
                Layout.fillWidth: true
                label: qsTr("Prep time")
                text: "25"
                suffix: qsTr("min")
                numeric: true
            }
            TextField {
                Layout.fillWidth: true
                leadingIcon: "basket"
                placeholderText: qsTr("Add an item")
                trailingAction: TextField.Submit
                onAccepted: {
                    if (text !== "")
                        ShowcaseState.notify(qsTr("Added %1").arg(text), null)
                    clear()
                }
            }
            TextField {
                Layout.fillWidth: true
                size: TextField.Compact
                label: qsTr("Note")
                placeholderText: qsTr("Optional")
            }
            TextField {
                Layout.fillWidth: true
                enabled: false
                label: qsTr("Disabled")
                text: qsTr("Can't change this")
            }
        }
    }

    Specimen {
        title: qsTr("Inset on a surface: TextField, SearchField, ComboBox")
        onSurface: true

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space4

            TextField {
                Layout.fillWidth: true
                inset: true
                label: qsTr("Aisle")
                placeholderText: qsTr("New aisle name")
            }
            SearchField {
                Layout.fillWidth: true
                inset: true
                placeholderText: qsTr("Search recipes")
                text: qsTr("dahl")
            }
            ComboBox {
                inset: true
                model: [qsTr("Produce"), qsTr("Dairy")]
            }
        }
    }

    Specimen {
        title: qsTr("TextArea: label and counter, empty")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space4

            TextArea {
                id: description

                Layout.fillWidth: true
                label: qsTr("Description")
                text: qsTr("Thin slices of potato baked slowly in cream and garlic until golden.")
                counterText: qsTr("%1 / %2").arg(description.length).arg(200)
            }
            TextArea {
                Layout.fillWidth: true
                placeholderText: qsTr("Anything to remember next time?")
            }
        }
    }

    Specimen {
        title: qsTr("TitleField: default and medium")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space5

            TitleField {
                Layout.fillWidth: true
                label: qsTr("Recipe name")
                text: qsTr("Gratin dauphinois")
            }
            TitleField {
                Layout.fillWidth: true
                size: TitleField.Medium
                label: qsTr("Section name")
                placeholderText: qsTr("For the sauce")
            }
        }
    }

    Specimen {
        title: qsTr("ComboBox (Select): default, medium, disabled")

        ComboBox {
            id: aisleCombo

            model: [qsTr("Produce"), qsTr("Dairy"), qsTr("Bakery"), qsTr("Spices")]
        }
        ComboBox {
            size: ComboBox.Medium
            model: [qsTr("Metric"), qsTr("US")]
        }
        ComboBox {
            enabled: false
            model: [qsTr("Weekly")]
        }
    }

    Specimen {
        title: qsTr("CheckBox and Switch")

        ColumnLayout {
            width: parent.width
            spacing: 0

            CheckBox {
                text: qsTr("Vegetarian")
                checked: true
            }
            CheckBox {
                text: qsTr("Freezes well")
            }
            CheckBox {
                enabled: false
                text: qsTr("Disabled")
            }
            Switch {
                text: qsTr("Keep the screen on while cooking")
                checked: true
            }
            Switch {
                text: qsTr("Suggest recipes in season")
            }
            Switch {
                enabled: false
                text: qsTr("Disabled")
            }
        }
    }

    Specimen {
        title: qsTr("SegmentedControl: plain labels, icons, second lines")
        onSurface: true

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space4

            SegmentedControl {
                Layout.fillWidth: true

                SegmentedButton {
                    text: qsTr("Metric")
                }
                SegmentedButton {
                    text: qsTr("US")
                }
            }
            SegmentedControl {
                Layout.fillWidth: true
                currentIndex: 1

                SegmentedButton {
                    icon.name: "book"
                    text: qsTr("Recipes")
                }
                SegmentedButton {
                    icon.name: "calendar"
                    text: qsTr("Plan")
                }
                SegmentedButton {
                    icon.name: "basket"
                    text: qsTr("List")
                }
            }
            SegmentedControl {
                Layout.fillWidth: true

                SegmentedButton {
                    text: qsTr("This week")
                    detail: qsTr("3 recipes")
                }
                SegmentedButton {
                    text: qsTr("Next week")
                    detail: qsTr("1 recipe")
                }
            }
        }
    }

    Specimen {
        title: qsTr("SegmentedControl: plain")
        onSurface: true

        SegmentedControl {
            width: parent.width
            plain: true

            SegmentedButton {
                text: qsTr("All")
            }
            SegmentedButton {
                text: qsTr("Favorites")
            }
            SegmentedButton {
                text: qsTr("Quick")
            }
        }
    }

    Specimen {
        title: qsTr("Stepper: default, small, large")
        note: qsTr("They count. At the minimum, − turns off; the last one removes at 1.")
        onSurface: true

        Stepper {
            text: `${page.servings}`
            unit: page.servings === 1 ? qsTr("serving") : qsTr("servings")
            canDecrease: page.servings > 1
            canIncrease: page.servings < 12
            onDecreaseClicked: page.servings--
            onIncreaseClicked: page.servings++
        }
        Stepper {
            size: Stepper.Small
            text: page.servings === 1 ? qsTr("1 serving") : qsTr("%1 servings").arg(page.servings)
            canDecrease: page.servings > 1
            canIncrease: page.servings < 12
            onDecreaseClicked: page.servings--
            onIncreaseClicked: page.servings++
        }
        Stepper {
            size: Stepper.Large
            text: `${page.servings}`
            unit: page.servings === 1 ? qsTr("serving") : qsTr("servings")
            canDecrease: page.servings > 1
            canIncrease: page.servings < 12
            onDecreaseClicked: page.servings--
            onIncreaseClicked: page.servings++
        }
        Stepper {
            text: `${page.portions}`
            unit: qsTr("portion")
            canDecrease: false
            onIncreaseClicked: page.portions++
        }
        Stepper {
            size: Stepper.Small
            text: page.eggs > 0 ? qsTr("%1 eggs").arg(page.eggs) : qsTr("Removed")
            enabled: page.eggs > 0
            removable: true
            canDecrease: page.eggs > 1
            onDecreaseClicked: page.eggs--
            onIncreaseClicked: page.eggs++
            onRemoveClicked: {
                page.eggs = 0
                ShowcaseState.notify(qsTr("Eggs removed"), () => page.eggs = 1)
            }
        }
    }

    Specimen {
        title: qsTr("FilterChip: toggles, count, round")

        FilterChip {
            icon.name: "heart"
            text: qsTr("Favorites")
        }
        FilterChip {
            icon.name: "clock"
            text: qsTr("Quick")
            checked: true
        }
        FilterChip {
            text: qsTr("Vegetarian")
            count: "12"
            checked: true
        }
        FilterChip {
            text: qsTr("Pressed")
            down: true
        }
        FilterChip {
            round: true
            icon.name: "heart"
            text: qsTr("Favorites only")
        }
        FilterChip {
            round: true
            icon.name: "heart"
            text: qsTr("Favorites only")
            checked: true
        }
    }

    Specimen {
        title: qsTr("ChoiceChip: one of a row, several with dots, small")

        ScrollArea {
            width: parent.width
            height: mealRow.implicitHeight
            orientation: Qt.Horizontal
            contentWidth: mealRow.implicitWidth
            clip: true

            Row {
                id: mealRow

                spacing: UiMetrics.space2

                Repeater {
                    model: [qsTr("Breakfast"), qsTr("Lunch"), qsTr("Dinner"), qsTr("Snack"), qsTr("Dessert")]

                    delegate: ChoiceChip {
                        required property int index
                        required property string modelData

                        text: modelData
                        autoExclusive: true
                        checked: index === 2
                    }
                }
            }
        }

        ChoiceChip {
            text: qsTr("Produce")
            dotColor: page.mint.ink
            checked: true
        }
        ChoiceChip {
            text: qsTr("Dairy")
            dotColor: page.sky.ink
        }
        ChoiceChip {
            text: qsTr("Bakery")
            dotColor: page.butter.ink
            checked: true
        }
        ChoiceChip {
            size: ChoiceChip.Small
            text: qsTr("Small")
        }
        ChoiceChip {
            size: ChoiceChip.Small
            text: qsTr("Disabled")
            enabled: false
        }
    }

    Specimen {
        title: qsTr("ChoiceChip: a grid on a surface, ending with an add chip")
        onSurface: true

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: UiMetrics.space2
            rowSpacing: UiMetrics.space2

            Repeater {
                model: [
                    { name: qsTr("Produce"), dot: page.mint.ink },
                    { name: qsTr("Dairy"), dot: page.sky.ink },
                    { name: qsTr("Bakery"), dot: page.butter.ink },
                    { name: qsTr("Spices"), dot: page.peach.ink }
                ]

                delegate: ChoiceChip {
                    required property int index
                    required property string name
                    required property color dot

                    Layout.fillWidth: true
                    size: ChoiceChip.Grid
                    inset: true
                    autoExclusive: true
                    checked: index === 0
                    text: name
                    dotColor: dot
                }
            }

            ChoiceChip {
                Layout.fillWidth: true
                size: ChoiceChip.Grid
                add: true
                text: qsTr("New aisle")
                onClicked: ShowcaseState.notify(qsTr("This would open the new aisle sheet"), null)
            }
        }
    }

    Specimen {
        title: qsTr("TagChip: off and on, inset on a surface")
        onSurface: true

        TagChip {
            text: qsTr("Vegetarian")
            family: page.mint
            inset: true
            checked: true
        }
        TagChip {
            text: qsTr("Side")
            family: page.butter
            inset: true
        }
        TagChip {
            text: qsTr("Weeknight")
            family: page.sky
            inset: true
            checked: true
        }
        TagChip {
            text: qsTr("Oven")
            family: page.peach
            inset: true
        }
    }

    Specimen {
        title: qsTr("InputChip: family, accent, plain")
        note: qsTr("× removes it; Undo brings it back.")

        Repeater {
            model: ListModel {
                id: picked

                ListElement {
                    name: "Vegetarian"
                    kind: 0
                }
                ListElement {
                    name: "Dahl de lentilles corail"
                    kind: 1
                }
                ListElement {
                    name: "Garlic"
                    kind: 2
                }
            }

            delegate: InputChip {
                required property int index
                required property string name
                required property int kind

                text: name
                variant: kind === 0 ? InputChip.Family : kind === 1 ? InputChip.Accent : InputChip.Plain
                family: page.mint
                iconName: kind === 1 ? "book" : ""
                onRemoveClicked: {
                    const removed = { name: name, kind: kind }
                    const at = index
                    picked.remove(at)
                    ShowcaseState.notify(qsTr("%1 removed").arg(removed.name), () => picked.insert(at, removed))
                }
            }
        }
    }

    Specimen {
        title: qsTr("ColorSwatch: accents")
        note: qsTr("The toolbar's swatches switch the accent.")

        ColorSwatch {
            text: qsTr("Raspberry")
            family: ({ fill: page.theme.accentRaspberry, ink: page.theme.accentRaspberryInk })
            checked: true
        }
        ColorSwatch {
            text: qsTr("Spirulina")
            family: ({ fill: page.theme.accentSpirulina, ink: page.theme.accentSpirulinaInk })
        }
        ColorSwatch {
            text: qsTr("Blueberry")
            family: ({ fill: page.theme.accentBlueberry, ink: page.theme.accentBlueberryInk })
        }
        ColorSwatch {
            text: qsTr("Saffron")
            family: ({ fill: page.theme.accentSaffron, ink: page.theme.accentSaffronInk })
        }
        ColorSwatch {
            text: qsTr("Basil")
            family: ({ fill: page.theme.accentBasil, ink: page.theme.accentBasilInk })
        }
    }

    Specimen {
        title: qsTr("ColorSwatch: color families, pressed, disabled")

        ColorSwatch {
            text: qsTr("Mint")
            family: page.mint
        }
        ColorSwatch {
            text: qsTr("Butter")
            family: page.butter
            checked: true
        }
        ColorSwatch {
            text: qsTr("Sky")
            family: page.sky
            down: true
        }
        ColorSwatch {
            text: qsTr("Peach")
            family: page.peach
            enabled: false
        }
    }
}
