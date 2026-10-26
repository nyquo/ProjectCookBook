#pragma once

#include "core/Aisle.hpp"
#include "core/Observers.hpp"
#include "core/UuidV7Generator.hpp"
#include "core/clock.hpp"

#include <expected>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace core {

class Database;

// Validation failures the user can fix
enum class AisleError
{
  EmptyName,     // blank once trimmed
  DuplicateName, // another live aisle has it, ignoring ASCII case
  InUse,         // remove(): catalog items are in the aisle
};

enum class AisleField
{
  Name,
  Colors
};

// Changes to AisleStore::aisles(), by index in that list
struct AisleInserted
{
  int index;
  bool operator==(const AisleInserted&) const = default;
};

struct AisleRemoved
{
  int index;
  bool operator==(const AisleRemoved&) const = default;
};

// The aisle at `from` is now at `to`; those in between shifted by one
struct AisleMoved
{
  int from;
  int to;
  bool operator==(const AisleMoved&) const = default;
};

struct AisleUpdated
{
  int index;
  AisleField field;
  bool operator==(const AisleUpdated&) const = default;
};

using AisleChange =
  std::variant<AisleInserted, AisleRemoved, AisleMoved, AisleUpdated>;

// Called before memory changes (the database has already committed) and after:
// during aisleAboutToChange(), aisles() still holds the old list. An observer
// registered during aisleAboutToChange() gets both calls; one registered during
// aisleChanged() gets neither.
class AisleObserver
{
public:
  virtual void aisleAboutToChange(const AisleChange& change) noexcept = 0;
  virtual void aisleChanged(const AisleChange& change) noexcept = 0;

protected:
  ~AisleObserver() = default;
};

// Live aisles in position order, held in memory and written through to SQLite.
// A change is validated, committed, then applied to memory and reported to
// observers; if the write throws, memory and observers see nothing. Programming
// errors throw std::logic_error subclasses before anything changes: unknown id,
// index out of range, or a change requested from inside a notification.
class AisleStore
{
public:
  // The database must be migrated
  AisleStore(Database& db, Clock clock);
  AisleStore(const AisleStore&) = delete;
  AisleStore& operator=(const AisleStore&) = delete;

  const std::vector<Aisle>& aisles() const { return m_aisles; }

  // Appends; returns the new id
  [[nodiscard]] std::expected<std::string, AisleError> create(
    std::string_view name,
    const ThemedColors& colors);
  [[nodiscard]] std::expected<void, AisleError> rename(std::string_view id,
                                                       std::string_view name);
  void setColors(std::string_view id, const ThemedColors& colors);
  void move(int from, int to);
  // Soft delete: the row stays, flagged deleted, for restore(). Fails with
  // InUse while catalog items are in the aisle; ingredients outside the
  // catalog may keep it, they show under "Other".
  [[nodiscard]] std::expected<void, AisleError> remove(std::string_view id);
  // Back to the old position, or last if the list got shorter. Fails with
  // DuplicateName if a live aisle took the name meanwhile.
  [[nodiscard]] std::expected<void, AisleError> restore(std::string_view id);

  // Not owned: an observer must unregister before it's destroyed
  void addObserver(AisleObserver& observer);
  void removeObserver(AisleObserver& observer);

private:
  int count() const { return static_cast<int>(m_aisles.size()); }
  int indexOf(std::string_view id) const;
  void checkIndex(int index) const;
  void checkNotNotifying() const;
  // The trimmed name, unless blank or taken by another live aisle
  std::expected<std::string, AisleError> validName(std::string_view name,
                                                   int ignoredIndex = -1) const;
  void setModifiedAt(int first, int last, Timestamp time);

  template<typename Mutation>
  void apply(const AisleChange& change, Mutation mutate) noexcept;

  Database& m_db;
  Clock m_clock;
  UuidV7Generator m_ids;
  std::vector<Aisle> m_aisles;
  Observers<AisleObserver> m_observers;
};

}
