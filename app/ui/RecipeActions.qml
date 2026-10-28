import QtQuick
import Plating

// The round buttons over a recipe's photo: back on the left; favorite, edit
// and more actions on the right. At the top of the window, they clear the
// status bar (SafeArea). RecipeHeader shows them; a screen can float them
// instead, so they stay while its content scrolls.
Item {
    id: control

    property bool favorite: false

    // The more actions button, for a menu to open under it
    readonly property Item moreButton: more

    signal backClicked
    signal favoriteClicked
    signal editClicked
    signal moreClicked

    implicitHeight: back.y + back.implicitHeight

    IconButton {
        id: back

        x: CookbookMetrics.recipeHeaderButtonSide + control.SafeArea.margins.left
        y: CookbookMetrics.recipeHeaderButtonTop + control.SafeArea.margins.top
        size: IconButton.Large
        icon.name: "back"
        text: qsTr("Back")
        onClicked: control.backClicked()
    }

    Row {
        x: control.width - width - CookbookMetrics.recipeHeaderButtonSide - control.SafeArea.margins.right
        y: back.y
        spacing: CookbookMetrics.recipeHeaderButtonGap

        IconButton {
            size: IconButton.Large
            variant: IconButton.Tint
            icon.name: "heart"
            text: control.favorite ? qsTr("Remove from favorites") : qsTr("Add to favorites")
            checked: control.favorite
            Accessible.checkable: true
            Accessible.checked: control.favorite
            onClicked: control.favoriteClicked()
        }

        IconButton {
            size: IconButton.Large
            icon.name: "edit"
            text: qsTr("Edit")
            onClicked: control.editClicked()
        }

        IconButton {
            id: more

            size: IconButton.Large
            icon.name: "more"
            text: qsTr("More actions")
            onClicked: control.moreClicked()
        }
    }
}
