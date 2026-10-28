pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

GroupPage {
    id: page

    readonly property url photo: Qt.resolvedUrl("../images/gratin.svg")
    readonly property var sortOptions: [
        { label: qsTr("Least recently cooked"), reversedLabel: qsTr("Most recently cooked") },
        { label: qsTr("Name A–Z"), reversedLabel: qsTr("Name Z–A") },
        { label: qsTr("Quickest first"), reversedLabel: qsTr("Longest first") }
    ]

    property bool favorite: true

    scenes: [
        { name: "sort-menu", show: () => { page.reveal(sortButton); sortMenu.openUnder(sortButton) }, hide: () => sortMenu.close() },
        { name: "quick-menu", show: () => { page.reveal(row2); quickMenu.openUnder(row2) }, hide: () => quickMenu.close() }
    ]
    property int sortIndex: 0
    property bool sortReversed: false
    property int planned: 4
    property bool plannedShown: true
    property string note: qsTr("Slice the potatoes thin, no need to rinse them: their starch thickens the cream.")

    title: qsTr("Recipes")
    subtitle: qsTr("RecipeHeader, RecipeActions, RecipeRow, PlannedRecipeCard, SortMenu, NoteCard")

    Specimen {
        title: qsTr("RecipeHeader: with a photo")
        note: qsTr("The heart toggles.")
        fullBleed: true

        RecipeHeader {
            width: parent.width
            photo: page.photo
            initial: "G"
            family: page.butter
            tags: [
                { name: qsTr("Vegetarian"), family: page.mint },
                { name: qsTr("Oven"), family: page.peach },
                { name: qsTr("Sunday"), family: page.butter }
            ]
            title: qsTr("Gratin dauphinois")
            description: qsTr("Thin slices of potato baked slowly in cream and garlic until golden.")
            favorite: page.favorite
            onFavoriteClicked: page.favorite = !page.favorite
            onBackClicked: ShowcaseState.notify(qsTr("Back"), null)
            onEditClicked: ShowcaseState.notify(qsTr("Edit"), null)
            onMoreClicked: ShowcaseState.notify(qsTr("More"), null)
        }
    }

    Specimen {
        title: qsTr("RecipeHeader: without a photo")
        fullBleed: true

        RecipeHeader {
            width: parent.width
            initial: "D"
            family: page.peach
            tags: [
                { name: qsTr("Weeknight"), family: page.sky },
                { name: qsTr("Vegetarian"), family: page.mint }
            ]
            title: qsTr("Dahl de lentilles corail")
        }
    }

    Specimen {
        title: qsTr("RecipeActions")
        note: qsTr("RecipeHeader's buttons, which the recipe screen floats over its content.")
        fullBleed: true

        Rectangle {
            width: parent.width
            implicitHeight: actions.implicitHeight + UiMetrics.space5
            color: page.butter.fill

            RecipeActions {
                id: actions

                width: parent.width
                favorite: page.favorite
                onFavoriteClicked: page.favorite = !page.favorite
                onBackClicked: ShowcaseState.notify(qsTr("Back"), null)
                onEditClicked: ShowcaseState.notify(qsTr("Edit"), null)
                onMoreClicked: ShowcaseState.notify(qsTr("More actions"), null)
            }
        }
    }

    Specimen {
        title: qsTr("RecipeRow")
        note: qsTr("Press and hold a row for its quick actions.")
        fullBleed: true

        Column {
            width: parent.width

            RecipeRow {
                id: row1

                width: parent.width
                text: qsTr("Gratin dauphinois")
                thumbnail: page.photo
                initials: "GD"
                family: page.butter
                favorite: true
                tags: [
                    { name: qsTr("Vegetarian"), family: page.mint },
                    { name: qsTr("Oven"), family: page.peach },
                    { name: qsTr("Sunday"), family: page.butter }
                ]
                time: qsTr("1 h 15")
                lastCooked: qsTr("3 weeks ago")
                onPressAndHold: quickMenu.openUnder(row1)
            }
            RecipeRow {
                id: row2

                width: parent.width
                text: qsTr("Dahl de lentilles corail et lait de coco")
                initials: "DL"
                family: page.peach
                tags: [{ name: qsTr("Weeknight"), family: page.sky }]
                time: qsTr("35 min")
                lastCooked: qsTr("Yesterday")
                onPressAndHold: quickMenu.openUnder(row2)
            }
            RecipeRow {
                id: row3

                width: parent.width
                text: qsTr("Tarte aux poireaux")
                initials: "TP"
                family: page.mint
                time: qsTr("50 min")
                lastCooked: qsTr("Never")
                onPressAndHold: quickMenu.openUnder(row3)
            }
            RecipeRow {
                id: row4

                width: parent.width
                down: true
                text: qsTr("Pressed")
                initials: "P"
                family: page.sky
                time: qsTr("20 min")
            }
        }
    }

    Specimen {
        title: qsTr("SortMenu")
        note: qsTr("Tap another option, or the checked one again: the menu stays open.")

        Button {
            id: sortButton

            variant: Button.Quiet
            size: Button.Small
            icon.name: "sort"
            text: page.sortReversed ? page.sortOptions[page.sortIndex].reversedLabel
                                    : page.sortOptions[page.sortIndex].label
            onClicked: sortMenu.openUnder(sortButton)
        }
    }

    Specimen {
        title: qsTr("PlannedRecipeCard")
        note: qsTr("The stepper counts; × removes it, Undo brings it back.")

        PlannedRecipeCard {
            width: parent.width
            visible: page.plannedShown
            title: qsTr("Dahl de lentilles corail")
            meta: qsTr("Tuesday · 35 min")
            initials: "DL"
            family: page.peach
            servings: page.planned === 1 ? qsTr("1 serving") : qsTr("%1 servings").arg(page.planned)
            canDecrease: page.planned > 1
            onDecreaseClicked: page.planned--
            onIncreaseClicked: page.planned++
            onCookedClicked: ShowcaseState.notify(qsTr("Marked as cooked"), null)
            onRemoveClicked: {
                page.plannedShown = false
                ShowcaseState.notify(qsTr("Removed from the plan"), () => page.plannedShown = true)
            }
        }
    }

    Specimen {
        title: qsTr("NoteCard: default, small, editable")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space3

            NoteCard {
                Layout.fillWidth: true
                title: qsTr("Tip")
                text: qsTr("Rub the dish with a cut clove of garlic before the potatoes go in.")
            }
            NoteCard {
                Layout.fillWidth: true
                size: NoteCard.Small
                title: qsTr("Makes ahead")
                text: qsTr("Keeps two days in the fridge; reheat covered.")
            }
            NoteCard {
                Layout.fillWidth: true
                editable: true
                title: qsTr("My notes")
                text: page.note
                placeholderText: qsTr("Anything to remember next time?")
                onTextEdited: text => page.note = text
            }
        }
    }

    Menu {
        id: quickMenu

        title: qsTr("Quick actions")

        MenuItem {
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
        MenuItem {
            icon.name: "heart"
            text: qsTr("Add to favorites")
        }
        MenuItem {
            icon.name: "edit"
            text: qsTr("Edit")
        }
        MenuSeparator {}
        MenuItem {
            icon.name: "trash"
            destructive: true
            text: qsTr("Delete recipe")
        }
    }

    SortMenu {
        id: sortMenu

        options: page.sortOptions
        selectedIndex: page.sortIndex
        reversed: page.sortReversed
        onChosen: (index, reversed) => {
            page.sortIndex = index
            page.sortReversed = reversed
        }
    }
}
