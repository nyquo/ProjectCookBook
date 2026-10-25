import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// An ingredient of the quick-add grid. Clicking an available one emits
// addClicked(); on the list it's ringed in accent and shows a removable
// stepper; needed by a recipe, it's dimmed and says so.
T.AbstractButton {
    id: control

    enum Status {
        Available,
        OnList,
        Needed
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int status: IngredientTile.Available
    // An IngredientIcons name; the jar without one
    property string ingredientIcon
    // The aisle's family
    property colorFamily family
    // Under the name while available: the default amount ("1 kg")
    property string amount
    // Needed: why ("On your list, for Dahl")
    property string neededText
    // On the list: the stepper's value ("1 kg")
    property string quantity
    property bool canDecrease: true
    property bool canIncrease: true

    signal addClicked
    signal decreaseClicked
    signal increaseClicked
    signal removeClicked

    readonly property bool onList: control.status === IngredientTile.OnList
    readonly property bool needed: control.status === IngredientTile.Needed

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    enabled: !control.needed
    opacity: control.needed ? UiMetrics.opacityMuted : 1
    padding: CookbookMetrics.ingredientTilePadding
    spacing: CookbookMetrics.ingredientTileGap
    font: UiTypography.labelBold
    // Only an available tile adds; on the list, the stepper does the rest
    focusPolicy: control.status === IngredientTile.Available ? Qt.StrongFocus : Qt.NoFocus

    onClicked: {
        if (control.status === IngredientTile.Available)
            control.addClicked()
    }

    contentItem: ColumnLayout {
        spacing: control.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: control.spacing

            IconBadge {
                size: IconBadge.Large
                iconSource: IngredientIcons.source(control.ingredientIcon)
                family: control.family
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: control.text
                    font: control.font
                    color: control.theme.ink
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: UiMetrics.space1

                    Icon {
                        visible: control.needed
                        Layout.preferredWidth: CookbookMetrics.ingredientTileLinkIcon
                        Layout.preferredHeight: CookbookMetrics.ingredientTileLinkIcon
                        name: "link"
                        color: control.theme.inkMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: control.onList ? qsTr("Added") : control.needed ? control.neededText : control.amount
                        font: UiTypography.overline
                        color: control.onList ? control.theme.accent : control.theme.inkMuted
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Stepper {
            visible: control.onList
            Layout.fillWidth: true
            padding: CookbookMetrics.ingredientTileStepperPadding
            font: UiTypography.labelExtraBold
            text: control.quantity
            canDecrease: control.canDecrease
            canIncrease: control.canIncrease
            removable: true
            onDecreaseClicked: control.decreaseClicked()
            onIncreaseClicked: control.increaseClicked()
            onRemoveClicked: control.removeClicked()
        }
    }

    background: Rectangle {
        radius: CookbookMetrics.ingredientTileRadius
        color: control.theme.surface
        border.width: control.onList ? UiMetrics.borderStrong : 0
        border.color: control.theme.accent

        PressOverlay {
            radius: parent.radius
            pressed: control.down && control.status === IngredientTile.Available
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }
}
