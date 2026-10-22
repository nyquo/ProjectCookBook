#include "core/Backend.hpp"
#include "core/migrations.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>

using namespace std::chrono_literals;

TEST_CASE("A database file keeps its data when reopened")
{
  const test::TempDatabasePath file;
  test::FakeClock clock;
  std::vector<core::Aisle> saved;
  {
    core::Backend backend(file.path(), clock.function());
    CHECK(backend.tagColors().tagColors().size() == 8);
    core::AisleStore& aisles = backend.aisles();
    CHECK(test::names(aisles) == test::seedNames);

    REQUIRE(aisles.create("Bakery", test::someColors));
    clock.now += 1min;
    aisles.move(4, 0);
    aisles.remove(aisles.aisles()[2].id);
    saved = aisles.aisles();
  }

  // Re-running the first migration would throw: the table already exists
  core::Backend reopened(file.path(), clock.function());
  CHECK(reopened.aisles().aisles() == saved);

  core::Database db(file.path());
  CHECK(core::schemaVersion(db) == core::latestSchemaVersion());
}
