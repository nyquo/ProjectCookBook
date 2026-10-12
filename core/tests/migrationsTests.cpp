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
  const auto rows = test::aisleRows(db);

  core::migrate(db);
  CHECK(core::schemaVersion(db) == core::latestSchemaVersion());
  CHECK(test::aisleRows(db) == rows);
}

TEST_CASE("The first migration seeds the default aisles")
{
  core::Database db(":memory:");
  core::migrate(db);

  const std::int64_t time = core::toMillis(test::seedTime);
  const std::vector<test::AisleRow> expected{
    { "01a11df5-a400-7c7d-9ae7-fc4361b1e2a5",
      "Produce",
      "mint",
      0,
      time,
      false },
    { "01a11df5-a401-727a-ad40-bac8b3bb1336",
      "Dairy & eggs",
      "butter",
      1,
      time,
      false },
    { "01a11df5-a402-7845-b69e-c790451ea4bb",
      "Meat & fish",
      "peach",
      2,
      time,
      false },
    { "01a11df5-a403-79a8-8557-af5e0069fefa", "Pantry", "sky", 3, time, false },
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

TEST_CASE("The aisle table itself rejects invalid rows")
{
  core::Database db(":memory:");
  core::migrate(db);
  auto insert = [&](std::string_view id,
                    std::string_view name,
                    std::string_view color,
                    int deleted) {
    return test::errorCode([&] {
      db.prepare(
          "INSERT INTO aisle (id, name, color, position, modified_at, deleted) "
          "VALUES (?1, ?2, ?3, 9, 0, ?4)")
        .bind(1, id)
        .bind(2, name)
        .bind(3, color)
        .bind(4, deleted)
        .run();
    });
  };

  CHECK(insert("a", "  ", "mint", 0) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert("b", "Bakery", "red", 0) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert("c", "Bakery", "mint", 2) == SQLITE_CONSTRAINT_CHECK);
  CHECK(insert("d", "PRODUCE", "mint", 0) == SQLITE_CONSTRAINT_UNIQUE);
  CHECK(insert("e", "Produce", "mint", 1) ==
        SQLITE_OK); // deleted rows don't count
  CHECK(insert("f", "Bakery", "mint", 0) == SQLITE_OK);
}
