-- The colors offered for tags and aisles: a fill and its ink, for each theme.
-- Rules: docs/schema.md
CREATE TABLE tag_color (
  id          TEXT    NOT NULL PRIMARY KEY,
  name        TEXT    NOT NULL CHECK (length(trim(name)) > 0),
  fill        TEXT    NOT NULL CHECK (fill      GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  ink         TEXT    NOT NULL CHECK (ink       GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  dark_fill   TEXT    NOT NULL CHECK (dark_fill GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  dark_ink    TEXT    NOT NULL CHECK (dark_ink  GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  position    INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  deleted     INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

CREATE UNIQUE INDEX tag_color_name_live ON tag_color(name COLLATE NOCASE) WHERE deleted = 0;

-- Default tag colors, in hue order, the neutral last. Every ink has 7:1
-- contrast or more on its fill. IDs and modified_at (2026-10-09 00:00 UTC) are
-- fixed so every device starts with identical rows.
INSERT INTO tag_color (id, name, fill, ink, dark_fill, dark_ink, position, modified_at) VALUES
  ('01a11df5-a404-7d38-abd0-3a217e753bf7', 'Rose',     '#fadfe8', '#6c314a', '#3b232c', '#f7b7cf', 0, 1791504000000),
  ('01a11df5-a405-77f8-a657-ba9d7642ee98', 'Peach',    '#f8e0d5', '#7a3312', '#3b241b', '#f6b89c', 1, 1791504000000),
  ('01a11df5-a406-73dc-a362-c8802db18945', 'Butter',   '#f6e9c2', '#5e4600', '#342d16', '#edd68a', 2, 1791504000000),
  ('01a11df5-a407-7a61-b167-1c6b8fbd643b', 'Mint',     '#d9efe2', '#1f5636', '#1c3327', '#a3ddba', 3, 1791504000000),
  ('01a11df5-a408-7b59-a21c-70ec96242c7e', 'Aqua',     '#d0eef1', '#015259', '#0e3135', '#8bdce5', 4, 1791504000000),
  ('01a11df5-a409-77f3-b2da-911f19ae8b47', 'Sky',      '#dce6f7', '#1f3e73', '#1c273d', '#afc8f5', 5, 1791504000000),
  ('01a11df5-a40a-7785-8063-302bd3719072', 'Lavender', '#ece2f9', '#533a6e', '#30263b', '#d8bff7', 6, 1791504000000),
  ('01a11df5-a40b-7345-9636-967a4dd27ec6', 'Oat',      '#ede6dd', '#55452f', '#312a21', '#dac9b3', 7, 1791504000000);

-- Aisles group the shopping list. Each keeps its own copy of the colors it was
-- given. Rules: docs/schema.md
CREATE TABLE aisle (
  id          TEXT    NOT NULL PRIMARY KEY,
  name        TEXT    NOT NULL CHECK (length(trim(name)) > 0),
  fill        TEXT    NOT NULL CHECK (fill      GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  ink         TEXT    NOT NULL CHECK (ink       GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  dark_fill   TEXT    NOT NULL CHECK (dark_fill GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  dark_ink    TEXT    NOT NULL CHECK (dark_ink  GLOB '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'),
  position    INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  deleted     INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

CREATE UNIQUE INDEX aisle_name_live ON aisle(name COLLATE NOCASE) WHERE deleted = 0;

-- Default aisles, with the colors of Mint, Butter, Peach and Sky. IDs and
-- modified_at are fixed like the tag colors'. "Other" is not a row: the UI
-- shows it for items whose aisle is gone.
INSERT INTO aisle (id, name, fill, ink, dark_fill, dark_ink, position, modified_at) VALUES
  ('01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'Produce',      '#d9efe2', '#1f5636', '#1c3327', '#a3ddba', 0, 1791504000000),
  ('01a11df5-a401-727a-ad40-bac8b3bb1336', 'Dairy & eggs', '#f6e9c2', '#5e4600', '#342d16', '#edd68a', 1, 1791504000000),
  ('01a11df5-a402-7845-b69e-c790451ea4bb', 'Meat & fish',  '#f8e0d5', '#7a3312', '#3b241b', '#f6b89c', 2, 1791504000000),
  ('01a11df5-a403-79a8-8557-af5e0069fefa', 'Pantry',       '#dce6f7', '#1f3e73', '#1c273d', '#afc8f5', 3, 1791504000000);

-- Ingredients: the dictionary recipes link to, and the shopping catalog (the
-- rows in_catalog). canonical_name is computed by core::canonicalName().
-- Rules: docs/schema.md
CREATE TABLE ingredient (
  id               TEXT    NOT NULL PRIMARY KEY,
  display_name     TEXT    NOT NULL CHECK (length(trim(display_name)) > 0),
  canonical_name   TEXT    NOT NULL CHECK (length(canonical_name) > 0),
  aisle_id         TEXT    REFERENCES aisle(id),
  icon             TEXT    CHECK (length(icon) > 0),
  one_tap_quantity REAL    CHECK (one_tap_quantity > 0),
  one_tap_unit     TEXT    CHECK (one_tap_unit IN ('pcs', 'g', 'kg', 'ml', 'cl', 'l', 'pack', 'bunch',
                                                    'oz', 'lb', 'fl_oz', 'tsp', 'tbsp', 'cup',
                                                    'clove', 'pinch', 'can')),
  in_catalog       INTEGER NOT NULL DEFAULT 0 CHECK (in_catalog IN (0,1)),
  modified_at      INTEGER NOT NULL,
  deleted          INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1)),
  -- An amount has both parts or neither
  CHECK ((one_tap_quantity IS NULL) = (one_tap_unit IS NULL)),
  -- A catalog item has an aisle and a one-tap amount
  CHECK (in_catalog = 0 OR (aisle_id IS NOT NULL AND one_tap_quantity IS NOT NULL))
) STRICT;

CREATE UNIQUE INDEX ingredient_canonical_name_live ON ingredient(canonical_name) WHERE deleted = 0;

-- The default catalog, over the default aisles. IDs and modified_at are fixed
-- like the aisles'.
INSERT INTO ingredient (id, display_name, canonical_name, aisle_id, icon, one_tap_quantity, one_tap_unit, in_catalog, modified_at) VALUES
  -- Produce
  ('01a11df5-a40c-713e-b0e1-0a3fcc878b23', 'Apples',          'apples',          '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'apple',     1,   'kg',    1, 1791504000000),
  ('01a11df5-a40d-7233-9ed5-e1a057e5d6bd', 'Bananas',         'bananas',         '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'banana',    6,   'pcs',   1, 1791504000000),
  ('01a11df5-a40e-77dd-b716-0a0491af245c', 'Carrots',         'carrots',         '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'carrot',    1,   'kg',    1, 1791504000000),
  ('01a11df5-a40f-7e92-a52d-6c8e25bc5dbc', 'Potatoes',        'potatoes',        '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'potato',    2,   'kg',    1, 1791504000000),
  ('01a11df5-a410-708c-a129-5e50f23b7952', 'Tomatoes',        'tomatoes',        '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'tomato',    500, 'g',     1, 1791504000000),
  ('01a11df5-a411-7403-9bdb-d7b0f4e60457', 'Onions',          'onions',          '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'bulb',      1,   'kg',    1, 1791504000000),
  ('01a11df5-a412-7d4f-89c6-61fcbf4d0b9e', 'Garlic',          'garlic',          '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'bulb',      1,   'pcs',   1, 1791504000000),
  ('01a11df5-a413-7082-9297-4fad1bfdfdbb', 'Shallots',        'shallots',        '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'bulb',      250, 'g',     1, 1791504000000),
  ('01a11df5-a414-7d78-91a0-d0008786cbae', 'Lemons',          'lemons',          '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'lemon',     3,   'pcs',   1, 1791504000000),
  ('01a11df5-a415-74f1-87ec-13cad8736809', 'Mushrooms',       'mushrooms',       '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'mushroom',  250, 'g',     1, 1791504000000),
  ('01a11df5-a416-7482-b42a-cf235b60fd82', 'Bell peppers',    'bell peppers',    '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'pepper',    3,   'pcs',   1, 1791504000000),
  ('01a11df5-a417-71d6-8c9f-4343eccc36f2', 'Lettuce',         'lettuce',         '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'leaf',      1,   'pcs',   1, 1791504000000),
  ('01a11df5-a418-7bac-9b6c-94ce1604d038', 'Spinach',         'spinach',         '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'leaf',      500, 'g',     1, 1791504000000),
  ('01a11df5-a419-7a93-bc24-0b063940c699', 'Parsley',         'parsley',         '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'leaf',      1,   'bunch', 1, 1791504000000),
  ('01a11df5-a41a-7e4a-b64c-93062ed95fbc', 'Basil',           'basil',           '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'leaf',      1,   'bunch', 1, 1791504000000),
  -- Dairy & eggs
  ('01a11df5-a41b-7b09-b57c-b4c64287c125', 'Milk',            'milk',            '01a11df5-a401-727a-ad40-bac8b3bb1336', 'milk',      1,   'l',     1, 1791504000000),
  ('01a11df5-a41c-74dc-9b17-01bbdf99f316', 'Eggs',            'eggs',            '01a11df5-a401-727a-ad40-bac8b3bb1336', 'egg',       6,   'pcs',   1, 1791504000000),
  ('01a11df5-a41d-74af-9bf4-eda855f6480b', 'Butter',          'butter',          '01a11df5-a401-727a-ad40-bac8b3bb1336', 'butter',    250, 'g',     1, 1791504000000),
  ('01a11df5-a41e-70e9-8977-fda63830c3ee', 'Crème fraîche',   'creme fraiche',   '01a11df5-a401-727a-ad40-bac8b3bb1336', 'cup',       20,  'cl',    1, 1791504000000),
  ('01a11df5-a41f-797f-bf52-a7c85009f6ae', 'Plain yogurt',    'plain yogurt',    '01a11df5-a401-727a-ad40-bac8b3bb1336', 'cup',       1,   'pack',  1, 1791504000000),
  ('01a11df5-a420-72fa-9582-85183e0ab9ac', 'Grated cheese',   'grated cheese',   '01a11df5-a401-727a-ad40-bac8b3bb1336', 'cheese',    200, 'g',     1, 1791504000000),
  ('01a11df5-a421-7bb3-8118-c298ecb76631', 'Parmesan',        'parmesan',        '01a11df5-a401-727a-ad40-bac8b3bb1336', 'cheese',    150, 'g',     1, 1791504000000),
  -- Meat & fish
  ('01a11df5-a422-706a-acc2-cc98891aec51', 'Chicken breasts', 'chicken breasts', '01a11df5-a402-7845-b69e-c790451ea4bb', 'drumstick', 500, 'g',     1, 1791504000000),
  ('01a11df5-a423-7923-8740-ff07f22ac63a', 'Ground beef',     'ground beef',     '01a11df5-a402-7845-b69e-c790451ea4bb', 'drumstick', 500, 'g',     1, 1791504000000),
  ('01a11df5-a424-756a-8f62-b76e7030ccef', 'Bacon',           'bacon',           '01a11df5-a402-7845-b69e-c790451ea4bb', 'drumstick', 1,   'pack',  1, 1791504000000),
  ('01a11df5-a425-7a85-9966-54bb6d2b0205', 'Salmon fillets',  'salmon fillets',  '01a11df5-a402-7845-b69e-c790451ea4bb', 'fish',      2,   'pcs',   1, 1791504000000),
  ('01a11df5-a426-7128-8d5e-c3a73c5d25d6', 'Shrimp',          'shrimp',          '01a11df5-a402-7845-b69e-c790451ea4bb', 'fish',      250, 'g',     1, 1791504000000),
  -- Pantry
  ('01a11df5-a427-7f49-9e26-ba2b0bb1ba28', 'Pasta',           'pasta',           '01a11df5-a403-79a8-8557-af5e0069fefa', 'sack',      500, 'g',     1, 1791504000000),
  ('01a11df5-a428-7d5f-b383-f7ae00f8c0d4', 'Rice',            'rice',            '01a11df5-a403-79a8-8557-af5e0069fefa', 'sack',      1,   'kg',    1, 1791504000000),
  ('01a11df5-a429-715f-89c3-a738c630e331', 'Flour',           'flour',           '01a11df5-a403-79a8-8557-af5e0069fefa', 'sack',      1,   'kg',    1, 1791504000000),
  ('01a11df5-a42a-7058-b768-967b671efd42', 'Olive oil',       'olive oil',       '01a11df5-a403-79a8-8557-af5e0069fefa', 'bottle',    500, 'ml',    1, 1791504000000),
  ('01a11df5-a42b-73bc-bc3c-743c75a0e43e', 'Canned tomatoes', 'canned tomatoes', '01a11df5-a403-79a8-8557-af5e0069fefa', 'can',       2,   'pcs',   1, 1791504000000),
  ('01a11df5-a42c-71fb-8b41-05e533530578', 'Bread',           'bread',           '01a11df5-a403-79a8-8557-af5e0069fefa', 'bread',     1,   'pcs',   1, 1791504000000),
  ('01a11df5-a42d-7237-b9a3-cb5fb5ec0fc9', 'Black pepper',    'black pepper',    '01a11df5-a403-79a8-8557-af5e0069fefa', 'spice',     1,   'pcs',   1, 1791504000000);

-- Tags label recipes. A tag's color is one of the theme's four tag families,
-- by key: the theme gives its fill and ink. canonical_name is computed by
-- core::canonicalName(). Rules: docs/schema.md
CREATE TABLE tag (
  id             TEXT    NOT NULL PRIMARY KEY,
  name           TEXT    NOT NULL CHECK (length(trim(name)) > 0),
  canonical_name TEXT    NOT NULL CHECK (length(canonical_name) > 0),
  color          TEXT    NOT NULL CHECK (color IN ('mint', 'butter', 'sky', 'peach')),
  modified_at    INTEGER NOT NULL,
  deleted        INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

CREATE UNIQUE INDEX tag_canonical_name_live ON tag(canonical_name) WHERE deleted = 0;

-- Recipes. Optional fields are NULL when empty, never blank. Deleting a
-- recipe flags only this row: its child rows below stay as they were, for
-- Undo. Rules: docs/schema.md
CREATE TABLE recipe (
  id                    TEXT    NOT NULL PRIMARY KEY,
  title                 TEXT    NOT NULL CHECK (length(trim(title)) > 0),
  description           TEXT    CHECK (length(trim(description)) > 0),
  -- The SHA-256 of the photo's file, which is named after it
  photo_id              TEXT    CHECK (length(photo_id) = 64 AND photo_id NOT GLOB '*[^0-9a-f]*'),
  base_servings         INTEGER NOT NULL DEFAULT 4 CHECK (base_servings >= 1),
  prep_minutes          INTEGER CHECK (prep_minutes >= 0),
  cook_minutes          INTEGER CHECK (cook_minutes >= 0),
  -- For the whole recipe
  cost_cents            INTEGER CHECK (cost_cents >= 0),
  source                TEXT    CHECK (length(trim(source)) > 0),
  notes                 TEXT    CHECK (length(trim(notes)) > 0),
  favorite              INTEGER NOT NULL DEFAULT 0 CHECK (favorite IN (0,1)),
  cook_count            INTEGER NOT NULL DEFAULT 0 CHECK (cook_count >= 0),
  -- A local date, YYYY-MM-DD: date() gives it back unchanged only if valid
  last_cooked           TEXT    CHECK (date(last_cooked) IS last_cooked),
  last_planned_servings INTEGER CHECK (last_planned_servings >= 1),
  created_at            INTEGER NOT NULL,
  modified_at           INTEGER NOT NULL,
  deleted               INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

-- A recipe's ingredients, and their substitutes. Rules: docs/schema.md
CREATE TABLE recipe_ingredient (
  id            TEXT    NOT NULL PRIMARY KEY,
  recipe_id     TEXT    NOT NULL REFERENCES recipe(id),
  -- On a substitute: the main ingredient it can replace
  parent_id     TEXT    REFERENCES recipe_ingredient(id),
  -- Among siblings: main ingredients among themselves, a main ingredient's
  -- substitutes among themselves
  position      INTEGER NOT NULL CHECK (position >= 0),
  -- NULL: to taste
  quantity      REAL    CHECK (quantity > 0),
  unit          TEXT    CHECK (unit IN ('pcs', 'g', 'kg', 'ml', 'cl', 'l', 'pack', 'bunch',
                                        'oz', 'lb', 'fl_oz', 'tsp', 'tbsp', 'cup',
                                        'clove', 'pinch', 'can')),
  -- A free-text unit, as typed: "handfuls"
  unit_text     TEXT    CHECK (length(trim(unit_text)) > 0),
  name          TEXT    NOT NULL CHECK (length(trim(name)) > 0),
  -- The dictionary ingredient with the same canonical name
  ingredient_id TEXT    NOT NULL REFERENCES ingredient(id),
  note          TEXT    CHECK (length(trim(note)) > 0),
  optional      INTEGER NOT NULL DEFAULT 0 CHECK (optional IN (0,1)),
  modified_at   INTEGER NOT NULL,
  deleted       INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1)),
  -- One unit at most
  CHECK (unit IS NULL OR unit_text IS NULL),
  -- A quantity has a unit; without one, only free text can stay ("a handful")
  CHECK (CASE WHEN quantity IS NULL THEN unit IS NULL
              ELSE unit IS NOT NULL OR unit_text IS NOT NULL END)
) STRICT;

-- A recipe's steps. Rules: docs/schema.md
CREATE TABLE step (
  id          TEXT    NOT NULL PRIMARY KEY,
  recipe_id   TEXT    NOT NULL REFERENCES recipe(id),
  position    INTEGER NOT NULL CHECK (position >= 0),
  text        TEXT    NOT NULL CHECK (length(trim(text)) > 0),
  modified_at INTEGER NOT NULL,
  deleted     INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

-- Words of a step's text that name one of the recipe's main ingredients.
-- Rules: docs/schema.md
CREATE TABLE step_mention (
  id                   TEXT    NOT NULL PRIMARY KEY,
  step_id              TEXT    NOT NULL REFERENCES step(id),
  recipe_ingredient_id TEXT    NOT NULL REFERENCES recipe_ingredient(id),
  -- In Unicode code points
  start                INTEGER NOT NULL CHECK (start >= 0),
  length               INTEGER NOT NULL CHECK (length > 0),
  -- What the step uses, in the ingredient's unit. NULL: all of it.
  quantity             REAL    CHECK (quantity > 0),
  modified_at          INTEGER NOT NULL,
  deleted              INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

-- The tags a recipe carries. Rules: docs/schema.md
CREATE TABLE recipe_tag (
  id          TEXT    NOT NULL PRIMARY KEY,
  recipe_id   TEXT    NOT NULL REFERENCES recipe(id),
  tag_id      TEXT    NOT NULL REFERENCES tag(id),
  modified_at INTEGER NOT NULL,
  deleted     INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

CREATE UNIQUE INDEX recipe_tag_live ON recipe_tag(recipe_id, tag_id) WHERE deleted = 0;

-- The app's settings, by key, e.g. theme = 'dark'. Values are language-neutral
-- codes, never translated text. Unlike the other tables, no id and no deleted
-- flag: a key is set once and then only changes. Rules: docs/schema.md
CREATE TABLE setting (
  key         TEXT    NOT NULL PRIMARY KEY CHECK (length(key) > 0),
  value       TEXT    NOT NULL,
  modified_at INTEGER NOT NULL
) STRICT;
