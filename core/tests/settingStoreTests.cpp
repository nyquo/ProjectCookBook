#include "core/SettingStore.hpp"
#include "core/appearance.hpp"
#include "core/cooking.hpp"
#include "core/recipeFields.hpp"
#include "core/unitSystem.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

using namespace std::chrono_literals;

namespace {

class RecordingObserver final : public core::SettingObserver
{
public:
  explicit RecordingObserver(core::SettingStore& store)
    : m_store(store)
  {
    m_store.addObserver(*this);
  }
  ~RecordingObserver() { m_store.removeObserver(*this); }

  // "before:key=value seen", "after:key=value seen"
  void settingAboutToChange(std::string_view key) noexcept override
  {
    calls.push_back("before:" + describe(key));
  }
  void settingChanged(std::string_view key) noexcept override
  {
    calls.push_back("after:" + describe(key));
  }

  std::vector<std::string> calls;

private:
  std::string describe(std::string_view key) const
  {
    return std::string(key) + "=" + m_store.value(key).value_or("(none)");
  }

  core::SettingStore& m_store;
};

struct Fixture
{
  test::FakeClock clock;
  core::Database db{ ":memory:" };
  core::SettingStore store{ test::migrated(db), clock.function() };
  RecordingObserver observer{ store };

  std::int64_t modifiedAt(std::string_view key)
  {
    core::Statement select =
      db.prepare("SELECT modified_at FROM setting WHERE key = ?1");
    select.bind(1, key);
    REQUIRE(select.step());
    return select.columnInt64(0);
  }
};

}

TEST_CASE_FIXTURE(Fixture, "A key never set has no value")
{
  CHECK_FALSE(store.value("theme").has_value());
}

TEST_CASE_FIXTURE(Fixture, "setValue stores, replaces and notifies")
{
  store.setValue("theme", "dark");
  CHECK(store.value("theme") == "dark");
  CHECK(modifiedAt("theme") == core::toMillis(clock.now));
  CHECK(observer.calls ==
        std::vector<std::string>{ "before:theme=(none)", "after:theme=dark" });

  observer.calls.clear();
  clock.now += 1min;
  store.setValue("theme", "light");
  CHECK(store.value("theme") == "light");
  CHECK(modifiedAt("theme") == core::toMillis(clock.now));
  CHECK(observer.calls ==
        std::vector<std::string>{ "before:theme=dark", "after:theme=light" });

  const core::SettingStore reloaded(db, clock.function());
  CHECK(reloaded.value("theme") == "light");
}

TEST_CASE_FIXTURE(Fixture, "setValue with the same value writes nothing")
{
  store.setValue("theme", "dark");
  const std::int64_t written = modifiedAt("theme");
  observer.calls.clear();
  clock.now += 1min;

  store.setValue("theme", "dark");
  CHECK(modifiedAt("theme") == written);
  CHECK(observer.calls.empty());
}

TEST_CASE_FIXTURE(Fixture, "Programming errors throw before anything changes")
{
  CHECK_THROWS_AS(store.setValue("", "x"), std::invalid_argument);

  struct MeddlingObserver final : core::SettingObserver
  {
    explicit MeddlingObserver(core::SettingStore& store)
      : store(store)
    {
    }
    void settingAboutToChange(std::string_view) noexcept override
    {
      CHECK_THROWS_AS(store.setValue("accent", "basil"), std::logic_error);
    }
    void settingChanged(std::string_view) noexcept override {}

    core::SettingStore& store;
  } meddling(store);
  store.addObserver(meddling);
  store.setValue("theme", "dark");
  store.removeObserver(meddling);

  CHECK_FALSE(store.value("accent").has_value());
}

TEST_CASE_FIXTURE(Fixture,
                  "A failed write changes neither the table nor memory")
{
  db.exec("CREATE TRIGGER fail BEFORE INSERT ON setting "
          "BEGIN SELECT RAISE(ABORT, 'simulated'); END");

  CHECK(test::errorCode([&] { store.setValue("theme", "dark"); }) ==
        SQLITE_CONSTRAINT_TRIGGER);
  CHECK_FALSE(store.value("theme").has_value());
  CHECK(observer.calls.empty());
}

TEST_CASE_FIXTURE(Fixture, "The appearance defaults to System and Raspberry")
{
  CHECK(core::themeMode(store) == core::ThemeMode::System);
  CHECK(core::accent(store) == core::Accent::Raspberry);
}

TEST_CASE_FIXTURE(Fixture, "The appearance is stored as language-neutral codes")
{
  core::setThemeMode(store, core::ThemeMode::Dark);
  core::setAccent(store, core::Accent::Blueberry);

  CHECK(store.value("theme") == "dark");
  CHECK(store.value("accent") == "blueberry");
  CHECK(core::themeMode(store) == core::ThemeMode::Dark);
  CHECK(core::accent(store) == core::Accent::Blueberry);

  for (const auto mode : { core::ThemeMode::System,
                           core::ThemeMode::Light,
                           core::ThemeMode::Dark }) {
    core::setThemeMode(store, mode);
    CHECK(core::themeMode(store) == mode);
  }
  for (const auto accent : { core::Accent::Raspberry,
                             core::Accent::Spirulina,
                             core::Accent::Blueberry,
                             core::Accent::Saffron,
                             core::Accent::Basil }) {
    core::setAccent(store, accent);
    CHECK(core::accent(store) == accent);
  }
}

TEST_CASE_FIXTURE(Fixture,
                  "Unknown appearance values fall back to the defaults")
{
  store.setValue("theme", "sepia");
  store.setValue("accent", "Basil"); // codes are lowercase

  CHECK(core::themeMode(store) == core::ThemeMode::System);
  CHECK(core::accent(store) == core::Accent::Raspberry);
}

TEST_CASE_FIXTURE(Fixture, "A flag is stored as true or false")
{
  CHECK(store.flag("keep_screen_on", true));
  CHECK_FALSE(store.flag("keep_screen_on", false));

  store.setFlag("keep_screen_on", false);
  CHECK(store.value("keep_screen_on") == "false");
  CHECK_FALSE(store.flag("keep_screen_on", true));

  store.setFlag("keep_screen_on", true);
  CHECK(store.value("keep_screen_on") == "true");
  CHECK(store.flag("keep_screen_on", false));
}

TEST_CASE_FIXTURE(Fixture, "A flag with another value takes its fallback")
{
  for (const char* value : { "", "1", "yes", "True" }) {
    CAPTURE(value);
    store.setValue("keep_screen_on", value);
    CHECK(store.flag("keep_screen_on", true));
    CHECK_FALSE(store.flag("keep_screen_on", false));
  }
}

TEST_CASE_FIXTURE(Fixture, "The unit system defaults to metric")
{
  CHECK(core::unitSystem(store) == core::UnitSystem::Metric);

  core::setUnitSystem(store, core::UnitSystem::Us);
  CHECK(store.value("unit_system") == "us");
  CHECK(core::unitSystem(store) == core::UnitSystem::Us);

  core::setUnitSystem(store, core::UnitSystem::Metric);
  CHECK(store.value("unit_system") == "metric");

  store.setValue("unit_system", "imperial");
  CHECK(core::unitSystem(store) == core::UnitSystem::Metric);
}

TEST_CASE("Each unit system offers its own units")
{
  using core::Unit;
  const auto choices = [](core::UnitSystem system) {
    const auto units = core::unitChoices(system);
    return std::vector<Unit>(units.begin(), units.end());
  };

  CHECK(choices(core::UnitSystem::Metric) == std::vector{ Unit::Pieces,
                                                          Unit::Grams,
                                                          Unit::Kilograms,
                                                          Unit::Milliliters,
                                                          Unit::Centiliters,
                                                          Unit::Liters,
                                                          Unit::Packs,
                                                          Unit::Bunches });
  CHECK(choices(core::UnitSystem::Us) == std::vector{ Unit::Pieces,
                                                      Unit::Ounces,
                                                      Unit::Pounds,
                                                      Unit::FluidOunces,
                                                      Unit::Packs,
                                                      Unit::Bunches });
}

TEST_CASE_FIXTURE(Fixture, "Every recipe field is shown by default")
{
  using core::RecipeField;
  const std::vector<std::pair<RecipeField, std::string>> fields{
    { RecipeField::Cost, "show_cost" },
    { RecipeField::Times, "show_times" },
    { RecipeField::StepAmounts, "show_step_amounts" },
    { RecipeField::CookingHistory, "show_cooking_history" },
    { RecipeField::Source, "show_source" },
    { RecipeField::Notes, "show_notes" },
  };
  for (const auto& [field, key] : fields) {
    CAPTURE(key);
    CHECK(core::recipeFieldShown(store, field));

    core::setRecipeFieldShown(store, field, false);
    CHECK(store.value(key) == "false");
    CHECK_FALSE(core::recipeFieldShown(store, field));
  }

  // Each field has its own key
  core::setRecipeFieldShown(store, RecipeField::Notes, true);
  CHECK(core::recipeFieldShown(store, RecipeField::Notes));
  CHECK_FALSE(core::recipeFieldShown(store, RecipeField::Source));
}

TEST_CASE_FIXTURE(Fixture, "Keep screen on is on by default")
{
  CHECK(core::keepScreenOn(store));

  core::setKeepScreenOn(store, false);
  CHECK(store.value("keep_screen_on") == "false");
  CHECK_FALSE(core::keepScreenOn(store));
}
