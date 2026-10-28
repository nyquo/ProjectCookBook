#include "core/TagStore.hpp"

#include "core/Database.hpp"
#include "core/text.hpp"

#include <sqlite3.h>

#include <algorithm>
#include <array>
#include <stdexcept>
#include <utility>

namespace core {

static TagFamily colorColumn(const Statement& statement, int index)
{
  const std::string code = statement.columnText(index);
  const std::optional<TagFamily> color = tagFamilyFromCode(code);
  if (!color) {
    throw DatabaseError(SQLITE_CORRUPT, "invalid tag color '" + code + "'");
  }
  return *color;
}

TagStore::TagStore(Database& db, Clock clock)
  : m_db(db)
  , m_clock(std::move(clock))
{
  Statement select =
    m_db.prepare("SELECT id, name, canonical_name, color, modified_at "
                 "FROM tag WHERE deleted = 0 ORDER BY id");
  while (select.step()) {
    m_tags.push_back({ select.columnText(0),
                       select.columnText(1),
                       select.columnText(2),
                       colorColumn(select, 3),
                       fromMillis(select.columnInt64(4)) });
  }
}

std::expected<std::string, TagError> TagStore::create(std::string_view name)
{
  checkNotNotifying();
  auto validated = validName(name);
  if (!validated) {
    return std::unexpected(validated.error());
  }

  const Timestamp now = m_clock();
  Tag tag{ m_ids.next(now),
           std::move(validated->name),
           std::move(validated->canonicalName),
           nextColor(),
           now };
  m_db
    .prepare("INSERT INTO tag (id, name, canonical_name, color, modified_at) "
             "VALUES (?1, ?2, ?3, ?4, ?5)")
    .bind(1, tag.id)
    .bind(2, tag.name)
    .bind(3, tag.canonicalName)
    .bind(4, tagFamilyCode(tag.color))
    .bind(5, toMillis(now))
    .run();

  // Ids made in the same millisecond don't sort by creation
  const int index = insertionIndex(tag.id);
  std::string id = tag.id;
  apply(TagInserted{ index },
        [&] { m_tags.insert(m_tags.begin() + index, std::move(tag)); });
  return id;
}

std::expected<void, TagError> TagStore::rename(std::string_view id,
                                               std::string_view name)
{
  checkNotNotifying();
  const int index = indexOf(id);
  if (trimmed(name) == m_tags[index].name) {
    return {};
  }
  auto validated = validName(name, index);
  if (!validated) {
    return std::unexpected(validated.error());
  }

  const Timestamp now = m_clock();
  m_db
    .prepare("UPDATE tag SET name = ?2, canonical_name = ?3, modified_at = ?4 "
             "WHERE id = ?1")
    .bind(1, id)
    .bind(2, validated->name)
    .bind(3, validated->canonicalName)
    .bind(4, toMillis(now))
    .run();

  apply(TagUpdated{ index, TagField::Name }, [&] {
    Tag& tag = m_tags[index];
    tag.name = std::move(validated->name);
    tag.canonicalName = std::move(validated->canonicalName);
    tag.modifiedAt = now;
  });
  return {};
}

void TagStore::setColor(std::string_view id, TagFamily color)
{
  checkNotNotifying();
  const int index = indexOf(id);
  if (color == m_tags[index].color) {
    return;
  }

  const Timestamp now = m_clock();
  m_db.prepare("UPDATE tag SET color = ?2, modified_at = ?3 WHERE id = ?1")
    .bind(1, id)
    .bind(2, tagFamilyCode(color))
    .bind(3, toMillis(now))
    .run();

  apply(TagUpdated{ index, TagField::Color }, [&] {
    m_tags[index].color = color;
    m_tags[index].modifiedAt = now;
  });
}

void TagStore::remove(std::string_view id)
{
  checkNotNotifying();
  const int index = indexOf(id);

  m_db.prepare("UPDATE tag SET deleted = 1, modified_at = ?2 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toMillis(m_clock()))
    .run();

  apply(TagRemoved{ index }, [&] { m_tags.erase(m_tags.begin() + index); });
}

std::expected<void, TagError> TagStore::restore(std::string_view id)
{
  checkNotNotifying();
  const Timestamp now = m_clock();
  // Deleted tags aren't in memory. Leaving the lambda finishes the SELECT
  // before the write below.
  Tag tag = [&] {
    Statement select = m_db.prepare("SELECT name, canonical_name, color "
                                    "FROM tag WHERE id = ?1 AND deleted = 1");
    select.bind(1, id);
    if (!select.step()) {
      throw std::invalid_argument(
        "TagStore::restore: no deleted tag with this id");
    }
    return Tag{ std::string(id),
                select.columnText(0),
                select.columnText(1),
                colorColumn(select, 2),
                now };
  }();
  if (canonicalNameTaken(tag.canonicalName)) {
    return std::unexpected(TagError::DuplicateName);
  }

  m_db.prepare("UPDATE tag SET deleted = 0, modified_at = ?2 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toMillis(now))
    .run();

  const int index = insertionIndex(id);
  apply(TagInserted{ index },
        [&] { m_tags.insert(m_tags.begin() + index, std::move(tag)); });
  return {};
}

TagFamily TagStore::nextColor() const
{
  std::array<int, tagFamilyCount> uses{};
  for (const Tag& tag : m_tags) {
    ++uses[std::to_underlying(tag.color)];
  }
  // min_element keeps the first of equal counts
  return static_cast<TagFamily>(std::ranges::min_element(uses) - uses.begin());
}

void TagStore::addObserver(TagObserver& observer)
{
  m_observers.add(observer);
}

void TagStore::removeObserver(TagObserver& observer)
{
  m_observers.remove(observer);
}

int TagStore::indexOf(std::string_view id) const
{
  const auto it = std::ranges::find(m_tags, id, &Tag::id);
  if (it == m_tags.end()) {
    throw std::invalid_argument("TagStore: no live tag with this id");
  }
  return static_cast<int>(it - m_tags.begin());
}

int TagStore::insertionIndex(std::string_view id) const
{
  const auto it = std::ranges::lower_bound(m_tags, id, {}, &Tag::id);
  return static_cast<int>(it - m_tags.begin());
}

void TagStore::checkNotNotifying() const
{
  if (m_observers.notifying()) {
    throw std::logic_error(
      "TagStore: no changes from inside an observer notification");
  }
}

std::expected<TagStore::ValidName, TagError> TagStore::validName(
  std::string_view name,
  int ignoredIndex) const
{
  std::string clean(trimmed(name));
  std::string canonical = canonicalName(clean);
  if (canonical.empty()) {
    return std::unexpected(TagError::EmptyName);
  }
  if (canonicalNameTaken(canonical, ignoredIndex)) {
    return std::unexpected(TagError::DuplicateName);
  }
  return ValidName{ std::move(clean), std::move(canonical) };
}

bool TagStore::canonicalNameTaken(std::string_view canonicalName,
                                  int ignoredIndex) const
{
  for (int i = 0; i < static_cast<int>(m_tags.size()); ++i) {
    if (i != ignoredIndex && m_tags[i].canonicalName == canonicalName) {
      return true;
    }
  }
  return false;
}

template<typename Mutation>
void TagStore::apply(const TagChange& change, Mutation mutate) noexcept
{
  m_observers.notify(
    [&](TagObserver& observer) { observer.tagAboutToChange(change); },
    mutate,
    [&](TagObserver& observer) { observer.tagChanged(change); });
}

}
