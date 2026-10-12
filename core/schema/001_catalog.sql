-- Aisles group the shopping list. Rules: docs/schema.md.
CREATE TABLE aisle (
  id          TEXT    NOT NULL PRIMARY KEY,
  name        TEXT    NOT NULL CHECK (length(trim(name)) > 0),
  color       TEXT    NOT NULL CHECK (color IN ('mint','butter','sky','peach')),
  position    INTEGER NOT NULL,
  modified_at INTEGER NOT NULL,
  deleted     INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))
) STRICT;

CREATE UNIQUE INDEX aisle_name_live ON aisle(name COLLATE NOCASE) WHERE deleted = 0;

-- Default aisles. IDs and modified_at (2026-10-09 00:00 UTC) are fixed so every
-- device starts with identical rows. "Other" is not a row: the UI shows it for
-- items whose aisle is gone.
INSERT INTO aisle (id, name, color, position, modified_at) VALUES
  ('01a11df5-a400-7c7d-9ae7-fc4361b1e2a5', 'Produce',      'mint',   0, 1791504000000),
  ('01a11df5-a401-727a-ad40-bac8b3bb1336', 'Dairy & eggs', 'butter', 1, 1791504000000),
  ('01a11df5-a402-7845-b69e-c790451ea4bb', 'Meat & fish',  'peach',  2, 1791504000000),
  ('01a11df5-a403-79a8-8557-af5e0069fefa', 'Pantry',       'sky',    3, 1791504000000);
