pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

GroupPage {
    id: page

    property int planServings: 4

    scenes: [
        { name: "sheet", show: () => planSheet.open(), hide: () => planSheet.close() },
        { name: "tall-sheet", show: () => listSheet.open(), hide: () => listSheet.close() },
        { name: "locked-sheet", show: () => leaveSheet.open(), hide: () => leaveSheet.close() },
        { name: "menu", show: () => { page.reveal(moreButton); recipeMenu.openUnder(moreButton) }, hide: () => recipeMenu.close() },
        { name: "checked-menu", show: () => { page.reveal(menuButton); viewMenu.openUnder(menuButton) }, hide: () => viewMenu.close() },
        { name: "snackbar", show: () => ShowcaseState.notify(qsTr("Leeks removed"), () => {}), hide: () => ShowcaseState.snackbar.close() }
    ]

    title: qsTr("Navigation and overlays")
    subtitle: qsTr("BottomNav, BottomSheet, Menu, Snackbar, EmptyState")

    Specimen {
        title: qsTr("BottomNav")
        note: qsTr("Switching tabs: the new page fades in while rising.")

        Rectangle {
            width: parent.width
            height: tabs.implicitHeight + UiMetrics.badgeTileL * 3
            radius: UiMetrics.radiusLg
            color: page.theme.bg
            border.width: UiMetrics.hairline
            border.color: page.theme.line
            clip: true

            Item {
                id: tabPage

                width: parent.width
                height: parent.height - tabs.height

                IconBadge {
                    id: tabIcon

                    anchors.centerIn: parent
                    shape: IconBadge.Tile
                    size: IconBadge.Large
                    family: page.butter
                    iconName: ["book", "calendar", "basket", "settings"][tabs.currentIndex]
                }

                Text {
                    anchors.top: tabIcon.bottom
                    anchors.topMargin: UiMetrics.space2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: [qsTr("Recipes"), qsTr("Plan"), qsTr("List"), qsTr("Settings")][tabs.currentIndex]
                    font: UiTypography.titleL
                    color: page.theme.ink
                }
            }

            BottomNav {
                id: tabs

                anchors.bottom: parent.bottom
                width: parent.width

                onCurrentIndexChanged: pageEnter.restart()

                BottomNavItem {
                    icon.name: "book"
                    text: qsTr("Recipes")
                }
                BottomNavItem {
                    icon.name: "calendar"
                    text: qsTr("Plan")
                }
                BottomNavItem {
                    icon.name: "basket"
                    text: qsTr("List")
                }
                BottomNavItem {
                    icon.name: "settings"
                    text: qsTr("Settings")
                }
            }

            ParallelAnimation {
                id: pageEnter

                NumberAnimation {
                    target: tabPage
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: UiMotion.fade(UiMotion.pageEnter)
                }
                NumberAnimation {
                    target: tabPage
                    property: "y"
                    from: UiMotion.reduced ? 0 : UiMetrics.pageEnterOffset
                    to: 0
                    duration: UiMotion.move(UiMotion.pageEnter)
                    easing.type: Easing.Bezier
                    easing.bezierCurve: UiMotion.decelerate
                }
            }
        }
    }

    Specimen {
        title: qsTr("BottomSheet")
        note: qsTr("Tap the scrim or swipe down to dismiss, except the last one.")

        Button {
            variant: Button.Secondary
            size: Button.Small
            text: qsTr("Fits its content")
            onClicked: planSheet.open()
        }
        Button {
            variant: Button.Secondary
            size: Button.Small
            text: qsTr("Tall")
            onClicked: listSheet.open()
        }
        Button {
            variant: Button.Secondary
            size: Button.Small
            text: qsTr("Not dismissible")
            onClicked: leaveSheet.open()
        }
    }

    Specimen {
        title: qsTr("Menu")

        IconButton {
            id: moreButton

            icon.name: "more"
            text: qsTr("More")
            onClicked: recipeMenu.openUnder(moreButton)
        }
        Button {
            id: menuButton

            variant: Button.Quiet
            size: Button.Small
            icon.name: "filter"
            text: qsTr("View")
            onClicked: viewMenu.openUnder(menuButton)
        }
    }

    Specimen {
        title: qsTr("Snackbar")
        note: qsTr("A new one replaces the current one. Undo works.")

        Button {
            variant: Button.Secondary
            size: Button.Small
            text: qsTr("Message")
            onClicked: ShowcaseState.notify(qsTr("Recipe saved"), null)
        }
        Button {
            variant: Button.Quiet
            size: Button.Small
            destructive: true
            icon.name: "trash"
            enabled: removable.count > 0
            text: qsTr("Remove one")
            onClicked: {
                const removed = removable.get(0).name
                removable.remove(0)
                ShowcaseState.notify(qsTr("%1 removed").arg(removed),
                                     () => removable.insert(0, { name: removed }))
            }
        }

        Repeater {
            model: ListModel {
                id: removable

                ListElement {
                    name: "Leeks"
                }
                ListElement {
                    name: "Gruyère"
                }
                ListElement {
                    name: "Nutmeg"
                }
            }

            delegate: InputChip {
                required property string name

                text: name
                onRemoveClicked: {
                    for (let i = 0; i < removable.count; ++i) {
                        if (removable.get(i).name === name) {
                            removable.remove(i)
                            const removed = name
                            ShowcaseState.notify(qsTr("%1 removed").arg(removed),
                                                 () => removable.insert(Math.min(i, removable.count), { name: removed }))
                            return
                        }
                    }
                }
            }
        }
    }

    Specimen {
        title: qsTr("EmptyState")

        Rectangle {
            width: parent.width
            height: empty.implicitHeight
            radius: UiMetrics.radiusLg
            color: page.theme.bg
            border.width: UiMetrics.hairline
            border.color: page.theme.line

            EmptyState {
                id: empty

                width: parent.width
                title: qsTr("No recipes yet")
                text: qsTr("Add your first recipe, or import the ones you already have.")
                illustration: IconBadge {
                    shape: IconBadge.Tile
                    size: IconBadge.Large
                    iconName: "book"
                    family: page.butter
                }
                action: Button {
                    size: Button.Large
                    icon.name: "plus"
                    text: qsTr("New recipe")
                }
                secondaryAction: Button {
                    variant: Button.Text
                    text: qsTr("Import recipes")
                }
            }
        }
    }

    BottomSheet {
        id: planSheet

        title: qsTr("Add to plan")
        subtitle: qsTr("Gratin dauphinois")
        headerAction: Button {
            variant: Button.Text
            muted: true
            size: Button.Small
            text: qsTr("Cancel")
            onClicked: planSheet.close()
        }
        footer: Button {
            size: Button.Large
            text: qsTr("Add to plan")
            onClicked: {
                planSheet.close()
                ShowcaseState.notify(qsTr("Added to Thursday"), null)
            }
        }

        SegmentedControl {
            Layout.fillWidth: true
            currentIndex: 3

            Repeater {
                model: [qsTr("Mon"), qsTr("Tue"), qsTr("Wed"), qsTr("Thu"), qsTr("Fri")]

                delegate: SegmentedButton {
                    required property string modelData

                    text: modelData
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: qsTr("Servings")
                font: UiTypography.labelLBold
                color: page.theme.ink
            }

            Stepper {
                size: Stepper.Small
                text: qsTr("%1 servings").arg(page.planServings)
                canDecrease: page.planServings > 1
                onDecreaseClicked: page.planServings--
                onIncreaseClicked: page.planServings++
            }
        }
    }

    BottomSheet {
        id: listSheet

        tall: true
        title: qsTr("Ingredients")
        subtitle: qsTr("Pick what to add to the list")
        headerAction: Button {
            variant: Button.Secondary
            size: Button.Small
            text: qsTr("Done")
            onClicked: listSheet.close()
        }
        footer: RowLayout {
            spacing: UiMetrics.space3

            Button {
                variant: Button.Quiet
                destructive: true
                size: Button.Large
                icon.name: "trash"
                text: qsTr("Remove")
                onClicked: listSheet.close()
            }
            Button {
                Layout.fillWidth: true
                variant: Button.Secondary
                size: Button.Large
                text: qsTr("Done")
                onClicked: listSheet.close()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: sheetRows.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ListGroup {
                id: sheetRows

                width: parent.width
                iconRows: true

                Repeater {
                    model: [qsTr("Potatoes"), qsTr("Whole milk"), qsTr("Cream"), qsTr("Garlic"), qsTr("Butter"),
                        qsTr("Nutmeg"), qsTr("Gruyère"), qsTr("Red lentils"), qsTr("Coconut milk"),
                        qsTr("Ginger"), qsTr("Cumin"), qsTr("Coriander")]

                    delegate: ListRow {
                        required property string modelData

                        icon.name: "basket"
                        text: modelData
                        trailing: CheckBox {}
                    }
                }
            }
        }
    }

    BottomSheet {
        id: leaveSheet

        dismissible: false
        title: qsTr("Leave without saving?")
        subtitle: qsTr("Your changes to this recipe will be lost.")
        footer: RowLayout {
            spacing: UiMetrics.space3

            Button {
                variant: Button.Quiet
                destructive: true
                size: Button.Large
                icon.name: "trash"
                text: qsTr("Discard")
                onClicked: leaveSheet.close()
            }
            Button {
                Layout.fillWidth: true
                variant: Button.Secondary
                size: Button.Large
                text: qsTr("Keep editing")
                onClicked: leaveSheet.close()
            }
        }
    }

    Menu {
        id: recipeMenu

        title: qsTr("Gratin dauphinois")

        MenuItem {
            icon.name: "edit"
            text: qsTr("Edit")
        }
        MenuItem {
            icon.name: "calendar"
            text: qsTr("Add to plan")
        }
        MenuItem {
            icon.name: "upload"
            text: qsTr("Export")
        }
        MenuSeparator {}
        MenuItem {
            icon.name: "trash"
            destructive: true
            text: qsTr("Delete recipe")
            onTriggered: ShowcaseState.notify(qsTr("Recipe deleted"), () => ShowcaseState.notify(qsTr("Recipe restored"), null))
        }
    }

    Menu {
        id: viewMenu

        title: qsTr("Group by")

        MenuItem {
            text: qsTr("Aisle")
            checked: true
            hint: qsTr("As in your shop")
        }
        MenuItem {
            text: qsTr("Recipe")
        }
        MenuItem {
            text: qsTr("Nothing")
            enabled: false
        }
    }
}
