pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// Edits the aisles in place: their order, names and colors; adds and deletes
// them. Every change applies at once.
BottomSheet {
    id: sheet

    required property AisleListModel aisles

    // Something to tell the user, e.g. why a rename was undone
    signal message(string text)
    // The aisle was deleted; the caller can offer to undo it
    signal removed(string aisleId, string name)

    function report(error: int) {
        const text = ErrorTexts.aisle(error)
        if (text !== "")
            sheet.message(text)
    }

    function add() {
        const color = AisleColors.all[addForm.colorIndex]
        const error = sheet.aisles.create(addForm.name, color.fill, color.ink, color.darkFill, color.darkInk)
        if (error === AisleListModel.Error.NoError)
            addForm.name = ""
        else
            sheet.report(error)
    }

    // Fits its content until that's too tall; then the content scrolls
    tall: implicitContentHeight + topPadding + bottomPadding > maxHeight
    focus: true
    title: qsTr("Aisles")

    headerAction: Button {
        variant: Button.Secondary
        size: Button.Small
        text: qsTr("Done")
        onClicked: sheet.close()
    }

    // A caption between the parts
    component Caption: Text {
        font: UiTypography.caption
        lineHeightMode: Text.FixedHeight
        lineHeight: UiTypography.captionLineHeight
        color: sheet.theme.inkMuted
        wrapMode: Text.Wrap
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: parts.implicitHeight
        contentHeight: parts.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: parts

            width: parent.width
            spacing: UiMetrics.space4

            Caption {
                Layout.fillWidth: true
                text: qsTr("Your shopping list follows this order. Put them in the order you walk through your store.")
            }

            ListGroup {
                Layout.fillWidth: true
                iconRows: true

                Repeater {
                    model: sheet.aisles

                    delegate: AisleEditRow {
                        id: row

                        required property int index
                        required property string aisleId
                        required name
                        required property color fill
                        required property color ink
                        required property color darkFill
                        required property color darkInk
                        required property int itemCount

                        family: ({ fill: sheet.theme.dark ? row.darkFill : row.fill,
                                   ink: sheet.theme.dark ? row.darkInk : row.ink })
                        countText: qsTr("%Ln item(s)", "", row.itemCount)
                        canMoveUp: row.index > 0
                        canMoveDown: row.index < sheet.aisles.count - 1
                        canDelete: row.itemCount === 0
                        deleteText: row.canDelete ? qsTr("Delete %1").arg(row.name)
                                                  : qsTr("Can't delete %1: it still holds items").arg(row.name)

                        onRenamed: name => sheet.report(sheet.aisles.rename(row.index, name))
                        onColorClicked: {
                            colorMenu.row = row.index
                            colorMenu.currentIndex = AisleColors.indexOf(row.fill)
                            colorMenu.openUnder(row.dotButton)
                        }
                        onMoveUpClicked: sheet.report(sheet.aisles.move(row.index, row.index - 1))
                        onMoveDownClicked: sheet.report(sheet.aisles.move(row.index, row.index + 1))
                        onDeleteClicked: {
                            const aisleId = row.aisleId
                            const name = row.name
                            const error = sheet.aisles.remove(row.index)
                            if (error === AisleListModel.Error.NoError)
                                sheet.removed(aisleId, name)
                            else
                                sheet.report(error)
                        }
                    }
                }
            }

            Caption {
                Layout.fillWidth: true
                text: qsTr("An aisle that still holds items can't be deleted. Move its items to another aisle first.")
            }

            AisleForm {
                id: addForm

                Layout.fillWidth: true
                placeholderText: qsTr("Aisle name, e.g. Frozen")
                colors: AisleColors.choices(sheet.theme)
                onAddClicked: sheet.add()
            }
        }
    }

    ColorMenu {
        id: colorMenu

        // The aisle it recolors
        property int row: -1

        colors: AisleColors.choices(sheet.theme)
        onColorClicked: index => {
            const color = AisleColors.all[index]
            sheet.report(sheet.aisles.setColors(colorMenu.row, color.fill, color.ink, color.darkFill,
                                                color.darkInk))
        }
    }
}
