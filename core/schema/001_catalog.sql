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
