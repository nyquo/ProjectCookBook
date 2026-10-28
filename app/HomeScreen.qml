pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// The first screen: the three tabs over the bottom bar. Each tab keeps its
// state while another one is shown; the tab shown fades in while rising.
AppScreen {
    id: screen

    signal settingsClicked
    signal recipeClicked(string recipeId)

    // Undoes a recipe's deletion, e.g. from the snackbar that reported it
    function restoreRecipe(recipeId: string) {
        const text = ErrorTexts.recipeList(recipes.restore(recipeId))
        if (text !== "")
            screen.notify(text, "", null)
    }

    // A tab of the StackLayout
    component Tab: TabPage {
        id: tab

        property real rise: 0

        function enter() {
            appear.restart()
        }

        transform: Translate {
            y: tab.rise
        }

        onSettingsClicked: screen.settingsClicked()

        ParallelAnimation {
            id: appear

            NumberAnimation {
                target: tab
                property: "opacity"
                from: 0
                to: 1
                duration: UiMotion.fade(UiMotion.pageEnter)
            }
            NumberAnimation {
                target: tab
                property: "rise"
                from: UiMotion.reduced ? 0 : UiMetrics.pageEnterOffset
                to: 0
                duration: UiMotion.move(UiMotion.pageEnter)
                easing.type: Easing.Bezier
                easing.bezierCurve: UiMotion.decelerate
            }
        }
    }

    snackbarOffset: nav.height

    RecipeListModel {
        id: recipes
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StackLayout {
            id: tabs

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: nav.currentIndex

            onCurrentIndexChanged: (tabs.children[tabs.currentIndex] as Tab)?.enter()

            Tab {
                title: qsTr("Recipes")

                // TODO(recipes list): a plain list of titles until the real
                // recipes list
                ScrollArea {
                    anchors.fill: parent

                    view: ListView {
                        clip: true
                        model: recipes
                        leftMargin: UiMetrics.space4 + screen.SafeArea.margins.left
                        rightMargin: UiMetrics.space4 + screen.SafeArea.margins.right

                        delegate: ListRow {
                            id: row

                            required property string recipeId
                            required property string title

                            width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                            text: row.title
                            onClicked: screen.recipeClicked(row.recipeId)
                        }
                    }
                }
            }
            Tab {
                title: qsTr("Planning")
            }
            Tab {
                title: qsTr("Shopping list")
            }
        }

        BottomNav {
            id: nav

            Layout.fillWidth: true

            BottomNavItem {
                text: qsTr("Recipes")
                icon.source: CookbookIcons.source("recipes")
            }
            BottomNavItem {
                text: qsTr("Planning")
                icon.source: CookbookIcons.source("planning")
            }
            BottomNavItem {
                text: qsTr("Shopping list")
                icon.source: CookbookIcons.source("shopping")
            }
        }
    }
}
