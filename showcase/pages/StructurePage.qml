import QtQuick
import QtQuick.Layouts
import Plating

GroupPage {
    id: page

    property int defaultServings: 4

    title: qsTr("Structure")
    subtitle: qsTr("ScreenHeader, SectionHeader, ListGroup and ListRow")

    Specimen {
        title: qsTr("ScreenHeader: top level")
        note: qsTr("Shown here inside the page; at the top of a screen it also clears the status bar.")

        Rectangle {
            width: parent.width
            height: topLevel.height
            color: page.theme.bg
            border.width: UiMetrics.hairline
            border.color: page.theme.line
            radius: UiMetrics.radiusMd

            ScreenHeader {
                id: topLevel

                width: parent.width
                title: qsTr("Recipes")
                subtitle: qsTr("24 recipes, 3 favorites")
                trailing: IconButton {
                    size: IconButton.Large
                    icon.name: "settings"
                    text: qsTr("Settings")
                }

                Row {
                    spacing: UiMetrics.space2

                    Button {
                        variant: Button.Secondary
                        size: Button.ExtraSmall
                        text: qsTr("All")
                    }
                    Button {
                        variant: Button.Quiet
                        size: Button.ExtraSmall
                        icon.name: "heart"
                        text: qsTr("Favorites")
                    }
                    Button {
                        variant: Button.Quiet
                        size: Button.ExtraSmall
                        icon.name: "clock"
                        text: qsTr("Quick")
                    }
                }
            }
        }
    }

    Specimen {
        title: qsTr("ScreenHeader: pushed")

        Rectangle {
            width: parent.width
            height: pushed.height
            color: page.theme.bg
            border.width: UiMetrics.hairline
            border.color: page.theme.line
            radius: UiMetrics.radiusMd

            ScreenHeader {
                id: pushed

                width: parent.width
                variant: ScreenHeader.Pushed
                title: qsTr("Dahl de lentilles corail")
                subtitle: qsTr("Serves 4 · 35 min")
                trailing: IconButton {
                    icon.name: "more"
                    text: qsTr("More")
                }
            }
        }
    }

    Specimen {
        title: qsTr("ScreenHeader: editor")

        Rectangle {
            width: parent.width
            height: editor.height
            color: page.theme.bg
            border.width: UiMetrics.hairline
            border.color: page.theme.line
            radius: UiMetrics.radiusMd

            ScreenHeader {
                id: editor

                width: parent.width
                variant: ScreenHeader.Editor
                title: qsTr("Edit recipe")
            }
        }
    }

    Specimen {
        title: qsTr("SectionHeader")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space4

            SectionHeader {
                Layout.fillWidth: true
                text: qsTr("Ingredients")
            }
            SectionHeader {
                Layout.fillWidth: true
                text: qsTr("Produce")
                count: "3"
                dotColor: page.theme.tagMintInk
            }
            SectionHeader {
                Layout.fillWidth: true
                size: SectionHeader.Large
                text: qsTr("In the cart")
                count: "2"
                actionText: qsTr("Clear")
            }
        }
    }

    Specimen {
        title: qsTr("ListGroup with icon rows")

        ListGroup {
            width: parent.width
            iconRows: true

            ListRow {
                icon.name: "book"
                text: qsTr("Recipes")
                value: "24"
                chevron: true
            }
            ListRow {
                icon.name: "basket"
                text: qsTr("Aisles")
                subtitle: qsTr("Produce, Dairy, Bakery and 5 more")
                chevron: true
            }
            ListRow {
                icon.name: "download"
                iconTone: ListRow.Neutral
                text: qsTr("Export")
                subtitle: qsTr("2 recipes have no photo")
                subtitleAccent: true
                chevron: true
            }
        }
    }

    Specimen {
        title: qsTr("ListRow: strong, used, trailing item, states")

        ListGroup {
            width: parent.width

            ListRow {
                strong: true
                text: qsTr("Gratin dauphinois")
                subtitle: qsTr("Cooked 3 weeks ago")
                chevron: true
            }
            ListRow {
                used: true
                text: qsTr("Dahl de lentilles corail")
                subtitle: qsTr("Already on the plan")
            }
            ListRow {
                text: qsTr("Tarte aux poireaux")
                trailing: IconButton {
                    size: IconButton.Small
                    variant: IconButton.Ghost
                    icon.name: "more"
                    text: qsTr("More")
                }
            }
            ListRow {
                down: true
                text: qsTr("Pressed")
                chevron: true
            }
            ListRow {
                enabled: false
                text: qsTr("Disabled")
                value: qsTr("Off")
            }
        }
    }

    Specimen {
        title: qsTr("ListRow: leading badge or tag, trailing switch or stepper")
        note: qsTr("Tapping the row toggles its switch.")

        ListGroup {
            width: parent.width
            iconRows: true

            ListRow {
                text: qsTr("Keep the screen on")
                subtitle: qsTr("While a recipe is open")
                icon.name: "clock"
                trailing: Switch {
                    checked: true
                }
            }
            ListRow {
                text: qsTr("Produce")
                subtitle: qsTr("12 items")
                leading: IconBadge {
                    iconName: "basket"
                    family: page.mint
                }
                chevron: true
            }
            ListRow {
                text: qsTr("Weeknight")
                leading: TagPill {
                    text: qsTr("Tag")
                    family: page.sky
                }
                value: qsTr("8 recipes")
            }
            ListRow {
                text: qsTr("Servings")
                icon.name: "book"
                iconTone: ListRow.Neutral
                trailing: Stepper {
                    size: Stepper.Small
                    text: `${page.defaultServings}`
                    canDecrease: page.defaultServings > 1
                    onDecreaseClicked: page.defaultServings--
                    onIncreaseClicked: page.defaultServings++
                }
            }
        }
    }

    Specimen {
        title: qsTr("ListRow: highlight")

        ListRow {
            width: parent.width
            highlighted: true
            text: qsTr("Plan this week")
            subtitle: qsTr("3 recipes planned, 4 to go")
        }
    }
}
