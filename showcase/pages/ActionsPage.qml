import QtQuick
import Plating

GroupPage {
    id: page

    title: qsTr("Actions")
    subtitle: qsTr("Button, IconButton, floating action button")

    Specimen {
        title: qsTr("Button variants")

        Button {
            text: qsTr("Add to plan")
        }
        Button {
            variant: Button.Secondary
            text: qsTr("Done")
        }
        Button {
            variant: Button.Quiet
            text: qsTr("Edit")
        }
        Button {
            variant: Button.Tonal
            text: qsTr("Cook now")
        }
        Button {
            variant: Button.Text
            text: qsTr("See all")
        }
    }

    Specimen {
        title: qsTr("Modifiers: add, dashed, destructive, danger")

        Button {
            variant: Button.Quiet
            add: true
            text: qsTr("Ingredient")
        }
        Button {
            variant: Button.Text
            add: true
            text: qsTr("Add a step")
        }
        Button {
            variant: Button.Dashed
            icon.name: "plus"
            text: qsTr("New aisle")
        }
        Button {
            variant: Button.Quiet
            destructive: true
            icon.name: "trash"
            text: qsTr("Remove")
        }
        Button {
            variant: Button.Text
            destructive: true
            text: qsTr("Clear list")
        }
        Button {
            variant: Button.Danger
            text: qsTr("Delete recipe")
        }
    }

    Specimen {
        title: qsTr("Sizes: large, medium, small, extra small")

        Button {
            size: Button.Large
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
        Button {
            size: Button.Medium
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
        Button {
            size: Button.Small
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
        Button {
            size: Button.ExtraSmall
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
        Button {
            variant: Button.Secondary
            size: Button.Large
            text: qsTr("Done")
        }
        Button {
            variant: Button.Secondary
            size: Button.Small
            icon.name: "check"
            text: qsTr("Cooked it")
        }
        Button {
            variant: Button.Quiet
            size: Button.ExtraSmall
            add: true
            text: qsTr("Ingredient")
        }
    }

    Specimen {
        title: qsTr("Full width")

        Button {
            width: parent.width
            size: Button.Large
            text: qsTr("Save recipe")
        }
        Button {
            width: parent.width
            variant: Button.Secondary
            size: Button.Large
            text: qsTr("Done")
        }
    }

    Specimen {
        title: qsTr("Inset: quiet on a surface")
        onSurface: true

        Button {
            variant: Button.Quiet
            inset: true
            text: qsTr("Edit")
        }
        Button {
            variant: Button.Quiet
            inset: true
            size: Button.ExtraSmall
            add: true
            text: qsTr("Ingredient")
        }
    }

    Specimen {
        title: qsTr("States: pressed, disabled, focused")
        note: qsTr("Tab moves the keyboard focus; its ring shows on the focused control only.")

        Button {
            down: true
            text: qsTr("Pressed")
        }
        Button {
            variant: Button.Quiet
            down: true
            text: qsTr("Pressed")
        }
        Button {
            enabled: false
            text: qsTr("Disabled")
        }
        Button {
            variant: Button.Secondary
            enabled: false
            text: qsTr("Disabled")
        }
        Button {
            id: focused

            variant: Button.Tonal
            text: qsTr("Focused")
            Component.onCompleted: focused.forceActiveFocus(Qt.TabFocusReason)
        }
    }

    Specimen {
        title: qsTr("IconButton fills")

        IconButton {
            icon.name: "more"
            text: qsTr("More")
        }
        IconButton {
            variant: IconButton.Ghost
            icon.name: "close"
            text: qsTr("Remove")
        }
        IconButton {
            variant: IconButton.Tint
            icon.name: "edit"
            text: qsTr("Edit")
        }
        IconButton {
            variant: IconButton.Accent
            icon.name: "plus"
            text: qsTr("Add")
        }
        IconButton {
            variant: IconButton.Tonal
            icon.name: "calendar"
            text: qsTr("Plan")
        }
        IconButton {
            variant: IconButton.Destructive
            icon.name: "trash"
            text: qsTr("Delete")
        }
    }

    Specimen {
        title: qsTr("IconButton sizes: small, default, large")

        IconButton {
            size: IconButton.Small
            icon.name: "more"
            text: qsTr("More")
        }
        IconButton {
            icon.name: "more"
            text: qsTr("More")
        }
        IconButton {
            size: IconButton.Large
            icon.name: "settings"
            text: qsTr("Settings")
        }
    }

    Specimen {
        title: qsTr("IconButton states: favorite, pressed, disabled")
        note: qsTr("The heart toggles.")

        IconButton {
            variant: IconButton.Tint
            size: IconButton.Large
            checkable: true
            checked: true
            icon.name: "heart"
            text: qsTr("Favorite")
        }
        IconButton {
            variant: IconButton.Tint
            size: IconButton.Large
            checkable: true
            icon.name: "heart"
            text: qsTr("Favorite")
        }
        IconButton {
            down: true
            icon.name: "edit"
            text: qsTr("Edit")
        }
        IconButton {
            variant: IconButton.Accent
            down: true
            icon.name: "plus"
            text: qsTr("Add")
        }
        IconButton {
            enabled: false
            icon.name: "edit"
            text: qsTr("Edit")
        }
    }

    Specimen {
        title: qsTr("Floating action button")

        FloatingActionButton {
            text: qsTr("New recipe")
        }
        FloatingActionButton {
            extended: true
            text: qsTr("New recipe")
        }
        FloatingActionButton {
            down: true
            text: qsTr("New recipe")
        }
        FloatingActionButton {
            enabled: false
            text: qsTr("New recipe")
        }
    }
}
