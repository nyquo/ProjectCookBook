pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating
import CookbookUi

// A recipe, pushed over the tabs: its photo and header, its key facts, the
// ingredients for the servings shown, the steps, the notes and the source,
// under buttons that float at the top and the bottom. Parts the user hides in
// Settings, or that are empty, don't show. Keeps the display awake while
// shown, if the Keep screen on setting allows it.
AppScreen {
    id: screen

    required property string recipeId

    // The recipe was deleted: the caller closes the screen and offers Undo
    signal removed(string recipeId, string title)

    // The key facts, as SpecStrip shows them: [{ label, value, detail }]
    readonly property var specs: {
        const cells = []
        if (RecipeFieldSettings.times && recipe.prepTime !== "")
            cells.push({ label: qsTr("Prep"), value: recipe.prepTime, detail: "" })
        if (RecipeFieldSettings.times && recipe.cookTime !== "")
            cells.push({ label: qsTr("Cook"), value: recipe.cookTime, detail: "" })
        if (RecipeFieldSettings.cost && recipe.costPerServing !== "")
            cells.push({ label: qsTr("Per serving"), value: recipe.costPerServing, detail: "" })
        if (RecipeFieldSettings.cookingHistory)
            cells.push({ label: qsTr("Cooked"), value: recipe.cookedCount, detail: recipe.lastCooked })
        return cells
    }
    // The first tag's family; without tags, surface and a muted letter
    readonly property colorFamily family: recipe.tags.length > 0
                                          ? TagFamilies.family(screen.theme, recipe.tags[0].colorKey)
                                          : ({ fill: screen.theme.surface, ink: screen.theme.inkMuted })

    // Tells the user why a change failed, if there's something to say
    function report(error: int) {
        const text = ErrorTexts.recipe(error)
        if (text !== "")
            screen.notify(text, "", null)
    }

    function markCooked() {
        const error = recipe.markCooked()
        if (error !== RecipeModel.Error.NoError) {
            screen.report(error)
            return
        }
        screen.notify(qsTr("%1 marked as cooked").arg(recipe.title), qsTr("Undo"),
                      () => screen.report(recipe.undoCooked()))
    }

    function remove() {
        const error = recipe.remove()
        if (error !== RecipeModel.Error.NoError) {
            screen.report(error)
            return
        }
        screen.removed(screen.recipeId, recipe.title)
    }

    keepScreenOn: true
    snackbarOffset: screen.SafeArea.margins.bottom + CookbookMetrics.recipeActionsMargin + bottomActions.height

    RecipeModel {
        id: recipe

        recipeId: screen.recipeId
    }

    // A drag that starts at the top and goes down pulls the recipe down to
    // close it
    ScrollArea {
        id: scroller

        anchors.fill: parent
        contentHeight: header.implicitHeight
        pullDownEnabled: true
        onPulledDown: distance => screen.dragPull(distance)
        onPullDownReleased: screen.releasePull()

        RecipeHeader {
            id: header

            width: scroller.width
            height: implicitHeight
            showActions: false
            photo: recipe.photo
            initial: recipe.initial
            family: screen.family
            tags: recipe.tags.map(tag => ({ name: tag.name, family: TagFamilies.family(screen.theme, tag.colorKey) }))
            title: recipe.title
            description: recipe.description
            sheetBottomPadding: screen.snackbarOffset + CookbookMetrics.recipeActionsClearance

            SpecStrip {
                visible: screen.specs.length > 0
                Layout.fillWidth: true
                model: screen.specs
            }

            IngredientsCard {
                visible: ingredientRows.count > 0
                Layout.fillWidth: true
                trailing: Stepper {
                    text: recipe.servings.toLocaleString(Qt.locale(), "f", 0)
                    unit: qsTr("serving(s)", "", recipe.servings)
                    canDecrease: recipe.servings > 1
                    canIncrease: recipe.servings < recipe.maxServings
                    onDecreaseClicked: recipe.servings -= 1
                    onIncreaseClicked: recipe.servings += 1
                }

                Repeater {
                    id: ingredientRows

                    model: recipe.ingredients

                    delegate: IngredientRow {
                        required quantity
                        required name
                        required optional
                        required note
                        required alternatives

                        Layout.fillWidth: true
                    }
                }
            }

            ColumnLayout {
                visible: stepCards.count > 0
                Layout.fillWidth: true
                spacing: CookbookMetrics.recipeStepGap

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: CookbookMetrics.recipeTitleGap - CookbookMetrics.recipeStepGap
                    text: qsTr("Steps")
                    font: UiTypography.titleL
                    color: screen.theme.ink
                    wrapMode: Text.Wrap
                    Accessible.role: Accessible.Heading
                }

                Repeater {
                    id: stepCards

                    model: recipe.steps

                    delegate: StepCard {
                        required number
                        required segments
                        required amounts

                        Layout.fillWidth: true
                        plain: !RecipeFieldSettings.stepAmounts
                    }
                }
            }

            NoteCard {
                visible: RecipeFieldSettings.notes && recipe.notes !== ""
                Layout.fillWidth: true
                title: qsTr("Notes")
                text: recipe.notes
            }

            // A link source opens in the browser
            T.AbstractButton {
                id: sourceLink

                visible: RecipeFieldSettings.source && recipe.sourceHost !== ""
                Layout.fillWidth: true
                implicitHeight: implicitContentHeight
                padding: 0
                text: qsTr("From %1").arg(recipe.sourceHost)
                containmentMask: TouchTarget {
                    target: sourceLink
                }
                Accessible.role: Accessible.Link
                Accessible.name: sourceLink.text
                onClicked: Qt.openUrlExternally(recipe.sourceUrl)

                contentItem: Text {
                    text: sourceLink.text
                    font: UiTypography.bodyS
                    color: screen.theme.accent
                    wrapMode: Text.Wrap
                }

                background: Item {
                    FocusRing {
                        visible: sourceLink.visualFocus
                        targetRadius: UiMetrics.radiusSm
                    }
                }
            }

            Text {
                visible: RecipeFieldSettings.source && recipe.source !== "" && recipe.sourceHost === ""
                Layout.fillWidth: true
                text: qsTr("From %1").arg(recipe.source)
                font: UiTypography.bodyS
                color: screen.theme.inkMuted
                wrapMode: Text.Wrap
            }
        }
    }

    // Over the photo, they stay while the recipe scrolls
    RecipeActions {
        id: actions

        width: parent.width
        favorite: recipe.favorite
        onBackClicked: screen.StackView.view.pop()
        onFavoriteClicked: screen.report(recipe.setFavorite(!recipe.favorite))
        // TODO(recipe editor): open the recipe in the editor, once there's one
        onMoreClicked: moreMenu.openUnder(actions.moreButton)
    }

    Menu {
        id: moreMenu

        MenuItem {
            icon.name: "trash"
            destructive: true
            text: qsTr("Delete recipe")
            onTriggered: screen.remove()
        }
    }

    RowLayout {
        id: bottomActions

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: CookbookMetrics.recipeActionsMargin + screen.SafeArea.margins.left
        anchors.rightMargin: CookbookMetrics.recipeActionsMargin + screen.SafeArea.margins.right
        anchors.bottomMargin: CookbookMetrics.recipeActionsMargin + screen.SafeArea.margins.bottom
        spacing: CookbookMetrics.recipeActionsGap

        Button {
            variant: Button.Secondary
            size: Button.Large
            icon.name: "check"
            text: qsTr("Cooked it")
            onClicked: screen.markCooked()
        }

        // TODO(planning): add the recipe to the plan, once there's one
        Button {
            Layout.fillWidth: true
            variant: Button.Primary
            size: Button.Large
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
    }
}
