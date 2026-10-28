import QtQuick
import QtQuick.Layouts
import Plating

// The card a recipe's IngredientRows sit in: its title and an optional item on
// the right (the servings Stepper), then the rows given to it
Rectangle {
    id: card

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string title: qsTr("Ingredients")
    // Right of the title
    property Item trailing
    default property alias rows: column.data

    implicitHeight: column.implicitHeight + CookbookMetrics.ingredientsCardPaddingTop
                    + CookbookMetrics.ingredientsCardPaddingBottom
    radius: UiMetrics.radiusLg
    color: card.theme.surface

    ColumnLayout {
        id: column

        x: CookbookMetrics.ingredientsCardPaddingH
        y: CookbookMetrics.ingredientsCardPaddingTop
        width: parent.width - 2 * CookbookMetrics.ingredientsCardPaddingH
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: CookbookMetrics.ingredientsCardTitleGap
            spacing: UiMetrics.space3

            Text {
                Layout.fillWidth: true
                text: card.title
                font: UiTypography.titleL
                color: card.theme.ink
                elide: Text.ElideRight
                Accessible.role: Accessible.Heading
            }

            Item {
                visible: card.trailing !== null
                implicitWidth: card.trailing?.implicitWidth ?? 0
                implicitHeight: card.trailing?.implicitHeight ?? 0
                children: card.trailing ? [card.trailing] : []
            }
        }
    }
}
