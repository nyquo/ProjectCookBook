#pragma once

#include "core/Observers.hpp"
#include "core/Tag.hpp"
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
enum class TagError
{
  EmptyName,     // blank once trimmed and folded
  DuplicateName, // another live tag has the same canonical name
};

enum class TagField
{
  Name,
  Color
};

// Changes to TagStore::tags(), by index in that list
struct TagInserted
{
  int index;
  bool operator==(const TagInserted&) const = default;
};

struct TagRemoved
{
  int index;
  bool operator==(const TagRemoved&) const = default;
};

struct TagUpdated
{
  int index;
  TagField field;
  bool operator==(const TagUpdated&) const = default;
};

using TagChange = std::variant<TagInserted, TagRemoved, TagUpdated>;

// Called like AisleObserver's functions: before memory changes, then after
class TagObserver
{
public:
  virtual void tagAboutToChange(const TagChange& change) noexcept = 0;
  virtual void tagChanged(const TagChange& change) noexcept = 0;

protected:
  ~TagObserver() = default;
};

// Live tags in id order, which is creation order, held in memory and written
// through to SQLite like AisleStore's aisles. Programming errors throw
// std::logic_error subclasses before anything changes: unknown id, or a change
// requested from inside a notification.
class TagStore
{
public:
  // The database must be migrated
  TagStore(Database& db, Clock clock);
  TagStore(const TagStore&) = delete;
  TagStore& operator=(const TagStore&) = delete;

  const std::vector<Tag>& tags() const { return m_tags; }

  // The tag takes nextColor(); returns its id
  [[nodiscard]] std::expected<std::string, TagError> create(
    std::string_view name);
  // A tag can take another case or spelling of its own name
  [[nodiscard]] std::expected<void, TagError> rename(std::string_view id,
                                                     std::string_view name);
  void setColor(std::string_view id, TagFamily color);
  // Soft delete: the row stays, flagged deleted, for restore()
  void remove(std::string_view id);
  // Fails with DuplicateName if a live tag took the name meanwhile
  [[nodiscard]] std::expected<void, TagError> restore(std::string_view id);

  // The color least used among live tags; ties go in TagFamily order. The
  // recipes that carry a tag: RecipeStore::recipeCount().
  TagFamily nextColor() const;

  // Not owned: an observer must unregister before it's destroyed
  void addObserver(TagObserver& observer);
  void removeObserver(TagObserver& observer);

private:
  struct ValidName
  {
    std::string name;
    std::string canonicalName;
  };

  int indexOf(std::string_view id) const;
  // Where a tag with this id goes, to keep id order
  int insertionIndex(std::string_view id) const;
  void checkNotNotifying() const;
  // Trimmed and folded, unless blank or another live tag has it
  std::expected<ValidName, TagError> validName(std::string_view name,
                                               int ignoredIndex = -1) const;
  bool canonicalNameTaken(std::string_view canonicalName,
                          int ignoredIndex = -1) const;

  template<typename Mutation>
  void apply(const TagChange& change, Mutation mutate) noexcept;

  Database& m_db;
  Clock m_clock;
  UuidV7Generator m_ids;
  std::vector<Tag> m_tags;
  Observers<TagObserver> m_observers;
};

}
