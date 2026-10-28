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
    // The TagEditRow sample that's open, or -1
    property int openTag: 0

    // Aisles with both variants of their colors, as AisleListModel gives them
    ListModel {
        id: aisles
    }

    // Tags with an index in `colors`
    ListModel {
        id: tags

        ListElement {
            name: qsTr("Brunch")
            colorIndex: 3
            count: 3
        }
        ListElement {
            name: qsTr("Vegetarian")
            colorIndex: 0
            count: 1
        }
        ListElement {
            name: qsTr("Weeknight")
            colorIndex: 2
            count: 0
        }
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
    subtitle: qsTr("Card, IconDiscStack, AislesButton, ColorDot, ColorMenu, AisleForm, AisleEditRow, AddField, TagEditRow, IngredientIconGrid")

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
        note: qsTr("Smaller than ColorSwatch: 44 targets, 30 discs, ringed when checked. Large: 48 discs, with a check. ColorMenu shows them in a menu.")

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

        Row {
            Repeater {
                model: page.colors

                delegate: ColorDot {
                    required property var modelData
                    required property int index

                    size: ColorDot.Large
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
        title: qsTr("AddField")
        note: qsTr("A pill field with an accent + inside, off while the field is blank. The + and Enter emit addClicked(); the field keeps focus.")

        AddField {
            id: addField

            width: parent.width
            placeholderText: qsTr("New tag")
            actionText: qsTr("Add tag")
            onAddClicked: {
                tags.append({ name: addField.text.trim(), colorIndex: tags.count % 4, count: 0 })
                addField.clear()
            }
        }
    }

    Specimen {
        title: qsTr("TagEditRow")
        note: qsTr("In a ListGroup, one open at a time. Closed: the tag's pill, its recipes and a chevron. Open: its name, its color, Delete and Done.")

        ListGroup {
            width: parent.width
            leftPadding: CookbookMetrics.tagsListPaddingH
            rightPadding: CookbookMetrics.tagsListPaddingH

            Repeater {
                model: tags

                delegate: TagEditRow {
                    id: tagRow

                    required property int index
                    required name
                    required colorIndex
                    required property int count

                    family: page.colors[tagRow.colorIndex].family
                    countText: tagRow.count === 1 ? qsTr("1 recipe") : qsTr("%1 recipes").arg(tagRow.count)
                    usageText: tagRow.count === 0 ? qsTr("Not used by any recipe")
                                                  : tagRow.count === 1 ? qsTr("Used by 1 recipe")
                                                                       : qsTr("Used by %1 recipes").arg(tagRow.count)
                    open: tagRow.index === page.openTag
                    colors: page.colors
                    onOpenClicked: page.openTag = tagRow.index
                    onRenamed: name => {
                        if (name.trim() !== "")
                            tags.setProperty(tagRow.index, "name", name.trim())
                    }
                    onColorClicked: index => tags.setProperty(tagRow.index, "colorIndex", index)
                    onDeleteClicked: {
                        ShowcaseState.notify(qsTr("“%1” deleted").arg(tagRow.name), () => {})
                        page.openTag = -1
                        tags.remove(tagRow.index)
                    }
                    onDoneClicked: page.openTag = -1
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
