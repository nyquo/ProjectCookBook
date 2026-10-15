#include "core/AisleStore.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

#include <optional>
#include <stdexcept>

using core::AisleColor;
using core::AisleError;
using namespace std::chrono_literals;

namespace {

using Names = std::vector<std::string>;

struct Fixture
{
  test::FakeClock clock;
  core::Database db{ ":memory:" };
  core::AisleStore store{ test::migrated(db), clock.function() };
  test::RecordingObserver observer{ store };

  std::string idAt(std::size_t index) const
  {
    return store.aisles().at(index).id;
  }
};

// `write` must fail, because of a trigger the test installed.
void checkFailedWriteChangesNothing(Fixture& f, auto&& write)
{
  const auto aislesBefore = f.store.aisles();
  const auto rowsBefore = test::aisleRows(f.db);
  f.observer.notifications.clear();

  CHECK(test::errorCode(write) == SQLITE_CONSTRAINT_TRIGGER);
  CHECK(f.store.aisles() == aislesBefore);
  CHECK(test::aisleRows(f.db) == rowsBefore);
  CHECK(f.observer.notifications.empty());
}

}

TEST_CASE_FIXTURE(Fixture, "Loading reads the live aisles in position order")
{
  CHECK(test::names(store) == test::seedNames);
  CHECK(store.aisles()[1].color == AisleColor::Butter);
  CHECK(store.aisles()[3].color == AisleColor::Sky);
  CHECK(store.aisles()[0].modifiedAt == test::seedTime);
}

TEST_CASE_FIXTURE(Fixture,
                  "Loading renumbers gaps and duplicates in live positions")
{
  db.exec("UPDATE aisle SET position = 5 WHERE name = 'Produce';"
          "UPDATE aisle SET position = 1 WHERE name = 'Meat & fish'");

  const core::AisleStore reloaded(db, clock.function());

  // Dairy & eggs and Meat & fish are both at 1: ties keep id order.
  CHECK(test::names(reloaded) ==
        Names{ "Dairy & eggs", "Meat & fish", "Pantry", "Produce" });
  CHECK(test::modifiedTimes(reloaded) ==
        std::vector{ clock.now, test::seedTime, clock.now, clock.now });
  CHECK(test::reloadMatches(db, reloaded));
}

TEST_CASE_FIXTURE(Fixture, "create appends a trimmed aisle")
{
  const auto id = store.create("  Bakery\t", AisleColor::Peach);

  REQUIRE(id);
  CHECK((*id)[14] == '7');
  CHECK(store.aisles().back() ==
        core::Aisle{ *id, "Bakery", AisleColor::Peach, clock.now });
  CHECK(observer.notifications ==
        test::notificationsFor(core::AisleInserted{ 4 }, 4, 5));
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(Fixture, "create rejects blank and duplicate names")
{
  const auto rowsBefore = test::aisleRows(db);

  CHECK(store.create("", AisleColor::Mint) ==
        std::unexpected(AisleError::EmptyName));
  CHECK(store.create(" \t\n", AisleColor::Mint) ==
        std::unexpected(AisleError::EmptyName));
  CHECK(store.create("produce", AisleColor::Mint) ==
        std::unexpected(AisleError::DuplicateName));
  CHECK(store.create(" PANTRY ", AisleColor::Mint) ==
        std::unexpected(AisleError::DuplicateName));

  CHECK(test::names(store) == test::seedNames);
  CHECK(test::aisleRows(db) == rowsBefore);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(
  Fixture,
  "Names compare ignoring case for ASCII letters only, like the index")
{
  REQUIRE(store.create("Épicerie", AisleColor::Mint));
  CHECK(store.create("épicerie", AisleColor::Mint)); // É and é differ
  CHECK(store.create("ÉPICERIE", AisleColor::Mint) ==
        std::unexpected(AisleError::DuplicateName));
}

TEST_CASE_FIXTURE(Fixture, "A deleted aisle's name can be reused")
{
  store.remove(idAt(3));
  CHECK(store.create("Pantry", AisleColor::Sky));
}

TEST_CASE_FIXTURE(Fixture, "rename trims and updates the name")
{
  CHECK(store.rename(idAt(1), " Dairy "));

  CHECK(store.aisles()[1].name == "Dairy");
  CHECK(store.aisles()[1].modifiedAt == clock.now);
  CHECK(observer.notifications ==
        test::notificationsFor(
          core::AisleUpdated{ 1, core::AisleField::Name }, 4, 4));
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(
  Fixture,
  "rename to the same name does nothing; a case change is allowed")
{
  CHECK(store.rename(idAt(0), " Produce "));
  CHECK(store.aisles()[0].modifiedAt == test::seedTime);
  CHECK(observer.notifications.empty());

  CHECK(store.rename(idAt(0), "PRODUCE"));
  CHECK(store.aisles()[0].name == "PRODUCE");
}

TEST_CASE_FIXTURE(Fixture, "rename rejects blank and duplicate names")
{
  const auto rowsBefore = test::aisleRows(db);

  CHECK(store.rename(idAt(0), "  ") == std::unexpected(AisleError::EmptyName));
  CHECK(store.rename(idAt(0), "pantry") ==
        std::unexpected(AisleError::DuplicateName));

  CHECK(test::names(store) == test::seedNames);
  CHECK(test::aisleRows(db) == rowsBefore);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "setColor stores the color as text")
{
  store.setColor(idAt(0), AisleColor::Peach);

  CHECK(store.aisles()[0].color == AisleColor::Peach);
  CHECK(store.aisles()[0].modifiedAt == clock.now);
  CHECK(test::aisleRows(db)[0].color == "peach");
  CHECK(observer.notifications ==
        test::notificationsFor(
          core::AisleUpdated{ 0, core::AisleField::Color }, 4, 4));

  observer.notifications.clear();
  store.setColor(idAt(0), AisleColor::Peach);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "Every color is accepted by the database's CHECK constraint")
{
  for (AisleColor color : core::allAisleColors) {
    store.setColor(idAt(0), color);
    CHECK(test::reloadMatches(db, store));
  }
}

TEST_CASE_FIXTURE(Fixture, "move down shifts the aisles in between up")
{
  store.move(0, 2);

  CHECK(test::names(store) ==
        Names{ "Dairy & eggs", "Meat & fish", "Produce", "Pantry" });
  CHECK(test::modifiedTimes(store) ==
        std::vector{ clock.now, clock.now, clock.now, test::seedTime });
  CHECK(observer.notifications ==
        test::notificationsFor(core::AisleMoved{ 0, 2 }, 4, 4));
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(Fixture, "move up shifts the aisles in between down")
{
  store.move(3, 1);

  CHECK(test::names(store) ==
        Names{ "Produce", "Pantry", "Dairy & eggs", "Meat & fish" });
  CHECK(test::modifiedTimes(store) ==
        std::vector{ test::seedTime, clock.now, clock.now, clock.now });
  CHECK(observer.notifications ==
        test::notificationsFor(core::AisleMoved{ 3, 1 }, 4, 4));
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(
  Fixture,
  "move to the same index does nothing; an index out of range throws")
{
  store.move(2, 2);
  CHECK(observer.notifications.empty());

  CHECK_THROWS_AS(store.move(0, 4), std::out_of_range);
  CHECK_THROWS_AS(store.move(-1, 0), std::out_of_range);
}

TEST_CASE_FIXTURE(Fixture, "remove soft-deletes the aisle and closes the gap")
{
  const std::string id = idAt(1);
  store.remove(id);

  CHECK(test::names(store) == Names{ "Produce", "Meat & fish", "Pantry" });
  CHECK(test::modifiedTimes(store) ==
        std::vector{ test::seedTime, clock.now, clock.now });
  CHECK(observer.notifications ==
        test::notificationsFor(core::AisleRemoved{ 1 }, 4, 3));
  CHECK(test::aisleRows(db).back() ==
        test::AisleRow{
          id, "Dairy & eggs", "butter", 1, core::toMillis(clock.now), true });
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(Fixture, "restore puts the aisle back at its old position")
{
  const std::string id = idAt(1);
  store.remove(id);
  observer.notifications.clear();
  clock.now += 1min;

  REQUIRE(store.restore(id));

  CHECK(test::names(store) == test::seedNames);
  CHECK(test::modifiedTimes(store) ==
        std::vector{ test::seedTime, clock.now, clock.now, clock.now });
  CHECK(observer.notifications ==
        test::notificationsFor(core::AisleInserted{ 1 }, 3, 4));
  CHECK(test::aisleRows(db).size() == 4);
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(Fixture,
                  "restore appends when the old position is past the end")
{
  const std::string pantry = idAt(3);
  store.remove(pantry);
  store.remove(idAt(0));

  REQUIRE(store.restore(pantry));

  CHECK(test::names(store) == Names{ "Dairy & eggs", "Meat & fish", "Pantry" });
  CHECK(test::reloadMatches(db, store));
}

TEST_CASE_FIXTURE(Fixture,
                  "restore fails if a live aisle took the name in the meantime")
{
  const std::string id = idAt(1);
  store.remove(id);
  REQUIRE(store.create("dairy & EGGS", AisleColor::Mint));
  const auto rowsBefore = test::aisleRows(db);
  observer.notifications.clear();

  CHECK(store.restore(id) == std::unexpected(AisleError::DuplicateName));

  CHECK(test::aisleRows(db) == rowsBefore);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "Unknown ids are programming errors")
{
  CHECK_THROWS_AS((void)store.rename("unknown", "Bakery"),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.setColor("unknown", AisleColor::Mint),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.remove("unknown"), std::invalid_argument);
  CHECK_THROWS_AS((void)store.restore("unknown"), std::invalid_argument);
  CHECK_THROWS_AS((void)store.restore(idAt(0)),
                  std::invalid_argument); // live, not deleted
}

TEST_CASE_FIXTURE(Fixture,
                  "A failed write changes neither the database nor memory")
{
  // Triggers make SQLite fail in the middle of a write, as a full disk would.
  SUBCASE("create")
  {
    db.exec("CREATE TRIGGER fail BEFORE INSERT ON aisle "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(
      *this, [&] { (void)store.create("Bakery", AisleColor::Mint); });
  }
  SUBCASE("rename")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF name ON aisle "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(
      *this, [&] { (void)store.rename(idAt(0), "Fruit"); });
  }
  SUBCASE("setColor")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF color ON aisle "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(
      *this, [&] { store.setColor(idAt(0), AisleColor::Sky); });
  }
  SUBCASE("move, failing at its second statement")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF position ON aisle "
            "WHEN OLD.id = '01a11df5-a400-7c7d-9ae7-fc4361b1e2a5' "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { store.move(0, 2); });
  }
  SUBCASE("remove, failing at its second statement")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF position ON aisle "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { store.remove(idAt(1)); });
  }
  SUBCASE("restore, failing at its second statement")
  {
    const std::string id = idAt(1);
    store.remove(id);
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF deleted ON aisle "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { (void)store.restore(id); });
  }
}

TEST_CASE_FIXTURE(Fixture, "A removed observer is no longer notified")
{
  store.removeObserver(observer);
  store.setColor(idAt(0), AisleColor::Peach);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "An observer can unregister while being notified")
{
  struct LeavingObserver final : core::AisleObserver
  {
    explicit LeavingObserver(core::AisleStore& store)
      : store(store)
    {
    }
    void aisleAboutToChange(const core::AisleChange&) noexcept override
    {
      ++calls;
      store.removeObserver(*this);
    }
    void aisleChanged(const core::AisleChange&) noexcept override { ++calls; }

    core::AisleStore& store;
    int calls = 0;
  } leaving(store);
  store.addObserver(leaving);

  store.setColor(idAt(0), AisleColor::Peach);
  store.setColor(idAt(0), AisleColor::Sky);

  CHECK(leaving.calls == 1);
  CHECK(observer.notifications.size() == 4);
}

TEST_CASE_FIXTURE(
  Fixture,
  "An observer registered while notified gets both calls or neither")
{
  // Registered during aisleAboutToChange(), it saw the old list; during
  // aisleChanged(), the new one.
  struct JoiningObserver final : core::AisleObserver
  {
    explicit JoiningObserver(core::AisleStore& store)
      : store(store)
    {
    }
    void aisleAboutToChange(const core::AisleChange&) noexcept override
    {
      early.emplace(store);
    }
    void aisleChanged(const core::AisleChange&) noexcept override
    {
      late.emplace(store);
    }

    core::AisleStore& store;
    std::optional<test::RecordingObserver> early;
    std::optional<test::RecordingObserver> late;
  } joining(store);
  store.addObserver(joining);

  REQUIRE(store.create("Bakery", AisleColor::Mint));

  REQUIRE(joining.early);
  REQUIRE(joining.late);
  CHECK(joining.early->notifications ==
        test::notificationsFor(core::AisleInserted{ 4 }, 4, 5));
  CHECK(joining.late->notifications.empty());
  store.removeObserver(joining);
}

TEST_CASE_FIXTURE(Fixture,
                  "Changing the store from inside a notification is refused")
{
  struct MeddlingObserver final : core::AisleObserver
  {
    explicit MeddlingObserver(core::AisleStore& store)
      : store(store)
    {
    }
    void aisleAboutToChange(const core::AisleChange&) noexcept override
    {
      CHECK_THROWS_AS(store.move(0, 1), std::logic_error);
    }
    void aisleChanged(const core::AisleChange&) noexcept override
    {
      CHECK_THROWS_AS((void)store.create("Bakery", AisleColor::Mint),
                      std::logic_error);
    }

    core::AisleStore& store;
  } meddling(store);
  store.addObserver(meddling);

  store.setColor(idAt(0), AisleColor::Peach);

  CHECK(test::names(store) == test::seedNames);
  store.removeObserver(meddling);
}
