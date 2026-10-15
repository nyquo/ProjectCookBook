#pragma once

#include "core/AisleStore.hpp"
#include "core/Database.hpp"
#include "core/UuidV7Generator.hpp"
#include "core/clock.hpp"
#include "core/migrations.hpp"

#include <sqlite3.h>

#include <cstdint>
#include <filesystem>
#include <string>
#include <system_error>
#include <vector>

namespace test {

inline const std::vector<std::string> seedNames{ "Produce",
                                                 "Dairy & eggs",
                                                 "Meat & fish",
                                                 "Pantry" };
inline const core::Timestamp seedTime =
  core::fromMillis(1791504000000); // 2026-10-09 00:00 UTC

struct FakeClock
{
  core::Timestamp now =
    core::fromMillis(1798761600000); // 2027-01-01 00:00 UTC, after the seeds

  core::Clock function()
  {
    return [this] { return now; };
  }
};

inline core::Database& migrated(core::Database& db)
{
  core::migrate(db);
  return db;
}

// SQLITE_OK when `write` doesn't throw.
inline int errorCode(auto&& write)
{
  try {
    write();
  } catch (const core::DatabaseError& error) {
    return error.code();
  }
  return SQLITE_OK;
}

struct AisleRow
{
  std::string id;
  std::string name;
  std::string color;
  std::int64_t position;
  std::int64_t modifiedAt;
  bool deleted;

  bool operator==(const AisleRow&) const = default;
};

// Live rows first, then deleted ones, each in position order.
inline std::vector<AisleRow> aisleRows(core::Database& db)
{
  core::Statement select =
    db.prepare("SELECT id, name, color, position, modified_at, deleted "
               "FROM aisle ORDER BY deleted, position");
  std::vector<AisleRow> rows;
  while (select.step()) {
    rows.push_back({ select.columnText(0),
                     select.columnText(1),
                     select.columnText(2),
                     select.columnInt64(3),
                     select.columnInt64(4),
                     select.columnInt64(5) != 0 });
  }
  return rows;
}

inline std::vector<std::string> names(const core::AisleStore& store)
{
  std::vector<std::string> result;
  for (const core::Aisle& aisle : store.aisles()) {
    result.push_back(aisle.name);
  }
  return result;
}

inline std::vector<core::Timestamp> modifiedTimes(const core::AisleStore& store)
{
  std::vector<core::Timestamp> result;
  for (const core::Aisle& aisle : store.aisles()) {
    result.push_back(aisle.modifiedAt);
  }
  return result;
}

// Also checks that live positions are exactly 0..n-1, which loading would
// otherwise repair.
inline bool reloadMatches(core::Database& db, const core::AisleStore& store)
{
  std::int64_t expected = 0;
  for (const AisleRow& row : aisleRows(db)) {
    if (!row.deleted && row.position != expected++) {
      return false;
    }
  }
  const core::AisleStore reloaded(db, core::systemNow);
  return reloaded.aisles() == store.aisles();
}

struct Notification
{
  enum Phase
  {
    AboutToChange,
    Changed
  };

  Phase phase;
  core::AisleChange change;
  std::size_t sizeSeen; // store.aisles().size() when notified

  bool operator==(const Notification&) const = default;
};

inline std::vector<Notification> notificationsFor(core::AisleChange change,
                                                  std::size_t sizeBefore,
                                                  std::size_t sizeAfter)
{
  return { { Notification::AboutToChange, change, sizeBefore },
           { Notification::Changed, change, sizeAfter } };
}

class RecordingObserver final : public core::AisleObserver
{
public:
  explicit RecordingObserver(core::AisleStore& store)
    : m_store(store)
  {
    m_store.addObserver(*this);
  }
  ~RecordingObserver() { m_store.removeObserver(*this); }

  void aisleAboutToChange(const core::AisleChange& change) noexcept override
  {
    notifications.push_back(
      { Notification::AboutToChange, change, m_store.aisles().size() });
  }
  void aisleChanged(const core::AisleChange& change) noexcept override
  {
    notifications.push_back(
      { Notification::Changed, change, m_store.aisles().size() });
  }

  std::vector<Notification> notifications;

private:
  core::AisleStore& m_store;
};

// Deletes the file and its journal on destruction.
class TempDatabasePath
{
public:
  TempDatabasePath()
    : m_path(std::filesystem::temp_directory_path() /
             ("cookbook-test-" +
              core::UuidV7Generator().next(core::systemNow()) + ".db"))
  {
  }
  ~TempDatabasePath()
  {
    std::error_code ignored;
    std::filesystem::remove(m_path, ignored);
    std::filesystem::remove(std::filesystem::path(m_path) += "-journal",
                            ignored);
  }
  TempDatabasePath(const TempDatabasePath&) = delete;
  TempDatabasePath& operator=(const TempDatabasePath&) = delete;

  const std::filesystem::path& path() const { return m_path; }

private:
  std::filesystem::path m_path;
};

}
