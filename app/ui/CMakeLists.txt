# CookbookUi: the app's own components (recipes, ingredients, shopping), built on
# Plating. Presentational only: never links or includes core (see the guard in
# the root CMakeLists.txt), and Plating never depends on it.
qt_add_library(cookbookui STATIC)

set_source_files_properties(
    CookbookIcons.qml
    CookbookMetrics.qml
    CookbookMotion.qml
    CookbookTypography.qml
    IngredientIcons.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(cookbookui
    URI CookbookUi
    # Gives qmlcachegen Plating's import path, so it compiles typed code
    DEPENDENCIES TARGET plating
    QML_FILES
        AddField.qml
        AisleEditRow.qml
        AisleForm.qml
        AislesButton.qml
        Card.qml
        ColorDot.qml
        ColorMenu.qml
        CookbookIcons.qml
        CookbookMetrics.qml
        CookbookMotion.qml
        CookbookTypography.qml
        IconDiscStack.qml
        IngredientIconGrid.qml
        IngredientIcons.qml
        IngredientRow.qml
        IngredientsCard.qml
        IngredientTile.qml
        NoteCard.qml
        PlannedRecipeCard.qml
        QuantityField.qml
        QuantityPill.qml
        RecipeActions.qml
        RecipeHeader.qml
        RecipeRow.qml
        ShoppingItem.qml
        SortMenu.qml
        StepCard.qml
        TagEditRow.qml
    # Icons: see CookbookIcons.qml and IngredientIcons.qml
    RESOURCES
        icons/ingredients/apple.svg
        icons/ingredients/banana.svg
        icons/ingredients/bottle.svg
        icons/ingredients/bread.svg
        icons/ingredients/bulb.svg
        icons/ingredients/butter.svg
        icons/ingredients/can.svg
        icons/ingredients/carrot.svg
        icons/ingredients/cheese.svg
        icons/ingredients/cup.svg
        icons/ingredients/drumstick.svg
        icons/ingredients/egg.svg
        icons/ingredients/fish.svg
        icons/ingredients/jar.svg
        icons/ingredients/leaf.svg
        icons/ingredients/lemon.svg
        icons/ingredients/milk.svg
        icons/ingredients/mushroom.svg
        icons/ingredients/pepper.svg
        icons/ingredients/potato.svg
        icons/ingredients/sack.svg
        icons/ingredients/spice.svg
        icons/ingredients/tomato.svg
        icons/ui/back.svg
        icons/ui/check.svg
        icons/ui/chevron-right.svg
        icons/ui/down.svg
        icons/ui/edit.svg
        icons/ui/minus.svg
        icons/ui/moon.svg
        icons/ui/phone.svg
        icons/ui/planning.svg
        icons/ui/plus.svg
        icons/ui/recipes.svg
        icons/ui/search.svg
        icons/ui/settings.svg
        icons/ui/shopping.svg
        icons/ui/sun.svg
        icons/ui/trash.svg
        icons/ui/up.svg
)

target_link_libraries(cookbookui PRIVATE Qt6::Quick)
# On Android it ends up inside the executable's shared library
set_target_properties(cookbookui cookbookuiplugin PROPERTIES POSITION_INDEPENDENT_CODE ON)
cookbook_set_warnings(cookbookui)
