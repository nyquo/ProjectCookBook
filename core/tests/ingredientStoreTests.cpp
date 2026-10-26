#include "core/AisleStore.hpp"
#include "core/IngredientStore.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

#include <algorithm>
#include <limits>
#include <ostream>
#include <stdexcept>

using core::IngredientError;
using core::IngredientField;
using core::Unit;
using namespace std::chrono_literals;

namespace {

struct Notification
{
  bool changed; // false: about to change
  core::IngredientChange change;
  std::size_t sizeSeen;

  bool operator==(const Notification&) const = default;
};

class RecordingObserver final : public core::IngredientObserver
{
public:
  explicit RecordingObserver(core::IngredientStore& store)
    : m_store(store)
  {
    m_store.addObserver(*this);
  }
  ~RecordingObserver() { m_store.removeObserver(*this); }

  void ingredientAboutToChange(
    const core::IngredientChange& change) noexcept override
  {
    notifications.push_back({ false, change, m_store.ingredients().size() });
  }
  void ingredientChanged(const core::IngredientChange& change) noexcept override
  {
    notifications.push_back({ true, change, m_store.ingredients().size() });
  }

  std::vector<Notification> notifications;

private:
  core::IngredientStore& m_store;
};

std::vector<Notification> notificationsFor(core::IngredientChange change,
                                           std::size_t sizeBefore,
                                           std::size_t sizeAfter)
{
  return { { false, change, sizeBefore }, { true, change, sizeAfter } };
}

struct Fixture
{
  test::FakeClock clock;
  core::Database db{ ":memory:" };
  core::AisleStore aisles{ test::migrated(db), clock.function() };
  core::IngredientStore store{ db, clock.function(), aisles };
  RecordingObserver observer{ store };

  std::string aisleId(int index) const { return aisles.aisles()[index].id; }

  // The live ingredient with this name; fails the test without one
  const core::Ingredient& named(std::string_view name) const
  {
    const auto& all = store.ingredients();
    const auto it = std::ranges::find(all, name, &core::Ingredient::name);
    REQUIRE_MESSAGE(it != all.end(), "no ingredient named " << name);
    return *it;
  }

  int indexOf(std::string_view name) const
  {
    const auto& all = store.ingredients();
    return static_cast<int>(&named(name) - all.data());
  }

  bool reloadMatches()
  {
    const core::IngredientStore reloaded(db, core::systemNow, aisles);
    return reloaded.ingredients() == store.ingredients();
  }
};

// `write` must fail, because of a trigger the test installed
void checkFailedWriteChangesNothing(Fixture& f, auto&& write)
{
  const auto before = f.store.ingredients();
  f.observer.notifications.clear();

  CHECK(test::errorCode(write) == SQLITE_CONSTRAINT_TRIGGER);
  CHECK(f.store.ingredients() == before);
  CHECK(f.reloadMatches());
  CHECK(f.observer.notifications.empty());
}

}

TEST_CASE_FIXTURE(Fixture, "Loading reads the live ingredients")
{
  CHECK(store.ingredients().size() == 34);
  const core::Ingredient& cream = named("Crème fraîche");
  CHECK(cream.canonicalName == "creme fraiche");
  CHECK(cream.aisleId == aisleId(1));
  CHECK(cream.oneTap == core::Amount{ 20, Unit::Centiliters });

  db.exec("UPDATE ingredient SET deleted = 1 WHERE display_name = 'Milk'");
  const core::IngredientStore reloaded(db, clock.function(), aisles);
  CHECK(reloaded.ingredients().size() == 33);
}

TEST_CASE_FIXTURE(Fixture, "Loading refuses a unit it doesn't know")
{
  // Only a write that bypassed the CHECK constraints could store one
  db.exec("PRAGMA ignore_check_constraints = ON;"
          "UPDATE ingredient SET one_tap_unit = 'tbsp' "
          "WHERE display_name = 'Milk'");
  CHECK(test::errorCode([&] {
          core::IngredientStore reloaded(db, clock.function(), aisles);
        }) == SQLITE_CORRUPT);
}

TEST_CASE_FIXTURE(Fixture, "addToCatalog appends a trimmed item")
{
  const auto id = store.addToCatalog(
    { "  Leeks\t", aisleId(0), "leaf", { 1.5, Unit::Kilograms } });

  REQUIRE(id);
  CHECK((*id)[14] == '7');
  CHECK(store.ingredients().back() ==
        core::Ingredient{ *id,
                          "Leeks",
                          "leeks",
                          aisleId(0),
                          "leaf",
                          core::Amount{ 1.5, Unit::Kilograms },
                          true,
                          clock.now });
  CHECK(observer.notifications ==
        notificationsFor(core::IngredientInserted{ 34 }, 34, 35));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "addToCatalog takes an item without an icon")
{
  const auto id = store.addToCatalog(
    { "Tofu", aisleId(3), std::nullopt, { 1, Unit::Packs } });

  REQUIRE(id);
  CHECK_FALSE(store.ingredients().back().icon.has_value());
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "Every unit is stored and read back")
{
  const auto id =
    store.addToCatalog({ "Leeks", aisleId(0), "leaf", { 1, Unit::Pieces } });
  REQUIRE(id);
  for (const Unit unit : { Unit::Grams,
                           Unit::Kilograms,
                           Unit::Milliliters,
                           Unit::Centiliters,
                           Unit::Liters,
                           Unit::Packs,
                           Unit::Bunches,
                           Unit::Ounces,
                           Unit::Pounds,
                           Unit::FluidOunces,
                           Unit::Pieces }) {
    CAPTURE(core::unitCode(unit));
    REQUIRE(store.updateCatalogItem(
      *id, { "Leeks", aisleId(0), "leaf", { 1.5, unit } }));
    CHECK(core::unitFromCode(core::unitCode(unit)) == unit);
    REQUIRE(reloadMatches());
  }
}

TEST_CASE_FIXTURE(Fixture, "addToCatalog rejects blank names and catalog items")
{
  const auto before = store.ingredients();
  const auto add = [&](std::string_view name) {
    return store.addToCatalog(
      { name, aisleId(0), "leaf", { 1, Unit::Pieces } });
  };

  CHECK(add("") == std::unexpected(IngredientError::EmptyName));
  CHECK(add(" \t ") == std::unexpected(IngredientError::EmptyName));
  CHECK(add("\xc2\xa0") == std::unexpected(IngredientError::EmptyName)); // NBSP
  CHECK(add("CRÈME FRAICHE") ==
        std::unexpected(IngredientError::DuplicateName));
  CHECK(add(" creme   fraiche ") ==
        std::unexpected(IngredientError::DuplicateName));

  CHECK(store.ingredients() == before);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "addToCatalog reuses a live ingredient outside the catalog")
{
  const core::Ingredient milk = named("Milk");
  const int index = indexOf("Milk");
  store.removeFromCatalog(milk.id);
  observer.notifications.clear();
  clock.now += 1min;

  const auto id = store.addToCatalog(
    { "MILK", aisleId(3), std::nullopt, { 2, Unit::Liters } });

  REQUIRE(id);
  CHECK(*id == milk.id);
  CHECK(store.ingredients().size() == 34);
  CHECK(store.ingredients()[index] ==
        core::Ingredient{ milk.id,
                          "MILK",
                          "milk",
                          aisleId(3),
                          std::nullopt,
                          core::Amount{ 2, Unit::Liters },
                          true,
                          clock.now });
  CHECK(
    observer.notifications ==
    notificationsFor(core::IngredientUpdated{ index,
                                              { IngredientField::Name,
                                                IngredientField::Aisle,
                                                IngredientField::Icon,
                                                IngredientField::OneTap,
                                                IngredientField::InCatalog } },
                     34,
                     34));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "updateCatalogItem changes the fields that differ")
{
  const core::Ingredient eggs = named("Eggs");
  const int index = indexOf("Eggs");

  REQUIRE(store.updateCatalogItem(
    eggs.id, { "Free-range eggs", aisleId(1), "egg", { 12, Unit::Pieces } }));

  CHECK(store.ingredients()[index].name == "Free-range eggs");
  CHECK(store.ingredients()[index].canonicalName == "free-range eggs");
  CHECK(store.ingredients()[index].oneTap == core::Amount{ 12, Unit::Pieces });
  CHECK(store.ingredients()[index].modifiedAt == clock.now);
  CHECK(observer.notifications ==
        notificationsFor(
          core::IngredientUpdated{
            index, { IngredientField::Name, IngredientField::OneTap } },
          34,
          34));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "updateCatalogItem without a change writes nothing; a case "
                  "change is allowed")
{
  const core::Ingredient eggs = named("Eggs");
  const int index = indexOf("Eggs");

  REQUIRE(store.updateCatalogItem(
    eggs.id, { " Eggs ", aisleId(1), "egg", { 6, Unit::Pieces } }));
  CHECK(store.ingredients()[index].modifiedAt == test::seedTime);
  CHECK(observer.notifications.empty());

  REQUIRE(store.updateCatalogItem(
    eggs.id, { "EGGS", aisleId(1), "egg", { 6, Unit::Pieces } }));
  CHECK(store.ingredients()[index].name == "EGGS");
}

TEST_CASE_FIXTURE(Fixture,
                  "updateCatalogItem rejects blank names and names in use")
{
  const std::string eggs = named("Eggs").id;
  store.removeFromCatalog(named("Milk").id);
  const auto before = store.ingredients();
  observer.notifications.clear();
  const auto rename = [&](std::string_view name) {
    return store.updateCatalogItem(
      eggs, { name, aisleId(1), "egg", { 6, Unit::Pieces } });
  };

  CHECK(rename(" ") == std::unexpected(IngredientError::EmptyName));
  CHECK(rename("butter") == std::unexpected(IngredientError::DuplicateName));
  CHECK(rename("Milk") == std::unexpected(IngredientError::NameTaken));

  CHECK(store.ingredients() == before);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "checkCatalogName says what adding or renaming would say")
{
  const std::string eggs = named("Eggs").id;
  store.removeFromCatalog(named("Milk").id);

  CHECK(store.checkCatalogName("Leeks"));
  CHECK(store.checkCatalogName("") ==
        std::unexpected(IngredientError::EmptyName));
  CHECK(store.checkCatalogName("eggs") ==
        std::unexpected(IngredientError::DuplicateName));
  CHECK(store.checkCatalogName("milk")); // reused when added

  CHECK(store.checkCatalogName("eggs", eggs)); // its own name
  CHECK(store.checkCatalogName("butter", eggs) ==
        std::unexpected(IngredientError::DuplicateName));
  CHECK(store.checkCatalogName("milk", eggs) ==
        std::unexpected(IngredientError::NameTaken));
}

TEST_CASE_FIXTURE(Fixture,
                  "removeFromCatalog keeps the ingredient; restoreToCatalog "
                  "puts it back")
{
  const core::Ingredient butter = named("Butter");
  const int index = indexOf("Butter");

  store.removeFromCatalog(butter.id);

  CHECK(store.ingredients().size() == 34);
  CHECK_FALSE(store.ingredients()[index].inCatalog);
  CHECK(store.ingredients()[index].modifiedAt == clock.now);
  CHECK(observer.notifications ==
        notificationsFor(
          core::IngredientUpdated{ index, { IngredientField::InCatalog } },
          34,
          34));
  CHECK(reloadMatches());

  observer.notifications.clear();
  clock.now += 1min;
  REQUIRE(store.restoreToCatalog(butter.id));

  core::Ingredient restored = butter;
  restored.modifiedAt = clock.now;
  CHECK(store.ingredients()[index] == restored);
  CHECK(observer.notifications ==
        notificationsFor(
          core::IngredientUpdated{ index, { IngredientField::InCatalog } },
          34,
          34));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "restoreToCatalog fails once the item's aisle is deleted")
{
  const std::string meatAndFish = aisleId(2);
  std::string salmon;
  for (const core::Ingredient& ingredient : store.ingredients()) {
    if (ingredient.inCatalog && ingredient.aisleId == meatAndFish) {
      if (ingredient.name == "Salmon fillets") {
        salmon = ingredient.id;
      }
      store.removeFromCatalog(ingredient.id);
    }
  }
  REQUIRE(aisles.remove(meatAndFish));
  const auto before = store.ingredients();
  observer.notifications.clear();

  CHECK(store.restoreToCatalog(salmon) ==
        std::unexpected(IngredientError::AisleDeleted));
  CHECK(store.ingredients() == before);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "Programming errors throw before anything changes")
{
  const std::string eggs = named("Eggs").id;
  const auto before = store.ingredients();
  const auto fields = [&](std::string_view aisle,
                          std::optional<std::string_view> icon,
                          double quantity) {
    return core::CatalogFields{
      "Leeks", aisle, icon, { quantity, Unit::Grams }
    };
  };

  CHECK_THROWS_AS((void)store.addToCatalog(fields("unknown", "leaf", 1)),
                  std::invalid_argument);
  CHECK_THROWS_AS((void)store.addToCatalog(fields(aisleId(0), "", 1)),
                  std::invalid_argument);
  for (const double quantity : { 0.0,
                                 -1.0,
                                 std::numeric_limits<double>::quiet_NaN(),
                                 std::numeric_limits<double>::infinity() }) {
    CAPTURE(quantity);
    CHECK_THROWS_AS(
      (void)store.addToCatalog(fields(aisleId(0), "leaf", quantity)),
      std::invalid_argument);
  }
  CHECK_THROWS_AS(
    (void)store.updateCatalogItem("unknown", fields(aisleId(0), "leaf", 1)),
    std::invalid_argument);
  CHECK_THROWS_AS(store.removeFromCatalog("unknown"), std::invalid_argument);
  CHECK_THROWS_AS((void)store.restoreToCatalog(eggs),
                  std::invalid_argument); // already in the catalog
  CHECK_THROWS_AS((void)store.checkCatalogName("Leeks", "unknown"),
                  std::invalid_argument);
  CHECK(store.ingredients() == before);
  CHECK(observer.notifications.empty());

  store.removeFromCatalog(eggs);
  CHECK_THROWS_AS(store.removeFromCatalog(eggs), std::invalid_argument);
  CHECK_THROWS_AS(
    (void)store.updateCatalogItem(eggs, fields(aisleId(0), "leaf", 1)),
    std::invalid_argument);
}

TEST_CASE_FIXTURE(Fixture,
                  "A failed write changes neither the database nor memory")
{
  // Triggers make SQLite fail in the middle of a write, as a full disk would
  SUBCASE("addToCatalog, new")
  {
    db.exec("CREATE TRIGGER fail BEFORE INSERT ON ingredient "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] {
      (void)store.addToCatalog(
        { "Leeks", aisleId(0), "leaf", { 1, Unit::Kilograms } });
    });
  }
  SUBCASE("addToCatalog, reused")
  {
    store.removeFromCatalog(named("Milk").id);
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF in_catalog ON ingredient "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] {
      (void)store.addToCatalog(
        { "Milk", aisleId(1), "milk", { 1, Unit::Liters } });
    });
  }
  SUBCASE("updateCatalogItem")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF display_name ON ingredient "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] {
      (void)store.updateCatalogItem(
        named("Eggs").id,
        { "Duck eggs", aisleId(1), "egg", { 6, Unit::Pieces } });
    });
  }
  SUBCASE("removeFromCatalog")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF in_catalog ON ingredient "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(
      *this, [&] { store.removeFromCatalog(named("Eggs").id); });
  }
}

TEST_CASE_FIXTURE(Fixture,
                  "Changing the store from inside a notification is refused")
{
  struct MeddlingObserver final : core::IngredientObserver
  {
    explicit MeddlingObserver(core::IngredientStore& store, std::string id)
      : store(store)
      , id(std::move(id))
    {
    }
    void ingredientAboutToChange(
      const core::IngredientChange&) noexcept override
    {
      CHECK_THROWS_AS(store.removeFromCatalog(id), std::logic_error);
    }
    void ingredientChanged(const core::IngredientChange&) noexcept override
    {
      CHECK_THROWS_AS((void)store.restoreToCatalog(id), std::logic_error);
    }

    core::IngredientStore& store;
    std::string id;
  } meddling(store, named("Butter").id);
  store.addObserver(meddling);

  store.removeFromCatalog(named("Eggs").id);

  CHECK(named("Butter").inCatalog);
  store.removeObserver(meddling);
}
