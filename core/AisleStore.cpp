#include "core/AisleStore.hpp"

#include "core/Database.hpp"

#include <sqlite3.h>

#include <algorithm>
#include <stdexcept>

namespace core {

static bool isAsciiSpace(char c)
{
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

static std::string_view trimmed(std::string_view text)
{
  while (!text.empty() && isAsciiSpace(text.front())) {
    text.remove_prefix(1);
  }
  while (!text.empty() && isAsciiSpace(text.back())) {
    text.remove_suffix(1);
  }
  return text;
}

static char asciiLower(char c)
{
  return c >= 'A' && c <= 'Z' ? static_cast<char>(c - 'A' + 'a') : c;
}

// Like the unique index's COLLATE NOCASE: only ASCII letters fold.
static bool equalIgnoringAsciiCase(std::string_view a, std::string_view b)
{
  return std::ranges::equal(a, b, {}, asciiLower, asciiLower);
}

static AisleColor colorColumn(const Statement& statement, int index)
{
  const std::string text = statement.columnText(index);
  if (const auto color = aisleColorFromText(text)) {
    return *color;
  }
  throw DatabaseError(SQLITE_CORRUPT, "unknown aisle color '" + text + "'");
}

AisleStore::AisleStore(Database& db, Clock clock)
  : m_db(db)
  , m_clock(std::move(clock))
{
  Statement select =
    m_db.prepare("SELECT id, name, color, modified_at, position FROM aisle "
                 "WHERE deleted = 0 ORDER BY position");
  while (select.step()) {
    // Every shift below relies on live positions being exactly 0..n-1.
    if (select.columnInt64(4) != count()) {
      throw DatabaseError(SQLITE_CORRUPT,
                          "live aisle positions are not 0..n-1");
    }
    m_aisles.push_back({ select.columnText(0),
                         select.columnText(1),
                         colorColumn(select, 2),
                         fromMillis(select.columnInt64(3)) });
  }
}

std::expected<std::string, AisleError> AisleStore::create(std::string_view name,
                                                          AisleColor color)
{
  checkNotNotifying();
  auto validated = validName(name);
  if (!validated) {
    return std::unexpected(validated.error());
  }

  const Timestamp now = m_clock();
  Aisle aisle{ m_ids.next(now), std::move(*validated), color, now };
  const int index = count();
  m_db
    .prepare("INSERT INTO aisle (id, name, color, position, modified_at) "
             "VALUES (?1, ?2, ?3, ?4, ?5)")
    .bind(1, aisle.id)
    .bind(2, aisle.name)
    .bind(3, toText(color))
    .bind(4, index)
    .bind(5, toMillis(now))
    .run();

  std::string id = aisle.id;
  apply(AisleInserted{ index }, [&] { m_aisles.push_back(std::move(aisle)); });
  return id;
}

std::expected<void, AisleError> AisleStore::rename(std::string_view id,
                                                   std::string_view name)
{
  checkNotNotifying();
  const int index = indexOf(id);
  if (trimmed(name) == m_aisles[index].name) {
    return {};
  }
  auto validated = validName(name, index);
  if (!validated) {
    return std::unexpected(validated.error());
  }

  const Timestamp now = m_clock();
  m_db.prepare("UPDATE aisle SET name = ?2, modified_at = ?3 WHERE id = ?1")
    .bind(1, id)
    .bind(2, *validated)
    .bind(3, toMillis(now))
    .run();

  apply(AisleUpdated{ index, AisleField::Name }, [&] {
    m_aisles[index].name = std::move(*validated);
    m_aisles[index].modifiedAt = now;
  });
  return {};
}

void AisleStore::setColor(std::string_view id, AisleColor color)
{
  checkNotNotifying();
  const int index = indexOf(id);
  if (color == m_aisles[index].color) {
    return;
  }

  const Timestamp now = m_clock();
  m_db.prepare("UPDATE aisle SET color = ?2, modified_at = ?3 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toText(color))
    .bind(3, toMillis(now))
    .run();

  apply(AisleUpdated{ index, AisleField::Color }, [&] {
    m_aisles[index].color = color;
    m_aisles[index].modifiedAt = now;
  });
}

void AisleStore::move(int from, int to)
{
  checkNotNotifying();
  checkIndex(from);
  checkIndex(to);
  if (from == to) {
    return;
  }

  const Timestamp now = m_clock();
  Transaction transaction(m_db);
  // The aisles between the two positions shift by one towards `from`.
  m_db
    .prepare("UPDATE aisle SET position = position + ?1, modified_at = ?2 "
             "WHERE deleted = 0 AND position BETWEEN ?3 AND ?4 AND id <> ?5")
    .bind(1, from < to ? -1 : 1)
    .bind(2, toMillis(now))
    .bind(3, std::min(from, to))
    .bind(4, std::max(from, to))
    .bind(5, m_aisles[from].id)
    .run();
  m_db.prepare("UPDATE aisle SET position = ?2, modified_at = ?3 WHERE id = ?1")
    .bind(1, m_aisles[from].id)
    .bind(2, to)
    .bind(3, toMillis(now))
    .run();
  transaction.commit();

  apply(AisleMoved{ from, to }, [&] {
    const auto first = m_aisles.begin();
    if (from < to) {
      std::rotate(first + from, first + from + 1, first + to + 1);
    } else {
      std::rotate(first + to, first + from, first + from + 1);
    }
    setModifiedAt(std::min(from, to), std::max(from, to), now);
  });
}

void AisleStore::remove(std::string_view id)
{
  checkNotNotifying();
  const int index = indexOf(id);
  // TODO(shopping list): an aisle can only be deleted while no shopping-list
  // item uses it. When that table exists, check it here, before writing, and
  // return a new AisleError::NotEmpty (remove() then returns std::expected).

  const Timestamp now = m_clock();
  Transaction transaction(m_db);
  m_db.prepare("UPDATE aisle SET deleted = 1, modified_at = ?2 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toMillis(now))
    .run();
  // The deleted row keeps its position, for restore().
  m_db
    .prepare("UPDATE aisle SET position = position - 1, modified_at = ?2 "
             "WHERE deleted = 0 AND position > ?1")
    .bind(1, index)
    .bind(2, toMillis(now))
    .run();
  transaction.commit();

  apply(AisleRemoved{ index }, [&] {
    m_aisles.erase(m_aisles.begin() + index);
    setModifiedAt(index, count() - 1, now);
  });
}

std::expected<void, AisleError> AisleStore::restore(std::string_view id)
{
  checkNotNotifying();
  const Timestamp now = m_clock();
  // Deleted aisles aren't in memory. Leaving the lambda finishes the SELECT
  // before the writes below.
  auto [aisle, oldPosition] = [&] {
    Statement select = m_db.prepare(
      "SELECT name, color, position FROM aisle WHERE id = ?1 AND deleted = 1");
    select.bind(1, id);
    if (!select.step()) {
      throw std::invalid_argument(
        "AisleStore::restore: no deleted aisle with this id");
    }
    return std::pair(
      Aisle{
        std::string(id), select.columnText(0), colorColumn(select, 1), now },
      select.columnInt64(2));
  }();
  if (const auto validated = validName(aisle.name); !validated) {
    return std::unexpected(validated.error());
  }

  const int index =
    static_cast<int>(std::min<std::int64_t>(oldPosition, count()));
  Transaction transaction(m_db);
  m_db
    .prepare("UPDATE aisle SET position = position + 1, modified_at = ?2 "
             "WHERE deleted = 0 AND position >= ?1")
    .bind(1, index)
    .bind(2, toMillis(now))
    .run();
  m_db
    .prepare("UPDATE aisle SET deleted = 0, position = ?2, modified_at = ?3 "
             "WHERE id = ?1")
    .bind(1, id)
    .bind(2, index)
    .bind(3, toMillis(now))
    .run();
  transaction.commit();

  apply(AisleInserted{ index }, [&] {
    m_aisles.insert(m_aisles.begin() + index, std::move(aisle));
    setModifiedAt(index + 1, count() - 1, now);
  });
  return {};
}

void AisleStore::addObserver(AisleObserver& observer)
{
  m_observers.push_back(&observer);
}

void AisleStore::removeObserver(AisleObserver& observer)
{
  std::erase(m_observers, &observer);
}

int AisleStore::indexOf(std::string_view id) const
{
  const auto it = std::ranges::find(m_aisles, id, &Aisle::id);
  if (it == m_aisles.end()) {
    throw std::invalid_argument("AisleStore: no live aisle with this id");
  }
  return static_cast<int>(it - m_aisles.begin());
}

void AisleStore::checkIndex(int index) const
{
  if (index < 0 || index >= count()) {
    throw std::out_of_range("AisleStore: aisle index out of range");
  }
}

void AisleStore::checkNotNotifying() const
{
  // Memory is mid-change: a nested write would act on stale state.
  if (m_notifying) {
    throw std::logic_error(
      "AisleStore: no changes from inside an observer notification");
  }
}

std::expected<std::string, AisleError> AisleStore::validName(
  std::string_view name,
  int ignoredIndex) const
{
  const std::string_view clean = trimmed(name);
  if (clean.empty()) {
    return std::unexpected(AisleError::EmptyName);
  }
  for (int i = 0; i < count(); ++i) {
    if (i != ignoredIndex && equalIgnoringAsciiCase(m_aisles[i].name, clean)) {
      return std::unexpected(AisleError::DuplicateName);
    }
  }
  return std::string(clean);
}

void AisleStore::setModifiedAt(int first, int last, Timestamp time)
{
  for (int i = first; i <= last; ++i) {
    m_aisles[i].modifiedAt = time;
  }
}

template<typename Mutation>
void AisleStore::apply(const AisleChange& change, Mutation mutate)
{
  m_notifying = true;
  notify(&AisleObserver::aisleAboutToChange, change);
  mutate();
  notify(&AisleObserver::aisleChanged, change);
  m_notifying = false;
}

void AisleStore::notify(void (AisleObserver::*method)(const AisleChange&),
                        const AisleChange& change)
{
  // A copy: an observer may unregister itself or another while notified.
  const std::vector<AisleObserver*> observers = m_observers;
  for (AisleObserver* observer : observers) {
    if (std::ranges::find(m_observers, observer) != m_observers.end()) {
      (observer->*method)(change);
    }
  }
}

}
