# CookbookUi: the app's own components (recipes, ingredients, shopping), built on
# Plating. Presentational only: never links or includes core (see the guard in
# the root CMakeLists.txt), and Plating never depends on it.
qt_add_library(cookbookui STATIC)

set_source_files_properties(
    CookbookMetrics.qml
    CookbookTypography.qml
    IngredientIcons.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(cookbookui
    URI CookbookUi
    # Gives qmlcachegen Plating's import path, so it compiles typed code
    DEPENDENCIES TARGET plating
    QML_FILES
        CookbookMetrics.qml
        CookbookTypography.qml
        IngredientIcons.qml
        IngredientRow.qml
        IngredientTile.qml
        NoteCard.qml
        PlannedRecipeCard.qml
        QuantityField.qml
        QuantityPill.qml
        RecipeHeader.qml
        RecipeRow.qml
        ShoppingItem.qml
        SortMenu.qml
        StepCard.qml
    # Ingredient icons: see IngredientIcons.qml
    RESOURCES
        icons/ingredients/jar.svg
)

target_link_libraries(cookbookui PRIVATE Qt6::Quick)
# On Android it ends up inside the executable's shared library
set_target_properties(cookbookui cookbookuiplugin PROPERTIES POSITION_INDEPENDENT_CODE ON)
cookbook_set_warnings(cookbookui)
