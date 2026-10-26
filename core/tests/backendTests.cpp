#include "core/Backend.hpp"
#include "core/appearance.hpp"
#include "core/migrations.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>

using namespace std::chrono_literals;

TEST_CASE("A database file keeps its data when reopened")
{
  const test::TempDatabasePath file;
  test::FakeClock clock;
  std::vector<core::Aisle> savedAisles;
  std::vector<core::Ingredient> savedIngredients;
  std::vector<core::Tag> savedTags;
  {
    core::Backend backend(file.path(), clock.function());
    CHECK(backend.tagColors().tagColors().size() == 8);
    core::AisleStore& aisles = backend.aisles();
    CHECK(test::names(aisles) == test::seedNames);
    CHECK(backend.ingredients().ingredients().size() == 34);
    CHECK(backend.tags().tags().empty());

    REQUIRE(aisles.create("Bakery", test::someColors));
    REQUIRE(aisles.create("Frozen", test::otherColors));
    clock.now += 1min;
    aisles.move(4, 0);
    REQUIRE(aisles.remove(aisles.aisles()[5].id));
    REQUIRE(backend.ingredients().addToCatalog({ "Baguette",
                                                 aisles.aisles()[0].id,
                                                 "bread",
                                                 { 2, core::Unit::Pieces } }));
    const auto brunch = backend.tags().create("Brunch");
    REQUIRE(brunch);
    REQUIRE(backend.tags().create("Weeknight"));
    backend.tags().setColor(*brunch, core::TagFamily::Peach);
    core::setThemeMode(backend.settings(), core::ThemeMode::Dark);
    savedAisles = aisles.aisles();
    savedIngredients = backend.ingredients().ingredients();
    savedTags = backend.tags().tags();
  }

  // Re-running the first migration would throw: the table already exists
  core::Backend reopened(file.path(), clock.function());
  CHECK(reopened.aisles().aisles() == savedAisles);
  CHECK(reopened.ingredients().ingredients() == savedIngredients);
  CHECK(reopened.tags().tags() == savedTags);
  CHECK(core::themeMode(reopened.settings()) == core::ThemeMode::Dark);

  core::Database db(file.path());
  CHECK(core::schemaVersion(db) == core::latestSchemaVersion());
}
