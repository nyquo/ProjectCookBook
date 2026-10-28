#include "core/TagStore.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

#include <algorithm>
#include <stdexcept>

using core::TagError;
using core::TagFamily;
using namespace std::chrono_literals;

namespace {

struct Notification
{
  bool changed; // false: about to change
  core::TagChange change;
  std::size_t sizeSeen;

  bool operator==(const Notification&) const = default;
};

class RecordingObserver final : public core::TagObserver
{
public:
  explicit RecordingObserver(core::TagStore& store)
    : m_store(store)
  {
    m_store.addObserver(*this);
  }
  ~RecordingObserver() { m_store.removeObserver(*this); }

  void tagAboutToChange(const core::TagChange& change) noexcept override
  {
    notifications.push_back({ false, change, m_store.tags().size() });
  }
  void tagChanged(const core::TagChange& change) noexcept override
  {
    notifications.push_back({ true, change, m_store.tags().size() });
  }

  std::vector<Notification> notifications;

private:
  core::TagStore& m_store;
};

std::vector<Notification> notificationsFor(core::TagChange change,
                                           std::size_t sizeBefore,
                                           std::size_t sizeAfter)
{
  return { { false, change, sizeBefore }, { true, change, sizeAfter } };
}

// A row of the tag table, as stored
struct TagRow
{
  std::string id;
  std::string name;
  std::string canonicalName;
  std::string color;
  std::int64_t modifiedAt;
  bool deleted;

  bool operator==(const TagRow&) const = default;
};

std::vector<TagRow> tagRows(core::Database& db)
{
  core::Statement select =
    db.prepare("SELECT id, name, canonical_name, color, modified_at, deleted "
               "FROM tag ORDER BY id");
  std::vector<TagRow> rows;
  while (select.step()) {
    rows.push_back({ select.columnText(0),
                     select.columnText(1),
                     select.columnText(2),
                     select.columnText(3),
                     select.columnInt64(4),
                     select.columnInt64(5) != 0 });
  }
  return rows;
}

struct Fixture
{
  test::FakeClock clock;
  core::Database db{ ":memory:" };
  core::TagStore store{ test::migrated(db), clock.function() };
  RecordingObserver observer{ store };

  std::string create(std::string_view name)
  {
    const auto id = store.create(name);
    REQUIRE(id);
    return *id;
  }

  const core::Tag& tag(std::string_view id) const
  {
    const auto& tags = store.tags();
    const auto it = std::ranges::find(tags, id, &core::Tag::id);
    REQUIRE(it != tags.end());
    return *it;
  }

  int indexOf(std::string_view id) const
  {
    return static_cast<int>(&tag(id) - store.tags().data());
  }

  bool reloadMatches()
  {
    const core::TagStore reloaded(db, core::systemNow);
    return reloaded.tags() == store.tags();
  }
};

// `write` must fail, because of a trigger the test installed
void checkFailedWriteChangesNothing(Fixture& f, auto&& write)
{
  const auto tagsBefore = f.store.tags();
  const auto rowsBefore = tagRows(f.db);
  f.observer.notifications.clear();

  CHECK(test::errorCode(write) == SQLITE_CONSTRAINT_TRIGGER);
  CHECK(f.store.tags() == tagsBefore);
  CHECK(tagRows(f.db) == rowsBefore);
  CHECK(f.observer.notifications.empty());
}

}

TEST_CASE_FIXTURE(Fixture, "A new database has no tags")
{
  CHECK(store.tags().empty());
}

TEST_CASE_FIXTURE(Fixture, "create adds a trimmed tag with its folded name")
{
  const std::string id = create("  Crème  Brûlée\t");

  CHECK(id[14] == '7');
  CHECK(store.tags() ==
        std::vector{ core::Tag{
          id, "Crème  Brûlée", "creme brulee", TagFamily::Mint, clock.now } });
  CHECK(observer.notifications ==
        notificationsFor(core::TagInserted{ 0 }, 0, 1));
  CHECK(tagRows(db) == std::vector{ TagRow{ id,
                                            "Crème  Brûlée",
                                            "creme brulee",
                                            "mint",
                                            core::toMillis(clock.now),
                                            false } });
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "create rejects blank and duplicate names")
{
  create("Brunch");
  const auto rowsBefore = tagRows(db);
  observer.notifications.clear();

  CHECK(store.create("") == std::unexpected(TagError::EmptyName));
  CHECK(store.create(" \t\n") == std::unexpected(TagError::EmptyName));
  // Trimming keeps a no-break space; folding drops it
  CHECK(store.create("\xc2\xa0") == std::unexpected(TagError::EmptyName));
  CHECK(store.create("brunch") == std::unexpected(TagError::DuplicateName));
  CHECK(store.create(" BRÜNCH ") == std::unexpected(TagError::DuplicateName));

  CHECK(store.tags().size() == 1);
  CHECK(tagRows(db) == rowsBefore);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "A new tag takes the least used color, ties in family order")
{
  const std::string a = create("A");
  const std::string b = create("B");
  const std::string c = create("C");
  const std::string d = create("D");
  CHECK(
    std::vector{ tag(a).color, tag(b).color, tag(c).color, tag(d).color } ==
    std::vector{
      TagFamily::Mint, TagFamily::Butter, TagFamily::Sky, TagFamily::Peach });

  // All used once: Mint comes first
  const std::string e = create("E");
  CHECK(tag(e).color == TagFamily::Mint);
  // Mint 2, the others 1
  CHECK(store.nextColor() == TagFamily::Butter);

  // Mint 1, Butter 1, Sky 1, Peach 2
  store.setColor(a, TagFamily::Peach);
  CHECK(store.nextColor() == TagFamily::Mint);

  // Deleted tags don't count: Sky 0
  store.remove(c);
  const std::string f = create("F");
  CHECK(tag(f).color == TagFamily::Sky);
}

TEST_CASE_FIXTURE(Fixture, "rename trims and updates both names")
{
  const std::string id = create("Brunch");
  observer.notifications.clear();
  clock.now += 1min;

  CHECK(store.rename(id, " Sunday lunch "));

  CHECK(tag(id).name == "Sunday lunch");
  CHECK(tag(id).canonicalName == "sunday lunch");
  CHECK(tag(id).modifiedAt == clock.now);
  CHECK(observer.notifications ==
        notificationsFor(core::TagUpdated{ 0, core::TagField::Name }, 1, 1));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(
  Fixture,
  "rename to the same name does nothing; another case of it is allowed")
{
  const std::string id = create("Brunch");
  const core::Timestamp created = clock.now;
  observer.notifications.clear();
  clock.now += 1min;

  CHECK(store.rename(id, " Brunch "));
  CHECK(tag(id).modifiedAt == created);
  CHECK(observer.notifications.empty());

  CHECK(store.rename(id, "BRUNCH"));
  CHECK(tag(id).name == "BRUNCH");
  CHECK(store.rename(id, "Brünch"));
  CHECK(tag(id).name == "Brünch");
  CHECK(tag(id).canonicalName == "brunch");
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "rename rejects blank and duplicate names")
{
  const std::string id = create("Brunch");
  create("Weeknight");
  const auto rowsBefore = tagRows(db);
  observer.notifications.clear();

  CHECK(store.rename(id, "  ") == std::unexpected(TagError::EmptyName));
  CHECK(store.rename(id, "WEEKNIGHT") ==
        std::unexpected(TagError::DuplicateName));

  CHECK(tag(id).name == "Brunch");
  CHECK(tagRows(db) == rowsBefore);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "setColor stores the family's code")
{
  const std::string id = create("Brunch");
  observer.notifications.clear();
  clock.now += 1min;

  store.setColor(id, TagFamily::Peach);

  CHECK(tag(id).color == TagFamily::Peach);
  CHECK(tag(id).modifiedAt == clock.now);
  CHECK(tagRows(db)[0].color == "peach");
  CHECK(observer.notifications ==
        notificationsFor(core::TagUpdated{ 0, core::TagField::Color }, 1, 1));

  observer.notifications.clear();
  store.setColor(id, TagFamily::Peach);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture, "Every family is accepted by the CHECK constraint")
{
  const std::string id = create("Brunch");
  for (const auto color : { TagFamily::Butter,
                            TagFamily::Sky,
                            TagFamily::Peach,
                            TagFamily::Mint }) {
    store.setColor(id, color);
    REQUIRE(reloadMatches());
  }
}

TEST_CASE_FIXTURE(Fixture, "remove soft-deletes the tag")
{
  create("Brunch");
  const std::string id = create("Weeknight");
  const int index = indexOf(id);
  observer.notifications.clear();
  clock.now += 1min;

  store.remove(id);

  CHECK(store.tags().size() == 1);
  CHECK(observer.notifications ==
        notificationsFor(core::TagRemoved{ index }, 2, 1));
  const auto rows = tagRows(db);
  const auto row = std::ranges::find(rows, id, &TagRow::id);
  REQUIRE(row != rows.end());
  CHECK(row->deleted);
  CHECK(row->modifiedAt == core::toMillis(clock.now));
  CHECK(reloadMatches());

  // Its name is free again
  CHECK(store.create("weeknight"));
}

TEST_CASE_FIXTURE(Fixture, "restore brings the tag back as it was")
{
  create("A");
  create("B");
  create("C");
  const std::vector<core::Tag> before = store.tags();
  const std::string& middle = before[1].id;
  store.setColor(middle, TagFamily::Peach);
  store.remove(middle);
  observer.notifications.clear();
  clock.now += 1min;

  REQUIRE(store.restore(middle));

  CHECK(store.tags().size() == 3);
  CHECK(store.tags()[1].id == middle);
  CHECK(store.tags()[1].name == before[1].name);
  CHECK(store.tags()[1].color == TagFamily::Peach);
  CHECK(store.tags()[1].modifiedAt == clock.now);
  CHECK(observer.notifications ==
        notificationsFor(core::TagInserted{ 1 }, 2, 3));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture,
                  "restore fails if a live tag took the name in the meantime")
{
  const std::string id = create("Brunch");
  store.remove(id);
  create("BRÜNCH");
  const auto rowsBefore = tagRows(db);
  observer.notifications.clear();

  CHECK(store.restore(id) == std::unexpected(TagError::DuplicateName));

  CHECK(tagRows(db) == rowsBefore);
  CHECK(observer.notifications.empty());
}

TEST_CASE_FIXTURE(Fixture,
                  "Tags stay in id order, even made in the same millisecond")
{
  // The clock doesn't move: the ids differ only by their random bits
  for (int i = 0; i < 20; ++i) {
    create("Tag " + std::to_string(i));
  }

  CHECK(std::ranges::is_sorted(store.tags(), {}, &core::Tag::id));
  CHECK(reloadMatches());
}

TEST_CASE_FIXTURE(Fixture, "Unknown ids are programming errors")
{
  const std::string id = create("Brunch");

  CHECK_THROWS_AS((void)store.rename("unknown", "Lunch"),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.setColor("unknown", TagFamily::Sky),
                  std::invalid_argument);
  CHECK_THROWS_AS(store.remove("unknown"), std::invalid_argument);
  CHECK_THROWS_AS((void)store.restore("unknown"), std::invalid_argument);
  CHECK_THROWS_AS((void)store.restore(id),
                  std::invalid_argument); // live, not deleted
}

TEST_CASE_FIXTURE(Fixture, "Loading refuses a color it doesn't know")
{
  create("Brunch");
  // Only a write that bypassed the CHECK constraints could store one
  db.exec("PRAGMA ignore_check_constraints = ON;"
          "UPDATE tag SET color = 'rose'");
  CHECK(test::errorCode([&] {
          core::TagStore reloaded(db, clock.function());
        }) == SQLITE_CORRUPT);
}

TEST_CASE_FIXTURE(Fixture,
                  "A failed write changes neither the database nor memory")
{
  const std::string id = create("Brunch");
  // Triggers make SQLite fail in the middle of a write, as a full disk would
  SUBCASE("create")
  {
    db.exec("CREATE TRIGGER fail BEFORE INSERT ON tag "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this,
                                   [&] { (void)store.create("Weeknight"); });
  }
  SUBCASE("rename")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF name ON tag "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this,
                                   [&] { (void)store.rename(id, "Lunch"); });
  }
  SUBCASE("setColor")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF color ON tag "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this,
                                   [&] { store.setColor(id, TagFamily::Sky); });
  }
  SUBCASE("remove")
  {
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF deleted ON tag "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { store.remove(id); });
  }
  SUBCASE("restore")
  {
    store.remove(id);
    db.exec("CREATE TRIGGER fail BEFORE UPDATE OF deleted ON tag "
            "BEGIN SELECT RAISE(ABORT, 'simulated'); END");
    checkFailedWriteChangesNothing(*this, [&] { (void)store.restore(id); });
  }
}

TEST_CASE_FIXTURE(Fixture,
                  "Changing the store from inside a notification is refused")
{
  const std::string id = create("Brunch");
  struct MeddlingObserver final : core::TagObserver
  {
    explicit MeddlingObserver(core::TagStore& store, std::string id)
      : store(store)
      , id(std::move(id))
    {
    }
    void tagAboutToChange(const core::TagChange&) noexcept override
    {
      CHECK_THROWS_AS(store.remove(id), std::logic_error);
    }
    void tagChanged(const core::TagChange&) noexcept override
    {
      CHECK_THROWS_AS((void)store.create("Lunch"), std::logic_error);
    }

    core::TagStore& store;
    std::string id;
  } meddling(store, id);
  store.addObserver(meddling);

  store.setColor(id, TagFamily::Sky);

  CHECK(store.tags().size() == 1);
  store.removeObserver(meddling);
}
