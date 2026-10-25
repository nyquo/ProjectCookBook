# CookbookUi

The app's own components, about recipes, ingredients and shopping: a static QML module, URI `CookbookUi`, built on Plating's components (see `plating/README.md` for the conventions they share). It never links or includes `core`: like Plating's, these components are presentational, and callers pass display strings.

| Group | Components |
| --- | --- |
| Quantities | `QuantityPill`, `QuantityField` |
| Recipes | `RecipeHeader`, `RecipeRow`, `PlannedRecipeCard`, `SortMenu`, `NoteCard` |
| Ingredients and steps | `IngredientRow`, `StepCard` |
| Shopping | `ShoppingItem`, `IngredientTile` |

Their design px are in `CookbookMetrics.qml`, their own text styles in `CookbookTypography.qml`; everything else comes from Plating's theme.

Both the app and the showcase link `cookbookui` and `cookbookuiplugin` and call `Q_IMPORT_QML_PLUGIN(CookbookUiPlugin)`.

## Ingredient icons

Single-color SVG files in `icons/ingredients/`, on a 24 grid with a 1.8 stroke, drawn in black: `Icon` recolors them. `IngredientIcons.source(name)` gives a file's URL, or the jar's for an ingredient without its own icon. To add one, put `<name>.svg` in the folder, then list it in `CMakeLists.txt` (`RESOURCES`) and in `IngredientIcons.names`.

## Notes

- `QuantityField` steps and converts with the unit data it's given (`units`: key, label, step, kind, factor), and emits `amountEdited()` and `unitEdited()`: the caller formats the amount and the summary.
- `SortMenu` builds the hint "Tap again for …" by lowercasing the other label's first letter, which suits English and French labels.
- `StepCard` lays its text out as a flow of words, so a mention can be a token that wraps with the words around it. The cost: lines break only at spaces (no hyphenation), and the text can't be selected. The card exposes the whole text to screen readers.
