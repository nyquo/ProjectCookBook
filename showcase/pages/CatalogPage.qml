pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

GroupPage {
    id: page

    // The four aisle colors, as pickers take them
    readonly property var colors: [
        { name: qsTr("Mint"), family: page.mint },
        { name: qsTr("Butter"), family: page.butter },
        { name: qsTr("Sky"), family: page.sky },
        { name: qsTr("Peach"), family: page.peach }
    ]
    property int dotIndex: 0
    property string icon: "carrot"

    // Aisles with both variants of their colors, as AisleListModel gives them
    ListModel {
        id: aisles
    }

    Component.onCompleted: {
        const samples = [
            [qsTr("Produce"), "tagMint", 15],
            [qsTr("Dairy & eggs"), "tagButter", 7],
            [qsTr("Meat & fish"), "tagPeach", 5],
            [qsTr("Bakery"), "tagSky", 0]
        ]
        for (const [name, family, count] of samples) {
            aisles.append({
                name: name,
                fill: DefaultLightTheme[family],
                ink: DefaultLightTheme[`${family}Ink`],
                darkFill: DefaultDarkTheme[family],
                darkInk: DefaultDarkTheme[`${family}Ink`],
                count: count
            })
        }
    }

    scenes: [
        { name: "colormenu", show: () => { page.reveal(menuButton); colorMenu.openUnder(menuButton) }, hide: () => colorMenu.close() }
    ]

    title: qsTr("Catalog and settings")
    subtitle: qsTr("Card, IconDiscStack, AislesButton, ColorDot, ColorMenu, AisleForm, AisleEditRow, IngredientIconGrid")

    Specimen {
        title: qsTr("Card")
        note: qsTr("A surface card around one item, which spans its width. With a ring, it frames a form that adds something.")

        ColumnLayout {
            width: parent.width
            spacing: UiMetrics.space3

            Card {
                Layout.fillWidth: true

                Text {
                    text: qsTr("Changes buttons and highlights. Tag colors stay as they are.")
                    font: UiTypography.caption
                    color: page.theme.inkMuted
                    wrapMode: Text.Wrap
                }
            }

            Card {
                Layout.fillWidth: true
                ringColor: page.theme.accentSoft

                Text {
                    text: qsTr("Ringed in accent-soft")
                    font: UiTypography.labelLBold
                    color: page.theme.ink
                }
            }
        }
    }

    Specimen {
        title: qsTr("IconDiscStack")
        note: qsTr("A glimpse of what a list holds: discs overlapping by 8, ringed in surface.")
        onSurface: true

        IconDiscStack {
            discs: [
                { iconSource: IngredientIcons.source("carrot"), family: page.mint },
                { iconSource: IngredientIcons.source("cheese"), family: page.butter },
                { iconSource: IngredientIcons.source("sack"), family: page.sky }
            ]
        }
    }

    Specimen {
        title: qsTr("AislesButton")
        note: qsTr("The first three aisles' colors, then its text.")

        AislesButton {
            text: qsTr("Aisles · %1").arg(aisles.count)
            model: aisles
            onClicked: ShowcaseState.notify(qsTr("The aisles sheet opens"), null)
        }
    }

    Specimen {
        title: qsTr("ColorDot and ColorMenu")
        note: qsTr("Smaller than ColorSwatch: 44 targets, 30 discs, ringed when checked. ColorMenu shows them in a menu.")

        Row {
            Repeater {
                model: page.colors

                delegate: ColorDot {
                    required property var modelData
                    required property int index

                    text: modelData.name
                    family: modelData.family
                    checked: index === page.dotIndex
                    onClicked: page.dotIndex = index
                }
            }
        }

        Button {
            id: menuButton

            variant: Button.Quiet
            size: Button.Small
            text: qsTr("Pick a color")
            onClicked: colorMenu.openUnder(menuButton)
        }

        ColorMenu {
            id: colorMenu

            colors: page.colors
            currentIndex: page.dotIndex
            onColorClicked: index => page.dotIndex = index
        }
    }

    Specimen {
        title: qsTr("AisleForm")
        note: qsTr("Adds an aisle: a name and one of the colors. Enter or Add emit addClicked().")

        AisleForm {
            id: aisleForm

            width: parent.width
            placeholderText: qsTr("Aisle name, e.g. Frozen")
            colors: page.colors
            onAddClicked: {
                ShowcaseState.notify(qsTr("Would add %1").arg(aisleForm.name), null)
                aisleForm.name = ""
            }
        }
    }

    Specimen {
        title: qsTr("AisleEditRow")
        note: qsTr("In a ListGroup. Delete is off while the aisle holds items; its accessible name says why.")

        ListGroup {
            width: parent.width
            iconRows: true

            Repeater {
                model: aisles

                delegate: AisleEditRow {
                    id: row

                    required property int index
                    required name
                    required property color fill
                    required property color ink
                    required property color darkFill
                    required property color darkInk
                    required property int count

                    family: ({ fill: page.theme.dark ? row.darkFill : row.fill,
                               ink: page.theme.dark ? row.darkInk : row.ink })
                    countText: row.count === 1 ? qsTr("1 item") : qsTr("%1 items").arg(row.count)
                    canMoveUp: row.index > 0
                    canMoveDown: row.index < aisles.count - 1
                    canDelete: row.count === 0
                    deleteText: row.canDelete ? qsTr("Delete %1").arg(row.name)
                                              : qsTr("Can't delete %1: it still holds items").arg(row.name)
                    onRenamed: name => {
                        if (name.trim() !== "")
                            aisles.setProperty(row.index, "name", name.trim())
                    }
                    onColorClicked: ShowcaseState.notify(qsTr("A ColorMenu opens under the dot"), null)
                    onMoveUpClicked: aisles.move(row.index, row.index - 1, 1)
                    onMoveDownClicked: aisles.move(row.index, row.index + 1, 1)
                    onDeleteClicked: ShowcaseState.notify(qsTr("%1 deleted").arg(row.name), () => {})
                }
            }
        }
    }

    Specimen {
        title: qsTr("IngredientIconGrid")
        note: qsTr("Every ingredient icon, six to a row. The current one takes its aisle's family; picking it again clears it.")

        IngredientIconGrid {
            width: parent.width
            currentIcon: page.icon
            family: page.mint
            onIconClicked: name => page.icon = name === page.icon ? "" : name
        }
    }
}
