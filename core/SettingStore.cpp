#include "core/SettingStore.hpp"

#include "core/Database.hpp"

#include <stdexcept>

namespace core {

SettingStore::SettingStore(Database& db, Clock clock)
  : m_db(db)
  , m_clock(std::move(clock))
{
  Statement select = m_db.prepare("SELECT key, value FROM setting");
  while (select.step()) {
    m_values.emplace(select.columnText(0), select.columnText(1));
  }
}

std::optional<std::string> SettingStore::value(std::string_view key) const
{
  const auto it = m_values.find(key);
  if (it == m_values.end()) {
    return std::nullopt;
  }
  return it->second;
}

void SettingStore::setValue(std::string_view key, std::string_view value)
{
  if (m_observers.notifying()) {
    throw std::logic_error(
      "SettingStore: no changes from inside an observer notification");
  }
  if (key.empty()) {
    throw std::invalid_argument("SettingStore: empty key");
  }
  const auto it = m_values.find(key);
  if (it != m_values.end() && it->second == value) {
    return;
  }

  m_db
    .prepare("INSERT INTO setting (key, value, modified_at) "
             "VALUES (?1, ?2, ?3) ON CONFLICT (key) DO UPDATE "
             "SET value = excluded.value, modified_at = excluded.modified_at")
    .bind(1, key)
    .bind(2, value)
    .bind(3, toMillis(m_clock()))
    .run();

  m_observers.notify(
    [&](SettingObserver& observer) { observer.settingAboutToChange(key); },
    [&] { m_values.insert_or_assign(std::string(key), std::string(value)); },
    [&](SettingObserver& observer) { observer.settingChanged(key); });
}

void SettingStore::addObserver(SettingObserver& observer)
{
  m_observers.add(observer);
}

void SettingStore::removeObserver(SettingObserver& observer)
{
  m_observers.remove(observer);
}

}
