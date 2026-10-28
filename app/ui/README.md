# CookbookUi

The app's own components, about recipes, ingredients and shopping: a static QML module, URI `CookbookUi`, built on Plating's components (see `plating/README.md` for the conventions they share). It never links or includes `core`: like Plating's, these components are presentational, and callers pass display strings.

| Group | Components |
| --- | --- |
| Quantities | `QuantityPill`, `QuantityField` |
| Recipes | `RecipeHeader`, `RecipeRow`, `PlannedRecipeCard`, `SortMenu`, `NoteCard` |
| Ingredients and steps | `IngredientRow`, `StepCard` |
| Shopping | `ShoppingItem`, `IngredientTile` |
| Catalog and settings | `Card`, `IconDiscStack`, `AislesButton`, `ColorDot`, `ColorMenu`, `AisleForm`, `AisleEditRow`, `IngredientIconGrid`, `AddField`, `TagEditRow` |

Their design px are in `CookbookMetrics.qml`, their own text styles in `CookbookTypography.qml`, the app's own durations in `CookbookMotion.qml`; everything else comes from Plating's theme.

Both the app and the showcase link `cookbookui` and `cookbookuiplugin` and call `Q_IMPORT_QML_PLUGIN(CookbookUiPlugin)`.

## Icons

Single-color SVG files on a 24 grid, drawn in black: `Icon` recolors them (`icon.source` on buttons, `iconSource` elsewhere).

- **Interface icons**, in `icons/ui/`: `CookbookIcons.source(name)` gives a file's URL. Plating's own components keep Plating's glyphs (the back button, the swatch check, the floating button's plus), drawn with the same paths.
- **Ingredient icons**, in `icons/ingredients/`, with a 1.8 stroke: `IngredientIcons.source(name)` gives a file's URL, or the jar's for an ingredient without its own icon. A file's name without `.svg` is the icon's key, which the database stores. `IngredientIcons.label(name)` names it for screen readers.

To add one, put `<name>.svg` in its folder, then list it in `CMakeLists.txt` (`RESOURCES`) and in the singleton's `names` (and `label()` for an ingredient).

## Notes

- `QuantityField` steps and converts with the unit data it's given (`units`: key, label, step, kind, factor), and emits `amountEdited()` and `unitEdited()`: the caller formats the amount and the summary. `header: false` drops its "Quantity" header, for a caller that labels the card itself.
- `SortMenu` builds the hint "Tap again for …" by lowercasing the other label's first letter, which suits English and French labels.
- `StepCard` lays its text out as a flow of words, so a mention can be a token that wraps with the words around it. The cost: lines break only at spaces (no hyphenation), and the text can't be selected. The card exposes the whole text to screen readers.
- `ColorDot`, `IngredientIconGrid` and the controls of `AisleEditRow` and `TagEditRow` are controlled: they emit what was clicked and show what they're given. `ColorDot.Large` is the tags editor's 48 disc, with a check when checked.
- `AislesButton` takes a model with `ink` and `darkInk` roles, like `AisleListModel`; its first three rows give the dots.
- `AddField` is Plating's `TextField` with its own + inside, because the field's Submit action can't take an accessible name ("Add tag") or be turned off while the field is blank.
- `TagEditRow` takes the tag's family resolved for the theme, like the other components: the app maps the key the database stores (`mint`…) to the theme's tag family.
