#include "core/AisleStore.hpp"
#include "core/IngredientStore.hpp"
#include "core/migrations.hpp"
#include "core/text.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

#include <map>
#include <optional>
#include <set>

TEST_CASE("Migrating a new database applies every migration")
{
  core::Database db(":memory:");
  CHECK(core::schemaVersion(db) == 0);

  core::migrate(db);
  CHECK(core::schemaVersion(db) == core::latestSchemaVersion());
  CHECK(core::latestSchemaVersion() == 1);
}

TEST_CASE("Migrating an up-to-date database changes nothing")
{
  core::Database db(":memory:");
  core::migrate(db);
  const auto aisles = test::aisleRows(db);
  const auto tagColors = test::tagColorRows(db);

  core::migrate(db);
  CHECK(core::schemaVersion(db) == core::latestSchemaVersion());
  CHECK(test::aisleRows(db) == aisles);
  CHECK(test::tagColorRows(db) == tagColors);
}

TEST_CASE("The first migration seeds the default tag colors")
{
  core::Database db(":memory:");
  core::migrate(db);

  const std::int64_t time = core::toMillis(test::seedTime);
  const std::vector<test::Row> expected{
    { "01a11df5-a404-7d38-abd0-3a217e753bf7",
      "Rose",
      { "#fadfe8", "#6c314a", "#3b232c", "#f7b7cf" },
      0,
      time,
      false },
    { "01a11df5-a405-77f8-a657-ba9d7642ee98",
      "Peach",
      { "#f8e0d5", "#7a3312", "#3b241b", "#f6b89c" },
      1,
      time,
      false },
    { "01a11df5-a406-73dc-a362-c8802db18945",
      "Butter",
      { "#f6e9c2", "#5e4600", "#342d16", "#edd68a" },
      2,
      time,
      false },
    { "01a11df5-a407-7a61-b167-1c6b8fbd643b",
      "Mint",
      { "#d9efe2", "#1f5636", "#1c3327", "#a3ddba" },
      3,
      time,
      false },
    { "01a11df5-a408-7b59-a21c-70ec96242c7e",
      "Aqua",
      { "#d0eef1", "#015259", "#0e3135", "#8bdce5" },
      4,
      time,
      false },
    { "01a11df5-a409-77f3-b2da-911f19ae8b47",
      "Sky",
      { "#dce6f7", "#1f3e73", "#1c273d", "#afc8f5" },
      5,
      time,
      false },
    { "01a11df5-a40a-7785-8063-302bd3719072",
      "Lavender",
      { "#ece2f9", "#533a6e", "#30263b", "#d8bff7" },
      6,
      time,
      false },
    { "01a11df5-a40b-7345-9636-967a4dd27ec6",
      "Oat",
      { "#ede6dd", "#55452f", "#312a21", "#dac9b3" },
      7,
      time,
      false },
  };
  CHECK(test::tagColorRows(db) == expected);
}

TEST_CASE("The first migration seeds the default aisles")
{
  core::Database db(":memory:");
  core::migrate(db);

  // Mint, Butter, Peach and Sky
  const std::int64_t time = core::toMillis(test::seedTime);
  const std::vector<test::Row> expected{
    { "01a11df5-a400-7c7d-9ae7-fc4361b1e2a5",
      "Produce",
      { "#d9efe2", "#1f5636", "#1c3327", "#a3ddba" },
      0,
      time,
      false },
    { "01a11df5-a401-727a-ad40-bac8b3bb1336",
      "Dairy & eggs",
      { "#f6e9c2", "#5e4600", "#342d16", "#edd68a" },
      1,
      time,
      false },
    { "01a11df5-a402-7845-b69e-c790451ea4bb",
      "Meat & fish",
      { "#f8e0d5", "#7a3312", "#3b241b", "#f6b89c" },
      2,
      time,
      false },
    { "01a11df5-a403-79a8-8557-af5e0069fefa",
      "Pantry",
      { "#dce6f7", "#1f3e73", "#1c273d", "#afc8f5" },
      3,
      time,
      false },
  };
  CHECK(test::aisleRows(db) == expected);
}

TEST_CASE("A database newer than the app is refused")
{
  core::Database db(":memory:");
  db.exec("PRAGMA user_version = 99");
  CHECK_THROWS_AS(core::migrate(db), core::DatabaseError);
  CHECK(core::schemaVersion(db) == 99);
}

// One table at a time: the SQL is constant, never built from the table name
static void checkRejectsInvalidRows(auto&& insert)
{
  const test::ColorTexts valid{ "#012345", "#6789ab", "#cdef00", "#ff100a" };
  const auto withColor = [&](int column, std::string text) {
    test::ColorTexts colors = valid;
    std::string* const texts[] = {
      &colors.fill, &colors.ink, &colors.darkFill, &colors.darkInk
    };
    *texts[column] = std::move(text);
    return colors;
  };

  CHECK(insert("a", "  ", valid, 0) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert("b", "Bakery", valid, 2) == SQLITE_CONSTRAINT_CHECK);
  for (int column = 0; column < 4; ++column) {
    CAPTURE(column);
    for (const char* text :
         { "red", "", "#D9EFE2", "#d9efe", "#d9efe22", "d9efe22", "#d9efeg" }) {
      CAPTURE(text);
      CHECK(insert("c", "Bakery", withColor(column, text), 0) ==
            SQLITE_CONSTRAINT_CHECK);
    }
  }
  CHECK(insert("d", "Bakery", valid, 0) == SQLITE_OK);
  CHECK(insert("e", "BAKERY", valid, 0) == SQLITE_CONSTRAINT_UNIQUE);
  CHECK(insert("f", "Bakery", valid, 1) ==
        SQLITE_OK); // deleted rows don't count
}

TEST_CASE("The aisle table itself rejects invalid rows")
{
  core::Database db(":memory:");
  core::migrate(db);
  checkRejectsInvalidRows([&](std::string_view id,
                              std::string_view name,
                              const test::ColorTexts& colors,
                              int deleted) {
    return test::errorCode([&] {
      db.prepare("INSERT INTO aisle (id, name, fill, ink, dark_fill, dark_ink, "
                 "position, modified_at, deleted) "
                 "VALUES (?1, ?2, ?3, ?4, ?5, ?6, 9, 0, ?7)")
        .bind(1, id)
        .bind(2, name)
        .bind(3, colors.fill)
        .bind(4, colors.ink)
        .bind(5, colors.darkFill)
        .bind(6, colors.darkInk)
        .bind(7, deleted)
        .run();
    });
  });
}

TEST_CASE("The tag_color table itself rejects invalid rows")
{
  core::Database db(":memory:");
  core::migrate(db);
  checkRejectsInvalidRows([&](std::string_view id,
                              std::string_view name,
                              const test::ColorTexts& colors,
                              int deleted) {
    return test::errorCode([&] {
      db.prepare("INSERT INTO tag_color (id, name, fill, ink, dark_fill, "
                 "dark_ink, position, modified_at, deleted) "
                 "VALUES (?1, ?2, ?3, ?4, ?5, ?6, 9, 0, ?7)")
        .bind(1, id)
        .bind(2, name)
        .bind(3, colors.fill)
        .bind(4, colors.ink)
        .bind(5, colors.darkFill)
        .bind(6, colors.darkInk)
        .bind(7, deleted)
        .run();
    });
  });
}

TEST_CASE("The first migration seeds the default catalog")
{
  core::Database db(":memory:");
  const core::AisleStore aisles(test::migrated(db), core::systemNow);
  const core::IngredientStore store(db, core::systemNow, aisles);
  const auto& items = store.ingredients();

  REQUIRE(items.size() == 34);
  CHECK(items[0] == core::Ingredient{ "01a11df5-a40c-713e-b0e1-0a3fcc878b23",
                                      "Apples",
                                      "apples",
                                      aisles.aisles()[0].id,
                                      "apple",
                                      core::Amount{ 1, core::Unit::Kilograms },
                                      true,
                                      test::seedTime });

  std::map<std::string, int> perAisle;
  std::set<std::string> ids;
  for (const core::Ingredient& item : items) {
    CAPTURE(item.name);
    CHECK(item.inCatalog);
    CHECK(item.canonicalName == core::canonicalName(item.name));
    CHECK(item.icon.has_value());
    CHECK(item.oneTap.has_value());
    CHECK(item.modifiedAt == test::seedTime);
    REQUIRE(item.aisleId.has_value());
    ++perAisle[*item.aisleId];
    ids.insert(item.id);
  }
  CHECK(ids.size() == items.size());
  // Produce, Dairy & eggs, Meat & fish, Pantry
  CHECK(perAisle == std::map<std::string, int>{ { aisles.aisles()[0].id, 15 },
                                                { aisles.aisles()[1].id, 7 },
                                                { aisles.aisles()[2].id, 5 },
                                                { aisles.aisles()[3].id, 7 } });
}

TEST_CASE("The first migration creates no settings")
{
  core::Database db(":memory:");
  core::migrate(db);
  core::Statement count = db.prepare("SELECT count(*) FROM setting");
  REQUIRE(count.step());
  CHECK(count.columnInt64(0) == 0);
}

namespace {

// A valid catalog row; tests break one column at a time
struct IngredientRow
{
  std::string id = "i";
  std::string name = "Leeks";
  std::string canonicalName = "leeks";
  std::optional<std::string> aisleId = "01a11df5-a400-7c7d-9ae7-fc4361b1e2a5";
  std::optional<std::string> icon = "leaf";
  std::optional<double> quantity = 1.5;
  std::optional<std::string> unit = "kg";
  int inCatalog = 1;
  int deleted = 0;
};

int insert(core::Database& db, const IngredientRow& row)
{
  return test::errorCode([&] {
    db.prepare("INSERT INTO ingredient (id, display_name, canonical_name, "
               "aisle_id, icon, one_tap_quantity, one_tap_unit, in_catalog, "
               "modified_at, deleted) "
               "VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 0, ?9)")
      .bind(1, row.id)
      .bind(2, row.name)
      .bind(3, row.canonicalName)
      .bind(4, row.aisleId)
      .bind(5, row.icon)
      .bind(6, row.quantity)
      .bind(7, row.unit)
      .bind(8, row.inCatalog)
      .bind(9, row.deleted)
      .run();
  });
}

}

TEST_CASE("The ingredient table itself rejects invalid rows")
{
  core::Database db(":memory:");
  core::migrate(db);
  const auto with = [](auto change) {
    IngredientRow row;
    change(row);
    return row;
  };

  CHECK(insert(db, with([](auto& r) { r.name = " "; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.canonicalName = ""; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.icon = ""; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.unit = "tbsp"; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.quantity = 0.0; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.quantity = -1.0; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) {
                 r.inCatalog = 0;
                 r.unit.reset();
               })) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) {
                 r.inCatalog = 0;
                 r.quantity.reset();
               })) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.aisleId.reset(); })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) {
                 r.quantity.reset();
                 r.unit.reset();
               })) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.inCatalog = 2; })) ==
        SQLITE_CONSTRAINT_CHECK);
  CHECK(insert(db, with([](auto& r) { r.aisleId = "no-such-aisle"; })) ==
        SQLITE_CONSTRAINT_FOREIGNKEY);

  CHECK(insert(db, IngredientRow{}) == SQLITE_OK);
  CHECK(insert(db, with([](auto& r) { r.id = "j"; })) ==
        SQLITE_CONSTRAINT_UNIQUE);
  // Deleted rows don't count; outside the catalog, nothing else is required
  CHECK(insert(db, with([](auto& r) {
                 r.id = "k";
                 r.deleted = 1;
               })) == SQLITE_OK);
  CHECK(insert(db, with([](auto& r) {
                 r.id = "l";
                 r.canonicalName = "leek";
                 r.inCatalog = 0;
                 r.aisleId.reset();
                 r.icon.reset();
                 r.quantity.reset();
                 r.unit.reset();
               })) == SQLITE_OK);
}

TEST_CASE("The setting table itself rejects invalid rows")
{
  core::Database db(":memory:");
  core::migrate(db);
  const auto insert = [&](std::string_view key) {
    return test::errorCode([&] {
      db.prepare("INSERT INTO setting (key, value, modified_at) "
                 "VALUES (?1, 'x', 0)")
        .bind(1, key)
        .run();
    });
  };

  CHECK(insert("") == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert("theme") == SQLITE_OK);
  CHECK(insert("theme") == SQLITE_CONSTRAINT_PRIMARYKEY);
}
