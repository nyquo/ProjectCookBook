pragma Singleton

import QtQuick
import Plating

// The app components' own geometry, in design px passed through UiScaler,
// grouped by component. Values shared with the library come from UiMetrics.
QtObject {
    id: root

    // QuantityPill: default, list and small
    readonly property real quantityPillHeight: UiScaler.scale(30)
    readonly property real quantityPillMinWidth: UiScaler.scale(70)
    readonly property real quantityPillListMinWidth: UiScaler.scale(56)
    readonly property real quantityPillPadding: UiScaler.scale(10)
    readonly property real quantityPillSmallHeight: UiScaler.scale(26)
    readonly property real quantityPillSmallMinWidth: UiMetrics.sizeTouch
    readonly property real quantityPillSmallPadding: UiMetrics.space2

    // QuantityField: card padding and gap; stepper gap; input; unit grid gap.
    // Compact: capsule padding, input width, unit pill width.
    readonly property real quantityFieldPadding: UiMetrics.space4
    readonly property real quantityFieldGap: UiScaler.scale(14)
    readonly property real quantityFieldStepperGap: UiMetrics.space4
    readonly property real quantityInputWidth: UiScaler.scale(110)
    readonly property real quantityInputHeight: UiMetrics.stepperButtonL
    readonly property real quantityUnitGap: UiScaler.scale(6)
    readonly property real quantityCompactPadding: UiScaler.scale(2)
    readonly property real quantityCompactInputWidth: UiScaler.scale(52)
    readonly property real quantityUnitMinWidth: UiMetrics.sizeTouch

    // NoteCard
    readonly property real noteCardPadding: UiScaler.scale(18)
    readonly property real noteCardGap: UiMetrics.space2

    // RecipeHeader: photo, how far the sheet overlaps it; buttons from the top
    // and the sides; the sheet's padding and gaps
    readonly property real recipeHeaderPhotoHeight: UiScaler.scale(310)
    readonly property real recipeHeaderOverlap: UiScaler.scale(36)
    readonly property real recipeHeaderButtonTop: UiMetrics.space5
    readonly property real recipeHeaderButtonSide: UiMetrics.space4
    readonly property real recipeHeaderButtonGap: UiMetrics.space2
    readonly property real recipeHeaderPaddingV: UiScaler.scale(26)
    readonly property real recipeHeaderPaddingH: UiMetrics.space5
    readonly property real recipeHeaderGap: UiMetrics.space3
    readonly property real recipeHeaderTagGap: UiScaler.scale(6)

    // RecipeRow
    readonly property real recipeRowPaddingV: UiScaler.scale(10)
    readonly property real recipeRowPaddingH: UiMetrics.space4
    readonly property real recipeRowGap: UiMetrics.space3
    readonly property real recipeRowTagGap: UiScaler.scale(5)
    readonly property real recipeRowTagsTop: UiScaler.scale(6)

    // PlannedRecipeCard
    readonly property real plannedCardPadding: UiMetrics.space3
    readonly property real plannedCardGap: UiMetrics.space3

    // The card IngredientRows sit in
    readonly property real ingredientsCardPaddingTop: UiScaler.scale(18)
    readonly property real ingredientsCardPaddingH: UiMetrics.space4
    readonly property real ingredientsCardPaddingBottom: UiMetrics.space2

    // IngredientRow, and its edit variant; the Substitute link
    readonly property real ingredientRowPaddingV: UiScaler.scale(10)
    readonly property real ingredientRowGap: UiMetrics.space3
    readonly property real ingredientRowEditHeight: UiScaler.scale(56)
    readonly property real ingredientRowEditGap: UiMetrics.space2
    readonly property real ingredientRowHandle: UiMetrics.iconL
    readonly property real substituteHeight: UiMetrics.space8
    readonly property real substituteIcon: UiScaler.scale(15)

    // StepCard: padding, gap, number disc, text's top padding; the amounts row
    readonly property real stepCardPadding: UiMetrics.space4
    readonly property real stepCardGap: UiScaler.scale(14)
    readonly property real stepDisc: UiScaler.scale(40)
    readonly property real stepTextTop: UiScaler.scale(7)
    readonly property real stepAmountsGap: UiMetrics.space3
    readonly property real stepAmountsLineGap: UiMetrics.space2
    readonly property real stepAmountsItemGap: UiScaler.scale(14)
    readonly property real stepAmountNameGap: UiScaler.scale(6)
    // StepCard edit variant: padding, gap, disc; mention tokens; amount chips;
    // drag handle; the row that inserts a step
    readonly property real stepCardEditPaddingV: UiScaler.scale(14)
    readonly property real stepCardEditPaddingStart: UiScaler.scale(14)
    readonly property real stepCardEditPaddingEnd: UiMetrics.space2
    readonly property real stepCardEditGap: UiMetrics.space3
    readonly property real stepDiscEdit: UiScaler.scale(36)
    readonly property real stepTokenHeight: UiScaler.scale(28)
    readonly property real stepTokenPadding: UiScaler.scale(9)
    readonly property real stepAmountChipHeight: UiScaler.scale(36)
    readonly property real stepAmountChipPaddingStart: UiMetrics.space1
    readonly property real stepAmountChipPaddingEnd: UiMetrics.space3
    readonly property real stepAmountPillHeight: UiScaler.scale(28)
    readonly property real stepHandleWidth: UiScaler.scale(28)
    readonly property real stepInsertHeight: UiScaler.scale(36)
    readonly property real stepInsertDisc: UiScaler.scale(32)

    // ShoppingItem, unchecked then checked; its check circle
    readonly property real shoppingItemHeight: UiScaler.scale(68)
    readonly property real shoppingItemHeightChecked: UiScaler.scale(60)
    readonly property real shoppingItemPaddingV: UiMetrics.space3
    readonly property real shoppingItemPaddingVChecked: UiScaler.scale(10)
    readonly property real shoppingItemGap: UiMetrics.space3
    readonly property real shoppingCheck: UiScaler.scale(30)
    readonly property real shoppingCheckRing: UiScaler.scale(2.5)
    readonly property real shoppingQuantityGap: UiMetrics.space1
    // Between aisle groups of the shopping list
    readonly property real shoppingGroupGap: UiScaler.scale(14)

    // IngredientTile, and its stepper's capsule padding
    readonly property real ingredientTilePadding: UiMetrics.space2
    readonly property real ingredientTileGap: UiMetrics.space2
    readonly property real ingredientTileRadius: UiScaler.scale(22)
    readonly property real ingredientTileStepperPadding: UiScaler.scale(2)
    readonly property real ingredientTileLinkIcon: UiMetrics.space3
}
