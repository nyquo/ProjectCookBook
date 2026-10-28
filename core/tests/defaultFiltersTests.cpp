#include "core/SettingStore.hpp"
#include "core/TagStore.hpp"
#include "core/defaultFilters.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>

#include <stdexcept>

namespace {

using Ids = std::vector<std::string>;

struct Fixture
{
  test::FakeClock clock;
  core::Database db{ ":memory:" };
  core::SettingStore settings{ test::migrated(db), clock.function() };
  core::TagStore tags{ db, clock.function() };

  std::string create(std::string_view name)
  {
    const auto id = tags.create(name);
    REQUIRE(id);
    return *id;
  }

  Ids selected() const { return core::defaultTagIds(settings, tags); }

  void select(std::string_view id, bool on = true)
  {
    core::setDefaultTagSelected(settings, tags, id, on);
  }

  std::string stored() const
  {
    return settings.value("default_tag_ids").value_or("(none)");
  }
};

}

TEST_CASE_FIXTURE(Fixture, "The recipes list opens unfiltered by default")
{
  CHECK_FALSE(core::defaultFavoritesOnly(settings));
  CHECK(selected().empty());
}

TEST_CASE_FIXTURE(Fixture, "Favorites only is stored as a flag")
{
  core::setDefaultFavoritesOnly(settings, true);
  CHECK(core::defaultFavoritesOnly(settings));
  CHECK(settings.value("default_favorites_only") == "true");

  core::setDefaultFavoritesOnly(settings, false);
  CHECK(settings.value("default_favorites_only") == "false");
}

TEST_CASE_FIXTURE(Fixture,
                  "Selected tags are stored as comma-separated ids, in order")
{
  const std::string a = create("Brunch");
  const std::string b = create("Weeknight");

  select(b);
  select(a);
  select(a); // already selected: no change

  CHECK(selected() == Ids{ b, a });
  CHECK(stored() == b + "," + a);

  select(b, false);
  CHECK(selected() == Ids{ a });
  CHECK(stored() == a);

  select(a, false);
  CHECK(selected().empty());
  CHECK(stored().empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "A deleted tag is ignored but kept, so Undo brings it back")
{
  const std::string a = create("Brunch");
  const std::string b = create("Weeknight");
  const std::string c = create("Vegetarian");
  select(a);
  select(b);

  tags.remove(a);
  CHECK(selected() == Ids{ b });

  // Changing the other tags keeps the deleted one's id
  select(c);
  select(b, false);
  CHECK(selected() == Ids{ c });
  CHECK(stored() == a + "," + c);

  REQUIRE(tags.restore(a));
  CHECK(selected() == Ids{ a, c });
}

TEST_CASE_FIXTURE(Fixture, "Only live tags can be selected")
{
  const std::string a = create("Brunch");
  tags.remove(a);

  CHECK_THROWS_AS(select("unknown"), std::invalid_argument);
  CHECK_THROWS_AS(select(a), std::invalid_argument);
  CHECK_THROWS_AS(select(a, false), std::invalid_argument);
  CHECK(stored() == "(none)");
}

TEST_CASE_FIXTURE(Fixture, "Stray stored values are cleaned up when read")
{
  const std::string a = create("Brunch");
  settings.setValue("default_tag_ids", ",unknown,," + a + "," + a + ",");

  CHECK(selected() == Ids{ a });

  select(a, false);
  CHECK(stored() == "unknown");
}
