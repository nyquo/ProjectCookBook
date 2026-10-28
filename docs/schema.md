# Database schema

The migrations in [core/schema/](../core/schema/) are the source of truth; this page explains them. Conventions shared by every table (but `setting`, see [below](#setting)) are in [CLAUDE.md](../CLAUDE.md#database-conventions).

```mermaid
erDiagram
    tag_color {
        TEXT id PK "UUIDv7"
        TEXT name "trimmed; unique among live tag colors, ignoring ASCII case"
        TEXT fill "#rrggbb, lowercase"
        TEXT ink "#rrggbb, lowercase"
        TEXT dark_fill "#rrggbb, lowercase"
        TEXT dark_ink "#rrggbb, lowercase"
        INTEGER position "0..n-1 among live tag colors"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    aisle {
        TEXT id PK "UUIDv7"
        TEXT name "trimmed; unique among live aisles, ignoring ASCII case"
        TEXT fill "#rrggbb, lowercase"
        TEXT ink "#rrggbb, lowercase"
        TEXT dark_fill "#rrggbb, lowercase"
        TEXT dark_ink "#rrggbb, lowercase"
        INTEGER position "0..n-1 among live aisles"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    ingredient {
        TEXT id PK "UUIDv7"
        TEXT display_name "trimmed, as typed"
        TEXT canonical_name "computed by core; unique among live ingredients"
        TEXT aisle_id FK "nullable; may be a deleted aisle's"
        TEXT icon "nullable icon key"
        REAL one_tap_quantity "nullable; above 0"
        TEXT one_tap_unit "nullable; a unit code (see Units)"
        INTEGER in_catalog "0 or 1"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    tag {
        TEXT id PK "UUIDv7"
        TEXT name "trimmed, as typed"
        TEXT canonical_name "computed by core; unique among live tags"
        TEXT color "mint, butter, sky or peach"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    recipe {
        TEXT id PK "UUIDv7"
        TEXT title "trimmed"
        TEXT description "nullable"
        TEXT photo_id "nullable; SHA-256 of the photo file, 64 lowercase hex"
        INTEGER base_servings "1 or more; default 4"
        INTEGER prep_minutes "nullable; 0 or more"
        INTEGER cook_minutes "nullable; 0 or more"
        INTEGER cost_cents "nullable; euro cents, whole recipe"
        TEXT source "nullable; a link, a book, a person"
        TEXT notes "nullable"
        INTEGER favorite "0 or 1"
        INTEGER cook_count "0 or more"
        TEXT last_cooked "nullable; local date, YYYY-MM-DD"
        INTEGER last_planned_servings "nullable; 1 or more; unused for now"
        INTEGER created_at "ms since Unix epoch, UTC"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    recipe_ingredient {
        TEXT id PK "UUIDv7"
        TEXT recipe_id FK
        TEXT parent_id FK "nullable; set on a substitute"
        INTEGER position "among siblings"
        REAL quantity "nullable (to taste); above 0"
        TEXT unit "nullable; a unit code (see Units)"
        TEXT unit_text "nullable; a free-text unit, as typed"
        TEXT name "trimmed, as typed"
        TEXT ingredient_id FK "the dictionary entry"
        TEXT note "nullable"
        INTEGER optional "0 or 1"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    step {
        TEXT id PK "UUIDv7"
        TEXT recipe_id FK
        INTEGER position "0..n-1"
        TEXT text "not blank"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    step_mention {
        TEXT id PK "UUIDv7"
        TEXT step_id FK
        TEXT recipe_ingredient_id FK "a main ingredient"
        INTEGER start "code points into the step's text"
        INTEGER length "code points; 1 or more"
        REAL quantity "nullable (all of it); above 0"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    recipe_tag {
        TEXT id PK "UUIDv7"
        TEXT recipe_id FK
        TEXT tag_id FK "may be a deleted tag's"
        INTEGER modified_at "ms since Unix epoch, UTC"
        INTEGER deleted "0 or 1 (soft delete)"
    }
    setting {
        TEXT key PK "e.g. theme"
        TEXT value "a language-neutral code, e.g. dark"
        INTEGER modified_at "ms since Unix epoch, UTC"
    }
    aisle ||--o{ ingredient : "groups"
    recipe ||--o{ recipe_ingredient : "lists"
    recipe_ingredient |o--o{ recipe_ingredient : "has substitutes"
    ingredient ||--o{ recipe_ingredient : "is linked from"
    recipe ||--o{ step : "has"
    step ||--o{ step_mention : "marks words of"
    recipe_ingredient ||--o{ step_mention : "is mentioned by"
    recipe ||--o{ recipe_tag : "carries"
    tag ||--o{ recipe_tag : "labels"
```

There's no relation between `tag_color` and `aisle`: an aisle copies a tag color's four colors when it gets them. `tag` doesn't use `tag_color` either: it stores one of the theme's four tag families by key. `setting` stands alone.

## Units

`ingredient.one_tap_unit` and `recipe_ingredient.unit` take the same codes, mapped to `core::Unit`. The unit system setting only changes how amounts are shown (`core::shownAmount()`) and which units the app offers, never the stored unit.

| Kind | Codes |
| --- | --- |
| Mass | `g`, `kg`, `oz` (28.35 g), `lb` (453.6 g) |
| Volume | `ml`, `cl`, `l`, `tsp` (5 ml), `tbsp` (15 ml), `cup` (236.6 ml), `fl_oz` (29.57 ml) |
| Count | `pcs` |
| Discrete | `clove`, `pinch`, `pack`, `bunch`, `can` |

A recipe can also give a free-text unit ("handfuls", in `unit_text`), shown as typed and never converted.

## Colors

`tag_color` and `aisle` store colors the same way: four columns, read and written together as one `core::ThemedColors`.

| Column | Holds |
| --- | --- |
| `fill`, `ink` | In the light theme: the background, and the text and icons drawn on it. |
| `dark_fill`, `dark_ink` | The same in the dark theme. |

- **Format**: `#rrggbb`, lowercase hex, no alpha. The CHECK constraints (`GLOB '#[0-9a-f]...'`) accept nothing else, and `core::rgbFromText` parses nothing else, so equal colors have equal text. In C++, a color is a `core::Rgb`, so an invalid one can't reach a store.
- **Loading**: a stored color that isn't `#rrggbb` throws `DatabaseError` (`SQLITE_CORRUPT`). Only a write that bypassed the CHECK constraints can cause it.
- **Theme**: QML picks the pair with `UiTheme.dark`.

## tag_color

The colors offered for tags and aisles. Created by `001_catalog.sql`, loaded by `core::TagColorStore`, tested in `core/tests/tagColorStoreTests.cpp`.

**Read-only for now**: the store only loads the live rows, in position order (ties by id). It has no operations yet, so nothing in the app writes this table.

**Not used by the screens yet**: the aisle screens offer the theme's four tag families (Mint, Butter, Sky, Peach: `app/AisleColors.qml`), whose values equal these rows', and tags store one of those families by key (see [tag](#tag)).

**Name**: unique among live tag colors, ignoring ASCII case: the partial index `tag_color_name_live`, like `aisle_name_live`. Seeded in English; the app doesn't translate them.

**Seed rows**, in hue order with the neutral last, positions 0 to 7: Rose, Peach, Butter, Mint, Aqua, Sky, Lavender, Oat. Peach, Butter, Mint and Sky are the design's `tag-*` tokens (`docs/design/tokens.json`); the other four share their OKLCH lightness and chroma, with another hue. Every ink has 7:1 contrast or more on its fill, in both themes. Their ids and `modified_at` are fixed, so every device starts with identical rows.

## aisle

User-defined aisles that group the shopping list. Created by `001_catalog.sql`, managed by `core::AisleStore`, tested in `core/tests/aisleStoreTests.cpp`.

**Name**
- Trimmed of ASCII whitespace; empty → `EmptyName`.
- Unique among live aisles, ignoring ASCII case → `DuplicateName`. The store mirrors the partial index `aisle_name_live` (`COLLATE NOCASE ... WHERE deleted = 0`), so a deleted aisle's name can be reused. Non-ASCII letters don't fold: "Épices" and "épices" are different names.

**Colors**: the aisle's own copy, usually of a tag color's (see [Colors](#colors)). Changing or deleting a tag color later doesn't touch the aisles that copied it.

**Position**: live aisles always have positions 0..n-1, without gaps. If a gap or a duplicate ever reaches the database, loading renumbers the live aisles in order (ties by id) and updates `modified_at` on the renumbered rows. There's deliberately no unique index on `position`: SQLite checks UNIQUE row by row, so shifting several positions in one UPDATE would collide halfway.

**Operations**

| Operation | Effect |
| --- | --- |
| create | Appended last. |
| rename, setColors | One row. No write if nothing changes. setColors writes the four color columns together. |
| move(from, to) | The aisles in between shift by one. |
| remove | Refused (`InUse`) while catalog items are in the aisle. Otherwise soft delete (`deleted = 1`), then the live aisles after it shift up to close the gap. The deleted row keeps its old position. |
| restore | Back at min(old position, live count), shifting the others down. Fails with `DuplicateName` if a live aisle took the name meanwhile. |

- move, remove and restore are each one transaction.
- `modified_at` is updated on every row a change touches, including rows shifted by move, remove or restore.

**Seed rows**: Produce (Mint's colors), Dairy & eggs (Butter's), Meat & fish (Peach's), Pantry (Sky's), at positions 0 to 3. Their ids and `modified_at` are fixed, so every device starts with identical rows.

**"Other"** is not a row: the UI shows it for ingredients whose aisle is gone.

**Deleting**: refused while catalog items are in the aisle; ingredients outside the catalog don't hold it back, and show under "Other" once it's gone. Shopping-list items will hold it too; see the TODO in `AisleStore::remove`.

## ingredient

The ingredient dictionary, which recipe ingredients link to, and the shopping catalog: the rows with `in_catalog = 1`. Created by `001_catalog.sql`, managed by `core::IngredientStore`, tested in `core/tests/ingredientStoreTests.cpp`.

**Names**
- `display_name`: trimmed of ASCII whitespace, as the user typed it.
- `canonical_name`: `core::canonicalName(display_name)`: lowercase, accents removed, whitespace (no-break spaces too) trimmed and collapsed. "Crème  Fraîche" gives "creme fraiche". It folds ASCII and the Latin-1 and Latin Extended-A letters (œ gives "oe", ß "ss") and typographic apostrophes; other scripts stay as they are. No plural folding: "egg" and "eggs" are two ingredients.
- `canonical_name` is unique among live ingredients, catalog items or not: the partial index `ingredient_canonical_name_live`. Empty once folded → `EmptyName`.
- Search matches folded names: "creme" finds "Crème fraîche".

**Columns**
- `aisle_id`: references `aisle`. Since aisles are only soft-deleted, it can point to a deleted aisle: the UI then shows the ingredient under "Other".
- `icon`: an icon key, the file name of an icon in `app/ui/icons/ingredients/` without `.svg`. NULL: the UI shows the jar.
- `one_tap_quantity` and `one_tap_unit`: what one tap adds to the shopping list. Both set or both NULL (CHECK). The unit is one of the [unit codes](#units); the catalog offers the metric `pcs`, `g`, `kg`, `ml`, `cl`, `l`, `pack`, `bunch` and the US `pcs`, `oz`, `lb`, `fl_oz`, `pack`, `bunch`.
- A catalog row has an aisle and a one-tap amount (CHECK). The store also requires the aisle to be live.

**Operations**

| Operation | Effect |
| --- | --- |
| addToCatalog | A new row, appended. If a live ingredient outside the catalog has the same canonical name, that row is reused instead: it gets the new fields and `in_catalog = 1`. A catalog item with that name → `DuplicateName`. |
| updateCatalogItem | One row; no write if nothing changes. A name another catalog item has → `DuplicateName`; one an ingredient outside the catalog has → `NameTaken`. |
| removeFromCatalog | "Delete from catalog": `in_catalog = 0`, the row stays live for recipes. |
| restoreToCatalog | Undo: `in_catalog = 1` again. Fails with `AisleDeleted` if its aisle was deleted meanwhile. |
| dictionaryId | For recipes: the live row with the name's canonical name, catalog item or not; without one, a new row outside the catalog, with no aisle, icon or one-tap amount. |

The store keeps the live rows in creation order (by id). The catalog screen's order (aisle order, "Other" last, then by name in the user's locale) and its filters come from `core::catalogView()`.

**Seed rows**: 34 catalog items over the four default aisles (Produce 15, Dairy & eggs 7, Meat & fish 5, Pantry 7), each with an icon and a one-tap amount, using all eight metric units. Names are in English; the app doesn't translate them. Ids and `modified_at` are fixed like the aisles'.

## tag

The tags that label recipes. Created by `001_catalog.sql`, managed by `core::TagStore`, tested in `core/tests/tagStoreTests.cpp`.

**Names**
- `name`: trimmed of ASCII whitespace, as the user typed it.
- `canonical_name`: `core::canonicalName(name)`, the same folding as ingredient names: "Brünch" and " BRUNCH " are the same tag. Unique among live tags: the partial index `tag_canonical_name_live`, mirrored by the store. Empty once folded → `EmptyName`; taken by another live tag → `DuplicateName`.
- A rename to another case or spelling of the tag's own name is allowed.

**Color**: `color` is the key of one of the theme's four tag families, mapped to `core::TagFamily`. The theme gives its fill and ink in each theme, so unlike an aisle a tag stores no color values. A new tag takes the color least used among live tags; ties go in the order mint, butter, sky, peach.

**Operations**

| Operation | Effect |
| --- | --- |
| create | A new row, with the next color. |
| rename, setColor | One row. No write if nothing changes. |
| remove | Soft delete (`deleted = 1`). |
| restore | Undo: `deleted = 0`. Fails with `DuplicateName` if a live tag took the name meanwhile. |

The store keeps the live rows in id order, which is creation order; restoring a tag puts it back in that order. Screens sort them by name in the user's locale (`core::tagsByName()`).

**Recipes**: `recipe_tag` links tags to recipes. `core::RecipeStore::recipeCount()` counts the live recipes that carry a tag, for the tags editor. Deleting a tag leaves its links in place, so Undo finds them again; recipes show only live tags.

**No seed rows**: a new database has no tags.

## recipe

Recipes, with their ingredients (`recipe_ingredient`), steps (`step`), the ingredients those steps mention (`step_mention`) and their tags (`recipe_tag`). Created by `001_catalog.sql`. The five tables are read and written together, as one recipe, by `core::RecipeStore`, tested in `core/tests/recipeStoreTests.cpp`.

**recipe**
- `title` trimmed, not blank → `EmptyTitle`. Optional text fields (`description`, `source`, `notes`) are NULL when empty, never blank: the store trims them and drops blank ones.
- `photo_id`: the SHA-256, in lowercase hex, of the photo's JPEG file, which the app keeps as `photos/<photo_id>.jpg` in its private data. At startup, the app deletes the photo files no live recipe uses.
- `base_servings`: what the quantities are written for, 1 or more. The recipe screen scales them to the servings it shows (`core::shownAmount()`), which it never saves.
- `cost_cents`: the whole recipe's cost, in euro cents. Screens divide it by `base_servings`.
- `cook_count` and `last_cooked`, a local date `YYYY-MM-DD`: "Cooked it" adds one and sets today; Undo puts both back. The CHECK `date(last_cooked) IS last_cooked` accepts only valid dates in that form.
- `last_planned_servings`: unused for now.
- `created_at` is set once; `modified_at` on every change of the row, as everywhere.

**recipe_ingredient**
- `parent_id` set: a substitute for that main ingredient, one level only. `position` counts among siblings: main ingredients among themselves, a main ingredient's substitutes among themselves.
- `quantity` NULL: to taste. With a quantity, a unit: a [unit code](#units) in `unit` or a free-text one in `unit_text` ("handfuls"). Without a quantity, only `unit_text` can stay ("a handful"). Never both (CHECKs).
- `name`: trimmed, as the user typed it, not blank once folded → `EmptyIngredientName`. `ingredient_id` links the dictionary entry with the same canonical name, which the store adds outside the catalog when there's none (`IngredientStore::dictionaryId()`).

**step**: `text` not blank → `EmptyStep`, stored as given: mentions count in it. `position` 0..n-1.

**step_mention**: words of a step's text, `start` and `length` in Unicode code points, naming one of the recipe's main ingredients (never a substitute). `quantity`: what the step uses, in the ingredient's unit; NULL: all of it. The text always holds every word: a mention only marks some. The recipe screen shows, under each step, one amount per mentioned ingredient: its mentions in that step add up, a mention without quantity counts the whole quantity (`core::stepAmounts()`).

**recipe_tag**: a live recipe carries a tag once (partial unique index `recipe_tag_live`). `tag_id` may be a deleted tag's.

**Loading**: a row is live while its own `deleted` is 0. The store drops what a recipe can't show: substitutes whose main ingredient isn't live, mentions of an ingredient that isn't a live main one of the recipe, mentions outside their text or overlapping another. The text stays whole, so a deleted ingredient's mention just becomes plain words.

**Operations**

| Operation | Effect |
| --- | --- |
| create | A recipe and every row of it, in one transaction, after the dictionary links. Drafts that break a rule above are programming errors. |
| setFavorite | One row; no write if nothing changes. |
| markCooked | `cook_count + 1`, `last_cooked` today. Returns the history before, for Undo. |
| setCookingHistory | Undo of markCooked: both columns back. |
| remove | Soft delete of the `recipe` row only: its child rows stay as they were. |
| restore | Undo: `deleted = 0`, and the recipe comes back with its children. |

The store keeps live recipes in id order, which is creation order. The recipes list sorts them by title in the user's locale (`core::recipesByTitle()`).

**No seed rows**. Debug builds add sample recipes at startup when the table has no row at all, deleted ones included (`app/sampleRecipes.cpp`).

## setting

The app's settings, by key: a key-value table, so it breaks two of the conventions every other table follows. Created by `001_catalog.sql`, managed by `core::SettingStore`, tested in `core/tests/settingStoreTests.cpp`.

- **No `id`**: the key is the primary key.
- **No `deleted`**: a setting is set once, then only changes; nothing removes one. A key with no row has its default value.
- **Values** are language-neutral codes, never translated text. Code that owns a setting maps it to a C++ enum and falls back to the default for a value it doesn't know (e.g. written by a newer version). On/off settings are `true` or `false` (`SettingStore::flag()`).

| Key | Values | Default | Owner |
| --- | --- | --- | --- |
| `theme` | `system`, `light`, `dark` | `system` | `core/appearance.hpp` |
| `accent` | `raspberry`, `spirulina`, `blueberry`, `saffron`, `basil` | `raspberry` | `core/appearance.hpp` |
| `unit_system` | `metric`, `us` | `metric` | `core/unitSystem.hpp` |
| `default_favorites_only` | `true`, `false` | `false` | `core/defaultFilters.hpp` |
| `default_tag_ids` | tag ids, comma-separated | none | `core/defaultFilters.hpp` |
| `show_cost`, `show_times`, `show_step_amounts`, `show_cooking_history`, `show_source`, `show_notes` | `true`, `false` | `true` | `core/recipeFields.hpp` |
| `keep_screen_on` | `true`, `false` | `true` | `core/cooking.hpp` |

**Default tags**: `default_tag_ids` is a personal preference, so it's a setting rather than a column of `tag`. Reading it keeps only live tags' ids; a deleted tag's id stays stored, so restoring the tag brings it back into the defaults. Selecting or deselecting a tag changes only its own id.
