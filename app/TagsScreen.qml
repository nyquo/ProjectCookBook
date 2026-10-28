pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// The tags editor, pushed from Settings: adds tags, renames and recolors them
// in place, and deletes them with Undo. Every change applies at once.
AppScreen {
    id: screen

    // The open row's tag, or "" while all are closed: one at a time
    property string openTagId
    // Its row, which the list keeps in view
    property Item openRow: null

    readonly property real sideMargin: CookbookMetrics.tagsHeaderPadding

    // Tells the user why a change failed, if there's something to say
    function report(error: int) {
        const text = ErrorTexts.tag(error)
        if (text !== "")
            screen.notify(text, "", null)
    }

    function add() {
        const error = tagModel.create(addField.text)
        if (error === TagListModel.Error.NoError)
            addField.clear()
        else
            screen.report(error)
    }

    function remove(tagId: string, name: string, recipeCount: int) {
        const error = tagModel.remove(tagId)
        if (error !== TagListModel.Error.NoError) {
            screen.report(error)
            return
        }
        screen.openTagId = ""
        const message = recipeCount > 0 ? qsTr("“%1” deleted from %Ln recipe(s)", "", recipeCount).arg(name)
                                        : qsTr("“%1” deleted").arg(name)
        screen.notify(message, qsTr("Undo"), () => screen.report(tagModel.restore(tagId)))
    }

    // Scrolls the list so that the open row shows whole, as far as it can
    function revealOpenRow() {
        if (!screen.openRow)
            return
        const top = screen.openRow.mapToItem(flick.contentItem, 0, 0).y
        const bottom = top + screen.openRow.height
        if (bottom > flick.contentY + flick.height)
            flick.contentY = Math.max(0, Math.min(bottom - flick.height, flick.contentHeight - flick.height))
        if (top < flick.contentY)
            flick.contentY = Math.max(0, top)
    }

    TagListModel {
        id: tagModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: CookbookMetrics.tagsHeaderPadding + screen.SafeArea.margins.top
            Layout.leftMargin: screen.sideMargin + screen.SafeArea.margins.left
            Layout.rightMargin: screen.sideMargin + screen.SafeArea.margins.right
            spacing: CookbookMetrics.tagsHeaderGap

            IconButton {
                icon.name: "back"
                text: qsTr("Back to settings")
                onClicked: screen.StackView.view.pop()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: CookbookMetrics.tagsSubtitleGap

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Tags")
                    font: UiTypography.titleXL
                    lineHeightMode: Text.FixedHeight
                    lineHeight: UiTypography.titleXL.pixelSize
                    color: screen.theme.ink
                    wrapMode: Text.Wrap
                    Accessible.role: Accessible.Heading
                }

                Text {
                    Layout.fillWidth: true
                    text: tagModel.count > 0
                          ? qsTr("%Ln tag(s). Tap one to rename it or change its color.", "", tagModel.count)
                          : qsTr("No tags yet. Add your first one.")
                    font: UiTypography.bodyS
                    lineHeightMode: Text.FixedHeight
                    lineHeight: UiTypography.bodySLineHeight
                    color: screen.theme.inkMuted
                    wrapMode: Text.Wrap
                }
            }

            AddField {
                id: addField

                Layout.fillWidth: true
                placeholderText: qsTr("New tag")
                actionText: qsTr("Add tag")
                onAddClicked: screen.add()
            }
        }

        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: CookbookMetrics.tagsListTop
            contentHeight: list.visible ? list.height + UiMetrics.space8 + screen.SafeArea.margins.bottom : 0
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            // The list lays out after the open row grows
            onContentHeightChanged: screen.revealOpenRow()

            ListGroup {
                id: list

                x: screen.sideMargin + screen.SafeArea.margins.left
                width: flick.width - 2 * screen.sideMargin - screen.SafeArea.margins.left
                       - screen.SafeArea.margins.right
                visible: tagModel.count > 0
                topPadding: CookbookMetrics.tagsListPaddingV
                bottomPadding: CookbookMetrics.tagsListPaddingV
                leftPadding: CookbookMetrics.tagsListPaddingH
                rightPadding: CookbookMetrics.tagsListPaddingH

                Repeater {
                    model: tagModel

                    delegate: TagEditRow {
                        id: row

                        required property string tagId
                        required name
                        required property string colorKey
                        required property int recipeCount

                        family: TagFamilies.family(screen.theme, row.colorKey)
                        countText: qsTr("%Ln recipe(s)", "", row.recipeCount)
                        usageText: row.recipeCount > 0 ? qsTr("Used by %Ln recipe(s)", "", row.recipeCount)
                                                       : qsTr("Not used by any recipe")
                        open: screen.openTagId === row.tagId
                        colors: TagFamilies.choices(screen.theme)
                        colorIndex: TagFamilies.indexOf(row.colorKey)

                        onOpenClicked: screen.openTagId = row.tagId
                        onRenamed: name => screen.report(tagModel.rename(row.tagId, name))
                        onColorClicked: index => screen.report(tagModel.setColor(row.tagId,
                                                                                 TagFamilies.all[index].key))
                        onDeleteClicked: screen.remove(row.tagId, row.name, row.recipeCount)
                        onDoneClicked: screen.openTagId = ""

                        onOpenChanged: {
                            if (row.open)
                                screen.openRow = row
                            else if (screen.openRow === row)
                                screen.openRow = null
                        }
                        // Opening it, closing the one above, a rename that moves it
                        onHeightChanged: {
                            if (row.open)
                                screen.revealOpenRow()
                        }
                        onYChanged: {
                            if (row.open)
                                screen.revealOpenRow()
                        }
                    }
                }
            }
        }
    }
}
