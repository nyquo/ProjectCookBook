# Project Cookbook

Personal Android recipe app: Qt 6.12 / QML + C++23, CMake. Build, run and device setup: README.md.

## Workflow

- Work in phases and stop after each for review. Never commit: the user commits after reviewing.
- Build and test: `.\scripts\build.ps1 desktop -Test` (MinGW: app + core tests) and `.\scripts\build.ps1 core-msvc -Test` (core only, MSVC, no Qt). Tests are never built for Android. Only core has tests: QML isn't tested. Keep every build warning-free.
- Format every C++ file you touch with `.clang-format` (Mozilla), using the clang-format bundled with VS Code's C/C++ extension: the user formats on save with it.

## Architecture

- `core/`: static library, standard C++23, **no Qt** (no QString, QObject, QtSql, QJson, qrc). CMake fails if it links Qt. Third-party code: permissive licenses only, vendored in `third_party/`.
- `app/`: the Qt/QML layer. Adapts core types to list models and builds every user-facing text (qsTr, QLocale). Qt: LGPL modules only.
- `plating/`: static QML module `Plating`, the app's Qt Quick Controls style and design tokens (themes, metrics, typography, its OFL font). Never links or includes `core`; CMake fails if it links it. QML reads the theme through `readonly property UiTheme theme: Plating.theme as UiTheme`; color values only in `LightTheme.qml`/`DarkTheme.qml`, design px only in `UiMetrics.qml`/`UiTypography.qml`. See `plating/README.md`.
- `core::Backend` owns the `Database` and every store. `main()` creates it before the QML engine and hands it to `app::setBackend()`.
- One **store** per table (e.g. `core::AisleStore`):
  - loads the live rows into memory at startup; reads come from memory;
  - each change is validated, written to SQLite, and applied to memory only after the commit;
  - then observers are notified twice, before and after memory changes (`...AboutToChange`, `...Changed`), with the exact change: inserted, removed or moved index, or updated index + field.
- One **list model** per screen (e.g. `AisleListModel`):
  - `QML_ELEMENT`, created by QML (`AisleListModel {}`); its default constructor gets the store from `app::backend()`;
  - maps notifications to begin/end Insert/Remove/Move rows, and `dataChanged` with only the changed roles; never resets;
  - actions are `Q_INVOKABLE` on the model and return a `Q_ENUM Error` that QML maps to qsTr text.
- Errors:
  - user-correctable validation → `std::expected<T, XxxError>`: codes, never strings;
  - broken database → `core::DatabaseError`; models catch it and return `StorageFailed`;
  - programming errors (unknown id, bad index, a change from inside a notification) → `std::logic_error` subclasses, thrown before anything changes; models catch them (stale input from QML) and return `InvalidRequest`.
- All database work is synchronous on the main thread; the comment on `core::Backend` says what changes if that stops being true.

## Database conventions

- SQLite amalgamation (`third_party/sqlite`; compile options in its README) behind `core/Database.hpp`: `Database`, `Statement`, `Transaction`. Prepared statements with bound parameters only, never SQL built by concatenation (sole exception: `PRAGMA user_version` in the migrator).
- Schema = `core/schema/NNN_name.sql`, numbered without gaps: the single source of truth, embedded at build time. Each file runs once, in its own transaction, tracked by `PRAGMA user_version`; files must not contain BEGIN/COMMIT. Once a migration has run on a device that matters, never edit it: add a new one.
- Every table is `STRICT` and has:
  - `id TEXT NOT NULL PRIMARY KEY`: a UUIDv7 from `core::UuidV7Generator`;
  - `modified_at INTEGER NOT NULL`: ms since Unix epoch, UTC, from the injected `core::Clock`; set on every insert and update, including soft delete, restore, and rows shifted by a reorder;
  - `deleted INTEGER NOT NULL DEFAULT 0 CHECK (deleted IN (0,1))`: soft delete. The app never DELETEs; restore flips it back (that's Undo).
- Uniqueness: partial unique indexes `WHERE deleted = 0`. The store mirrors the check, so the user gets a validation error instead of a constraint exception.
- Booleans: INTEGER 0/1 with CHECK. Enums: TEXT with `CHECK (x IN (...))`, mapped to a C++ enum in core.
- Cascades and "can't delete while in use" rules live in core code, not in ON DELETE.
- `PRAGMA foreign_keys = ON` is set only in `Database`'s constructor. Default rollback journal, no WAL.
- Changing a CHECK or a column type later needs a table-rebuild migration, with foreign keys switched off around it; the migrator doesn't support that yet.
- `.db` files are never committed. `tools/pull-db.sh` copies the device's database into `scratch/`.
- `docs/schema.md` documents every table (Mermaid diagram + rules): update it with each schema change.

## Code style

- clang-format (Mozilla). `.hpp` next to `.cpp`, includes written `"core/AisleStore.hpp"`.
- File names: PascalCase, named after the class or struct the file holds (`AisleStore.hpp`, `Backend.cpp`); camelCase otherwise (`main.cpp`, `migrations.hpp`, `aisleStoreTests.cpp`). QML files are PascalCase, as QML requires.
- `namespace a::b {`, with no closing `// namespace` comment. File-local helpers are `static` functions.
- Comments only for why, contracts, or non-obvious facts; code that reads on its own gets none.
- A comment that fits on one line doesn't end with a period. Comments that span several lines keep theirs.
- The product spec is private and not in the repo: sources, docs and commit messages never cite it (feature ids, section numbers). State the fact itself.
- Every own CMake target calls `cookbook_set_warnings(<target>)`.

## Adding a table

1. `core/schema/NNN_name.sql`, with seed rows if any.
2. A plain struct and a store in `core/`, following `AisleStore`. Tests in `core/tests/`, using `:memory:` databases that run the real migrations.
3. A list model in `app/`, following `AisleListModel`.
4. Update `docs/schema.md`.
