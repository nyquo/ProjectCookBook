pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// The shopping catalog: its items by aisle, searchable and filtered by aisle,
// with the item sheet to add or edit one and the aisles sheet
AppScreen {
    id: screen

    readonly property real sideMargin: UiMetrics.space4

    // Tells the user why a change failed, if there's something to say
    function report(text: string) {
        if (text !== "")
            screen.notify(text, "", null)
    }

    // A chip of the aisle filter, one checked at a time
    component FilterChoice: ChoiceChip {
        id: choice

        required property string filter

        checkable: false
        checked: catalogModel.aisleFilter === choice.filter
        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: choice.checked
        onClicked: catalogModel.aisleFilter = choice.filter
    }

    snackbarOffset: screen.SafeArea.margins.bottom + CookbookMetrics.catalogFabBottom + fab.height

    CatalogListModel {
        id: catalogModel
    }

    AisleListModel {
        id: aisleModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScreenHeader {
            Layout.fillWidth: true
            variant: ScreenHeader.Pushed
            title: qsTr("Catalog")
            trailing: AislesButton {
                text: qsTr("Aisles · %1").arg(aisleModel.count.toLocaleString(Qt.locale(), "f", 0))
                model: aisleModel
                onClicked: aislesSheet.open()
            }
            onBackClicked: screen.StackView.view.pop()
        }

        ColumnLayout {
            Layout.fillWidth: true
            // The header already ends with a gap of its own
            Layout.topMargin: CookbookMetrics.catalogHeaderGap - UiMetrics.headerPushedBottomPadding
            Layout.leftMargin: screen.sideMargin + screen.SafeArea.margins.left
            Layout.rightMargin: screen.sideMargin + screen.SafeArea.margins.right
            spacing: CookbookMetrics.catalogHeaderGap

            Text {
                Layout.fillWidth: true
                text: qsTr("What you can add to the shopping list in one tap. Recipes also use it to pick icons.")
                font: UiTypography.bodyS
                lineHeightMode: Text.FixedHeight
                lineHeight: UiTypography.bodySLineHeight
                color: screen.theme.inkMuted
                wrapMode: Text.Wrap
            }

            SearchField {
                Layout.fillWidth: true
                placeholderText: qsTr("Search the catalog")
                onTextChanged: catalogModel.searchText = text
            }
        }

        // Scrolls past the side margins, to the screen's edges
        Flickable {
            Layout.fillWidth: true
            Layout.topMargin: CookbookMetrics.catalogHeaderGap
            implicitHeight: chips.implicitHeight
            contentWidth: chips.implicitWidth + 2 * screen.sideMargin + screen.SafeArea.margins.left
                          + screen.SafeArea.margins.right
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: chips

                x: screen.sideMargin + screen.SafeArea.margins.left
                spacing: UiMetrics.space2

                FilterChoice {
                    filter: ""
                    text: qsTr("All")
                }

                Repeater {
                    model: aisleModel

                    delegate: FilterChoice {
                        required property string aisleId
                        required property string name
                        required property color ink
                        required property color darkInk

                        filter: aisleId
                        text: name
                        dotColor: screen.theme.dark ? darkInk : ink
                    }
                }
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: UiMetrics.space4
            clip: true
            model: catalogModel
            boundsBehavior: Flickable.StopAtBounds
            leftMargin: screen.sideMargin + screen.SafeArea.margins.left
            rightMargin: screen.sideMargin + screen.SafeArea.margins.right
            // Room for the floating button, so it never hides the last row
            bottomMargin: screen.snackbarOffset + UiMetrics.space4

            delegate: Column {
                id: entry

                required property int index
                required property string ingredientId
                required property string name
                required property string icon
                required property real quantity
                required property string unit
                required property string amountText
                required property string aisleId
                required property string aisleName
                required property color fill
                required property color ink
                required property color darkFill
                required property color darkInk
                required property int groupCount
                required property bool firstInGroup
                required property bool lastInGroup

                // No live aisle: neutral colors
                readonly property bool other: entry.aisleId === ""
                readonly property colorFamily family: ({
                                                           fill: screen.theme.dark ? entry.darkFill : entry.fill,
                                                           ink: screen.theme.dark ? entry.darkInk : entry.ink
                                                       })

                width: ListView.view.width - list.leftMargin - list.rightMargin
                topPadding: entry.firstInGroup && entry.index > 0 ? CookbookMetrics.catalogGroupGap : 0

                SectionHeader {
                    width: parent.width
                    visible: entry.firstInGroup
                    text: entry.other ? qsTr("Other") : entry.aisleName
                    count: entry.groupCount.toLocaleString(Qt.locale(), "f", 0)
                    dotColor: entry.other ? screen.theme.inkMuted : entry.family.ink
                }

                // This row's part of its aisle's card
                Rectangle {
                    width: parent.width
                    height: row.height
                    color: screen.theme.surface
                    topLeftRadius: entry.firstInGroup ? UiMetrics.radiusLg : 0
                    topRightRadius: entry.firstInGroup ? UiMetrics.radiusLg : 0
                    bottomLeftRadius: entry.lastInGroup ? UiMetrics.radiusLg : 0
                    bottomRightRadius: entry.lastInGroup ? UiMetrics.radiusLg : 0

                    Rectangle {
                        x: UiMetrics.listGroupIconPaddingH
                        width: parent.width - 2 * UiMetrics.listGroupIconPaddingH
                        height: UiMetrics.hairline
                        visible: !entry.firstInGroup
                        color: screen.theme.line
                    }

                    ListRow {
                        id: row

                        x: UiMetrics.listGroupIconPaddingH
                        width: parent.width - 2 * UiMetrics.listGroupIconPaddingH
                        text: entry.name
                        subtitle: qsTr("One tap adds %1").arg(entry.amountText)
                        strong: true
                        leading: IconBadge {
                            shape: IconBadge.Tile
                            size: IconBadge.Small
                            iconSource: IngredientIcons.source(entry.icon)
                            family: entry.family
                            muted: entry.other
                        }
                        trailing: Icon {
                            implicitWidth: CookbookMetrics.catalogEditIcon
                            implicitHeight: CookbookMetrics.catalogEditIcon
                            source: CookbookIcons.source("edit")
                            color: screen.theme.inkMuted
                        }
                        onClicked: itemSheet.openItem(entry.ingredientId, entry.name, entry.aisleId, entry.icon,
                                                      entry.quantity, entry.unit)
                    }
                }
            }

            // Over the list rather than in its content, which scrolls
            Text {
                parent: list
                anchors.centerIn: parent
                width: parent.width - 2 * screen.sideMargin
                visible: list.count === 0
                text: catalogModel.searchText !== "" ? qsTr("Nothing in the catalog matches “%1”.").arg(catalogModel.searchText)
                                                : qsTr("No items here yet.")
                font: UiTypography.bodyL
                color: screen.theme.inkMuted
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    FloatingActionButton {
        id: fab

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: CookbookMetrics.catalogFabRight + screen.SafeArea.margins.right
        anchors.bottomMargin: CookbookMetrics.catalogFabBottom + screen.SafeArea.margins.bottom
        extended: true
        text: qsTr("New item")
        enabled: aisleModel.count > 0
        onClicked: itemSheet.openNew(catalogModel.aisleFilter !== "" ? catalogModel.aisleFilter : aisleModel.aisleIdAt(0))
    }

    CatalogItemSheet {
        id: itemSheet

        catalog: catalogModel
        aisles: aisleModel
        onRemoved: (ingredientId, name) => {
            screen.notify(qsTr("%1 deleted from the catalog").arg(name), qsTr("Undo"),
                          () => screen.report(ErrorTexts.catalog(catalogModel.restoreToCatalog(ingredientId))))
        }
        onFailed: error => screen.report(ErrorTexts.catalog(error))
        onMessage: text => screen.report(text)
    }

    AislesSheet {
        id: aislesSheet

        aisles: aisleModel
        onMessage: text => screen.report(text)
        onRemoved: (aisleId, name) => {
            screen.notify(qsTr("%1 deleted").arg(name), qsTr("Undo"),
                          () => screen.report(ErrorTexts.aisle(aisleModel.restore(aisleId))))
        }
    }
}
