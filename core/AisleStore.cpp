#include "core/AisleStore.hpp"

#include "core/Database.hpp"

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

// Like the unique index's COLLATE NOCASE: only ASCII letters fold
static bool equalIgnoringAsciiCase(std::string_view a, std::string_view b)
{
  return std::ranges::equal(a, b, {}, asciiLower, asciiLower);
}

AisleStore::AisleStore(Database& db, Clock clock)
  : m_db(db)
  , m_clock(std::move(clock))
{
  // Every shift below relies on live positions being exactly 0..n-1. A gap or
  // a duplicate (a bug, a bad migration) is renumbered rather than refusing to
  // start, which on a phone would lock the user out of their data.
  std::vector<int> misplaced;
  {
    Statement select = m_db.prepare(
      "SELECT id, name, fill, ink, dark_fill, dark_ink, modified_at, position "
      "FROM aisle WHERE deleted = 0 ORDER BY position, id");
    while (select.step()) {
      if (select.columnInt64(7) != count()) {
        misplaced.push_back(count());
      }
      m_aisles.push_back({ select.columnText(0),
                           select.columnText(1),
                           themedColorsColumns(select, 2),
                           fromMillis(select.columnInt64(6)) });
    }
  }
  if (misplaced.empty()) {
    return;
  }

  const Timestamp now = m_clock();
  Transaction transaction(m_db);
  for (int index : misplaced) {
    m_db
      .prepare("UPDATE aisle SET position = ?2, modified_at = ?3 WHERE id = ?1")
      .bind(1, m_aisles[index].id)
      .bind(2, index)
      .bind(3, toMillis(now))
      .run();
  }
  transaction.commit();
  for (int index : misplaced) {
    m_aisles[index].modifiedAt = now;
  }
}

std::expected<std::string, AisleError> AisleStore::create(
  std::string_view name,
  const ThemedColors& colors)
{
  checkNotNotifying();
  auto validated = validName(name);
  if (!validated) {
    return std::unexpected(validated.error());
  }

  const Timestamp now = m_clock();
  Aisle aisle{ m_ids.next(now), std::move(*validated), colors, now };
  const int index = count();
  m_db
    .prepare("INSERT INTO aisle (id, name, fill, ink, dark_fill, dark_ink, "
             "position, modified_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)")
    .bind(1, aisle.id)
    .bind(2, aisle.name)
    .bind(3, toText(colors.fill))
    .bind(4, toText(colors.ink))
    .bind(5, toText(colors.darkFill))
    .bind(6, toText(colors.darkInk))
    .bind(7, index)
    .bind(8, toMillis(now))
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

void AisleStore::setColors(std::string_view id, const ThemedColors& colors)
{
  checkNotNotifying();
  const int index = indexOf(id);
  if (colors == m_aisles[index].colors) {
    return;
  }

  const Timestamp now = m_clock();
  m_db
    .prepare("UPDATE aisle SET fill = ?2, ink = ?3, dark_fill = ?4, "
             "dark_ink = ?5, modified_at = ?6 WHERE id = ?1")
    .bind(1, id)
    .bind(2, toText(colors.fill))
    .bind(3, toText(colors.ink))
    .bind(4, toText(colors.darkFill))
    .bind(5, toText(colors.darkInk))
    .bind(6, toMillis(now))
    .run();

  apply(AisleUpdated{ index, AisleField::Colors }, [&] {
    m_aisles[index].colors = colors;
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
  // The aisles between the two positions shift by one towards `from`
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
  // The deleted row keeps its position, for restore()
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
    Statement select =
      m_db.prepare("SELECT name, fill, ink, dark_fill, dark_ink, position "
                   "FROM aisle WHERE id = ?1 AND deleted = 1");
    select.bind(1, id);
    if (!select.step()) {
      throw std::invalid_argument(
        "AisleStore::restore: no deleted aisle with this id");
    }
    return std::pair(Aisle{ std::string(id),
                            select.columnText(0),
                            themedColorsColumns(select, 1),
                            now },
                     select.columnInt64(5));
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
  // Memory is mid-change: a nested write would act on stale state
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

// noexcept: the write has committed, so if memory or an observer can't follow,
// terminating beats running on, out of sync; the next launch reloads the
// database.
template<typename Mutation>
void AisleStore::apply(const AisleChange& change, Mutation mutate) noexcept
{
  m_notifying = true;
  // Observers may register or unregister others while notified. Each one
  // registered by the end of this loop saw the old list, so it gets both calls.
  std::vector<AisleObserver*> notified;
  const auto nextToNotify = [&]() -> AisleObserver* {
    for (AisleObserver* observer : m_observers) {
      if (std::ranges::find(notified, observer) == notified.end()) {
        return observer;
      }
    }
    return nullptr;
  };
  while (AisleObserver* observer = nextToNotify()) {
    notified.push_back(observer);
    observer->aisleAboutToChange(change);
  }
  mutate();
  for (AisleObserver* observer : notified) {
    if (std::ranges::find(m_observers, observer) != m_observers.end()) {
      observer->aisleChanged(change);
    }
  }
  m_notifying = false;
}

}
