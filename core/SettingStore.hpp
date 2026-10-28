#pragma once

#include "core/Observers.hpp"
#include "core/clock.hpp"

#include <cstddef>
#include <functional>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace core {

class Database;

// Called like AisleObserver's functions: before memory changes, then after
class SettingObserver
{
public:
  virtual void settingAboutToChange(std::string_view key) noexcept = 0;
  virtual void settingChanged(std::string_view key) noexcept = 0;

protected:
  ~SettingObserver() = default;
};

// The app's settings: a text value by key, held in memory and written through
// to SQLite like the other stores. Values are language-neutral codes ("dark"),
// never translated text. A key that was never set has no value; settings are
// never removed.
class SettingStore
{
public:
  // The database must be migrated
  SettingStore(Database& db, Clock clock);
  SettingStore(const SettingStore&) = delete;
  SettingStore& operator=(const SettingStore&) = delete;

  std::optional<std::string> value(std::string_view key) const;
  // No write if the value doesn't change. Throws std::invalid_argument for an
  // empty key, std::logic_error from inside a notification.
  void setValue(std::string_view key, std::string_view value);

  // A setting that takes one of `codes`: the stored code's index, or 0, the
  // default, when unset or another value (e.g. written by a newer version)
  std::size_t codeIndex(std::string_view key,
                        std::span<const std::string_view> codes) const;

  // An on/off setting, stored as "true" or "false"; `fallback` when unset or
  // another value
  bool flag(std::string_view key, bool fallback) const;
  void setFlag(std::string_view key, bool on);

  // Not owned: an observer must unregister before it's destroyed
  void addObserver(SettingObserver& observer);
  void removeObserver(SettingObserver& observer);

private:
  Database& m_db;
  Clock m_clock;
  std::map<std::string, std::string, std::less<>> m_values;
  Observers<SettingObserver> m_observers;
};

}
