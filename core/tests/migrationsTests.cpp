#include "core/migrations.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

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
